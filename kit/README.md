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
| `00-terrain.sql` | — (variante sans compilation du terrain des slides, qui est celui de `rpg/`) | Mini-application de devis : 5 tables journalisées (`CLIENT`, `DEVIS`, `DEVLIG`, `FACTURE`, `COMPTEUR`) et 7 procédures SQL `PS_…` qui jouent le rôle des « programmes » | **oui**, dans votre bibliothèque |
| `01-cartographier.sql` | « 2.1 Cartographier », « La chaîne d'appels », « Un diagramme sans outil » — **variante sans compilation** (les slides utilisent `rpg/15-cartographier-rpg.sql`) | `DSPPGMREF` piloté en SQL, chaîne d'appels récursive (catalogue `SYSROUTINEDEP`), diagramme Mermaid généré en SQL | dans `QTEMP` seulement |
| `03-decoupler.sql` | « 2.3 Le journal et la file » — **variante sans compilation** (les slides utilisent `rpg/17-decoupler.sql`) | Valide et facture un devis, lit le journal (`DISPLAY_JOURNAL`), publie et consomme un JSON dans une file de données | **oui** : devis 101 facturé, `*DTAQ` créée puis supprimée |
| `04-la-base.sql` | « 1. Le chantier 2019-2022 » (notes) | Régénère le DDL de la bibliothèque (`GENERATE_SQL`) | dans `QTEMP` seulement |
| `05-administrer.sql` | « 3. Administrer et exploiter en SQL », « Sécurité · exploitation · audit » | Services IBM i : valeurs système, historique, droits… | non |
| `06-industrialiser.sql` | « 4.3 Industrialiser l'extraction » | Taille au catalogue, tranche par `RRN` | non |
| `99-menage.sql` | — | Supprime tout ce que le kit a créé | **oui** |

`03-decoupler.sql` ne se rejoue pas deux fois de suite : il facture le devis 101.
Pour recommencer : `99-menage.sql`, puis `00-terrain.sql`.

## Nomenclature

Le kit préfixe les objets SQL par leur type ; les programmes RPG et CL n'ont pas de préfixe.

| Préfixe | Objet | Exemples |
|---|---|---|
| `PS_` | Procédure stockée (SQL ou façade d'un programme) | `PS_VALIDER`, `PS_CALC_TARIF_RPG3` |
| `F_` | Fonction | `F_TARIF_RPG3` |
| `V_` | Vue | `V_DEVIS` |
| `T_` | Table de travail (les tables métier gardent leur nom) | `T_CAS`, `T_COMPARE` |
| *(aucun)* | Programme RPG, CL | `VALDEVIS`, `CALCTARIF` |

Pourquoi sur IBM i : **une procédure SQL crée un objet `*PGM`** (attribut `CLE`), une fonction
SQL un `*SRVPGM`. Sans préfixe, rien ne les distingue d'un RPG dans `WRKOBJ`, dans
`DSPPGMREF` ou dans le journal (`PROGRAM_NAME`). La façade `PS_VAL_DEVIS` et le programme
`VALDEVIS` qu'elle encapsule ne se confondent plus.

**Noms longs : toujours un `SPECIFIC` de 10 caractères au plus.** Le nom de l'objet système
est le nom spécifique ; s'il dépasse 10 caractères, Db2 en fabrique un
(`PS_CALCULER` → `PS_CA00001`), qui dépend de l'ordre de création. Le kit l'écrit donc
toujours : `PS_CALCULER` … `SPECIFIC PS_CALCUL`. Conséquence en cartographie :
`SYSROUTINEDEP` nomme l'appelant par son nom spécifique et l'appelé par son nom SQL,
`DSPPGMREF` donne le nom du `*PGM` ; `SYSROUTINES` fait le lien (voir `01-cartographier.sql`).

## Avec du vrai RPG : `rpg/`

Le kit SQL tourne partout sans compilation. Pour encapsuler de **vrais programmes RPG**
(RPG III, RPG IV, code généré façon Adélia), comparer leurs résultats et cartographier une
chaîne d'appels qui part d'une procédure SQL et descend dans le RPG (catalogue + `DSPPGMREF`) :
voir [`rpg/README.md`](rpg/README.md). C'est le terrain des slides « Le terrain » à « 2.3 Découpler ». Sources
fournies, chargées et compilées depuis ACS, sans rien téléverser.

## Exemples côté poste : `exemples/`

Ce qui tourne sur votre poste, pas dans ACS :

- `duckdb-odbc.sql` : DuckDB (≥ 1.2, extension officielle `odbc`) interroge l'IBM i et copie `CLIENT`
  en local — `duckdb -f duckdb-odbc.sql`.
- `arrow_odbc_duckdb.py` : la même extraction en lots Apache Arrow, en colonne, pour le volume.

Les deux demandent le pilote IBM i Access ODBC et un DSN (`MONIBMI` dans les scripts : remplacez-le
par le vôtre, qui porte système, utilisateur et mot de passe), et `00-terrain.sql` dans `VOTREBIB`.
Exécutés sur pub400 le 30/09/2026, en connexion directe.

## Bon à savoir

- **Les « programmes » sont des procédures SQL** (`PS_…`, voir la nomenclature). `DSPPGMREF` voit les tables qu'elles lisent
  et écrivent, mais pas leurs appels entre elles (un `CALL` SQL se résout à l'exécution) :
  la chaîne d'appels se lit donc dans le catalogue `QSYS2.SYSROUTINEDEP`. Sur du RPG ou du CL,
  `DSPPGMREF` donne aussi les programmes appelés (objets `*PGM`) : voir `rpg/15-cartographier-rpg.sql`.
- **Journal.** `00-terrain.sql` crée un journal `QSQJRN` si votre bibliothèque n'en a pas
  (une bibliothèque `CRTLIB` n'en a pas) ; `99-menage.sql` ne le supprime que s'il vient du kit.
- **Vues `SYS*`.** Dès qu'une bibliothèque porte des contraintes, Db2 y crée six vues de
  catalogue (`SYSCST`, `SYSREFCST`…). Elles restent après le ménage : c'est normal, Db2 les gère.
- **Droits.** Les services IBM i respectent vos droits : sur un compte sans `*ALLOBJ`, certaines
  requêtes rendent peu de lignes, d'autres sont refusées (`SQL0443`, `SQL0552`). Le kit n'utilise
  que ce qui répond sur un compte gratuit pub400.
- **pub400 est un système partagé** : restez dans vos bibliothèques.
