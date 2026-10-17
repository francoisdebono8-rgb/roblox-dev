# Portage des outils Studio de Codex — rapport

Branche `claude/nd-ccc2-devtools`, base `50b90bc`. Source : `origin/codex/ninja-chakra-interactions`, commits `33028b2` (outils, online) et `7091585` (labo chakra), ancienne base `4df212c`. Guide d’usage : [DEVTOOLS](../../../tools/DEVTOOLS.md).

## En bref

- Les outils de Codex sont dans les places **Debug** et **QA** : panneau F6, neuf mises en situation, profiler serveur + client, export de rapport, auto-test natif, volumes de hitbox, labo chakra.
- La place **normale** n’en contient aucun. Le test d’isolation le prouve, et il échoue bien si un module fuit (vérifié en retirant `DevMetrics` de `DEBUG_SOURCES` dans une copie).
- **Aucun fichier de gameplay modifié** : `tools/dev.py audit --baseline 50b90bc` donne 21/21 fichiers cœur identiques. `Main.client.luau` reçoit seulement la garde Debug (une ligne de getter + un `require` conditionnel) ; `DevHooks.luau` reçoit seulement des ajouts.
- Toutes les ops existantes de `NinjaDuelDev` gardent leur comportement exact.
- Studio n’était pas disponible : rien n’a été vérifié nativement (liste en fin de rapport).

## Porté et adapté

| Fichier | Origine | Adaptation à l’arbre courant |
|---|---|---|
| `src/Server/DevTools.luau` | Codex | ops `list`, `panel` et `selftest` ajoutées ; sessions online refusées ; garde `DevTools.missing` pour le labo chakra |
| `src/Server/DevCommands.luau` | Codex `Shared/DevCommands` | déplacé côté serveur (jamais répliqué) ; nouvelles ops dans la liste blanche |
| `src/Server/DevScenarios.luau` | Codex | `Matches:start(player,id,id,false,options)` ; builds de compétences gardés si la paire ne change pas ; refus online ; `wall` via le vrai `Brawler.splat` sur le panneau `NinjaWall` sondé à `World.WALL_RADIUS`, joueur au sol ; une requête refusée fait échouer la situation ; vérification du KO |
| `src/Server/DevProfiler.luau` | Codex | observe aussi les duels online (`Online.duels`) et libère leurs wrappers au `teardown` ; restaure le wrapper de latence de `delayRequests` |
| `src/Server/DevReport.luau` | Codex | inchangé (lignes `[NinjaDuelPerf]` bornées) |
| `src/Server/DevQA.luau` | Codex | plus de place `DevQA` : lancé explicitement par `dev:Invoke("tool","selftest")` dans une tâche ; refus online ; nettoyage garanti |
| `src/Shared/DevMetrics.luau` | Codex | budget de `validPayload` paramétrable (8192 pour un rapport client complet, qui dépasse 2048) |
| `src/Client/DevClient.luau` | Codex | CORE4 lus dans `Fighters` ; panneau à droite (l’inspecteur F8 garde le coin gauche, DisplayOrder 110) ; relâchement complet à l’ouverture (garde, saut, mouvement) ; sélection manette seulement si la manette est active ; repli `panel` ; **ne répond plus à `probe`, `info` ni aux logs** : ces réponses restent celles de `Main.client`, dont dépendent les sondes du lead |
| `src/Client/DevVolumes.luau` | Codex | adversaire trouvé par `data.bot.id` (le duel online nomme ses corps `Duelist1/2`) |
| `src/Server/ChakraLab/ChakraDev/ChakraStudioView/ChakraStudioQA.luau` | Codex `7091585` | code identique, en-têtes seulement |
| `src/Server/DevHooks.luau` | Codex | ajouts uniquement : ops `tool` et `interactions`, RemoteFunction `ReplicatedStorage.NinjaDuelDevControl` (4 commandes/s), réponse `report` du client sur `NinjaDuelDevLog` (connexion séparée, validée, 2/s), `watch` du profiler, nettoyage à la déconnexion |
| `src/Client/Main.client.luau` | Codex | getter d’Input bloqué quand le panneau est ouvert ; `DevClient` cherché par `FindFirstChild` sous `IsStudio`, installé dans un `pcall` ; le bloc Studio existant (sonde, info, logs) est intact |
| `tools/dev.py`, `tools/inspect.luau` | Codex | kinds `main/debug/qa` ; suites lues dans `TEST_RUNNERS` de `build.py` ; `.exe` et `LUAU_COMPILE` sous Windows ; sortie UTF-8 ; `audit --baseline` obligatoire, liste cœur actuelle (21 fichiers) ; `report` accepte une copie de l’Output (préfixe horaire, suffixe « - Server - Script:ligne ») et joint les `RESULT` de DevQA et du labo ; `--out` facultatif |
| `lab/` | Codex | données identiques ; lien du README corrigé |
| `tests/DevInfra.spec.luau` | Codex `DevInfra.spec` | réécrit sur les vrais `Matches`/`Combat`/`Online` (stubs de scène du spec Online) au lieu d’un faux `matches` |
| `tests/test_build_isolation.py` | — | étendu (voir preuve), avec les vérifications CLI de Codex `BuildTools.spec.py` |

