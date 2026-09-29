-- =====================================================================
-- Kit iBelieve 2026 — 01. Cartographier (slides « Étape 1 », « La chaîne d'appels »,
-- « Un diagramme sans outil »). Lecture seule, hors QTEMP (disparaît avec la session).
-- Prérequis : 00-terrain.sql. Lancer dans la même session ACS, de haut en bas.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Qui référence quoi ? DSPPGMREF, piloté en SQL, résultat dans QTEMP
CALL QSYS2.QCMDEXC(
  'DSPPGMREF PGM(' CONCAT CURRENT SCHEMA CONCAT '/*ALL) OUTPUT(*OUTFILE) '
  CONCAT 'OBJTYPE(*PGM) OUTFILE(QTEMP/PGMREF) OUTMBR(*FIRST *REPLACE)');

-- Combien de programmes, combien de tables de la bibliothèque référencées ?
SELECT COUNT(DISTINCT WHPNAM) AS PROGRAMMES,
       COUNT(*)               AS REFERENCES_TABLES
  FROM QTEMP.PGMREF
 WHERE WHOTYP = '*FILE' AND TRIM(WHLNAM) = CURRENT SCHEMA;

-- La chaîne d'appels depuis VALIDER, lue dans le catalogue
WITH CHAINE (APPELANT, APPELE, NIVEAU, CHEMIN) AS (
  SELECT SPECIFIC_NAME, OBJECT_NAME, 1,
         CAST(SPECIFIC_NAME CONCAT ' > ' CONCAT OBJECT_NAME AS VARCHAR(1000))
    FROM QSYS2.SYSROUTINEDEP
   WHERE SPECIFIC_SCHEMA = CURRENT SCHEMA
     AND SPECIFIC_NAME = 'VALIDER' AND OBJECT_TYPE = 'PROCEDURE'
  UNION ALL
  SELECT D.SPECIFIC_NAME, D.OBJECT_NAME, C.NIVEAU + 1,
         C.CHEMIN CONCAT ' > ' CONCAT D.OBJECT_NAME
    FROM CHAINE C
    JOIN QSYS2.SYSROUTINEDEP D
      ON D.SPECIFIC_SCHEMA = CURRENT SCHEMA AND D.SPECIFIC_NAME = C.APPELE
   WHERE D.OBJECT_TYPE = 'PROCEDURE' AND C.NIVEAU < 15    -- profondeur max
     AND LOCATE(' ' CONCAT D.OBJECT_NAME CONCAT ' ',
                ' ' CONCAT C.CHEMIN CONCAT ' ') = 0       -- pas de boucle
)
SELECT NIVEAU, CHEMIN FROM CHAINE ORDER BY CHEMIN;

-- En réserve : qui utilise la table DEVIS, et comment (1 lecture, 2 écriture, 4 mise à jour…) ?
SELECT TRIM(WHPNAM) AS PROGRAMME, WHFUSG AS USAGE
  FROM QTEMP.PGMREF
 WHERE WHFNAM = 'DEVIS' AND WHOTYP = '*FILE'
 ORDER BY PROGRAMME;

-- Un diagramme sans outil : le SQL écrit du Mermaid (appels + tables)
SELECT 'graph TD' AS LIGNE FROM SYSIBM.SYSDUMMY1
UNION ALL
SELECT DISTINCT '  ' CONCAT TRIM(WHPNAM) CONCAT ' --> '
       CONCAT TRIM(WHFNAM) CONCAT '[(' CONCAT TRIM(WHFNAM) CONCAT ')]'
  FROM QTEMP.PGMREF                             -- [( )] : table en cylindre
 WHERE WHOTYP = '*FILE'
   AND TRIM(WHLNAM) = CURRENT SCHEMA
UNION ALL
SELECT '  ' CONCAT SPECIFIC_NAME
       CONCAT ' --> ' CONCAT OBJECT_NAME
  FROM QSYS2.SYSROUTINEDEP
 WHERE SPECIFIC_SCHEMA = CURRENT SCHEMA
   AND OBJECT_TYPE = 'PROCEDURE';
