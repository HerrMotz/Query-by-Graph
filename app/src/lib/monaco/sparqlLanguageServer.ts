import * as monaco from "./monaco.ts";
import type {
    CompletionItem,
    CompletionItemKind as LspCompletionItemKind,
    CompletionList,
    Diagnostic,
    DocumentUri,
    Hover,
    Position,
    Range,
    TextEdit,
} from "vscode-languageserver-types";

// Client for the Qlue-ls SPARQL language server (https://github.com/IoannisNezis/Qlue-ls).
//
// The server itself runs as WASM inside `src/workers/sparqlLs.worker.ts`. This
// module speaks LSP to that worker and translates between LSP and Monaco:
// completion, hover and formatting are exposed as Monaco providers, diagnostics
// are pushed into the model as markers.

export type SparqlEngine = 'QLever' | 'GraphDB' | 'Virtuoso' | 'MillenniumDB' | 'Blazegraph' | 'Jena';

/**
 * A SPARQL endpoint the language server may query to provide completions for
 * subjects, predicates and objects.
 */
export interface SparqlBackend {
    name: string;
    /** The SPARQL endpoint itself, not the query service UI. */
    url: string;
    healthCheckUrl?: string;
    engine?: SparqlEngine;
    requestMethod?: 'GET' | 'POST';
    prefixMap?: Record<string, string>;
    /** Templates for the queries the server runs against `url`, keyed by completion type. */
    queries?: Record<string, string>;
}

export interface SparqlLanguageServer {
    /**
     * Use `backend` for completions. Passing `undefined` unregisters the
     * current one, so that a data source without a SPARQL endpoint does not
     * silently keep completing against the previously selected Wikibase.
     */
    setBackend: (backend?: SparqlBackend) => void;
    /**
     * Format a query string with qlue-ls' standalone formatter. Use this
     * instead of Monaco's format action for text the application generates:
     * formatting the model instead would edit it after the fact and feed a
     * change back into the graph round trip.
     */
    formatText: (text: string) => Promise<string>;
    dispose: () => void;
}

const REQUEST_TIMEOUT_MS = 5000;
const DIAGNOSTICS_DEBOUNCE_MS = 300;

// LSP CompletionItemKind (1-indexed) -> Monaco CompletionItemKind. The two
// enumerations list the same kinds in different orders, so they have to be
// mapped rather than cast.
const COMPLETION_ITEM_KIND: Record<LspCompletionItemKind, monaco.languages.CompletionItemKind> = {
    1: monaco.languages.CompletionItemKind.Text,
    2: monaco.languages.CompletionItemKind.Method,
    3: monaco.languages.CompletionItemKind.Function,
    4: monaco.languages.CompletionItemKind.Constructor,
    5: monaco.languages.CompletionItemKind.Field,
    6: monaco.languages.CompletionItemKind.Variable,
    7: monaco.languages.CompletionItemKind.Class,
    8: monaco.languages.CompletionItemKind.Interface,
    9: monaco.languages.CompletionItemKind.Module,
    10: monaco.languages.CompletionItemKind.Property,
    11: monaco.languages.CompletionItemKind.Unit,
    12: monaco.languages.CompletionItemKind.Value,
    13: monaco.languages.CompletionItemKind.Enum,
    14: monaco.languages.CompletionItemKind.Keyword,
    15: monaco.languages.CompletionItemKind.Snippet,
    16: monaco.languages.CompletionItemKind.Color,
    17: monaco.languages.CompletionItemKind.File,
    18: monaco.languages.CompletionItemKind.Reference,
    19: monaco.languages.CompletionItemKind.Folder,
    20: monaco.languages.CompletionItemKind.EnumMember,
    21: monaco.languages.CompletionItemKind.Constant,
    22: monaco.languages.CompletionItemKind.Struct,
    23: monaco.languages.CompletionItemKind.Event,
    24: monaco.languages.CompletionItemKind.Operator,
    25: monaco.languages.CompletionItemKind.TypeParameter,
};

