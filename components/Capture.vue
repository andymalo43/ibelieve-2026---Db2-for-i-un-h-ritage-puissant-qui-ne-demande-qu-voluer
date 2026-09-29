<!-- Emplacement de capture d'écran ou de vidéo, déposée par Andy dans public/.
     Tant que le fichier manque, un cadre « Capture à venir » le signale en répétition.
     <Capture src="captures/acs-exemples.png" sujet="ACS → Insert from Examples" duree="30 s" /> -->
<script setup lang="ts">
import { computed, ref } from 'vue'

const props = defineProps<{ src: string, sujet: string, duree?: string, hauteur?: string }>()
const absent = ref(false)
const url = computed(() => `${import.meta.env.BASE_URL}${props.src}`)
const video = computed(() => /\.(mp4|webm)$/i.test(props.src))
</script>

<template>
  <div class="capture" :style="{ '--capture-h': props.hauteur ?? '20rem' }">
    <div v-if="absent" class="capture__attente">
      <carbon-screen class="capture__icone" />
      <div class="capture__titre">Capture à venir</div>
      <div>{{ props.sujet }}</div>
      <div class="capture__meta">{{ props.src }}<template v-if="props.duree"> · {{ props.duree }}</template></div>
    </div>
    <video v-else-if="video" :src="url" controls muted playsinline preload="metadata" @error="absent = true" />
    <img v-else :src="url" :alt="props.sujet" @error="absent = true">
  </div>
</template>

<style>
.capture {
  display: flex;
  justify-content: center;
}
.capture img,
.capture video {
  max-height: var(--capture-h);
  max-width: 100%;
  border-radius: 8px;
  box-shadow: 0 4px 18px rgba(0, 0, 0, 0.15);
}
.capture__attente {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  width: 100%;
  min-height: var(--capture-h);
  border: 2px dashed #b56959;
  border-radius: 12px;
  color: #b56959;
  text-align: center;
  padding: 1rem;
}
.capture__icone {
  font-size: 2.5rem;
}
.capture__titre {
  font-weight: 700;
  font-size: 1.2rem;
}
.capture__meta {
  font-size: 0.8rem;
  opacity: 0.8;
  font-family: monospace;
}
</style>
