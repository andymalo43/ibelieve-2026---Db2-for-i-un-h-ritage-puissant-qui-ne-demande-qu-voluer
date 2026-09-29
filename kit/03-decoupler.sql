-- =====================================================================
-- Kit iBelieve 2026 — 03. Découpler (slides « le journal a tout vu », « la base publie »).
-- ÉCRIT dans votre bibliothèque : valide et facture le devis 101, crée puis supprime la *DTAQ EVT_CLIENT.
-- Prérequis : 00-terrain.sql. Pour rejouer, relancer 99-menage.sql puis 00-terrain.sql.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- De l'activité : les « programmes » travaillent, sans rien savoir du journal
CALL VALIDER(101, ?);
CALL FACTURER(101, ?);

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
                       'id'      VALUE ID_CLIENT,
                       'encours' VALUE ENCOURS,
                       'ts'      VALUE CURRENT TIMESTAMP)
      FROM CLIENT WHERE ID_CLIENT = 1),
  DATA_QUEUE         => 'EVT_CLIENT',
  DATA_QUEUE_LIBRARY => CURRENT SCHEMA);

-- Côté consommateur, y compris via ODBC
SELECT CAST(MESSAGE_DATA_UTF8 AS VARCHAR(1000)) AS MESSAGE
  FROM TABLE (QSYS2.RECEIVE_DATA_QUEUE(
         DATA_QUEUE         => 'EVT_CLIENT',
         DATA_QUEUE_LIBRARY => CURRENT SCHEMA));

CALL QSYS2.QCMDEXC('DLTDTAQ DTAQ(' CONCAT CURRENT SCHEMA CONCAT '/EVT_CLIENT)');