/** InsertTextFormat.Snippet — the item's text contains snippet placeholders. */
const SNIPPET_FORMAT = 2;

// The semantic token legend qlue-ls declares, which is what colours the editor:
// there is no client side grammar. Monaco asks a provider for its legend once,
// before any server has answered, so the legend cannot come from the handshake
// — `verifySemanticTokenLegend` reports a server that disagrees with it.
const SEMANTIC_TOKEN_TYPES = [
    'keyword', 'function', 'variable', 'string', 'number', 'comment', 'operator', 'namespace',
];
const SEMANTIC_TOKEN_MODIFIERS = ['async'];

/**
 * Asks Monaco to fetch semantic tokens again. Monaco requests them as soon as
 * the model is attached, which is long before the WASM server has started, so
 * without this the query would stay uncoloured until the next keystroke.
 */
const semanticTokensChanged = new monaco.Emitter<void>();

/** Model URI -> connection, so the shared Monaco providers can route requests. */
const connections = new Map<string, LanguageServerConnection>();

let providersRegistered = false;

function toMonacoRange(range: Range): monaco.IRange {
    return {
        startLineNumber: range.start.line + 1,
        startColumn: range.start.character + 1,
        endLineNumber: range.end.line + 1,
        endColumn: range.end.character + 1,
    };
}

function toLspPosition(position: monaco.IPosition): Position {
    return {line: position.lineNumber - 1, character: position.column - 1};
}

/** The text of an LSP string-or-markup value. */
function textOf(content: string | { value: string }): string {
    return typeof content === 'string' ? content : content.value;
}

/** The plain text of `contents`, whichever of the three LSP shapes it has. */
function hoverText(contents: Hover['contents']): string[] {
    return (Array.isArray(contents) ? contents : [contents]).map(textOf);
}

/**
 * qlue-ls asks the client to open the suggest widget again after an item that
 * only completes part of a triple. Monaco has no handler for the server's own
 * command, but it has an equivalent built-in action.
 */
function retriggerCommand(command?: CompletionItem['command']) {
    if (command?.command !== 'triggerNewCompletion') return undefined;
    return {id: 'editor.action.triggerSuggest', title: command.title ?? 'Suggest'};
}

function verifySemanticTokenLegend(legend?: { tokenTypes?: string[] }) {
    // Monaco indexes into the legend it was given, so a server that reordered
    // or extended its own would silently colour the wrong tokens.
    if (legend?.tokenTypes && legend.tokenTypes.join() !== SEMANTIC_TOKEN_TYPES.join()) {
        console.warn('qlue-ls: unexpected semantic token legend', legend.tokenTypes);
    }
}

function markerSeverity(severity?: number): monaco.MarkerSeverity {
    switch (severity) {
        case 1:
            return monaco.MarkerSeverity.Error;
        case 2:
            return monaco.MarkerSeverity.Warning;
        case 4:
            return monaco.MarkerSeverity.Hint;
        default:
            return monaco.MarkerSeverity.Info;
    }
}

class LanguageServerConnection {
    private readonly worker: Worker;
    private readonly model: monaco.editor.ITextModel;
    private readonly uri: string;
    private readonly disposables: monaco.IDisposable[] = [];
    private readonly pending = new Map<number, {
        settle: (value: any) => void,
        timeout: ReturnType<typeof setTimeout>,
    }>();

    private nextRequestId = 0;
    private documentVersion = 0;
    private previousText = '';
    /** The language server has answered the initialize handshake. */
    private ready = false;
    private disposed = false;
    private backend?: SparqlBackend;
    private diagnosticsTimeout?: ReturnType<typeof setTimeout>;

    constructor(editor: monaco.editor.IStandaloneCodeEditor, model: monaco.editor.ITextModel, backend?: SparqlBackend) {
        this.model = model;
        this.uri = model.uri.toString();
        this.backend = backend;

        this.worker = new Worker(new URL('../../workers/sparqlLs.worker.ts', import.meta.url), {type: 'module'});
        this.worker.addEventListener('message', this.onWorkerMessage);

        this.disposables.push(editor.onDidChangeModelContent(() => this.syncDocument()));

        connections.set(this.uri, this);
    }

