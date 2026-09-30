<!-- Bandeau de fil rouge, au-dessus de chaque slide de contenu.
     Lit le frontmatter de la slide : chapitre (intro, 1-4, fin), etape (0-4, chapitres 2 et 4 : voir etapesParChapitre).
     Sans `chapitre`, rien n'est affiché (couverture, slide de fin).
     Avec `class: gabarit` (gabarit iBelieve, style.css) : fil rouge dans le bandeau marine, titre de la session
     dans le pied, numéro de slide en haut à droite. -->
<script setup lang="ts">
import { computed } from 'vue'
import { useNav } from '@slidev/client'

const { currentSlideRoute } = useNav()
const fm = computed<Record<string, any>>(() => currentSlideRoute.value?.meta?.slide?.frontmatter ?? {})

const chapitres: { n: number | string, titre: string }[] = [
  { n: 'intro', titre: 'Intro' },
  { n: 1, titre: 'Chantier' },
  { n: 2, titre: 'Moderniser' },
  { n: 3, titre: 'Administrer' },
  { n: 4, titre: 'Données' },
  { n: 'fin', titre: 'Conclusion' },
]
const etapesParChapitre: Record<number, { n: number, titre: string }[]> = {
  2: [
  { n: 1, titre: 'Cartographier' },
  { n: 2, titre: 'Encapsuler' },
  { n: 3, titre: 'Découpler' },
  { n: 4, titre: 'Un bloc à la fois' },
  ],
  4: [
  { n: 1, titre: 'Se connecter' },
  { n: 2, titre: 'Extraire' },
  { n: 3, titre: 'Industrialiser' },
  { n: 4, titre: 'En vrai' },
  ],
}

const chapitre = computed(() => chapitres.find(c => String(c.n) === String(fm.value.chapitre ?? ''))?.n)
const etape = computed(() => Number(fm.value.etape) || 0)
const etapes = computed(() => etapesParChapitre[chapitre.value as number] ?? [])
const avecEtapes = computed(() => etapes.value.length > 0 && fm.value.etape !== undefined)
// etape 0 : ouverture du chapitre, étapes affichées mais c'est le chapitre qui est surligné
const etapeActive = computed(() => avecEtapes.value && etapes.value.some(e => e.n === etape.value))
const gabarit = computed(() => fm.value.layout !== 'couverture' && String(fm.value.class ?? '').split(/\s+/).includes('gabarit'))
const numero = computed(() => currentSlideRoute.value?.no)
</script>

<template>
  <template v-if="gabarit">
    <div class="gabarit-numero">{{ numero }}</div>
    <div class="gabarit-pied">Db2 for i : un héritage puissant qui ne demande qu'à évoluer</div>
  </template>
  <div v-if="chapitre !== undefined" class="fil-rouge" :class="{ 'fil-rouge--gabarit': gabarit }">
    <div class="fil-rouge__groupe">
      <template v-for="(c, i) in chapitres" :key="c.n">
        <span v-if="i" class="fil-rouge__sep">›</span>
        <span class="fil-rouge__item" :class="{ actif: c.n === chapitre && !etapeActive }">{{ typeof c.n === 'number' ? `${c.n} · ${c.titre}` : c.titre }}</span>
        <template v-if="c.n === chapitre && avecEtapes">
          <span class="fil-rouge__sep">▸</span>
          <template v-for="(e, j) in etapes" :key="e.n">
            <span v-if="j" class="fil-rouge__sep">›</span>
            <span class="fil-rouge__item fil-rouge__etape" :class="{ actif: e.n === etape }">{{ chapitre }}.{{ e.n }} {{ e.titre }}</span>
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
.fil-rouge--gabarit {
  top: 62px;
  height: 18px;
  left: 4.25rem;
  right: 4.25rem;
  color: #fff;
}
.fil-rouge--gabarit .fil-rouge__item {
  opacity: 0.6;
}
.fil-rouge--gabarit .fil-rouge__item.actif {
  opacity: 1;
  color: var(--gabarit-jaune);
  border-bottom: none;
}
.fil-rouge--gabarit .fil-rouge__sep {
  opacity: 0.5;
}
.gabarit-numero {
  position: absolute;
  top: 0.7rem;
  right: 1.9rem;
  font-size: 0.7rem;
  color: #7a8599;
  z-index: 5;
}
.gabarit-pied {
  position: absolute;
  top: 494px;
  left: 33%;
  width: 40%;
  font-family: var(--gabarit-police);
  font-size: 0.62rem;
  line-height: 1.1;
  color: var(--gabarit-marine);
  z-index: 5;
  pointer-events: none;
}
</style>
