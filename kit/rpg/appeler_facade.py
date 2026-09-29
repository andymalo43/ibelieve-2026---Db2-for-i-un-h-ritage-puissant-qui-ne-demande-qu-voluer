"""Kit iBelieve 2026 — RPG — lire en ODBC ce que le RPG a calculé, par la fonction table F_TARIF_RPG3.

    pip install pyodbc        (pilote IBM i Access ODBC installé, DSN « MONIBMI » déclaré)

pyodbc ne lit pas les paramètres OUT d'un CALL : la fonction table (16-appeler.sql) rend les
valeurs en ligne. Remplacer VOTREBIB. Prérequis : 16-appeler.sql.
"""
import pyodbc

cnx = pyodbc.connect("DSN=MONIBMI")   # IBM i Access ODBC
remise, tva, ttc, rc = cnx.execute(
    "SELECT * FROM TABLE(VOTREBIB.F_TARIF_RPG3(?, ?)) T",
    10000.00, 5.00).fetchone()
print(remise, tva, ttc)   # 9500.00 1900.00 11400.00
