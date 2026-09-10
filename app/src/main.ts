import { createApp } from 'vue'
import './style.css'
import App from './App.vue'

import { loader } from '@guolao/vue-monaco-editor'
import EditorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker'
import * as monaco from './lib/monaco/monaco.ts'
import { registerSparqlLanguage } from './lib/monaco/sparqlLanguage.ts'
import { registerSparqlTheme } from './lib/monaco/theme.ts'

// Use the bundled monaco instead of the CDN copy the loader would fetch, so
// that the theme, the SPARQL language and the language server providers
// registered here apply to the editor rendered by <vue-monaco-editor>.
(globalThis as any).MonacoEnvironment = {
    getWorker: () => new EditorWorker(),
};
loader.config({monaco});
registerSparqlLanguage();
registerSparqlTheme();

createApp(App).mount('#app')
