<template>
  <div>
    <EntitySelector type="item" language="en"
                    :is-variable="isVariable"
                    :is-selected="includeInProjection"
                    :is-literal="isLiteral"
                    :initial-selection="data.value"
                    @pointerdown.stop=""
                    @selected-entity="handleEntitySelected"
    />
    <ProjectionCheckbox
        v-if="isVariable"
        :id="`projection-${data.id}`"
        v-model="includeInProjection"
        :is-variable="isVariable"
        container-classes="px-2"
        label-classes="text-white"
    />
  </div>
</template>

<script>
import EntitySelector from "./EntitySelector.vue";
import ProjectionCheckbox from "./ProjectionCheckbox.vue";

export default {
  components: {EntitySelector, ProjectionCheckbox},
  props: ['data'],
  computed: {
    isLiteral() {
      return this.data.value?.isLiteral === true;
    },
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