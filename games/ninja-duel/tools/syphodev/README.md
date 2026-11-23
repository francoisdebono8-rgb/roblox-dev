# tools/syphodev : la route d'animation de SyphoDev sur le squelette du jeu

Le guide complet est dans [docs/tools/METHODE_SYPHODEV.md](../../docs/tools/METHODE_SYPHODEV.md). Ici, seulement les commandes,
depuis `games/ninja-duel`, après `bash ../../tools/syphodev/setup_cloud.sh` :

```bash
S=../../.claude/skills/roblox-animation/scripts
lune run tools/syphodev/rig_dump.luau tools/syphodev/rig.json          # World.RIG -> rig.json (vérifié par tests/run.sh)
blender --background --python-exit-code 1 --python tools/syphodev/make_parts.py -- tools/syphodev/rig.json work/anim/parts
# chiffres (0,7 s) : pieds, glissement d'appui, mains dans le corps, position des poings -> report.json
blender --background --python-exit-code 1 --python $S/r6_clip.py -- --rig tools/syphodev/rig.json \
    --glb-dir work/anim/parts --clip tools/syphodev/examples/cross.json --outdir work/anim/cross --no-render
# images : même commande sans --no-render, de préférence sur le Mac (MCP Blender, 15 s pour 32 images)
ffmpeg -start_number 0 -i work/anim/cross/side_%03d.png -vf "scale=150:-1,tile=8x2" work/anim/cross_sheet.png
python3 tools/syphodev/to_authored.py tools/syphodev/rig.json work/anim/clips.json work/anim/cross/resolved.json
```

Le JSON produit a le format de `tools/blender/nd_io.export`. L'ANIMATEUR le passe à
`tools/blender/clips_to_luau.py` avec ses autres exports, car les `AuthoredClips` sont à lui.

Sur le Mac, les fichiers de travail sont dans `~/Documents/NinjaDuel/LAB/syphodev/`. Les
scripts du skill vont dans `skill-scripts/`, ce dossier dans `nd/` et les rendus dans
`anim/`. Le rendu se lance par le MCP Blender (`execute_blender_code_for_cli`), qui démarre
un second Blender avec la même ligne de commande.

## Deux squelettes : choisir celui sur lequel le clip sera joué

- `rig.json` est `World.RIG`, le squelette des avatars des joueurs (AvatarBody). `tests/run.sh`
  le garde égal au jeu.
- `rig_prodigy.json` est le corps d'un prodige tel que le jeu le construit, **lu dans Studio**
  comme le fait SyphoDev. `Looks.form` y resserre les épaules (C0 x ±0,84 au lieu de ±1,05) et
  y monte la tête (Neck C0 y 1,05 au lieu de 0,9). Il faut le relire si `Looks.form` change :
  lancer `studio_rig.luau` sur le serveur d'un Play après la preuve ci-dessous, puis
  `python3 tools/syphodev/rig_from_studio.py sortie.json tools/syphodev/rig.json > tools/syphodev/rig_prodigy.json`.

## Preuve dans Studio (étapes 10 et 11 de la vidéo)

```bash
python3 tools/syphodev/studio_parity.py luau tools/syphodev/rig_prodigy.json work/anim/clips.json SyphoDemo.Cross 0 2 4 6 8 10 11 13 15 > proof.luau
# proof.luau s'exécute par le MCP (execute_luau, datamodel Server, en Play). Il construit un vrai
# combattant (World.rig), passe le clip au décodeur du jeu (AuthoredMotion), écrit les
# Motor6D.Transform et relit chaque partie. On enregistre sa sortie JSON, puis :
python3 tools/syphodev/studio_parity.py check tools/syphodev/rig_prodigy.json work/anim/clips.json SyphoDemo.Cross studio.json
```

