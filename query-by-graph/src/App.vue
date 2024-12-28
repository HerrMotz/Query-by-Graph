<script setup lang="ts">
import {onMounted, ref, shallowRef} from 'vue';
import {createEditor} from "./lib/rete/editor.ts";
import {ClassicPreset} from 'rete';

import {graph_to_query_wasm, query_to_graph_wasm} from "../pkg";

import {VueMonacoEditor} from '@guolao/vue-monaco-editor'
import * as monaco from "monaco-editor"

monaco.editor.defineTheme('custom-theme', {
  base: 'vs', // Use 'vs-light' as the base theme
  inherit: false, // Inherit other colors and styles from 'vs-light'
  rules: [], // Leave empty to inherit syntax highlighting from 'vs-light'
  colors: {
    "editor.background": "#ffffff00", // Fully transparent background
    "editor.foreground": "#BDAE9D",
    "editor.selectionBackground": "#e9ffc3",
    "editor.lineHighlightBackground": "#3A312C",
    "editorCursor.foreground": "#889AFF",
    "editorWhitespace.foreground": "#BFBFBF",
    "editorIndentGuide.background": "#5e81ce52",
    "editor.selectionHighlightBorder": "#122d42",
    'editor.inactiveSelectionBackground': '#ff000066',
    'editor.selectionHighlight': '#00ff0066',
  }
});

const codeEditorRef = shallowRef();
const handleMount = (codeEditor: any) => {
  codeEditorRef.value = codeEditor;

  // Set the theme explicitly on mount
  monaco.editor.setTheme('custom-theme');
};

const MONACO_EDITOR_OPTIONS = {
  automaticLayout: true,
  formatOnType: true,
  formatOnPaste: true,
}

// your action
function formatCode() {
  codeEditorRef.value?.getAction('editor.action.formatDocument').run()
}

import Button from "./components/Button.vue";
import ConnectionInterfaceType from "./lib/types/ConnectionInterfaceType.ts";
import ClipboardButton from "./components/ClipboardButton.vue";
import QueryButton from './components/QueryButton.vue';
import WikibaseDataService from './lib/wikidata/WikibaseDataService.ts';
import {selectedDataSource, dataSources} from './store.ts';
import {WikibaseDataSource} from "./lib/types/WikibaseDataSource.ts";
import {debounce} from "./lib/utils";


interface Editor {
  setVueCallback: (callback: (context: any) => void) => void;
  removeSelectedConnections: () => Promise<void>;
  undo: () => void;
  redo: () => void;
  importConnections: (connections: ConnectionInterfaceType[]) => Promise<Promise<true>[] | undefined>;
  exportConnections: () => ConnectionInterfaceType[];
  layout: (animate: boolean) => void;
  getNode: (nodeId: string) => ClassicPreset.Node | undefined;
}

const editor = ref<Editor | null>();  // Define the type of editor as Promise<Editor> | null
const rete = ref();

const code = ref("");
const loadingForCodeChanges = ref(false);

function codeChangeEvent() {
  if (editor.value) {
    console.log("code changed")
    // if the code value is not empty but the returned connection array is,
    // then there is probably a syntax error.
    // in this case, do not import the connections
    const graph = JSON.parse(query_to_graph_wasm(code.value));
    if (!!code.value && !!graph && graph?.length > 0) {
      console.log("graph", graph)
      loadingForCodeChanges.value = true;
      editor.value.importConnections(graph).then(ps => {
        if (ps) {
          Promise.all(ps).then(_ => {
            loadingForCodeChanges.value = false;
          })
        } else {
          console.error("There was an error while building the new graph");
          loadingForCodeChanges.value = false;
        }

      });
    } else {
      // DEBUG
      console.log("Query is probably faulty. Doing nothing.");
    }
  }
}

const debouncedCodeChangeEvent = debounce(codeChangeEvent, 1000);

const selectedNode = ref<{ id: any; label: any; entityId: any; metadata: any; dataSource: any } | null>(null);


// for listening to the EntitySelector
// DEBUG
const triggerEvents = [
  "connectioncreated",
  "connectionremoved",
  "nodecreated",
  "rendered"
]

