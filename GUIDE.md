# Guide du lecteur et lexique

Ce guide accompagne la session **« Db2 for i : un héritage puissant qui ne demande qu'à évoluer »**.
Il s'adresse à celles et ceux qui suivent la session sans être techniciens : pour chaque
partie, ce qu'elle montre, pourquoi cela compte pour l'organisation, et **la question à poser
à un collègue technique** pour aller plus loin.

Le bandeau en haut de chaque slide indique où l'on en est : le chapitre (1 à 4), et pour le
chapitres 2 et 4 l'étape (2.1 à 2.4, 4.1 à 4.4).

## Le fil de la session

Un IBM i qui tourne depuis des décennies : 40 ans de programmes, des règles métier cachées
dans le code, peu de documentation. Comment le faire évoluer sans tout réécrire ? Réponse en
quatre temps : **comprendre** ce qui existe, le **rendre appelable**, le **découpler**, puis
le **moderniser un bloc à la fois**. L'outil de chaque temps est le **SQL**, bien au-delà
des transactions : il sert à moderniser, administrer, exploiter et ouvrir les données.

## Chapitre par chapitre

### 1. Le chantier 2019-2022
- **Ce que ça montre** : plus de 500 tables migrées vers le SQL sans recompiler les programmes existants.
- **Pourquoi ça compte** : c'est la fondation. Une base en SQL porte ses propres règles (clés, contraintes, sécurité) au lieu de les laisser aux programmes.
- **À demander à un collègue technique** : « Quelles règles métier sont aujourd'hui dans les programmes plutôt que dans la base ? »

### 2. Moderniser progressivement
- **2.1 Cartographier** — savoir qui appelle quoi et quelles tables sont touchées, avant de modifier. *Question :* « Peut-on produire la carte des programmes et des tables de notre application ? »
- **2.2 Encapsuler** — faire d'un programme existant une « procédure » appelable de l'extérieur, sans le réécrire. *Question :* « Lesquels de nos programmes pourrait-on appeler depuis un site, un outil de données ou un autre système ? »
- **2.3 Découpler** — ce qui est découplé, ce sont le programme qui change une donnée et les systèmes qui ont besoin de le savoir. Aujourd'hui le programme appelle lui-même chaque service. L'alternative montrée : la base publie ce qui change et chacun vient lire, sans modifier le programme. Testé avec le journal et une file de données ; aucun consommateur n'est déployé. *Question :* « Qui a besoin d'être prévenu quand un client ou une facture change, et comment l'est-il aujourd'hui ? »
- **2.4 Un bloc à la fois** — on ne réécrit pas tout d'un coup, on remplace un morceau puis le suivant. *Question :* « Quel serait le premier bloc à moderniser, celui où l'on gagne le plus pour le moins de risque ? »

### 3. Administrer et exploiter en SQL
- **Ce que ça montre** : l'état du système (sécurité, messages, droits) se consulte comme une table, avec des requêtes.
- **Pourquoi ça compte** : contrôles et audits deviennent reproductibles, automatisables et partageables. Et tout peut partir vers l'outil de sécurité de l'entreprise (un SIEM : Graylog, ELK, ClickStack), par le même chemin que l'étape 2.3.
- **À demander à un collègue technique** : « Quels contrôles d'exploitation refait-on à la main que l'on pourrait écrire une fois en SQL ? »

### 4. L'IBM i, source de données
- **Le fil** : 4.1 se connecter, 4.2 extraire, 4.3 industrialiser, 4.4 en vrai (le retour d'expérience Sinapse).
- **Ce que ça montre** : les données de l'IBM i sont lisibles par les outils modernes (Python, outils de BI, bases analytiques) et extractibles vite, en colonnes.
- **Pourquoi ça compte** : la donnée de gestion nourrit l'analyse et l'IA sans copie manuelle et sans ralentir la production.
- **À demander à un collègue technique** : « Comment nos données IBM i arrivent-elles aujourd'hui vers l'analyse ? Combien de temps prend une extraction ? »

> Deux éléments sont volontairement signalés comme non exécutés : la réécriture d'un bloc (slide 2.4, un principe)
> et les chiffres avant / après du retour d'expérience Sinapse.

## Lexique

| Terme | En une phrase |
|---|---|
| **IBM i** | Le système d'exploitation d'IBM (ex-AS/400) sur lequel tournent de nombreuses applications de gestion. |
| **Db2 for i** | La base de données intégrée à l'IBM i. |
| **DDS** | Ancienne façon de décrire les fichiers de données de l'IBM i, avant le SQL. |
| **SQL** | Le langage standard pour interroger et gérer des données. |
| **RPG** | Le langage historique des programmes de gestion sur IBM i. |
| **Adélia** | Atelier de génie logiciel qui génère du code (dont du RPG) à partir d'une description. |
| **Programme** | Une unité de traitement compilée (ici, souvent en RPG). |
| **Table** | Un tableau de données (lignes et colonnes) dans la base. |
| **Procédure stockée** | Un traitement enregistré dans la base, que l'on déclenche par un simple appel (`CALL`). |
| **Façade** | Une procédure stockée qui enveloppe un programme existant, sans le modifier. |
| **Encapsuler** | Placer un programme existant derrière une façade pour qu'il soit appelable de l'extérieur. |
| **Catalogue** | La partie de la base qui décrit les objets eux-mêmes : tables, procédures, dépendances. |
| **Journal** | Le registre automatique de toutes les modifications faites sur les tables. |
| **File de données** | Une boîte aux lettres du système où l'on dépose des messages que d'autres programmes viennent lire. |
| **Capture de changements** | Repérer ce qui a changé dans la base pour le transmettre ailleurs. |
| **JSON** | Un format texte simple pour échanger des données entre systèmes. |
| **ODBC / JDBC** | Deux « prises standard » par lesquelles un outil se connecte à une base. |
| **API** | Un point d'accès par lequel un système en appelle un autre. |
| **Apache Arrow** | Un format de données en colonnes, très rapide à transférer et à analyser. |
| **DuckDB** | Une base d'analyse légère, installée sur un poste, sans serveur. |
| **Parquet** | Un format de fichier en colonnes, compact, courant pour l'analyse. |
| **SIEM** | L'outil où la sécurité centralise et analyse les journaux de tous les systèmes (Graylog, ELK, ClickStack…). |
| **Syslog** | Le format standard d'envoi des journaux vers un outil de supervision. |
| **Pipeline de données** | Une chaîne automatisée qui extrait, transforme et charge des données. |
| **Service IBM i (QSYS2)** | Une fonction SQL fournie par l'IBM i qui expose l'état du système comme une table. |
| **pub400** | Un serveur IBM i public et gratuit, utilisé pour tester les exemples. |
| **Kit** | Le dossier `kit/` de ce dépôt : tous les scripts pour rejouer les exemples. |
