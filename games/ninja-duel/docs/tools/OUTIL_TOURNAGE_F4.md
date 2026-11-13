> Guide technique (outils Studio, place FILM). État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md).

# Tournage F4 — l'assistant, le replay, le directeur

Demandé par le propriétaire le 13/11/2026 : un outil dans Studio pour que le CM tourne ses clips sans bug d'image, d'éclairage, de perso qui passe devant le plan ni de caméra, et qu'il se rende compte des erreurs qu'il fait. Revu le même jour après la relecture du CM (`claude/revue-outil-f4-par-le-cm-2026-11-13`).

Tout est dans la place **FILM** seulement (`build.py --capture`, `ReplicatedStorage.NDFactory`). JEU, DEV et QA ne contiennent rien de tout ça (`tests/test_build_isolation.py`).

| Module | Rôle |
|---|---|
| `tools/capture/studio/ClipAssist.luau` | l'assistant **F4** : liste de contrôle, défauts en direct, prises, journal image par image ; chargé par `Client/DevClient` |
| `tools/capture/studio/NDReplay.luau` | le replay du CM (FILM08) : enregistrer un vrai match, le rejouer à n'importe quelle vitesse |
| `tools/capture/studio/NDDirector.luau` | ses caméras (`front`, `ots`, `best`, `pair`, `center`) et le programme de prises |
| `tools/capture/studio/ClipSight.luau` | les lignes de vue qui voient aussi les buissons et les corps du replay |
| `tools/capture/edit_list.py` | le meilleur plan de chaque scène, à partir de plusieurs prises |

Aucun ne change le jeu.

## 1. L'assistant F4

**Ouvrir.** Dans `ND-FILM`, lance **Play** puis appuie sur **F4**, ou clique sur la pastille « 🎬 F4 ».

**Rien n'entre dans l'image.** L'assistant ne dessine jamais dans la bande 9:16 que garde OBS (la même que ClipKit) :
- le panneau est dans la marge gauche ;
- le **compteur d'images** est dans la marge droite (voir la section 2) ;
- deux traits verticaux sont posés à **24 points** de la bande, en vert, orange ou rouge selon l'état de l'image. Ils se cachent pendant une prise (`linesDuringRec` pour les garder) ;
- les repères dans la bande (tiers ; en rouge pâle, la légende et les boutons de TikTok) se cachent aussi pendant une prise.

L'assistant est au-dessus de l'écran noir du directeur.

### Avant de tourner

La liste se coche toute seule :

| Point | Pourquoi |
|---|---|
| Combat trouvé | Les deux corps du duel, ou ceux qu'on donne pour un replay |
| Qualité graphique fixe | En « Automatique », Roblox retire des particules quand le Mac rame. Dans Studio, la lecture peut répondre « Automatique » à tort : `Report:Invoke("quality",12)` déclare le niveau réglé |
| Image fluide | Sous 32 i/s pendant une prise : ERREUR (une vidéo à 30 i/s en a besoin). Sous 50 : À VOIR |
| Profondeur de champ coupée, rayons du soleil coupés, ombres allumées | Saccades, éblouissement, réglage validé du 12/11 |
| HUD, panneaux F6 / F7, curseur hors de l'image | Ils seraient filmés |

**« Préparer l'image »** fait tout ce qui se règle d'un clic, sur cet écran seulement :
- cacher le HUD et l'interface Roblox ;
- fermer F6 et F7 ;
- couper la profondeur de champ et les rayons du soleil ;
- cacher le curseur.