Résultat du 19/11 sur un prodige, pour le direct du droit : durée 0,5 s (= la durée d'auteur),
pièces à **0,000057 stud au pire** du calcul, sur 9 images. Contre `rig.json`, la même mesure
donnait **0,21 stud** : c'est ainsi que l'écart de `Looks.form` a été trouvé.

## Le jeu actuel au contrôle (19/11 au soir)

François, le 19/11 : appliquer la méthode à tout ce qui est déjà dans le jeu, et adapter ce qui
ne passe pas. Les résultats sont au § 15 de [METHODE_SYPHODEV](../../docs/tools/METHODE_SYPHODEV.md).

```bash
# Animations : les 862 clips posés sur le squelette, image par image (dans tests/run.sh : SyphoClips)
LUNE=... python3 tools/syphodev/audit_clips.py --gate          # échoue si une boucle ou un saut d'une image revient
LUNE=... python3 tools/syphodev/audit_clips.py                 # rapport complet : sol, glissement, mains dans le corps
# clip_passes.py tourne seul dans tools/blender/clips_to_luau.py à chaque export (ND_NO_FILM=1 le coupe)

# Konoha au prouveur de carte (roblox-map) : environ 11 min à 4 studs, 2 min 30 à 8 (RES=8)
lune run tools/syphodev/konoha_dump.luau work/map/konoha.json       # le village que Hub.build construit
python3 tools/syphodev/konoha_spec.py work/map/konoha.json work/map/konoha_spec.json
python3 tools/syphodev/konoha_prove.py work/map/konoha_spec.json work/map/konoha_report.json > work/map/konoha_report.txt
```

`konoha_prove.py` lance le prouveur du skill sans le modifier. Il ajoute seulement un index
spatial à deux de ses boucles : le prouveur seul n'avait pas fini après 14 minutes sur 711 pièces.
Le profil de marche est `konoha_profile.json` : gravité 140, marche 16, course 36, saut 56 et
second saut 54 (`HubClient`). Depuis le 22/11, il contient aussi la course sur les murs
(`abilities.wallClimb`, 36 studs : `Client/HubMove`, CLIMB 38 pendant 0,95 s). Le prouveur s'en
sert dans sa passe large : un toit marqué « only via the generous envelope » est donc un toit où
il faut courir sur le mur (ou sauter en courant).

### Sans lune dans la session (OUTILLEUR, 21-22/11)

```bash
# le plan seul, maisons comprises comme toits à atteindre : à pied / avec élan / jamais, et les maisons dans les murs
python3 tools/syphodev/konoha_plan_roofs.py work/map/plan
# le village construit : le dump se fait sur GitHub, sur une branche de travail (jamais la branche commune)
python3 tools/syphodev/ci_dump.py --fetch <run id> work/map/konoha.json      # le mode d'emploi est en tête du fichier
```

**Plus rapide (23/11, étape 4).** Depuis que le profil a la course sur le mur, le passage large cherchait un
mur à côté de chaque saut trop court, pour chaque paire de points : plus de 15 minutes sur le village
généré. `konoha_prove.py` cherche maintenant ce mur une fois par point et ne teste que les pièces sous le
rayon (la grille `geom.BoxIndex`). Les réponses sont les mêmes : sur le village du 22/11, le rapport est
identique octet pour octet, en 6 s au lieu de 527 s (résolution 8).

Le 23/11, sur le village généré (`acfb00d6` : 1 159 pièces solides, 289 composantes, 250 surfaces à
atteindre ; 44 s à la résolution 4, 8 s à la résolution 8) :
- aucun toit n'est jamais atteignable : les échelles de la porte et de la résidence suffisent ;
- 19 toits ne s'atteignent que par la course sur le mur ;
- les murs du village (`Wall_5` à `Wall_12`, 46 studs) sont atteignables, et le plan ne le dit pas. Peut-on
  passer par-dessus et sortir du village ? C'est au DEV ;
- 12 pièces se traversent : les murs du village dans des maisons (`Walls_55`, `Walls_21`, `Walls_44`,
  `Walls_72`, `Walls_28`, `Walls_69`) et les bords de la carte ;
- 1 surface scintille (`Crate_21` et `Crate_73`) ; 37 % de vide, à l'ouest (x -360).

Le 22/11, sur le nouveau Konoha construit (554f1dec : 2 080 pièces, 981 solides, 179 surfaces à atteindre) :
- 2 toits ne sont jamais atteignables :
  - la porte (65 studs) ;
  - la résidence du Hokage (52 studs), plus haute que la course sur le mur (36).
- 34 toits ont besoin de la course sur le mur, surtout les maisons-réservoirs et les immeubles (28,6). Le robot du village (`tools/villagebot`) y monte en 1,3 s.
- L'escalier vers les visages (`Step_13` à `Step_24`) est dans les murs de la résidence : jusqu'à 11,7 studs de chevauchement, et 9 marches sans endroit où poser le pied.
- Autres résultats :
  - 27 paires de pièces qui se traversent ;
  - 3 surfaces qui scintillent : le perchoir de Flashstep et la terrasse des visages, à 31,2 ;
  - 36 % de vide, au-delà du budget de 22 %, surtout à l'ouest, vers x -370.

**Interface :** `ui_probe.luau` s'exécute côté client pendant un Play, par le MCP Studio
(`execute_luau`, datamodel Client). Choisir d'abord l'appareil avec `set_device_simulator`
(robloxstudio-mcp). La sonde mesure en pixels réels :
- les cibles tactiles de moins de 44 px ;
- les textes de moins de 11 px ;
- ce qui sort de l'écran ou passe sous la barre Roblox ;
- les blocs qui se chevauchent ;
- les épaisseurs de contour en usage.

Ensuite, `capture_device_matrix` (cible `client-1`) prend les 4 tailles. L'orientation se
règle seulement sur les téléphones et les tablettes.
