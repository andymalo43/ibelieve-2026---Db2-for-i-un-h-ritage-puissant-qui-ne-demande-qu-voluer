-- =====================================================================
-- Kit iBelieve 2026 — 04. La base elle-même : régénérer le DDL de sa bibliothèque.
-- N'écrit que dans QTEMP (fichier source Q_GENSQL) ; le DDL revient aussi en résultat.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

CALL QSYS2.GENERATE_SQL('%', CURRENT SCHEMA, 'TABLE', REPLACE_OPTION => '0');