    setBackend(backend: SparqlBackend) {
        this.backend = backend;
        if (this.ready) this.applyBackend();
    }

    dispose() {
        this.disposed = true;
        if (this.diagnosticsTimeout) clearTimeout(this.diagnosticsTimeout);
        connections.delete(this.uri);
        this.disposables.forEach(disposable => disposable.dispose());
        this.worker.removeEventListener('message', this.onWorkerMessage);
        this.worker.terminate();
        // Settle whatever Monaco is still waiting for; an unsettled promise
        // would keep a suggest or hover operation pending forever.
        for (const [, callbacks] of this.pending) callbacks.settle(null);
        this.pending.clear();
        if (!this.model.isDisposed()) monaco.editor.setModelMarkers(this.model, 'qlue-ls', []);
    }

    /**
     * Send an LSP request. Resolves with `null` when the server is not (yet)
     * running or does not answer in time — a language server is an enhancement,
     * it must never block the editor.
     */
    request<T>(method: string, params: unknown): Promise<T | null> {
        if (!this.ready) return Promise.resolve(null);
        return this.sendRequest<T>(method, params);
    }

    /**
     * Format `text`, which is not one of the open documents — qlue-ls' formatter
     * is a plain function next to the language server, so it needs no document
     * at all (see `sparqlLs.worker.ts`).
     *
     * Returns `text` unchanged while the server is still starting up, rather
     * than making the caller wait for it.
     */
    async formatText(text: string): Promise<string> {
        // Formatting a blank query would turn it into a stray newline, which
        // reads as "there is a query" everywhere the emptiness is checked.
        if (!this.ready || !text.trim()) return text;

        const formatted = await this.awaitReply<string>('format', id => ({type: 'format', id, text}));
        // The formatter terminates its output with a newline; the editor would
        // show that as a trailing empty line.
        return formatted?.replace(/\n$/, '') ?? text;
    }

    /**
     * Send a request regardless of the handshake state. Only `initialize` may
     * use this — everything else has to wait until the server is initialized
     * and therefore goes through {@link request}.
     */
    private sendRequest<T>(method: string, params: unknown): Promise<T | null> {
        return this.awaitReply<T>(method, id => ({jsonrpc: '2.0', id, method, params}));
    }

    /**
     * Post a message built with a fresh request id and resolve with whatever
     * the worker sends back under that id — `null` if it does not answer in
     * time. `label` names the request in that warning.
     */
    private awaitReply<T>(label: string, message: (id: number) => unknown): Promise<T | null> {
        if (this.disposed) return Promise.resolve(null);
        return new Promise(resolve => {
            const id = ++this.nextRequestId;
            const timeout = setTimeout(() => {
                if (this.pending.delete(id)) {
                    console.warn(`qlue-ls: no response to "${label}" within ${REQUEST_TIMEOUT_MS}ms`);
                    resolve(null);
                }
            }, REQUEST_TIMEOUT_MS);
            this.pending.set(id, {
                timeout,
                settle: value => {
                    clearTimeout(timeout);
                    resolve(value);
                },
            });
            this.send(message(id));
        });
    }

    private notify(method: string, params: unknown) {
        this.send({jsonrpc: '2.0', method, params});
    }

    private send(message: unknown) {
        if (!this.disposed) this.worker.postMessage(message);
    }

    private onWorkerMessage = (event: MessageEvent) => {
        const message = event.data;
        if (!message || typeof message !== 'object') return;

        if (message.type === 'ready') {
            this.initialize();
            return;
        }

        if (message.type === 'error') {
            // The worker cannot answer any more. Settle what is outstanding
            // instead of letting every request run into its timeout.
            console.error('qlue-ls: the language server worker failed', message.error);
            this.ready = false;
            for (const [, callbacks] of this.pending) callbacks.settle(null);
            this.pending.clear();
            return;
        }

        if (message.type === 'formatted') {
            const callback = this.pending.get(message.id);
            if (!callback) return;
            this.pending.delete(message.id);
            callback.settle(message.text);
            return;
        }

        if ('id' in message && !('method' in message)) {
            const callback = this.pending.get(message.id);
            if (!callback) return;
            this.pending.delete(message.id);
            if (message.error) console.warn('qlue-ls: request failed', message.error);
            callback.settle(message.error ? null : message.result);
            return;
        }

        // Only diagnostics for the edited model may become markers.
        if (message.method === 'textDocument/publishDiagnostics' && message.params?.uri === this.uri) {
            this.setDiagnostics(message.params?.diagnostics ?? []);
        }
    };

