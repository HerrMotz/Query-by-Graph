<template>
  <div class="z-10">
    <svg width="250" height="250" xmlns="http://www.w3.org/2000/svg">
      <!-- This highlights the path on selection -->
      <!-- Todo: the arrowhead should also change color on selection, currently it does not -->
      <path :d="path"
            :class="[
                $props.data.selected ? 'hover:stroke-red-400 stroke-red-500' : `${entityStyles.connectionHover} ${entityStyles.connection}`
            ]"/>
    </svg>
    <div class="absolute flex flex-col items-center" :style="{transform: `translate(calc(${centerX}px - 50%), calc(${centerY}px - 50%))`}">
      <!-- Alternation Header -->
      <div v-if="isAlternation" class="bg-amber-100 px-2 py-1 rounded-t-md border-x border-t border-amber-300 flex items-center justify-between w-40">
        <span class="text-xs font-bold uppercase text-amber-800">Alternation (+)</span>
        <button @click.stop="toggleAlternation" class="text-amber-600 hover:text-amber-800">
          <XMarkIcon class="h-4 w-4" />
        </button>
      </div>

      <!-- List of Properties -->
      <div :class="['flex flex-col gap-2 p-2 bg-amber-50 border border-amber-200 shadow-sm rounded-md', isAlternation ? 'rounded-t-none border-t-0' : '']">
        <div v-for="(prop, index) in propertiesList" :key="index" class="flex flex-col items-center">
          <div class="flex items-center gap-1">
            <EntitySelector
                type="property"
                language="en"
                input-classes="w-32"
                :is-variable="isPropVariable(prop)"
                :is-selected="isPropSelected(prop)"
                :initial-selection="prop"
                dropdown-classes="w-80 -ml-24"
                @pointerdown.stop=""
                @dblclick.stop=""
                @selected-entity="(selectedProp) => updateProperty(index, selectedProp)"
            />
            <button v-if="isAlternation" @click.stop="removeProperty(index)" class="p-1 text-red-500 hover:bg-red-50 rounded">
              <TrashIcon class="h-4 w-4" />
            </button>
          </div>

          <div v-if="prop && prop.id" class="mt-1 text-center">
            <h3 class="font-bold font-mono text-xs truncate w-32">
              {{ prop.label }}
            </h3>
            <h3 class="font-bold font-mono text-xs text-gray-600">
              {{ prop.prefix.abbreviation }}{{ prop.prefix.abbreviation && ':' }}{{ prop.id }}
            </h3>
          </div>
        </div>

        <!-- Add Property Button -->
        <button @click.stop="addPropertyToPath" class="mt-1 flex items-center justify-center gap-1 px-2 py-1 bg-white border border-amber-300 rounded hover:bg-amber-100 text-xs font-medium transition-colors">
          <span>{{ isAlternation ? 'Add Alternative' : 'Property Path' }}</span>
        </button>

        <ProjectionCheckbox
            v-if="!isAlternation"
            :id="`projection-property-${data.id}`"
            v-model="includeInProjection"
            :is-variable="isVariable"
            container-classes="mt-1"
        />
      </div>
    </div>

  </div>
</template>

<script>
import {defineComponent} from 'vue'
import EntitySelector from "./EntitySelector.vue";
import ProjectionCheckbox from "./ProjectionCheckbox.vue";
import {getEntityStyles} from "../lib/utils/entityStyles.ts";
import { PlusIcon, TrashIcon, XMarkIcon } from '@heroicons/vue/20/solid'
import {noEntity} from "../lib/rete/constants.ts";

// This connection component has the following features:
// - it displays a label in the middle of the connection
// - the label container/border adjusts to the length of the label
// - it can be selected by clicking on it

