# Kit auditeur — « Db2 for i : un héritage puissant qui ne demande qu'à évoluer »

Tous les exemples SQL de la session iBelieve 2026, à rejouer **dans votre propre
bibliothèque**, sur votre IBM i ou sur un compte gratuit [pub400.com](https://pub400.com).
Chaque bloc SQL montré sur les slides figure ici mot pour mot.

## Prérequis

- IBM i **7.5** (c'est là que le kit a été testé : pub400, le 29/09/2026). Sur une autre version, certains services SQL peuvent demander un niveau de groupe PTF Db2 plus récent.
- Une bibliothèque où vous avez le droit de créer des objets (sur pub400 : l'une des deux
  bibliothèques de votre compte).
- **ACS → Run SQL Scripts**, en nommage SQL (option par défaut). Les scripts contiennent des
  blocs `BEGIN … END` : lancez-les avec **Run All**.

## Mode d'emploi

1. Dans chaque script, **remplacez `VOTREBIB` par le nom de votre bibliothèque**
   (2 lignes en tête de script : `SET SCHEMA` et `SET PATH`).
2. Lancez `00-terrain.sql` une fois.
3. Lancez les scripts des chapitres dans l'ordre qui vous intéresse.
4. Terminez par `99-menage.sql`.

| Script | Slides | Ce qu'il fait | Écrit ? |
|---|---|---|---|
| `00-terrain.sql` | Le terrain | Mini-application de devis : 5 tables journalisées (`CLIENT`, `DEVIS`, `DEVLIG`, `FACTURE`, `COMPTEUR`) et 7 procédures SQL qui jouent le rôle des « programmes » | **oui**, dans votre bibliothèque |
| `01-cartographier.sql` | Cartographier, La chaîne d'appels, Un diagramme sans outil | `DSPPGMREF` piloté en SQL, chaîne d'appels récursive (catalogue `SYSROUTINEDEP`), diagramme Mermaid généré en SQL | dans `QTEMP` seulement |
| `03-decoupler.sql` | Découpler (×2) | Valide et facture un devis, lit le journal (`DISPLAY_JOURNAL`), publie et consomme un JSON dans une file de données | **oui** : devis 101 facturé, `*DTAQ` créée puis supprimée |
| `04-la-base.sql` | De 2021 à 2026 (notes) | Régénère le DDL de la bibliothèque (`GENERATE_SQL`) | dans `QTEMP` seulement |
| `05-administrer.sql` | Administrer, Sécurité · exploitation · audit | Services IBM i : valeurs système, historique, droits… | non |
| `06-industrialiser.sql` | Industrialiser l'extraction | Taille au catalogue, tranche par `RRN` | non |
| `99-menage.sql` | — | Supprime tout ce que le kit a créé | **oui** |

`03-decoupler.sql` ne se rejoue pas deux fois de suite : il facture le devis 101.
Pour recommencer : `99-menage.sql`, puis `00-terrain.sql`.

## Exemples non exécutés par le kit

Dans `exemples/`, ce qui dépend de votre environnement :

- `encapsuler-rpg.non-execute.sql` : déclarer **votre** programme RPG existant comme procédure
  stockée (le kit n'a pas de RPG, pour tourner partout sans compilation) ;
- `arrow_odbc_duckdb.py` et `duckdb-nanodbc.non-execute.sql` : extraire en colonne par ODBC
  vers Apache Arrow et DuckDB, depuis votre poste (pilote IBM i Access ODBC requis).

## Bon à savoir

- **Les « programmes » sont des procédures SQL.** `DSPPGMREF` voit les tables qu'elles lisent
  et écrivent, mais pas leurs appels entre elles (un `CALL` SQL se résout à l'exécution) :
  la chaîne d'appels se lit donc dans le catalogue `QSYS2.SYSROUTINEDEP`. Sur du RPG ou du CL,
  `DSPPGMREF` donne aussi les programmes appelés (objets `*PGM`).
- **Journal.** `00-terrain.sql` crée un journal `QSQJRN` si votre bibliothèque n'en a pas
  (une bibliothèque `CRTLIB` n'en a pas) ; `99-menage.sql` ne le supprime que s'il vient du kit.
- **Vues `SYS*`.** Dès qu'une bibliothèque porte des contraintes, Db2 y crée six vues de
  catalogue (`SYSCST`, `SYSREFCST`…). Elles restent après le ménage : c'est normal, Db2 les gère.
- **Droits.** Les services IBM i respectent vos droits : sur un compte sans `*ALLOBJ`, certaines
  requêtes rendent peu de lignes, d'autres sont refusées (`SQL0443`, `SQL0552`). Le kit n'utilise
  que ce qui répond sur un compte gratuit pub400.
- **pub400 est un système partagé** : restez dans vos bibliothèques.
