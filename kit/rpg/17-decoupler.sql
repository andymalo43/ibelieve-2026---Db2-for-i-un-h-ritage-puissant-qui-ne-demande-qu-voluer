-- =====================================================================
-- Kit iBelieve 2026 — RPG — 17. Découpler (slides « le journal a tout vu », « la base publie »)
-- Le RPG travaille sans rien savoir du journal ; la base publie l'état du client en JSON.
-- ÉCRIT : valide et facture le devis 500005, crée puis supprime la *DTAQ EVT_CLIENT.
-- Prérequis : 13-facades.sql. Pour rejouer : relancer 10-terrain-rpg.sql.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Les programmes s'appellent par leur nom (*LIBL) et CTLENCOURS ouvre CLIENT par *LIBL :
-- la bibliothèque du kit doit passer devant toute autre qui aurait les mêmes noms.
-- ADDLIBLE ne suffit pas : la bibliothèque en cours (CURLIB) est cherchée avant la
-- partie utilisateur de la liste. On en fait donc la bibliothèque en cours de la session.
CALL QSYS2.QCMDEXC('CHGCURLIB CURLIB(' CONCAT CURRENT SCHEMA CONCAT ')');

-- De l'activité : les programmes RPG travaillent, sans rien savoir du journal
CALL PS_TRAITER_DEVIS(500005, 20260929, ?, ?);   -- attendu facture 1003, ' '

-- Le journal a déjà tout capté
SELECT ENTRY_TIMESTAMP, JOURNAL_ENTRY_TYPE,
       SUBSTR(OBJECT, 1, 10) AS TABLE_, PROGRAM_NAME
  FROM TABLE (QSYS2.DISPLAY_JOURNAL(
         JOURNAL_LIBRARY    => CURRENT SCHEMA,
         JOURNAL_NAME       => 'QSQJRN',
         STARTING_TIMESTAMP => CURRENT TIMESTAMP - 1 HOUR))
 WHERE JOURNAL_CODE = 'R';

-- Une file de données pour publier des événements
CALL QSYS2.QCMDEXC('CRTDTAQ DTAQ(' CONCAT CURRENT SCHEMA CONCAT '/EVT_CLIENT) MAXLEN(1000)');

-- Publier l'état du client en JSON
CALL QSYS2.SEND_DATA_QUEUE_UTF8(
  MESSAGE_DATA => (
    SELECT JSON_OBJECT('table'   VALUE 'CLIENT',
                       'id'      VALUE CLI_NUM,
                       'encours' VALUE CLI_ENCOURS,
                       'ts'      VALUE CURRENT TIMESTAMP)
      FROM CLIENT WHERE CLI_NUM = 1001),
  DATA_QUEUE         => 'EVT_CLIENT',
  DATA_QUEUE_LIBRARY => CURRENT SCHEMA);

-- Côté consommateur, y compris via ODBC
SELECT CAST(MESSAGE_DATA_UTF8 AS VARCHAR(1000)) AS MESSAGE
  FROM TABLE (QSYS2.RECEIVE_DATA_QUEUE(
         DATA_QUEUE         => 'EVT_CLIENT',
         DATA_QUEUE_LIBRARY => CURRENT SCHEMA));

CALL QSYS2.QCMDEXC('DLTDTAQ DTAQ(' CONCAT CURRENT SCHEMA CONCAT '/EVT_CLIENT)');
