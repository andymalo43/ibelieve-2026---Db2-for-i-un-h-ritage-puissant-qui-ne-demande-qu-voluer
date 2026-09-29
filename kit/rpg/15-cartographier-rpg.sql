-- =====================================================================
-- Kit iBelieve 2026 — RPG — 15. Cartographier du vrai RPG avec DSPPGMREF
-- Sur des programmes RPG, DSPPGMREF donne aussi les appels (objets *PGM) :
-- la chaîne se reconstitue sans le catalogue. N'écrit que dans QTEMP.
-- Prérequis : 12-compiler.sql.
-- =====================================================================

SET SCHEMA VOTREBIB;

CALL QSYS2.QCMDEXC(
  'DSPPGMREF PGM(' CONCAT CURRENT SCHEMA CONCAT '/*ALL) OUTPUT(*OUTFILE) '
  CONCAT 'OBJTYPE(*PGM) OUTFILE(QTEMP/PGMREF) OUTMBR(*FIRST *REPLACE)');

-- La chaîne d'appels depuis VALDEVIS
WITH CHAINE (APPELANT, APPELE, NIVEAU, CHEMIN) AS (
  SELECT TRIM(WHPNAM), TRIM(WHFNAM), 1,
         CAST(TRIM(WHPNAM) CONCAT ' > ' CONCAT TRIM(WHFNAM) AS VARCHAR(4000))
    FROM QTEMP.PGMREF
   WHERE WHPNAM = 'VALDEVIS' AND WHOTYP = '*PGM' AND WHLNAM <> 'QSYS'
  UNION ALL
  SELECT TRIM(R.WHPNAM), TRIM(R.WHFNAM), C.NIVEAU + 1,
         C.CHEMIN CONCAT ' > ' CONCAT TRIM(R.WHFNAM)
    FROM CHAINE C
    JOIN QTEMP.PGMREF R ON TRIM(R.WHPNAM) = C.APPELE
   WHERE R.WHOTYP = '*PGM' AND R.WHLNAM <> 'QSYS'
     AND C.NIVEAU < 15                                    -- profondeur max
     AND LOCATE(' ' CONCAT TRIM(R.WHFNAM) CONCAT ' ',
                ' ' CONCAT C.CHEMIN CONCAT ' ') = 0       -- pas de boucle
)
SELECT NIVEAU, CHEMIN FROM CHAINE ORDER BY CHEMIN;

-- Qui utilise DEVIS, et comment (1 lecture, 2 écriture, 4 mise à jour, cumulables) ?
SELECT TRIM(WHPNAM) AS PROGRAMME, WHFUSG AS USAGE
  FROM QTEMP.PGMREF
 WHERE WHFNAM = 'DEVIS' AND WHOTYP = '*FILE'
 ORDER BY PROGRAMME;
