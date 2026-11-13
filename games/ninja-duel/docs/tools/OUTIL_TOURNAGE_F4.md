> Guide technique (outils Studio, place FILM). État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md).

# Tournage F4 — l'assistant, le replay, le directeur

Demandé par le propriétaire le 13/11/2026 : un outil dans Studio pour que le CM tourne ses clips sans bug d'image, d'éclairage, de perso qui passe devant le plan ni de caméra, et qu'il se rende compte des erreurs qu'il fait. Revu le même jour après la relecture du CM (`claude/revue-outil-f4-par-le-cm-2026-11-13`).

Revu le 13/11 au soir après les demandes du CM (`claude/demandes-outilleur-prises-humain-2026-11-13`) : **une prise que F4 laisse passer doit être une prise que François ne rejette pas.** F4, le replay et le directeur jugent maintenant comme un spectateur (décor, ombre, taille, regard, course, image illisible), et le directeur choisit lui-même l'angle qui évite le défaut.

Tout est dans la place **FILM** seulement (`build.py --capture`, `ReplicatedStorage.NDFactory`). JEU, DEV et QA ne contiennent rien de tout ça (`tests/test_build_isolation.py`).

| Module | Rôle |
|---|---|
| `tools/capture/studio/ClipAssist.luau` | l'assistant **F4** : liste de contrôle, défauts en direct, prises, journal image par image ; chargé par `Client/DevClient` |
| `tools/capture/studio/NDReplay.luau` | le replay du CM (FILM08) : enregistrer un vrai match, le rejouer à n'importe quelle vitesse |
| `tools/capture/studio/NDDirector.luau` | ses caméras (`front`, `ots`, `best`, `pair`, `center`) et le programme de prises |
| `tools/capture/studio/ClipSight.luau` | les lignes de vue qui voient aussi les buissons et les corps du replay |
| `tools/capture/studio/ClipJudge.luau` | ce qu'un spectateur voit d'un perso (visage et corps cachés, ombre, regard, taille dans la bande, enceinte) et ce qui se passe dans un match (évènements, moments forts) ; partagé par F4, le replay et le directeur |
| `tools/capture/edit_list.py` | le meilleur plan de chaque scène, à partir de plusieurs prises, avec ce qu'on y voit |
| `tools/capture/sound_cues.py` | les sons du replay placés sur le rush d'un rendu au ralenti |

Aucun ne change le jeu.

## 1. L'assistant F4

**Ouvrir.** Dans `ND-FILM`, lance **Play** puis appuie sur **F4**, ou clique sur la pastille « 🎬 F4 ».

**Rien de F4 à l'écran pendant une prise** (demande 11). Dès REC, à l'image près, tout se cache : panneau, pastille, traits, repères. Le compteur d'images est coupé d'office (`counter` pour le remettre).

Hors prise :
- le panneau est dans la marge gauche ;
- deux traits verticaux sont posés à **24 points** de la bande 9:16 que garde OBS, en vert, orange ou rouge selon l'état de l'image ;
- les repères dans la bande (tiers ; en rouge pâle, la légende et les boutons de TikTok) ne s'affichent que panneau ouvert.

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
- cacher le curseur ;
- mettre la **lumière de tournage**, le préréglage F7 « midi » (soleil haut, demande 4). `Report:Invoke("preset","film")` en choisit un autre, `("preset",false)` n'y touche pas.

