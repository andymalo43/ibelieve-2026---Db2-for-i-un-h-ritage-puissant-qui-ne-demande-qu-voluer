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

-- La chaîne d'appels depuis PS_VALIDER, lue dans le catalogue
-- SYSROUTINEDEP nomme l'appelant par son nom spécifique, l'appelé par son nom SQL :
-- SYSROUTINES fait le lien, pour avoir le nom SQL des deux côtés.
WITH APPELS (APPELANT, APPELE) AS (
  SELECT R.ROUTINE_NAME, D.OBJECT_NAME
    FROM QSYS2.SYSROUTINEDEP D
    JOIN QSYS2.SYSROUTINES R ON R.SPECIFIC_SCHEMA = D.SPECIFIC_SCHEMA
                            AND R.SPECIFIC_NAME   = D.SPECIFIC_NAME
   WHERE D.SPECIFIC_SCHEMA = CURRENT SCHEMA AND D.OBJECT_TYPE = 'PROCEDURE'
), CHAINE (APPELE, NIVEAU, CHEMIN) AS (
  SELECT APPELE, 1, CAST(APPELANT CONCAT ' > ' CONCAT APPELE AS VARCHAR(1000))
    FROM APPELS WHERE APPELANT = 'PS_VALIDER'
  UNION ALL
  SELECT A.APPELE, C.NIVEAU + 1, C.CHEMIN CONCAT ' > ' CONCAT A.APPELE
    FROM CHAINE C JOIN APPELS A ON A.APPELANT = C.APPELE
   WHERE C.NIVEAU < 15                                       -- profondeur max
     AND LOCATE(' ' CONCAT A.APPELE CONCAT ' ', ' ' CONCAT C.CHEMIN CONCAT ' ') = 0
)
SELECT NIVEAU, CHEMIN FROM CHAINE ORDER BY CHEMIN;

-- En réserve : qui utilise la table DEVIS, et comment (1 lecture, 2 écriture, 4 mise à jour…) ?
SELECT TRIM(WHPNAM) AS PROGRAMME, WHFUSG AS USAGE
  FROM QTEMP.PGMREF
 WHERE WHFNAM = 'DEVIS' AND WHOTYP = '*FILE'
 ORDER BY PROGRAMME;

-- Un diagramme sans outil : le SQL écrit du Mermaid (appels + tables), en noms SQL
-- (DSPPGMREF donne le nom du *PGM, c'est-à-dire le nom spécifique)
SELECT 'graph TD' AS LIGNE FROM SYSIBM.SYSDUMMY1
UNION ALL
SELECT DISTINCT '  ' CONCAT R.ROUTINE_NAME CONCAT ' --> '
       CONCAT TRIM(P.WHFNAM) CONCAT '[(' CONCAT TRIM(P.WHFNAM) CONCAT ')]'
  FROM QTEMP.PGMREF P                           -- [( )] : table en cylindre
  JOIN QSYS2.SYSROUTINES R ON R.SPECIFIC_SCHEMA = CURRENT SCHEMA
                          AND R.SPECIFIC_NAME   = TRIM(P.WHPNAM)
 WHERE P.WHOTYP = '*FILE' AND TRIM(P.WHLNAM) = CURRENT SCHEMA
UNION ALL
SELECT '  ' CONCAT R.ROUTINE_NAME CONCAT ' --> ' CONCAT D.OBJECT_NAME
  FROM QSYS2.SYSROUTINEDEP D
  JOIN QSYS2.SYSROUTINES R ON R.SPECIFIC_SCHEMA = D.SPECIFIC_SCHEMA
                          AND R.SPECIFIC_NAME   = D.SPECIFIC_NAME
 WHERE D.SPECIFIC_SCHEMA = CURRENT SCHEMA AND D.OBJECT_TYPE = 'PROCEDURE';
