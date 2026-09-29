# Kit auditeur — partie RPG

De **vrais programmes RPG**, pour rejouer ce que le kit SQL ne peut pas montrer sans
compilation : encapsuler des programmes existants dans des procédures stockées, comparer
trois implémentations d'un même calcul, et cartographier une chaîne d'appels RPG avec
`DSPPGMREF`. Tout se fait depuis **ACS → Run SQL Scripts** : rien à téléverser, les sources
sont chargées dans des fichiers source par de simples `INSERT`.

Testé sur IBM i **7.5** (pub400, le 29/09/2026), du chargement des sources au ménage.

## Les programmes

| Programme | Langage | Rôle |
|---|---|---|
| `CALCTAR3` | RPG III (OPM), colonné | Remise puis TVA à 20 % — version historique |
| `CALCTARIF` | RPG IV free-form (ILE) | Le même calcul, réécrit |
| `CALCTARA` | RPG IV colonné (ILE) | Le même calcul, **tel que le génèrerait un atelier Adélia** |
| `CALCDEVIS` | RPG IV + SQL imbriqué | Calcule un devis (lignes, remise client) en appelant `CALCTARIF` |
| `CTLENCOURS` | RPG IV, accès natif | Contrôle l'encours d'un client |
| `VALDEVIS` | RPG IV + SQL imbriqué | Valide un devis : appelle `CALCDEVIS` et `CTLENCOURS` |
| `GENFACT` | RPG IV + SQL imbriqué | Facture un devis validé, **possède sa transaction** (`COMMIT(*CHG)`) |

`CALCTARA.rpgle` **simule** la sortie du générateur Adélia (aucun atelier Adélia n'était
disponible) ; `sources/CALCTARA.l4g` en est le source L4G de référence, à lire.
`CALCTAR3.rpg` respecte les colonnes du RPG III : ne le reformatez pas.

## Mode d'emploi

1. Remplacez `VOTREBIB` par votre bibliothèque dans **tous** les scripts de ce dossier
   (y compris `11-sources.sql`, où elle figure aussi dans le SQL imbriqué des programmes).
   ⚠️ Les tables portent les mêmes noms que celles du kit SQL : utilisez une **autre
   bibliothèque**, ou lancez d'abord `../99-menage.sql`.
2. Lancez dans l'ordre, avec **Run All** :

| Script | Ce qu'il fait | Écrit ? |
|---|---|---|
| `10-terrain-rpg.sql` | Journal `QSQJRN` (si absent), 5 tables, une vue, jeu d'essai | **oui** |
| `11-sources.sql` | Fichiers source `KITRPGSRC` / `KITRPGLSRC`, un membre par programme | **oui** |
| `12-compiler.sql` | `CRTRPGPGM`, `CRTBNDRPG`, `CRTSQLRPGI` : 7 programmes | **oui** |
| `13-facades.sql` | Les procédures SQL qui encapsulent les programmes, un `CALL` de chaque façade de tarif, et `PS_TRAITER_DEVIS`, une procédure SQL qui enchaîne validation et facturation | **oui** (DDL) |
| `14-rejouer.sql` | Les trois versions comparées sur un jeu de valeurs ; la chaîne validation → facturation, puis `PS_TRAITER_DEVIS` | **oui** |
| `15-cartographier-rpg.sql` | Le graphe des appels dans une table `T_APPELS`, de trois sources (`SYSROUTINEDEP`, `SYSROUTINES`, `DSPPGMREF` dans `T_PGMREF`) : chaîne d'appels du SQL jusqu'au RPG, usage des tables, diagramme Mermaid | **oui** (2 tables) |
| `16-appeler.sql` | Fonction table `F_TARIF_RPG3` : les valeurs calculées par le RPG, lisibles par un simple `SELECT` (pour les clients ODBC qui ne lisent pas les paramètres OUT) | **oui** (DDL) |
| `17-decoupler.sql` | Découpler : `PS_TRAITER_DEVIS` valide et facture le devis 500005, le journal montre quel programme RPG a modifié quoi (`DISPLAY_JOURNAL`), puis un JSON publié et consommé dans une file de données | **oui** : devis 500005 facturé, `*DTAQ` créée puis supprimée |
| `19-menage.sql` | Supprime tout ce que cette partie a créé | **oui** |