Il écrit aussi `workspace.NDWarmup` (l'heure), pour qu'un script de scène lance son préchauffage des effets. **« Rétablir »** remet l'écran comme avant, lumière comprise.

### En ce moment (15 fois par seconde)

Chaque ligne donne la gravité, à qui revient le défaut, depuis combien de temps il dure, et son identifiant (pour `ignore`).

Ce qu'un spectateur voit est mesuré sur **15 points** de chaque perso : 5 sur le visage, 4 sur le buste, les mains, les pieds et le bas des jambes. Les rayons voient le décor qu'on peut viser, les buissons et les cimes (`ClipSight`), l'autre corps, les clones et les effets, ceux du jeu comme ceux du replay.

| Id | À qui | Défaut | Gravité |
|---|---|---|---|
| `A:decor` | cadrage | Plus de **15 %** du visage ou du corps caché par le décor, buissons et feuillages compris (demande 1) | ERREUR s'il agit, sinon À VOIR |
| `A:hid` | cadrage | Caché par l'autre corps ou un clone : 60 % du visage ou du corps | ERREUR (40 % : À VOIR) |
| `A:noye` | cadrage | Noyé dans un effet : la moitié du corps sous le feu, le Chidori… | À VOIR |
| `A:illisible` | cadrage | Celui qui agit est avalé par un effet : 70 % du corps pendant 0,3 s (demande 6) | ERREUR |
| `illisible` | cadrage | Effets ou flash sur **70 %** de la bande pendant 0,3 s (40 rayons dans la bande, 5 fois par seconde) | ERREUR |
| `A:ombre` | cadrage | Visage ou corps à **60 %** à l'ombre d'un mur, d'un arbre, de la tribune ; ou caméra à contre-jour, du côté que le soleil n'éclaire pas (plus de 120° du soleil autour du perso) (demande 4) | ERREUR s'il agit et qu'il est à l'ombre, sinon À VOIR |
| `nuit` | réglage | Le soleil est couché | ERREUR |
| `A:small` | cadrage | Celui qui agit fait moins d'**un tiers** de la hauteur de la bande (demande 5) ; ERREUR pendant les 2 premières secondes | À VOIR / ERREUR |
| `small` | cadrage | Personne n'est connu pour agir et le plus grand fait moins d'un tiers | À VOIR / ERREUR |
| `A:regard` | scène | À portée (15 studs) ou en fonçant sur l'autre (8 studs/s vers lui), la tête et le buste sont à plus de **60°** de lui pendant 0,3 s ; ou il **regarde l'objectif** (moins de 15°), même de face (demande 2) | ERREUR s'il agit, sinon À VOIR |
| `A:course` | jeu | Il court à plus de 30 studs/s au sol sans la pose de sprint ninja (`MovementSprinting` éteint), ou **ses pieds glissent** : le pied d'appui va à plus de 60 % de la vitesse du corps pendant 0,3 s (demande 3). Ruée, poursuite, esquive et réactions ne comptent pas | À VOIR |
| `outside` | cadrage | La caméra est hors de l'enceinte (derrière le mur de l'arène) | ERREUR |
| `A:back` / `B:back` | cadrage | Le perso qui agit est filmé de dos (> 115°) | ERREUR |
| `A:out` | cadrage | Il agit hors de la bande ; ou celui qui reçoit sort du cadre | ERREUR / À VOIR |
| `A:top` | cadrage | Tête coupée en haut | À VOIR |
| `A:front` | cadrage | L'autre corps est au premier plan, à moins de 4,5 studs de l'objectif | À VOIR |
| `lens` | cadrage | Un corps, le décor ou un débris est collé à l'objectif | ERREUR |
| `insidecam` | cadrage | La caméra est dans un mur, un arbre ou un effet | ERREUR / À VOIR |
| `sun` | cadrage | La caméra est face au soleil | À VOIR |
| `jump` | cadrage | Saut de caméra que le mouvement des corps n'explique pas | À VOIR |
| `cuts` | cadrage | Deux coupes à moins de 0,5 s | À VOIR |
| `A:ui` | cadrage | Le visage est sous l'interface TikTok | INFO |
| `quality`, `dof`, `rays`, `shadows`, `hud`, `panelF6`, `panelF7`, `cursor` | réglage | voir « Avant de tourner » | ERREUR / À VOIR |
| `hitch`, `fps` | machine | Image figée (3 fois plus longue que la moyenne, ou plus de 0,1 s) ; Studio trop lent | ERREUR pendant une prise |
| `inside` | jeu | Corps l'un dans l'autre (moins de 1 stud pendant 0,4 s) | À VOIR |
| `flash:<perso>` | jeu | Un flash qui couvre tout le corps plus de 0,3 s, perso dans l'image | À VOIR |
| `error` | jeu | Erreur d'un script **du jeu** (`NinjaDuelClient`, `NinjaDuelServer`, `ReplicatedStorage.NinjaDuel`) ; les scripts de tournage, les commandes Studio et les plugins ne comptent pas | ERREUR |