Il écrit aussi `workspace.NDWarmup` (l'heure), pour qu'un script de scène lance son préchauffage des effets. **« Rétablir »** remet l'écran comme avant.

### En ce moment (15 fois par seconde)

Chaque ligne donne la gravité, à qui revient le défaut, depuis combien de temps il dure, et son identifiant (pour `ignore`).

| Id | À qui | Défaut | Gravité |
|---|---|---|---|
| `A:back` / `B:back` | cadrage | Le perso qui agit est filmé de dos (> 115°) | ERREUR |
| `A:hid` | cadrage | Il est caché par l'autre corps, un clone (vivant ou du replay), le décor ou un buisson | ERREUR (à moitié caché : À VOIR) |
| `A:hands` | cadrage | Ses mains sont cachées | À VOIR |
| `A:out` | cadrage | Il agit hors de la bande ; ou celui qui reçoit sort du cadre | ERREUR / À VOIR |
| `A:top` | cadrage | Tête coupée en haut | À VOIR |
| `A:front` | cadrage | L'autre corps est au premier plan, à moins de 4,5 studs de l'objectif | À VOIR |
| `small` | cadrage | Les deux persos font moins de 18 % de la hauteur ; ERREUR pendant les 2 premières secondes d'une prise | À VOIR / ERREUR |
| `lens` | cadrage | Un corps, le décor ou un débris est collé à l'objectif | ERREUR |
| `insidecam` | cadrage | La caméra est dans un mur, un arbre ou un effet | ERREUR / À VOIR |
| `sun` | cadrage | La caméra est face au soleil | À VOIR |
| `jump` | cadrage | Saut de caméra que le mouvement des corps n'explique pas | À VOIR |
| `cuts` | cadrage | Deux coupes à moins de 0,5 s | À VOIR |
| `A:ui` | cadrage | Le visage est sous l'interface TikTok | INFO |
| `quality`, `dof`, `rays`, `shadows`, `hud`, `panelF6`, `panelF7`, `cursor` | réglage | voir « Avant de tourner » | ERREUR / À VOIR |
| `hitch`, `fps` | machine | Image figée (3 fois plus longue que la moyenne, ou plus de 0,1 s) ; Studio trop lent | ERREUR pendant une prise |
| `inside` | jeu | Corps l'un dans l'autre (moins de 1 stud pendant 0,4 s) | À VOIR |
| `light:<perso>` | jeu | Lumière colorée qui **reste** sur un perso : plus de 1,5 s pour une lumière portée par le corps (le Kakashi rose du FILM04), plus de 4 s pour celle d'une technique. Les flashs du Chidori, du Sharingan et du feu ne comptent pas | À VOIR |
| `flash:<perso>` | jeu | Un flash qui couvre tout le corps plus de 0,3 s | À VOIR |
| `error` | jeu | Erreur d'un script **du jeu** (`NinjaDuelClient`, `NinjaDuelServer`, `ReplicatedStorage.NinjaDuel`) ; les scripts de tournage, les commandes Studio et les plugins ne comptent pas | ERREUR |

**Qui agit.** Si `workspace.NDAct` vaut `"A"`, `"B"` ou `"AB"`, il décide. Le directeur l'écrit à chaque image d'après la scène. Un gros plan voulu sur l'un ne sort donc plus en erreur pour l'autre. Sinon, c'est l'état du duel qui décide : un perso agit pendant ses coups, ses jutsu, sa ruée, son esquive ou sa poursuite. Dans un replay sans `NDAct`, les deux persos sont surveillés en « À VOIR ».

Une ligne « jeu » part au DEV ou à l'ANIMATEUR, avec l'heure, la ligne `BUILD … @ commit` et la prise.

### Les prises

On démarre avec **● REC** quand OBS démarre, avec `Report:Invoke("rec","start","nom")`, ou en écrivant `workspace.NDRec = "nom"`. On arrête avec **■ STOP**, `("rec","stop")` ou `NDRec = nil`. Le directeur peut le faire seul (`P.f4 = true`).

À l'arrêt :
- **plages propres** de la prise (au moins **0,5 s** sans ERREUR ; `set` pour changer) et plages sans rien « à voir » ;
- **scène par scène** (`NDScene`, sinon `NDBeat` de ClipKit), avec la caméra (`NDShot`, sinon `NDTake`) : part propre, erreurs, temps de la prise et temps du replay (`NDClock`) ;
- **chaque défaut** avec ses plages exactes (`faults[].at`, `spans`, `events`) ;
- les coupes de caméra et les images figées ;
- la même chose en une ligne `[NinjaDuelClip] {…}` dans Output.

Les écrans noirs entre deux scènes (`workspace.NDCut = true`, écrit par le directeur) ne sont pas jugés.

## 2. Le compteur d'images et le journal image par image

Le **compteur** est dans la marge droite, visible pendant une prise et quand le panneau est ouvert. Il affiche le numéro de l'image en chiffres et en **24 cases** : blanc = 1, bit de poids faible en premier, entre une case blanche et une case noire de garde. OBS le filme et CapCut le recadre hors de l'image. Sa position exacte (en points depuis le coin du viewport ; ×2 sur un écran Retina) est dans `Report:Invoke()` → `counter`.

Le compteur sert à deux choses :
- **caler le rush sur le journal**, à l'image près ;
- **distinguer deux pannes.** Si un numéro reste sur plusieurs images du rush, Studio a rendu une image trop longue. Si un numéro manque, OBS a perdu une image.

Le **journal** se lit par morceaux : `Report:Invoke("frames",{from=1,count=600})`. Une entrée par image rendue pendant la prise :

```
{ "f": 1146,                 numéro de l'image (= le compteur)
  "w": 0.653,  "dt": 0.017,  temps depuis REC, durée de l'image
  "st": 1.25,                temps du replay (NDClock), si un replay tourne
  "scene": "S1", "shot": "T1", "act": "A", "black": true (écran noir)
  "cam": [x, y, z, lookX, lookY, lookZ, fov],
  "def": ["A:back", ...],    défauts ouverts (À VOIR et plus)
  "A": { "head": [u,v], "face": [u,v], "eyes": [[u,v],[u,v]], "hands": [[u,v],[u,v]] },
  "B": { ... } }
```

`u` et `v` sont donnés **dans la bande 9:16** : 0 à 1 de gauche à droite et de haut en bas, hors de cette plage hors du cadre, `false` derrière la caméra. Les yeux viennent des pièces `FaceEye` du personnage.

C'est de quoi poser par code la **loupe** sur le Sharingan (elle suit l'œil), ou placer textes et miniatures sans couvrir un visage.

