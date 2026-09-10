import {defineConfig} from 'vite';
import vue from '@vitejs/plugin-vue';
import wasm from "vite-plugin-wasm";

// https://vitejs.dev/config/
export default defineConfig(
  {
      plugins: [vue(), wasm()],
      // The Qlue-ls language server is WASM and runs inside a web worker,
      // so the worker bundle needs the wasm plugin as well.
      worker: {
          format: 'es',
          plugins: () => [wasm()],
      },
      optimizeDeps: {
          // pre-bundling would break the wasm-bindgen glue of qlue-ls
          exclude: ['qlue-ls'],
      },
  })
