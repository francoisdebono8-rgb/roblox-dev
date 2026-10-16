# Outils de développement Studio — panneau F6, mises en situation, profiler

Outils préparés par Codex (`33028b2` outils/online, `7091585` labo chakra, branche `codex/ninja-chakra-interactions`, base `4df212c`) et portés sur l’arbre courant : API `Matches:start(player,playerId,botId,training,options)`, sessions online, roster CORE4, `World.WALL_RADIUS`. Ils ne changent aucune règle de gameplay : ils appellent le moteur réel (Matches, Combat, Brawler) et observent. Rapport de portage : [DEVTOOLS_PORT](../reports/convergence2/DEVTOOLS_PORT.md).

## Où ils existent

| Place | Outils |
|---|---|
| `dist/NinjaDuel.rbxlx` | **aucun** : `build.py` exclut tout module de `DEBUG_SOURCES` ; `tests/test_build_isolation.py` le prouve (noms, marqueurs, manifest, aucun `require` statique) |
| `dist/NinjaDuel-Debug.rbxlx` | inspecteur F8 (lecture seule) + panneau F6, ops `tool`, profiler, auto-test, labo chakra |
| `dist/NinjaDuel-QA.rbxlx` | même règle que l’inspecteur : QA = Debug + NativeQA automatique. Les outils y sont présents mais inertes tant qu’on ne les appelle pas |

Il n’y a pas de place `NinjaDuel-DevQA` : l’auto-test des outils se lance explicitement dans la place Debug (`selftest`, plus bas). Tous les modules sont aussi gardés par `RunService:IsStudio()` et l’attribut `NinjaDuelDebug`.

## Utilisation immédiate

Ouvrir `dist/NinjaDuel-Debug.rbxlx`, **Test → Play**, lancer un duel, puis **F6** (fenêtre de jeu au premier plan). Le panneau est caché au départ, à droite de l’écran (l’inspecteur F8 garde le coin haut-gauche).

- Joueur / Adversaire : Minato (Flashstep), Itachi (Mirage), Neji (GentleFist), Sasuke (Lion). Gaara (`Sand`) reste accessible par la Command Bar.
- Reset immédiat (sans intro, à 6 studs), Chakra / sub pleins, Éveil joueur, KO adversaire, Dummy (bot figé) / IA.
- Situations : `neutral`, `launcher`, `air`, `wall`, `substitution`, `grab`, `whiff`, `projectile` (le KO a son bouton), puis Répéter.
- Mesures ON / OFF, Rapport → Output, Volumes ON / OFF.

Une situation reconstruit le duel (nouveaux acteurs, nouvelle époque) puis le met dans un état par le moteur réel ; elle ne ressuscite pas un Humanoid mort et ne prouve pas qu’un humain a exécuté la route. Même paire de personnages : les builds de compétences (`startBuild`) sont conservés ; nouvelle paire : kits canoniques. Une session online (file, code privé, duel) est **refusée**, jamais reconstruite.

Panneau ouvert : Input reçoit un état non-Duel, donc aucune action de combat ne part derrière le panneau ; à l’ouverture les touches tenues sont relâchées (garde, saut, mouvement) comme lors d’une perte de focus. Panneau fermé : l’input est exactement celui du jeu. Manette : à l’ouverture la sélection Roblox se place sur le premier bouton. F6 n’est utilisé par aucun binding du jeu (`Controls.luau`) ; F8 reste l’inspecteur. Si Studio capture F6 (raccourci personnalisé), utiliser `dev:Invoke("tool","panel")`.

**Volumes** : racines en bleu, vraies Parts `BanglaHitbox` du duel en rouge (adornments locaux, aucune propriété ni collision modifiée). Une boîte de startup n’est pas une fenêtre active confirmée ; projectiles et hazards n’utilisent pas cette Part. Désactiver pour mesurer le rendu sans adornments.

## Command Bar (côté **Server**, pendant le Play)

