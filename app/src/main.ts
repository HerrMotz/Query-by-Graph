import { createApp } from 'vue'
import './style.css'
import App from './App.vue'

import * as monaco from 'monaco-editor'
import { loader } from '@guolao/vue-monaco-editor'
import EditorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker'
import { registerSparqlLanguage } from './lib/monaco/sparqlLanguage.ts'

import hljs from 'highlight.js/lib/core';
import hljsDefineSparql from './lib/highlight/sparql.ts';
import hljsVuePlugin from "./lib/highlight/component.ts";

hljs.registerLanguage('sparql', hljsDefineSparql);

// Use the bundled monaco instead of the CDN copy the loader would fetch, so
// that the theme, the SPARQL language and the language server providers
// registered here apply to the editor rendered by <vue-monaco-editor>.
(globalThis as any).MonacoEnvironment = {
    getWorker: () => new EditorWorker(),
};
loader.config({monaco});
registerSparqlLanguage();

const app = createApp(App)
app.use(hljsVuePlugin)
app.mount('#app')
