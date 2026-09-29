-- =====================================================================
-- Kit iBelieve 2026 « Db2 for i : un héritage puissant… » — 00. Le terrain
--
-- Crée dans VOTRE bibliothèque une mini-application de devis :
--   5 tables journalisées + 7 procédures SQL qui jouent le rôle des « programmes ».
-- À lancer dans ACS → Run SQL Scripts, après avoir remplacé VOTREBIB ci-dessous.
-- Tout se supprime avec 99-menage.sql.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Un journal nommé QSQJRN : Db2 y journalise d'office toute table créée ensuite
-- (une bibliothèque créée par CREATE SCHEMA en a déjà un ; une bibliothèque CRTLIB, non).
BEGIN
  IF NOT EXISTS (SELECT 1 FROM TABLE (QSYS2.OBJECT_STATISTICS(CURRENT SCHEMA, '*JRN')) J
                  WHERE J.OBJNAME = 'QSQJRN') THEN
    CALL QSYS2.QCMDEXC('CRTJRNRCV JRNRCV(' CONCAT CURRENT SCHEMA CONCAT '/KITRCV0001)');
    CALL QSYS2.QCMDEXC('CRTJRN JRN(' CONCAT CURRENT SCHEMA CONCAT '/QSQJRN) JRNRCV('
                       CONCAT CURRENT SCHEMA CONCAT '/KITRCV0001)');
  END IF;
END;

-- ---------------------------------------------------------------------
-- Les données
-- ---------------------------------------------------------------------
CREATE TABLE CLIENT (
  ID_CLIENT    INTEGER       NOT NULL PRIMARY KEY,
  NOM          VARCHAR(40)   NOT NULL,
  TAUX_REMISE  DECIMAL(5, 2) NOT NULL DEFAULT 0,      -- en %
  ENCOURS      DECIMAL(11, 2) NOT NULL DEFAULT 0,     -- déjà facturé, non payé
  PLAFOND      DECIMAL(11, 2) NOT NULL DEFAULT 0      -- encours autorisé
);

CREATE TABLE DEVIS (
  ID_DEVIS     INTEGER       NOT NULL PRIMARY KEY,
  ID_CLIENT    INTEGER       NOT NULL REFERENCES CLIENT,
  DATE_DEVIS   DECIMAL(8, 0) NOT NULL,                -- AAAAMMJJ, « parce que c'est partout »
  STATUT       CHAR(1)       NOT NULL DEFAULT 'B',    -- B brouillon, V validé, F facturé
  MONTANT_TTC  DECIMAL(11, 2) NOT NULL DEFAULT 0
);

CREATE TABLE DEVLIG (
  ID_DEVIS      INTEGER       NOT NULL REFERENCES DEVIS,
  LIGNE         SMALLINT      NOT NULL,
  ARTICLE       VARCHAR(20)   NOT NULL,
  QUANTITE      DECIMAL(7, 2) NOT NULL,
  PRIX_UNITAIRE DECIMAL(9, 2) NOT NULL,
  PRIMARY KEY (ID_DEVIS, LIGNE)
);

CREATE TABLE FACTURE (
  ID_FACTURE   INTEGER       NOT NULL PRIMARY KEY,
  ID_DEVIS     INTEGER       NOT NULL REFERENCES DEVIS,
  DATE_FACTURE DECIMAL(8, 0) NOT NULL,
  MONTANT_TTC  DECIMAL(11, 2) NOT NULL
);

CREATE TABLE COMPTEUR (
  CODE         VARCHAR(10)   NOT NULL PRIMARY KEY,
  VALEUR       INTEGER       NOT NULL
);

INSERT INTO CLIENT VALUES (1, 'Atelier Martin',      5.00,     0.00, 50000.00),
                          (2, 'Boulangerie du Port', 0.00, 48000.00, 50000.00),
                          (3, 'Garage des Iles',     10.00,    0.00,  1000.00);
INSERT INTO DEVIS VALUES (101, 1, 20260915, 'B', 0), (102, 2, 20260916, 'B', 0),
                         (103, 3, 20260917, 'B', 0);
INSERT INTO DEVLIG VALUES (101, 1, 'Etabli',      2, 1500.00), (101, 2, 'Etau',    4, 120.00),
                          (102, 1, 'Four a pain', 1, 4000.00),
                          (103, 1, 'Pont eleva',  1, 9000.00);
INSERT INTO COMPTEUR VALUES ('DEVIS', 103), ('FACTURE', 5000);

-- ---------------------------------------------------------------------
-- Les « programmes » : des procédures SQL qui s'appellent les unes les autres
-- ---------------------------------------------------------------------

-- Prochain numéro d'une série (devis, facture)
CREATE OR REPLACE PROCEDURE NUMEROTER (IN P_CODE VARCHAR(10), OUT P_VALEUR INTEGER)
LANGUAGE SQL
BEGIN
  UPDATE COMPTEUR SET VALEUR = VALEUR + 1 WHERE CODE = P_CODE;
  SELECT VALEUR INTO P_VALEUR FROM COMPTEUR WHERE CODE = P_CODE;
END;

-- Remise puis TVA à 20 % : un calcul pur, sans table
CREATE OR REPLACE PROCEDURE TARIFER (IN  P_HT   DECIMAL(11, 2), IN P_TAUX DECIMAL(5, 2),
                                     OUT P_TTC  DECIMAL(11, 2))
