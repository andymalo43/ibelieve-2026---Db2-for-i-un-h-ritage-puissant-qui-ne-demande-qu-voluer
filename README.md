# Db2 for i : un héritage puissant qui ne demande qu'à évoluer

Session de 40 minutes présentée à **iBelieve 2026** (15 octobre 2026, en ligne,
co-organisé par Itheis et IBM), par Andy, ingénieur de données.

Le propos : sur IBM i, le SQL ne se limite pas au transactionnel. Il sert à
**moderniser, administrer, exploiter et ouvrir les données** — avec ou sans outil,
et souvent avec le seul natif. Ce n'est ni une démo produit ni une vente.

## Pour suivre sans être technicien

Le [**guide du lecteur et lexique**](GUIDE.md) résume chaque partie, explique pourquoi elle compte
et propose une question à poser à un collègue technique. Le [**diaporama en PDF**](diaporama.pdf)
se relit à son rythme. En haut de chaque slide, un bandeau indique le chapitre et, pour le chapitre 2, l'étape.

## Rejouer les exemples : le kit

Tout le SQL montré pendant la session est dans [`kit/`](kit/), prêt à lancer dans
**votre** bibliothèque, sur votre IBM i ou sur un compte gratuit
[pub400.com](https://pub400.com). Mode d'emploi : [`kit/README.md`](kit/README.md).

**Deux chemins pour le terrain.** Les slides s'appuient sur `kit/rpg/` : de vrais programmes RPG,
chargés et compilés depuis ACS. Si vous ne pouvez pas compiler, `kit/` propose la variante tout SQL
(des procédures SQL jouent le rôle des programmes). Les deux portent les mêmes noms de tables : utilisez
**deux bibliothèques différentes**, ou lancez le ménage de l'un avant l'autre.

| Chapitre | Avec le vrai RPG (celui des slides) | Sans compilation |
|---|---|---|
| Le terrain : une mini-application de devis | `kit/rpg/10` à `12` | `kit/00-terrain.sql` |
| Cartographier, chaîne d'appels, diagramme sans outil | `kit/rpg/15-cartographier-rpg.sql` | `kit/01-cartographier.sql` |
| Encapsuler, appeler la façade | `kit/rpg/13`, `16`, `AppelerFacade.java`, `appeler_facade.py` | — |
| Découpler : le journal, la file de données | `kit/rpg/17-decoupler.sql` | `kit/03-decoupler.sql` |

Les autres chapitres n'ont qu'une version :

| Chapitre | Script |
|---|---|
| La base elle-même (`GENERATE_SQL`) | `kit/04-la-base.sql` |
| Administrer et exploiter en SQL | `kit/05-administrer.sql` |
| Industrialiser l'extraction | `kit/06-industrialiser.sql` |
| Tout supprimer | `kit/99-menage.sql` (kit SQL), `kit/rpg/19-menage.sql` (kit RPG) |
| ODBC → Arrow → DuckDB | `kit/exemples/` (à adapter) |

## Voir le deck

Le deck est écrit avec [Slidev](https://sli.dev) ; ses schémas en [D2](https://d2lang.com),
compilés au build (rien à installer). Prérequis : [bun](https://bun.sh).

```bash
bun install
bun run dev       # présente le deck dans le navigateur (notes de présentateur incluses)
bun run build     # version statique dans dist/
bun run export    # PDF (première fois : bunx playwright install chromium)
```

## Licences

- Le **code** (kit SQL, exemples, composants, configuration) : [MIT](LICENSE).
- Le **contenu** de la présentation (textes, schémas, notes) :
  [CC BY 4.0](LICENSE-CONTENU.md) — réutilisation libre, en citant la source.
- Les **logos** (`public/logos/`) sont des marques de leurs détenteurs, hors de ces licences : voir `public/logos/README.md`.
