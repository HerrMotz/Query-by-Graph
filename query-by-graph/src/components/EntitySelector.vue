<script setup lang="ts">
import WikibaseDataService from "../lib/wikidata/WikibaseDataService.ts";
import {WikiDataEntity, WikiDataSearchApiResponse} from "../lib/types/WikibaseDataSource.ts";
import {computed} from 'vue';

const props = defineProps({
  language: {type: String, required: true},
  type: {type: String, required: true}, // will be passed to the wikidata query, can be e.g. "item" or "property"
  inputClasses: {type: String, required: false},
  dropdownClasses: {type: String, required: false}
});

const language = computed(() => selectedDataSource.value.preferredLanguages[0]);

// my local data type contains an ID and a label
// where the ID is the P or Q number
// and the label describes the entity

// so the wikidataentity.display.label.value is what I am looking for.

const emit = defineEmits<{
  selectedEntity: [EntityType] // named tuple syntax
}>();

import {ref} from 'vue'
import {CheckIcon, ChevronUpDownIcon} from '@heroicons/vue/20/solid'
import {
  Combobox,
  ComboboxButton,
  ComboboxInput,
  ComboboxLabel,
  ComboboxOption,
  ComboboxOptions,
} from '@headlessui/vue'
import EntityType from "../lib/types/EntityType.ts";
import {noEntity, variableEntity, variableEntityConstructor} from "../lib/rete/constants.ts";
import {selectedDataSource} from "../store.ts";

const queriedEntities = ref([
  noEntity,
  variableEntity
]);

const selectedEntity = ref(noEntity);

function displayValue(entity: unknown): string {
  if (typeof entity === 'object' && entity !== null && 'label' in entity) {
    return (entity as { label: string }).label;
  } else {
    return 'No label';
  }
}

function queryHelper(query: string) {
  console.log(`queryHelper called with query: "${query}"`);
  const wds = new WikibaseDataService(selectedDataSource.value);
  wds.queryWikidata({
    language: language.value,
    uselang: language.value,
    type: props.type,
    search: query
  }).then((data: WikiDataSearchApiResponse) => {
    queriedEntities.value = data.search.map((entity: WikiDataEntity) => {
      const prefix = props.type === 'item'
          ? selectedDataSource.value.itemPrefix
          : selectedDataSource.value.propertyPrefix

      return { // EntityType
        id: entity.id,
        label: entity.display.label.value,
        description: entity.display.description.value,
        prefix: {
          uri: prefix.iri,
          abbreviation: prefix.abbreviation,
        },
        dataSource: {...selectedDataSource.value} // save datasource
      }
    }).concat([
        variableEntityConstructor(query.startsWith('?') ? query.slice(1) : query)
    ]);
  }).catch(reason => {
    console.log(reason);
  });
}

function eventEmitEntityHelper(entity: EntityType) {
  console.log("Entity Selector emits event");
  console.log(entity)
  selectedEntity.value = entity;
  emit('selectedEntity', entity);
}
</script>

<template>
  <div>
    <h4 class="">
      <slot></slot>
    </h4>
    <Combobox as="div" :model-value="selectedEntity" @update:modelValue="($event) => eventEmitEntityHelper($event)">
      <ComboboxLabel class="block text-sm font-medium leading-6 text-gray-900"></ComboboxLabel>
      <div class="relative mt-2">
        <ComboboxInput
            :class="[
                'rounded-md border-0 bg-white py-1.5 pl-3 pr-12 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6',
                inputClasses ? inputClasses : 'w-full'
            ]"
            @change="queryHelper($event.target.value)"
            :display-value="displayValue"
        />
        <ComboboxButton class="absolute inset-y-0 right-0 flex items-center rounded-r-md px-2 focus:outline-none">
          <ChevronUpDownIcon class="h-5 w-5 text-gray-400" aria-hidden="true"/>
        </ComboboxButton>

        <ComboboxOptions v-if="queriedEntities.length > 0"
                         :class="[
                             'absolute z-10 mt-1 max-h-60 overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm',
                             dropdownClasses ? dropdownClasses : 'w-full'
                             ]">
          <ComboboxOption v-for="entity in queriedEntities" :key="entity.id" :value="entity" as="template"
                          v-slot="{ active, selected }">
            <li :class="['relative cursor-default select-none py-2 pl-3 pr-9', active ? 'bg-indigo-600 text-white' : 'text-gray-900']">
              <div class="flex">
              <span :class="['truncate', selected && 'font-semibold']">
                {{ entity.id }}
              </span>
                <span :class="['ml-2 truncate text-gray-500', active ? 'text-indigo-200' : 'text-gray-500']">
                {{ entity.label }}
              </span>
              </div>
              <div class="flex">
                <span :class="['ml-2 truncate text-gray-500', active ? 'text-indigo-200' : 'text-gray-500']">
                  {{ entity.description }}
                </span>
              </div>
              <span v-if="selected"
                    :class="['absolute inset-y-0 right-0 flex items-center pr-4', active ? 'text-white' : 'text-indigo-600']">
              <CheckIcon class="h-5 w-5" aria-hidden="true"/>
            </span>
            </li>
          </ComboboxOption>
        </ComboboxOptions>
      </div>
    </Combobox>
  </div>
</template>

<style scoped>

</style>
