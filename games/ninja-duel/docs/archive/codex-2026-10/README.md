# Les branches Codex d'octobre : leurs documents et rapports (archivés le 23/11)

François (23/11) : « tout ce qui a été fait doit être ajouté ». Ces branches sont le prototype d'octobre, avant la branche commune. Leurs documents et rapports sont rangés ici, chacun dans le dossier de sa branche, avec leurs chemins d'origine. Ce sont des documents d'époque, pas des règles actives.

| Dossier | Branche | Ce que c'était |
|---|---|---|
| `ninja-chakra-interactions/` | `codex/ninja-chakra-interactions` | règles d'interactions de chakra et labo (11/10) |
| `ninja-devtools-online/` | `codex/ninja-devtools-online` | diagnostics Studio, outils QA, bases du jeu en ligne (11/10) |
| `ninja-progression-foundations/` | `codex/ninja-progression-foundations` | progression, collection et profils de développement (11/10) |
| `forge-motion-lab-ui-edit/` | `codex/forge-motion-lab-ui-edit` | missions de passe sur la bibliothèque de mouvements (11/10) |

Les rapports de `codex/ninja-fight-continuity` (25/10) sont à leur chemin d'origine, `docs/archive/reports/fight-continuity-2026-10-25/` et `docs/archive/requests/2026-10-25-fight-continuity.md`. Ses deux sondes Studio sont dans `tools/studio/probes/` (`fight_record`, `fight_sequence`).

**Le code de ces prototypes n'est pas repris dans `src/`.** Le jeu l'a remplacé depuis : `Server/Online`, `Server/Progression` et `ProfileSchema`, `Server/ChakraFlow`. Il reste lisible dans ces branches sur GitHub. Le script `run-kimi-motion.sh` n'est pas repris : il demande un outil extérieur (le CLI Kimi).
