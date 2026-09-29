-- =====================================================================
-- Kit iBelieve 2026 — RPG — 10. Le terrain du RPG
-- Tables et jeu d'essai des programmes RPG du kit (devis, lignes, factures, clients).
-- ÉCRIT dans votre bibliothèque. Les tables portent les mêmes noms que celles du kit SQL
-- (00-terrain.sql) : utilisez une autre bibliothèque, ou lancez d'abord ../99-menage.sql.
-- =====================================================================

SET SCHEMA VOTREBIB;
SET PATH = CURRENT PATH, VOTREBIB;              -- pour trouver les procédures du kit

-- Un journal nommé QSQJRN : Db2 y journalise d'office toute table créée ensuite.
-- GENFACT travaille sous contrôle de validation : ses tables doivent être journalisées.
BEGIN
  IF NOT EXISTS (SELECT 1 FROM TABLE (QSYS2.OBJECT_STATISTICS(CURRENT SCHEMA, '*JRN')) J
                  WHERE J.OBJNAME = 'QSQJRN') THEN
    CALL QSYS2.QCMDEXC('CRTJRNRCV JRNRCV(' CONCAT CURRENT SCHEMA CONCAT '/KITRCV0001)');
    CALL QSYS2.QCMDEXC('CRTJRN JRN(' CONCAT CURRENT SCHEMA CONCAT '/QSQJRN) JRNRCV('
                       CONCAT CURRENT SCHEMA CONCAT '/KITRCV0001)');
  END IF;
END;

-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE CLIENT (
    CLI_NUM         DECIMAL(7,0)   NOT NULL,
    CLI_NOM         CHAR(40)       NOT NULL DEFAULT '',
    CLI_TAUX_REM    DECIMAL(5,2)   NOT NULL DEFAULT 0,
    CLI_ENCOURS     DECIMAL(11,2)  NOT NULL DEFAULT 0,
    CLI_ENCOURS_MAX DECIMAL(11,2)  NOT NULL DEFAULT 0,
    CONSTRAINT PK_CLIENT PRIMARY KEY (CLI_NUM)
)
RCDFMT CLIENTR;

LABEL ON TABLE CLIENT IS 'Clients';
LABEL ON COLUMN CLIENT (
    CLI_TAUX_REM    IS 'Taux remise %',
    CLI_ENCOURS     IS 'Encours actuel',
    CLI_ENCOURS_MAX IS 'Encours autorise'
);

-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE DEVIS (
    DEV_NUM     DECIMAL(9,0)  NOT NULL,
    DEV_CLI     DECIMAL(7,0)  NOT NULL,
    DEV_DATE    DECIMAL(8,0)  NOT NULL DEFAULT 0,   -- AAAAMMJJ, exprès
    DEV_STATUT  CHAR(1)       NOT NULL DEFAULT 'S',
    DEV_HT      DECIMAL(11,2) NOT NULL DEFAULT 0,
    DEV_REMISE  DECIMAL(11,2) NOT NULL DEFAULT 0,
    DEV_TVA     DECIMAL(11,2) NOT NULL DEFAULT 0,
    DEV_TTC     DECIMAL(11,2) NOT NULL DEFAULT 0,
    CONSTRAINT PK_DEVIS  PRIMARY KEY (DEV_NUM),
    CONSTRAINT FK_DEVCLI FOREIGN KEY (DEV_CLI) REFERENCES CLIENT (CLI_NUM),
    CONSTRAINT CK_DEVSTA CHECK (DEV_STATUT IN ('S','V','F'))
)
RCDFMT DEVISR;

-- DEV_DATE en numérique AAAAMMJJ : c'est laid, c'est partout, et c'est
-- exactement le genre de zone qu'il faut convertir en sortant de l'IBM i.

-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE DEVLIG (
    DVL_DEV  DECIMAL(9,0)  NOT NULL,
    DVL_LIG  DECIMAL(3,0)  NOT NULL,
    DVL_ART  CHAR(10)      NOT NULL DEFAULT '',
    DVL_QTE  DECIMAL(7,2)  NOT NULL DEFAULT 0,
    DVL_PU   DECIMAL(9,2)  NOT NULL DEFAULT 0,
    CONSTRAINT PK_DEVLIG PRIMARY KEY (DVL_DEV, DVL_LIG),
    CONSTRAINT FK_DVLDEV FOREIGN KEY (DVL_DEV) REFERENCES DEVIS (DEV_NUM)
)
RCDFMT DEVLIGR;

