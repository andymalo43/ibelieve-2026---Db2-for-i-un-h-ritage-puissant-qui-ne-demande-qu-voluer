# Db2 for i : un héritage puissant qui ne demande qu'à évoluer

Session de 40 minutes présentée à **iBelieve 2026** (15 octobre 2026, en ligne,
co-organisé par Itheis et IBM), par Andy, ingénieur de données.

Le propos : sur IBM i, le SQL ne se limite pas au transactionnel. Il sert à
**moderniser, administrer, exploiter et ouvrir les données** — avec ou sans outil,
et souvent avec le seul natif. Ce n'est ni une démo produit ni une vente.

## Rejouer les exemples : le kit

Tout le SQL montré pendant la session est dans [`kit/`](kit/), prêt à lancer dans
**votre** bibliothèque, sur votre IBM i ou sur un compte gratuit
[pub400.com](https://pub400.com). Mode d'emploi : [`kit/README.md`](kit/README.md).

| Chapitre | Script |
|---|---|
| Le terrain : une mini-application de devis | `kit/00-terrain.sql` |
| Cartographier, chaîne d'appels, diagramme sans outil | `kit/01-cartographier.sql` |
| Découpler : le journal, la file de données | `kit/03-decoupler.sql` |
| La base elle-même (`GENERATE_SQL`) | `kit/04-la-base.sql` |
| Administrer et exploiter en SQL | `kit/05-administrer.sql` |
| Industrialiser l'extraction | `kit/06-industrialiser.sql` |
| Tout supprimer | `kit/99-menage.sql` |
| Encapsuler de vrais RPG, comparer trois versions, cartographier du RPG | `kit/rpg/` (sources RPG III / RPG IV fournies, compilées depuis ACS) |
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
