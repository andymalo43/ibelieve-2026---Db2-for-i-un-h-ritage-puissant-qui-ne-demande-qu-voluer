**FREE
// =====================================================================
// VALDEVIS - Validation d'un devis (orchestrateur)
// RPG IV free-form - ILE - SQL imbrique + 2 appels de programmes
//
// Parametres  1 IN  numero devis          packed(9,0)
//             2 OUT montant TTC           packed(11,2)
//             3 OUT encours disponible    packed(11,2)
//             4 OUT code retour           char(1)
//                     ' ' valide
//                     'N' devis inconnu
//                     'S' statut incompatible (deja valide ou facture)
//                     'V' devis sans ligne
//                     'O' montant hors capacite
//                     'T' tarif refuse
//                     'C' client inconnu
//                     'E' encours depasse
//                     'X' erreur technique
//
// CRTSQLRPGI OBJ(VOTREBIB/VALDEVIS) SRCFILE(VOTREBIB/KITRPGLSRC)
//            COMMIT(*NONE) COMPILEOPT('ACTGRP(''DEMO'') DFTACTGRP(*NO)')
//
// Niveau 1 de la pile. C'est LE SEUL programme que la passerelle voit.
// Tout ce qui se passe en dessous (CALCDEVIS, CALCTARIF, CTLENCOURS)
// n'existe pour elle qu'a travers ce code retour a 1 caractere.
// =====================================================================

ctl-opt dftactgrp(*no) actgrp('DEMO')
        option(*srcstmt: *nodebugio);

dcl-pr CalcDevis extpgm('CALCDEVIS');
  devis  packed(9:0) const;
  ttc    packed(11:2);
  rc     char(1);
end-pr;

dcl-pr CtlEncours extpgm('CTLENCOURS');
  client   packed(7:0)  const;
  montant  packed(11:2) const;
  dispo    packed(11:2);
  rc       char(1);
end-pr;

dcl-pi *n;
  inDevis   packed(9:0) const;
  outTTC    packed(11:2);
  outDispo  packed(11:2);
  outRC     char(1);
end-pi;

dcl-s wStatut  char(1);
dcl-s wClient  packed(7:0);
dcl-s wRC      char(1);

outRC    = ' ';
outTTC   = 0;
outDispo = 0;

// --- 1. Etat du devis -----------------------------------------------
exec sql
  select DEV_STATUT, DEV_CLI into :wStatut, :wClient
    from VOTREBIB.DEVIS where DEV_NUM = :inDevis;

if sqlcode = 100;
  outRC = 'N';
  return;
elseif sqlcode < 0;
  outRC = 'X';
  return;
endif;

if wStatut <> 'S';
  outRC = 'S';
  return;
endif;

// --- 2. Calcul des totaux (niveau 2, qui appelle le niveau 3) -------
CalcDevis(inDevis : outTTC : wRC);

if wRC <> ' ';
  // On PROPAGE le code de CALCDEVIS tel quel : il a ete concu pour
  // ne pas entrer en collision avec les notres ('N','V','O','T','X').
  outRC = wRC;
  return;
endif;

// --- 3. Controle de l'encours (niveau 2, acces natif) ---------------
CtlEncours(wClient : outTTC : outDispo : wRC);

select;
  when wRC = 'N';
    outRC = 'C';          // 'N' voudrait dire "devis inconnu" ici
    return;
  when wRC = 'E';
    outRC = 'E';
    return;
endsl;

// --- 4. Validation --------------------------------------------------
exec sql
  update VOTREBIB.DEVIS set DEV_STATUT = 'V'
   where DEV_NUM = :inDevis;

if sqlcode < 0;
  outRC = 'X';
endif;

return;
