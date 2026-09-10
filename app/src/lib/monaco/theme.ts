import * as monaco from "./monaco.ts";

// The editor theme. The token names below are qlue-ls' semantic token types:
// Monaco's standalone theme matches a semantic token against these rules by the
// literal `type.modifier` string, so they have to be named exactly like the
// entries of `SEMANTIC_TOKEN_TYPES` in `sparqlLanguageServer.ts`. The types not
// listed here (`string`, `number`, `comment`) keep the colours of the inherited
// `vs` theme.
//
// The editor is rendered on the app's light background with a transparent
// editor background, so this is a light theme: everything is dark ink and
// low-opacity black tints, and the selection colours are variations of one
// green rather than three unrelated hues.
const SELECTION = '#cfe8a7';
const SELECTION_MUTED = '#e2eecd';
const TINT = '#0000000a';
const TINT_STRONG = '#00000014';

export function registerSparqlTheme() {
    monaco.editor.defineTheme('custom-theme', {
        base: 'vs',
        inherit: true,
        rules: [
            {token: 'comment', foreground: '8b8b8b', fontStyle: 'italic'},
            {token: 'keyword', foreground: '0000c0'},
            {token: 'function', foreground: '795e26'},
            // Both IRIs and prefixed names; qlue-ls does not tell them apart.
            {token: 'namespace', foreground: '267f99'},
            {token: 'variable', foreground: '0a4d20'},
        ],
        colors: {
            // Let the app's own background show through.
            "editor.background": "#ffffff00",
            "editor.foreground": "#1f2328",
            "editor.selectionBackground": SELECTION,
            // The editor loses focus on every click into the graph, so the
            // inactive selection is the one on screen most of the time.
            "editor.inactiveSelectionBackground": SELECTION_MUTED,
            "editor.selectionHighlightBackground": SELECTION_MUTED,
            "editor.selectionHighlightBorder": SELECTION,
            // A tint, not a fill: a dark current line would swallow the text.
            "editor.lineHighlightBackground": TINT,
            "editor.lineHighlightBorder": TINT_STRONG,
            "editorCursor.foreground": "#1f2328",
            "editorWhitespace.foreground": "#BFBFBF",
            "editorIndentGuide.background1": TINT_STRONG,
        },
    });
}
