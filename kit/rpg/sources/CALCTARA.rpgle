      *=================================================================
      * CALCTARA  -  SOURCE RPG IV GENERE (SIMULATION GENERATEUR ADELIA)
      *
      * PROGRAMME LOGIQUE : CALCUL_TARIF          TYPE : SADELIA
      * BIBLIOTHEQUE      : VOTREBIB               VERSION FICHE : 1.0
      *
      * >>> SOURCE GENERE - TOUTE MODIFICATION SERA PERDUE A LA <<<
      * >>> PROCHAINE GENERATION DEPUIS LE REFERENTIEL          <<<
      *
      * Ce fichier tient lieu de sortie du generateur pour la demo :
      * pas d'atelier Adelia disponible. Il transcrit fidelement la
      * fiche programme et la logique du source L4G (CALCTARA.l4g),
      * en RPG IV colonne - la forme que produit reellement l'atelier.
      *
      * CRTBNDRPG PGM(VOTREBIB/CALCTARA) SRCFILE(VOTREBIB/KITRPGLSRC)
      *           DFTACTGRP(*NO) ACTGRP('DEMO')
      *=================================================================
     H DFTACTGRP(*NO) ACTGRP('DEMO')
     H OPTION(*SRCSTMT:*NODEBUGIO)
      *
      *-----------------------------------------------------------------
      * PARAMETRES - transcription de la fiche programme du referentiel
      * (le contrat d'appel est LA FICHE, pas ce source)
      *-----------------------------------------------------------------
     D MONTANT_HT      S              9P 2
     D TAUX_REMISE     S              5P 2
     D MONTANT_REMISE  S             11P 2
     D MONTANT_TVA     S             11P 2
     D MONTANT_TTC     S             11P 2
     D CODE_RETOUR     S              1A
      *
      * Zones de travail declarees au glossaire du programme.
      * Les arrondis sont portes par la DEFINITION des zones (13,2) :
      * le generateur n'emet pas d'ajustement explicite. C'est ici que
      * CALCTARA peut diverger de CALCTAR3 / CALCTARIF au centime pres.
     D W_REMISE        S             13P 2
     D W_TVA           S             13P 2
     D K_TAUX_TVA      S              5P 2 INZ(20.00)
      *
      *-----------------------------------------------------------------
      * INTERFACE D'APPEL
      *-----------------------------------------------------------------
     C     *ENTRY        PLIST
     C                   PARM                    MONTANT_HT
     C                   PARM                    TAUX_REMISE
     C                   PARM                    MONTANT_REMISE
     C                   PARM                    MONTANT_TVA
     C                   PARM                    MONTANT_TTC
     C                   PARM                    CODE_RETOUR
      *
      * --- Initialisation des sorties ---------------------------------
     C                   EVAL      CODE_RETOUR = ' '
     C                   EVAL      MONTANT_REMISE = 0
     C                   EVAL      MONTANT_TVA = 0
     C                   EVAL      MONTANT_TTC = 0
      *
      * --- Controle du taux de remise ---------------------------------
     C                   IF        TAUX_REMISE < 0
     C                             OR TAUX_REMISE > 100
     C                   EVAL      CODE_RETOUR = 'E'
     C                   RETURN
     C                   ENDIF
      *
      * --- Remise -----------------------------------------------------
     C                   EVAL      W_REMISE = MONTANT_HT
     C                             * TAUX_REMISE / 100
     C                   EVAL      MONTANT_REMISE = MONTANT_HT
     C                             - W_REMISE
      *
      * --- TVA --------------------------------------------------------
     C                   EVAL      W_TVA = MONTANT_REMISE
     C                             * K_TAUX_TVA / 100
     C                   EVAL      MONTANT_TVA = W_TVA
      *
      * --- TTC --------------------------------------------------------
     C                   EVAL      MONTANT_TTC = MONTANT_REMISE
     C                             + MONTANT_TVA
      *
     C                   RETURN