```lua
local dev=game.ServerStorage.NinjaDuelDev
print(dev:Invoke("tool","list"))
print(dev:Invoke("tool","character",{first="Flashstep",second="Mirage"}))
print(dev:Invoke("tool","scenario",{name="wall",first="Lion",second="GentleFist"}))
print(dev:Invoke("tool","repeat"))
print(dev:Invoke("tool","dummy",{enabled=false}))
print(dev:Invoke("tool","refill"))
print(dev:Invoke("tool","awaken",{actor="human"}))
print(dev:Invoke("tool","ko",{actor="bot"}))
print(dev:Invoke("tool","panel"))
```

| Op `tool` | Arguments | Effet |
|---|---|---|
| `list` | — | situations, CORE4, dernière situation, mesures, dummy |
| `reset` / `character` | `first`, `second` (ids Fighters) | duel neuf à courte distance, sans intro ; le choix Dummy/IA est gardé |
| `scenario` | `name`, `first`, `second` optionnels | duel neuf + état ; le bot devient dummy |
| `repeat` | — | rejoue la dernière situation (sinon `neutral`) |
| `dummy` | `enabled` | bot figé (`true`) ou IA (`false`) |
| `refill` | — | chakra, cooldowns, charges de substitution (pas les PV) |
| `awaken` | `actor` = `human`/`bot` | PV à 30 %, vraie requête `Awaken` ; refusée (`Reacting`) si l’acteur subit une réaction, par exemple l’onde d’un éveil adverse |
| `ko` | `actor` | KO par l’adversaire via `Combat:damage` ; la manche suit le vrai flux (KO, manche suivante) |
| `profile` | `enabled` | mesures serveur + client ON/OFF |
| `report` | — | rapport serveur + client, imprimé en lignes `[NinjaDuelPerf]` |
| `selftest` | — | auto-test natif des outils (voir plus bas) |
| `panel` | — | ouvre / ferme le panneau du premier joueur (repli de F6) |

Arguments refusés hors liste blanche (`DevCommands`) : clés `first`, `second`, `name` (≤ 32 caractères), `actor`, `enabled`, cinq au plus. Le panneau passe par le RemoteFunction `ReplicatedStorage.NinjaDuelDevControl` (créé par DevHooks, Debug/QA seulement, 4 commandes/s par joueur) ; la Command Bar agit sur le premier joueur, comme les autres ops.

Situations : `neutral` (face à face), `launcher` (bot `Launched`, fenêtre de poursuite ouverte), `air` (les deux en l’air, bot `Juggled`), `wall` (vrai panneau `NinjaWall` sondé à `World.WALL_RADIUS` sur +X, puis `Brawler.splat` du moteur : épinglage, impact, dégâts de splat et fenêtre de poursuite ; le joueur au sol en face), `substitution` (vraie requête après un hit), `grab`, `whiff` (Heavy à 22 studs), `projectile` (outil vers le bot à 24 studs), `ko`. Une requête refusée par le moteur fait échouer la situation avec sa raison.

Les ops historiques restent identiques : `start`, `startBuild`, `skills`, `selection`, `lag`, `online`, `act`, `scripted`, `move`, `health`, `sprint`, `refill` (avec PV), `place`, `freezeBot`, `autopilot`, `clientlog`, `probe`, `clientinfo`, `ko`, `rematch`, `damagelog`, `inspect`, `trace`, `state`, `contracts`, ainsi que les remotes `NinjaDuelDevLog` / `NinjaDuelCombatDebug` et les sondes de [tools/studio](../../tools/studio/README.md). Reproduction scriptée sans paquet Move concurrent :

```lua
local dev=game.ServerStorage.NinjaDuelDev
dev:Invoke("tool","scenario",{name="neutral"})
dev:Invoke("scripted",true)
dev:Invoke("act","human","Attack")
task.wait(.25)
print(dev:Invoke("state"))
dev:Invoke("scripted",false)
```

## Mesurer, puis attribuer

Mesures ON, reproduire une séquence courte, Rapport → Output, Mesures OFF. Command Bar : `dev:Invoke("tool","profile",{enabled=true})`, puis `dev:Invoke("tool","report")`, puis `dev:Invoke("tool","profile",{enabled=false})`.