Les alertes `light:` ont disparu (fausses pendant les jutsu et hors champ) : `A:ombre` les remplace.

**Qui agit.** Si `workspace.NDAct` vaut `"A"`, `"B"` ou `"AB"`, il décide. Le directeur l'écrit à chaque image d'après la scène. Un gros plan voulu sur l'un ne sort donc plus en erreur pour l'autre. Sinon, c'est l'état du duel qui décide : un perso agit pendant ses coups, ses jutsu, sa ruée, son esquive ou sa poursuite. **Dans un replay aussi** : le replay écrit l'état du duel sur ses fantômes (`NDState`, `NDReaction`, `NDHealth`…), F4 le lit.

**Rien n'est jugé hors de la phase Duel** : avant le duel, et après le K.O. quand le jeu passe au résultat (dans un replay, la phase est celle du fantôme). Pendant un rendu au ralenti (`workspace.NDSlow`), les durées (0,3 s, 2 premières secondes…) sont comptées en temps d'écran, une fois le rush accéléré.

Une ligne « jeu » part au DEV ou à l'ANIMATEUR, avec l'heure, la ligne `BUILD … @ commit` et la prise.

### Les prises

On démarre avec **● REC** quand OBS démarre, avec `Report:Invoke("rec","start","nom")`, ou en écrivant `workspace.NDRec = "nom"`. On arrête avec **■ STOP**, `("rec","stop")` ou `NDRec = nil`. Le directeur peut le faire seul (`P.f4 = true`).

À l'arrêt :
- **plages propres** de la prise (au moins **0,5 s** sans ERREUR ; `set` pour changer) et plages sans rien « à voir » ;
- **scène par scène** (`NDScene`, sinon `NDBeat` de ClipKit), avec la caméra (`NDShot`, sinon `NDTake`) : part propre, erreurs, temps de la prise et temps du replay (`NDClock`) ;
- **chaque défaut** avec son identifiant et ses plages exactes (`faults[].id`, `faults[].at`, `spans`, `events`) ;
- les coupes de caméra et les images figées ;
- la **ligne de temps de ce qui est vu** (demande 7), pour toute la prise (`timeline`) et pour chaque scène (`scenes[].timeline`). Une ligne par évènement du duel : qui frappe qui, quel jutsu, qui esquive, qui tombe, le K.O., les retournements. Chacune dit comment chaque perso est vu à cet instant (« vu », « de dos », « décor 40 % », « hors cadre », « petit ») et les effets dessinés dans la bande. Exemple : `1,25 s (replay 10,95) Sasuke lance Chidori — Sasuke vu · Kakashi vu, de dos · effets à l'image : Chidori`. Le CM écrit ses textes à partir de cette ligne. `Report:Invoke("timeline")` la donne en texte ;
- les **moments forts** de la prise (`moments`, voir la section 3) ;
- la même chose en une ligne `[NinjaDuelClip] {…}` dans Output.

Les écrans noirs entre deux scènes (`workspace.NDCut = true`, écrit par le directeur) ne sont pas jugés.

## 2. Le calage du rush et le journal image par image

**Pour caler un rush sur le journal**, sans rien de F4 à l'écran :
- dans un replay, le temps du replay (`st`, `NDClock`) de chaque image du journal suffit ;
- sinon, `Report:Invoke("syncFlash",true)` : à REC, un carré blanc s'affiche **2 images** dans le coin haut gauche de la bande. C'est le seul élément de F4 dans le rush, il se coupe au montage.

