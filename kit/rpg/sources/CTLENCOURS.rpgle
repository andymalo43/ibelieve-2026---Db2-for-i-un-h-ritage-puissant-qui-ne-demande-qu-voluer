**FREE
// =====================================================================
// CTLENCOURS - Controle de l'encours d'un client
// RPG IV free-form - ILE - acces natif (CHAIN), pas de SQL
//
// Parametres  1 IN  numero client         packed(7,0)
//             2 IN  montant a engager     packed(11,2)
//             3 OUT encours disponible    packed(11,2)
//             4 OUT code retour           char(1)
//                     ' ' OK
//                     'E' encours depasse
//                     'N' client inconnu
//
// CRTBNDRPG PGM(VOTREBIB/CTLENCOURS) SRCFILE(VOTREBIB/KITRPGLSRC)
//           DFTACTGRP(*NO) ACTGRP('DEMO')
//
// Pourquoi de l'acces natif ici : pour montrer qu'un fichier ouvert
// est une ressource du GROUPE D'ACTIVATION. Sans CLOSE explicite et
// sans *INLR, CLIENT reste ouvert dans 'DEMO' entre deux appels du
// meme job. Deuxieme appel plus rapide ; etat conserve.
// =====================================================================

ctl-opt dftactgrp(*no) actgrp('DEMO')
        option(*srcstmt: *nodebugio);

// ALIAS : utilise les noms SQL longs (CLI_ENCOURS_MAX) au lieu des
// noms courts generes par le systeme (CLI_E00001).
dcl-f CLIENT keyed usage(*input) alias;

dcl-pi *n;
  inClient   packed(7:0)  const;
  inMontant  packed(11:2) const;
  outDispo   packed(11:2);
  outRC      char(1);
end-pi;

outRC    = ' ';
outDispo = 0;

chain inClient CLIENT;
if not %found(CLIENT);
  outRC = 'N';
  return;
endif;

outDispo = CLI_ENCOURS_MAX - CLI_ENCOURS;

if inMontant > outDispo;
  outRC = 'E';
endif;

return;