export default defineComponent({
  name: "CustomConnection",
  components: {EntitySelector, ProjectionCheckbox, PlusIcon, TrashIcon, XMarkIcon},
  props: ['data', 'start', 'end', 'path', 'seed'],
  emits: ['changedEntitySelector'],
  data() {
    return {
      isMounted: false,
      value: this?.data?.properties?.[0],
    }
  },
  created() {
    // Initialize selectedForProjection to true if not set
    if (this.value && this.value.selectedForProjection === undefined) {
      this.value.selectedForProjection = true;
    }
  },
  mounted() {
    this.isMounted = true;
  },
  computed: {
    centerX() {
      return (this.end.x + this.start.x) / 2;
    },
    centerY() {
      return (this.end.y + this.start.y) / 2;
    },
    isAlternation() {
      return this.value?.pathType === 'alternation';
    },
    propertiesList() {
      if (this.isAlternation) {
        return this.value.properties || [];
      }
      return [this.value];
    },
    isVariable() {
      // Use seed to force re-computation when area.update is called
      this.seed;
      // Check if the property is a variable (starts with '?')
      return this.isPropVariable(this.value);
    },
    entityStyles() {
      return getEntityStyles(this.isVariable, this.includeInProjection);
    },
    includeInProjection: {
      get() {
        // Use seed to force re-computation when area.update is called
        this.seed;
        // Read from the property's selectedForProjection property (default to true if not set)
        return this.value?.selectedForProjection !== false;
      },
      set(value) {
        // Write to the property's selectedForProjection property
        if (this.value) {
          this.value.selectedForProjection = value;
          // Ensure the data.properties is also updated
          if (this.data.properties && this.data.properties[0]) {
            this.data.properties[0].selectedForProjection = value;
          }
          // Emit change to notify the editor
          this.$emit('changedEntitySelector', this.value);
        }
      }
    },
    alternationLabel() {
      if (!this.isAlternation || !this.value.properties) return 'Property Path';
      
      return this.value.properties
        .map(prop => {
          if (this.isPropVariable(prop)) {
            return prop.id;
          }
          return prop.label || prop.id || '...';
        })
        .join('|');
    }
  },
  methods: {
    isPropVariable(prop) {
      const hasValue = prop && typeof prop === 'object';
      const hasId = hasValue && 'id' in prop && typeof prop.id === 'string';
      return hasId && prop.id.startsWith('?');
    },
    isPropSelected(prop) {
      return prop?.selectedForProjection !== false;
    },
    updateProperty(index, selectedProp) {
      if (this.isAlternation) {
        const newProperties = [...this.value.properties];
        newProperties[index] = selectedProp;
        this.value = {
          ...this.value,
          properties: newProperties
        };
        // Update label to reflect new property
        this.value.label = this.alternationLabel;
      } else {
        this.value = selectedProp;
      }
      this.$emit('changedEntitySelector', this.value);
    },
    addPropertyToPath() {
      if (this.isAlternation) {
        // Add another one to the list
        const newProperties = [...this.value.properties, { ...noEntity }];
        this.value = {
          ...this.value,
          properties: newProperties
        };
        // Update label
        this.value.label = this.alternationLabel;
      } else {
        // Convert single property to alternation
        const currentProp = this.value || { ...noEntity };
        const alternationValue = {
          id: 'path',
          label: '', // Will be set below
          prefix: { iri: '', abbreviation: '' },
          pathType: 'alternation',
          modifier: '+',
          properties: [currentProp, { ...noEntity }]
        };
        
        // Use computed property to get the correct label
        // We need to set it on a temporary object or use a helper because this.value is not yet updated
        alternationValue.label = alternationValue.properties
          .map(prop => this.isPropVariable(prop) ? prop.id : (prop.label || prop.id || '...'))
          .join('|');
          
        this.value = alternationValue;
      }
      this.$emit('changedEntitySelector', this.value);
    },
    removeProperty(index) {
      if (!this.isAlternation) return;

      const newProperties = this.value.properties.filter((_, i) => i !== index);
      
      if (newProperties.length <= 1) {
        // Convert back to single property
        this.value = newProperties[0] || { ...noEntity };
      } else {
        this.value = {
          ...this.value,
          properties: newProperties
        };
        // Update label
        this.value.label = this.alternationLabel;
      }
      this.$emit('changedEntitySelector', this.value);
    },
    toggleAlternation() {
      if (this.isAlternation) {
        // Convert back to the first property in the list
        this.value = this.value.properties[0] || { ...noEntity };
        this.$emit('changedEntitySelector', this.value);
      }
    }
  },
  watch: {
    // Watch for external changes to the property value
    'data.properties': {
      handler(newValue) {
        if (newValue && newValue[0] && newValue[0] !== this.value) {
          this.value = newValue[0];
        }
      },
      deep: true,
      immediate: true
    }
  }
})
</script>

<style lang="scss" scoped>
svg {
  overflow: visible !important;
  position: absolute;
  pointer-events: none;
  width: 9999px;
  height: 9999px;

  path {
    fill: none;
    stroke-width: 5px;
    pointer-events: auto;
  }
}
</style>
