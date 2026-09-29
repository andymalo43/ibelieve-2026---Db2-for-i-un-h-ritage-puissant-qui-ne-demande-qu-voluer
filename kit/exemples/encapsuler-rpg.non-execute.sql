-- =====================================================================
-- Kit iBelieve 2026 — Exemple NON EXÉCUTÉ par le kit (slide « Étape 2 — Encapsuler »).
-- Déclarer un programme RPG existant comme procédure stockée, sans le recompiler.
-- À adapter : bibliothèque, nom du programme, paramètres (ceux de son *ENTRY PLIST).
-- =====================================================================

-- Exemple : votre programme RPG III existant, derrière un contrat SQL
CREATE OR REPLACE PROCEDURE VOTREBIB.CALC_TARIF (
    IN  P_MONTANT_HT  DECIMAL(9, 2),
    IN  P_TAUX_REMISE DECIMAL(5, 2),
    OUT P_TTC         DECIMAL(11, 2),
    OUT P_RC          CHAR(1))
  LANGUAGE RPG                          -- RPG, pas RPGLE : c'est de l'OPM
  NOT DETERMINISTIC  NO SQL
  EXTERNAL NAME 'VOTREBIB/TARIFOPM'
  PARAMETER STYLE GENERAL;

CALL VOTREBIB.CALC_TARIF(10000.00, 5.00, ?, ?);
