# Les tenues et les bandeaux comparés aux références (20/11, étape 1 ANIMATEUR 4)

**François (20/11) :** « les tenues et les bandeaux Blender sur les joueurs ne sont pas fidèles ».

Skills suivis : `ninja-animation-direction` et `roblox-3d-model`.

**Planches :** chaque tenue posée sur trois corps d'avatar (mince, large, grand), vue de dos à gauche et de face à droite, dans les couleurs du catalogue.
- `planche_maitres.png` : les 8 tenues des prodiges.
- `planche_inventees.png` : les 6 tenues inventées.
- `planche_bandeau.png` : le bandeau.

Le rendu est `outfit_models.py bodies` sur le Mac (Blender). Une pièce y est posée comme `OutfitDress` la pose en jeu : à la taille de la partie du corps, divisée par la référence. Rien n'est encore vu dans Studio (catégorie TECHNICAL).

**Références :** Naruto, première partie (12–14 ans). Pas de visage, et aucun logo : ni spirale, ni éventail, ni feuille, ni sable sur les plaques.

## Ce qui ne collait pas, et ce qui est corrigé

| Tenue | Écart avec la référence | Correction |
|---|---|---|
| Naruto | Pas de holster ni de sacoche ; il les porte toujours | Holster de kunai sur la cuisse droite (bandage blanc, étui bleu) et sacoche à l'arrière de la ceinture |
| Sasuke | **Tibias bandés** : Sasuke ne les a pas, ses mollets sont nus ; manchettes sans leurs bords bleus ; pas de holster | Tibias nus, bords bleus aux deux bouts des manchettes, holster sur la cuisse droite |
| Lee | Ceinture rouge sans plaque. Or la ceinture de Lee **est** son bandeau, porté à la taille | Plaque de métal devant la ceinture, avec ses rivets |
| Neji | Pas de holster | Holster sur la cuisse droite bandée |
| Gaara | Il porte son bandeau **sur la sangle** de la gourde, pas sur le front | Plaque sur la sangle, sur la poitrine |
| Kakashi | Ni gants ni masque : ce sont les deux choses qu'on voit le plus chez lui | Gants sans doigts avec une plaque de métal sur le dos de la main, et le masque jusque sous les yeux |
| Itachi, Minato | Conformes | — |
| Bandeau (`Server/Headband`) | Plaque plate de 40 % de la largeur du front, sans rivets ; bande faite de 8 lattes | Bandeau modélisé (`HeadbandClassic`) : plaque bombée à 55 % du front, un rivet à chaque coin, deux lignes gravées (pas de symbole), nœud et deux pans derrière |
| Bandes des bras | Trop épaisses (19/11) | Un tiers de l'épaisseur d'avant |

## Ce qui attend le DEV : le bandeau

Le bandeau porté en jeu est construit par `Server/Headband.luau` (son fichier) : huit lattes et une plaque plate. Le modèle `HeadbandClassic` et les 7 autres bandeaux sont prêts dans `Shared/OutfitMeshes` (`Items[HeadbandBlue]` et les autres).

**Ce qu'il faut faire :**
- quand un bandeau a son modèle, `Headband.wear` le donne à `OutfitDress`, comme une pièce de tenue, au lieu de le construire ;
- les bandeaux au cou (`HeadbandNeck`) et à la taille (`HeadbandWaist`) ne sont justes qu'avec le modèle ;
- d'ici là, les nouveaux bandeaux du catalogue s'affichent comme le classique, dans leurs couleurs.

## La garde-robe branchée sur le catalogue

`outfit_models.py write` écrit maintenant les looks de la garde-robe dans `Shared/Catalog.luau`, dans un bloc généré entre `BEGIN wardrobe` et `END wardrobe` :
- 52 nouveaux looks : 10 hauts, 7 bas, 6 bras, 6 pieds, 7 bandeaux, 3 masques, 4 capes et foulards, 3 objets dans le dos, et les 6 tenues inventées. Avec ce qui existait, le catalogue compte 15 hauts, 10 bas, 8 bras, 8 pieds, 10 bandeaux, 4 masques, 5 capes et 4 objets dans le dos ;
- les prix en Ryō sont des propositions (l'économie est au DEV) ;
- les tenues inventées sont en Robux, donc SOON tant que le produit n'existe pas. Leurs 6 clés sont ajoutées à `Config.Shop.Products`, à 0 ;
- chaque tenue est rattachée à un kit, comme l'exige `Shop.spec` : Ember Monk à Lee, Mist Hunter à Itachi, Storm Courier à Naruto, Shadow Scout à Kakashi, Leaf Medic à Neji, Sand Nomad à Gaara. C'est une proposition, que le DEV peut changer ;
- chaque look a ses pièces en tissu de secours (`pieces`), que `Server/Outfit` pose tant que le client n'a pas dessiné le modèle.

`CapeTravel`, `BackScroll`, `MaskCloth` et `HeadbandBlue` existaient déjà : ils gardent leur id, et leur modèle remplace la pièce en tissu.

Une tenue inventée n'a pas de maillage à elle. `OutfitMeshes.Sets` la monte au chargement à partir des pièces qu'elle regroupe, en préfixant leurs emplacements de couleur (`GiCloth`, `HakamaCloth`…).