`build.py` : `DEBUG_SOURCES` étendu aux 13 modules ; `DevInfra` ajouté à `TEST_RUNNERS` et à `tests/run.sh`. Aucune autre ligne du build ne change.

## Labo chakra : porté, avec une dépendance

Le labo pilote le moteur chakra `ChakraConfig` / `ChakraRules` / `ChakraInteractions` / `ChakraVectors`, porté par un autre agent sur une autre branche. Pour ne créer aucun conflit, ces quatre modules **ne sont pas** dans ce portage. Le labo reste autonome :

- `DevHooks` ne charge `ChakraDev` qu’à la première commande `interactions`, et seulement si les quatre modules existent dans `ServerScriptService.NinjaDuelServer`. Sinon la réponse est `{ok=false, error="Chakra lab needs the chakra runtime module ChakraConfig (not in this build)"}` et rien n’est chargé.
- `ProfileSchema` (`copy`, `serializable`, `id`, `integer`) a déjà la même sémantique que chez Codex.
- `DevInfra.spec` vérifie la garde aujourd’hui. Il active tout seul le test du labo (six démos, comparaison, ops Studio refusées en headless) dès que le runtime est fusionné.
- Vérifié pendant le portage dans une copie jetable, avec les modules runtime de Codex ajoutés : DevInfra 15/15 et `Chakra.spec` de Codex 19/19 (moteur et labo).

Risque à la fusion : si le runtime arrive dans un autre dossier, sous d’autres noms ou avec une autre API, la garde le signalera, ou le test auto-activé échouera. Il faudra alors adapter `DevTools.ChakraRuntime` ou l’appel `ChakraDev.new(cfg,true)`.

## Non porté, et pourquoi

| Élément Codex | Raison |
|---|---|
| Place `dist/NinjaDuel-DevQA.rbxlx` (`--dev-qa`) | un 4ᵉ artefact et une modification de `Main.server` pour un smoke test ; remplacé par `selftest` dans la place Debug ou QA, sans build en plus |
| Publication atomique, porte `luau-compile` et manifest git dans `build.py` | comportement du build hors périmètre (seuls les kinds et `DEBUG_SOURCES` me sont confiés) ; la vérification de syntaxe existe dans `tools/dev.py verify` |
| Test « un test raté ne publie pas » (`BuildTools.spec.py`) | dépend de cette publication atomique ; les deux autres vérifications sont portées |
| Changements Input / Controls / UI / Matches / Tutorial / NativeQA / Combat de `33028b2` | gameplay et input, déjà repris autrement dans l’arbre courant |
| `Online*`, `Progression*`, `Development*`, `CollectionEconomy`, `PackSimulation`, op `profiles`, `tools/progression.*` | systèmes déjà portés autrement (NET-001, PROG-001) ou hors outils |
| `ChakraConfig/Rules/Interactions/Vectors`, `ChakraInputPlan`, `tools/interactions.*`, `interactions/` | runtime chakra et ses outils hors ligne : travail chakra séparé |
| `reports/*.json` de Codex | photographies de l’ancienne base, périmées |
| Modification du Harness | inutile : les stubs `UserInputService` existent déjà |

## Commandes Studio exactes

Ouvrir `dist/NinjaDuel-Debug.rbxlx`, Test → Play, lancer un duel, puis **F6**. Command Bar côté Server :

```lua
local dev=game.ServerStorage.NinjaDuelDev
print(dev:Invoke("tool","list"))
print(dev:Invoke("tool","character",{first="GentleFist",second="Lion"}))
print(dev:Invoke("tool","scenario",{name="wall"}))
print(dev:Invoke("tool","repeat"))
print(dev:Invoke("tool","dummy",{enabled=false}))
print(dev:Invoke("tool","refill"))
print(dev:Invoke("tool","awaken",{actor="human"}))
print(dev:Invoke("tool","ko",{actor="bot"}))
print(dev:Invoke("tool","profile",{enabled=true}))
print(dev:Invoke("tool","report"))
print(dev:Invoke("tool","profile",{enabled=false}))
print(dev:Invoke("tool","selftest"))
print(dev:Invoke("tool","panel"))
print(dev:Invoke("interactions","demo",{name="redirection"}))
```

La dernière ligne doit aujourd’hui répondre « needs the chakra runtime module ». Ensuite, depuis `games/ninja-duel` : `python tools/dev.py report --log <log Studio ou Output copié>`.

## Preuve d’isolation

`python -I tests/test_build_isolation.py` : 9 tests OK.

