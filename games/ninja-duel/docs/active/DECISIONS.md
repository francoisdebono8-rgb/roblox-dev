# Décisions en vigueur

| ID | Décision | Conséquence |
|---|---|---|
| DEC-001 | Quatre sélectionnables : Minato/Flashstep, Itachi/Mirage, Neji/GentleFist, Sasuke/Lion | Gaara/Sand reste serveur/tests, caché dans le menu ; aucune extension implicite |
| DEC-002 | Motion Lab reste sous `games/ninja-duel/motion-lab` | Son adapter lit/exporte vers Ninja Duel ; le runtime ne dépend jamais du laboratoire |
| DEC-003 | Séparation jeu, plugins historiques et branding | `plugins/*` n’importe aucun code Ninja Duel ; le jeu n’importe aucun code Forge, même via shared |
| DEC-004 | Codex prépare outils, diagnostics, contrats, recherche et tests ; Claude juge technique, mouvement et feel | Un export Lab est inert. Claude décide son intégration après preuve native |
| DEC-005 | Jeunes prodiges et plausibilité documentée | Chaque proposition de capacité/mouvement reçoit un label lore, une source et une limite |
| DEC-006 | Grammaire commune, expressions distinctes, contrôles simples | Réutiliser les briques utiles ; éviter arbres clonés, surcharge d’inputs et framework prématuré |
| DEC-007 | Tests techniques et jugement visuel séparés | PASS automatique ≠ PASS Studio ≠ acceptation humaine |
| DEC-008 | Exigences cumulatives, sources intégrales, archives non exécutables | La dernière mission ne remplace jamais silencieusement les précédentes |
| DEC-009 | Aucune modification gameplay dans l’orchestration du 12 octobre 2026 | La prochaine exécution gameplay attend l’approbation globale de son plan |
| DEC-010 | League, Path, ~32 personnages, PvP/prediction et publication sont futurs | Maintenir le backlog, demander une décision de scope quand leur activation dépasse le plan approuvé |
| DEC-011 | 2026-10-14, approuvé par l’utilisateur avec le plan Claude : la chaîne Codex non fusionnée du 11 octobre (`codex/ninja-input-ps5` → `ninja-devtools-online` → `ninja-progression-foundations` → `ninja-chakra-interactions`) est intégrée **partiellement** | Seuls `92cd73b` + `ad8247c` (inputs clavier/PS5, Input.spec) sont repris sur `claude/ninja-duel-2026-10-14` (`2de7b03`, `5db5199`) car QA-001/QA-005 exigent des contrôles fiables. `33028b2` (devtools/online), `29a9ec1` (progression), `7091585` (chakra rules/lab) restent sur leur branche comme référence pour NET-001, PROG-001, TOOL-006/SYS-001. Alternatives rejetées : tout fusionner (active des systèmes DEFERRED et conflits DevHooks), tout ignorer (perd un correctif d’entrées testé) |

Labels obligatoires : `CANON_YOUNG` (preuve canonique à l’âge visé), `PLAUSIBLE_YOUNG` (extension plausible explicitée), `GAMEPLAY_LIBERTY` (liberté assumée avec coût/contre-jeu), `REJECT_ADULT_ONLY` (capacité adulte exclue). Une idée ancienne d’Awakening, de Mangekyō ou d’un kit adulte n’est pas autorisée par sa présence dans une recherche. L’existence d’un move dans le code ne prouve pas son label lore : CHR-CORE-002 reste PARTIAL.

Priorité normative : demande utilisateur actuelle > VISION > DECISIONS > MASTER_BACKLOG > specs actives > recherches > missions/rapports archivés. Un fait de code/test/Studio ne change pas parce qu’un document souhaite un autre comportement : signaler l’écart et proposer une décision. Ne pas inventer une approbation passée. Toute nouvelle décision note date, auteur/autorisation, raison, IDs concernés et alternatives rejetées.