    private async initialize() {
        // NOTE: qlue-ls recognises "Code - OSS" as a Monaco based client.
        // This is the request that makes the server ready, so it cannot go
        // through `request()`, which waits for exactly that.
        const response = await this.sendRequest<{
            capabilities?: { semanticTokensProvider?: { legend?: { tokenTypes?: string[] } } },
        }>('initialize', {
            processId: null,
            clientInfo: {name: 'Code - OSS', version: 'query-by-graph'},
            rootUri: null,
            capabilities: {
                textDocument: {
                    synchronization: {didSave: false},
                    completion: {completionItem: {snippetSupport: true}},
                    hover: {contentFormat: ['markdown', 'plaintext']},
                    formatting: {},
                    onTypeFormatting: {},
                    publishDiagnostics: {},
                    diagnostic: {},
                    semanticTokens: {
                        requests: {full: true, range: false},
                        tokenTypes: SEMANTIC_TOKEN_TYPES,
                        tokenModifiers: SEMANTIC_TOKEN_MODIFIERS,
                        formats: ['relative'],
                    },
                },
            },
        });
        if (this.disposed) return;

        this.notify('initialized', {});
        this.ready = true;
        verifySemanticTokenLegend(response?.capabilities?.semanticTokensProvider?.legend);

        // NOTE: formatting is deliberately left unconfigured. qlue-ls ignores
        // the options an LSP formatting request carries and formats by its own
        // settings, which `format_raw` — the formatter behind `formatText` —
        // cannot be given. Overriding them here would make generated queries
        // format differently from typed ones.
        this.notify('qlueLs/changeSettings', {
            completion: {
                resultSizeLimit: 50,
                timeoutMs: 3000,
            },
        });

        this.applyBackend();

        this.previousText = this.model.getValue();
        this.documentVersion = 1;
        this.notify('textDocument/didOpen', {
            textDocument: {
                uri: this.uri,
                languageId: 'sparql',
                version: this.documentVersion,
                text: this.previousText,
            },
        });
        this.requestDiagnostics();
        semanticTokensChanged.fire();
    }

    /** Register {@link backend} with the server and make it the default. */
    private applyBackend() {
        const backend = this.backend;
        if (!backend) return;

        this.notify('qlueLs/addBackend', {
            name: backend.name,
            url: backend.url,
            healthCheckUrl: backend.healthCheckUrl,
            engine: backend.engine,
            requestMethod: backend.requestMethod ?? 'GET',
            prefixMap: backend.prefixMap ?? {},
            queries: backend.queries ?? {},
            default: true,
        });
        this.notify('qlueLs/updateDefaultBackend', {backendName: backend.name});
    }

    private syncDocument() {
        if (!this.ready || this.disposed) return;

        const text = this.model.getValue();
        if (text === this.previousText) return;

        this.documentVersion++;
        // A change without a range replaces the whole document, which is what
        // every change here is: the model is rewritten by the graph round trip
        // as often as it is typed in.
        this.notify('textDocument/didChange', {
            textDocument: {uri: this.uri, version: this.documentVersion},
            contentChanges: [{text}],
        });
        this.previousText = text;

        if (this.diagnosticsTimeout) clearTimeout(this.diagnosticsTimeout);
        this.diagnosticsTimeout = setTimeout(() => this.requestDiagnostics(), DIAGNOSTICS_DEBOUNCE_MS);
    }

