> Guide technique (outil Studio, place FILM). État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md).

# Assistant de tournage F4 — pour filmer sans défaut et voir ses erreurs

Demandé par le propriétaire le 13/11/2026 : un outil dans Studio pour que le CM tourne ses clips sans bug d'image, d'éclairage, de perso qui passe devant le plan ni de caméra, et qu'il se rende compte des erreurs qu'il fait.

Module : `tools/capture/studio/ClipAssist.luau`. Il est seulement dans la place **FILM** (`build.py --capture`, `ReplicatedStorage.NDFactory.ClipAssist`). `Client/DevClient` le charge quand il le trouve. Les places JEU, DEV et QA ne le contiennent pas, ce que vérifie `tests/test_build_isolation.py`.

L'outil ne change pas le jeu. Il lit la caméra, les deux corps, la lumière et l'écran. Le bouton « Préparer l'image » ne touche que cet écran.

## Utilisation

Ouvre `PLACES/ND-FILM.rbxlx`, lance **Play**, puis appuie sur **F4** (ou clique sur la pastille « 🎬 F4 » en haut à gauche).

- **La bande 9:16.** Deux traits verticaux sont posés juste à l'extérieur de la bande que garde OBS (la même que ClipKit). Leur couleur donne l'état de l'image : **vert** rien à signaler, **orange** à voir, **rouge** erreur. Ils restent hors de l'image recadrée.
- **Le panneau** est dans la marge gauche, hors de la bande. Si la fenêtre est trop étroite pour lui, il le dit et se cache pendant une prise.
- **Les repères dans la bande** se cachent pendant une prise :
  - les tiers ;
  - en rouge pâle, les zones que TikTok et Shorts couvrent : la légende en bas, les boutons à droite.

### 1. Avant de tourner (vérifié tout seul)

| Point | Pourquoi |
|---|---|
| Combat trouvé | Sans les deux corps, rien ne peut être vérifié |
| Qualité graphique fixe | En « Automatique », Roblox retire les particules quand le Mac rame (lot 3 animation, 08/11) |
| Image fluide (≥ 55 i/s) | Studio en arrière-plan tombe à 15 i/s (FILM05) |
| Profondeur de champ coupée | Elle fait saccader la prise (FILM01, FILM02) |
| Rayons du soleil coupés | Éblouissement (FILM07) |
| Ombres allumées | Réglage validé du 12/11 |
| HUD du jeu hors de l'image | Sauf prise de preuve voulue : `allowHud` |
| Panneaux F6 / F7 fermés | Ils couvriraient la bande |
| Curseur hors de l'image | OBS filme le curseur |

**« Préparer l'image »** fait tout ce qui se règle d'un clic :
- cacher le HUD et l'interface Roblox ;
- fermer F6 et F7 ;
- couper la profondeur de champ et les rayons du soleil ;
- cacher le curseur.

**« Rétablir »** remet l'écran comme avant. La qualité graphique se règle à la main, dans les réglages de Studio.

Les points que l'outil ne peut pas voir sont rappelés en bas du panneau :
- une prise par enregistrement OBS ;
- OBS sur un autre bureau ;
- un clic sur la barre de titre de Studio avant de lancer ;
- aucune autre place en Play ;
- OBS à 30 i/s ;
- personne ne touche le Mac pendant la prise.

### 2. En ce moment (vérifié 15 fois par seconde)

Chaque défaut porte une gravité (**ERREUR**, **À VOIR**, **INFO**) et dit à qui il revient :

| À qui | Défaut | Gravité |
|---|---|---|
| cadrage | Le perso qui agit est filmé **de dos** (plus de 115° entre son regard et la caméra) | ERREUR |
| cadrage | Il est **caché** par l'autre corps, un clone ou le décor (arbre, mur) | ERREUR (à moitié caché : À VOIR) |
| cadrage | On ne voit pas ses mains : le geste est caché | À VOIR |
| cadrage | Il agit **hors de la bande 9:16** ; ou l'autre, qui reçoit, sort du cadre | ERREUR / À VOIR |
| cadrage | Tête coupée en haut | À VOIR |
| cadrage | **Persos trop petits** : moins de 18 % de la hauteur. Pendant les 2 premières secondes d'une prise, c'est une ERREUR (`retention-ce-qui-retient`, 13/11) | À VOIR / ERREUR |
| cadrage | Un corps, le décor ou un débris **collé à l'objectif** (image bouchée) | ERREUR |
| cadrage | La caméra est **dans** un mur, un arbre ou un effet | ERREUR / À VOIR |
| cadrage | La caméra est **face au soleil** | À VOIR |
| cadrage | **Saut de caméra** dans un plan ; **deux coupes** à moins de 0,5 s | À VOIR |
| cadrage | Le visage du perso qui agit est sous l'interface TikTok | INFO |
| réglage | Qualité Automatique, profondeur de champ, panneau F6/F7 dans l'image | ERREUR |
| réglage | Rayons du soleil, ombres coupées, HUD ou curseur dans l'image | À VOIR |
| machine | **Image figée** (une image beaucoup plus longue que les autres) ; Studio sous 50 i/s | ERREUR pendant une prise |
| jeu | Corps l'un dans l'autre ; **lumière colorée** forte qui teinte un perso (le Kakashi rose du FILM04) ; flash plein corps qui dure ; erreur de script | À VOIR / ERREUR |

