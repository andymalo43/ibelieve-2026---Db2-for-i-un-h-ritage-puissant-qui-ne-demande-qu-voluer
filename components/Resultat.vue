<!-- Résultat d'une requête, mis en forme comme la grille de Run SQL Scripts (ACS).
     Les lignes viennent de pub400/resultats-kit/*.txt : ce n'est pas une capture d'écran.
     Une valeur entre ‹ › est masquée (nom de profil…) et s'affiche en italique.
     <Resultat :colonnes="['NOM', 'VALEUR']" :lignes="[['QSECURITY', '50']]" :total="195" /> -->
<script setup lang="ts">
const props = defineProps<{ colonnes: string[], lignes: string[][], total?: number }>()
const masque = (valeur: string) => /^‹.*›$/.test(valeur)
</script>

<template>
  <div class="resultat">
    <table>
      <thead>
        <tr><th v-for="c in props.colonnes" :key="c">{{ c }}</th></tr>
      </thead>
      <tbody>
        <tr v-for="(ligne, i) in props.lignes" :key="i">
          <td v-for="(valeur, j) in ligne" :key="j" :class="{ masque: masque(valeur) }">{{ valeur }}</td>
        </tr>
      </tbody>
    </table>
    <div class="resultat__pied">
      <template v-if="props.total && props.total > props.lignes.length">… </template>
      {{ props.total ?? props.lignes.length }} ligne(s)
    </div>
  </div>
</template>

<style>
.resultat {
  border-radius: 8px;
  border: 1px solid #d3e0e5;
  overflow: hidden;
  font-family: var(--slidev-code-font-family, monospace);
  font-size: 0.8rem;
}
.resultat table {
  width: 100%;
  border-collapse: collapse;
  margin: 0;
}
.resultat th,
.resultat td {
  padding: 0.25rem 0.75rem;
  text-align: left;
  border: none;
  border-bottom: 1px solid #e6eef1;
}
.resultat th {
  background: #eef3f5;
  font-weight: 700;
  color: var(--slidev-theme-primary, #5d8392);
}
.resultat td.masque {
  font-style: italic;
  opacity: 0.6;
}
.resultat__pied {
  padding: 0.2rem 0.75rem;
  font-size: 0.7rem;
  opacity: 0.6;
}
</style>