    /**
     * qlue-ls only pushes diagnostics on save, which never happens here, so they
     * are pulled after every change instead.
     */
    private requestDiagnostics() {
        // The document may well have changed again while the server was
        // answering; markers computed for an older text would sit under
        // unrelated words.
        const version = this.documentVersion;
        this.request<{ items?: Diagnostic[] }>('textDocument/diagnostic', {textDocument: {uri: this.uri}})
            .then(report => {
                if (report?.items && version === this.documentVersion) this.setDiagnostics(report.items);
            })
            .catch(error => console.warn('qlue-ls: could not pull diagnostics', error));
    }

    private setDiagnostics(diagnostics: Diagnostic[]) {
        if (this.disposed || this.model.isDisposed()) return;
        monaco.editor.setModelMarkers(this.model, 'qlue-ls', diagnostics
            .filter(diagnostic => !!diagnostic?.range)
            .map(diagnostic => ({
                ...toMonacoRange(diagnostic.range),
                severity: markerSeverity(diagnostic.severity),
                message: textOf(diagnostic.message),
                code: diagnostic.code === undefined ? undefined : String(diagnostic.code),
                source: diagnostic.source ?? 'qlue-ls',
            })));
    }
}

/** The connection that serves `model`, if the language server is attached to it. */
function connectionFor(model: monaco.editor.ITextModel): LanguageServerConnection | undefined {
    return connections.get(model.uri.toString());
}

function textDocument(model: monaco.editor.ITextModel): { uri: DocumentUri } {
    return {uri: model.uri.toString()};
}

function toMonacoEdits(edits: TextEdit[] | null): monaco.languages.TextEdit[] {
    if (!Array.isArray(edits)) return [];
    return edits.map(edit => ({range: toMonacoRange(edit.range), text: edit.newText}));
}

