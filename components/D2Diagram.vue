<!-- Schéma D2 compilé au build par setup/transformers.ts (SVG en base64).
     Avec `steps` > 1, les éléments de classe `etapeN` (N = 2…steps) apparaissent au clic,
     en fondu : un seul SVG, donc une disposition stable d'une étape à l'autre. Les clics
     sont réservés comme le fait v-switch (calculateSince / register). -->
<script setup lang="ts">
import { onMounted, onUnmounted, ref, watchEffect } from 'vue'
import { useSlideContext } from '@slidev/client'

const props = defineProps<{ svg: string, maxHeight?: string, steps?: number }>()
const bytes = Uint8Array.from(atob(props.svg), c => c.charCodeAt(0))
const html = new TextDecoder().decode(bytes)

const racine = ref<HTMLElement>()
const niveau = ref(props.steps && props.steps > 1 ? 1 : 99)

if (props.steps && props.steps > 1) {
  const { $clicksContext: clics } = useSlideContext()
  const id = `d2-${Math.random().toString(36).slice(2)}`
  onMounted(() => {
    const infos = clics.calculateSince('+1', props.steps! - 1)
    if (!infos) {
      niveau.value = 99   // pas de contexte de clics (vue d'ensemble, impression) : tout afficher
      return
    }
    clics.register(id, infos)
    watchEffect(() => {
      niveau.value = 1 + Math.min(Math.max(infos.currentOffset.value + 1, 0), props.steps! - 1)
    })
  })
  onUnmounted(() => clics.unregister(id))
}

watchEffect(() => {
  const el = racine.value
  if (!el || !props.steps)
    return
  for (let n = 2; n <= props.steps; n++) {
    el.querySelectorAll<SVGElement>(`.etape${n}`).forEach((g) => {
      g.style.opacity = n <= niveau.value ? '1' : '0'
    })
  }
})
</script>

<template>
  <div ref="racine" class="d2-diagram" :style="{ '--d2-max-h': props.maxHeight ?? '22rem' }" v-html="html" />
</template>

<style>
.d2-diagram > svg {
  display: block;
  margin: 0 auto;
  max-width: 100%;
  height: auto;
  max-height: var(--d2-max-h);
}
/* Espacement des lettres fidèle aux mesures de D2, même réduit */
.d2-diagram text {
  text-rendering: geometricPrecision;
}
/* Révélation des étapes */
.d2-diagram [class*="etape"] {
  transition: opacity 0.45s ease;
}
</style>
