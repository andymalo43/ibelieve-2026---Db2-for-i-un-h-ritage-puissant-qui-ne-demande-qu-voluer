-- =====================================================================
-- Kit iBelieve 2026 — Exemple NON EXÉCUTÉ (SQL DuckDB, pas Db2), cité à l'oral sur
-- la slide « ODBC → Arrow → DuckDB ». Prérequis : pilote IBM i Access ODBC et un DSN.
-- À valider avec votre pilote : ces extensions sont surtout testées sur d'autres bases.
-- =====================================================================

INSTALL nanodbc FROM community;
LOAD nanodbc;
SELECT * FROM odbc_query(
  connection => 'DSN=MONIBMI',
  query      => 'SELECT * FROM VOTREBIB.CLIENT');