Le **compteur d'images** (coupé d'office) se remet avec `Report:Invoke("counter",true)`. Il est dans la marge droite, hors de la bande : un rush recadré par OBS ne le contient pas. Il affiche le numéro de l'image en chiffres et en **24 cases** : blanc = 1, bit de poids faible en premier, entre une case blanche et une case noire de garde. OBS le filme et CapCut le recadre hors de l'image. Sa position exacte (en points depuis le coin du viewport ; ×2 sur un écran Retina) est dans `Report:Invoke()` → `counter`.

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
  "A": { "head": [u,v], "face": [u,v], "eyes": [[u,v],[u,v]], "hands": [[u,v],[u,v]],
         "see": [0.8, 1],      part visible du visage, du corps
         "size": 0.41,         hauteur dans la bande
         "shade": [0, 0.2] },  part à l'ombre du visage, du corps (4 fois par seconde)
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
P.run(beats, 0.4)          -- rendu au quart de vitesse (P.slow) ; P.run(beats, 0.4, 1) : temps réel, avec le son
```

### Le directeur choisit l'angle (demandes 1, 4, 5, 9)

Avant REC, derrière l'écran noir, le directeur vérifie chaque segment toutes les **0,25 s** du replay, comme un spectateur : décor devant le visage ou le corps (buissons compris), corps devant, acteur de dos ou qui regarde l'objectif, caméra face au soleil ou à contre-jour, acteur de moins d'un tiers de la bande, objectif dans le décor ou hors de l'enceinte. Là où le plan écrit échoue, il coupe vers le meilleur angle autour de l'acteur (24 azimuts, le côté du soleil et l'angle `want` du CM préférés), avec des plans d'au moins 0,7 s. Output note chaque choix :

```
[NDDirector] 0.00–1.13 s : plan écrit (front)
[NDDirector] 1.13–2.40 s : angle choisi θ=45° — le plan écrit échouait à 1.25 s : décor 40 % (Bush12)
```

- `kind="auto"` : un segment dont le directeur choisit l'angle d'emblée (`p.a`, `p.d`, `p.h`, `p.fov`, `p.want` comptent).
- `p.lock=true` : garder le plan écrit tel quel.
- **Jamais plus large** : quel que soit le plan, la caméra avance pour que celui qui agit fasse au moins un tiers de la bande (`D.cfg.minShare`).
- **Jamais hors de l'enceinte** : la caméra est ramenée dans l'arène.
- Réglages : `D.cfg` (`auto`, `minShare`, `step`, `thetaStep`, `bad`, `minShot`, `sun`, `verbose`) ; le détail des choix : `D.planLog`.

### Le rendu au ralenti (demande 8)

`P.run` rend désormais au **quart de vitesse** par défaut (`P.slow = 0.25`). Le montage accélère ×4 : chaque image finale est une vraie image distincte, même quand Studio tombe à 25 i/s pendant le feu. Tout suit la vitesse : les fantômes, particules (`TimeScale`), traînées, faisceaux, lumières et tweens enregistrés, les paliers de vitesse des scènes, et maintenant les fondus (`ease`), le lissage de vitesse et les tenues (`hold`), comptés en temps d'écran.

- Une **image figée** (Studio qui gèle) n'avance le replay que de `P.maxStep` (1/30 s) : plus de saut après un gel.
- Un temps où une image a gelé est **rejoué une fois** (`P.retakes`), après un noir. F4 a les deux passages, `edit_list.py` garde le propre.
- Le rendu au ralenti est **muet**. Les sons se replacent au montage : `R.soundLog()` (l'heure de chaque son dans le replay), le journal F4 de la prise, puis :

```sh
python3 tools/capture/sound_cues.py frames.json sons.json --slow 0.25 > sons_places.json
```

Pour chaque son, il donne l'instant du rush et l'instant une fois accéléré, scène par scène.

### Les moments forts d'un vrai match (demande 10)

Le replay enregistre aussi **le duel lui-même** : l'état, la réaction, les PV et la technique de chaque perso, le K.O. (les messages du jeu à ce client).

```lua
print(R.highlightsText())          -- les moments forts, en texte
local h=R.highlights({n=4})        -- {score, perMinute, dead, moments={{from,to,score,lines}}}
local beats=D.beatsFromMoments(h)  -- un temps par moment, caméra sur celui qui mène l'action, angles choisis par le directeur
P.run(beats)
```

L'intensité compte : coups qui touchent (selon les PV perdus), réactions (au sol, projeté, mur…), jutsu préparés et lancés, esquives, ruées, parades, éveils, **retournements** (celui qui mène aux PV change) et le K.O. Les 3 ou 4 moments les plus forts sortent dans l'ordre réel, avec leurs lignes :

```
match · 41 évènements · intensité 186 (124 par minute) · temps morts 38 %
M1  4,10–8,85 s  (intensité 47)
     4,90 s  Sasuke attaque (Lion Combo)
     5,40 s  Sasuke frappe Kakashi (−12 PV)
     ...
