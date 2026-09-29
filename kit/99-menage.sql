-- =====================================================================
-- Kit iBelieve 2026 — 99. Ménage : supprime tout ce que le kit a créé.
-- Le journal QSQJRN n'est supprimé que s'il a été créé par le kit (récepteurs KITRCV*).
-- Restent 6 vues SYS* (SYSCST, SYSREFCST…) : Db2 les crée et les gère lui-même
-- dès qu'une bibliothèque porte des contraintes ; elles ne se suppriment pas en SQL.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

DROP PROCEDURE CREERDEVIS;
DROP PROCEDURE FACTURER;
DROP PROCEDURE VALIDER;
DROP PROCEDURE CONTROLER;
DROP PROCEDURE CALCULER;
DROP PROCEDURE TARIFER;
DROP PROCEDURE NUMEROTER;
DROP TABLE FACTURE;
DROP TABLE DEVLIG;
DROP TABLE DEVIS;
DROP TABLE COMPTEUR;
DROP TABLE CLIENT;

BEGIN
  IF EXISTS (SELECT 1 FROM TABLE (QSYS2.OBJECT_STATISTICS(CURRENT SCHEMA, '*JRNRCV')) R
              WHERE R.OBJNAME LIKE 'KITRCV%') THEN
    CALL QSYS2.QCMDEXC('DLTJRN JRN(' CONCAT CURRENT SCHEMA CONCAT '/QSQJRN)');
    FOR R AS SELECT OBJNAME FROM TABLE (QSYS2.OBJECT_STATISTICS(CURRENT SCHEMA, '*JRNRCV')) X
              WHERE OBJNAME LIKE 'KITRCV%'
    DO
      CALL QSYS2.QCMDEXC('DLTJRNRCV JRNRCV(' CONCAT CURRENT SCHEMA CONCAT '/' CONCAT R.OBJNAME
                         CONCAT ') DLTOPT(*IGNINQMSG)');
    END FOR;
  END IF;
END;

-- Ce qui reste dans la bibliothèque
SELECT OBJNAME, OBJTYPE FROM TABLE (QSYS2.OBJECT_STATISTICS(CURRENT SCHEMA, '*ALL')) X
 ORDER BY OBJTYPE, OBJNAME;
