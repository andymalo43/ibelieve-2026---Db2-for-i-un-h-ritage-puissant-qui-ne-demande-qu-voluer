**FREE
// =====================================================================
// CALCTARIF - Calcul d'un tarif remise + TVA
// RPG IV free-form - ILE
//
// Strictement equivalent, fonctionnellement, a CALCTAR3 (RPG III)
// et a CALCTARA (Adelia). Meme interface, meme resultat.
//
// CRTBNDRPG PGM(VOTREBIB/CALCTARIF) SRCFILE(VOTREBIB/KITRPGLSRC)
//           DFTACTGRP(*NO) ACTGRP('DEMO')
//
// ACTGRP nomme : le programme reste active entre deux appels dans le
// meme job. Compare a CALCTAR3 qui, en OPM avec SETON LR, repart de
// zero a chaque fois. Meme fonction, profils de performance opposes.
// =====================================================================

ctl-opt dftactgrp(*no) actgrp('DEMO')
        option(*srcstmt: *nodebugio)
        bnddir('QC2LE');

dcl-pi *n;
  inMontantHT   packed(9:2)  const;
  inTauxRemise  packed(5:2)  const;
  outRemise     packed(11:2);
  outTVA        packed(11:2);
  outTTC        packed(11:2);
  outRC         char(1);
end-pi;

dcl-c TAUX_TVA  20.00;

dcl-s wRemise   packed(13:2);
dcl-s wTVA      packed(13:2);

// --- Initialisation des sorties -------------------------------------
outRC     = ' ';
outRemise = 0;
outTVA    = 0;
outTTC    = 0;

// --- Controle du taux de remise -------------------------------------
if inTauxRemise < 0 or inTauxRemise > 100;
  outRC = 'E';
  return;
endif;

// --- Calcul ----------------------------------------------------------
wRemise   = %dech(inMontantHT * inTauxRemise / 100 : 13 : 2);
outRemise = inMontantHT - wRemise;

wTVA      = %dech(outRemise * TAUX_TVA / 100 : 13 : 2);
outTVA    = wTVA;

outTTC    = outRemise + outTVA;

return;
