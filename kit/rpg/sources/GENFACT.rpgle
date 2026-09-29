**FREE
// =====================================================================
// GENFACT - Transforme un devis valide en facture
// RPG IV free-form - ILE - SQL imbrique - TRANSACTIONNEL
//
// Parametres  1 IN  numero devis          packed(9,0)
//             2 IN  date facture AAAAMMJJ packed(8,0)
//             3 OUT numero facture        packed(9,0)
//             4 OUT code retour           char(1)
//                     ' ' facture creee
//                     'N' devis inconnu
//                     'D' deja facture
//                     'S' devis non valide (statut <> 'V')
//                     'X' erreur technique - transaction annulee
//
// CRTSQLRPGI OBJ(VOTREBIB/GENFACT) SRCFILE(VOTREBIB/KITRPGLSRC)
//            COMMIT(*CHG) COMPILEOPT('ACTGRP(''DEMO'') DFTACTGRP(*NO)')
//
// Quatre ecritures, une transaction. Soit tout, soit rien.
// Le programme POSSEDE sa transaction : il commit ou rollback lui-meme.
// C'est le choix le plus simple a exposer derriere une facade SQL.
// =====================================================================

ctl-opt dftactgrp(*no) actgrp('DEMO')
        option(*srcstmt: *nodebugio);

exec sql set option commit = *chg, closqlcsr = *endactgrp;

dcl-pi *n;
  inDevis     packed(9:0) const;
  inDate      packed(8:0) const;
  outFacture  packed(9:0);
  outRC       char(1);
end-pi;

dcl-s wClient  packed(7:0);
dcl-s wStatut  char(1);
dcl-s wTTC     packed(11:2);
dcl-s wNum     packed(9:0);

outRC      = ' ';
outFacture = 0;

// --- 1. Lecture et controle d'etat ----------------------------------
exec sql
  select DEV_CLI, DEV_STATUT, DEV_TTC
    into :wClient, :wStatut, :wTTC
    from VOTREBIB.DEVIS where DEV_NUM = :inDevis;

if sqlcode = 100;
  outRC = 'N';
  return;
elseif sqlcode < 0;
  outRC = 'X';
  return;
endif;

if wStatut = 'F';
  outRC = 'D';            // idempotence : deuxieme appel = refus propre
  return;
elseif wStatut <> 'V';
  outRC = 'S';
  return;
endif;

// --- 2. Numero de facture : increment SOUS VERROU, dans la transaction
exec sql
  update VOTREBIB.COMPTEUR set CPT_VAL = CPT_VAL + 1
   where CPT_CODE = 'FACTURE';
if sqlcode < 0;
  exsr annuler;
  return;
endif;

exec sql
  select CPT_VAL into :wNum
    from VOTREBIB.COMPTEUR where CPT_CODE = 'FACTURE';
if sqlcode <> 0;
  exsr annuler;
  return;
endif;

// --- 3. La facture --------------------------------------------------
exec sql
  insert into VOTREBIB.FACTURE
         (FAC_NUM, FAC_DEV, FAC_CLI, FAC_DATE, FAC_TTC)
  values (:wNum, :inDevis, :wClient, :inDate, :wTTC);

if sqlcode = -803;
  // UQ_FACDEV : deux jobs ont lu 'V' en meme temps. La base a tranche.
  exsr annuler;
  outRC = 'D';
  return;
elseif sqlcode < 0;
  exsr annuler;
  return;
endif;

// --- 4. L'encours du client -----------------------------------------
exec sql
  update VOTREBIB.CLIENT set CLI_ENCOURS = CLI_ENCOURS + :wTTC
   where CLI_NUM = :wClient;
if sqlcode < 0;
  exsr annuler;
  return;
endif;

// --- 5. Le devis passe a 'F' ----------------------------------------
exec sql
  update VOTREBIB.DEVIS set DEV_STATUT = 'F'
   where DEV_NUM = :inDevis;
if sqlcode < 0;
  exsr annuler;
  return;
endif;

// --- 6. Tout ou rien ------------------------------------------------
exec sql commit;
if sqlcode < 0;
  exsr annuler;
  return;
endif;

outFacture = wNum;
return;

// ---------------------------------------------------------------------
begsr annuler;
  exec sql rollback;
  outRC = 'X';
endsr;
