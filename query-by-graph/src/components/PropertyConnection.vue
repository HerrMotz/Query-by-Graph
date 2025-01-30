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
      <h3 v-if="value" class="font-bold font-mono w-32 -ml-16 bg-amber-50">
        {{value.prefix.abbreviation}}{{ value.prefix.abbreviation && ':'}}{{value.id}}
      </h3>
    </div>

  </div>
</template>

<script>
import {defineComponent} from 'vue'
import EntitySelector from "./EntitySelector.vue";
import {variableEntity} from "../lib/rete/constants.ts";

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
  mounted() {
    this.isMounted = true;
  },
  computed: {
    centerX() {
      return (this.end.x + this.start.x) / 2;
    },
    centerY() {
      return (this.end.y + this.start.y) / 2 - 20;
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
