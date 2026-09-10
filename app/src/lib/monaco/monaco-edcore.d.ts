// `edcore.main.js` is imported for its side effects only (it registers the
// editor contributions); Monaco ships no declaration file for that path, and
// the types come from `editor.api` next to it.
declare module 'monaco-editor/esm/vs/editor/edcore.main.js';