Serveur : temps CPU de `Matches.update/request/send/destroy`, `Combat.update`, `updateActor`, `updateProjectiles`, `updateHazards`, `runScheduled`, `separate`, `pushImpact`, `relocate` ; cadence Heartbeat ; écart et taille estimée des snapshots ; corrections de séparation ; sauts de position (avec `warpSerial`) ; états, réactions, événements de combat ; watchdog d’états transitoires en retard. Les duels online sont observés aussi et libérés à leur teardown. Client : frame, écart et âge des snapshots, temps de Presentation / Camera / HUD / Effects, écart présenté–répliqué et trajet par frame des deux corps. Scopes MicroProfiler `NinjaDuel/server.*` et `NinjaDuel/client.*`.

Bornes : 240 échantillons par mesure (p50/p95 sur cette fenêtre, moyenne/max sur toute la capture), 128 labels, 80 événements. Les wrappers sont retirés à OFF et à la destruction d’un duel. Le coût mesuré inclut les sondes imbriquées : comparer avec une capture MicroProfiler sans mesures avant toute optimisation. Un grand déplacement avec changement de `warpSerial` peut être une téléportation voulue ; une frame longue n’identifie pas le script responsable ; l’écart présenté inclut le lissage voulu (~45 ms). Ne pas modifier une trajectoire pour faire disparaître un compteur.

## Auto-test natif des outils

`dev:Invoke("tool","selftest")` rend la main tout de suite et lance, dans la place Debug ou QA : les neuf situations, changement de personnage / refill / éveil / répétition, 12 s d’IA contre IA avec mesures des deux côtés, puis la vérification que tous les wrappers ont disparu. Sortie : lignes `[NinjaDuelDevQA] PASS|FAIL` puis une ligne `RESULT` JSON (build inclus). Pendant ~25 s : fenêtre Studio au premier plan, ne pas toucher aux commandes. Jamais lancé au démarrage ; dans la place QA, attendre la ligne `[NinjaDuelQA] TOTAL` de NativeQA avant de le lancer. Refusé si le premier joueur est dans une session online.

## Export du rapport (CLI)

Le jeu imprime une ligne JSON bornée par métrique / événement, encadrée par `begin` / `end` et marquée du `BuildFingerprint`. Depuis `games/ninja-duel` (`python` sous Windows) :

```sh
python3 tools/dev.py report --log "$LOCALAPPDATA/Roblox/logs/<dernier log Studio>.log" --out <fichier>.json
python3 tools/dev.py report --log <output copié>.txt --manifest dist/NinjaDuel-QA.json
```

La CLI exige le fingerprint exact du manifest (`dist/NinjaDuel-Debug.json` par défaut), un artefact identique à son manifest et toutes les lignes entre `begin` et `end` ; elle refuse une capture tronquée ou d’un autre build. Un texte copié depuis la fenêtre Output (horodatage, suffixe « - Server - Script:ligne ») est accepté. Les lignes `RESULT` de `selftest` et du labo chakra sont jointes. Sans `--out`, le JSON va sur la sortie standard.

## CLI locale

```sh
python3 tools/dev.py verify                        # syntaxe Luau, catalogue lab, suites headless, isolation si dist/ est construit
python3 tools/dev.py build --kind debug            # main | debug | qa
python3 tools/dev.py release                       # verify + trois builds + isolation ; ne publie, ne commit, ne pousse rien
python3 tools/dev.py audit --baseline 50b90bc      # fichiers cœur gameplay identiques à une révision ?
python3 tools/dev.py compare --out <fichier>.json
python3 tools/dev.py catalogue --archetype acrobatique
```

Outils : `LUAU`, `LUNE`, `LUAU_COMPILE`, puis `NINJA_DUEL_TOOLS`, `/private/tmp/ninja-duel-tools`, `%LOCALAPPDATA%/ninja-duel-tools`, puis PATH ; aucun téléchargement. La liste des suites est lue dans `TEST_RUNNERS` de `build.py` (même liste que `tests/run.sh`). `compare` lit les tables actives via `tools/inspect.luau` (aucun duel, aucune mutation) ; une sortie `--out` est une photographie à régénérer après modification des données.

