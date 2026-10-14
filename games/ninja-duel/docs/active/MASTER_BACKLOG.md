# Backlog maître cumulatif

Snapshot 2026-10-12. Chaque bloc est un record Markdown stable, filtrable par ses champs. P0 = reprise/sûreté, P1 = cœur du duel et qualité, P2 = profondeur/profilage, P3 = futur conditionnel. `CORE4` = Minato/Itachi/Neji/Sasuke ; `ALL` = transversal. Ce tableau est cumulatif ; tous ses tickets ouverts ne sont pas un plan approuvé.

Statuts : OPEN/PARTIAL/IN_PROGRESS/DONE/BLOCKED/DEFERRED/REJECTED. Résultat IMPROVED : DONE + outcome IMPROVED + justification/proof. Une clôture technique ne clôt pas l’item visuel adjacent. Chaque ticket référence au moins une source documentaire liée ou une `justification` explicite non vide ; NONE/TBD ne constituent pas une provenance. Chaque exigence détaillée conserve sa source ; consulter [couverture](../reports/SOURCE_COVERAGE.md), specs et documents complets avant exécution. Les idées research restent candidates tant que non validées. Dependencies désigne les prérequis pour clôturer le critère, pas une interdiction d’auditer en parallèle.

Convention DONE : un ticket clôt son critère, pas une feature entière par déduction. `outcome: VERIFIED_TECHNICAL` = DONE technique ; `VERIFIED_NATIVE` = critère natif Studio prouvé ; `VERIFIED_HUMAN` = critère accepté visuellement/humainement. Evidence distingue TECHNICAL / NATIVE_STUDIO / HUMAN_VISUAL : PASS, PENDING, FAIL ou NOT_APPLICABLE justifié, avec artefact et preuve. IMPROVED documente les mêmes dimensions. Les DONE existants VERIFIED_TECHNICAL ne valent pas acceptation Studio/humaine.

Une feature technique peut donc avoir un ticket DONE et un ticket visuel PARTIAL/OPEN : COM-001 → COM-002/003/004/005 ; DEF-001/004 → DEF-002/003/005 ; CHR-*-001 → CHR-*-002 et CHR-CORE-001/002 ; LAB-001 → LAB-002/003 ; QA-002/003 → QA-001/005. Ne pas cacher ces suites lorsque les tests passent. Si tous les critères restent dans le même ticket, conserver PARTIAL jusqu’à leur validation.

Avant tout nouvel ID, rechercher une intention équivalente dans le backlog, y compris DONE/DEFERRED/REJECTED. Enrichir l’ID existant et ajouter la source ; scinder en sous-ID lié au parent seulement si son périmètre devient trop large. Deux formulations ou deux dates ne justifient jamais deux tickets de même intention.

## DOC-001 — Entrée unique et orchestration cumulative traçable

- status: DONE
- priority: P0
- dependencies: NONE
- subsystem: docs
- character: ALL
- summary: Entrée unique et orchestration cumulative traçable
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Fichiers requis, liens actifs, IDs/dépendances et couverture des sources valides
- evidence: check_project_docs.py + rapport ORCHESTRATION_REFACTOR
- outcome: VERIFIED_TECHNICAL

## QA-001 — Baseline Studio du HEAD actuel, 16 matchups et manette

- status: OPEN
- priority: P0
- dependencies: QA-002, QA-003
- subsystem: qa
- character: CORE4
- summary: Baseline Studio du HEAD actuel, 16 matchups et manette
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Artefact exact/hashes ; quatre joueurs × quatre IA ; contrôles, transitions, camera, reset/rematch ; résultat natif distinct du feel
- evidence: Native final PENDING ; anciens reports non transférables
- outcome: PENDING

## QA-002 — Contrats headless existants

- status: DONE
- priority: P0
- dependencies: DOC-001
- subsystem: qa
- character: ALL
- summary: Contrats headless existants
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: 15 suites /153 cas passent sur sources actuelles
- evidence: tests/run.sh : 153 PASS (2026-10-14, Input.spec ajouté par DEC-011) ; ne valide pas feel
- outcome: VERIFIED_TECHNICAL

