import
{defineConfig} from 'vite';
import vue from '@vitejs/plugin-vue'; 
import wasm from "vite-plugin-wasm"; 
// @ts-ignore — package exports map doesn't expose types but the runtime import is correct
import topLevelAwait from "vite-plugin-top-level-await";

// https://vitejs.dev/config/ 
export default defineConfig(
  {
      plugins: [vue(), wasm(), topLevelAwait()],
  })