# Fondation de progression — PROG-001 / PROG-002 / PROG-003

2026-10-16, branche `claude/nd-progression-foundation` (base `c2d797c`). Mission : [COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §15–17, ouverte par DEC-012. Référence données : [PROGRESSION](../../systems/PROGRESSION.md).

Statut : **TECHNICAL PASS** (suites headless, trois builds, isolation, contrôles) · **NATIVE_STUDIO PENDING** (aucune session Studio pour ce bloc) · **HUMAN_VISUAL PENDING**. Aucun réglage d’équilibre n’est validé : les coûts sont un premier jet.

## Résumé

- Un arbre de compétences par fighter CORE4, tiré de ses mécaniques réelles (fiches [Minato](../../characters/MINATO.md), [Itachi](../../characters/ITACHI.md), [Neji](../../characters/NEJI.md), [Sasuke](../../characters/SASUKE.md)) : 75 nœuds, 35 majeurs, maximum 122–132 SP. Les 9 types demandés sont présents dans chaque arbre.
- Le fighter à **0 SP est exactement le kit actuel** : égalité profonde des définitions et des graphes, et rejouage tick à tick (duels IA et parcours scripté de toutes les actions) identique avec et sans build vide.
- **Les 75 nœuds sont câblés** ; chacun des 35 nœuds majeurs a un test « avec / sans nœud » qui prouve le changement de comportement ; les nœuds mineurs sont prouvés par le diff du kit et par les lectures du pipeline (coût, cooldown, canal, santé, regen).
- Budgets classés configurables 50 / 80 / 100 / 120+ ; le serveur refuse un build hors budget, verrouillé ou incohérent ; un build d’exemple par bracket et par fighter.
- IA à budget : 5 paliers par fighter (Beginner 23–27, Medium 43–46, Hard 65–69, Boss 88–95, Legendary 118–132 SP), builds ordinaires de l’arbre, sans stat cachée ; paramètre optionnel de démarrage de match (par défaut : rien ne change).
- Profil (SP gagnés, nœuds débloqués, builds sauvés par fighter) + repository : store mémoire pour les tests, adaptateur DataStore gardé (désactivé par défaut, DEV en Studio, live seulement sur demande explicite). Aucun achat.
- Tests : 17 suites / 222 cas (163 existants inchangés + Progression 49 + Profiles 11).

## Audit de la fondation Codex `29a9ec1`

| Module Codex | Décision | Raison |
|---|---|---|
| ProfileSchema (utilitaires `serializable`, `integer`, `id`, `copy` ; refus de réparer) | **Repris** dans [ProfileSchema](../../../src/Server/ProfileSchema.luau) | Sain et indépendant de l’économie |
| ProfileRepository (lease exclusif, révisions clôturées, jeton d’écriture idempotent, lecture ratée ≠ profil par défaut, pulse/closeAll) | **Repris et adapté** dans [ProfileRepository](../../../src/Server/ProfileRepository.luau) | Couplé à `CollectionEconomy.apply` et à la config économie ; remplacé par les commandes de compétences. Une lecture corrompue est maintenant refusée sans réessais |
| CollectionEconomy.apply (ledger de commandes : même séquence ⇒ rejoue le résultat, séquence ancienne ou trouée refusée) | **Principe repris** dans `ProfileSchema.apply` | Le reste (packs, monnaies, fragments, pity) est de la monétisation : **écarté** |
| DevelopmentProfileStore (UpdateAsync simulé, pannes injectées) | **Repris** comme `ProfileRepository.memoryStore` | Indispensable aux tests |
| DevelopmentDataStore (garde Studio + namespace DEV) | **Adapté** en `ProfileRepository.dataStore` | Même garde, plus un chemin live explicite (`live=true`) et des clés `p_u_<UserId>` |
| CharacterProgression (XP, rangs, croissance de vitesse) | **Écarté** | La croissance de stats par XP donne de la puissance hors build : contraire au principe des brackets |
| ProgressionConfig, ProgressionDefinitions, PackSimulation, ProgressionRandom | **Écartés** | Monnaies premium, raretés, packs : hors périmètre (monétisation) |
| ProgressionLobby, ProgressionRoster | **Écartés pour l’instant** | Files online (NET-001) ; l’idée de files séparées par mode est reprise par les brackets |

## Architecture

```
profil (unlocked, build choisi) ─┐
preset IA / exemple classé ──────┼─> SkillBuilds.admit / build (validation serveur)
                                 └─> kit = copies de Fighters[id] + MoveGraphs[id] + effets
Matches:start(..., options) ──> Combat:add(..., kit) ──> actor.def / actor.graph
                                                      └─> lus par Combat, Brawler, Techniques, Elements, AI
```

Points d’accroche explicites dans le code existant :

1. **Injection** : `Combat:add(..., kit)` donne à l’acteur sa copie de définition et de graphe (sans kit : les tables canoniques elles-mêmes).
2. **Accesseur de graphe** : `Brawler.graph(a)` remplace les six lectures `MoveGraphs[a.fighterId]`.
3. **Lecteurs de champs optionnels** (même schéma que `HiddenBlades`, `Feintable` ou `Awakening.NoBlindSpot`) : chaque champ absent du kit de base est déclaré dans `SkillBuilds.OPTIONAL` avec son lecteur (tableau dans la [référence](../../systems/PROGRESSION.md)). Familles : riders de substitution, riders de parade, riders de projectile, payoffs de route, champs de technique, règles d’éveil.
4. **Deux généralisations neutres** dans `Combat:request` : le cancel de string garde le canal de la technique s’il est déjà plus court que 0,14 s (`math.min` ; les cancels existants ont 0,18–0,62 s et `trainingChannelScale` ne vaut que 1 ou 3) et vérifie la condition de la technique avant de consommer la string (les conditions des cancels existants renvoient toujours vrai).
5. **Démarrage** : `Matches:start(player, playerId, botId, training, options)` ; le remote client n’envoie jamais d’options.

Aucun nouveau bouton : les nœuds changent ce que font des entrées existantes selon le contexte (DEC-006). Visibilité : cues serveur (texte déjà affiché par le client) et styles d’impact déjà dessinés (`mirage`, `deflect`, `clash`, `pin`, `ember`, `quickstep`, sceaux du snapshot) ; le client n’est pas modifié.

## Arbres CORE4

Majeurs en gras ; ⟂ = choix exclusif. Coûts = SP pour débloquer **et** pour activer.

### Minato (`Flashstep`) — un réseau de destinations préparées — max 132 SP

| Nœud | Type | SP | Prérequis | Effet |
|---|---|---|---|---|
| SealInk | propriété | 4 | — | sceaux plantés 15 s au lieu de 12 |
| LongSeal | propriété | 3 | — | Marked Kunai porte à 78 au lieu de 66 |
| SealCraft | propriété | 4 | — | Marked Kunai 1,8 s au lieu de 2,2 |
| **KunaiRecall** | outil | 10 | SealInk | courir sur son kunai planté le ramasse : sceau retiré, +5 chakra |
| **ReturnSeal** | substitution | 10 | SealCraft | chaque substitution laisse un sceau au point de départ |
| FlashEconomy | propriété | 5 | — | FTG 14 chakra au lieu de 16 |
| **StringFlash** | route | 12 | FlashEconomy | une string propre se cancel en FTG (sceau requis, canal 0,06) |
| **AirSwitchSeal** ⟂ | air/mur | 9 | FlashEconomy | le switch aérien laisse un sceau corporel 1,8 s |
| **SpikeAnchor** ⟂ | air/mur | 9 | FlashEconomy | le spike aérien plante un sceau là où le corps tombe |
| **AirExit** | air/mur | 9 | un des deux | Tool pendant une arrivée aérienne : kunai vers le bas, sceau au sol |
| **ParrySeal** | contre | 9 | FlashEconomy | une parade scelle l’attaquant 1,8 s |
| **YellowFlow** | éveil | 14 | StringFlash | éveillé, un coup < 0,7 s après une arrivée rescelle le corps |
| **QuickstepCut** | route | 10 | — | après Quickstep, frappe / launcher / Rasengan instantané annulent la récupération |
| **GaleChase** | jutsu | 8 | QuickstepCut | un Wind Cut qui touche ouvre la poursuite 0,8 s |
| RasenganFocus | propriété | 4 | — | Rasengan 21 chakra au lieu de 24 |
| **RasenganDrive** | jutsu | 10 | RasenganFocus | le Rasengan plongeant spike : un rebond au sol au lieu d’un knockdown |
| DeepReserves / Endurance / QuickHands | stat / stat / outil | 4 / 4 / 3 | — | chakra 116 · santé 130 · kunai récupéré en 0,48 s |

### Itachi (`Mirage`) — contrôle calme, lectures, géométrie — max 122 SP

| Nœud | Type | SP | Prérequis | Effet |
|---|---|---|---|---|
| QuickRead / EconomicRead | propriété | 5 / 4 | — | Read 3 s de cooldown · 12 chakra |
| **ReadCancel** ⟂ | route | 10 | QuickRead | une string propre finit en posture Read : la riposte adverse est lue |
| PatientRead ⟂ | contre | 6 | QuickRead | fenêtre de Read 1,35 s |
| **MirageReflex** | éveil | 14 | un des deux | sous Focus, parade ou esquive parfaite = leurre de genjutsu 1,5 s sur l’attaquant |
| **CrowCounter** | substitution | 10 | EconomicRead | après le corbeau, le coup suivant (0,6 s) est la CounterPalm |
| Precision / WideFan | outil | 3 / 5 | — | paire récupérée en 0,65 s · éventail aérien de 5 lames |
| **RicochetChase** | outil | 9 | Precision | une lame redirigée (ricochet, Geometry) qui touche ouvre la poursuite 0,6 s |
| **FlankBlades** | jutsu | 10 | Precision | les deux lames cachées de Shadow Shuriken arrivent par les flancs, au-delà d’une garde frontale |
| **FeintEcho** | route | 9 | — | le FeintStep laisse un leurre 1,2 s : frapper le leurre donne la lecture (MirageCatch) |
| **WallPalm** | air/mur | 10 | FeintEcho | la CounterPalm vise un mur à ≤ 14 studs dans ±45° : splat et phase murale |
| ShortSigns / PhoenixVolley / FireTempo | propriété | 5 / 4 / 4 | — | Mirage en 0,72 s · Phoenix 17 chakra · Fireball 4,6 s |
| **FireGeometry** | jutsu | 12 | FireTempo | ses shuriken qui traversent son sol brûlant s’enflamment : +1 dégât et petite zone de feu |
| SteadyBreath / Composure | stat | 4 / 4 | — | regen 7,8/s · chakra 133 |

### Neji (`GentleFist`) — domination au contact, points, défense circulaire — max 123 SP

| Nœud | Type | SP | Prérequis | Effet |
|---|---|---|---|---|
| PrecisePalms / DeepPoints | propriété | 4 / 5 | — | drain 7 au lieu de 6 · points fermés 6,5 s |
| PointStep | route | 5 | PrecisePalms | le CircleStep ferme un second point |
| **KaitenCancel** ⟂ | route | 11 | PrecisePalms | une string propre se cancel en Rotation (canal 0,04) |
| **PalmBarrage** ⟂ | route | 12 | DeepPoints | une string propre se cancel en 64 Palms (canal 0,14) |
| **FullFieldPoints** | éveil | 14 | PointStep | Byakugan éveillé : les paumes ferment des points à travers la garde, drain plein |
| SwiftRotation / WideDome | propriété | 5 / 5 | — | Rotation 5,2 s · dôme 8,2 studs |
| **ReturningRotation** | outil | 10 | SwiftRotation | kunai et shuriken pris dans le dôme repartent vers leur lanceur |
| NarrowBlindSpot | propriété | 4 | — | angle mort arrière ~40° au lieu de ~52° |
| **RedirectParry** | contre | 10 | NarrowBlindSpot | sa parade tourne l’attaquant de côté, ferme un point, ouvre la PalmThrust (0,5 s) |
| **OutsideStep** | substitution | 10 | NarrowBlindSpot | la substitution réapparaît sur le flanc de l’attaquant, contre 0,5 s |
| VacuumEconomy | propriété | 4 | — | Vacuum Palm 2,3 s |
| **SealingPalm** | jutsu | 9 | VacuumEconomy | Vacuum Palm ferme un point à distance |
| LingeringSeal | jutsu | 5 | — | techniques scellées 4,5 s après les 64 Palms |
| **TrigramRebound** | air/mur | 9 | VacuumEconomy | la PalmThrust fait rebondir un corps épinglé au mur (nouvelle phase aérienne + poursuite) |
| Conditioning / ChakraControl / ChakraReserve | stat | 4 / 4 / 4 | — | santé 141 · regen 8,2/s · chakra 121 |

### Sasuke (`Lion`) — hybride agressif, fil, feu, Chidori — max 124 SP

| Nœud | Type | SP | Prérequis | Effet |
|---|---|---|---|---|
| **DancingLeaf** | route | 10 | — | le heavy après deux coups devient le LionKick suivi (Shadow Leaf → Lion Combo) |
| SharperEyes | propriété | 5 | — | Sharingan 0,27 / 0,20 (toujours sous Itachi) |
| **SharinganCounter** | contre | 10 | SharperEyes | parade ou esquive parfaite : le coup suivant est le VaultKick (changement de côté) |
| **CounterRush** | substitution | 9 | DancingLeaf | après une substitution, E (0,8 s) est un chakra dash gratuit vers l’attaquant |
| ShurikenFan | outil | 4 | — | 3 shuriken en l’air au lieu de 2 |
| BlockedTool | route | 5 | — | une string bloquée se cancel en lancer |
| **WireCancel** | route | 10 | BlockedTool | une string propre se cancel en Wire Trap → Dragon Flame |
| **WirePin** ⟂ | air/mur | 10 | ShurikenFan | un fil qui lie près d’un mur (≤ 10 studs) attache le corps à la paroi 1,35 s |
| **WiredFlames** ⟂ | outil | 10 | ShurikenFan | les lames cachées du Phoenix tirent un fil : lien 0,7 s → Dragon Flame |
| FireMastery / PhoenixTempo | propriété | 4 / 4 | — | Fireball (et Dragon Flame) 21 chakra · Phoenix 4,2 s |
| ChidoriFocus / ChidoriEconomy | propriété | 5 / 5 | — / ChidoriFocus | charge 0,51 s · 30 chakra |
| **WallChidori** | jutsu | 12 | ChidoriFocus | lancé depuis une course murale : charge 0,3 s accroché au mur, puis la poussée plonge |
| CurseControl | éveil | 5 | — | Curse Mark 1,0 PV/s au lieu de 1,4 |
| **CurseBlood** | éveil | 14 | CurseControl | sous Curse Mark, le chakra manquant d’une technique est payé en PV (jamais jusqu’au KO) |
| Stamina / ChakraFlow / Reserves | stat | 4 / 4 / 4 | — | santé 126 · regen 8,1/s · chakra 111 |

Libellés lore : chaque nœud porte son label DEC-005 dans les données (aucun REJECT_ADULT_ONLY ; les capacités adultes restent exclues). Les textes `Shows`/`Counter` de chaque nœud décrivent l’effet et le contre-jeu.

## Câblés / non câblés

- **Câblés : 75 / 75.** Chaque nœud majeur a son test comportemental (avec le nœud : nouveau comportement ; sans : comportement d’origine) dans [Progression.spec](../../../tests/Progression.spec.luau).
- **Non câblés : aucun.** Le mécanisme existe et est testé (`Wired=false` sur un point d’accroche ⇒ nœud non activable, non achetable, hors maximum jouable, arbre toujours valide) pour les futurs nœuds qui exigeraient du travail client.
- Hors nœuds, non câblé : l’IA ne fait pas encore les entrées propres à certains nœuds (cancels de string, Air Exit) — d’où des presets IA fondés sur les nœuds qu’elle exerce déjà ; aucun écran de build ; aucun cycle de vie de profil dans le jeu.

## Budgets classés (PROG-002)

| Bracket | Budget | Ouvert | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|---|
| Fundamentals | 50 | oui | 49 | 50 | 48 | 49 |
| Identity | 80 | oui | 77 | 79 | 80 | 80 |
| Advanced | 100 | oui | 99 | 99 | 99 | 98 |
| Endgame (« 120+ ») | 150 | plus tard | 132 | 122 | 123 | 124 |

Les colonnes fighter donnent le coût du build d’exemple ([BuildPresets](../../../src/Server/BuildPresets.luau), `Ranked`). Les brackets sont des données (`SkillBuilds.Brackets`) ; `SkillBuilds.admit` refuse sans tronquer. Tests : un joueur qui a tout débloqué n’entre pas dans la file 50 avec son arbre complet ; un build de 80 SP est refusé en Fundamentals ; un nœud non débloqué est refusé ; une IA Boss (88 SP) est refusée dans un bracket à 80. Principe tenu : la progression donne plus de choix, pas plus de puissance dans un même bracket.

## IA à budget (PROG-003)

| Palier | Cible | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Beginner | 20–30 | 27 | 26 | 23 | 26 |
| Medium | 40–50 | 43 | 46 | 46 | 45 |
| Hard | 60–70 | 66 | 69 | 65 | 65 |
| Boss | 80–100 | 90 | 95 | 89 | 88 |
| Legendary | ≥ max − 8 | 132 | 118 | 123 | 124 |

Cohérence d’identité : Minato construit d’abord ses sceaux (substitution qui laisse un sceau, spike qui plante), Itachi sa défense de lecture (corbeau-contre, Read patient, ricochets), Neji sa Rotation (dôme large, lames renvoyées), Sasuke son Lion Combo et ses flammes à fil. Les paliers sont cumulatifs et privilégient ce que l’IA actuelle exerce déjà (règles passives, routes, riders de défense). Pas de triche : le test « nothing but tree nodes » vérifie que chaque différence avec le kit de base est déclarée par un nœud choisi ; `Config.AI` n’est pas touché. Démarrage : `options.bot={preset="Hard"}` ; sans option, l’IA est celle d’aujourd’hui. Stabilité : duels IA Legendary/Legendary et Hard/Beginner sur quatre paires sans blocage d’état.

## Persistance

- Profil v1 : par fighter `earned` (SP accordés par le serveur), `unlocked`, `builds` (8 max, noms validés), `selected`. SP dépensés dérivés, jamais stockés. Un profil incohérent (nœud inconnu, plus de SP dépensés que gagnés, prérequis manquant, build invalide, version future) est refusé, jamais réparé.
- Commandes serveur `grant`, `unlock` (prérequis et SP ; les deux options d’un choix exclusif peuvent être possédées), `saveBuild`, `deleteBuild`, `selectBuild` ; `ProfileSchema.selection` donne directement les nœuds et l’ensemble débloqué attendus par `SkillBuilds.admit`.
- Repository : lease exclusif, révision clôturée, rejouage idempotent d’une écriture ambiguë, incertitude de sauvegarde qui bloque les mutations, lecture ratée ou corrompue jamais remplacée par un profil vide. DataStore : désactivé par défaut ; en Studio uniquement le store `NinjaDuel_Progression_DEV` ; en live seulement avec `live=true`. **Rien ne le crée dans le jeu** (pas de chargement à l’arrivée d’un joueur, pas de BindToClose) : décision volontaire tant que l’usage live n’est pas tranché.

## Essayer un build en Studio

Ouvrir `dist/NinjaDuel-Debug.rbxlx`, Play, puis dans la barre de commande serveur :

```lua
local dev = game.ServerStorage.NinjaDuelDev
print(dev:Invoke("startBuild", {player="Lion", bot="Mirage", playerRanked="Identity", botPreset="Hard"}))
print(dev:Invoke("startBuild", {player="Flashstep", bot="GentleFist", playerNodes={"FlashEconomy","StringFlash","QuickstepCut"}, bracket="Fundamentals"}))
print(dev:Invoke("state").human.build, dev:Invoke("state").bot.build)
local skills = dev:Invoke("skills") -- arbres, brackets, paliers IA, maxima
```

`startBuild` passe par la même validation que `Matches:start` (`{ok=false, reason=...}` si le build est refusé). Le build normal ne contient pas DevHooks.

## Preuves

| Contrôle | Résultat |
|---|---|
| `bash games/ninja-duel/tests/run.sh` | 17 suites PASS : 163 cas existants inchangés + Progression 49 + Profiles 11 |
| `python games/ninja-duel/build.py` (+ `--debug`, `--qa`) | Automated suites PASS ×3, sourceEquality PASS (SHA ci-dessous) |
| `python -m unittest … test_build_isolation.py` | 4 OK (DevHooks hors build normal) |
| `python tools/check_architecture.py` | PASS |
| `python games/ninja-duel/tools/check_project_docs.py` | PASS |

Builds : voir la section « Artefacts » en fin de rapport.

## Risques

- **Équilibre** : coûts et valeurs sont un premier jet ; à même budget deux builds ne valent pas forcément la même chose. À mesurer (Balance.sim avec presets, duels humains).
- **Feel non jugé** : relocations nouvelles (Outside Step, Wire Pin, poussée du Wall Chidori), lames qui apparaissent sur les flancs, rebonds — contrats headless seulement ; à voir en Studio avant tout bracket ouvert.
- **Présentation** : aucun VFX propre ; cues texte et styles existants (le leurre FeintEcho réutilise les corbeaux de `mirage`).
- **Boucles** : YellowFlow (re-scellement après FTG) est borné par chakra, cooldown, scaling de combo et limite de 11 coups ; KunaiRecall rend moins que le lancer ne coûte ; CurseBlood ne peut pas tuer. À surveiller en jeu.
- **Stabilité des IDs** : un nœud renommé ou retiré invalide les profils qui le possèdent ; il faudra une migration qui rembourse.
- **Persistance** : jamais exercée sur un vrai DataStore (budgets, throttling, deux serveurs).

## Prochaines étapes

1. Validation native par nœud majeur sur l’artefact debug exact (`startBuild`), puis acceptation humaine.
2. Sélection de build compacte dans l’écran de sélection (sans nouveau bouton de combat) et tag de build au HUD/intro (champ de snapshot).
3. Hôte de profils : chargement à l’arrivée, gains de SP sur résultat de match (commande `grant`), sauvegarde/BindToClose, puis admission classée dans le lobby PvP (NET-001).
4. Règles IA pour les entrées propres aux nœuds (cancels de string, Air Exit) une fois les paliers joués.
5. Simulation d’équilibre avec les presets ; ajustement des coûts.
6. Backlog (non modifié ici, `docs/active` hors périmètre) — proposition : PROG-001 → PARTIAL (TECHNICAL PASS, NATIVE/HUMAN PENDING) ; PROG-002 → PARTIAL (architecture + admission + exemples ; UI et files online restantes) ; PROG-003 → PARTIAL (presets + option de démarrage ; règles IA dédiées restantes).

## Artefacts

Builds Windows (outils `NINJA_DUEL_TOOLS`), 17 suites PASS dans chaque manifest, sourceEquality PASS ; nativeQA / visualAcceptance PENDING.

| Artefact | SHA-256 | buildFingerprint |
|---|---|---|
| `dist/NinjaDuel.rbxlx` | `572a99d3052d3b2229390ce4d250ced106ba5b186e48d5411cee1740e4b53a77` | `39c1a5ada0830454a69b5551c4ec12b99148c802749509847f33588550ded476` |
| `dist/NinjaDuel-Debug.rbxlx` | `e86888a4f7621cab0a5ad121baa7dbe630ae8a2c916db01b83789156e5c4b31e` | `132415384155b11e5a8f496e9d23b5bd4164d694fe75d3252ea9a1ce56ac3c62` |
| `dist/NinjaDuel-QA.rbxlx` | `50f3ba88e701d43b1c2c739dd298935fb07b25958c154f4ae7d7be0f2aaa19fa` | `afd40d8bd0de8123ad8cc28a5ee0c285994659d4a792f90ff6e32968260387b1` |