## 3. Le replay et le directeur (outils du CM, FILM08, maintenant dans le dépôt)

```lua
local F=game.ReplicatedStorage.NDFactory
local R=require(F.NDReplay); local D=require(F.NDDirector); local P=shared.NDP
R.start({human=duel.PlayerFighter, bot=duel.AIFighter}, {workspace.NinjaDuelFX, workspace.NinjaDuelBodies, workspace.WorldMemory})
-- ... le vrai match se joue ...
R.stop(); R.prepare(); R.hideLive({workspace.NinjaDuels}); R.folder.Parent=workspace
local r=game.Players.LocalPlayer.PlayerGui.ClipAssistPanel.Report
r:Invoke("actors",{R.ghostFighter("human"), R.ghostFighter("bot")},{"Sasuke","Kakashi"})
P.f4=true; P.shot="T1"
P.run(beats, 0.4)          -- ou P.run(beats, 0.4, 0.25) : rendu au quart de vitesse
```

Ce qui a changé par rapport au FILM08 :
- **Une seule performance, autant de caméras qu'on veut.** On rejoue le même programme avec une autre carte de plans (`P.shot = "T2"`, d'autres `segs`). Chaque passage fait sa prise F4, puis `edit_list.py` choisit le meilleur plan de chaque scène.
- **Les sons.** Chaque son qui part est noté : instant, id, volume, vitesse et lieu. Le replay les rejoue à vitesse normale. En dessous de 0,9 il se tait, et `R.soundLog()` donne la liste au montage, en secondes depuis le début de l'enregistrement.
- **Les gerbes de particules (`Emit`).** Un émetteur qui écrit `NDEmit` (l'heure) et `NDEmitCount` (le nombre) après `Emit()` est rejoué exactement. Les autres émetteurs nés éteints font une gerbe de `R.emitDefault` (12) à leur apparition. Demande à l'ANIMATEUR : ajouter cette ligne dans les assistants d'émission (`VfxKit`, `Effects`, `SandFX`, `AwakenFX`, `ChakraFlowFX`).
- **Le ralenti.** `P.run(beats, gap, 0.25)` rejoue tout le programme au quart de la vitesse : particules (`TimeScale`), traînées, textures des faisceaux et paliers de vitesse des scènes compris. Le montage accélère ×4 : chaque image finale est une vraie image distincte. Un Mac qui rame met plus de temps, mais ne saccade pas.
- **Les buissons.** Les rayons des caméras `best`, `pair` et `ots` voient maintenant les buissons et les cimes (`ClipSight`). Une caméra n'est plus placée dans un buisson.
- **Les informations pour F4.** Le programme écrit `NDScene`, `NDShot`, `NDAct` (le `act` de la scène, sinon le perso du segment), `NDClock` et `NDCut` pendant les noirs.

Exemple de scène (FILM08) :

```lua
{name="B_chidori", a=9.9, b=12.8, act="A", speeds={{9.9,1},{10.95,0.35},{11.55,1}},
 segs={{from=9.9,to=10.85,kind="front",p={a="human",yaw=25,d=9,h=1.5,lookh=1.0,fov=50}},
       {from=10.85,to=11.6,kind="ots",p={a="human",back=5,off=3,h=2,lookh=1.0,fov=55}},
       {from=11.6,to=99,kind="best",p={a="bot",d=10,h=1.8,want=40,lookh=0.8,fov=52}}}}
```

## 4. Le meilleur plan de chaque scène

```sh
python3 tools/capture/edit_list.py prise_T1.json prise_T2.json prise_T3.json > montage.json
```

Chaque fichier contient le résumé d'une prise : la ligne `[NinjaDuelClip]` d'Output, ou `Report:Invoke()` → `last`. Pour chaque scène, dans l'ordre du programme, le script garde la prise qui en a le plus de temps propre. Il note aussi les autres prises, et signale les scènes propres à moins de 60 %.

## Pour les agents

```lua
local r=game.Players.LocalPlayer.PlayerGui.ClipAssistPanel.Report
print(r:Invoke())                         -- état JSON
r:Invoke("set",{clean=0.5,back=120})      -- un seuil (liste : thresholds dans l'état)
r:Invoke("ignore",{"A:inside","sun"})     -- ne plus signaler ces défauts ; r:Invoke("ignore") vide la liste
r:Invoke("show",true) ; r:Invoke("guides",false) ; r:Invoke("allowHud",true) ; r:Invoke("counter",false) ; r:Invoke("linesDuringRec",true)
```

Les attributs de `workspace` (`NDRec`, `NDAct`, `NDScene`, `NDShot`, `NDClock`, `NDCut`) se lisent quel que soit l'endroit d'où le script tourne. C'est pour ça qu'ils remplacent `_G`, qui n'est pas partagé entre la barre de commande, Studio MCP et les scripts du jeu.

## Vu dans Studio (13/11, place d'essai `LAB/repro/ND-F4-essai.rbxlx`)

- Le module se charge.
- Duel IA contre IA Sasuke–Kakashi, caméra du jeu : les défauts sortent avec les bons noms. Exemples : « Sasuke filmé de dos » (normal, la caméra du jeu est derrière le joueur), « Kakashi caché par le corps de Sasuke ».
- « Préparer l'image » coupe bien la profondeur de champ et les rayons, et cache HUD et curseur.
- Le replay enregistre 9 s (38 à 93 sons, 16 à 21 émetteurs à gerbes). Le programme à deux scènes rejoué avec deux cartes (T1, T2) donne deux prises F4 avec leurs scènes, et le journal donne les yeux et les mains.
- **Pas vérifié** :
  - les seuils sur une vraie prise à 60 i/s : Studio était en arrière-plan (14 i/s), donc toute la prise était rouge, à raison ;
  - le son rejoué à l'oreille ;
  - le rendu au quart de vitesse filmé ;
  - le décodage du compteur dans un rush.

## Limites connues

- La qualité graphique se lit mal dans Studio : la déclarer avec `quality`.
- Les rayons visent le centre de la tête, du torse et des mains. Un bras devant un visage peut passer inaperçu.
- Le recadrage CapCut doit rester dans la bande : les traits sont à 24 points, et cachés pendant une prise.
- Projet CapCut généré (demande B7 du CM) : **pas fait.** Les conditions de CapCut interdisent les scripts (boîte à outils du 05/11). C'est au propriétaire de trancher.
