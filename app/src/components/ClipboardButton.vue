<script setup lang="ts">
import {ClipboardDocumentIcon, ClipboardDocumentCheckIcon} from '@heroicons/vue/24/outline'
import {ref} from "vue";
const checked = ref(false);

const setCheckedForSomeSeconds = () => {
  checked.value = true;
  setTimeout(() => {
    checked.value = false;
  }, 2000);
}

</script>

<template>
  <button @click="setCheckedForSomeSeconds"
          :class="{ 'flex h-9 w-24 rounded-sm bg-amber-300 hover:bg-gray-200 items-center justify-center': true,
                    'text-green-700 underline': checked}">
    <span class="text-xs mr-1">Copy</span>
    <ClipboardDocumentCheckIcon v-if="checked" class="h-5 w-5" />
    <ClipboardDocumentIcon v-else class="h-5 w-5"/>
  </button>
</template>

<style scoped lang="scss">

</style>
