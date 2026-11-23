# Étape 3, ANIMATEUR (DEC-047) : Konoha, personnalisation, clips de parcours, mannequin et cibles

Tout ce qui suit a été vérifié en rendu Blender, en planche et en test headless. **Rien n'a été vu dans Studio** : c'est François qui joue. C'est un brouillon jusqu'à son avis (DEC-046).

| Demande | Livré | Où |
|---|---|---|
| Décors du nouveau Konoha | 17 repères (grande porte, résidence du Hokage, salle d'examen et son aile, Ichiraku, hôpital, annexe de l'Académie, Hyūga, police Uchiha, sanctuaire Naka, torii, ponton, château d'eau, halle du marché, stèle, arbre de l'Académie), plus les maisons du plan | `tools/blender/konoha_landmarks.py`, `Client/HubMeshData*` ; `reperes_konoha.png` |
| Humeur | vapeur d'Ichiraku et des boutiques, fumées de toits, guirlandes au marché, oiseaux, feuilles | `Client/KonohaLifeFX` |
| Personnalisation | 7 coiffures (slot `hair`) ; couleur du chakra sur les effets ; 7 poses de victoire et 5 émotes au Catalog ; 6 auras (dont 2 en Robux) | `wardrobe_models.py`, `ChakraTintFX`, `ShopAuraFX`, Catalog ; `coiffures.png` |
| Clips | `<kit>.AirJump` et `<kit>.Getup.Quick` (8 kits chacun), `Lion.Parkour.{Leap,LandRoll,LandHard,Vault}` | `AuthoredJutsu9-13` ; `clip_*.png` |
| Mannequin et cibles | mannequin et cible à trépied au terrain n° 3 (`TrainingProps`) ; panneau modelé sur les 8 cibles de la ruelle | `konoha_models.training_props`, `PropMeshData`, `KonohaLifeFX.dressBoards` ; `mannequin_cibles.png` |

## Deuxième passe, après le retour de François (22/11, 23 h 42)

> « les 7 coiffures sont mauvaises, les rues ne sont pas animées, l'arrangement de l'espace et la différence entre les bâtiments n'est pas assez forte, le village est trop lisse »

| Point | Fait |
|---|---|
| Coiffures | Refaites en mèches plates et larges, avec du volume, foncées à la racine. Le crâne est fermé au-dessus de la ligne des cheveux, les mèches de nuque cassent le bord et la frange encadre le visage. Planche : `coiffures_v4.jpg`. |
| Rues animées | 26 villageois qui marchent et s'arrêtent (`KonohaFolkFX`) ; linge sur des cordes dans les ruelles ; nobori devant les boutiques ; étals modelés à la place des blocs (`market_stall`, `barrel`). |
| Bâtiments différents | Chaque maison a son plâtre, choisi dans la palette de son quartier, et les toits changent de couleur par quartier (`KonohaLifeFX.tintHouses`). Le modèle de tour (`tower_house`, 28 de haut) est prêt et attend une ligne du DEV dans `Hub.LAYOUT_STANDIN`. |
| Arrangement | 70 jardinets (un arbre, parfois une lanterne de pierre) dans les vides entre les maisons. Le plan validé ne bouge pas. |

Avant et après, en rendu Blender du village tel que le client le dresse (`tools/hub_layout.luau`, plus l'émulation des teintes, des étals, du linge et des passants ; les passants y sont des blocs, alors qu'en jeu ils portent la garde-robe) : `village_marche_avant_apres.jpg`, `village_residences_avant_apres.jpg`.

## Troisième passe (23/11, 1 h)

> « les coiffures : des cheveux sur les yeux, je ne sais pas pourquoi tu as un problème avec les cheveux, et les bandanas qui tombent sur les yeux ; sinon elles sont belles mais pas assez variées »

- **Rien sur les yeux** : `lock()` raccourcit toute mèche qui passerait devant le visage entre les tempes (|x| < 0,42) sous y 0,36. Les mèches de côté sont posées hors des yeux, et la frange du bol est coupée au-dessus des sourcils.
- **Bandeaux et bandanas sur le front** : `BROW` passe de 0,27 à 0,40, donc le bandeau et la plaque sont au-dessus des yeux.
- **6 coupes de plus** (13 en tout) : `HairBob` (court et rond), `HairHime` (longue et droite, frange droite), `HairPony` (longue queue haute, mèche de côté), `HairMane` (crinière sauvage), `HairShort` (courte en bataille), `HairBlaze` (pointes en flamme). Elles sont au Catalog à 700 Ryō, et les villageois les portent aussi.

## Quatrième passe (23/11, 18 h) et premiers points de l'étape 4

- La garde contre les yeux porte sur toute la forme de chaque mèche, avec une marge ; les bandeaux sont à `BROW` 0,46.
- 18 coupes : `HairTwinTails`, `HairTopknot`, `HairBraid`, `HairUndercut` et `HairCurtain` en plus. Planche : `coiffures_v4.jpg`.
- Les couleurs de cheveux sont proposées au DEV (`CatalogStyle` est à lui).
- Clips de parcours pour le promeneur : `Parkour.WallRun`, `Parkour.Ledge`, `Parkour.LedgeUp` (`AuthoredJutsu14`).
- L'export de la tour.

## Notes des clips (`clip_grades`)

- AirJump : 9,4 à 9,7.
- Getup.Quick : 7,3 à 8,7.
- Victoires : 9 à 10.
- Émotes : 8,3 à 9,4.
- Point faible connu : `Parkour.LandRoll` à 6,0. Le corps passe sous le sol pendant la roulade.

## Limites

- Les clips de parcours ne se jouent pas sur l'avatar Roblox du promeneur. Il faudrait des Animation publiées, donc une étape LIVE.
- Le poteau de la course et les anneaux sont encore ceux du DEV.
- Les looks d'armes ne sont pas faits : il leur faut des icônes (OUTILLEUR).
- `Prediction.spec` est rouge sur la branche commune, déjà avant ces commits. La question est posée au DEV.
