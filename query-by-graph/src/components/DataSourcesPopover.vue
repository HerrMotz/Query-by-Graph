<template>
  <TransitionRoot as="template" :show="localOpen">
    <Dialog class="relative z-10" @close="localOpen = false">
      <TransitionChild
          as="template"
          enter="ease-out duration-300"
          enter-from="opacity-0"
          enter-to="opacity-100"
          leave="ease-in duration-200"
          leave-from="opacity-100"
          leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-gray-500/75 transition-opacity" />
      </TransitionChild>

      <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <TransitionChild
              as="template"
              enter="ease-out duration-300"
              enter-from="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              enter-to="opacity-100 translate-y-0 sm:scale-100"
              leave="ease-in duration-200"
              leave-from="opacity-100 translate-y-0 sm:scale-100"
              leave-to="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          >
            <DialogPanel class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-7xl sm:p-6">
              <div class="absolute right-0 top-0 hidden pr-4 pt-4 sm:block">
                <button type="button" class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" @click="localOpen = false">
                  <span class="sr-only">Close</span>
                  <XMarkIcon class="size-6" aria-hidden="true" />
                </button>
              </div>
              <div class="mb-4">
                <DialogTitle as="h3" class="text-xl font-semibold text-gray-900">
                  Manage Data Sources
                </DialogTitle>
              </div>

              <!-- Data Sources List -->
              <div class="mb-6 overflow-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead>
                  <tr>
                    <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Name</th>
                    <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">API URL</th>
                    <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Preferred Languages</th>
                    <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Item Prefix (IRI / Abbr.)</th>
                    <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Property Prefix (IRI / Abbr.)</th>
                    <th class="px-4 py-2 text-left text-sm font-medium text-gray-700">Query Service</th>
                    <th class="px-4 py-2"></th>
                  </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-200">
                  <tr v-for="(source, index) in dataSources" :key="index">
                    <td class="px-4 py-2 text-sm text-gray-900">{{ source.name }}</td>
                    <td class="px-4 py-2 text-sm text-gray-900">{{ source.uri }}</td>
                    <td class="px-4 py-2 text-sm text-gray-900">{{ source.preferredLanguages.join(', ') }}</td>
                    <td class="px-4 py-2 text-sm text-gray-900">
                      {{ source.itemPrefix.iri }} / {{ source.itemPrefix.abbreviation }}:
                    </td>
                    <td class="px-4 py-2 text-sm text-gray-900">
                      {{ source.propertyPrefix.iri }} / {{ source.propertyPrefix.abbreviation }}:
                    </td>
                    <td class="px-4 py-2 text-sm text-gray-900">{{ source.queryService }}</td>
                    <td class="px-4 py-2">
                      <button
                          class="text-red-600 hover:text-red-900 text-sm"
                          @click="deleteDataSource(index)"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                  </tbody>
                </table>
              </div>

              <!-- Add New Data Source Form -->
              <div class="mb-4">
                <h4 class="text-lg font-medium text-gray-900 mb-2">Add New Data Source</h4>
                <p class="mb-4">
                  <i>Hint:</i> Use the Wikibase "manifest.json" file of your desired data source configure data sources.
                  Example <a href="https://database.factgrid.de/factgrid-manifest.json">https://database.factgrid.de/factgrid-manifest.json</a>.
                </p>
                <div class="grid grid-cols-1 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Name</label>
                    <input
                        v-model="newDataSource.name"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="Name"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">API base URL</label>
                    <input
                        v-model="newDataSource.uri"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="https://www.wikidata.org/w/api.php"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">
                      Preferred Languages (comma separated)
                    </label>
                    <input
                        v-model="newPreferredLanguages"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="de,en,fr"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Item Prefix IRI</label>
                    <input
                        v-model="newDataSource.itemPrefix.iri"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="http://www.wikidata.org/entity/"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">
                      Item Prefix Abbreviation
                    </label>
                    <input
                        v-model="newDataSource.itemPrefix.abbreviation"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="wd"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Property Prefix IRI</label>
                    <input
                        v-model="newDataSource.propertyPrefix.iri"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="http://www.wikidata.org/prop/direct/"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">
                      Property Prefix Abbreviation
                    </label>
                    <input
                        v-model="newDataSource.propertyPrefix.abbreviation"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="wdt"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700">Query Service</label>
                    <input
                        v-model="newDataSource.queryService"
                        type="text"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm"
                        placeholder="https://query.wikidata.org/"
                    />
                  </div>
                </div>
                <div class="mt-4">
                  <Button @click="addDataSource">
                    Add Data Source
                  </Button>
                  <Button class="ml-6" @click="resetDataSources">
                    Reset Data Sources to Default
                  </Button>
                </div>
              </div>
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup>
import {ref, watchEffect} from 'vue'
import { XMarkIcon } from '@heroicons/vue/24/outline'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import {addDataSourceToStorage, dataSources, deleteDataSourceFromStorage, resetDataSourceToDefault} from "../store";
import Button from "./Button.vue";

// Accept boolean open as a prop
const { open } = defineProps({
  open: Boolean
});

const localOpen = ref(open);

watchEffect(() => {
  // runs only once before 3.5
  // re-runs when the "foo" prop changes in 3.5+
  localOpen.value = open;
})

// Object for the new data source form
const newDataSource = ref({
  name: '',
  uri: '',
  preferredLanguages: [],
  itemPrefix: {
    iri: '',
    abbreviation: ''
  },
  propertyPrefix: {
    iri: '',
    abbreviation: ''
  },
  queryService: ''
})

// Temporary input for comma-separated preferred languages
const newPreferredLanguages = ref('')

// Function to add a new data source
function addDataSource() {
  // Parse preferred languages from comma-separated input
  newDataSource.value.preferredLanguages = newPreferredLanguages.value
      .split(',')
      .map(lang => lang.trim())
      .filter(lang => lang)

  // Add a copy of the new data source to the array
  addDataSourceToStorage(dataSources, newDataSource.value);

  // Reset the form
  newDataSource.value = {
    name: '',
    uri: '',
    preferredLanguages: [],
    itemPrefix: {
      iri: '',
      abbreviation: ''
    },
    propertyPrefix: {
      iri: '',
      abbreviation: ''
    },
    queryService: ''
  }
  newPreferredLanguages.value = ''
}

// Function to delete a data source by its index
function deleteDataSource(index) {
  deleteDataSourceFromStorage(index);
}

function resetDataSources() {
  resetDataSourceToDefault();
}

</script>
