<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  color?: 'indigo' | 'red' | 'green' | 'blue' | 'yellow' | 'purple' | 'pink' | 'gray';
  active?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  color: 'indigo',
  active: false,
});

const buttonClasses = computed(() => {
  if (props.active) {
    return 'bg-green-600 hover:bg-green-500 focus-visible:outline-green-500';
  }

  const colorMap = {
    indigo: 'bg-indigo-600 hover:bg-indigo-500 focus-visible:outline-indigo-600 disabled:bg-indigo-300',
    red: 'bg-red-600 hover:bg-red-500 focus-visible:outline-red-600 disabled:bg-red-300',
    green: 'bg-green-600 hover:bg-green-500 focus-visible:outline-green-600 disabled:bg-green-300',
    blue: 'bg-blue-600 hover:bg-blue-500 focus-visible:outline-blue-600 disabled:bg-blue-300',
    yellow: 'bg-yellow-600 hover:bg-yellow-500 focus-visible:outline-yellow-600 disabled:bg-yellow-300',
    purple: 'bg-purple-600 hover:bg-purple-500 focus-visible:outline-purple-600 disabled:bg-purple-300',
    pink: 'bg-pink-600 hover:bg-pink-500 focus-visible:outline-pink-600 disabled:bg-pink-300',
    gray: 'bg-gray-600 hover:bg-gray-500 focus-visible:outline-gray-600 disabled:bg-gray-300',
  };

  return colorMap[props.color];
});
</script>

<template>
  <button
    type="button"
    class="disabled:text-indigo-50 rounded-md px-3.5 py-2.5 text-sm font-semibold text-white shadow-xs focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
    :class="buttonClasses"
  >
    <slot></slot>
  </button>
</template>