## QA-003 — Builds normal/debug/QA isolés

- status: DONE
- priority: P0
- dependencies: DOC-001
- subsystem: qa
- character: ALL
- summary: Builds normal/debug/QA isolés
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Trois builds sourceEquality PASS, 4 tests isolation ; normal sans QA/Lab
- evidence: build.py + test_build_isolation.py : PASS
- outcome: VERIFIED_TECHNICAL

## QA-004 — Reproduire séquences anormales et cycle de match

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: qa
- character: CORE4
- summary: Reproduire séquences anormales et cycle de match
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Jumpattack/attackjump/launcher-chase/airslam/walldash/teleport/mash/hitstun/cancel/landing ; mort reset rematch sans fuite
- evidence: Regression/Sequences/Preparation passent ; scène native à documenter
- outcome: PENDING

## QA-005 — Contrôles natifs Mac/PC/manette puis périmètre mobile

- status: OPEN
- priority: P1
- dependencies: QA-001
- subsystem: qa
- character: CORE4
- summary: Contrôles natifs Mac/PC/manette puis périmètre mobile
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Chaque action accessible sans conflit, lock/camera confortable ; plateformes testées explicites
- evidence: Mapping centralisé Controls ; correctif clavier/PS5 `2de7b03`/`5db5199` + Input.spec 14 PASS (TECHNICAL) ; NATIVE_STUDIO et manette réelle PENDING ; ergonomie humaine non validée
- outcome: PENDING

## MOV-001 — Course huit directions et conscience partielle de la cible

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Course huit directions et conscience partielle de la cible
- sources: [LOCOMOTION](../movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md)
- validation: Avant/arrière/strafe/diagonale/orbite/sprint/poursuite/reentrée ; tête/torse visent sans obliger hanches à glisser ; comparaison native avant/après
- evidence: Animation/renderer/IK existent, aucune acceptation native actuelle
- outcome: PENDING

## MOV-002 — Appuis, cadence et transfert de poids crédibles

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Appuis, cadence et transfert de poids crédibles
- sources: [LOCOMOTION](../movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md)
- validation: Longueur/fréquence du pas liées vitesse, bonne jambe pousse, pied pose stable, centre de gravité, dash impulsé ; comparaison native avant/après
- evidence: Animation/renderer/IK existent, aucune acceptation native actuelle
- outcome: PENDING

## MOV-003 — Vraie course latérale et changement de direction

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Vraie course latérale et changement de direction
- sources: [LOCOMOTION](../movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md)
- validation: Observer chaque direction et retournement, sans moonwalk/pivot mécanique ni glissade latérale ; comparaison native avant/après
- evidence: Animation/renderer/IK existent, aucune acceptation native actuelle
- outcome: PENDING

## MOV-004 — Continuité biomécanique des actions

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Continuité biomécanique des actions
- sources: [LOCOMOTION](../movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md)
- validation: Pied→hanche→torse→épaule→membre, anticipation/contact/followthrough/recovery ; aucun cut/run→attaque→run ; comparaison native avant/après
- evidence: Animation/renderer/IK existent, aucune acceptation native actuelle
- outcome: PENDING

## MOV-005 — Transitions air, landing et mur cohérentes

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Transitions air, landing et mur cohérentes
- sources: [LOCOMOTION](../movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md)
- validation: Impulsion, ascension/apogée/chute, appui mur, rebond, poursuite, récupération et corps lisibles sans snap ; comparaison native avant/après
- evidence: Animation/renderer/IK existent, aucune acceptation native actuelle
- outcome: PENDING

## MOV-006 — Évaluer prediction si preuves de latence la justifient

- status: DEFERRED
- priority: P2
- dependencies: NET-001
- subsystem: network
- character: ALL
- summary: Évaluer prediction si preuves de latence la justifient
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Mesure avant/après réseau réelle, autorité/hit validation conservées ; activation après décision PvP
- evidence: Pas de prediction générale ; ne pas repartir sur ancien moteur rollback
- outcome: PENDING

