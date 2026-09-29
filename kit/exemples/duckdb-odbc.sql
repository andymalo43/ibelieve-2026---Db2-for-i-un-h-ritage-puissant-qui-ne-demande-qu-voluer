-- =====================================================================
-- Kit iBelieve 2026 — Lire Db2 for i depuis DuckDB par ODBC (SQL DuckDB, pas Db2).
-- Slide « ODBC → DuckDB ». DuckDB ≥ 1.2, extension officielle odbc.
-- Prérequis : pilote IBM i Access ODBC, un DSN (ici MONIBMI) qui porte le système,
-- l'utilisateur et le mot de passe ; kit 00-terrain.sql dans VOTREBIB.
--   duckdb -f duckdb-odbc.sql
-- =====================================================================

INSTALL odbc;
LOAD odbc;

-- Une connexion, puis une requête exécutée par l'IBM i
SET VARIABLE ibmi = odbc_connect('DSN=MONIBMI');
CREATE TABLE client AS
  FROM odbc_query(getvariable('ibmi'),
                  'SELECT * FROM VOTREBIB.CLIENT');

-- Les données sont dans DuckDB : on analyse en local
SELECT count(*) AS clients, sum(ENCOURS) AS encours_total
  FROM client;

SELECT odbc_close(getvariable('ibmi'));
