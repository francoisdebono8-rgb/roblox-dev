# Backlog maître cumulatif

Audit documentaire du 2026-10-17, base `04d6eb0`. Propriétaire unique : travail, priorités, dépendances et critères de clôture. Les liens d’archive prouvent la provenance ; ils ne délèguent aucune instruction active. Les anciennes preuves restent datées et ne valent pas validation du HEAD.

Statuts : OPEN/PARTIAL/IN_PROGRESS/DONE/BLOCKED/DEFERRED/REJECTED. Résultat IMPROVED : DONE + outcome IMPROVED + justification/proof. Une clôture technique ne clôt pas l’item visuel adjacent. Chaque ticket référence au moins une source documentaire liée ou une `justification` explicite non vide ; NONE/TBD ne constituent pas une provenance. Chaque exigence détaillée conserve sa source ; consulter [couverture](../archive/reports/SOURCE_COVERAGE.md), specs et documents complets avant exécution. Les idées research restent candidates tant que non validées. Dependencies désigne les prérequis pour clôturer le critère, pas une interdiction d’auditer en parallèle.

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
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
- validation: Exactement sept sources actives, START par rôles, inventaire complet, conservation historique, références internes valides et vérification anti-doublon documentaire.
- evidence: 2026-10-17 : audit à 04d6eb0, inventaire et dispositions dans archive/audits/2026-10-17/AUDIT.md ; checks documentaires à consigner dans le journal. Aucune preuve gameplay créée.
- outcome: VERIFIED_TECHNICAL

## QA-001 — Validation Studio — artefact courant, roster réel et manette

- status: IN_PROGRESS
- priority: P0
- dependencies: QA-002, QA-003
- subsystem: qa
- character: ALL
- summary: Validation Studio du build courant, roster réel et contrôles
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Commit/hash exacts ; vraie sélection et inputs ; neutral, chaîne, routes, outils, jutsu, défense, relance, air/mur, éveil, KO, reset/rematch. Étendre la couverture au roster courant (ancienne matrice 4×4 historique). Par nouveau fighter au moins un duel IA ; couverture diversifiée des familles puis matchups à risque ; manette réelle et acceptation humaine distinctes.
- evidence: 17/10 Codex de33f3d : [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). MCP connecté et passe à vraies touches des dix nouveaux sur Debug067b732 ; final ne change que couleur Shisui, mais gate native finale non close. Sélection réelle complète, impacts outils/projectiles, états combinés, anciens et manette physique restent à prouver. Preuves Claude antérieures conservées dans le snapshot de l’audit.
- outcome: PENDING

## QA-002 — Contrats headless existants

- status: DONE
- priority: P0
- dependencies: DOC-001
- subsystem: qa
- character: ALL
- summary: Contrats headless existants
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
- validation: 27 suites actuelles passent sur sources exactes ; contrats roster exact20, trois hits réels, effet de contact et éveil comportemental explicites. Préserver tests des vingt neutral/whiff/block/buffer.
- evidence: 17/10 Codex de33f3d : 27 suites /489 cas PASS (Lune0.10.5, Luau0.743), plus180 sondes invariant PASS ; [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). Suite actuelle permissive sur Tier A : amélioration des critères requise, sans invalider les PASS techniques existants.
- outcome: VERIFIED_TECHNICAL

## QA-003 — Builds normal/debug/QA isolés

- status: DONE
- priority: P0
- dependencies: DOC-001
- subsystem: qa
- character: ALL
- summary: Builds normal/debug/QA isolés
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
- validation: Trois builds sourceEquality PASS, 4 tests isolation ; normal sans QA/Lab
- evidence: build.py + test_build_isolation.py : PASS
- outcome: VERIFIED_TECHNICAL

## QA-004 — Reproduire séquences anormales et cycle de match

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: qa
- character: ALL
- summary: Reproduire séquences anormales et cycle de match
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Jumpattack/attackjump/launcher-chase/airslam/walldash/teleport/mash/hitstun/cancel/landing ; mort reset rematch sans fuite
- evidence: 17/10 Codex : [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md), Camellia survit au vrai resetRound (round2 DamageScale1.22) ; buff masque Heavy/Armor éveillés ; téléports30–34 acceptés depuis120. Corriger lifecycle et composition avant feel, ajouter régressions ; ces politiques préexistaient aux lots, aucune nouvelle régression ancienne attribuée sans preuve.
- outcome: PENDING

## QA-005 — Contrôles natifs Mac/PC/manette puis périmètre mobile

- status: OPEN
- priority: P1
- dependencies: QA-001
- subsystem: qa
- character: CORE4
- summary: Contrôles natifs Mac/PC/manette puis périmètre mobile
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
- validation: Chaque action accessible sans conflit, lock/camera confortable ; plateformes testées explicites
- evidence: Mapping centralisé Controls ; correctif clavier/PS5 `2de7b03`/`5db5199` + Input.spec 14 PASS (TECHNICAL) ; NATIVE_STUDIO et manette réelle PENDING ; ergonomie humaine non validée 2026-10-16 soir : double tap à 0,1 s par le vrai remote `Action` (anti-triche inclus) : Light1 seul avant, Light1 > Light2 après (`ac31aa2`, probe `double_tap.luau`). Manette matérielle toujours non testée 2026-10-16 soir : contrôles clavier/souris joués par les outils `user_keyboard_input` / `user_mouse_input` de Studio (vraies entrées jusqu’au remote) : W + trois clics = Launcher 4/4 après correction de deux défauts (marche qui contournait l’adversaire, route perdue pour une pression tardive, `3865d87`)
- outcome: PENDING

