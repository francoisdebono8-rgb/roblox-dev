# État vérifié — 2026-10-12

Base technique : `bd3c483947bbf33dcc76282cf727d808c786141d`, assemblant `4bb3275` (Claude quatre personnages) et Motion Lab `89a54f9`, plus préparation/debug. Ce document décrit cette base et le refactor documentaire ; vérifier `git rev-parse HEAD` et le journal pour les suites. La branche de reprise est `codex/ninja-claude-technical-prep` ; `main` distant n’est pas cette base.

| Domaine | État | Preuve / limite |
|---|---|---|
| Menu et quatre kits | WORKING technique | `src/Client/UI.luau` : Flashstep, Mirage, GentleFist, Lion ; suites Neji/Sasuke/Tools/Preparation. Gaara serveur et 10 tests, non sélectionnable |
| Grammaire, défense, air/mur, grabs | WORKING technique / PARTIAL feel | 14 suites, 139 cas ; scripts Combat/Brawler/MoveGraphs/VelmoraDefense/Place1Parkour. Les motions existent, qualité finale à juger en Studio |
| Projectiles, maîtrise, marques FTG, fil/feu, Geometry | WORKING technique | Tools, Phase4, Systems, Sasuke ; ne signifie pas inventaire générique ni collision universelle entre outils |
| Chakra et Awake | PARTIAL | Coûts, charge, fenêtres/règles existent ; ambition d’infusion/interactions et revue lore pas achevées |
| Locomotion, contact et identité corporelle | PARTIAL | Animation/Preparation + clips/IK/interpolation existent ; course latérale, appuis, transitions et timing d’impact à revoir visuellement |
| Caméra, arène et présentation | PARTIAL | Stade, hauteur/murs, fade/lock, réactions par zones et usure existent ; confort à haute vitesse, audio et tournoi humain non acceptés |
| Match | WORKING joueur contre IA | Matches/AI : rounds, tutoriel, sélection. Aucun PvP général à deux joueurs ni prediction client validés |
| Jeu normal/debug/QA | WORKING build | Trois builds sourceEquality PASS ; 4 tests d’isolation. Le normal exclut DevHooks, CombatInspector, CombatDebug, NativeQA |
| Diagnostic opt-in | WORKING technique | inspect/trace/contracts + overlay Studio F8, lecture seule ; voir COMBAT_CONTRACTS et handoff |
| Motion Lab | WORKING automatique / PARTIAL natif | 45 cas + smoke du binaire avec événements Studio simulés ; 182 briques anciennes +120 variantes référencées ; export inert, héritage de clips préservé |
| Validation native de l’artefact final | NOT_STARTED dans ce refactor | QA-001 OPEN ; les 16 matchups historiques ne sont pas une preuve sur ce HEAD |
| Smoke/tags dédiés, infusion générique, League/Path | NOT_STARTED | La fumée de substitution et les explosions jutsu ne constituent pas ces systèmes |
| PvP, prediction, nouveau roster public | NOT_STARTED | Backlog DEFERRED ; pas de moteur réseau à reconstruire implicitement |
| Publication publique | NOT_STARTED vérifiable | Aucun PlaceID/version publique vérifiés ici ; permission/authentification actuelles non établies |
| Défauts confirmés nouveaux | BROKEN : aucun confirmé par les tests exécutés | Ne pas convertir une suspicion visuelle ou un vieux rapport en bug actuel sans reproduction |

Les états WORKING sont limités au type de preuve indiqué. Les sources de détail restent dans [l’inventaire](../current/COMBAT_INVENTORY.json), [la matrice](../FOUR_CHARACTER_COMBAT_MATRIX.md), [les contrats](../current/COMBAT_CONTRACTS.md) et [la validation préparatoire](../current/TECHNICAL_PREPARATION_VALIDATION.json). Les valeurs/timings effectifs sont dans le code ; ils ne sont pas à retuner durant ce refactor.
