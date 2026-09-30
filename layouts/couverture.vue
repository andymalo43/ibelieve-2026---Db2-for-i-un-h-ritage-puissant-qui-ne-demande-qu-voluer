<!-- Couverture du gabarit iBelieve 2026 (template.pptx, disposition « Disposition personnalisée ») :
     fond public/gabarit/couverture.jpg, logo Sinapse, titre de la slide, « avec Itheis » en bas à droite,
     logo IBM DB2 (public/logos/db2.png) et « Db2 for i » en bas à gauche de la zone blanche.
     Positions reprises du .pptx, en % de la slide. -->
<script setup lang="ts">
const base = import.meta.env.BASE_URL
</script>

<template>
  <div class="slidev-layout couverture" :style="{ backgroundImage: `url(${base}gabarit/couverture.jpg)` }">
    <img class="couverture__sinapse" :src="`${base}gabarit/sinapse.png`" alt="Sinapse">
    <div class="couverture__texte">
      <slot />
    </div>
    <div class="couverture__db2">
      <img class="couverture__db2-icone" :src="`${base}logos/db2.png`" alt="IBM Db2">
      <span>Db2 for i</span>
    </div>
    <div class="couverture__avec">
      <span>avec</span>
      <img :src="`${base}gabarit/itheis.png`" alt="Itheis">
    </div>
  </div>
</template>

<style>
.slidev-layout.couverture {
  padding: 0;
  background-size: 100% 100%;
  color: var(--gabarit-marine);
}
.couverture__sinapse {
  position: absolute;
  left: 53.8%;
  top: 33%;
  width: 31.2%;
}
.couverture__texte {
  position: absolute;
  left: 44.2%;
  top: 56%;
  width: 50.4%;
  text-align: center;
}
.slidev-layout.couverture h1 {
  font-family: var(--gabarit-police);
  font-size: 1.95rem;
  line-height: 1.15;
  font-weight: 700;
  margin: 0;
  color: var(--gabarit-marine);
}
.slidev-layout.couverture p {
  font-family: var(--gabarit-police);
}
.slidev-layout.couverture h1 + p {
  margin-top: 0.8rem;
  opacity: 1;
  font-size: 0.95rem;
}
.couverture__db2 {
  position: absolute;
  left: 44.2%;
  bottom: 4.5%;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-family: var(--gabarit-police);
  font-weight: 700;
  font-size: 1.15rem;
  color: var(--gabarit-marine);
}
.couverture__db2-icone {
  height: 3.4rem;
}
.couverture__avec {
  position: absolute;
  right: 3%;
  bottom: 4%;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 700;
  font-size: 0.95rem;
}
.couverture__avec img {
  height: 3.6rem;
}
</style>
