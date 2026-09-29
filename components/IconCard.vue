<!-- Carte-icône : remplace une puce de liste. L'icône passe en slot, car les icônes
     Iconify sont résolues à la compilation par leur nom de balise (<carbon-roadmap />).
     <IconCard titre="Étape par étape" texte="recouvrement d'abord"><carbon-roadmap /></IconCard> -->
<script setup lang="ts">
defineProps<{ titre: string, texte?: string, petit?: boolean }>()
</script>

<template>
  <div class="icon-card" :class="{ petit }">
    <div class="icon-card__icone"><slot /></div>
    <div class="icon-card__titre">{{ titre }}</div>
    <div v-if="texte" class="icon-card__texte">{{ texte }}</div>
  </div>
</template>

<style>
.icon-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 0.35rem;
  padding: 1rem 0.75rem;
  border-radius: 12px;
  background: #eef3f5;
  border: 1px solid #d3e0e5;
}
.icon-card__icone {
  font-size: 2.6rem;
  line-height: 1;
  color: var(--slidev-theme-primary, #5d8392);
}
.icon-card__titre {
  font-weight: 700;
  font-size: 1.15rem;
  line-height: 1.25;
}
.icon-card__texte {
  font-size: 0.85rem;
  opacity: 0.7;
  line-height: 1.3;
}
.icon-card.petit {
  padding: 0.5rem;
  background: transparent;
  border: none;
}
.icon-card.petit .icon-card__icone {
  font-size: 1.8rem;
}
.icon-card.petit .icon-card__titre {
  font-size: 0.95rem;
  font-weight: 600;
}
</style>
