# Registre de sources

| Source | État de revue / portée | IDs |
|---|---|---|
| [COMBAT_VERBS_AND_STATES.md](../../design_research/01_combat_grammar/COMBAT_VERBS_AND_STATES.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | COM-002..007, DEF-003/005 |
| [COMBO_BUILDING_BLOCKS.md](../../design_research/01_combat_grammar/COMBO_BUILDING_BLOCKS.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | COM-002..007, DEF-003/005 |
| [AWAKENING_DESIGN.md](../../design_research/02_character_architecture/AWAKENING_DESIGN.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | SYS-003, CHR-CORE-002 |
| [ROSTER_ARCHETYPES_32.md](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | CHR-EXT-002, CHR-CORE-001 |
| [SYSTEM_INTERACTION_MATRIX.md](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | TOOL-006, SYS-001/002 |
| [MOVEMENT_SOURCE_PIPELINE.md](../../design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | RES-001, RES-002, CHR-CORE-002 |
| [RESEARCH_BACKLOG.md](../../design_research/04_research/RESEARCH_BACKLOG.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | RES-001, RES-002, CHR-CORE-002 |
| [CLAUDE_USAGE_GUIDE.md](../../design_research/05_claude_handoff/CLAUDE_USAGE_GUIDE.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | RES-001, RES-002, CHR-CORE-002 |
| [README.md](../../design_research/README.md) | READ_FOR_EXTRACTION ; propositions, pas approbation ni observation vidéo certifiée | RES-001, RES-002, CHR-CORE-002 |
| [Vidéo fournie](https://youtu.be/uomkLDU10Lo?is=CrkR68i87Xife6tv) | PROVIDED_NOT_REVIEWED : pas visionnée dans ce refactor | RES-003, COM-002, MOV-001 |
| [UPD1] Voie Shinobi / Shinobi Way | PROVIDED_NOT_REVIEWED ; nom utilisateur, identité/lien/versions à vérifier | RES-003 |
| Naruto Arène de combat Shinobi ultime / Naruto Ninja Fighting Arena | PROVIDED_NOT_REVIEWED ; nom utilisateur, identité/lien/versions à vérifier | RES-003 |
| Roblox combat-system showcase + free download via `direct-link.net/1402163/NFWuW` + movement system via `link-hub.net/1402163/jfbUGuQZ` | PROVIDED_NOT_REVIEWED ; utilisateur fournit la description « smooth and responsive combat system » et indique un movement system séparé. Ne pas télécharger/exécuter tant que provenance, licence, contenu et sécurité ne sont pas vérifiés. Étudier surtout responsiveness, transitions, hit feel, mouvement et architecture réutilisable ; comparer aux systèmes actuels au lieu de remplacer le moteur aveuglément. | RES-003, COM-002, COM-003, COM-005, MOV-001, MOV-004, CAM-002 |

Ces noms/vidéo sont conservés depuis [la mission finale complète](../archive/missions/CLAUDE_FINAL_PASS.md). Ne pas inventer URL, timecode, verdict concurrentiel ou mouvements observés. Lors d’une review : consigner lien/date/version/âge, scène/timecode et observations exactes, puis mécanique candidate, label lore, IDs et limites. Une source proposée n’est pas une autorisation de copier le système entier.

## Références utilisateur ajoutées — 2026-10-12

### Showcase combat Roblox Studio

- Source : description collée par l’utilisateur ; URL YouTube, auteur et titre exact non fournis.
- [Download annoncé](https://direct-link.net/1402163/NFWuW) ; [Movement System utilisé dans la vidéo](https://link-hub.net/1402163/jfbUGuQZ).
- Promesses de la description : combat fluide/réactif, gratuit, destiné aux jeux action/PvP/RPG, mécanique propre et extensible. Les hashtags comprennent R6 ; compatibilité R15 non démontrée.
- Statut : PROVIDED_NOT_REVIEWED. Les trois liens de téléchargement de ces deux références ont été tentés avec l’outil web le 12 octobre2026 ; accès indisponible via cet outil. Aucun fichier téléchargé, code inspecté ou vidéo visionnée. Gratuité, licence, provenance et qualité réelle non vérifiées.
- Travail lié : RES-003 pour retrouver vidéo/source/version et analyser ; COM-002/003/005 et DEF-003 pour contacts, continuité, défense et décisions ; MOV-001/004 pour la liaison mouvement/combat. Extraire seulement les mécanismes utiles après comparaison avec le runtime existant, pas remplacer le moteur par défaut.

### R15 Movement System

- Source : description et métadonnées collées par l’utilisateur ; URL YouTube, auteur et titre exact de la vidéo non fournis.
- [Download annoncé](https://linkvertise.com/1402163/VyLSC).
- Métadonnées fournies, non vérifiées : 37 452 vues, publication8 février2026.
- Promesses de la description : framework de mouvement pour personnages R15, walking/running/jumping/directional control plus fluides/réactifs, animations plus réalistes, meilleure gestion physique et expérience plus soignée.
- Statut : PROVIDED_NOT_REVIEWED ; accès web au lien indisponible, aucun téléchargement/inspection ni visionnage. Ne pas confondre une promesse commerciale avec une preuve de physique, d’appuis ou de feel.
- Travail lié : RES-003 ; MOV-001/002/003/004/005 (course multidirectionnelle, appuis, course latérale, continuité, saut/traversal) ; CAM-002 si les observations montrent une contribution caméra à la vitesse perçue. Comparer course/sprint, impulsion, momentum horizontal, contrôle aérien et réception avec les exigences actives.

Pour les deux : obtenir la vidéo originale et une source de modèle inspectable, documenter timecodes/rig/inputs/contacts/appuis/trajectoires et limites, distinguer observation de promesse, vérifier licence et dépendances avant toute réutilisation. Ne pas assimiler les deux liens de movement à un même système sans preuve. Ces références enrichissent les IDs existants ; elles n’autorisent aucune intégration runtime, animation ou caméra dans cette capture.
