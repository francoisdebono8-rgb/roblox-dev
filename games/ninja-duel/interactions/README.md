# Chakra × outils — Codex prépare, Claude teste/adapte

**OFF dans le jeu.** Aucun import dans Combat, Techniques, Input, Camera ou les movesets. Le seul raccord est un bindable Studio, chargé à la première commande explicite. Les exemples n'utilisent jamais les vrais projectiles ni le chakra des combattants.

Fonctionne : règles déclaratives, tags/propriétés, natures, maîtrise, budgets, résultats atomiques, traces, comparaison, labo cinématique et vue Studio optionnelle. Préparé : branchement aux armes réelles, animations/timings/VFX, stun/ignition de gameplay, pièges, téléportation et choix d'input. **Claude décide de ces derniers et du feel.** Les valeurs/coûts/caps/durées du labo sont des fixtures, pas un équilibrage proposé pour le jeu. Le speed explicite de launch est un override QA borné par MaxSpeed.

## Tester immédiatement

Ouvrir le build principal `dist/NinjaDuel.rbxlx`, lancer Test, Command Bar **Server** :

```lua
local dev = game.ServerStorage.NinjaDuelDev
print(dev:Invoke("interactions", "demo", {name="redirection"}))
print(dev:Invoke("interactions", "show", {enabled=true}))
print(dev:Invoke("interactions", "log", {enabled=true}))
print(dev:Invoke("interactions", "play"))
```

La vue est dans `Workspace.NinjaDuelChakraLab`, à `(0,250,500)` : sélectionner ce dossier dans l'Explorer et cadrer avec F **dans la vue serveur/éditeur**, pour garder la caméra de jeu intacte. `show` accepte un `origin={x=…,y=…,z=…}` explicite pour déplacer le labo. Tous ses volumes sont anchored/non collidables/non queryables/non touchables ; ils ne participent pas aux collisions du duel. Ce sont des formes de diagnostic, pas les assets/animations définitifs.

`demo` remet l'état à zéro, prépare le scénario et met en marche uniquement ses règles qui n'ont pas déjà reçu un override. Scénarios : `kunai_wind`, `kunai_seal`, `redirection`, `wire_property`, `projectile_surface`, `fire_surface`. Puis `play` anime, `stop` suspend, `step {seconds=1}` avance de façon déterministe. Relancer `demo` pour reproduire. `close` déconnecte le tick, détruit la vue et vide le labo. Les objets/points expirent après MaxLife ; les surfaces restent jusqu'au reset.

```lua
print(dev:Invoke("interactions", "stop"))
print(dev:Invoke("interactions", "toggle", {rule="redirect-projectile",enabled=false}))
print(dev:Invoke("interactions", "demo", {name="redirection"}))
print(dev:Invoke("interactions", "step", {seconds=1}))
print(dev:Invoke("interactions", "report"))
print(dev:Invoke("interactions", "compare", {tool="Kunai",infusions={"None","Reinforce","Wind"},masteries={"Basic","WeaponExpert"}}))
print(dev:Invoke("interactions", "qa")) -- smoke natif explicite, jamais au bootstrap
```

`report` donne objets, surfaces, tags, vitesse/propriétés/anchor, coût, règles sélectionnées/rejetées et raisons. `log` exporte `[NinjaDuelChakra]` avec numéro/temps du labo et rule IDs. `qa` teste les six exemples, les positions des modèles natifs, l'isolation des volumes et le cleanup ; ce n'est pas une validation humaine du feel. Vérification de cette passe : 206 tests Luau + 10 Python PASS ; smoke natif PENDING, le contrôle UI reste attaché à une ancienne instance sans ChakraDev.

Opérations libres avec les mêmes arguments dans le bindable :

| Opération | Arguments |
|---|---|
| spawn | id, tool=Kunai/Shuriken/Wire/Target, position={x,y,z}, mastery, character, owner, chakra |
| nature | id, nature=Wind/Fire/Lightning/Reinforce/None |
| property | id, property=Marked/Seal, enabled=true/false |
| launch | id, direction={x,y,z}, speed optionnel |
| surface | id, kind=Wall/Floor/Wood, position, normal optionnel |
| collision | source, target : deux projectiles lancés ; direction/normal optionnels |
| embed | id, surface : force SurfaceHit avec le point/normal de la surface |
| trigger | trigger, source, target/surface, position/normal/direction, tags de contexte |
| inspect | id optionnel (sans id : état entier) |
| toggle | rule, enabled |
| reset | clearRules optionnel : sinon les overrides sont conservés pour A/B |

