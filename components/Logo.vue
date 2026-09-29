<!-- Logo d'un partenaire, depuis public/logos/ (marques de leurs détenteurs : voir public/logos/README.md).
     <Logo nom="sinapse.png" alt="Sinapse NC" hauteur="2.5rem" /> ; retombe sur le texte si le fichier manque. -->
<script setup lang="ts">
import { computed, ref } from 'vue'

const props = defineProps<{ nom: string, alt: string, hauteur?: string }>()
const absent = ref(false)
const url = computed(() => `${import.meta.env.BASE_URL}logos/${props.nom}`)
</script>

<template>
  <img v-if="!absent" class="logo" :src="url" :alt="props.alt" :style="{ height: props.hauteur ?? '2.5rem' }" @error="absent = true">
  <span v-else class="logo-texte">{{ props.alt }}</span>
</template>

<style>
.logo {
  display: inline-block;
  width: auto;
  object-fit: contain;
  vertical-align: middle;
  margin: 0;
  box-shadow: none;
}
.logo-texte {
  font-weight: 700;
  color: #5d8392;
}
</style>
