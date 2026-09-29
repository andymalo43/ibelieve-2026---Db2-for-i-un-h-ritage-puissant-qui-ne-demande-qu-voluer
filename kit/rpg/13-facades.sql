-- =====================================================================
-- Kit iBelieve 2026 — RPG — 13. Encapsuler : des programmes existants deviennent des procédures
-- Aucun programme n'est recompilé : on n'écrit que du DDL. Prérequis : 12-compiler.sql.
-- Trois implémentations d'époques différentes du même calcul (RPG III, RPG IV, code généré
-- façon Adélia), derrière un contrat SQL identique ; puis la validation et la facturation,
-- et une procédure SQL qui les compose (PS_TRAITER_DEVIS).
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Les programmes s'appellent par leur nom (*LIBL) et CTLENCOURS ouvre CLIENT par *LIBL :
-- la bibliothèque du kit doit passer devant toute autre qui aurait les mêmes noms.
-- ADDLIBLE ne suffit pas : la bibliothèque en cours (CURLIB) est cherchée avant la
-- partie utilisateur de la liste. On en fait donc la bibliothèque en cours de la session.
CALL QSYS2.QCMDEXC('CHGCURLIB CURLIB(' CONCAT CURRENT SCHEMA CONCAT ')');

-- ---------------------------------------------------------------------
-- 1. RPG III (OPM)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PS_CALC_TARIF_RPG3 (
    IN  p_montant_ht   DECIMAL(9,2),
    IN  p_taux_remise  DECIMAL(5,2),
    OUT p_remise       DECIMAL(11,2),
    OUT p_tva          DECIMAL(11,2),
    OUT p_ttc          DECIMAL(11,2),
    OUT p_rc           CHAR(1)
)
  LANGUAGE RPG                       -- RPG, pas RPGLE : c'est de l'OPM
  SPECIFIC PS_TARIF3
  NOT DETERMINISTIC
  NO SQL
  EXTERNAL NAME 'VOTREBIB/CALCTAR3'
  PARAMETER STYLE GENERAL;

CALL PS_CALC_TARIF_RPG3(10000.00, 5.00, ?, ?, ?, ?);

-- ---------------------------------------------------------------------
-- 2. RPG IV free-form (ILE)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PS_CALC_TARIF_RPGLE (
    IN  p_montant_ht   DECIMAL(9,2),
    IN  p_taux_remise  DECIMAL(5,2),
    OUT p_remise       DECIMAL(11,2),
    OUT p_tva          DECIMAL(11,2),
    OUT p_ttc          DECIMAL(11,2),
    OUT p_rc           CHAR(1)
)
  LANGUAGE RPGLE
  SPECIFIC PS_TARIF4
  NOT DETERMINISTIC
  NO SQL
  EXTERNAL NAME 'VOTREBIB/CALCTARIF'
  PARAMETER STYLE GENERAL;

CALL PS_CALC_TARIF_RPGLE(10000.00, 5.00, ?, ?, ?, ?);

-- ---------------------------------------------------------------------
-- 3. Adélia (module serveur SADELIA — RPG généré)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PS_CALC_TARIF_ADELIA (
    IN  p_montant_ht   DECIMAL(9,2),
    IN  p_taux_remise  DECIMAL(5,2),
    OUT p_remise       DECIMAL(11,2),
    OUT p_tva          DECIMAL(11,2),
    OUT p_ttc          DECIMAL(11,2),
    OUT p_rc           CHAR(1)
)
  LANGUAGE RPGLE                     -- le généré est du RPG IV
  SPECIFIC PS_TARIFA
  NOT DETERMINISTIC
  NO SQL
  EXTERNAL NAME 'VOTREBIB/CALCTARA'   -- bibliothèque des modules serveur
  PARAMETER STYLE GENERAL;

CALL PS_CALC_TARIF_ADELIA(10000.00, 5.00, ?, ?, ?, ?);

-- ---------------------------------------------------------------------
-- Validation (chaîne VALDEVIS -> CALCDEVIS -> CALCTARIF)
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PS_VAL_DEVIS (
    IN  p_devis  DECIMAL(9,0),
    OUT p_ttc    DECIMAL(11,2),
    OUT p_dispo  DECIMAL(11,2),
    OUT p_rc     CHAR(1)
)
  LANGUAGE RPGLE
  SPECIFIC PS_VALDEV
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
CREATE OR REPLACE PROCEDURE PS_GEN_FACT (
    IN  p_devis    DECIMAL(9,0),
    IN  p_date     DECIMAL(8,0),
    OUT p_facture  DECIMAL(9,0),
    OUT p_rc       CHAR(1)
)
  LANGUAGE RPGLE
  SPECIFIC PS_GEN_FACT
  NOT DETERMINISTIC
  MODIFIES SQL DATA
  COMMIT ON RETURN NO
  EXTERNAL NAME 'VOTREBIB/GENFACT'
  PARAMETER STYLE GENERAL;

-- ---------------------------------------------------------------------
-- Composer : une procédure SQL enchaîne les deux façades
--
-- Du SQL neuf par-dessus du RPG existant, sans le toucher. C'est aussi le
-- point de départ de la cartographie (15-cartographier-rpg.sql) : une chaîne
-- qui part du SQL et descend dans les programmes.
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PS_TRAITER_DEVIS (
    IN  p_devis    DECIMAL(9,0),
    IN  p_date     DECIMAL(8,0),
    OUT p_facture  DECIMAL(9,0),
    OUT p_rc       CHAR(1)
)
  LANGUAGE SQL
  SPECIFIC PS_TRTDEV
BEGIN
  DECLARE v_ttc, v_dispo DECIMAL(11,2) DEFAULT 0;   -- pas de NULL vers le RPG (SQL0470)
  DECLARE v_facture      DECIMAL(9,0)  DEFAULT 0;
  DECLARE v_rc           CHAR(1)       DEFAULT ' ';
  CALL PS_VAL_DEVIS(p_devis, v_ttc, v_dispo, v_rc);
  IF v_rc = ' ' THEN
    CALL PS_GEN_FACT(p_devis, p_date, v_facture, v_rc);
  END IF;
  SET p_facture = v_facture;
  SET p_rc      = v_rc;
END;
