import * as monaco from "monaco-editor";

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
    /** Register `backend` and make it the one used for completions. */
    setBackend: (backend: SparqlBackend) => void;
    /**
     * Format a query string. Use this instead of Monaco's format action for
     * text the application generates: formatting the model instead would edit
     * it after the fact and feed a change back into the graph round trip.
     */
    formatText: (text: string) => Promise<string>;
    dispose: () => void;
}

const REQUEST_TIMEOUT_MS = 5000;
const DIAGNOSTICS_DEBOUNCE_MS = 300;

// LSP CompletionItemKind (1-indexed) -> Monaco CompletionItemKind (0-indexed)
const COMPLETION_ITEM_KIND: Record<number, monaco.languages.CompletionItemKind> = {
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

interface LspRange {
    start: { line: number, character: number };
    end: { line: number, character: number };
}

/** Model URI -> connection, so the shared Monaco providers can route requests. */
const connections = new Map<string, LanguageServerConnection>();

let providersRegistered = false;

function toMonacoRange(range: LspRange): monaco.IRange {
    return {
        startLineNumber: range.start.line + 1,
        startColumn: range.start.character + 1,
        endLineNumber: range.end.line + 1,
        endColumn: range.end.character + 1,
    };
}

/**
 * qlue-ls asks the client to open the suggest widget again after an item that
 * only completes part of a triple. Monaco has no handler for the server's own
 * command, but it has an equivalent built-in action.
 */
function retriggerCommand(command?: { command?: string, title?: string }) {
    if (command?.command !== 'triggerNewCompletion') return undefined;
    return {id: 'editor.action.triggerSuggest', title: command.title ?? 'Suggest'};
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
        resolve: (value: any) => void,
        reject: (error: any) => void,
        timeout: ReturnType<typeof setTimeout>,
    }>();

    private nextRequestId = 0;
    private documentVersion = 0;
    private previousText = '';
    /** The worker has loaded the WASM module and listens for messages. */
    private workerReady = false;
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
        if (this.ready) this.registerBackend(backend);
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
        for (const [, callbacks] of this.pending) {
            clearTimeout(callbacks.timeout);
            callbacks.resolve(null);
        }
        this.pending.clear();
        if (!this.model.isDisposed()) monaco.editor.setModelMarkers(this.model, 'qlue-ls', []);
    }

    /**
     * Send an LSP request. Resolves with `null` when the server is not (yet)
     * running or does not answer in time — a language server is an enhancement,
     * it must never block the editor.
     */
    request(method: string, params: unknown): Promise<any> {
        if (!this.ready) return Promise.resolve(null);
        return this.sendRequest(method, params);
    }

    /**
     * Ask the language server to format `text` without going through a
     * document. Returns `text` unchanged while the worker is still starting up,
     * rather than making the caller wait for it.
     */
    formatText(text: string): Promise<string> {
        // Formatting a blank query would turn it into a stray newline, which
        // reads as "there is a query" everywhere the emptiness is checked.
        if (this.disposed || !this.workerReady || !text.trim()) return Promise.resolve(text);
        return this.sendRequest('qbg/formatText', text).then(formatted =>
            typeof formatted === 'string' ? formatted : text);
    }

    /**
     * Send a request regardless of the handshake state. Only `initialize` and
     * the worker's own methods may use this — everything else has to wait until
     * the server is initialized and therefore goes through {@link request}.
     */
    private sendRequest(method: string, params: unknown): Promise<any> {
        if (this.disposed) return Promise.resolve(null);
        return new Promise(resolve => {
            const id = ++this.nextRequestId;
            const timeout = setTimeout(() => {
                if (this.pending.delete(id)) {
                    console.warn(`qlue-ls: no response to "${method}" within ${REQUEST_TIMEOUT_MS}ms`);
                    resolve(null);
                }
            }, REQUEST_TIMEOUT_MS);
            this.pending.set(id, {
                timeout,
                resolve: value => {
                    clearTimeout(timeout);
                    resolve(value);
                },
                reject: error => {
                    clearTimeout(timeout);
                    console.warn(`qlue-ls: "${method}" failed`, error);
                    resolve(null);
                },
            });
            this.send({jsonrpc: '2.0', id, method, params});
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
            this.workerReady = true;
            this.initialize();
            return;
        }

        if ('id' in message && !('method' in message)) {
            const callback = this.pending.get(message.id);
            if (callback) {
                this.pending.delete(message.id);
                message.error ? callback.reject(message.error) : callback.resolve(message.result);
            }
            return;
        }

        if (message.method === 'textDocument/publishDiagnostics') {
            this.setDiagnostics(message.params?.diagnostics ?? []);
        }
    };

    private async initialize() {
        // NOTE: qlue-ls recognises "Code - OSS" as a Monaco based client.
        // This is the request that makes the server ready, so it cannot go
        // through `request()`, which waits for exactly that.
        await this.sendRequest('initialize', {
            processId: null,
            clientInfo: {name: 'Code - OSS', version: 'query-by-graph'},
            rootUri: null,
            capabilities: {
                textDocument: {
                    synchronization: {didSave: false},
                    completion: {completionItem: {snippetSupport: true}},
                    hover: {contentFormat: ['markdown', 'plaintext']},
                    formatting: {},
                    publishDiagnostics: {},
                    diagnostic: {},
                },
            },
        });
        if (this.disposed) return;

        this.notify('initialized', {});
        this.ready = true;

        this.notify('qlueLs/changeSettings', {
            format: {
                alignPredicates: true,
                capitalizeKeywords: true,
                insertSpaces: true,
                tabSize: 2,
            },
            completion: {
                resultSizeLimit: 50,
                timeoutMs: 3000,
            },
        });

        if (this.backend) this.registerBackend(this.backend);

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
    }

    private registerBackend(backend: SparqlBackend) {
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

        // qlue-ls uses incremental synchronisation; replacing a range that spans
        // the whole previous document is the simplest correct change to send.
        const previousLines = this.previousText.split('\n');
        this.documentVersion++;
        this.notify('textDocument/didChange', {
            textDocument: {uri: this.uri, version: this.documentVersion},
            contentChanges: [{
                range: {
                    start: {line: 0, character: 0},
                    end: {line: previousLines.length - 1, character: previousLines[previousLines.length - 1].length},
                },
                text,
            }],
        });
        this.previousText = text;

        if (this.diagnosticsTimeout) clearTimeout(this.diagnosticsTimeout);
        this.diagnosticsTimeout = setTimeout(() => this.requestDiagnostics(), DIAGNOSTICS_DEBOUNCE_MS);
    }

    /**
     * qlue-ls only pushes diagnostics on save, which never happens here, so they
     * are pulled after every change instead.
     */
    private async requestDiagnostics() {
        const report = await this.request('textDocument/diagnostic', {textDocument: {uri: this.uri}});
        if (report?.items) this.setDiagnostics(report.items);
    }

    private setDiagnostics(diagnostics: any[]) {
        if (this.disposed || this.model.isDisposed()) return;
        monaco.editor.setModelMarkers(this.model, 'qlue-ls', diagnostics.map(diagnostic => ({
            ...toMonacoRange(diagnostic.range),
            severity: markerSeverity(diagnostic.severity),
            message: diagnostic.message,
            code: typeof diagnostic.code === 'object' ? diagnostic.code?.value : diagnostic.code,
            source: diagnostic.source ?? 'qlue-ls',
        })));
    }
}

