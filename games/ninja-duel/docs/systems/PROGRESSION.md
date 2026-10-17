> Référence technique/recherche, non normative. État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md). Les commandes, exemples et anciens constats ci-dessous se vérifient sur le HEAD courant.

# Progression par arbres de compétences — référence données

IDs PROG-001 (arbres), PROG-002 (budgets classés), PROG-003 (IA à budget). Rapport, preuves et décisions : [PROGRESSION_FOUNDATION](../archive/reports/PROGRESSION_FOUNDATION.md). Tout est serveur ; aucun module client ne lit ces données aujourd’hui.

Règle de fond : le fighter à 0 SP est exactement le kit de [Fighters](../../src/Shared/Fighters.luau) + [MoveGraphs](../../src/Shared/MoveGraphs.luau). Un nœud approfondit une mécanique existante ; un nœud **majeur** ajoute une règle, une route ou un comportement absent du kit de base (ce que le joueur FAIT ou VOIT), jamais un simple chiffre.

## Modules

| Module | Rôle |
|---|---|
| [SkillTrees](../../src/Server/SkillTrees.luau) | Données : un arbre par fighter CORE4 (nœuds, coûts, prérequis, choix exclusifs, effets, textes Shows/Counter, label lore DEC-005) |
| [SkillBuilds](../../src/Server/SkillBuilds.luau) | Pur : validation d’un build actif, application (kit effectif), intégrité des arbres, brackets classés, admission |
| [BuildPresets](../../src/Server/BuildPresets.luau) | Données : un build d’exemple par bracket et par fighter, builds IA par palier |
| [ProfileSchema](../../src/Server/ProfileSchema.luau) | Profil versionné (SP gagnés, nœuds débloqués, builds sauvés par fighter), commandes serveur idempotentes |
| [ProfileRepository](../../src/Server/ProfileRepository.luau) | Persistance : lease exclusif, révisions clôturées, écritures idempotentes ; store mémoire (tests) et adaptateur DataStore gardé |

## Nœud

`Id` (stable, jamais recyclé : il est sauvé dans les profils), `Name`, `Branch`, `Kind` (`stat`, `property`, `route`, `airwall`, `counter`, `substitution`, `tool`, `jutsu`, `awakening`), `Major`, `Cost` (1–20 SP, prix du déblocage **et** de l’activation), `Requires` (tous), `RequiresAny` (au moins un), `Exclusive` (groupe : au plus un nœud actif du groupe), `Effects`, `Shows`, `Counter`, `Lore`.

Effet : `{chemin, op, valeur}` avec `op` = `set` | `add` | `mul`.

- `def.<champ>` : copie de la définition du fighter (ex. `def.Chakra`, `def.Awakening.Reflex`) ;
- `tech.<IdTechnique>.<champ>` : la technique de ce fighter (ex. `tech.Read.Cooldown`) ;
- `graph.<champ>` : copie du move graph (ex. `graph.stringCancels.Flashstep`).

Les effets s’empilent dans l’ordre de l’arbre (même kit quel que soit l’ordre de la liste). `SkillBuilds.apply` travaille sur des copies : `Fighters`/`MoveGraphs` ne sont jamais modifiés.

## Bornes et points d’accroche

Un champ numérique canonique n’est modifiable qu’avec une borne déclarée (`RATIO` dans SkillBuilds, ratio min–max sur la valeur de base) : santé ≤ +8 %, réserve et regen chakra ≤ +12 %, coût ≥ 75 %, cooldown ≥ 70 %, canal ≥ 70 % (et ≥ 0,04 s), actif ≤ 140 %, portée ≤ 130 % (seulement pour les techniques qui lisent `Range`). Aucune borne n’existe pour les dégâts ou la vitesse de déplacement : un nœud ne peut pas les toucher.

Un champ absent du kit de base doit être déclaré dans `SkillBuilds.OPTIONAL`, avec le code qui le lit :

| Chemin | Lu par | Nœuds |
|---|---|---|
| `def.LauncherMove` | Brawler.request (heavy après 2 coups) | Sasuke DancingLeaf |
| `graph.readCounter` | Brawler.request (fenêtre de contre) | Sasuke SharinganCounter |
| `graph.stringCancels.*` | Combat:request (cancel de string ; canal min(canal, .14)) | StringFlash, ReadCancel, KaitenCancel, PalmBarrage, WireCancel |
| `graph.onRoute.*` | Brawler.routePayoff (`bodySeal`, `floorSeal`, `tenketsu`, `echo`…) | AirSwitchSeal, SpikeAnchor, PointStep, FeintEcho |
| `graph.blockCancels.Tool` | Combat:request (Tool après string bloquée) | BlockedTool |
| `graph.wallBounce.*` | Brawler.wallFollow | TrigramRebound |
| `def.Seals.PlantedLife` | Techniques.plant | SealInk |
| `def.SealRecall` | Techniques.expireSeals → recall | KunaiRecall |
| `def.ArrivalThrow` | Combat:arrivalThrow | AirExit |
| `def.Substitution` (`Mode`, `Counter`, `PlantDeparture`, `FreeRush`) | Combat:substitute, Combat:rush | ReturnSeal, CrowCounter, OutsideStep, CounterRush |
| `def.ParrySeal`, `def.ParryRedirect` | Combat:parryRider | ParrySeal, RedirectParry |
| `def.WallSteer` | Brawler.hit → Brawler.wallAim | WallPalm |
| `def.ToolMastery.AirSpread` (Sasuke), `.Chase`, `.FireBlades` | Combat:request Tool, Combat:projectileRiders, Combat:igniteBlade | ShurikenFan, RicochetChase, FireGeometry |
| `def.Awakening.FlashChain`, `.Reflex`, `.GuardPoints`, `.BloodChakra` | Brawler.hit, Combat:reflexEcho, Brawler.gentleFist, Combat:curseBlood | YellowFlow, MirageReflex, FullFieldPoints, CurseBlood |
| `tech.Quickstep.Arrival` | Techniques.Quickstep | QuickstepCut |
| `tech.WindCut.Chase`, `tech.VacuumPalm.Tenketsu`, `tech.WireTrap.WallPin`, `tech.PhoenixFlower.WiredBlades` | projectile `riders` → Combat:projectileRiders / Techniques.wireBind | GaleChase, SealingPalm, WirePin, WiredFlames |
| `tech.BurstStrike.DropReaction` | Techniques.BurstStrike | RasenganDrive |
| `tech.NeedleFan.FlankBlades` | Techniques.NeedleFan | FlankBlades |
| `tech.Rotation.Reach`, `.Reflect` | Techniques.Rotation → Combat:stepRotation | WideDome, ReturningRotation |
| `tech.SixtyFourPalms.Seal` | Techniques.SixtyFourPalms | LingeringSeal |
| `tech.Chidori.WallCharge` | Combat:request (variante WallChidori) | WallChidori |