-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE FACTURE (
    FAC_NUM   DECIMAL(9,0)  NOT NULL,
    FAC_DEV   DECIMAL(9,0)  NOT NULL,
    FAC_CLI   DECIMAL(7,0)  NOT NULL,
    FAC_DATE  DECIMAL(8,0)  NOT NULL DEFAULT 0,
    FAC_TTC   DECIMAL(11,2) NOT NULL DEFAULT 0,
    CONSTRAINT PK_FACTURE PRIMARY KEY (FAC_NUM),
    CONSTRAINT UQ_FACDEV  UNIQUE (FAC_DEV),          -- anti double facturation
    CONSTRAINT FK_FACDEV  FOREIGN KEY (FAC_DEV) REFERENCES DEVIS (DEV_NUM)
)
RCDFMT FACTURER;

-- UQ_FACDEV : la base refuse la deuxième facture d'un même devis.
-- GENFACT s'appuie dessus : c'est la contrainte, pas le RPG, qui protège.

-- ---------------------------------------------------------------------
-- Compteur de numéros de facture (une ligne, verrouillée à l'update)
CREATE OR REPLACE TABLE COMPTEUR (
    CPT_CODE  CHAR(10)     NOT NULL,
    CPT_VAL   DECIMAL(9,0) NOT NULL DEFAULT 0,
    CONSTRAINT PK_COMPTEUR PRIMARY KEY (CPT_CODE)
)
RCDFMT COMPTEURR;

-- ---------------------------------------------------------------------
-- Vue de confort : noms lisibles, vraie date, aucun programme appelé.
CREATE OR REPLACE VIEW V_DEVIS AS
SELECT d.DEV_NUM                                     AS numero_devis,
       d.DEV_CLI                                     AS numero_client,
       TRIM(c.CLI_NOM)                               AS client,
       DATE(TIMESTAMP_FORMAT(DIGITS(d.DEV_DATE), 'YYYYMMDD')) AS date_devis,
       CASE d.DEV_STATUT WHEN 'S' THEN 'Saisi'
                         WHEN 'V' THEN 'Valide'
                         WHEN 'F' THEN 'Facture' END AS statut,
       d.DEV_HT     AS montant_ht,
       d.DEV_REMISE AS montant_remise,
       d.DEV_TVA    AS montant_tva,
       d.DEV_TTC    AS montant_ttc
FROM   DEVIS d
JOIN   CLIENT c ON c.CLI_NUM = d.DEV_CLI;

-- ---------------------------------------------------------------------
-- Jeu d'essai
-- ---------------------------------------------------------------------
DELETE FROM FACTURE;
DELETE FROM DEVLIG;
DELETE FROM DEVIS;
DELETE FROM CLIENT;
DELETE FROM COMPTEUR;

INSERT INTO COMPTEUR VALUES ('FACTURE', 1000);

INSERT INTO CLIENT VALUES
  (1001, 'DUPONT ET FILS',       5.00,  1200.00, 50000.00),
  (1002, 'MARTIN DISTRIBUTION', 10.00, 48000.00, 50000.00),  -- proche du plafond
  (1003, 'LEROY SARL',           0.00,      .00,  1000.00);  -- plafond bas

INSERT INTO DEVIS (DEV_NUM, DEV_CLI, DEV_DATE, DEV_STATUT, DEV_HT) VALUES
  (500001, 1001, 20260115, 'S', 10000.00),   -- cas nominal
  (500002, 1002, 20260116, 'S',  5000.00),   -- fera sauter l'encours
  (500003, 1003, 20260117, 'S',   800.00),   -- passe de justesse
  (500004, 1001, 20260118, 'V',  2000.00),   -- déjà validé, prêt à facturer
  (500005, 1001, 20260119, 'S',  1500.00);   -- pour 17-decoupler.sql

INSERT INTO DEVLIG VALUES
  (500001, 1, 'ART-A', 10.00, 800.00),
  (500001, 2, 'ART-B',  4.00, 500.00),
  (500002, 1, 'ART-C',  5.00,1000.00),
  (500003, 1, 'ART-A',  1.00, 800.00),
  (500004, 1, 'ART-B',  4.00, 500.00),
  (500005, 1, 'ART-B',  3.00, 500.00);

-- Vérification
SELECT * FROM V_DEVIS ORDER BY numero_devis;
