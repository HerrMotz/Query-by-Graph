import * as monaco from "./monaco.ts";

// Monaco ships no SPARQL language. The editor in App.vue asks for
// `language="sparql"`, so it has to be registered before the editor mounts —
// the language server providers (which are keyed by language id) are never
// asked otherwise.
//
// There is deliberately no tokenizer here: the colours come from qlue-ls'
// semantic tokens (see `sparqlLanguageServer.ts`), which are produced from a
// real parse tree instead of a second, hand-maintained copy of the SPARQL
// grammar. What is left is the configuration a language server cannot provide,
// because LSP has no notion of it.

export function registerSparqlLanguage() {
    if (monaco.languages.getLanguages().some(language => language.id === 'sparql')) return;

    monaco.languages.register({id: 'sparql', extensions: ['.rq', '.sparql']});

    monaco.languages.setLanguageConfiguration('sparql', {
        comments: {lineComment: '#'},
        // Monaco's default word pattern breaks at `?`, `$` and `:`, which would
        // make the editor treat `wd:Q42` as two words — and a completion that
        // the server sends without its own text edit would then be inserted
        // after the prefix instead of replacing it.
        wordPattern: /(<[^\s<>]*>)|([?$]?[A-Za-z_][\w.%-]*:?[\w.%-]*)/,
        brackets: [['{', '}'], ['(', ')'], ['[', ']']],
        // `notIn` is deliberately absent: it is matched against the token types
        // of a tokenizer, and semantic tokens carry only colours, so it would
        // be dead configuration.
        autoClosingPairs: [
            {open: '{', close: '}'},
            {open: '(', close: ')'},
            {open: '[', close: ']'},
            {open: '"', close: '"'},
            {open: "'", close: "'"},
            {open: '<', close: '>'},
        ],
    });
}