function registerProviders() {
    if (providersRegistered) return;
    providersRegistered = true;

    monaco.languages.registerCompletionItemProvider('sparql', {
        triggerCharacters: [' ', '<', '?', ':'],
        async provideCompletionItems(model, position, context) {
            const connection = connections.get(model.uri.toString());
            if (!connection) return {suggestions: []};

            const result = await connection.request('textDocument/completion', {
                textDocument: {uri: model.uri.toString()},
                position: {line: position.lineNumber - 1, character: position.column - 1},
                // Monaco's trigger kind is 0-indexed, the LSP one is 1-indexed.
                context: {
                    triggerKind: context.triggerKind + 1,
                    ...(context.triggerCharacter ? {triggerCharacter: context.triggerCharacter} : {}),
                },
            });
            if (!result) return {suggestions: []};

            const items: any[] = Array.isArray(result) ? result : (result.items ?? []);
            // Values an item may omit because the list declares them once.
            const itemDefaults = (Array.isArray(result) ? undefined : result.itemDefaults) ?? {};
            const word = model.getWordUntilPosition(position);
            const defaultRange: monaco.IRange = itemDefaults.editRange
                ? toMonacoRange(itemDefaults.editRange.insert ?? itemDefaults.editRange)
                : {
                    startLineNumber: position.lineNumber,
                    startColumn: word.startColumn,
                    endLineNumber: position.lineNumber,
                    endColumn: position.column,
                };

            return {
                // Keep asking the server as the user types instead of filtering
                // the first result set; the entity search depends on the term.
                incomplete: Array.isArray(result) ? false : !!result.isIncomplete,
                suggestions: items.map(item => {
                    const label = typeof item.label === 'string' ? item.label : (item.label?.label ?? '');
                    const textEdit = item.textEdit;
                    const insertTextFormat = item.insertTextFormat ?? itemDefaults.insertTextFormat;
                    return {
                        label,
                        kind: COMPLETION_ITEM_KIND[item.kind as number] ?? monaco.languages.CompletionItemKind.Text,
                        insertText: textEdit?.newText ?? item.insertText ?? label,
                        insertTextRules: insertTextFormat === 2
                            ? monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet
                            : undefined,
                        detail: item.detail,
                        documentation: typeof item.documentation === 'object'
                            ? item.documentation?.value
                            : item.documentation,
                        filterText: item.filterText,
                        sortText: item.sortText,
                        commitCharacters: item.commitCharacters ?? itemDefaults.commitCharacters,
                        command: retriggerCommand(item.command),
                        range: textEdit?.range ? toMonacoRange(textEdit.range) : defaultRange,
                    };
                }),
            };
        },
    });

    monaco.languages.registerHoverProvider('sparql', {
        async provideHover(model, position) {
            const connection = connections.get(model.uri.toString());
            if (!connection) return null;

            const result = await connection.request('textDocument/hover', {
                textDocument: {uri: model.uri.toString()},
                position: {line: position.lineNumber - 1, character: position.column - 1},
            });
            if (!result?.contents) return null;

            const contents = Array.isArray(result.contents) ? result.contents : [result.contents];
            return {
                range: result.range ? toMonacoRange(result.range) : undefined,
                contents: contents.map((content: any) => ({
                    value: typeof content === 'string' ? content : (content.value ?? String(content)),
                })),
            };
        },
    });

    monaco.languages.registerDocumentFormattingEditProvider('sparql', {
        async provideDocumentFormattingEdits(model, options) {
            const connection = connections.get(model.uri.toString());
            if (!connection) return [];

            const edits = await connection.request('textDocument/formatting', {
                textDocument: {uri: model.uri.toString()},
                options: {tabSize: options.tabSize, insertSpaces: options.insertSpaces},
            });
            if (!Array.isArray(edits)) return [];

            return edits.map((edit: any) => ({
                range: toMonacoRange(edit.range),
                text: edit.newText,
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

    const connection = new LanguageServerConnection(editor, model, backend);
    return {
        setBackend: (newBackend: SparqlBackend) => connection.setBackend(newBackend),
        formatText: (text: string) => connection.formatText(text),
        dispose: () => connection.dispose(),
    };
}
