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
| `13-facades.sql` | Les procédures SQL qui encapsulent les programmes, et un `CALL` de chaque façade de tarif | **oui** (DDL) |
| `14-rejouer.sql` | Les trois versions comparées sur un jeu de valeurs ; la chaîne validation → facturation | **oui** |
| `15-cartographier-rpg.sql` | `DSPPGMREF` : chaîne d'appels RPG et usage des tables | `QTEMP` |
| `19-menage.sql` | Supprime tout ce que cette partie a créé | **oui** |

## Ce que vous devez voir

- `13-facades.sql` : les trois façades rendent **9500.00 / 1900.00 / 11400.00** pour 10 000 HT
  et 5 % de remise.
- `14-rejouer.sql` : **deux divergences** entre les versions, dont un centime sur le TTC
  (99,99 à 33,33 % : 80,00 contre 79,99). C'est le résultat le plus instructif : encapsuler
  n'efface pas les différences, ça les rend testables. Puis la validation (`' '`, puis `'E'`
  pour l'encours dépassé, `'S'` pour un devis déjà validé) et la facturation (`'D'` à la
  deuxième tentative : c'est la contrainte `UQ_FACDEV` qui protège, pas le RPG).
- `15-cartographier-rpg.sql` : `VALDEVIS > CALCDEVIS > CALCTARIF` et `VALDEVIS > CTLENCOURS`.

## Pièges rencontrés (et réglés dans les scripts)

- **Liste de bibliothèques** : les programmes s'appellent par leur nom (`extpgm('CALCDEVIS')`)
  et `CTLENCOURS` lit `CLIENT` en accès natif ; les scripts font `ADDLIBLE` de votre bibliothèque.
- **`PARAMETER STYLE GENERAL` refuse un `NULL`**, même pour un paramètre de sortie (`SQL0470`) :
  les variables passées aux façades sont initialisées.
- **`CREATE OR REPLACE TABLE` garde les lignes** par défaut : `ON REPLACE DELETE ROWS` pour
  les tables de test.
- **Contrôle de validation** : `GENFACT` travaille en `COMMIT(*CHG)` ; ses tables doivent être
  journalisées (le kit crée `QSQJRN`). Une transaction ouverte par l'appelant ne traverse pas
  un programme compilé `COMMIT(*NONE)`, sans erreur : décidez qui possède la transaction.

## Régénérer `11-sources.sql`

Si vous modifiez un fichier de `sources/` : `python generer-11-sources.py`.
