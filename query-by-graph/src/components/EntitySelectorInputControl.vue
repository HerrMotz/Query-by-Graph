<template>
  <div>
    <EntitySelector type="item" language="en"
                    @pointerdown.stop=""
                    @selected-entity="handleEntitySelected"
    />
    <div v-if="isVariable" class="flex items-center mt-2 px-2">
      <input
        type="checkbox"
        :id="`projection-${data.id}`"
        v-model="includeInProjection"
        @change="handleProjectionChange"
        class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
      />
      <label :for="`projection-${data.id}`" class="ml-2 text-sm font-medium text-white">
        Include in SELECT
      </label>
    </div>
  </div>
</template>

<script>
import EntitySelector from "./EntitySelector.vue";

export default {
  components: {EntitySelector},
  props: ['data'],
  data() {
    return {
      includeInProjection: true,
      controlValue: this.data?.value || this.data?.options?.initial
    }
  },
  computed: {
    isVariable() {
      // Access the control's value via the local controlValue that's kept in sync
      const hasValue = this.controlValue && typeof this.controlValue === 'object';
      const hasId = hasValue && 'id' in this.controlValue && typeof this.controlValue.id === 'string';
      const result = hasId && this.controlValue.id.startsWith('?');
      return result;
    }
  },
  methods: {
    handleEntitySelected(entity) {
      // Update both the control's value and the local reactive copy
      this.controlValue = entity;
      this.data.value = entity;

      // Trigger the change callback
      if (this.data.options.change) {
        this.data.options.change(entity);
      }
    },
    handleProjectionChange() {
      // This could be used to trigger updates if needed
      console.log('Projection changed:', this.includeInProjection);
    }
  },
  watch: {
    // Watch for external changes to the control's value
    'data.value': {
      handler(newValue) {
        if (newValue !== this.controlValue) {
          this.controlValue = newValue;
        }
      },
      deep: true,
      immediate: true
    }
  },
  created() {
    // Initialize the control's value, prioritizing actual value over initial
    const initialValue = this.data.value || this.data.options?.initial;
    if (initialValue) {
      this.controlValue = initialValue;
      // Ensure data.value is set if it wasn't already
      if (!this.data.value) {
        this.data.value = initialValue;
      }
    }
  },
}
</script>