## COM-001 — Grammaire directionnelle et routes techniques existantes

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: combat
- character: CORE4
- summary: Grammaire directionnelle et routes techniques existantes
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Branches ground/air/launcher/chase/slam/throw/side swap/wall bornées
- evidence: Branches/Sequences/Sasuke/Preparation PASS
- outcome: VERIFIED_TECHNICAL

## COM-002 — Taijutsu riche et expressif

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Taijutsu riche et expressif
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Jab/cross/hook/uppercut/elbow/knee/kicks/sweep/spin/projection, formes adaptées au jeune personnage ; pas ajouter un bouton par brique ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; qualité et variété restent ouvertes
- outcome: PENDING

## COM-003 — Synchroniser corps, contact, cible et réaction

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Synchroniser corps, contact, cible et réaction
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Moment d’impact coïncide visuellement avec hitbox/réaction ; zone touchée cohérente ; VFX ne masque pas défaut ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; qualité et variété restent ouvertes
- outcome: PENDING

## COM-004 — Conversions air/mur et branches libres

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Conversions air/mur et branches libres
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Réaction→poursuite→conversion, drive/spike/side switch/wallpin/bounce/tech ; choisir poursuivre ou sortir ; whiff puni ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; qualité et variété restent ouvertes
- outcome: PENDING

## COM-005 — Transitions, cancels et décisions entre combos

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Transitions, cancels et décisions entre combos
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Feinte/outil/esquive/angle/clash/counter/disengage ; fenêtres lisibles, pas autoroutes ni infinites ni recovery gratuite ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; qualité et variété restent ouvertes
- outcome: PENDING

## COM-006 — Grabs et micro-conflits physiques

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Grabs et micro-conflits physiques
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Saisies courtes, poignet/pied retenu, projections directions/air/mur ; entrées et sorties lisibles, contre-jeu, pas cinéma 10 secondes ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; qualité et variété restent ouvertes
- outcome: PENDING

## COM-007 — États utilisables sans inventer un doublon d’enum

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: États utilisables sans inventer un doublon d’enum
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Contact→état→transition→conversion ; vérifier offbalance/guardopen/weaponclash par comportements, existing GuardBreak/events/recovery avant nouveau state ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; qualité et variété restent ouvertes
- outcome: PENDING

## DEF-001 — Guard, parry, dodge, riposte techniques

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: defense
- character: CORE4
- summary: Guard, parry, dodge, riposte techniques
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Coûts/fenêtres/récupérations et décisions serveur bornés
- evidence: Rules/Combat/Phase4/Regression PASS
- outcome: VERIFIED_TECHNICAL

## DEF-002 — Substitution à ressources et contre-jeu

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: defense
- character: CORE4
- summary: Substitution à ressources et contre-jeu
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Pas évasion gratuite infinie ; clarté fenêtre charge/chakra et sorties ; duel humain
- evidence: Coûts/recharge implémentés et testés ; contre-jeu humain en attente
- outcome: PENDING

## DEF-003 — Déviation/parade corporelle lisible

- status: PARTIAL
- priority: P1
- dependencies: QA-001, COM-003
- subsystem: defense
- character: CORE4
- summary: Déviation/parade corporelle lisible
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Arme ou membre agit visiblement ; récupération et riposte perceptibles
- evidence: Défense technique existe ; expressivité non acceptée
- outcome: PENDING

