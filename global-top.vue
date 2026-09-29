<!-- Bandeau de fil rouge, au-dessus de chaque slide de contenu.
     Lit le frontmatter de la slide : chapitre (1-4), etape (0-4, chapitre 2 seulement).
     Sans `chapitre`, rien n'est affiché (titre, intro, conclusion). -->
<script setup lang="ts">
import { computed } from 'vue'
import { useNav } from '@slidev/client'

const { currentSlideRoute } = useNav()
const fm = computed<Record<string, any>>(() => currentSlideRoute.value?.meta?.slide?.frontmatter ?? {})

const chapitres = [
  { n: 1, titre: 'Chantier' },
  { n: 2, titre: 'Moderniser' },
  { n: 3, titre: 'Administrer' },
  { n: 4, titre: 'Données' },
]
const etapes = [
  { n: 1, titre: 'Cartographier' },
  { n: 2, titre: 'Encapsuler' },
  { n: 3, titre: 'Découpler' },
  { n: 4, titre: 'Un bloc à la fois' },
]

const chapitre = computed(() => Number(fm.value.chapitre) || 0)
const etape = computed(() => Number(fm.value.etape) || 0)
const avecEtapes = computed(() => chapitre.value === 2 && fm.value.etape !== undefined)
</script>

<template>
  <div v-if="chapitre" class="fil-rouge">
    <div class="fil-rouge__groupe">
      <template v-for="(c, i) in chapitres" :key="c.n">
        <span v-if="i" class="fil-rouge__sep">›</span>
        <span class="fil-rouge__item" :class="{ actif: c.n === chapitre && !avecEtapes }">{{ c.n }} · {{ c.titre }}</span>
        <template v-if="c.n === 2 && avecEtapes">
          <span class="fil-rouge__sep">▸</span>
          <template v-for="(e, j) in etapes" :key="e.n">
            <span v-if="j" class="fil-rouge__sep">›</span>
            <span class="fil-rouge__item fil-rouge__etape" :class="{ actif: e.n === etape }">2.{{ e.n }} {{ e.titre }}</span>
          </template>
        </template>
      </template>
    </div>
  </div>
</template>

<style>
.fil-rouge {
  position: absolute;
  top: 0.45rem;
  left: 2rem;
  right: 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.62rem;
  line-height: 1rem;
  color: #5d8392;
  z-index: 5;
  pointer-events: none;
}
.fil-rouge__groupe {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}
.fil-rouge__item {
  opacity: 0.45;
}
.fil-rouge__item.actif {
  opacity: 1;
  font-weight: 700;
  color: #b56959;
  border-bottom: 2px solid #b56959;
}
.fil-rouge__etape {
  font-size: 0.6rem;
}
.fil-rouge__sep {
  opacity: 0.35;
}
</style>
