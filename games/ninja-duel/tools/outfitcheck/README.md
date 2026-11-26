# Le contrôle des tenues sur plusieurs avatars Roblox (OUTILLEUR, passe commune 2, 26/11, DEC-054)

La demande : « un contrôle des tenues sur plusieurs avatars Roblox : il dit quelle pièce traverse ou flotte, sur quel corps ». Les bandages et les bracelets passent en premier : ils rendent mal.

Ce contrôle remplace la cabine d'essayage (`tools/tenues`) pour la mesure. La cabine posait des avatars dans l'Édition d'une copie LAB, au repos. Le contrôle, lui, travaille dans un Play de la place du jeu (DEC-052), sur des corps de duel, au repos et en mouvement.

## Comment il mesure

1. **Les corps.** Le serveur construit sept avatars Roblox types, comme le jeu construit celui du joueur (`Server/AvatarBody`). Ce sont ceux de la cabine :

   | Corps | Paquet | Ce qu'il représente |
   |---|---|---|
   | François | son avatar | l'avatar du propriétaire |
   | Bloc R15 | | le corps par défaut |
   | Femme | 239 | un corps mince |
   | Garçon Roblox | 109 | un corps petit, au torse étroit |
   | Rthro Vanessa | 551 | un corps grand et mince |
   | Rthro Big Bill | 363 | un corps large et massif |
   | Korblox | 192 | un corps à armure |

   Puis chaque avatar est mis dans un corps de duel par `AvatarBody.rig` lui-même, avec un kit sans pièce à lui (Lee). On obtient le squelette du jeu, le bandeau et le tissu de `Server/Outfit`.

   Le jeu ramène tous les avatars aux échelles standard et à la taille des prodiges (6,5 studs). Ce qui change d'un corps à l'autre, c'est la forme de ses maillages, pas sa taille.
2. **Les pièces.** Le client du Play habille les corps comme il habille un combattant (`Client/OutfitDress`). Pour chaque pièce modelée, le contrôle reprend les sommets de la pièce (`Shared/OutfitMeshes`, dépaquetés comme `Client/MeshKit` le fait) là où la pièce se trouve.
3. **La mesure.** Pour chaque sommet, on lance un rayon depuis l'extérieur vers l'os du membre qui porte la pièce. Le rayon vise les pièces de ce membre : le bras, la jambe, le torse ou la tête. Il rencontre la surface du corps :
   - **avant le sommet** : le sommet est dans le corps. Le corps passe à travers le tissu (**traverse**) ;
   - **après le sommet** : le tissu est décollé du corps (**flotte**).
4. **Les poses.**
   - Le repos.
   - Des images des clips du jeu (`Client/AuthoredMotion`) posées sur les articulations, comme le moteur les pose : idle, course, coups, garde, saut, coup reçu, prise, chute.

Un tableau dit, par pièce et par corps, la part des points en défaut dans la pire pose, et la profondeur ou l'écart le plus grand. Les captures montrent la rangée de face, de dos et en mouvement.

## Lancer

Pendant un Play de la place du jeu, dans une Studio à soi (`tools/robots/README.md`) :

```sh
python3 tools/robots/inject.py --server outfitbodies          # Serveur : puis _G.NDOutfitBodies.build()
python3 tools/robots/inject.py outfit                         # Client
python3 tools/outfitcheck/report.py --looks                   # les tenues, bandages et bracelets d'abord
python3 tools/outfitcheck/report.py --dress ArmsWraps         # Serveur : la rangée en bandages
python3 tools/outfitcheck/report.py --measure ArmsWraps       # Client : la mesure (JSON)
python3 tools/outfitcheck/report.py MESURES/*.json --md RAPPORT.md
```

Pour les captures : `_G.NDOutfitCheck.camera("front")`, `"back"` ou `"side"`, puis `capture_screenshot`. En mouvement : `_G.NDOutfitCheck.play()` et une suite de captures, puis `_G.NDOutfitCheck.stop()` et `release()`.

## Ce qu'il ne prouve pas

- **La surface du corps est sa forme de collision, et c'est une boîte.** Les maillages d'un avatar Roblox ont la collision `Box` : le rayon rencontre la boîte du membre, pas son dessin. Le 26/11, les sept corps donnent donc les mêmes chiffres sur les bras, les jambes et le torse, ramenés à la même taille par le jeu. Seule la tête change d'un corps à l'autre : elle garde sa taille. Lire le maillage lui-même (`AssetService:CreateEditableMeshAsync`) est refusé sur les maillages d'avatar : la place n'en a pas le droit. La différence d'un corps à l'autre se voit donc sur les captures, pas dans les chiffres.
- **Une boîte est plus large qu'un bras rond.** Un bracelet serré sur un bras rond peut être compté « dans le bras » aux coins de la boîte. Les chiffres disent où regarder ; les captures confirment.
- **Les poses sont celles des clips de Sasuke (Lion)**, prises à des instants fixes. Le contrôle ne parcourt pas tous les clips de tous les kits.
- **Un défaut mesuré n'est pas un avis.** Les chiffres disent où regarder ; les captures disent ce qu'on voit. L'avis est celui de François (HUMAN_VISUAL_FEEL).