**Qui agit.** L'outil le lit dans l'état du duel : un perso agit pendant ses coups, ses jutsu, sa ruée, son esquive ou sa poursuite, pas quand il encaisse. Dans un replay sans duel, c'est le script qui le dit (`acting`). À défaut, les deux persos sont surveillés en « À VOIR ».

Une ligne « jeu » est un défaut du jeu. Elle se signale au DEV ou à l'ANIMATEUR, avec l'heure, la ligne `BUILD … @ commit` et la prise, et on ne la contourne pas.

### 3. La prise : ● REC / ■ STOP

Appuie sur **● REC** au moment où OBS démarre, et sur **■ STOP** à l'arrêt. Chaque défaut est noté avec son temps depuis le début de la prise. À l'arrêt, la section « Dernière prise » donne :
- les **plages propres** (au moins 1 s sans ERREUR) : ce sont elles qu'on monte ;
- les plages sans rien « à voir » ;
- chaque défaut, avec sa durée totale et ses premiers moments (« à 2,4, 7,9 s ») ;
- les coupes de caméra (utile pour le montage) et le nombre d'images figées.

La même chose part dans Output en une ligne `[NinjaDuelClip] {…}` (JSON), à joindre à un bug ou à la fiche du clip. Un temps de prise est compté depuis REC : si OBS a démarré un peu avant, ajoute ce décalage pour retrouver le temps du rush.

### 4. Plan vu du dessus

Le plan montre A en bleu, B en rouge et la caméra en blanc, avec un trait pour le regard et l'angle de la bande. Le soleil est en jaune, au bord. On y voit d'un coup d'œil de quel côté est le visage du perso qui agit, et où est le soleil par rapport à l'objectif.

## Pour les agents (Studio MCP, côté Client, pendant le Play)

```lua
local r=game.Players.LocalPlayer.PlayerGui.ClipAssistPanel.Report
print(r:Invoke())                 -- état JSON : liste de contrôle, défauts en cours, dernière prise
r:Invoke("prepare")               -- prépare l'image ; r:Invoke("restore") la rétablit
r:Invoke("rec","start","M1 Sasuke-Kakashi")  -- au moment où OBS démarre
print(r:Invoke("rec","stop"))     -- résumé : last.clean = plages propres
r:Invoke("actors",{a,b})          -- replay : les deux corps à suivre (nil = le duel)
r:Invoke("acting","A")            -- replay : qui agit ("A", "B", "AB" ; nil = lu dans le duel)
r:Invoke("show",true)             -- panneau visible ou non
r:Invoke("guides",false)          -- repères dans la bande
r:Invoke("allowHud",true)         -- prise où le HUD est voulu
```

Les scripts du même client (le directeur de replay, par exemple) peuvent aussi passer par `_G.NDClipAssist` : `startTake`, `stopTake`, `prepare`, `restore`, `snapshot`.

## Limites connues

- **État :** l'outil n'a **pas encore été vu dans Studio**. Le Mac n'était pas relié le 13/11. Les seuils (115°, 18 %, 2,2 studs, 35°) sont à recaler au premier tournage.
- **Les rayons** de visibilité visent le centre de la tête, du torse et des mains. Un bras qui passe devant un visage peut ne pas être vu.
- **Les buissons sans collision ni requête** (`CanQuery` coupé) sont invisibles pour les rayons, comme pour le replay du FILM08.
- **La qualité graphique** se lit, mais ne se change pas depuis un script.
- **Le temps de la prise** part de REC, pas d'OBS.
- **Le recadrage d'OBS** doit suivre la bande (les deux traits). Si le recadrage est plus large, les traits entrent dans l'image.
