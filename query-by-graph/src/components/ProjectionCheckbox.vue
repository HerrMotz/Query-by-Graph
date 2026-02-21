<template>
  <div v-if="isVariable" :class="['flex items-center mt-2', containerClasses]" @click.stop @pointerdown.stop @mousedown.stop>
    <input
      type="checkbox"
      :id="id"
      :checked="modelValue"
      @change="$emit('update:modelValue', ($event.target as HTMLInputElement).checked)"
      class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 focus:ring-2"
    />
    <label :for="id" :class="['ml-2 text-sm font-medium cursor-pointer', labelClasses]">
      {{ label }}
    </label>
  </div>
</template>

<script setup lang="ts">
defineProps({
  modelValue: {
    type: Boolean,
    required: true
  },
  id: {
    type: String,
    required: true
  },
  isVariable: {
    type: Boolean,
    default: false
  },
  label: {
    type: String,
    default: 'Select?'
  },
  containerClasses: {
    type: String,
    default: ''
  },
  labelClasses: {
    type: String,
    default: 'text-gray-800'
  }
});

defineEmits(['update:modelValue']);
</script>