## Ce que vous devez voir

- `13-facades.sql` : les trois façades rendent **9500.00 / 1900.00 / 11400.00** pour 10 000 HT
  et 5 % de remise.
- `14-rejouer.sql` : **deux divergences** entre les versions, dont un centime sur le TTC
  (99,99 à 33,33 % : 80,00 contre 79,99). C'est le résultat le plus instructif : encapsuler
  n'efface pas les différences, ça les rend testables. Puis la validation (`' '`, puis `'E'`
  pour l'encours dépassé, `'S'` pour un devis déjà validé) et la facturation (`'D'` à la
  deuxième tentative : c'est la contrainte `UQ_FACDEV` qui protège, pas le RPG).
- `15-cartographier-rpg.sql` : depuis `PS_TRAITER_DEVIS`, la chaîne descend dans le RPG —
  `PS_TRAITER_DEVIS > PS_VAL_DEVIS > VALDEVIS > CALCDEVIS > CALCTARIF`, la branche
  `VALDEVIS > CTLENCOURS`, et `PS_TRAITER_DEVIS > PS_GEN_FACT > GENFACT` —, chaque maillon avec sa source.
- `16-appeler.sql` : `SELECT * FROM TABLE(F_TARIF_RPG3(10000.00, 5.00)) T` → `9500.00 | 1900.00 | 11400.00`.
- `17-decoupler.sql` : facture 1003 ; dans le journal, `CALCDEVIS`, `VALDEVIS` et `GENFACT` en `PROGRAM_NAME` — des programmes qu'on n'a pas modifiés.

## Appeler la façade depuis votre code

- **JDBC** — `AppelerFacade.java` : un `CallableStatement` lit directement les paramètres OUT.
  `IBMI_HOTE=… IBMI_USER=… IBMI_PWD=… java -cp jt400.jar AppelerFacade.java` (pilote [JTOpen](https://github.com/IBM/JTOpen)).
- **ODBC** — `appeler_facade.py` : pyodbc [ne lit pas les paramètres de sortie](https://github.com/mkleehammer/pyodbc/wiki/Calling-Stored-Procedures) ;
  il interroge la fonction table de `16-appeler.sql`. Même principe pour Excel, Power BI ou DuckDB.

Le programme Java a tourné tel quel sur pub400 (29/09) ; la requête du script Python aussi, avec
ses marqueurs alimentés par des flottants comme le fait pyodbc (le script lui-même demande un DSN ODBC).

## Pièges rencontrés (et réglés dans les scripts)

- **Liste de bibliothèques** : les programmes s'appellent par leur nom (`extpgm('CALCDEVIS')`)
  et `CTLENCOURS` lit `CLIENT` en accès natif : tout se résout par la liste de bibliothèques.
  Les scripts font de votre bibliothèque la **bibliothèque en cours** (`CHGCURLIB`). Un simple
  `ADDLIBLE` ne suffit pas : la bibliothèque en cours est cherchée avant la partie utilisateur
  de la liste, et si elle porte des programmes ou des tables de mêmes noms (une autre version
  de l'application, par exemple), ce sont eux qui répondent — sans erreur, sur d'autres données.
- **`PARAMETER STYLE GENERAL` refuse un `NULL`**, même pour un paramètre de sortie (`SQL0470`) :
  les variables passées aux façades sont initialisées.
- **`CREATE OR REPLACE TABLE` garde les lignes** par défaut : `ON REPLACE DELETE ROWS` pour
  les tables de test.
- **Contrôle de validation** : `GENFACT` travaille en `COMMIT(*CHG)` ; ses tables doivent être
  journalisées (le kit crée `QSQJRN`). Une transaction ouverte par l'appelant ne traverse pas
  un programme compilé `COMMIT(*NONE)`, sans erreur : décidez qui possède la transaction.

## Régénérer `11-sources.sql`

Si vous modifiez un fichier de `sources/` : `python generer-11-sources.py`.