onMounted(async () => {
  if (rete.value) {
    editor.value = await createEditor(rete.value);
    editor.value?.setVueCallback((context) => { // add pipe to parent scope
      if (triggerEvents.includes(context.type)) {
        setTimeout(() => {
          const connections = editor.value!.exportConnections()
          // DEBUG
          console.log("The connections in App.vue")
          console.log(connections)
          code.value = graph_to_query_wasm(JSON.stringify(connections));
          formatCode();
        }, 10);
      }

      // Fill the metainfo window with the selected node's data
      if (context.type === 'nodeselected') {
        const nodeId = context.data.id;
        const node = editor.value?.getNode(nodeId);

        if (node) {
          const item = (node as any).entity;
          const itemId = item.id; // Q number
          const label = item.label; // Label from Wikidata
          const dataSource = item.dataSource;

          // everything but metadata is for debugging, can be removed later
          selectedNode.value = {
            id: nodeId,
            label: label,
            entityId: itemId,
            dataSource: dataSource,
            metadata: null,
          };

          // extract relevant Metadata from wikidata
          if (!itemId.startsWith('?')) {
            const wds = new WikibaseDataService(dataSource);
            wds.getItemMetaInfo(itemId).then((metadata) => {
              selectedNode.value!.metadata = metadata;
            });

            // DEBUG
            console.log('Selected Entity ID:', itemId);
          }
        }
      }
    });
  }
});

const copyToClipboard = () => {
  navigator.clipboard.writeText(code.value);
}

const setDataSource = (source: WikibaseDataSource) => {
  if (source) {
    selectedDataSource.value = source;
    console.log('selectedDataSource updated to:', selectedDataSource.value);
  }
};

const gotoLink = (url?: string) => {
  const link = url || window.location.href;
  window.open(link, '_blank');
}


</script>