Une entrée `Wired=false` marque un point d’accroche déclaré mais pas encore codé : ses nœuds restent des données (validées), ne peuvent être ni activés ni débloqués et sortent du maximum jouable. Aujourd’hui aucune entrée n’est dans ce cas.

## Contrats vérifiés (`SkillBuilds.checkTree`, suite Progression)

Identifiants uniques ; type connu ; coût entier 1–20 ; textes Shows/Counter ; label lore ; prérequis existants, sans cycle, jamais dans le propre groupe exclusif ; groupes exclusifs ≥ 2 options ; les 9 types présents dans chaque arbre ; un nœud `stat` ne touche que santé/réserve/regen ; un nœud majeur n’est pas une stat et ajoute au moins un comportement (`set` sur un chemin absent du kit de base) ; aucun nœud ne remplace une partie du kit de base (un nœud peut ajouter une route, jamais en écraser une) ; maximum de conception 120–150 SP ; chaque build maximal (chaque combinaison de choix exclusifs) reste dans les bornes.

## Build actif, budgets classés

`SkillBuilds.validate(fighter, nœuds, {budget, unlocked, allowUnwired})` : liste sans doublon, nœuds connus et câblés, prérequis actifs, au plus un nœud par groupe exclusif, nœuds débloqués (ensemble du profil), coût ≤ budget. `SkillBuilds.build` = validate + apply.

Brackets (`SkillBuilds.Brackets`, configurables) : `Fundamentals` 50, `Identity` 80, `Advanced` 100, `Endgame` 150 (« 120+ », fermé pour l’instant). `SkillBuilds.admit(bracket, fighter, nœuds, unlocked)` refuse (sans tronquer) un build hors budget, verrouillé ou incohérent : dans une file à N SP, chacun n’active que N points quel que soit son total débloqué.

## Presets

`BuildPresets.Ranked[fighter][bracket]` : un build d’exemple par bracket. `BuildPresets.AI[fighter][palier]` avec `AITiers` : Beginner 20–30, Medium 40–50, Hard 60–70, Boss 80–100, Legendary ≥ maximum jouable − 8. Les paliers IA sont cumulatifs et ne sont que des builds de l’arbre (aucun bonus caché).

## Démarrage de match

`Matches:start(player, playerId, botId, training, options)` ; `options` optionnel : `{player={nodes, unlocked}, bot={preset} ou {nodes}, bracket}`. Résolution et validation serveur (`Matches.resolveKit`) ; un build invalide ou hors budget refuse le départ. Sans `options` (tous les appels actuels, dont le remote client) : kits d’aujourd’hui. Le rematch conserve les options.

## Profil et persistance

Profil v1 : `{schemaVersion=1, id="u_<UserId>"|"dev_<nom>", sequence, lastCommand, fighters={[fighter]={earned, unlocked={[nœud]=true}, builds={[nom]={nodes}}, selected}}}`. Les SP dépensés sont dérivés (somme des coûts débloqués), jamais stockés. Commandes : `grant` (serveur uniquement), `unlock`, `saveBuild`, `deleteBuild`, `selectBuild` ; `ProfileSchema.apply(profil, séquence, commande, args)` travaille sur une copie, valide puis renvoie ; la même séquence rejoue le résultat sans réappliquer. Un profil inconnu, futur ou incohérent est refusé, jamais réparé ; supprimer ou renommer un nœud exigera une migration qui rembourse.

`ProfileRepository.new(store, {owner, clock, sleep})` : `load`, `view`, `apply`, `save(handle, release)`, `verify`, `pulse`, `closeAll`. Stores : `memoryStore()` (tests, injection de pannes) ; `dataStore({enabled=true, live=?})` : refusé par défaut, store DEV en Studio, store live seulement avec `live=true`, clés `p_u_<UserId>` / `p_dev_<nom>`. Aucun script du jeu ne crée encore de repository.

## Ajouter un nœud

1. Vérifier la mécanique réelle (fiche du personnage, code) ; choisir un type et un coût cohérents avec l’arbre.
2. Écrire l’effet sur un champ déjà lu, sinon déclarer le chemin dans `OPTIONAL` avec son lecteur ; borner tout nombre.
3. Ajouter le test avec/sans nœud dans `tests/Progression.spec.luau` ; `checkTree` doit rester vide.
4. Mettre à jour les presets si un palier ou un exemple doit l’utiliser.