## Labo chakra (optionnel)

Porté tel quel (`ChakraLab`, `ChakraDev`, `ChakraStudioView`, `ChakraStudioQA`, Debug/QA seulement). Il pilote le moteur chakra `ChakraConfig` / `ChakraRules` / `ChakraInteractions` / `ChakraVectors`, **qui n’est pas dans ce portage** (travail chakra séparé). Tant que ces modules manquent, `dev:Invoke("interactions",…)` répond `{ok=false, error="Chakra lab needs the chakra runtime module …"}` sans rien charger. Dès qu’ils sont dans le build, le labo se charge à la première commande ; `tests/DevInfra.spec.luau` active alors automatiquement son test (six démos, comparaison, ops Studio refusées en headless). Vérifié pendant le portage contre les modules runtime de Codex dans une copie : 15/15 DevInfra et 19/19 `Chakra.spec` de Codex.

```lua
local dev=game.ServerStorage.NinjaDuelDev
print(dev:Invoke("interactions","demo",{name="redirection"}))
print(dev:Invoke("interactions","show",{enabled=true}))
print(dev:Invoke("interactions","log",{enabled=true}))
print(dev:Invoke("interactions","play"))
print(dev:Invoke("interactions","step",{seconds=1}))
print(dev:Invoke("interactions","report"))
print(dev:Invoke("interactions","compare",{tool="Kunai",infusions={"None","Reinforce","Wind"},masteries={"Basic","WeaponExpert"}}))
print(dev:Invoke("interactions","qa"))
print(dev:Invoke("interactions","close"))
```

Démos : `kunai_wind`, `kunai_seal`, `redirection`, `wire_property`, `projectile_surface`, `fire_surface`. Autres ops : `spawn`, `nature`, `property`, `launch`, `surface`, `collision`, `embed`, `trigger`, `inspect`, `toggle`, `reset`, `stop`. La vue est `Workspace.NinjaDuelChakraLab` à `(0,250,500)` (sélectionner le dossier, F dans la vue éditeur) ; volumes anchored, non collidables, non requêtables. Proxies cinématiques sans gravité ni rig : réutiliser les règles, pas ces proxies, pour la vraie physique. Les valeurs du labo sont des fixtures, pas un équilibrage.

## Données `lab/` (inertes)

[lab/](../../lab/README.md) : `combat-library.json` (33 propositions, dix archétypes, variantes CORE4), `templates/` (personnage, moveset, éveil, projectile, grab ; `null` = à décider), `combat-tags.json`. Rien n’est chargé par le jeu ni par le build ; ne pas recopier une proposition dans les tables actives sans choix gameplay explicite.

## Checklists (Codex, à remplir, pas acquises)

Personnage : routes résolues ; whiff / garde / dodge / substitution / grab break ; KO pendant saisie ; réveil et manches ; nettoyage des projectiles ; clavier et PS5 ; lisible sans HUD ; budgets CPU/VFX/payload mesurés ; permissions d’animation. Map : spawns ; sol / mur / plafond réels ; tag `NinjaWall` cohérent ; sweep et occlusion ; wall tech / detach ; réception ; limites caméra ; budgets parts/rendu sur appareil cible. Online : deux clients distincts ; dégâts et états décidés par le serveur ; directions / aim / temps validés ; anti-spam ; impacts livrés aux deux ; déconnexion / KO / cleanup ; perte / latence / jitter ; aucun canal dev en production.

## Non vérifié nativement par ce portage

Studio n’était pas disponible : F6 dans la fenêtre de jeu, rendu et navigation du panneau, blocage / relâchement réel de l’input, adornments Volumes, wrappers et scopes MicroProfiler en Studio, lignes `[NinjaDuelPerf]` dans un vrai log, `selftest` complet, situation `wall` sur la vraie géométrie (headless : plan `NinjaWall` du harness), profiler sur un duel online à deux clients, labo chakra (runtime absent). Les suites headless prouvent états, wrappers et isolation, pas le ressenti.