function registerProviders() {
    if (providersRegistered) return;
    providersRegistered = true;

    monaco.languages.registerCompletionItemProvider('sparql', {
        // A space starts a new token in SPARQL, so it is a completion trigger
        // just as much as the token prefixes are.
        triggerCharacters: [' ', '<', '?', ':'],
        async provideCompletionItems(model, position, context) {
            const connection = connectionFor(model);
            if (!connection) return {suggestions: []};

            const result = await connection.request<CompletionList | CompletionItem[]>('textDocument/completion', {
                textDocument: textDocument(model),
                position: toLspPosition(position),
                // Monaco's trigger kind is 0-indexed, the LSP one is 1-indexed.
                context: {
                    triggerKind: context.triggerKind + 1,
                    ...(context.triggerCharacter ? {triggerCharacter: context.triggerCharacter} : {}),
                },
            });
            if (!result) return {suggestions: []};

            const list: CompletionList = Array.isArray(result) ? {isIncomplete: false, items: result} : result;
            // Values an item may omit because the list declares them once.
            const itemDefaults = list.itemDefaults ?? {};
            const editRange = itemDefaults.editRange;
            const word = model.getWordUntilPosition(position);
            const defaultRange: monaco.IRange = editRange
                ? toMonacoRange('insert' in editRange ? editRange.insert : editRange)
                : {
                    startLineNumber: position.lineNumber,
                    startColumn: word.startColumn,
                    endLineNumber: position.lineNumber,
                    endColumn: position.column,
                };

            return {
                // Keep asking the server as the user types instead of filtering
                // the first result set; the entity search depends on the term.
                incomplete: list.isIncomplete,
                suggestions: (list.items ?? []).map(item => {
                    const textEdit = item.textEdit;
                    const insertTextFormat = item.insertTextFormat ?? itemDefaults.insertTextFormat;
                    return {
                        label: item.label,
                        kind: COMPLETION_ITEM_KIND[item.kind!] ?? monaco.languages.CompletionItemKind.Text,
                        insertText: textEdit?.newText ?? item.insertText ?? item.label,
                        insertTextRules: insertTextFormat === SNIPPET_FORMAT
                            ? monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet
                            : undefined,
                        detail: item.detail,
                        documentation: typeof item.documentation === 'object'
                            ? item.documentation.value
                            : item.documentation,
                        filterText: item.filterText,
                        sortText: item.sortText,
                        commitCharacters: item.commitCharacters ?? itemDefaults.commitCharacters,
                        command: retriggerCommand(item.command),
                        range: textEdit && 'range' in textEdit ? toMonacoRange(textEdit.range) : defaultRange,
                    };
                }),
            };
        },
    });

    // The only thing that colours the editor — there is no Monarch grammar.
    monaco.languages.registerDocumentSemanticTokensProvider('sparql', {
        onDidChange: semanticTokensChanged.event,
        getLegend: () => ({tokenTypes: SEMANTIC_TOKEN_TYPES, tokenModifiers: SEMANTIC_TOKEN_MODIFIERS}),
        async provideDocumentSemanticTokens(model) {
            const connection = connectionFor(model);
            if (!connection) return null;

            const result = await connection.request<{ data: number[] }>('textDocument/semanticTokens/full', {
                textDocument: textDocument(model),
            });
            // While the server is starting up there are no tokens yet; `null`
            // leaves the text in the default colour rather than blanking it.
            return result?.data ? {data: Uint32Array.from(result.data)} : null;
        },
        releaseDocumentSemanticTokens() {
            // No result ids are requested, so there is nothing to release.
        },
    });

    monaco.languages.registerHoverProvider('sparql', {
        async provideHover(model, position) {
            const connection = connectionFor(model);
            if (!connection) return null;

            const result = await connection.request<Hover>('textDocument/hover', {
                textDocument: textDocument(model),
                position: toLspPosition(position),
            });
            if (!result?.contents) return null;

            return {
                range: result.range ? toMonacoRange(result.range) : undefined,
                contents: hoverText(result.contents).map(value => ({value})),
            };
        },
    });

    monaco.languages.registerDocumentFormattingEditProvider('sparql', {
        async provideDocumentFormattingEdits(model, options) {
            const connection = connectionFor(model);
            if (!connection) return [];

            return toMonacoEdits(await connection.request<TextEdit[]>('textDocument/formatting', {
                textDocument: textDocument(model),
                options: {tabSize: options.tabSize, insertSpaces: options.insertSpaces},
            }));
        },
    });

    monaco.languages.registerOnTypeFormattingEditProvider('sparql', {
        // qlue-ls indents the next line to the predicate column once a triple
        // is terminated, which is what makes `formatOnType` worth enabling.
        autoFormatTriggerCharacters: ['\n', ';', '.'],
        async provideOnTypeFormattingEdits(model, position, character, options) {
            const connection = connectionFor(model);
            if (!connection) return [];

            return toMonacoEdits(await connection.request<TextEdit[]>('textDocument/onTypeFormatting', {
                textDocument: textDocument(model),
                position: toLspPosition(position),
                ch: character,
                options: {tabSize: options.tabSize, insertSpaces: options.insertSpaces},
            }));
        },
    });
}

/**
 * Start a SPARQL language server for `editor` and hook it up to Monaco.
 * The returned handle must be disposed when the editor goes away.
 */
export function attachSparqlLanguageServer(
    editor: monaco.editor.IStandaloneCodeEditor,
    backend?: SparqlBackend,
): SparqlLanguageServer {
    registerProviders();

    const model = editor.getModel();
    if (!model) throw new Error('Cannot attach the SPARQL language server to an editor without a model');

    let connection = new LanguageServerConnection(editor, model, backend);
    let current = backend;

    return {
        setBackend: (newBackend?: SparqlBackend) => {
            if (newBackend) {
                current = newBackend;
                connection.setBackend(newBackend);
                return;
            }
            if (!current) return;
            // qlue-ls can add a backend but not remove one, so the only way to
            // stop completing against the Wikibase selected before is to start
            // the server over without it.
            current = undefined;
            connection.dispose();
            connection = new LanguageServerConnection(editor, model);
        },
        formatText: (text: string) => connection.formatText(text),
        dispose: () => connection.dispose(),
    };
}
