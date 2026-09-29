-- =====================================================================
-- Kit iBelieve 2026 — RPG — 12. Compiler les programmes
-- ÉCRIT dans votre bibliothèque : 7 programmes (*PGM). Prérequis : 10 et 11.
-- Les options d'activation (DFTACTGRP(*NO) ACTGRP('DEMO')) sont dans les sources (ctl-opt / H).
-- =====================================================================

SET SCHEMA VOTREBIB;

-- Les programmes s'appellent par leur nom (*LIBL) et CTLENCOURS ouvre CLIENT par *LIBL :
-- la bibliothèque du kit doit passer devant toute autre qui aurait les mêmes noms.
-- ADDLIBLE ne suffit pas : la bibliothèque en cours (CURLIB) est cherchée avant la
-- partie utilisateur de la liste. On en fait donc la bibliothèque en cours de la session.
CALL QSYS2.QCMDEXC('CHGCURLIB CURLIB(' CONCAT CURRENT SCHEMA CONCAT ')');

-- RPG III (OPM) : CRTRPGPGM, depuis un fichier source uniquement
CALL QSYS2.QCMDEXC('CRTRPGPGM PGM(' CONCAT CURRENT SCHEMA CONCAT '/CALCTAR3) SRCFILE('
                   CONCAT CURRENT SCHEMA CONCAT '/KITRPGSRC)');

-- RPG IV (ILE), sans SQL
CALL QSYS2.QCMDEXC('CRTBNDRPG PGM(' CONCAT CURRENT SCHEMA CONCAT '/CALCTARIF) SRCFILE('
                   CONCAT CURRENT SCHEMA CONCAT '/KITRPGLSRC)');
CALL QSYS2.QCMDEXC('CRTBNDRPG PGM(' CONCAT CURRENT SCHEMA CONCAT '/CTLENCOURS) SRCFILE('
                   CONCAT CURRENT SCHEMA CONCAT '/KITRPGLSRC)');
CALL QSYS2.QCMDEXC('CRTBNDRPG PGM(' CONCAT CURRENT SCHEMA CONCAT '/CALCTARA) SRCFILE('
                   CONCAT CURRENT SCHEMA CONCAT '/KITRPGLSRC)');

-- RPG IV avec SQL imbriqué. GENFACT possède sa transaction : COMMIT(*CHG)
CALL QSYS2.QCMDEXC('CRTSQLRPGI OBJ(' CONCAT CURRENT SCHEMA CONCAT '/CALCDEVIS) SRCFILE('
                   CONCAT CURRENT SCHEMA CONCAT '/KITRPGLSRC) COMMIT(*NONE)');
CALL QSYS2.QCMDEXC('CRTSQLRPGI OBJ(' CONCAT CURRENT SCHEMA CONCAT '/VALDEVIS) SRCFILE('
                   CONCAT CURRENT SCHEMA CONCAT '/KITRPGLSRC) COMMIT(*NONE)');
CALL QSYS2.QCMDEXC('CRTSQLRPGI OBJ(' CONCAT CURRENT SCHEMA CONCAT '/GENFACT) SRCFILE('
                   CONCAT CURRENT SCHEMA CONCAT '/KITRPGLSRC) COMMIT(*CHG)');

-- Vérification : 7 programmes, OPM pour CALCTAR3 (attribut RPG), ILE pour les autres
SELECT OBJNAME AS PROGRAMME, OBJATTRIBUTE AS ATTRIBUT, OBJCREATED AS CREE_LE
  FROM TABLE (QSYS2.OBJECT_STATISTICS(CURRENT SCHEMA, '*PGM')) X
 WHERE OBJNAME IN ('CALCTAR3', 'CALCTARIF', 'CTLENCOURS', 'CALCTARA', 'CALCDEVIS', 'VALDEVIS', 'GENFACT')
 ORDER BY OBJNAME;
