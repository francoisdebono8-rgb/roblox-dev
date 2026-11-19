# Les six maisons du nouveau Konoha (19/11, DEC-042)

Vague 2, § 2 ANIMATEUR, tâche 1. `maisons.png` : les six modèles, triangles mesurés sur les pièces construites.

| Modèle (nom dans KonohaLayout) | Triangles | Budget | Taille du modèle (l x p, haut des murs) | Nombre dans le plan |
|---|---|---|---|---|
| small_house | 892 | 900 | 14 x 14, 7 | 33 |
| machiya | 1 396 | 1 400 | 17 x 17, 14 | 20 |
| tank_house | 1 534 | 1 800 | 17 x 16, 21 | 37 |
| shop_house | 1 490 | 1 500 | 20 x 16, 14 | 25 |
| apartment | 1 980 | 2 000 | 24 x 16, 21 | 16 |
| clan_house | 988 | 1 600 | 22 x 17, 9 | 23 |

`konoha_models.write` vérifie chaque budget (`konoha_houses.check`, entre 800 et le budget du modèle), ainsi que l'accord entre `konoha_houses.REF` et `KonohaLayout.HOUSES`.

## Le contrat avec le constructeur (DEV 6)

- Le nom du modèle est celui de `KonohaLayout.Buildings[i][1]`.
- L'origine est au centre du pied du bâtiment.
- La porte regarde +Z : yaw 0 dans le plan.
- Le modèle est fait à sa propre taille, donnée dans `KonohaLayout.Houses[m].width/depth/height`. Le constructeur l'étire en X et en Z jusqu'à l'emprise du lot (w, d), sans toucher à la hauteur.
- Les hauteurs du plan sont devenues les hauts de murs réels des modèles. Les emprises n'ont pas bougé ; le prouveur repasse avec PASS et 18 % de vide.

## L'export

Il suit le même chemin que les autres modèles du village :
- les FBX sont dans `LAB/hub-fbx/` : `small_house.fbx`, `machiya.fbx`, `tank_house.fbx`, `shop_house.fbx`, `apartment.fbx` et `clan_house.fbx` ;
- le manifeste est `tools/blender/imports/hub/Hub.manifest.json` (189 pièces au total).

Le circuit se poursuit ensuite comme d'habitude : import dans Studio, `hub_studio_dump.luau`, puis `hub_to_luau.py`.

Les maisons n'entrent dans `HubMeshData` que lorsque `Client/HubDress.NAMES` les étiquette (DEV 6). D'ici là, `Hub.spec` refuserait un modèle que rien ne porte. Dès que les six noms y sont, `konoha_models.py write` les ajoute tout seul.

## Ce qui n'est pas vu

Les maisons ne sont rendues que dans Blender (catégorie TECHNICAL). Il faudra les regarder dans Studio, à la caméra du jeu, une fois le village construit à partir de `KonohaLayout`.
