# Architecture du dépôt

| Périmètre | Emplacement | Dépendances autorisées |
|---|---|---|
| Ninja Duel | `games/ninja-duel/` | Son runtime, assets/vendor et composants réellement transversaux de `shared/` |
| Plugins historiques Forge/BrickKit et candidats | `plugins/*/` | Leur code, autres composants plugins nécessaires, `shared/` transversal |
| Forge Playground | `plugins/forge-playground/` | Ses stations/adapters et les modules Forge explicitement référencés dans son projet Rojo |
| Motion Lab | `games/ninja-duel/motion-lab/` | Adapter vers Ninja Duel ; absent de ce checkout |
| Documentation Forge | `docs/forge/` | Documentation catalogue, commercial, branding, UI et outreach ; aucun runtime |
| Outils de développement/QA | `tools/` | Les projets qu’ils construisent/testent ; jamais embarqués implicitement en production |
| Composants transversaux | `shared/` | Usages avérés par plusieurs consommateurs ; aucun composant exécutable actuellement |

Ninja Duel ne doit importer **aucun code des plugins Forge historiques**, directement ou par une dépendance transitive. `plugins/*` ne doit importer **aucun code de Ninja Duel**, ni de Motion Lab. Motion Lab peut utiliser un adapter vers Ninja Duel, mais **le runtime Ninja Duel ne dépend jamais de Motion Lab**. Ne pas créer de dépendance dans `shared/` qui contourne ces règles.

Les dossiers `src/Shared` internes à un projet restent locaux à ce projet. Leur nom ne signifie pas qu’ils sont transversaux au dépôt. Les moteurs Forge utilisés par Playground restent dans leurs plugins d’origine : leur consommation réelle est préservée sans créer de framework.

## Documentation et migrations

| Ancien emplacement | Emplacement actuel |
|---|---|
| `products/*` | `plugins/*` |
| `experiences/forge-playground/` | `plugins/forge-playground/` |
| Documents Forge auparavant directement sous `docs/` | `docs/forge/` (structure interne préservée) |
| `missions/ninja-duel-v0/` | `games/ninja-duel/docs/missions/` |
| Brief initial et anciens plans du jeu | `games/ninja-duel/docs/archive/` |
| Rapports V0.2 et passes du jeu | `games/ninja-duel/docs/reports/` |
| Suivi animation ouvert | `games/ninja-duel/docs/current/` |

README, licences tierces, assets et vendor Ninja Duel restent auprès du jeu. `docs/game-market-research.md` concerne une étude de jeux générique : il reste en place. Les guides et médias propres à un plugin restent dans son workspace.

Les quatre builders qui vérifient les checkpoints Git antérieurs au refactor utilisent encore le nom `products/` **pour la lecture de ces objets historiques uniquement**. Les chemins sur disque et les nouveaux manifests utilisent `plugins/`. Les hashes/preuves QA sauvegardés représentent leur exécution historique ; une migration documentaire ne vaut pas une nouvelle acceptation native.

Avant un prochain déplacement : chercher les références au chemin et au nom, identifier tous les consommateurs, garder les composants transversaux et laisser les cas ambigus en place. Aucune suppression sans preuve d’absence d’usage.

## Vérification

Depuis la racine :

```sh
python3 tools/check_architecture.py
python3 -m unittest discover -s tools -p 'test_architecture.py'
python3 -m unittest discover -s tools/forge-release -p 'test_*.py'
bash games/ninja-duel/tests/run.sh
python3 tools/forge-release/verify_freeze.py --rojo /chemin/vers/rojo
python3 games/ninja-duel/build.py
python3 games/ninja-duel/build.py --qa
python3 plugins/forge-playground/tools/build.py --rojo /chemin/vers/rojo
python3 plugins/forge-playground/tools/build.py --qa --rojo /chemin/vers/rojo
```

Le contrôle de frontières inspecte les chemins Rojo, imports/requires littéraux, imports Python et espaces de noms Roblox, y compris via `shared/`. Les imports calculés et résolutions dynamiques exigent toujours une revue ; ce contrôle statique ne prétend pas les prouver.

Validation du refactor (2026-10-11) : 34 projets Rojo reconstruits et comparés avant/après, tous byte-identiques ; aucune source Lua/Luau modifiée ; 64 assertions Ninja Duel, 7 tests de packaging et 7 tests de frontières PASS ; gate des cinq candidats Forge Studio PASS ; 390 liens Markdown préalablement valides restent valides. Les builds des places normale/QA ont également été exercés pour Ninja Duel et Playground dans des copies isolées.

Les anciens gates techniques/final/UI qui supposent les sources V1 échouent déjà avant le refactor face aux sources UI actuelles. Leurs échecs restent identiques après migration ; ils ne sont pas réécrits pour masquer cette divergence. `build_scenes.py` nécessite un checkout donor externe épinglé, absent du dépôt : son chemin de sortie est actualisé, mais son exécution complète n’est pas revendiquée. Les résultats des wrappers et comparaisons sont consignés dans [architecture-validation.json](architecture-validation.json).

Aucune QA native Studio ni publication n’a été exécutée pendant ce refactor. L’identité des sources et des 34 builds prouve l’absence de modification des programmes embarqués ; elle ne remplace pas une nouvelle session native Studio.
