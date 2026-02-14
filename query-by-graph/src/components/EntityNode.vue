<template>
  <div class="node bg-indigo-300 hover:bg-indigo-400"
       :class="{
         selected: data.selected,
         'bg-violet-400 hover:bg-violet-500': data?.entity?.id.startsWith('?'),
         'projection-selected': isVariableSelectedForProjection
       }"
       :style="nodeStyles"
       data-testid="node">
    <div class="p-2">
      <h1 class="text-3xl text-white font-bold" data-testid="title">{{ data.entity.label }} </h1>
      <h2 class="text-2xl text-gray-100 font-bold font-mono">{{data.entity.prefix.abbreviation}}{{ data.entity.prefix.abbreviation && ':'}}{{data.entity.id}}</h2>
    </div>

    <!-- Outputs-->
    <div class="output" v-for="[key, output] in outputs" :key="key + seed" :data-testid="'output-' + key">
      <div class="output-title" data-testid="output-title">{{ output.label }}</div>
      <Ref class="output-socket" :emit="emit"
           :data="{ type: 'socket', side: 'output', key: key, nodeId: data.id, payload: output.socket }"
           data-testid="output-socket" />
    </div>
    <!-- Controls-->
    <Ref class="control" v-for="[key, control] in controls" :key="key + seed" :emit="emit"
         :data="{ type: 'control', payload: control }" :data-testid="'control-' + key" />
    <!-- Inputs-->
    <div class="input" v-for="[key, input] in inputs" :key="key + seed" :data-testid="'input-' + key">
      <Ref class="input-socket" :emit="emit"
           :data="{ type: 'socket', side: 'input', key: key, nodeId: data.id, payload: input.socket }"
           data-testid="input-socket" />
      <div class="input-title" v-show="!input.control || !input.showControl" data-testid="input-title">{{ input.label }}
      </div>
      <Ref class="input-control" v-show="input.control && input.showControl" :emit="emit"
           :data="{ type: 'control', payload: input.control }" data-testid="input-control" />
    </div>
  </div>
</template>

<script lang="js">
import { defineComponent, computed } from 'vue'
import { Ref } from 'rete-vue-plugin'
import EntitySelector from "./EntitySelector.vue";

function sortByIndex(entries) {
  entries.sort((a, b) => {
    const ai = a[1] && a[1].index || 0
    const bi = b[1] && b[1].index || 0

    return ai - bi
  })
  return entries
}

export default defineComponent({
  props: {
    data: Object,
    emit: Function,
    seed: [String, Number]
  },
  setup(props) {
    const nodeStyles = computed(() => ({
      width: Number.isFinite(props.data.width) ? `${props.data.width}px` : '',
      height: Number.isFinite(props.data.height) ? `${props.data.height}px` : ''
    }));

    const inputs = computed(() => sortByIndex(Object.entries(props.data.inputs)));
    const controls = computed(() => sortByIndex(Object.entries(props.data.controls)));
    const outputs = computed(() => sortByIndex(Object.entries(props.data.outputs)));

    const isVariable = computed(() => props.data?.entity?.id?.startsWith('?'));
    const isVariableSelectedForProjection = computed(() =>
      isVariable.value && props.data?.entity?.selectedForProjection !== false
    );
    const projectionTooltip = computed(() => {
      if (!isVariable.value) return '';
      return isVariableSelectedForProjection.value
        ? 'Click to exclude from SELECT projection'
        : 'Click to include in SELECT projection';
    });

    return {
      nodeStyles,
      inputs,
      controls,
      outputs,
      isVariableSelectedForProjection,
      projectionTooltip
    };
  },
  components: {
    EntitySelector,
    Ref
  }
});
</script>

<style lang="scss" scoped>
@use "sass:math";
$node-width: 300px;
$socket-margin: 6px;
$socket-size: 16px;

.node {
  // background: #8b9ffb;
  border: 2px solid grey;
  border-radius: 10px;
  cursor: pointer;
  box-sizing: border-box;
  width: $node-width;
  height: auto;
  padding-bottom: 6px;
  position: relative;
  user-select: none;

  &:hover {
    // background: #9bacfb;
  }

  &.selected {
    color: black;
    border-color: red;
    background: #ffcf00;
  }


  .title {
    color: white;
    font-family: sans-serif;
    font-size: 18px;
    padding: 8px;
  }

  .output {
    text-align: right;
  }

  .input {
    text-align: left;
  }

  .output-socket {
    text-align: right;
    margin-right: -18px;
    display: inline-block;
  }

  .input-socket {
    text-align: left;
    margin-left: -18px;
    display: inline-block;
  }

  .input-title,
  .output-title {
    vertical-align: middle;
    color: white;
    display: inline-block;
    font-family: sans-serif;
    font-size: 14px;
    margin: $socket-margin;
    line-height: $socket-size;
  }

  .input-control {
    z-index: 1;
    width: calc(100% - #{$socket-size + 2*$socket-margin});
    vertical-align: middle;
    display: inline-block;
  }

  .control {
    padding: $socket-margin math.div($socket-size, 2) + $socket-margin;
  }
}
</style>
