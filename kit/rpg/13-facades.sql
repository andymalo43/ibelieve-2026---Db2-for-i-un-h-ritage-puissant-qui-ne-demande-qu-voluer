-- =====================================================================
-- Kit iBelieve 2026 — RPG — 13. Encapsuler : des programmes existants deviennent des procédures
-- Aucun programme n'est recompilé : on n'écrit que du DDL. Prérequis : 12-compiler.sql.
-- Trois implémentations d'époques différentes du même calcul (RPG III, RPG IV, code généré
-- façon Adélia), derrière un contrat SQL identique ; puis la validation et la facturation.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Les programmes s'appellent par leur nom : la bibliothèque doit être dans la liste
BEGIN
  DECLARE V_DEJA INTEGER DEFAULT 0;
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET V_DEJA = 1;   -- déjà dans la liste
  CALL QSYS2.QCMDEXC('ADDLIBLE ' CONCAT CURRENT SCHEMA);
END;

-- ---------------------------------------------------------------------
-- 1. RPG III (OPM)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CALC_TARIF_RPG3 (
    IN  p_montant_ht   DECIMAL(9,2),
    IN  p_taux_remise  DECIMAL(5,2),
    OUT p_remise       DECIMAL(11,2),
    OUT p_tva          DECIMAL(11,2),
    OUT p_ttc          DECIMAL(11,2),
    OUT p_rc           CHAR(1)
)
  LANGUAGE RPG                       -- RPG, pas RPGLE : c'est de l'OPM
  SPECIFIC CALCTARIF3
  NOT DETERMINISTIC
  NO SQL
  EXTERNAL NAME 'VOTREBIB/CALCTAR3'
  PARAMETER STYLE GENERAL;

CALL CALC_TARIF_RPG3(10000.00, 5.00, ?, ?, ?, ?);

-- ---------------------------------------------------------------------
-- 2. RPG IV free-form (ILE)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CALC_TARIF_RPGLE (
    IN  p_montant_ht   DECIMAL(9,2),
    IN  p_taux_remise  DECIMAL(5,2),
    OUT p_remise       DECIMAL(11,2),
    OUT p_tva          DECIMAL(11,2),
    OUT p_ttc          DECIMAL(11,2),
    OUT p_rc           CHAR(1)
)
  LANGUAGE RPGLE
  SPECIFIC CALCTARIF4
  NOT DETERMINISTIC
  NO SQL
  EXTERNAL NAME 'VOTREBIB/CALCTARIF'
  PARAMETER STYLE GENERAL;

CALL CALC_TARIF_RPGLE(10000.00, 5.00, ?, ?, ?, ?);

-- ---------------------------------------------------------------------
-- 3. Adélia (module serveur SADELIA — RPG généré)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CALC_TARIF_ADELIA (
    IN  p_montant_ht   DECIMAL(9,2),
    IN  p_taux_remise  DECIMAL(5,2),
    OUT p_remise       DECIMAL(11,2),
    OUT p_tva          DECIMAL(11,2),
    OUT p_ttc          DECIMAL(11,2),
    OUT p_rc           CHAR(1)
)
  LANGUAGE RPGLE                     -- le généré est du RPG IV
  SPECIFIC CALCTARIFA
  NOT DETERMINISTIC
  NO SQL
  EXTERNAL NAME 'VOTREBIB/CALCTARA'   -- bibliothèque des modules serveur
  PARAMETER STYLE GENERAL;

CALL CALC_TARIF_ADELIA(10000.00, 5.00, ?, ?, ?, ?);

-- ---------------------------------------------------------------------
-- Validation (chaîne VALDEVIS -> CALCDEVIS -> CALCTARIF)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE VAL_DEVIS (
    IN  p_devis  DECIMAL(9,0),
    OUT p_ttc    DECIMAL(11,2),
    OUT p_dispo  DECIMAL(11,2),
    OUT p_rc     CHAR(1)
)
  LANGUAGE RPGLE
  SPECIFIC VAL_DEVIS
  NOT DETERMINISTIC
  MODIFIES SQL DATA            -- VALDEVIS et CALCDEVIS font des UPDATE
  EXTERNAL NAME 'VOTREBIB/VALDEVIS'
  PARAMETER STYLE GENERAL;

-- ---------------------------------------------------------------------
-- Facturation
--
-- COMMIT ON RETURN NO : la procédure ne commite rien elle-même.
-- C'est GENFACT qui possède sa transaction (COMMIT / ROLLBACK dans
-- le programme). Frontière nette : l'appelant n'a rien à gérer.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE GEN_FACT (
    IN  p_devis    DECIMAL(9,0),
    IN  p_date     DECIMAL(8,0),
    OUT p_facture  DECIMAL(9,0),
    OUT p_rc       CHAR(1)
)
  LANGUAGE RPGLE
  SPECIFIC GEN_FACT
  NOT DETERMINISTIC
  MODIFIES SQL DATA
  COMMIT ON RETURN NO
  EXTERNAL NAME 'VOTREBIB/GENFACT'
  PARAMETER STYLE GENERAL;

