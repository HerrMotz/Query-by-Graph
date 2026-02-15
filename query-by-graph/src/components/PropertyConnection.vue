<template>
  <div class="z-10">
    <svg width="250" height="250" xmlns="http://www.w3.org/2000/svg">
      <!-- This highlights the path on selection -->
      <path :d="path"
            :class="[$props.data.selected ? 'hover:stroke-red-400 stroke-red-500' : 'hover:stroke-blue-400 stroke-blue-600']"/>
    </svg>
    <div class="absolute" :style="{transform: `translate(${centerX}px,${centerY}px)`}">
      <EntitySelector
          type="property"
          language="en"
          input-classes="w-32 -ml-16"
          dropdown-classes="w-80 -ml-40"
          @pointerdown.stop=""
          @dblclick.stop=""
          @selected-entity="(prop) => {value = prop; $emit('changedEntitySelector', value)}"
      />
      <h3 v-if="value" class="font-bold font-mono w-32 -ml-16 bg-amber-50">
        {{ value.label }}
      </h3>
      <h3 v-if="value" class="font-bold font-mono w-32 -ml-16 bg-amber-50 text-lg">
        {{value.prefix.abbreviation}}{{ value.prefix.abbreviation && ':'}}{{value.id}}
      </h3>
      <div v-if="isVariable" class="flex items-center mt-2 w-32 -ml-16 bg-amber-50 px-2 py-1" @click.stop @pointerdown.stop @mousedown.stop>
        <input
          type="checkbox"
          :id="`projection-property-${data.id}`"
          v-model="includeInProjection"
          class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
        />
        <label :for="`projection-property-${data.id}`" class="ml-2 text-sm font-medium text-gray-800 cursor-pointer">
          Select?
        </label>
      </div>
    </div>

  </div>
</template>

<script>
import {defineComponent} from 'vue'
import EntitySelector from "./EntitySelector.vue";

// This connection component has the following features:
// - it displays a label in the middle of the connection
// - the label container/border adjusts to the length of the label
// - it can be selected by clicking on it

export default defineComponent({
  name: "CustomConnection",
  components: {EntitySelector},
  props: ['data', 'start', 'end', 'path'],
  emits: ['changedEntitySelector'],
  data() {
    return {
      isMounted: false,
      value: this?.data?.property,
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
      return (this.end.y + this.start.y) / 2 - 20;
    },
    isVariable() {
      // Check if the property is a variable (starts with '?')
      const hasValue = this.value && typeof this.value === 'object';
      const hasId = hasValue && 'id' in this.value && typeof this.value.id === 'string';
      return hasId && this.value.id.startsWith('?');
    },
    includeInProjection: {
      get() {
        // Read from the property's selectedForProjection property (default to true if not set)
        return this.value?.selectedForProjection !== false;
      },
      set(value) {
        // Write to the property's selectedForProjection property
        if (this.value) {
          this.value.selectedForProjection = value;
          // Ensure the data.property is also updated
          if (this.data.property) {
            this.data.property.selectedForProjection = value;
          }
          // Emit change to notify the editor
          this.$emit('changedEntitySelector', this.value);
        }
      }
    }
  },
  watch: {
    // Watch for external changes to the property value
    'data.property': {
      handler(newValue) {
        if (newValue !== this.value) {
          this.value = newValue;
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
