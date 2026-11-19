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

Contrôle de parité dans Studio, c'est l'étape 10 de la vidéo. Jouer le clip sur un
combattant du jeu, puis comparer la position de chaque partie à l'image de contact avec le
monde posé de `report.json`. L'écart doit rester sous 0,0001 stud. On vérifie aussi que la
durée jouée est la durée d'auteur.
