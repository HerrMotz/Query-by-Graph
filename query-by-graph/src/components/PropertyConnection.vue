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
    <div class="absolute" :style="{transform: `translate(${centerX}px,${centerY}px)`}">
      <EntitySelector
          type="property"
          language="en"
          input-classes="w-32 -ml-16"
          :is-variable="isVariable"
          :is-selected="includeInProjection"
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
      <ProjectionCheckbox
          :id="`projection-property-${data.id}`"
          v-model="includeInProjection"
          :is-variable="isVariable"
          container-classes="w-32 -ml-16 bg-amber-50 px-2 py-1"
      />
    </div>

  </div>
</template>

<script>
import {defineComponent} from 'vue'
import EntitySelector from "./EntitySelector.vue";
import ProjectionCheckbox from "./ProjectionCheckbox.vue";
import {getEntityStyles} from "../lib/utils/entityStyles.ts";

// This connection component has the following features:
// - it displays a label in the middle of the connection
// - the label container/border adjusts to the length of the label
// - it can be selected by clicking on it

export default defineComponent({
  name: "CustomConnection",
  components: {EntitySelector, ProjectionCheckbox},
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
    entityStyles() {
      return getEntityStyles(this.isVariable, this.includeInProjection);
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
