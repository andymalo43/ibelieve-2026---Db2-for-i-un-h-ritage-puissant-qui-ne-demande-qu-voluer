-- =====================================================================
-- Kit iBelieve 2026 — RPG — 15. Cartographier une chaîne qui traverse SQL et RPG
-- (slides « 2.1 Cartographier » et « La chaîne d'appels, du SQL jusqu'au RPG »)
-- Trois sources, une table T_APPELS :
--   SYSROUTINEDEP            procédure SQL → procédure
--   SYSROUTINES              façade → programme (EXTERNAL_NAME)
--   DSPPGMREF                programme → programme, programme → table
-- ÉCRIT dans votre bibliothèque : T_PGMREF et T_APPELS, le référentiel matérialisé.
-- Prérequis : 13-facades.sql (façades et PS_TRAITER_DEVIS).
-- =====================================================================

SET SCHEMA VOTREBIB;

-- Qui référence quoi ? DSPPGMREF, piloté en SQL, matérialisé dans la bibliothèque
CALL QSYS2.QCMDEXC(
  'DSPPGMREF PGM(' CONCAT CURRENT SCHEMA CONCAT '/*ALL) OUTPUT(*OUTFILE) OBJTYPE(*PGM) '
  CONCAT 'OUTFILE(' CONCAT CURRENT SCHEMA CONCAT '/T_PGMREF) OUTMBR(*FIRST *REPLACE)');

-- Combien de programmes analysés, d'appels entre eux, de références de tables ?
-- (hors bibliothèques système : moteur SQL, runtime RPG, catalogue)
SELECT COUNT(DISTINCT WHPNAM) AS PROGRAMMES,
       SUM(CASE WHEN WHOTYP = '*PGM'  AND WHLNAM NOT IN ('QSYS', 'QSYS2') THEN 1 ELSE 0 END) AS APPELS,
       SUM(CASE WHEN WHOTYP = '*FILE' AND WHLNAM NOT IN ('QSYS', 'QSYS2') THEN 1 ELSE 0 END) AS TABLES_
  FROM T_PGMREF;

-- Le graphe des appels, matérialisé : trois sources, une table
CREATE OR REPLACE TABLE T_APPELS (APPELANT, APPELE, SOURCE) AS (
  SELECT R.ROUTINE_NAME, D.OBJECT_NAME, 'SYSROUTINEDEP'        -- procédure → procédure
    FROM QSYS2.SYSROUTINEDEP D
    JOIN QSYS2.SYSROUTINES R ON R.SPECIFIC_SCHEMA = D.SPECIFIC_SCHEMA
                            AND R.SPECIFIC_NAME   = D.SPECIFIC_NAME
   WHERE D.SPECIFIC_SCHEMA = CURRENT SCHEMA AND D.OBJECT_TYPE = 'PROCEDURE'
  UNION
  SELECT ROUTINE_NAME, SUBSTR(EXTERNAL_NAME, LOCATE('/', EXTERNAL_NAME) + 1),
         'SYSROUTINES'                                         -- façade → programme
    FROM QSYS2.SYSROUTINES
   WHERE ROUTINE_SCHEMA = CURRENT SCHEMA AND ROUTINE_BODY = 'EXTERNAL'
  UNION
  SELECT TRIM(WHPNAM), TRIM(WHFNAM), 'DSPPGMREF'               -- programme → programme
    FROM T_PGMREF WHERE WHOTYP = '*PGM' AND WHLNAM NOT IN ('QSYS', 'QSYS2')
) WITH DATA ON REPLACE DELETE ROWS;

-- La chaîne d'appels depuis PS_TRAITER_DEVIS, du SQL jusqu'au RPG
WITH CHAINE (APPELE, NIVEAU, CHEMIN, SOURCE) AS (
  SELECT APPELE, 1, CAST(APPELANT CONCAT ' > ' CONCAT APPELE AS VARCHAR(1000)), SOURCE
    FROM T_APPELS WHERE APPELANT = 'PS_TRAITER_DEVIS'
  UNION ALL
  SELECT A.APPELE, C.NIVEAU + 1, C.CHEMIN CONCAT ' > ' CONCAT A.APPELE, A.SOURCE
    FROM CHAINE C JOIN T_APPELS A ON A.APPELANT = C.APPELE
   WHERE C.NIVEAU < 15                                    -- profondeur max
     AND LOCATE(' ' CONCAT A.APPELE CONCAT ' ',
                ' ' CONCAT C.CHEMIN CONCAT ' ') = 0       -- pas de boucle
)
SELECT NIVEAU, CHEMIN, SOURCE FROM CHAINE ORDER BY CHEMIN;

-- En réserve : qui utilise DEVIS, et comment (1 lecture, 2 écriture, 4 mise à jour, cumulables) ?
SELECT TRIM(WHPNAM) AS PROGRAMME, WHFUSG AS USAGE
  FROM T_PGMREF
 WHERE WHFNAM = 'DEVIS' AND WHOTYP = '*FILE'
 ORDER BY PROGRAMME;

-- Un diagramme sans outil : le SQL écrit du Mermaid, procédures PS_ en couleur
SELECT 'graph LR' AS LIGNE FROM SYSIBM.SYSDUMMY1
UNION ALL
SELECT DISTINCT '  ' CONCAT APPELANT CONCAT ' --> ' CONCAT APPELE FROM T_APPELS
UNION ALL
SELECT DISTINCT '  ' CONCAT TRIM(WHPNAM) CONCAT ' --> '
       CONCAT TRIM(WHFNAM) CONCAT '[(' CONCAT TRIM(WHFNAM) CONCAT ')]'
  FROM T_PGMREF                                 -- [( )] : table en cylindre
 WHERE WHOTYP = '*FILE' AND WHLNAM NOT IN ('QSYS', 'QSYS2')
UNION ALL
SELECT '  class ' CONCAT ROUTINE_NAME CONCAT ' ps' FROM QSYS2.SYSROUTINES
 WHERE ROUTINE_SCHEMA = CURRENT SCHEMA AND ROUTINE_TYPE = 'PROCEDURE'
UNION ALL
SELECT '  classDef ps fill:#5d8392,stroke:#3f5f6b,color:#fff' FROM SYSIBM.SYSDUMMY1;