<template>
  <div>
    <div class="place-items-center bg-white px-6 pb-24 pt-12 sm:pb-2 sm:pt-6 lg:px-8">
      <div class="text-5xl text-center mb-4 font-serif font-bold italic">Query by Graph</div>
      <p class="text-center font-medium text-gray-500 text-sm mb-6 w-[550px] mx-auto">
        This program allows you to build a SPARQL query using visual elements.
        Press RMB on the canvas to create a new individual and LMB on an individual's socket to create a connection.
        You can delete an individual by pressing RMB on it.
      </p>
      <div class="flex w-full bg-amber-100 rounded-2xl h-[65vh]">
        <div class="w-2/12 bg-amber-50 rounded-tl-2xl h-full">
          <h2 class="text-xl font-semibold bg-amber-100 p-4">
            Metainfo
            <span v-if="selectedNode?.dataSource?.name"
                  class="inline"> (from {{ selectedNode.dataSource.name }}) </span>
          </h2>
          <!-- Metainfowindow content -->
          <div class="p-4 overflow-auto max-h-[90%]">
            <!-- Display when a node is selected -->
            <div v-if="selectedNode">
              <div v-if="selectedNode.metadata">
                <!-- Labels Section -->
                <h3 class="text-lg font-bold mb-2">Labels:</h3>
                <ul class="list-disc pl-6 mb-4">
                  <li v-for="(label, lang) in selectedNode.metadata.labels" :key="lang">
                    <span class="font-medium">{{ label.value }} </span>
                  </li>
                </ul>

                <!-- Descriptions Section -->
                <h3 class="text-lg font-bold mb-2">Descriptions:</h3>
                <ul class="list-disc pl-6 mb-4">
                  <li v-for="(description, lang) in selectedNode.metadata.descriptions" :key="lang">
                    <span class="font-medium">{{ description.value }}</span>
                  </li>
                </ul>

                <img v-if="selectedNode.metadata.image" :src="selectedNode.metadata.image" alt="Entity Image"/>


                <!-- Claims Section -->
                <h3 class="text-lg font-bold mb-2">Claims:</h3>
                <div class="space-y-4">
                  <div v-for="(claims, property) in selectedNode.metadata.claims" :key="property" class="border-t pt-2">
                    <h4 class="text-md font-semibold mb-1">{{ property }}</h4>
                    <ul class="list-disc pl-6">
                      <li v-for="claim in claims" :key="claim.id">
                        {{ claim.mainsnak.datavalue?.value || 'No value available' }}
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>

            <!-- Fallback when no node is selected -->
            <p v-else class="text-gray-500">
              No node selected.
            </p>
          </div>

        </div>
        <div class="w-8/12 bg-amber-50 rounded-tl-2xl h-full">
          <h2 class="text-xl font-semibold bg-amber-100 p-4">
            <!-- This has the same propeties as the toolbox heading -->
            Visual Query Builder
            <span class="text-sm ml-2 font-medium">
              Each Box is a SPARQL-Individual and each Connection between them is a SPARQL-Property
            </span>
          </h2>
          <div ref="rete" class="h-[90%]"></div>
        </div>
        <div v-if="editor" class="w-2/12 overflow-auto rounded-tr-2xl h-full">
          <h2 class="text-xl font-semibold bg-amber-200 p-4">
            Toolbox
            <span class="text-sm ml-2 font-medium">
              Perform actions on the graph
            </span>
          </h2>
          <div class="flex-col flex gap-6 p-4">
            <div class="flex-col flex gap-2">
              <h4 class="font-semibold">History</h4>
              <div class="flex gap-4">
                <Button class="grow" @click="() => {
                if (editor) {
                  editor.undo();
                }
              }">
                  Undo
                  <kbd
                      class="inline-flex items-center rounded border border-gray-200 px-1 font-sans text-xs text-gray-200">CTRL+Y</kbd>
                </Button>
                <Button class="grow" @click="() => {
                if (editor) {
                  editor.redo();
                }
              }">

                  Redo
                  <kbd
                      class="inline-flex items-center rounded border border-gray-200 px-1 font-sans text-xs text-gray-200">CTRL+Z</kbd>
                </Button>
              </div>
            </div>

            <div class="flex-col flex gap-2">
              <h4 class="font-semibold">Arrangement</h4>
              <div class="flex gap-4">
                <Button class="grow" @click="() => {if (editor) {editor.layout(true)}}">
                  Auto-Arrange the graph
                </Button>
              </div>
            </div>

            <!-- Data Source Selector -->
            <div class="flex-col flex gap-2">
              <h4 class="font-semibold">Data Source</h4>
              <div class="flex gap-4">
                <Button
                    v-for="ds in dataSources"
                    :class="{'highlighted': selectedDataSource.name === ds.name}"
                    @click="setDataSource(ds)">
                  Use {{ ds.name }}
                </Button>
              </div>
              <p class="text-gray-600 text-sm hover:text-gray-900 transition-all">
                <em>Hint:</em>
                Select a data source by clicking one of the buttons above.
              </p>
            </div>
            <div class="flex-col flex gap-2">
              <h4 class="font-semibold">Delete selected connections</h4>
              <Button
                  @click="() => { // why the hell is this necessary in TypeScript with Vue3 D':
                if (editor) {
                  editor.removeSelectedConnections();
                }
              }">
                Delete selected
              </Button>
              <p class="text-gray-600 text-sm hover:text-gray-900 transition-all">
                <em>Hint:</em>
                Select a connection by clicking on it and then click the button above to delete it.
                This only works when at least one connection is selected (red).
              </p>
            </div>
            <div class="flex-col flex gap-2">
              <h4 class="font-semibold">Open new query builder</h4>
              <Button
                  @click="gotoLink()">
                Open builder
              </Button>
              <p class="text-gray-600 text-sm hover:text-gray-900 transition-all">
                <em>Hint:</em>
                Open a new window for building another graph without deleting the current one.
              </p>
              <p class="text-gray-600 text-sm hover:text-gray-900 transition-all">


              </p>
            </div>
          </div>
        </div>
      </div>
      <div class="mt-10 w-full">
        <div class="bg-amber-100 rounded-t-2xl p-4">
          <!-- This has the same propeties as the toolbox heading -->
          <h2 class="font-semibold text-xl flex justify-between">
            <span>
              Generated SPARQL Query
              <span v-if="loadingForCodeChanges">
                <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-green-600" xmlns="http://www.w3.org/2000/svg" fill="none"
                     viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              </span>
            </span>
            <span class="flex items-center space-x-2">
              <ClipboardButton @click="copyToClipboard();"/>
              <QueryButton @click="gotoLink(selectedDataSource.queryService+'#'+encodeURIComponent(code));"/>
            </span>
          </h2>
          <span>

          </span>
          <span class="text-sm font-medium block">
                This contains the generated SPARQL code. It is updated with every change in the editor.
          </span>
        </div>
        <div class="bg-amber-50 flex w-full flex-row">
          <vue-monaco-editor
              v-model:value="code"
              class="min-h-[30vh] bg-amber-50"
              theme="custom-theme"
              language="sparql"
              :options="MONACO_EDITOR_OPTIONS"
              @mount="handleMount"
              @change="debouncedCodeChangeEvent()"
          />
        </div>
        <div>
          asd
        </div>
      </div>

    </div>
    <div>
      <!-- Footer -->
      <div class="text-center text-gray-600 text-sm mt-10 pb-12">
        <p>
          <a class="underline" href="https://github.com/HerrMotz/bachelor-thesis/">Repository</a> &middot;
          Made with ❤️ by <a class="underline" href="https://www.daniel-motz.de">Daniel Motz</a>
        </p>
      </div>
    </div>
  </div>
</template>

<style>
.highlighted {
  background-color: #28a745;
  color: #ffffff;
}
</style>
