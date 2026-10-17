> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Ajouter un combattant jouable — le chemin de code (DEC-015)

Ce guide décrit ce qu’il a réellement fallu toucher pour rendre Gaara (`Sand`) et Rock Lee (`Leaf`) jouables sur les systèmes partagés, sans copier un moteur de combat. La fiche de conception vient d’abord ([gabarit](FIGHTER_TEMPLATE.md), [vague du roster](ROSTER_WAVE_PLAN.md)) ; ce document est la liste d’intégration. Chaque étape a son test : un combattant n’est « jouable » qu’une fois sa suite dans `tests/run.sh` **et** dans `TEST_RUNNERS` de `build.py`.

## 1. Données partagées (`src/Shared`)

| Fichier | Ce qu’on ajoute | Exemple |
|---|---|---|
| `Fighters.luau` | L’entrée du combattant : nom, stats (santé, chakra, vitesses), `CombatStyle`, `Tool`, `AttackProfile` (multiplicateurs de startup/recovery/portée/dégâts par coup, `kind` de coup pour les réactions), `Techniques` (Id, coût, canal, actif, recovery, cooldown, `Interruptible`, `Mobile`/`Throw` pour un jutsu lancé en courant), `Awakening`, `Skin/Hair/Outfit`, et `Motion` (famille de mouvement, §3) | `Fighters.Leaf`, `Fighters.Sand` |
| `MoveGraphs.luau` | Les routes directionnelles (`routes.up/down/side`, `airUp/airDown/airSide`), `heavyAfterOne`, `stringCancels`, `onRoute`, `airFinisher`, et le style de réengagement `reengage` (vitesse, distance d’arrivée, angle, `recovery`, `chase`) | `MoveGraphs.Leaf.airFinisher` (Lotus) |
| `Attacks.luau` | Seulement les coups nouveaux (`move(startup, active, recovery, damage, travel, reaction, impulse, stun)`), leur zone (`zone`) et leur style de contact ; réutiliser d’abord les coups existants | `LeafRising`, `SandPillar` |

## 2. Serveur (`src/Server`)

- `Techniques.luau` : une table `Techniques.<Id>={check=…, execute=…}` par jutsu ; les règles d’éveil vivent dans `Techniques.awakenedHit` / `awakenedReact`.
- `Brawler.luau` / `Combat.luau` : n’y entrer que par des crochets courts (un `onRoute`, un mode de substitution, un `Tool` spécial). Ce sont les fichiers les plus disputés : un combattant ne doit jamais y dupliquer la machine à états.
- `AI.luau` : l’envie de réengager (`DASH[id]`, `CHASE[id]`) et l’usage de ses jutsus dans la boucle des techniques (une ligne `if spec.Id=="…" then use=… end`).
- `ChakraTuning.luau` : sa maîtrise de chakra (`T.CharacterMastery[id]`), ou un refus explicite et testé (Lee : taijutsu seul, pas de lame infusée).
- `World.luau` : son costume (`dress<Nom>`, branché dans `World.dress`). Matériaux plats (`SmoothPlastic`) : le tissage de `Fabric` a rendu les jambières de Lee comme du bois en Studio.

## 3. Client (`src/Client`)

- **Famille de mouvement** (`VelmoraMotionEngine.luau`) : `Fighters.<id>.Motion = {body=…, weapons=…, clips=…, intro=…, springy=…}`. `familyOf(id)` résout posture (`STANCE`), démarche (`GAIT`), clips (`CLIPS`), armes en main et intro ; un `CLIPS.<id>` peut hériter d’une autre famille par `setmetatable(…, {__index=CLIPS.Lion})`. Les traits d’éveil se déclarent dans la famille (`awakenPosture="curse"`), jamais en testant le corps d’un autre combattant.
- **Couche d’identité visuelle** : un module `src/Client/<Nom>FX.luau` avec `install(FX, kit)`, branché par une ligne à la fin d’`Effects.luau` (à côté de `SandFX` et `LeeFX`). Le module reçoit les helpers d’Effects (`new`, `block`, `tween`, `sound`, `flash`, `shockRing`, `burst`, `smokePuff`, `floorUnder`, `anchorPart`, `weldAll`, `num`, `seq`, `TEX`, `SOUND`, `BUILD`) et peut enregistrer :
  - des constructeurs de projectiles (`kit.BUILD[kind]`) et leur pose par image (`FX.poses[kind]`) ;
  - une couche `{impact=function(fx,impact,folder) … return true end, fighter=function(fx,model,actor,dt) … end}` dans `FX.layers` : `impact` dessine ses styles de contact (et peut reprendre `awaken`/`chase`/`afterimage` aux couleurs du combattant quand `impact.fighter` est le sien) ; `fighter` tourne à chaque image pour les deux combattants (`actor.opponentFighter` est renseigné).
- `UI.luau` : l’ajouter à `playable`.

## 3 bis. Corps supplémentaires (clones, marionnettes, invocations)

Un combattant à plusieurs corps n'ajoute pas d'acteur : `Server/Bodies` porte des corps légers (point au sol, contrôleur, durée, volume, dissipation en un coup) que `Combat` fait avancer, frapper et effacer. Données : `Fighters.<id>.Bodies[kind]={Max,Cost,Life,…}` ; une frappe portée par un corps se déclare dans `MoveGraphs.<id>.proxy[move]={move,body,summon,solo,awake}` et `Attacks[move].proxy` (où il se place : `behind`, `side`, `under`), elle est jugée depuis lui (`p.from`, `hitOrigin`). Le module du combattant enregistre ses contrôleurs (`Bodies.controllers[mode]`), ce que fait une dissipation (`Bodies.onDispel[kind]`), un outil qui devient un corps (`Bodies.transforms[kind]`, `ToolMastery.Transform`) et ses paiements de route (`Brawler.payoffs`) ; une technique peut préparer son canal (`technique.start`). Côté client, `Client/BodyViews` dessine chaque corps (un clone = copie posée du modèle du propriétaire) ; les fumées et effets vont dans la couche du combattant. Exemple : `Server/Legion.luau`, `Client/NarutoFX.luau`, `tests/Naruto.spec.luau`.

## 4. Tests et build

- Une suite `tests/<Nom>.spec.luau` : règles du kit, IA (duels seedés contre chaque combattant, jusqu’au KO, sans blocage d’un même état > 2,5 s), et un test client sur scène simulée (`Harness.stubScene()` : projectiles dessinés avec le bon modèle, chaque style de contact dessiné, couche par image). Exemples : la fin de `Gaara.spec.luau`, `Lee.spec.luau`.
- Inscrire la suite dans `tests/run.sh` et `TEST_RUNNERS` (`build.py`), reconstruire les trois places, lancer isolation / docs / architecture.

## 5. Vérification native (Studio, place Debug)

Probes de `tools/studio/probes` : `staged_moment.luau` (une action à une distance donnée), `fx_freeze.luau` (copie figée d’un effet + caméra latérale), `ai_soak.luau` (IA contre IA, erreurs de la console), `seqrec.luau` avec les outils `user_keyboard_input` / `user_mouse_input` (vraies touches et clics). Un combattant passe en « jouable » quand son menu, ses coups, ses effets et un soak sans erreur ont été vus dans Studio ; le ressenti reste une acceptation humaine.