LANGUAGE SQL
BEGIN
  SET P_TTC = ROUND(P_HT * (100 - P_TAUX) * 1.20 / 100, 2);   -- sans division intermédiaire
END;

-- Montant d'un devis : ses lignes, la remise du client, le tarif
CREATE OR REPLACE PROCEDURE CALCULER (IN P_DEVIS INTEGER, OUT P_TTC DECIMAL(11, 2))
LANGUAGE SQL
BEGIN
  DECLARE V_HT   DECIMAL(11, 2);
  DECLARE V_TAUX DECIMAL(5, 2);
  SELECT COALESCE(SUM(QUANTITE * PRIX_UNITAIRE), 0) INTO V_HT
    FROM DEVLIG WHERE ID_DEVIS = P_DEVIS;
  SELECT C.TAUX_REMISE INTO V_TAUX
    FROM DEVIS D JOIN CLIENT C ON C.ID_CLIENT = D.ID_CLIENT
   WHERE D.ID_DEVIS = P_DEVIS;
  CALL TARIFER(V_HT, V_TAUX, P_TTC);
  UPDATE DEVIS SET MONTANT_TTC = P_TTC WHERE ID_DEVIS = P_DEVIS;
END;

-- Le client peut-il encore s'engager de ce montant ?
CREATE OR REPLACE PROCEDURE CONTROLER (IN P_CLIENT INTEGER, IN P_MONTANT DECIMAL(11, 2),
                                       OUT P_OK CHAR(1))
LANGUAGE SQL
BEGIN
  DECLARE V_ENCOURS, V_PLAFOND DECIMAL(11, 2);
  SELECT ENCOURS, PLAFOND INTO V_ENCOURS, V_PLAFOND FROM CLIENT WHERE ID_CLIENT = P_CLIENT;
  SET P_OK = CASE WHEN V_ENCOURS + P_MONTANT <= V_PLAFOND THEN 'O' ELSE 'N' END;
END;

-- Valider un devis : le calculer, contrôler l'encours, changer son statut
CREATE OR REPLACE PROCEDURE VALIDER (IN P_DEVIS INTEGER, OUT P_RETOUR CHAR(1))
LANGUAGE SQL
BEGIN
  DECLARE V_CLIENT INTEGER;
  DECLARE V_STATUT CHAR(1);
  DECLARE V_TTC    DECIMAL(11, 2);
  DECLARE V_OK     CHAR(1);
  SELECT ID_CLIENT, STATUT INTO V_CLIENT, V_STATUT FROM DEVIS WHERE ID_DEVIS = P_DEVIS;
  IF V_STATUT <> 'B' THEN
    SET P_RETOUR = 'S';                                -- statut incompatible
  ELSE
    CALL CALCULER(P_DEVIS, V_TTC);
    CALL CONTROLER(V_CLIENT, V_TTC, V_OK);
    IF V_OK = 'O' THEN
      UPDATE DEVIS SET STATUT = 'V' WHERE ID_DEVIS = P_DEVIS;
      SET P_RETOUR = ' ';
    ELSE
      SET P_RETOUR = 'E';                              -- encours dépassé
    END IF;
  END IF;
END;

-- Facturer un devis validé
CREATE OR REPLACE PROCEDURE FACTURER (IN P_DEVIS INTEGER, OUT P_FACTURE INTEGER)
LANGUAGE SQL
BEGIN
  DECLARE V_CLIENT INTEGER;
  DECLARE V_TTC    DECIMAL(11, 2);
  SELECT ID_CLIENT, MONTANT_TTC INTO V_CLIENT, V_TTC
    FROM DEVIS WHERE ID_DEVIS = P_DEVIS AND STATUT = 'V';
  CALL NUMEROTER('FACTURE', P_FACTURE);
  INSERT INTO FACTURE VALUES (P_FACTURE, P_DEVIS,
                              DEC(VARCHAR_FORMAT(CURRENT DATE, 'YYYYMMDD'), 8, 0), V_TTC);
  UPDATE DEVIS  SET STATUT = 'F' WHERE ID_DEVIS = P_DEVIS;
  UPDATE CLIENT SET ENCOURS = ENCOURS + V_TTC WHERE ID_CLIENT = V_CLIENT;
END;

-- Créer un devis vide pour un client
CREATE OR REPLACE PROCEDURE CREERDEVIS (IN P_CLIENT INTEGER, OUT P_DEVIS INTEGER)
LANGUAGE SQL
BEGIN
  CALL NUMEROTER('DEVIS', P_DEVIS);
  INSERT INTO DEVIS (ID_DEVIS, ID_CLIENT, DATE_DEVIS)
    VALUES (P_DEVIS, P_CLIENT, DEC(VARCHAR_FORMAT(CURRENT DATE, 'YYYYMMDD'), 8, 0));
END;

-- Vérification : 5 tables journalisées, 7 procédures
SELECT OBJNAME AS TABLE_, JOURNALED FROM TABLE (QSYS2.OBJECT_STATISTICS(CURRENT SCHEMA, '*FILE')) X
 WHERE OBJNAME IN ('CLIENT', 'DEVIS', 'DEVLIG', 'FACTURE', 'COMPTEUR');
SELECT ROUTINE_NAME FROM QSYS2.SYSROUTINES WHERE ROUTINE_SCHEMA = CURRENT SCHEMA
   AND ROUTINE_NAME IN ('NUMEROTER', 'TARIFER', 'CALCULER', 'CONTROLER', 'VALIDER', 'FACTURER', 'CREERDEVIS');