## MOV-001 — Course huit directions et conscience partielle de la cible

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Course huit directions et conscience partielle de la cible
- sources: [LOCOMOTION](../archive/movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Avant/arrière/strafe/diagonale/orbite/sprint/poursuite/reentrée ; tête/torse visent sans obliger hanches à glisser ; comparaison native avant/après
- evidence: Animation/renderer/IK existent, aucune acceptation native actuelle
- outcome: PENDING
- acceptance: Huit directions, diagonales/orbite et retournements ; tête/torse suivent partiellement la cible sans glisser les jambes ; comparer libre et lock-on en Studio.

## MOV-002 — Appuis, cadence et transfert de poids crédibles

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Appuis, cadence et transfert de poids crédibles
- sources: [LOCOMOTION](../archive/movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Longueur/fréquence du pas liées vitesse, bonne jambe pousse, pied pose stable, centre de gravité, dash impulsé ; comparaison native avant/après
- evidence: Animation/renderer/IK existent ; 2026-10-14 cadence de foulée plafonnée à 3,8 (au lieu de 3,1) au-delà de la vitesse de course pour que le sprint se lise aussi par les jambes. 2026-10-16 NATIVE_STUDIO ([audit visuel](../archive/reports/convergence/VISUAL_AUDIT.md)) : trajectoire de jambe de course refaite (talon qui remonte, genou qui passe haut, pied posé devant la hanche), bras normalisés par la foulée, appui de sprint ≥ 85 ms ; pied qui « saute » par rapport au corps en sprint 11,7 % → 4,8 % des images, course inchangée 0,1 %. TECHNICAL PASS (Animation 10). HUMAN_VISUAL PENDING
- outcome: PENDING
- acceptance: Pied d’appui, poussée, cadence/amplitude liées à vitesse, hanches et poids ; sprint nettement distinct de course par corps/accélération/caméra bornée, pas WalkSpeed/FOV seuls.

## MOV-003 — Vraie course latérale et changement de direction

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Vraie course latérale et changement de direction
- sources: [LOCOMOTION](../archive/movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
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
- sources: [LOCOMOTION](../archive/movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Pied→hanche→torse→épaule→membre, anticipation/contact/followthrough/recovery ; aucun cut/run→attaque→run ; comparaison native avant/après
- evidence: Animation/renderer/IK existent, aucune acceptation native actuelle 2026-10-16 : outil de chronophotographie Studio (poses de 6–9 instants côte à côte, distances par image) ; premier usage sur la chaîne de Minato ([rapport](../archive/reports/convergence/CONTACT_AND_REACTIONS.md)) 2026-10-16 : poursuite en bond vertical après un lanceur, clips recalés sur le temps serveur, entrée des coups enchaînés adoucie et coups tournants bras serrés (pire saut de main par chaîne : Sasuke 3,1→1,8, Minato 2,9→2,1 studs/image) ; familles de mouvement pour les nouveaux combattants 2026-10-16 soir : poses d’identité (glissade du Read, retrait du Mirage, contres glissés, posture tenketsu, Curse Mark, freinage de fin de dash, arrivée aérienne Yellow Flash) ; attaques aériennes martelées qui faisaient planer au ras du sol corrigées (`885fdbc`, Regression.spec)
- outcome: PENDING

## MOV-005 — Transitions air, landing et mur cohérentes

- status: IN_PROGRESS
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: movement
- character: CORE4
- summary: Transitions air, landing et mur cohérentes
- sources: [LOCOMOTION](../archive/movement/LOCOMOTION.md); [CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Impulsion, ascension/apogée/chute, appui mur, rebond, poursuite, récupération et corps lisibles sans snap ; comparaison native avant/après
- evidence: 2026-10-16 NATIVE_STUDIO (debug, mesuré) : saut debout 19,6 studs/0,53 s → 16,4/0,94 s ; saut en course vitesse à l’atterrissage 36→14 avant, 36→19 après ; saut sprint 69→20 avant, 69→50 après. TECHNICAL PASS (Regression). Silhouette ([audit visuel](../archive/reports/convergence/VISUAL_AUDIT.md)) : bond en ciseaux dès la vitesse de course (avant : seulement au-delà de ~30 studs/s), sauts latéral et arrière lisibles, réception en course sans arrêt-accroupi (le bassin absorbe, la foulée continue). Anticipation encore absente. HUMAN_VISUAL PENDING
- outcome: PENDING
- acceptance: Saut neutre/avec élan/sprint, air control et momentum conservés, approche mur/rebond/mantle/detach, réception faible/grande hauteur et reprise sans pause ; comparer avant/après natif.

## MOV-006 — Évaluer prediction si preuves de latence la justifient

- status: OPEN
- priority: P2
- dependencies: NET-001
- subsystem: network
- character: ALL
- summary: Évaluer prediction si preuves de latence la justifient
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Mesure avant/après réseau réelle, autorité/hit validation conservées ; activation après décision PvP
- evidence: 2026-10-16 DEC-012 : prédiction « là où c’est approprié » demandée par la mission ; à décider après mesures 0 / ~60 / ~100–120 ms et gigue sur le PvP réel (NET-001)
- outcome: PENDING

## COM-001 — Grammaire directionnelle et routes techniques existantes

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: combat
- character: CORE4
- summary: Grammaire directionnelle et routes techniques existantes
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Branches ground/air/launcher/chase/slam/throw/side swap/wall bornées
- evidence: Branches/Sequences/Sasuke/Preparation PASS 2026-10-16 soir (CCC2) : modèle de combo à coups confirmés et mémoire directionnelle fusionné (`c4f0466`) ; NATIVE_STUDIO : coup dans le vide puis pression = Light1, L, L, vers relâché + L = Launcher, côté + L = AngleStep (`tools/studio/probes/staged_moment.luau`)
- outcome: VERIFIED_TECHNICAL

## COM-002 — Taijutsu riche et expressif

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Taijutsu riche et expressif
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Jab/cross/hook/uppercut/elbow/knee/kicks/sweep/spin/projection, formes adaptées au jeune personnage ; pas ajouter un bouton par brique ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; qualité et variété restent ouvertes
- outcome: PENDING
- acceptance: Boucle distance → lecture/feinte/outil → défense/angle → contact → route → décision du défenseur → conversion air/mur → retour neutral ; observer 60–90 s de jeu continu.

## COM-003 — Synchroniser corps, contact, cible et réaction

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Synchroniser corps, contact, cible et réaction
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Moment d’impact coïncide visuellement avec hitbox/réaction ; zone touchée cohérente ; VFX ne masque pas défaut ; preuve native
- evidence: Mécanismes Combat/Brawler/MoveGraphs partiels ; 2026-10-16 : le recul redémarre à chaque nouveau contact même si le type de réaction se répète (Light1→Light2, Air1→Air2) et le début de frappe part en snapshot urgent (plus d’impact qui précède l’animation). Constat non corrigé : un coup qui ne pose que Stunned (kunai, shuriken, hazard) n’a pas de pose de recul. TECHNICAL compile + suites PASS ; NATIVE_STUDIO et HUMAN_VISUAL PENDING 2026-10-16 NATIVE_STUDIO ([contact et réactions](../archive/reports/convergence/CONTACT_AND_REACTIONS.md), chronophotographie) : les corps se chevauchaient pendant les chaînes (avancée stoppée à 2,6 studs, recul d’un coup léger ~0,5 stud ; têtes à 1,4) → distance de contact par frappe (3,6 poings, 4,0 pieds), boîte de touche des coups légers alignée, recul léger ~0,9 stud ; même scénario : bassins 3,0 → 3,65, têtes 1,44 → 2,04, 3/3 coups touchés. Réactions debout lisibles (plancher de force, flexion/hanches/tête). TECHNICAL PASS (Regression 25). HUMAN_VISUAL PENDING
- outcome: PENDING
- acceptance: Appui → hanche → torse → membre → impact → réaction → recovery ; pas de corps imbriqués, glissade ou root déplacé sous un corps figé ; observation en mouvement, pas particules masquantes.

## COM-004 — Conversions air/mur et branches libres

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Conversions air/mur et branches libres
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Réaction→poursuite→conversion, drive/spike/side switch/wallpin/bounce/tech ; choisir poursuivre ou sortir ; whiff puni ; preuve native
- evidence: 2026-10-16 NATIVE_STUDIO : Motor.move intégré une seule fois quand le solveur Studio est actif (f895158) — rush scripté : sauts du corps 1,1 % jusqu’à 3–4 studs → 0,4 % ; Regression +1. Restent : à-coups de l’IA en l’air pendant ses techniques aériennes, rotations instantanées (AI.luau facing, lock au départ d’une frappe) — mesurés, non corrigés
- outcome: PENDING

## COM-005 — Transitions, cancels et décisions entre combos

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Transitions, cancels et décisions entre combos
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Feinte/outil/esquive/angle/clash/counter/disengage ; fenêtres lisibles, pas autoroutes ni infinites ni recovery gratuite ; preuve native
- evidence: Mécanismes partiels ; 2026-10-16 : chainOpen/recoveryCancelAt ne fuient plus (f93d866). Mission 2026-10-16 : construire une vraie couche de neutral (approche, retraite, repositionnement latéral, feinte, sonde, outil, pression projectile, garde, parade, esquive, perfect dodge, contre, substitution, clash, reset) avec des phases et des échanges courts 2026-10-16 soir : réengagement unique (poursuite dans une fenêtre, dash chakra hors fenêtre) ; NATIVE_STUDIO : arrivée à 3,0 studs pour les quatre après correction du glissement post-arrivée (`6b98e28`, Regression.spec), probe `reengage.luau`
- outcome: PENDING
- acceptance: Premier hit confirmé ouvre la chaîne ; whiff/buffer ne consomme pas un pas ; double tap, intention directionnelle tardive/relâchée, rotation caméra, poursuite, cancel, substitution et garde brisée sans état fantôme.

## COM-006 — Grabs et micro-conflits physiques

- status: PARTIAL
- priority: P1
- dependencies: QA-001, MOV-001
- subsystem: combat
- character: CORE4
- summary: Grabs et micro-conflits physiques
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
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
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
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
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
- validation: Coûts/fenêtres/récupérations et décisions serveur bornés
- evidence: Rules/Combat/Phase4/Regression PASS ; 2026-10-16 audit : garde brisée et interruption gardent leur étourdissement complet (0,65 / 0,42 s) à travers la réaction de mêlée ; la touche de garde maintenue est relevée dès que le joueur est libre, sans nouvelle fenêtre de parade. Constats non corrigés : le gap anti-cheat Dodge (0,42 s) dépasse la fenêtre de wall tech (≈0,29 s) ; la fenêtre de perfect dodge d’Itachi éveillé ne peut dépasser les i-frames
- outcome: VERIFIED_TECHNICAL

## DEF-002 — Substitution à ressources et contre-jeu

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: defense
- character: CORE4
- summary: Substitution à ressources et contre-jeu
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
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
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Arme ou membre agit visiblement ; récupération et riposte perceptibles
- evidence: Défense technique existe ; 2026-10-16 : une parade contre lame, flamme, hazard ou Rotation ne fait plus qu’annuler le coup (« deflect ») au lieu d’étourdir le lanceur à distance ; seul un coup de corps reste puni. TECHNICAL PASS (Regression) ; expressivité NATIVE_STUDIO et HUMAN_VISUAL PENDING
- outcome: PENDING

## DEF-004 — Clash de frappes technique

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: defense
- character: CORE4
- summary: Clash de frappes technique
- sources: [COMBAT_REQUIREMENTS](../archive/combat/COMBAT_REQUIREMENTS.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH](../archive/missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md); [CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md)
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
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md)
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
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Draw/grip/release, throw pendant run/air/dodge, retour contact et conversion distincts par personnage
- evidence: Tools et routes existent ; 2026-10-16 : un lancer (outil ou kunai marqué) depuis la garde la baisse — plus de lancer en garde pleine ni de « fausse garde » ; la garde revient après le lancer si la touche est tenue. TECHNICAL PASS ; transitions corporelles NATIVE_STUDIO PENDING
- outcome: PENDING

## TOOL-006 — Prototype ciblé objet + chakra + déclencheur → résultat

- status: PARTIAL
- priority: P2
- dependencies: QA-001, SYS-001
- subsystem: chakra
- character: CORE4
- summary: Prototype ciblé objet + chakra + déclencheur → résultat
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Au moins interaction concrète lisible/contre-jeu avant abstraction ; infusion propriété/nature testée
- evidence: ChakraCombat/ChakraTuning intégrés ; 738b449 ajoute fil-objet, conduction métal et feedback des objets. Rapport convergence3/CHAKRA_PLAYER_LAYER : headless uniquement ; tailles, lisibilité, cadence et interactions réelles restent à vérifier dans Studio.
- outcome: PENDING

## SYS-001 — Faire du chakra une décision contextuelle

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: chakra
- character: CORE4
- summary: Faire du chakra une décision contextuelle
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Coût, recharge, infusion, déclencheur, opportunité et contre-jeu mesurés ; éviter barre cosmétique
- evidence: Ressources et jutsu présents ; 2026-10-16 mission : chakra systémique `Objet + Propriété/Nature + Contexte → Résultat`, infrastructure générique d’abord (kunai/shuriken renforcés, vent coupant, foudre conduite par fil/métal, feu sur pièges/zones préparées, kunai marqué ancre FTG, collision/déviation de projectiles, projectile planté devenant point tactique) sans bouton par interaction. Fondations Codex à auditer (`7091585`) 2026-10-16 soir : chakra systémique sur l’outil (Z + R / R1 + R2), maîtrise par combattant, collisions par règles de données (`4ec179c`, Chakra.spec 17) ; kunai de vent vu en Studio. PARTIAL : brûlures, fil, points plantés et collisions non observés en natif
- outcome: PENDING
- acceptance: Chakra + action existante ; changer un comportement (trajectoire, stabilité, garde, conduction, brûlure, persistance ou ancrage), pas seulement dégâts. Contrôler fil tenu/planté, courant puis Dragon Flame, rencontres de projectiles, lisibilité et nettoyage.

## SYS-002 — Interactions élémentaires/environnement ciblées

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: elements
- character: CORE4
- summary: Interactions élémentaires/environnement ciblées
- sources: [TOOLS_AND_CHAKRA](../archive/systems/TOOLS_AND_CHAKRA.md); [SYSTEM_INTERACTION_MATRIX](../archive/design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md); [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Deux modifications de règles compréhensibles proposées/testées par kit ; labels lore ; pas boost statistique seul
- evidence: 17/10 Codex : [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). Haku/Shisui/Deidara/Nagato ont des éveils exclusivement numériques ; Kimimaro a Heavy/Armor mais Camellia peut les masquer. Clôturer bug de composition au premier bloc combat ; définir les règles manquantes au bloc identité de DEC-021.
- outcome: PENDING
- acceptance: Chaque éveil change au moins une règle/route/ressource/défense avec coût et contre-jeu visibles ; pas simple multiplicateur.

## CHR-MIN-001 — Marques FTG et angles techniques

- status: DONE
- priority: P1
- dependencies: DOC-001
- subsystem: character
- character: Minato
- summary: Marques FTG et angles techniques
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
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
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Entrée/sortie main/FTG visibles ; rapidité corporelle lisible, pas costume Hokage ; preuve native/lore pertinente
- evidence: Code et profils existent ; 2026-10-16 fiche : signature « géométrie préparée » (jusqu’à 4 destinations : 2 sceaux plantés 12 s, 1 corporel, 1 kunai en vol) ; candidat P1 recadrage jeune des noms/visuels (décision utilisateur requise). Anomalie à vérifier : clip Flashstep.Heavy construit sur la stance d’Itachi ; hint MarkedBlade « Two seals planted at once » corrigé le 2026-10-16 (« Plants a seal (two held at most) »). NATIVE_STUDIO PENDING
- outcome: PENDING

## CHR-MIN-003 — Conversions Minato recherchées

- status: OPEN
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Minato
- summary: Conversions Minato recherchées
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Sources jeunes + angle/marque/outil/poursuite ; juger avant ajout, pas copier kit adulte ; preuve native/lore pertinente
- evidence: 2026-10-16 fiche : candidats P4 déviation au kunai revers et P5 sortie après poursuite FTG aérienne, non implémentés (à juger en natif avant ajout)
- outcome: PENDING

## CHR-ITA-002 — Calme, tromperie, geometry et feu

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Itachi
- summary: Calme, tromperie, geometry et feu
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Lecture, précision, feintes et lanes distinctes, pas spam jutsu ni costume Akatsuki ; preuve native/lore pertinente
- evidence: Code et profils existent ; 2026-10-16 fiche : signature = l’action adverse devient l’ouverture (Geometry jugée depuis le flanc, Read, punition du whiff sous Mirage, ricochet) ; manques : CounterPalm « vers un mur » annoncé dans MoveGraphs mais non codé, Fireball/Phoenix quasi identiques à ceux de Sasuke, éveil numérique. Décision âge 13 → 12 requise. NATIVE_STUDIO PENDING
- outcome: PENDING

## CHR-NEJ-002 — Personnaliser les clips hérités air/throws

- status: OPEN
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Neji
- summary: Personnaliser les clips hérités air/throws
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Héritage Mirage préservé adapter ; juger paumes/rotation/pression/précision et créer variante seulement si insuffisant ; preuve native/lore pertinente
- evidence: Code et profils existent ; 2026-10-16 fiche : 7 clips hérités d’Itachi confirmés (Air1, Air2, Slam, Grab, Throw, ThrowUp, WallDive) ; PalmThrust occupe les emplacements du CounterPalm d’Itachi et CircleStep laisse une image rémanente comme FeintStep ; signature drain chakra/tenketsu + 64 Paumes scellant les techniques 3,5 s. Vacuum Palm labellisée PLAUSIBLE_YOUNG provisoire (apparition Partie 1 contre Kidōmaru à vérifier). NATIVE_STUDIO PENDING
- outcome: PENDING

## CHR-SAS-002 — Agressivité jeune et transitions mix-range

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: Sasuke
- summary: Agressivité jeune et transitions mix-range
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Lion/Flashstep hérités évalués, kicks/fil/projection/poursuite/recovery distincts et lisibles ; preuve native/lore pertinente
- evidence: Code et profils existent ; 2026-10-16 fiche : signature LionKick → ShadowLeaf (chasse gratuite) → Lion Combo, fil → Dragon Flame, Chidori 34 chakra ; manques : Heavy après 2 coups lance le Launcher générique sans ShadowLeaf, counterUntil du Sharingan sans readCounter, aucune interaction murale propre (la matrice annonce Chidori/wire au mur, absent du code), Curse Mark purement numérique. NATIVE_STUDIO PENDING
- outcome: PENDING

## CHR-CORE-001 — Quatre identités reconnaissables sans jutsu

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: ALL
- summary: Quatre identités reconnaissables sans jutsu
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Mouvement, garde, distance, rythme, outil, conversions distinguent quatre en duel ; preuve native/lore pertinente
- evidence: 17/10 Codex : [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). Hors jutsu beaucoup de clips/graphes hérités ; Zabuza arme au dos, Sasori sans corps distant, Deidara sans détonation liée, Nagato absorption abstraite. Passe de signatures après le bloc combat selon DEC-021 ; pas vingt refontes en parallèle.
- outcome: PENDING
- acceptance: Minato : marques/angles/chaînes FTG ; Itachi : lecture/leurre/shuriken/feu ; Neji : paumes/tenketsu/Rotation ; Sasuke : kicks/air/fil/Chidori/risque maudit. Vérifier quatre couches : règle, corps, feedback et conséquence de route.

## CHR-CORE-002 — Revue lore par capacité

- status: PARTIAL
- priority: P1
- dependencies: QA-001, RES-001
- subsystem: character
- character: CORE4
- summary: Revue lore par capacité
- sources: [CORE_ROSTER](../characters/CORE_ROSTER.md); [ROSTER_MOVESETS_10_PRODIGIES](../characters/ROSTER_MOVESETS_10_PRODIGIES.md); [CLAUDE_PHASE_3_YOUTH_TOURNAMENT](../archive/missions/CLAUDE_PHASE_3_YOUTH_TOURNAMENT.md); [README](../research/README.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Chaque proposition/kit documente label canonical jeune/plausible/liberté/rejet adulte avec source exacte ; preuve native/lore pertinente
- evidence: 2026-10-16 : table « Labels lore par capacité » posée pour chaque capacité réelle des quatre kits (fiches personnage), sources canon citées ou marquées « à vérifier ». Aucun pouvoir de Partie 2 / Mangekyō dans src. Écarts code ↔ DEC-005 à trancher par l’utilisateur : noms/visuels adultes de Minato (« Flying Thunder God », kunai à trois branches, éveil « YELLOW FLASH », Rasengan / FlashRasengan / RasenganDrop = REJECT_ADULT_ONLY en l’état) ; Itachi `Age = 13` (âge du Mangekyō) et imagerie corbeaux ; Curse Mark niveau 2 non présent (exclusion à confirmer). Statut PARTIAL tant que ces décisions et la vérification des sources ne sont pas faites
- outcome: PENDING

## CHR-EXT-001 — Gaara — finir la validation du kit sélectionnable

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: roster
- character: Gaara
- summary: Gaara : validation native complète du kit déjà sélectionnable
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Sélection et duel Studio en mouvement : fouets, pilier, bouclier, capture, projectiles, défense, relance, éveil ; aucune représentation de kunai de repli ; garder les limites de qualité visibles.
- evidence: Serveur + 10 tests existent ; 2026-10-16 DEC-012 : Gaara fait partie de la première vague d’archétypes à rendre jouable pour éprouver le moteur (zoning défensif / sable) 2026-10-16 (DEC-015) : Gaara sélectionnable des deux côtés (`545bc3d`) avec sa propre famille de mouvement (bras croisés, pas courts sans course ninja, fouets de sable lancés de la main, pilier paume levée, aucune arme en main) au lieu des visuels de Minato ; vu en Studio (menu, chaîne de fouets). PARTIAL : pas encore d’effet de sable sur les fouets ni d’acceptation humaine 2026-10-16 soir : couche client SandFX (`4dbccbe`, `15008c9`) — les projectiles de sable n’étaient plus des kunai, bouclier/flicker/cercueil/mur du Désert/fouets/pilier/charges dessinés ; vu en Studio sur images figées. PARTIAL : pas d’acceptation humaine en mouvement
- outcome: PENDING

## CHR-EXT-002 — 20 personnages — breadth-first Tier A, puis Tier B/C

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: roster
- character: ROSTER20
- summary: 20 personnages jouables en breadth-first, puis identité et polish par vagues
- sources: [Décision roster](DECISIONS.md#dec-016--20-jouables-breadth-first) ; [texte utilisateur archivé](../archive/missions/ROSTER_20_BREADTH_PASS.md)
- validation: Tier A pour chacun des 20 : sélection dans le build, stance/locomotion, chaîne légère, lourd, route directionnelle, route air ou alternative justifiée, outil, 2–3 jutsu, défense, relance pertinente, éveil qui change une règle, IA basique, aucun placeholder cassé. Chaque kit joué dans Studio avec au moins un matchup IA. Tier B ensuite : 2–3 mécaniques identitaires, rythme, signature, éveil et feedback lisibles. Tier C : animation/VFX/audio/caméra/balance/online par familles. Réutiliser les familles ; pas vingt clones ni extension au-delà de 20. Tenir ici le tableau des 20, famille, particularités, état Tier A/B et preuves natives.
- evidence: 17/10 Codex de33f3d : vingt entrées câblées, breadth pass terminé ; [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). Nouveaux : 2PASS/8WEAK/0BROKEN au sens fondation V1. Contrat Tier A non entièrement clos (quatre éveils numériques, états/portées, native final incomplet). Arrêt des ajouts selon DEC-021, convergence combat sur20 ; détails de kits dans ROSTER_20 comme référence spécialisée.
- outcome: PENDING

## ARENA-001 — Échelle utile et exploitation murs/cover

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: arena
- character: CORE4
- summary: Échelle utile et exploitation murs/cover
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Course/range/time de réentrée, fil/teleport/projectiles, wallcarry/pin/bounce et tech utiles ; native avant/après
- evidence: Mécanismes existent ; 2026-10-16 DEC-012 : la mission autorise la refonte/mise à l’échelle de l’arène (fighters petits face au décor ; neutral long, sprint, pression d’outils, poursuite aérienne, murs utiles sans être partout) puis le retuning course/sprint/saut/projectiles/lock/caméra/IA — l’ancien tuning peut être invalidé. Observation Studio désormais possible 2026-10-16 (DEC-015) : terrasses/piliers ajoutés puis retirés sur retour utilisateur (accessoires) ; stade de l’examen Chūnin agrandi (`e54688f`) : rayon de mur 103→145 (≈58 tailles de combattant), murs 62→76, sol ouvert, grands arbres le long du mur, 5 rochers conservés (couverture/splat), balcon des participants devenu une vraie corniche. Vu en Studio (vue d’ensemble, caméra de jeu, opposition à 90 studs). L’IA n’utilise pas encore murs/corniche dans ce stade plus grand
- outcome: PENDING
- acceptance: Vrai stade Chūnin agrandi et reconnaissable, sol large, hauts murs, tribunes/corniches et lignes de poursuite ; obstacle seulement pour couverture/angle/route/splat. Ne pas réintroduire accessoires arbitraires.

## ARENA-002 — Tournoi jeune et présentation légère

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: presentation
- character: CORE4
- summary: Tournoi jeune et présentation légère
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
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
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md); [LIVE_AUTONOMY_ADDENDUM](../archive/missions/LIVE_AUTONOMY_ADDENDUM.md)
- validation: Bornes, heights/LOS/angles/obstacles influencent combat sans bloquer mouvements ; native avant/après
- evidence: Mécanismes existent ; acceptation humaine finale absente. 2026-10-16 : non modifié (observation native requise avant changement) ; à reprendre après QA-001
- outcome: PENDING

## CAM-001 — Continuité camera et swap

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: camera
- character: CORE4
- summary: Continuité camera et swap
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Lock/free, fade, zoom, sideswap, téléport/throw/air/wall sans snap gênant ; native avant/après
- evidence: Mécanismes existent ; 2026-10-16 : basculer le verrouillage convertit le yaw (plus de bascule vers le nord du monde ni de décalage au re-verrouillage) ; la secousse s’applique après le lissage (avant : ~17 % survivait et restait incrustée) ; plus de secousse pendant le drain de la marque maudite. TECHNICAL compile PASS ; NATIVE_STUDIO PENDING
- outcome: PENDING

## CAM-002 — Confort haute vitesse et verticalité

- status: IN_PROGRESS
- priority: P1
- dependencies: QA-001
- subsystem: camera
- character: CORE4
- summary: Confort haute vitesse et verticalité
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Quatre personnages, caméra en poursuite et manette, ne masque pas appuis/contact ; native avant/après
- evidence: 2026-10-14 FOV/boom/lead pilotés par le sprint du joueur ; 2026-10-16 NATIVE_STUDIO : secousse continue amortie (au lieu d’un décalage aléatoire par image) → images avec saut de caméra en combat IA 7,8 % → 0,3–0,5 % (ancienne base 1,8–4,5 %). HUMAN_VISUAL PENDING
- outcome: PENDING

## FX-001 — Audio d’impact et feedback

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: audio
- character: CORE4
- summary: Audio d’impact et feedback
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md)
- validation: Contacts, parry/tool/wall/steps lisibles, pas effets pour cacher corps insuffisant ; native avant/après
- evidence: Mécanismes existent ; 2026-10-16 : un seul son par contact (le son serveur répliqué est retiré) ; seuls les styles de contact jouent un son de coup — cast, chase, fade, stick, afterimage n’en jouent plus, dodge/substitution/wall tech sonnent « air » ; une lame esquivée/parée/absorbée finit en silence. TECHNICAL compile + suites PASS ; écoute NATIVE_STUDIO PENDING 2026-10-16 soir : chaque son laissait un cube noir visible de 0,2 stud pour le reste du duel (ancre `anchorPart`) ; ancres invisibles et supprimées avec leur son (`15008c9`)
- outcome: PENDING

## FX-002 — Réactions par zones et usure corporelle

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: reactions
- character: CORE4
- summary: Réactions par zones et usure corporelle
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Hit bodyzone, déséquilibre, réception, knockdown/KO et recovery, usure non gênante ; native avant/après
- evidence: Mécanismes existent ; 2026-10-16 : l’usure se réinitialise quand un nouveau round rend la vie pleine (avant : round 2 démarrait usé au maximum, sans progression possible) ; le drain de la marque maudite ne crée plus de burst « -0 » à chaque snapshot. TECHNICAL compile PASS ; NATIVE_STUDIO PENDING
- outcome: PENDING

## UX-001 — Grammaire simple, tutoriel et choix contextuels

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: inputs
- character: CORE4
- summary: Grammaire simple, tutoriel et choix contextuels
- sources: [ARENA_CAMERA_PRESENTATION](../archive/systems/ARENA_CAMERA_PRESENTATION.md); [CLAUDE_FINAL_TODAY_POLISH](../archive/missions/CLAUDE_FINAL_TODAY_POLISH.md); [CLAUDE_45MIN_FINAL_PLAYABLE_PASS](../archive/missions/CLAUDE_45MIN_FINAL_PLAYABLE_PASS.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md); [CORE_COMBAT_CONVERGENCE_2](../archive/missions/CORE_COMBAT_CONVERGENCE_2.md)
- validation: Toutes routes apprenables et cohérentes keyboard/manette, aucun input conflict ; native avant/après
- evidence: Mécanismes existent ; 2026-10-16 : à la manette, les cues affichées traduisent les touches clavier en boutons (E → ×, SPACE → ×, C → R1 + L1, X → D-pad →, 1 → R1 + ×, labels issus de Controls) ; les cues WIRED/BOUND (comment s’échapper du fil/sable, utiliser Dragon Flame) sont désormais affichées. TECHNICAL PASS (Regression) ; NATIVE_STUDIO PENDING 2026-10-16 soir : l’étape « interrompre le jutsu » du tutoriel montre au moins 0,75 s de signes quel que soit l’adversaire (`e0abc32`)
- outcome: PENDING

## UX-002 — Mobile, rebinding et accessibilité

- status: OPEN
- priority: P2
- dependencies: QA-005
- subsystem: inputs
- character: ALL
- summary: Mobile, rebinding et accessibilité
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Prototype/contrôle plate-forme explicite sans overlay debug ; conserver simplicité
- evidence: Pas de validation cross-platform ; ancienne roadmap candidate
- outcome: PENDING

## NET-001 — Online — flow réel Roblox et duel serveur

- status: IN_PROGRESS
- priority: P0
- dependencies: QA-001
- subsystem: network
- character: ALL
- summary: Boucle de duel réellement publiée Roblox
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Après étape Studio à deux clients et latence mesurée : rejoindre une expérience Roblox publiée, trouver un adversaire, choisir, disputer/terminer un duel serveur, rematch ou retour en file, quitter/rejoindre sans corrompre la session. Tester avec deux comptes/clients sur Roblox réel ; consigner PlaceID, version, commit, hash, conditions réseau et résultat. Deux clients Studio seuls ne clôturent pas le produit online.
- evidence: 2026-10-16 DEC-012 : périmètre ouvert par la mission utilisateur (vrai 1v1 joueur contre joueur, autorité serveur, réactivité client, prédiction si utile, réconciliation, validation tenant compte de la latence, projectiles/substitution/FTG/air/mur/clash sous latence, sync chakra/état). Auditer d’abord les fondations Codex (`33028b2` : OnlineHost/Match/Queue/Validation/Replication) avant de reconstruire. 2026-10-16 fondation livrée ([rapport](../archive/reports/ONLINE_FOUNDATION.md), merge `560d059`) : file casual, duel privé par code, choix en face à face, deux humains dans le même moteur serveur, validation par joueur (anti-triche, débit, visée), forfait à la déconnexion, outil de latence Debug seulement ; prédiction client volontairement écartée avant mesure. TECHNICAL PASS (Online 17 cas, isolation). NATIVE_STUDIO PENDING : session deux clients et matrice 0 / ~60 / ~100–120 ms + gigue
- outcome: PENDING

## NET-002 — Robustesse réseau et entrées hostiles

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: network
- character: ALL
- summary: Robustesse réseau et entrées hostiles
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Charge/latence réelle, finite/borne/rate limits et déconnexions ; pas transfert de confiance client
- evidence: Validation serveur/anti-cheat/rate limit existants ; profil réel à compléter
- outcome: PENDING
- acceptance: Vérifier autorité/borne/rate limits par joueur, latence/gigue, départ pendant choix/duel/résultat et retour en file ; ne pas inférer la sécurité/persistance à partir du seul harness.

## PERF-001 — Mesurer parts, cadence, rematches et multi-lanes

- status: OPEN
- priority: P2
- dependencies: QA-001
- subsystem: performance
- character: ALL
- summary: Mesurer parts, cadence, rematches et multi-lanes
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)
- validation: Mesures exactes device,10rematches/cleanup ; spectateurs/30players seulement si scope activé, pas promesse
- evidence: Ancien plan chiffre1300parts et lanes ; budget réel non mesuré
- outcome: PENDING
- acceptance: Mesurer coût des clones/copies, snapshots et multi-lanes sur appareils réels ; harness corrigé dans la passe Temari (Move cumulé, ancien biais 3,3×) : rejouer les simulations comparatives sur le nouveau harness, ne pas réutiliser les anciennes statistiques comme mesures équivalentes.

## BAL-001 — Balance humain et durée sans inflation HP

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: balance
- character: ALL
- summary: Balance humain et durée sans inflation HP
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Seeds/sim distinctes des duels humains ; diversité routes/defense, pas augmenter HP pour masquer manque de décisions
- evidence: 17/10 Codex : [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). HP400 du pilote sert uniquement à éviter le KO pendant la capture ; aucune conclusion de balance. Mesurer létalité/neutral à HP produit après corrections, adversaire mobile/garde et matchups réciproques ; pas inflation HP comme cache-misère.
- outcome: PENDING

## AI-001 — IA comprend les conversions tactiques utiles

- status: PARTIAL
- priority: P2
- dependencies: QA-001
- subsystem: ai
- character: ALL
- summary: IA comprend les conversions tactiques utiles
- sources: [FUTURE_SYSTEMS](../archive/systems/FUTURE_SYSTEMS.md); [ROADMAP_WEEK](../archive/plans/ROADMAP_WEEK.md); [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md); [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Mesurer planification wall/seal/angle/outil et sorties sans triche ni spam
- evidence: 17/10 Codex : [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). Ring headless20 matchups voisins PASS ; aucune preuve exhaustive des synergies. Prévoir matchups réciproques miroirs/brume/poison/buffs/counter, ancien clones/vent ; lenteur Sasori vs Lee90s signalée par Claude à reproduire.
- outcome: PENDING
- acceptance: Éprouver murs, hauteur, outils/chakra, corps secondaires, identité, éveil et disengage dans des matchs variés ; aucun accès injustifié aux intentions du joueur.

## REL-001 — Alpha publique Roblox — gates minimum, sans attendre le polish final

- status: OPEN
- priority: P1
- dependencies: CHR-EXT-002, NET-001
- subsystem: release
- character: ALL
- summary: Alpha publique Roblox dès le roster baseline et le combat online suffisamment jouables
- sources: [Décision alpha](DECISIONS.md#dec-018--alpha-publique-et-online-réel) ; [demande archivée](../archive/missions/PUBLIC_ALPHA_AFTER_ROSTER_20.md)
- validation: 20 baseline réellement jouables ; flow NET-001 ; pas de crash/verrouillage courant de session ; autorité serveur et déconnexion/forfait ; persistance non destructive ou désactivée ; canal simple de bugs/feedback ; télémétrie pratique (choix, durée/résultat, abandon, rematch, erreurs) ; permissions/auth réelles et PlaceID/version/commit/hash consignés. Ni VFX premium, ni balance finale, ni progression complète, ni monétisation requis. Passage privé/test publié puis public : pas de dépendance circulaire NET-001/REL-001.
- evidence: Au HEAD 04d6eb0 : direction alpha autorisée, publication et identifiants non prouvés. Cet audit ne publie rien.
- outcome: PENDING

## RES-001 — Banques de mouvement source → mécanique → variante

- status: PARTIAL
- priority: P1
- dependencies: RES-002
- subsystem: research
- character: CORE4
- summary: Banques de mouvement source → mécanique → variante
- sources: [SOURCE_REGISTER](../research/SOURCE_REGISTER.md); [MOVEMENT_SOURCE_PIPELINE](../archive/design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md); [CLAUDE_DESIGN_LIBRARY_WORKFLOW](../archive/missions/CLAUDE_DESIGN_LIBRARY_WORKFLOW.md)
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
- sources: [SOURCE_REGISTER](../research/SOURCE_REGISTER.md); [MOVEMENT_SOURCE_PIPELINE](../archive/design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md); [CLAUDE_DESIGN_LIBRARY_WORKFLOW](../archive/missions/CLAUDE_DESIGN_LIBRARY_WORKFLOW.md)
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
- sources: [SOURCE_REGISTER](../research/SOURCE_REGISTER.md); [MOVEMENT_SOURCE_PIPELINE](../archive/design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md); [CLAUDE_DESIGN_LIBRARY_WORKFLOW](../archive/missions/CLAUDE_DESIGN_LIBRARY_WORKFLOW.md)
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
- evidence: Export inert ; aucune motion remplacée pendant préparation 2026-10-16 : outils de dev Studio de Codex (`33028b2`/`7091585`) portés en Debug/QA (merge `9766017`, [DEVTOOLS](../tools/DEVTOOLS.md)) ; auto-test natif 9/9 PASS en Studio
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
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
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
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
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
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
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
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
- validation: Checker +9tests et isolation, sources/artifacts plugins inchangés
- evidence: check_architecture.py PASS ; Motion Lab unidirectionnel
- outcome: VERIFIED_TECHNICAL

## ARC-002 — Architecture roster — hooks démontrés, pas de branches par nom en cascade

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: architecture
- character: ALL
- summary: Hooks et familles pilotés par les besoins des 20 fighters
- sources: [PROJECT_STRUCTURE](../tools/PROJECT_STRUCTURE.md); [MAINTENANCE_BACKLOG_SOURCE](../archive/tools/MAINTENANCE_BACKLOG_SOURCE.md); [ORCHESTRATION_REFACTOR](../archive/reports/ORCHESTRATION_REFACTOR.md)
- validation: Quand plusieurs fighters forcent les mêmes conditionnels centraux, extraire le besoin démontré en hook/trait/module neutre (hit, défense, outil, route, éveil, mouvement, ressource, projectile, présentation). Préserver contrats et autorité serveur ; aucune réécriture générique anticipée ; vérifier cleanup et snapshots des corps secondaires.
- evidence: 17/10 Codex : [audit roster20](../archive/audits/2026-10-17-roster20/AUDIT.md). Les trois lots réutilisent familles et hooks sans cascade de noms dans le cœur. Risques démontrés : état persistant, priorité buff/éveil/OnHit, portée Teleport. Corriger ces contrats localement et protéger anciens consommateurs ; aucune justification de refonte globale.
- outcome: PENDING

## PROG-001 — Arbres et maîtrises — préparer la phase suivante

- status: PARTIAL
- priority: P1
- dependencies: QA-001
- subsystem: progression
- character: ALL
- summary: Arbres par personnage et maîtrises par pratique — architecture préparatoire
- sources: [DEC-024](DECISIONS.md#dec-024--progression-double-et-tournoi-standardisé) ; [Proposition à valider](../systems/PROGRESSION_MASTERY_PROPOSAL.md) ; [demande intégrale](../archive/requests/2026-10-17-progression-mastery-architecture.md) ; [fondation historique](../archive/reports/PROGRESSION_FOUNDATION.md)
- validation: Après validation produit et au bon moment de DEC-021 : identité niveau1 complète, compilation serveur bornée, acquisition/performance séparées, maîtrises qualifiées non spammables et non achetables, profils versionnés migrés sans perte. Trois pilotes Lee/Minato/Temari avant extension aux vingt ; Studio obligatoire. Le livrable architecture seul ne clôt pas le système.
- evidence: Audit Codex b3f8ffb (17/10) : 75 nodes CORE4/35 majeurs/10 stat, validation SkillBuilds et profils V1 réutilisables ; pas de mastery acquise ni host de persistance. Proposition spécialisée livrée (modèle, politiques, risques, trois mini-arbres et étapes), non approuvée. tests/run.sh tenté mais Luau/Lune absents ; aucun nouveau PASS gameplay ni Studio.
- outcome: PENDING
- acceptance: Priorité Claude inchangée : roster V1 et séquence DEC-021. Aucune implémentation autorisée par la proposition. Les chiffres historiques de branche/arbre ne fixent pas le nouveau produit ; pas de remplacement du kit de base par des nodes.

## PROG-002 — Tournoi — budget standard, droits et maîtrises à arbitrer

- status: PARTIAL
- priority: P2
- dependencies: PROG-001, NET-001
- subsystem: progression
- character: ALL
- summary: Budgets de points de compétence actifs en classé
- sources: [DEC-024](DECISIONS.md#dec-024--progression-double-et-tournoi-standardisé) ; [proposition T1/P2](../systems/PROGRESSION_MASTERY_PROPOSAL.md#tournoi-standardisé)
- validation: Même arbre, fighter possédé vérifié serveur, budget temporaire identique, presets tournoi distincts des droits permanents, snapshot verrouillé et aucune puissance payée. Avant code, USER DECISION REQUIRED T1 : catalogue de nodes et conditions de maîtrise prêtés ou gating de pratique conservé ; P2 : budget/format du lancement. Puis flow réel Online/Roblox selon NET-001.
- evidence: SkillBuilds.admit sait valider un budget et les unlocked, mais Online:fight passe aucun kit et ne vérifie pas le roster possédé. Budgets 50/80/100/150 fermé sont config existante, pas nouveau choix produit. Proposition de politique prêtée non validée ; tests headless historiques ne prouvent pas tournoi intégré.
- outcome: PENDING

## PROG-003 — IA à builds de budget cohérents

- status: PARTIAL
- priority: P2
- dependencies: PROG-001, AI-001
- subsystem: ai
- character: ALL
- summary: IA à builds de budget cohérents
- sources: [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md)
- validation: Profils d’IA par budget (débutant ~20–30 SP, moyen ~40–50, difficile ~60–70, boss de tournoi ~80+, légendaire proche du max) au lieu de tricher sur les stats ; utilisables comme outil d’équilibrage
- evidence: 2026-10-16 DEC-012 : ouvert par la mission 2026-10-16 (merge `5c6f3be`) : cinq paliers d’IA par fighter construits uniquement depuis l’arbre (débutant 23–27 SP, moyen 43–46, difficile 65–69, boss 88–95, légendaire 118–132), `Config.AI` inchangé ; `Matches:start(…, options)` validé côté serveur. TECHNICAL PASS. L’IA n’exploite pas encore les nœuds d’entrée pure (cancels, Air Exit)
- outcome: PENDING
