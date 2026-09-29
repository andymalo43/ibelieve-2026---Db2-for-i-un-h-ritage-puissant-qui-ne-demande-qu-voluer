-- =====================================================================
-- Kit iBelieve 2026 — RPG — 16. Appeler la façade depuis l'extérieur (JDBC, ODBC)
-- JDBC lit les paramètres OUT directement : voir AppelerFacade.java.
-- Beaucoup de clients ODBC (pyodbc, outils BI) ne lisent pas les paramètres OUT :
-- une fonction table appelle la façade et rend ses valeurs en ligne. Voir appeler_facade.py.
-- ÉCRIT : la fonction F_TARIF_RPG3. Prérequis : 13-facades.sql.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Les valeurs calculées par le RPG, en ligne : lisible par n'importe quel client SQL
CREATE OR REPLACE FUNCTION F_TARIF_RPG3 (P_MONTANT_HT  DECIMAL(9, 2),
                                        P_TAUX_REMISE DECIMAL(5, 2))
  RETURNS TABLE (REMISE DECIMAL(11, 2), TVA DECIMAL(11, 2),
                 TTC    DECIMAL(11, 2), RC  CHAR(1))
  LANGUAGE SQL
  SPECIFIC F_TARIF3                  -- nom du *SRVPGM créé (10 caractères au plus)
  NOT DETERMINISTIC
BEGIN
  DECLARE V_REMISE, V_TVA, V_TTC DECIMAL(11, 2) DEFAULT 0;   -- pas de NULL (SQL0470)
  DECLARE V_RC CHAR(1) DEFAULT ' ';
  CALL PS_CALC_TARIF_RPG3(P_MONTANT_HT, P_TAUX_REMISE, V_REMISE, V_TVA, V_TTC, V_RC);
  PIPE (V_REMISE, V_TVA, V_TTC, V_RC);
  RETURN;
END;

-- Ce que voit un client ODBC
SELECT * FROM TABLE(F_TARIF_RPG3(10000.00, 5.00)) T;
