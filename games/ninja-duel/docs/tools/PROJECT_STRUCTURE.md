# Carte technique actuelle

```text
games/ninja-duel/
  CLAUDE_START_HERE.md         entrée unique
  src/Shared/                 Config, Fighters, MoveGraphs, Attacks, Rules, Controls
  src/Server/                 Combat/Brawler/Motor/Techniques/Matches/World/AI, autorité
  src/Client/                 Input/UI/Camera/Presentation/Effects, présentation
  tests/                      suites headless + isolation build
  tools/                      inventaire combat, vérification docs, dev.py (CLI outils), studio/ (sondes MCP)
  lab/                        propositions de combat inertes (catalogue, templates), jamais buildées
  build.py ; dist/             normal/debug/QA et manifests ; outils Dev* et labo chakra = Debug/QA seulement
  motion-lab/                  ForgeMotionLab/Modules, adapter, tests, build, dist
  design_research/             sources riches, conservées
  docs/active/                 décisions/état/backlog/journal/règles/outils
  docs/combat/ ; movement/     specs d’intentions et validations
  docs/characters/ ; systems/  quatre kits, outils, arène et futurs
  docs/research/ ; tools/      registres et capacité réelle
  docs/current/               contrats/inventaire/mapping stables pour générateurs
  docs/reports/               preuves datées ; pas ordres de mission
  docs/archive/               missions/plans/requests intégrales
plugins/*                     Forge historique et Forge Playground
docs/forge/                   documentation commerciale/branding Forge
shared/                       composants vraiment transversaux, non déplacés
```

Frontières vérifiées par `tools/check_architecture.py` : aucun code Forge importé/embarqué dans Ninja Duel ; aucun code Ninja Duel dans plugins ; adapter Lab→jeu autorisé, jeu→Lab interdit. Les modules Bangla/Velmora/Place1 dans src sont réellement utilisés par le runtime ; leur nom d’origine ne les rend pas obsolètes. Aucun déplacement code partagé pendant l’orchestration.

Lire [capacités](../active/CAPABILITIES_AND_TOOLS.md) pour commandes et limites. Le [maintenance source](MAINTENANCE_BACKLOG_SOURCE.md) est historique ; ses idées OPS-002/003/ARC-002 sont filtrées dans le backlog, pas une mission active séparée.
