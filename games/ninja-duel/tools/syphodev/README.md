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