## DEF-004 — Clash de frappes technique

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: defense
- character: CORE4
- summary: Clash de frappes technique
- sources: [COMBAT_REQUIREMENTS](../combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Conflit produit recovery contrôlée et sort proprement
- evidence: Phase4/Systems/Preparation PASS ; pas collision universelle
- outcome: VERIFIED_TECHNICAL

## DEF-005 — Évaluer conflits projectile/outil généralisés

- status: OPEN
- priority: P2
- dependencies: QA-001, TOOL-001
- subsystem: tools
- character: CORE4
- summary: Évaluer conflits projectile/outil généralisés
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Prototype ciblé, règles angle/temps/chakra, contre-jeu, trajectoires ; éviter moteur générique préalable
- evidence: Geometry spécifique existe ; généralisation non démontrée
- outcome: PENDING

## TOOL-001 — Cycle technique des projectiles et maîtrise commune

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: tools
- character: CORE4
- summary: Cycle technique des projectiles et maîtrise commune
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Lancement mobile, déplacement/impact/expiration et nettoyages bornés
- evidence: Tools/Systems/Preparation PASS
- outcome: VERIFIED_TECHNICAL

## TOOL-002 — Outils physiquement persistants et interactions ciblées

- status: PARTIAL
- priority: P2
- dependencies: QA-001, TOOL-001
- subsystem: tools
- character: CORE4
- summary: Outils physiquement persistants et interactions ciblées
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Distinguer main/draw/grip/release/vol/planté/expiration ; recall/équipement si besoin prouvé ; FTG identité de marque intacte
- evidence: Minato body/surface/in-flight marks ; pas inventaire générique prouvé
- outcome: PENDING

## TOOL-003 — Fil puis DragonFlame technique

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: tools
- character: Sasuke
- summary: Fil puis DragonFlame technique
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: WireTrap/fire conversion contrôlée, cancel et cleanup sûrs
- evidence: Sasuke/Tools PASS
- outcome: VERIFIED_TECHNICAL

## TOOL-004 — Étudier smoke et explosive tags dédiés

- status: DEFERRED
- priority: P2
- dependencies: QA-001
- subsystem: tools
- character: CORE4
- summary: Étudier smoke et explosive tags dédiés
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Activation après validation intérêt/inputs/contre-jeu ; smoke substitution ≠ outil ; explosion jutsu ≠ tag
- evidence: Absents ; concepts conditionnels, pas nouveaux systèmes immédiats
- outcome: PENDING

## TOOL-005 — Continuité outil ↔ corps à corps

- status: PARTIAL
- priority: P1
- dependencies: QA-001, COM-003
- subsystem: tools
- character: CORE4
- summary: Continuité outil ↔ corps à corps
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Draw/grip/release, throw pendant run/air/dodge, retour contact et conversion distincts par personnage
- evidence: Tools et routes existent ; transitions corporelles à juger
- outcome: PENDING

## TOOL-006 — Prototype ciblé objet + chakra + déclencheur → résultat

- status: OPEN
- priority: P2
- dependencies: QA-001, SYS-001
- subsystem: chakra
- character: CORE4
- summary: Prototype ciblé objet + chakra + déclencheur → résultat
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Au moins interaction concrète lisible/contre-jeu avant abstraction ; infusion propriété/nature testée
- evidence: Vision systémique ; aucun système général actuel
- outcome: PENDING

## SYS-001 — Faire du chakra une décision contextuelle

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: chakra
- character: CORE4
- summary: Faire du chakra une décision contextuelle
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Coût, recharge, infusion, déclencheur, opportunité et contre-jeu mesurés ; éviter barre cosmétique
- evidence: Ressources et jutsu présents ; infusion générale absente
- outcome: PENDING

## SYS-002 — Interactions élémentaires/environnement ciblées

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: elements
- character: CORE4
- summary: Interactions élémentaires/environnement ciblées
- sources: [TOOLS_AND_CHAKRA](../systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
- validation: Documenter interactions réellement existantes, prototypes et conditions ; pas full matrix forcée
- evidence: Elements + System interactions ; couverture non exhaustive
- outcome: PENDING

## SYS-003 — Awake modifie des règles et respecte la jeunesse

- status: PARTIAL
- priority: P2
- dependencies: QA-001, CHR-CORE-002
- subsystem: awakening
- character: CORE4
- summary: Awake modifie des règles et respecte la jeunesse
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Deux modifications de règles compréhensibles proposées/testées par kit ; labels lore ; pas boost statistique seul
- evidence: Awake et fenêtres existantes ; research adulte filtrée, qualité à auditer
- outcome: PENDING

## CHR-MIN-001 — Marques FTG et angles techniques

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: character
- character: Minato
- summary: Marques FTG et angles techniques
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Contrats existants passent ; scope technique uniquement
- evidence: Phase4/Tools/Preparation : body/surface/inflight, swaps et followups ; aucun verdict artistique
- outcome: VERIFIED_TECHNICAL

## CHR-ITA-001 — Geometry, ricochet et lecture techniques

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: character
- character: Itachi
- summary: Geometry, ricochet et lecture techniques
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Contrats existants passent ; scope technique uniquement
- evidence: Phase4/Tools/Preparation : shuriken geometry/fire lanes ; aucun verdict artistique
- outcome: VERIFIED_TECHNICAL

## CHR-NEJ-001 — GentleFist, Rotation et Tenketsu techniques

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: character
- character: Neji
- summary: GentleFist, Rotation et Tenketsu techniques
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Contrats existants passent ; scope technique uniquement
- evidence: Neji/Preparation PASS ; aucun verdict artistique
- outcome: VERIFIED_TECHNICAL

## CHR-SAS-001 — Lion, ShadowLeaf, fil, Chidori techniques

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: character
- character: Sasuke
- summary: Lion, ShadowLeaf, fil, Chidori techniques
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Contrats existants passent ; scope technique uniquement
- evidence: Sasuke/Preparation PASS ; aucun verdict artistique
- outcome: VERIFIED_TECHNICAL

## CHR-MIN-002 — Identité jeune, grip kunai, transfert et vitesse

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Minato
- summary: Identité jeune, grip kunai, transfert et vitesse
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Entrée/sortie main/FTG visibles ; rapidité corporelle lisible, pas costume Hokage ; preuve native/lore pertinente
- evidence: Code et profils existent ; audit visuel/lore détaillé non clôturé
- outcome: PENDING

## CHR-MIN-003 — Conversions Minato recherchées

- status: OPEN
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Minato
- summary: Conversions Minato recherchées
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Sources jeunes + angle/marque/outil/poursuite ; juger avant ajout, pas copier kit adulte ; preuve native/lore pertinente
- evidence: Code et profils existent ; audit visuel/lore détaillé non clôturé
- outcome: PENDING

## CHR-ITA-002 — Calme, tromperie, geometry et feu

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Itachi
- summary: Calme, tromperie, geometry et feu
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Lecture, précision, feintes et lanes distinctes, pas spam jutsu ni costume Akatsuki ; preuve native/lore pertinente
- evidence: Code et profils existent ; audit visuel/lore détaillé non clôturé
- outcome: PENDING

## CHR-NEJ-002 — Personnaliser les clips hérités air/throws

- status: OPEN
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Neji
- summary: Personnaliser les clips hérités air/throws
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Héritage Mirage préservé adapter ; juger paumes/rotation/pression/précision et créer variante seulement si insuffisant ; preuve native/lore pertinente
- evidence: Code et profils existent ; audit visuel/lore détaillé non clôturé
- outcome: PENDING

## CHR-SAS-002 — Agressivité jeune et transitions mix-range

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Sasuke
- summary: Agressivité jeune et transitions mix-range
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Lion/Flashstep hérités évalués, kicks/fil/projection/poursuite/recovery distincts et lisibles ; preuve native/lore pertinente
- evidence: Code et profils existent ; audit visuel/lore détaillé non clôturé
- outcome: PENDING

## CHR-CORE-001 — Quatre identités reconnaissables sans jutsu

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: CORE4
- summary: Quatre identités reconnaissables sans jutsu
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Mouvement, garde, distance, rythme, outil, conversions distinguent quatre en duel ; preuve native/lore pertinente
- evidence: Code et profils existent ; audit visuel/lore détaillé non clôturé
- outcome: PENDING

## CHR-CORE-002 — Revue lore par capacité

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: CORE4
- summary: Revue lore par capacité
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md)
- validation: Chaque proposition/kit documente label canonical jeune/plausible/liberté/rejet adulte avec source exacte ; preuve native/lore pertinente
- evidence: Code et profils existent ; audit visuel/lore détaillé non clôturé
- outcome: PENDING

## CHR-EXT-001 — Activer Gaara uniquement sur décision explicite

- status: DEFERRED
- priority: P3
- dependencies: QA-001
- subsystem: roster
- character: Gaara
- summary: Activer Gaara uniquement sur décision explicite
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Client/UI, identité/motion/lore, matrice et native complets avant exposition
- evidence: Serveur +10tests existent ; caché ; déclencheur ouverture roster
- outcome: PENDING

## CHR-EXT-002 — Conserver ~32 archétypes et dix blueprints riches

- status: DEFERRED
- priority: P3
- dependencies: QA-001
- subsystem: roster
- character: FUTURE32
- summary: Conserver ~32 archétypes et dix blueprints riches
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Scope approuvé, architecture kit, source/lore/validation spécifique ; pas produire32 kits maintenant
- evidence: ROSTER_ARCHETYPES_32 (pool prioritaire de 25 personnages choisi par l’utilisateur le 2026-10-13, `16e3a00`) et ROSTER_MOVESETS_10_PRODIGIES conservés ; aucune activation
- outcome: PENDING

## ARENA-001 — Échelle utile et exploitation murs/cover

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: arena
- character: CORE4
- summary: Échelle utile et exploitation murs/cover
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Course/range/time de réentrée, fil/teleport/projectiles, wallcarry/pin/bounce et tech utiles ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## ARENA-002 — Tournoi jeune et présentation légère

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: presentation
- character: CORE4
- summary: Tournoi jeune et présentation légère
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Intros/results/juges/faces/costumes/bannières/audio lisibles ; pas longs films ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## ARENA-003 — Espace vertical et lignes de vue

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: arena
- character: CORE4
- summary: Espace vertical et lignes de vue
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Bornes, heights/LOS/angles/obstacles influencent combat sans bloquer mouvements ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## CAM-001 — Continuité camera et swap

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: camera
- character: CORE4
- summary: Continuité camera et swap
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Lock/free, fade, zoom, sideswap, téléport/throw/air/wall sans snap gênant ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## CAM-002 — Confort haute vitesse et verticalité

- status: OPEN
- priority: P1
- dependencies: QA-001
- subsystem: camera
- character: CORE4
- summary: Confort haute vitesse et verticalité
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Quatre personnages, caméra en poursuite et manette, ne masque pas appuis/contact ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## FX-001 — Audio d’impact et feedback

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: audio
- character: CORE4
- summary: Audio d’impact et feedback
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Contacts, parry/tool/wall/steps lisibles, pas effets pour cacher corps insuffisant ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## FX-002 — Réactions par zones et usure corporelle

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: reactions
- character: CORE4
- summary: Réactions par zones et usure corporelle
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Hit bodyzone, déséquilibre, réception, knockdown/KO et recovery, usure non gênante ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## UX-001 — Grammaire simple, tutoriel et choix contextuels

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: inputs
- character: CORE4
- summary: Grammaire simple, tutoriel et choix contextuels
- sources: [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Toutes routes apprenables et cohérentes keyboard/manette, aucun input conflict ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente
- outcome: PENDING

## UX-002 — Mobile, rebinding et accessibilité

- status: OPEN
- priority: P2
- dependencies: QA-005
- subsystem: inputs
- character: ALL
- summary: Mobile, rebinding et accessibilité
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Prototype/contrôle plate-forme explicite sans overlay debug ; conserver simplicité
- evidence: Pas de validation cross-platform ; ancienne roadmap candidate
- outcome: PENDING

## NET-001 — PvP deux joueurs / audit fondation réseau

- status: DEFERRED
- priority: P2
- dependencies: QA-001
- subsystem: network
- character: ALL
- summary: PvP deux joueurs / audit fondation réseau
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Décision scope, deux clients réel, autorité, délais/erreurs et reconnection validés avant prediction
- evidence: Match actuel joueur vs IA ; vieux rollback/IAS non exigence de réécriture
- outcome: PENDING

## NET-002 — Robustesse réseau et entrées hostiles

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: network
- character: ALL
- summary: Robustesse réseau et entrées hostiles
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Charge/latence réelle, finite/borne/rate limits et déconnexions ; pas transfert de confiance client
- evidence: Validation serveur/anti-cheat/rate limit existants ; profil réel à compléter
- outcome: PENDING

## PERF-001 — Mesurer parts, cadence, rematches et multi-lanes

- status: OPEN
- priority: P2
- dependencies: QA-001
- subsystem: performance
- character: ALL
- summary: Mesurer parts, cadence, rematches et multi-lanes
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Mesures exactes device,10rematches/cleanup ; spectateurs/30players seulement si scope activé, pas promesse
- evidence: Ancien plan chiffre1300parts et lanes ; budget réel non mesuré
- outcome: PENDING

## BAL-001 — Balance humain et durée sans inflation HP

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: balance
- character: CORE4
- summary: Balance humain et durée sans inflation HP
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Seeds/sim distinctes des duels humains ; diversité routes/defense, pas augmenter HP pour masquer manque de décisions
- evidence: Simulation disponible ; durée AI historique45–70s pas vérité joueur
- outcome: PENDING

## AI-001 — IA comprend les conversions tactiques utiles

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: ai
- character: CORE4
- summary: IA comprend les conversions tactiques utiles
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Mesurer planification wall/seal/angle/outil et sorties sans triche ni spam
- evidence: AI fonctionne ; reports limites planification non clôturés
- outcome: PENDING

## REL-001 — Publication traçable de la place

- status: DEFERRED
- priority: P3
- dependencies: QA-001, PERF-001
- subsystem: release
- character: ALL
- summary: Publication traçable de la place
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Plan autorisé + permissions réelles, PlaceID/version/artifact/source SHA/tests enregistrés ; ne pas réutiliser ancien compte supposé
- evidence: Pas de publication vérifiée dans ce refactor
- outcome: PENDING

## RES-001 — Banques de mouvement source → mécanique → variante

- status: PARTIAL
- priority: P1
- dependencies: RES-002
- subsystem: research
- character: CORE4
- summary: Banques de mouvement source → mécanique → variante
- sources: [SOURCE_REGISTER](../research/SOURCE_REGISTER.md); [MOVEMENT_SOURCE_PIPELINE](../../design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md); [CLAUDE_DESIGN_LIBRARY_WORKFLOW](../archive/missions/CLAUDE_DESIGN_LIBRARY_WORKFLOW.md)
- validation: Sources scène/timecode/âge/lore, contact/réaction/résultat/followup/pieds/caméra/input ; banques détaillées dans protocole
- evidence: Pipeline et catalogue Lab existent ; banques4kits/lore non terminées
- outcome: PENDING

## RES-002 — Préserver catalogue de briques Lab

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: research
- character: ALL
- summary: Préserver catalogue de briques Lab
- sources: [SOURCE_REGISTER](../research/SOURCE_REGISTER.md); [MOVEMENT_SOURCE_PIPELINE](../../design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md); [CLAUDE_DESIGN_LIBRARY_WORKFLOW](../archive/missions/CLAUDE_DESIGN_LIBRARY_WORKFLOW.md)
- validation: 182 anciennes briques +120 variantes, L/R et six phases, inheritance et export propres
- evidence: 45tests + UI binary smoke simulé PASS ; pas feel natif
- outcome: VERIFIED_TECHNICAL

## RES-003 — Revoir références jeux/vidéo fournies

- status: OPEN
- priority: P2
- dependencies: DOC-001
- subsystem: research
- character: ALL
- summary: Revoir références jeux/vidéo fournies
- sources: [SOURCE_REGISTER](../research/SOURCE_REGISTER.md); [MOVEMENT_SOURCE_PIPELINE](../../design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md); [CLAUDE_DESIGN_LIBRARY_WORKFLOW](../archive/missions/CLAUDE_DESIGN_LIBRARY_WORKFLOW.md)
- validation: Consulter sources, noter observations vérifiées/timecodes vs hypothèses, transférer exigences utiles IDs
- evidence: Voie Shinobi/Shinobi Way, Ninja Fighting Arena, vidéo uomkLDU10Lo et descriptions utilisateur Combat Showcase / R15 Movement System : PROVIDED_NOT_REVIEWED ; liens de téléchargement inaccessibles via outil web, détails dans SOURCE_REGISTER
- outcome: PENDING

## LAB-001 — Lab/adapters sans dépendance runtime

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: tools
- character: CORE4
- summary: Lab/adapters sans dépendance runtime
- sources: [README](../../motion-lab/README.md); [FORGE_MOTION_LAB_CODEX_BRIEF](../archive/missions/FORGE_MOTION_LAB_CODEX_BRIEF.md)
- validation: 45cas et smoke binaire simulé,4 profils exportent données finies ordonnées/inertes et héritage réel
- evidence: build.py Lab PASS ; Ninja normal isolé
- outcome: VERIFIED_TECHNICAL

## LAB-002 — Intégrer seulement exports choisis/validés par Claude

- status: OPEN
- priority: P1
- dependencies: QA-001, LAB-001
- subsystem: tools
- character: CORE4
- summary: Intégrer seulement exports choisis/validés par Claude
- sources: [README](../../motion-lab/README.md); [FORGE_MOTION_LAB_CODEX_BRIEF](../archive/missions/FORGE_MOTION_LAB_CODEX_BRIEF.md)
- validation: Sélection variante + preuve native avant/après ; timings/contacts et identité corrects ; pas exportautointégré
- evidence: Export inert ; aucune motion remplacée pendant préparation
- outcome: PENDING

## LAB-003 — QA native UI/preview du Lab final

- status: PARTIAL
- priority: P1
- dependencies: LAB-001
- subsystem: tools
- character: CORE4
- summary: QA native UI/preview du Lab final
- sources: [README](../../motion-lab/README.md); [FORGE_MOTION_LAB_CODEX_BRIEF](../archive/missions/FORGE_MOTION_LAB_CODEX_BRIEF.md)
- validation: Preview, A/B,L/R, pose/timing/sequence, persistance/restart, undo, export/import ; largeur requise et nettoyage
- evidence: Simulated UI events PASS ; final native non validé
- outcome: PENDING

## OPS-001 — Build en une commande, arrêt sur tests échoués

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: build
- character: ALL
- summary: Build en une commande, arrêt sur tests échoués
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: SourceEquality, suites et manifest distinct normal/debug/QA
- evidence: build.py et4tests isolation PASS
- outcome: VERIFIED_TECHNICAL

## OPS-002 — Traçabilité manifest source commit/date

- status: PARTIAL
- priority: P2
- dependencies: OPS-001
- subsystem: build
- character: ALL
- summary: Traçabilité manifest source commit/date
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: HEAD, hash artifact, source/timestamp reproductibles, aucun faux native PASS
- evidence: Hashes/fingerprint déjà présents ; builders LF/UTF-8 et clés POSIX depuis `b085d97` (rebuild Windows identique octet par octet) ; source commit/date non systématiques
- outcome: PENDING

## OPS-003 — Mesures performance et continuité

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: diagnostics
- character: ALL
- summary: Mesures performance et continuité
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Cadence, interpolation/positionerror/drop/rematch/camera probe, protocole exact sans changer état combat
- evidence: Inspector/trace et debug opt-in existants ; métriques complètes absentes
- outcome: PENDING

## ARC-001 — Frontières game/plugins/Lab

- status: DONE
- priority: P0
- dependencies: DOC-001
- subsystem: architecture
- character: ALL
- summary: Frontières game/plugins/Lab
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Checker +9tests et isolation, sources/artifacts plugins inchangés
- evidence: check_architecture.py PASS ; Motion Lab unidirectionnel
- outcome: VERIFIED_TECHNICAL

## ARC-002 — Scinder modules personnage seulement si besoin réel

- status: DEFERRED
- priority: P3
- dependencies: QA-001
- subsystem: architecture
- character: ALL
- summary: Scinder modules personnage seulement si besoin réel
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../reports/ORCHESTRATION_REFACTOR.md)
- validation: Deux besoins concrets/régression protégée, pas monolithe remplacé ni framework avant preuve
- evidence: FIGHTER_TEMPLATE conservé ; pas de nécessité démontrée
- outcome: PENDING

## PROG-001 — Prodigy League / Shinobi Path

- status: DEFERRED
- priority: P3
- dependencies: QA-001
- subsystem: progression
- character: ALL
- summary: Prodigy League / Shinobi Path
- sources: [FUTURE_SYSTEMS](../systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Activation explicite, scope progression/compétition et interaction duel documentés
- evidence: Vision future utilisateur ; aucune obligation présent prototype
- outcome: PENDING