```

Pour comparer plusieurs vrais matchs, garder `R.highlights()` de chacun et `R.rank({h1,h2,h3})` : le plus vivant d'abord (intensité par minute). F4 donne aussi les moments forts d'une prise jouée en direct (`moments` du résumé).

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

Chaque fichier contient le résumé d'une prise : la ligne `[NinjaDuelClip]` d'Output, ou `Report:Invoke()` → `last`. Pour chaque scène, dans l'ordre du programme, le script garde la prise qui en a le plus de temps propre, avec la ligne de temps de ce qu'on y voit. Il note aussi les autres prises, et signale les scènes propres à moins de 60 %.

## Pour les agents

```lua
local r=game.Players.LocalPlayer.PlayerGui.ClipAssistPanel.Report
print(r:Invoke())                         -- état JSON
r:Invoke("set",{clean=0.5,back=120})      -- un seuil (liste : thresholds dans l'état)
r:Invoke("ignore",{"A:inside","sun"})     -- ne plus signaler ces défauts ; r:Invoke("ignore") vide la liste
r:Invoke("show",true) ; r:Invoke("guides",false) ; r:Invoke("allowHud",true)
r:Invoke("timeline")                      -- ce qui est vu, en texte (prise en cours, dernière prise, ou les derniers évènements)
r:Invoke("preset","midi")                 -- la lumière de « Préparer l'image » ; false : ne pas y toucher
r:Invoke("syncFlash",true) ; r:Invoke("counter",true)
r:Invoke("linesDuringRec",true) ; r:Invoke("panelDuringRec",true)   -- contre la demande 11 : pour un essai seulement
```

L'état (`r:Invoke()`) donne aussi `phase`, `fxCover` (part de la bande sous les effets), `recent` (les derniers évènements vus) et `judge` (ClipJudge chargé).

Les attributs de `workspace` (`NDRec`, `NDAct`, `NDScene`, `NDShot`, `NDClock`, `NDCut`, `NDSlow`) se lisent quel que soit l'endroit d'où le script tourne. C'est pour ça qu'ils remplacent `_G`, qui n'est pas partagé entre la barre de commande, Studio MCP et les scripts du jeu.

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

## Version du 13/11 au soir (spectateur) : pas encore vue dans Studio

La seule place ouverte sur le Mac était celle du CM, en Play : pas de duel lancé à côté. Vérifié ici : la structure des fichiers Luau, les noms, `sound_cues.py`, les tests de build. **À vérifier au premier essai** : le chargement des modules, les seuils de `decor`, `ombre`, `regard`, `course` et `illisible` sur une vraie prise, le temps que prend le choix des angles avant REC, les moments forts d'un vrai match.

## Limites connues

- La qualité graphique se lit mal dans Studio : la déclarer avec `quality`.
- Les rayons visent 15 points par perso. Un doigt ou une mèche cachés peuvent passer inaperçus.
- L'ombre est mesurée par des rayons vers le soleil, pas sur l'image : Roblox ne donne pas les pixels à un script. Un visage éclairé par une lumière d'effet compte encore comme à l'ombre s'il est sous un arbre.
- Les particules ne se visent pas : `illisible` compte les pièces d'effet (boules, sphères, éclairs en maillage) et les flashs d'étalonnage, pas une nuée de particules seule.
- Les moments forts d'un replay viennent des messages du jeu au client : un replay enregistré depuis un autre client que celui du duel n'a pas l'état du duel (F4 retombe alors sur `NDAct`).
- Le recadrage CapCut doit rester dans la bande : les traits sont à 24 points, et cachés pendant une prise.
- Projet CapCut généré (demande B7 du CM) : **pas fait.** Les conditions de CapCut interdisent les scripts (boîte à outils du 05/11). C'est au propriétaire de trancher.
