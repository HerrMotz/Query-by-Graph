<template>
  <div>
    <EntitySelector type="item" language="en"
                    @pointerdown.stop=""
                    @selected-entity="handleEntitySelected"
    />
    <div v-if="isVariable" class="flex items-center mt-2 px-2" @click.stop @pointerdown.stop @mousedown.stop>
      <input
        type="checkbox"
        :id="`projection-${data.id}`"
        v-model="includeInProjection"
        @change="handleProjectionChange"
        class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
      />
      <label :for="`projection-${data.id}`" class="ml-2 text-sm font-medium text-white cursor-pointer">
        Select?
      </label>
    </div>
  </div>
</template>

<script>
import EntitySelector from "./EntitySelector.vue";

export default {
  components: {EntitySelector},
  props: ['data'],
  computed: {
    isVariable() {
      const val = this.data.value;
      const hasValue = val && typeof val === 'object';
      const hasId = hasValue && 'id' in val && typeof val.id === 'string';
      const variable = hasId && val.id.startsWith('?');
      console.log('isVariable re-evaluating:', variable, 'for entity:', val?.id);
      return variable;
    },
    includeInProjection: {
      get() {
        return this.data.value?.selectedForProjection !== false;
      },
      set(value) {
        if (this.data.value) {
          this.data.value.selectedForProjection = value;
          if (this.data.options?.change) {
            this.data.options.change(this.data.value);
          }
        }
      }
    }
  },
  methods: {
    handleEntitySelected(entity) {
      console.log('Entity selected in control:', entity.id);
      this.data.value = entity;

      if (this.data.options?.change) {
        this.data.options.change(entity);
      }
    },
    handleProjectionChange() {
      console.log('Projection changed:', this.includeInProjection);
    }
  },
  created() {
    const val = this.data.value || this.data.options?.initial;
    if (val) {
      this.data.value = val;
      if (this.data.value.selectedForProjection === undefined) {
        this.data.value.selectedForProjection = true;
      }
    }
  },
}
</script>