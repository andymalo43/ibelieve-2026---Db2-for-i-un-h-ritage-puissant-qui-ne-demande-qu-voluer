"""Kit iBelieve 2026 — slide « 4.2 ODBC → DuckDB, avec ou sans Arrow » : lire l'IBM i en lots Arrow.

Prérequis : pilote IBM i Access ODBC, un DSN (ici MONIBMI) qui porte système, utilisateur et
mot de passe, puis  pip install arrow-odbc pyarrow duckdb. Remplacer VOTREBIB. Prérequis kit : 00-terrain.sql.
Exécuté sur pub400 le 30/09/2026, en connexion directe.
"""
from arrow_odbc import read_arrow_batches_from_odbc
import pyarrow as pa
import duckdb

reader = read_arrow_batches_from_odbc(
    query="SELECT * FROM VOTREBIB.CLIENT",
    connection_string="DSN=MONIBMI",
    batch_size=50_000,
)
clients = pa.Table.from_batches(
    reader, schema=reader.schema)

duckdb.sql(
  "CREATE TABLE client AS SELECT * FROM clients")
print(duckdb.sql("SELECT count(*) AS clients, sum(ENCOURS) AS encours FROM client"))