- `test_normal_artifact_has_none_of_the_dev_tools` : aucun des 16 modules Debug dans `NinjaDuel.rbxlx` ; aucun marqueur propre à ces modules dans ses sources (`NinjaDuelDevControl`, `NinjaDuelDevPanel`, `NinjaDuelDevMeasure`, `DevObservedVolume`, `[NinjaDuelPerf]`, `[NinjaDuelDevQA]`, `[NinjaDuelChakraQA]`, `NinjaDuelChakraLab`, `NinjaDuelCombatDebug`) ; aucun dans les sources du manifest ; fingerprint distinct de Debug.
- `test_debug_sources_are_declared_and_exist` : `DEBUG_SOURCES`, lu dans `build.py`, contient toute la liste, et chaque fichier existe.
- `test_no_shipped_module_requires_a_debug_only_module` : aucun `require(script.Parent.X)` statique vers un module Debug dans la place normale, sauf `Main.server` sous ses gardes Studio + `NinjaDuelDebug`/`NinjaDuelQA`. `Main.client` ne fait que `FindFirstChild("DevClient")` sous `IsStudio`.
- Debug et QA contiennent les 13 modules d’outils, et QA ajoute NativeQA. Les sources communes restent identiques octet par octet dans les trois places.
- CLI : catalogue `lab/` valide et absent de `src/` ; l’export refuse un autre build, une capture tronquée et un artefact différent de son manifest.

Manifests : la place normale garde exactement les 43 sources de la base ; seul le hash de `Main.client.luau` change. Debug passe de 46 à 59 sources, QA de 47 à 60. Contre-épreuve : avec `DevMetrics` retiré de `DEBUG_SOURCES` dans une copie, deux tests échouent.

**Règle QA** : elle reste celle de l’inspecteur, QA = Debug + NativeQA. Les outils sont présents dans la place QA mais inertes : panneau fermé, mesures OFF, rien au démarrage.

## Tests

- `bash tests/run.sh` : 19 suites PASS, dont la nouvelle `DevInfra` à 14 cas (15 avec le runtime chakra).
- Les trois builds passent. Chacun relance les 19 suites (`automatedQA` PASS).
- `tests/test_build_isolation.py` : 9 OK. `tools/check_project_docs.py` : PASS. `tools/check_architecture.py` : PASS.
- `tools/dev.py verify` : 60 sources Luau compilées, catalogue valide, suites et isolation PASS.
- `tools/dev.py audit --baseline 50b90bc` : 21/21 fichiers cœur identiques.

`DevInfra` couvre :

- les métriques bornées et inertes ;
- la liste blanche ;
- l’identité des PV et des événements, mesures ON ou OFF, sur le vrai duel ;
- la libération des wrappers après 20 resets ;
- les neuf situations sur le moteur réel, avec un plan `NinjaWall` du harness pour `wall`, puis le flux de manche après KO ;
- le refus d’un stage sans mur ;
- les CORE4, refill, éveils (y compris le refus pendant l’onde d’un éveil adverse) et KO ;
- la conservation des builds ;
- le refus online, en file comme en duel ;
- le profiler sur un duel online jusqu’au teardown ;
- le no-op hors Studio ;
- des lignes de rapport en JSON valide de moins de 1000 caractères ;
- la garde du labo chakra.

## Non vérifié nativement

Studio n’était pas disponible. Restent à vérifier :

- F6 arrive bien au jeu : Studio pourrait le capturer, le repli est `tool panel`.
- Le panneau : rendu, recouvrement avec F8 sur une petite fenêtre, navigation manette.
- L’input réellement bloqué derrière le panneau, puis relâché à la fermeture.
- Les adornments Volumes.
- Les wrappers et scopes MicroProfiler `NinjaDuel/*` dans Studio.
- Les lignes `[NinjaDuelPerf]` d’un vrai log, et leur export par la CLI.
- `selftest` de bout en bout, rapport client compris.
- La situation `wall` sur la vraie géométrie de l’arène. Le rayon est à y=12 vers +X : les bannières, buissons et balcon sont décoratifs et ne bloquent pas les requêtes ; l’arbre le plus proche est à x≈74, avant le départ du rayon à x=91.
- Le profiler sur un duel online à deux clients Studio.
- Le labo chakra en Studio : runtime absent, et le smoke natif de Codex n’avait jamais passé non plus.

## Risques

- **Conflits de fusion.** `Main.client.luau` (ligne `Input.new`) et `DevHooks.luau` si un autre agent les touche ; `TEST_RUNNERS` est une seule ligne dans `build.py`, et tout ajout de suite sur deux branches y entre en conflit, résolution triviale ; la dépendance runtime du labo chakra, décrite plus haut.
- **Erreurs pendant la mesure.** Une erreur dans une fonction mesurée est relancée avec son message, mais sans la pile d’origine, tant que les mesures sont ON (comportement de Codex).
- **Situations.** Ce sont des reproductions d’état : elles ne valident ni un combo humain ni le ressenti.
