// The single Monaco entry point for the whole app.
//
// Importing "monaco-editor" pulls in `editor.main`, which bundles every basic
// language Monaco ships (abap … yaml) plus the JSON/CSS/HTML/TypeScript
// language services and their workers. This app only ever edits SPARQL, whose
// grammar we register ourselves in `sparqlLanguage.ts`, so none of that is
// reachable — it was roughly half a megabyte of dead chunks in `dist/`.
//
// `edcore.main` is Monaco's core editor: the same widgets, keybindings and
// contributions (suggest, hover, find, folding …) without any language. It
// re-exports `editor.api`, which is also where the type definitions live.
import 'monaco-editor/esm/vs/editor/edcore.main.js';

export * from 'monaco-editor/esm/vs/editor/editor.api';