Une bascule affecte les **prochains triggers**, sans annuler les résultats déjà produits. `nature None` retire l'infusion et recalcule les stats de base ; retirer Marked/Seal retire la propriété manuelle. Un anchor déjà produit est un résultat historique jusqu'à reset/expiration ; Claude pourra choisir sa politique d'invalidation dans l'adaptateur réel. Les signals conduction/ignition/piège/spatial sont des données, sans dégâts, stun, feu réel ou téléportation.

Depuis `games/ninja-duel`, sans Studio ni réseau :

```sh
python3 tools/interactions.py suite --out interactions/reports/examples.json
python3 tools/interactions.py demo --name kunai_seal --seconds 1
python3 tools/interactions.py compare --tool Kunai --infusions None Wind --masteries Basic WeaponExpert
python3 tools/interactions.py batch --file interactions/example-batch.json --out interactions/reports/batch.json
python3 tools/dev.py verify
```

Le batch rejoue jusqu'à 64 commandes dans un nouveau labo, sans sauvegarde de profil. Les rapports contiennent une fixture/config ou les commandes reproductibles ; un échec n'écrase pas le rapport précédent. `suite` inclut les six exemples et une comparaison.

## Reprendre les interfaces

Modules `src/Server/Chakra*` :

- `ChakraConfig` : Objects.ToolType/tags/stats/caps/infusions ; Natures ; Properties ; Surfaces ; Triggers ; MasterySkills ; Masteries ; CharacterMastery ; Rules. Les IDs de personnages ne font que sélectionner des profils de maîtrise. Le test à 32 mappings passe par le même interpréteur ; aucun moteur par personnage ni import de Fighters.
- `ChakraRules` : conditions `all/any/none` sur source/target/surface/context/mastery, toolType ou minMastery ; ordre priority puis ID ; group exclusif pour éviter deux résultats de trajectoire concurrents. Effets whitelistés : scaleStat, tag, signal, redirect, reflect, embed, anchor. Aucune fonction/code string dans une config.
- `ChakraInteractions.new(cfg)` refuse Enabled=false. `spawn/surface/infuse/property/launch/trigger/inspect/reset` manipulent uniquement les données de l'instance. `trigger` résout sur copie et commit tous les résultats ensemble ; erreur/coût insuffisant conserve les objets. L'infusion recalcule les bases pour éviter le stacking accidentel ; son coût est payé à chaque demande explicite. Un snapshot retourné est une copie.
- `ChakraLab` active une copie de la config **uniquement pour le labo explicite**. Détecte collisions de sphères balayées et surfaces planes finies, trie les contacts, applique les résultats puis le reste du tick. Une interaction de mouvement par objet/tick ; les recontacts sont écartés tant que les proxies restent superposés. Cinématique sans gravité/rig/occlusion Roblox : réutiliser les règles, pas ces proxies pour remplacer la physique réelle.
- `ChakraStudioView/ChakraDev` : primitives de diagnostic, commandes, tick optionnel et nettoyage. Pas de touche, Remote ni vue chargée au lancement du jeu. Budgets bornés : 32 objets, 16 surfaces, 128 événements ; pas de catch-up infini après spike, temps écarté visible dans report.lab.discardedSeconds.
- `ChakraInputPlan.build(cfg,mode,intent,context)` : six propositions d'intention, retourne l'action existante sans l'envoyer ni la modifier. `requiresServerValidation=true`. Contexte fourni par un host serveur ; pas par le client. Comparaison et limites : [INPUT_OPTIONS.md](INPUT_OPTIONS.md).

Pour la prochaine passe : Claude choisit un seul test fun, crée l'adaptateur du vrai outil vers cette donnée, fournit contexte/maîtrise depuis l'état serveur et consomme les `effects/signals` dans les systèmes existants. Il décide des timings, animations, VFX, trajectoires permises et interactions disponibles. Avant toute intégration online, valider ownership, chakra réel, géométrie, cadence et unicité du contact côté serveur ; aucune propriété déclarée par un client ne fait autorité. Le labo n'est pas un protocole réseau ni un inventaire.
