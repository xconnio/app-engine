<script setup lang="ts">
import type { ManifestElement, ManifestEvent } from '../types'

const props = defineProps<{
  element: ManifestElement
  state: Record<string, string>
  onEvent: (event: ManifestEvent) => void
}>()

// A leaf's text is replaced once its action has written a result into state
// under its own id (e.g. a button's on.click.result target).
function displayText(): string | undefined {
  const el = props.element
  return el.id && props.state[el.id] !== undefined ? props.state[el.id] : el.text
}

// Wires every event the manifest declares on this element (not just "click") to
// the corresponding action call, generically via v-on="listeners()".
function listeners(): Record<string, () => void> {
  return Object.fromEntries(Object.entries(props.element.on ?? {}).map(([name, event]) => [name, () => props.onEvent(event)]))
}
</script>

<template>
  <component :is="element.tag" :style="element.style" v-on="listeners()">
    <template v-if="element.children?.length">
      <DynamicElement
        v-for="(child, i) in element.children"
        :key="child.id ?? i"
        :element="child"
        :state="state"
        :on-event="onEvent"
      />
    </template>
    <template v-else>{{ displayText() }}</template>
  </component>
</template>
