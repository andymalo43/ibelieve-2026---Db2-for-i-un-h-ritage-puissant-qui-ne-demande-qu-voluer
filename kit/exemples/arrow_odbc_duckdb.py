"""Kit iBelieve 2026 — exemple NON EXÉCUTÉ de la slide « ODBC → Arrow → DuckDB ».

Prérequis : pilote IBM i Access ODBC, puis  pip install arrow-odbc pyarrow duckdb
Adapter la chaîne de connexion (System, UID, PWD…) et la bibliothèque.
"""
from arrow_odbc import read_arrow_batches_from_odbc
import pyarrow as pa
import duckdb

reader = read_arrow_batches_from_odbc(
    query="SELECT * FROM VOTREBIB.CLIENT",
    connection_string="Driver={IBM i Access "
                      "ODBC Driver};System=MONIBMI;...",
    batch_size=50_000,
)
clients = pa.Table.from_batches(
    reader, schema=reader.schema)

duckdb.sql(
  "CREATE TABLE client AS SELECT * FROM clients")
