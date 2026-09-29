**FREE
// =====================================================================
// CALCDEVIS - Calcule les totaux d'un devis a partir de ses lignes
// RPG IV free-form - ILE - SQL imbrique + appel de CALCTARIF
//
// Parametres  1 IN  numero devis          packed(9,0)
//             2 OUT montant TTC           packed(11,2)
//             3 OUT code retour           char(1)
//                     ' ' OK
//                     'N' devis inconnu
//                     'V' devis sans ligne
//                     'O' HT hors capacite de CALCTARIF (> packed 9,2)
//                     'T' CALCTARIF a refuse le calcul
//                     'X' erreur SQL
//
// CRTSQLRPGI OBJ(VOTREBIB/CALCDEVIS) SRCFILE(VOTREBIB/KITRPGLSRC)
//            COMMIT(*NONE) DBGVIEW(*SOURCE)
//            COMPILEOPT('ACTGRP(''DEMO'') DFTACTGRP(*NO)')
//
// Niveau 2 de la pile de la demo 2 : VALDEVIS -> CALCDEVIS -> CALCTARIF.
// Ce programme est INVISIBLE pour la passerelle. Elle ne voit que
// VALDEVIS. C'est lui qui doit remonter proprement les erreurs de
// CALCTARIF, sinon elles sont perdues.
// =====================================================================

ctl-opt dftactgrp(*no) actgrp('DEMO')
        option(*srcstmt: *nodebugio);

// Le prototype de CALCTARIF : c'est le contrat, recopie ici.
// Une divergence avec le vrai *ENTRY = corruption memoire silencieuse.
dcl-pr CalcTarif extpgm('CALCTARIF');
  montantHT   packed(9:2)  const;
  tauxRemise  packed(5:2)  const;
  htRemise    packed(11:2);
  tva         packed(11:2);
  ttc         packed(11:2);
  rc          char(1);
end-pr;

dcl-pi *n;
  inDevis  packed(9:0) const;
  outTTC   packed(11:2);
  outRC    char(1);
end-pi;

dcl-s wHT       packed(13:2);
dcl-s wTaux     packed(5:2);
dcl-s wNbLig    int(10);
dcl-s wHTRem    packed(11:2);
dcl-s wTVA      packed(11:2);
dcl-s wTTC      packed(11:2);
dcl-s wRC       char(1);

outRC  = ' ';
outTTC = 0;

// --- Le devis existe-t-il, et quel est le taux de son client ? ------
exec sql
  select c.CLI_TAUX_REM
    into :wTaux
    from VOTREBIB.DEVIS d
    join VOTREBIB.CLIENT c on c.CLI_NUM = d.DEV_CLI
   where d.DEV_NUM = :inDevis;

if sqlcode = 100;
  outRC = 'N';
  return;
elseif sqlcode < 0;
  outRC = 'X';
  return;
endif;

// --- Somme des lignes -----------------------------------------------
exec sql
  select coalesce(sum(DVL_QTE * DVL_PU), 0), count(*)
    into :wHT, :wNbLig
    from VOTREBIB.DEVLIG
   where DVL_DEV = :inDevis;

if sqlcode < 0;
  outRC = 'X';
  return;
endif;
if wNbLig = 0;
  outRC = 'V';
  return;
endif;

// --- Le contrat de CALCTARIF plafonne le HT a packed(9,2) -----------
// Ne pas verifier ici = tronquer silencieusement le montant.
if wHT > 9999999.99;
  outRC = 'O';
  return;
endif;

// --- Niveau 3 de la pile --------------------------------------------
CalcTarif(wHT : wTaux : wHTRem : wTVA : wTTC : wRC);

if wRC = 'E';
  outRC = 'T';
  return;
endif;

// --- Memorisation sur le devis --------------------------------------
exec sql
  update VOTREBIB.DEVIS
     set DEV_HT     = :wHT,
         DEV_REMISE = :wHT - :wHTRem,
         DEV_TVA    = :wTVA,
         DEV_TTC    = :wTTC
   where DEV_NUM = :inDevis;

if sqlcode < 0;
  outRC = 'X';
  return;
endif;

outTTC = wTTC;
return;
