-- =====================================================================
-- Kit iBelieve 2026 — RPG — 14. Rejouer : les trois versions sont-elles équivalentes ? la chaîne tourne-t-elle ?
-- ÉCRIT : tables de test T_CAS, T_COMPARE ; valide et facture des devis du jeu d'essai.
-- Prérequis : 13-facades.sql. Pour rejouer la chaîne : relancer 10-terrain-rpg.sql.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Les programmes s'appellent par leur nom (*LIBL) et CTLENCOURS ouvre CLIENT par *LIBL :
-- la bibliothèque du kit doit passer devant toute autre qui aurait les mêmes noms.
-- ADDLIBLE ne suffit pas : la bibliothèque en cours (CURLIB) est cherchée avant la
-- partie utilisateur de la liste. On en fait donc la bibliothèque en cours de la session.
CALL QSYS2.QCMDEXC('CHGCURLIB CURLIB(' CONCAT CURRENT SCHEMA CONCAT ')');

-- ---------------------------------------------------------------------
-- Avant de remplacer une implémentation, prouver l'équivalence sur un jeu de valeurs
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE T_COMPARE (
    CMP_HT     DECIMAL(9,2),
    CMP_TAUX   DECIMAL(5,2),
    CMP_IMPL   CHAR(10),
    CMP_REMISE DECIMAL(11,2),
    CMP_TVA    DECIMAL(11,2),
    CMP_TTC    DECIMAL(11,2),
    CMP_RC     CHAR(1)
) ON REPLACE DELETE ROWS;                 -- sinon CREATE OR REPLACE garde les lignes

-- ---------------------------------------------------------------------
-- Jeu de valeurs : nominal, arrondis pénibles, bornes, erreurs
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE T_CAS (
    CAS_HT   DECIMAL(9,2),
    CAS_TAUX DECIMAL(5,2)
) ON REPLACE DELETE ROWS;

INSERT INTO T_CAS VALUES
  (10000.00,  5.00),   -- nominal
  (    0.00,  5.00),   -- zéro
  (  333.33,  3.33),   -- arrondi au centime : le cas qui divergera
  (   99.99, 33.33),   -- idem
  (10000.00,  0.00),   -- pas de remise
  (10000.00,100.00),   -- borne haute acceptée
  (10000.00,100.01),   -- refus attendu
  (10000.00, -1.00);   -- refus attendu

-- ---------------------------------------------------------------------
-- Exécution des trois implémentations sur tous les cas
-- ---------------------------------------------------------------------
BEGIN
  -- Initialisées : PARAMETER STYLE GENERAL refuse un NULL, même en sortie (SQL0470)
  DECLARE v_rem, v_tva, v_ttc DECIMAL(11,2) DEFAULT 0;
  DECLARE v_rc CHAR(1) DEFAULT ' ';

  DELETE FROM T_COMPARE;

  FOR c AS SELECT CAS_HT, CAS_TAUX FROM T_CAS DO

    CALL PS_CALC_TARIF_RPG3 (c.CAS_HT, c.CAS_TAUX, v_rem, v_tva, v_ttc, v_rc);
    INSERT INTO T_COMPARE
      VALUES (c.CAS_HT, c.CAS_TAUX, 'RPG3', v_rem, v_tva, v_ttc, v_rc);

    CALL PS_CALC_TARIF_RPGLE (c.CAS_HT, c.CAS_TAUX, v_rem, v_tva, v_ttc, v_rc);
    INSERT INTO T_COMPARE
      VALUES (c.CAS_HT, c.CAS_TAUX, 'RPGLE', v_rem, v_tva, v_ttc, v_rc);

    CALL PS_CALC_TARIF_ADELIA (c.CAS_HT, c.CAS_TAUX, v_rem, v_tva, v_ttc, v_rc);
    INSERT INTO T_COMPARE
      VALUES (c.CAS_HT, c.CAS_TAUX, 'ADELIA', v_rem, v_tva, v_ttc, v_rc);

  END FOR;
END;

-- ---------------------------------------------------------------------
-- Le verdict : toute ligne qui sort est une divergence
-- ---------------------------------------------------------------------
SELECT CMP_HT, CMP_TAUX,
       COUNT(DISTINCT CMP_REMISE) AS n_remise,
       COUNT(DISTINCT CMP_TVA)    AS n_tva,
       COUNT(DISTINCT CMP_TTC)    AS n_ttc,
       COUNT(DISTINCT CMP_RC)     AS n_rc,
       LISTAGG(TRIM(CMP_IMPL) || '=' || CHAR(CMP_TTC), ' | ')
         WITHIN GROUP (ORDER BY CMP_IMPL) AS detail
FROM   T_COMPARE
GROUP BY CMP_HT, CMP_TAUX
HAVING COUNT(DISTINCT CMP_REMISE) > 1
    OR COUNT(DISTINCT CMP_TVA)    > 1
    OR COUNT(DISTINCT CMP_TTC)    > 1
    OR COUNT(DISTINCT CMP_RC)     > 1
ORDER BY CMP_HT, CMP_TAUX;

-- Zéro ligne = les trois implémentations sont interchangeables.
-- Une ligne = un arrondi diverge entre deux versions. C'est le résultat
-- le plus instructif : encapsuler n'efface pas les différences, ça les rend testables.

-- ---------------------------------------------------------------------
-- La chaîne réelle : VALDEVIS -> CALCDEVIS -> CALCTARIF (+ CTLENCOURS), puis GENFACT
-- ---------------------------------------------------------------------
CALL PS_VAL_DEVIS(500001, ?, ?, ?);       -- attendu ' ', TTC 11400.00
CALL PS_VAL_DEVIS(500002, ?, ?, ?);       -- attendu 'E' : encours 48000/50000
CALL PS_VAL_DEVIS(500001, ?, ?, ?);       -- attendu 'S' : déjà validé
CALL PS_GEN_FACT (500004, 20260904, ?, ?); -- attendu ' ', facture 1001
CALL PS_GEN_FACT (500004, 20260904, ?, ?); -- attendu 'D' : déjà facturé (la contrainte UQ_FACDEV veille)
CALL PS_TRAITER_DEVIS(500003, 20260905, ?, ?);  -- attendu facture 1002, ' ' : validé puis facturé
