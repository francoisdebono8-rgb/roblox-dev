# La cabine d'essayage (OUTILLEUR, 20/11 ; repassée le 21/11)

La cabine montre les tenues du jeu sur des avatars Roblox types, de face et de dos. C'est le contrôle des tenues de l'étape 1 (DEC-043, OUTILLEUR 3). L'ANIMATEUR s'en sert pour comparer les tenues et les bandeaux aux vraies références, puis les corriger sur l'avatar (ANIMATEUR 4) : ses planches Blender montrent la pièce, la cabine montre ce que le jeu en fait dans Studio.

| Fichier | Rôle |
|---|---|
| `cabine.luau` | La cabine, dans Studio (Edit). Elle construit les avatars et les habille |
| `studio_code.py` | Sort le code Luau d'une étape, à coller ou à passer à `execute_luau` |
| `planche.py` | Recadre les captures et nomme chaque avatar sous sa silhouette. Sort une planche par tenue, plus la planche avant / après |
| `rendus/` | Les planches (voir plus bas) |
| `test_planche.py` | Les tests de la planche, sans Studio |

## Les avatars

Sept corps, dans cet ordre de gauche à droite sur la planche de face (inversé de dos) :

| Avatar | Paquet | Pourquoi |
|---|---|---|
| Korblox | 192 | Un corps dont le torse porte une armure |
| Rthro Big Bill | 363 | Une grande tête Rthro |
| Rthro Vanessa | 551 | Une grande tête Rthro |
| Garçon Roblox | 109 | Un torse avec un débardeur peint |
| Femme | 239 | |
| Bloc R15 | | Le corps par défaut |
| François | | L'avatar du propriétaire |

Chaque avatar est construit comme le jeu construit celui du joueur (`Server/AvatarBody`) :
- les échelles standard ;
- les vêtements et accessoires retirés, sauf les cheveux (`Outfit.strip`) ;
- le corps grandi d'un bloc jusqu'à la taille des prodiges (6,5 studs).

Studio ne résout aucune articulation en mode Édition : une tête Rthro restait 2 studs dans le torse. La cabine pose donc chaque pièce à son repos, depuis la racine (C0/C1), comme le squelette du jeu en partie.

Ensuite, l'avatar est habillé comme en duel :
1. les pièces de tissu de `Server/Outfit` ;
2. par-dessus, les pièces modelées de l'ANIMATEUR (`Client/OutfitDress`), avec le tissu d'une tenue modelée caché comme sur le client ;
3. le bandeau de `Server/Headband`.

(21/11) La cabine suit l'ordre du duel (`AvatarBody.rig`) : `Headband.fromLooks` puis `Outfit.wear`. Un set qui porte déjà son bandeau n'en reçoit pas un second.

Les paquets Femme, Vanessa et Big Bill n'ont aucun accessoire : pas de cheveux. Pour essayer les cheveux, la cabine leur en met (`AVATARS`, champs `hair` et `hat`) :
- Femme : des cheveux (`HairAccessory` 62234425) ;
- Vanessa : des cheveux rangés comme un chapeau (`HatAccessory` 1772336109) ;
- Big Bill : des cheveux rangés comme un chapeau (`HatAccessory` 15656347831).

## Les tenues (`Cabine.ORDER`)

- Les 8 sets des inspirations, avec le bandeau bleu (sauf Gaara).
- Trois tenues de base du catalogue.
- Deux tenues d'accessoires :
  - masque, cape de voyage, rouleau ;
  - masque de renard, cape à capuche, sabre, bandeau au cou.
- Les 6 tenues inventées de la garde-robe (SOON).

La gourde de Gaara n'apparaît pas : c'est l'objet de son kit, gagné sur l'arbre Sand et posé hors du vêtement.

## Refaire les rendus

1. **Ouvrir une copie LAB** de la place commune (`PLACES/ND-JEU.rbxlx`), jamais la place d'une autre discussion. Par exemple : `RobloxStudio -task EditFile -localPlaceFile ~/Documents/NinjaDuel/LAB/tenues/<copie>.rbxlx`. Rien n'est enregistré : la cabine est loin de la carte (`Cabine.ORIGIN`).
2. **Construire les avatars.** Lancer `python3 tools/tenues/studio_code.py setup` et passer le code à Studio (Edit). Le chargement des avatars prend environ une minute. On peut aussi poser le module une fois dans `ServerStorage` (`NDCabineTool`), puis appeler `require(...).dress(...)`.
3. **Capturer chaque tenue :**
   - habiller : `studio_code.py dress SetNaruto` ;
   - capturer depuis `studio_code.py camera front`, puis `camera back` (`Roblox_Studio screen_capture`, position et cible données) ;
   - enregistrer sous `SetNaruto_front.jpg` et `SetNaruto_back.jpg`.

   `Cabine.dress({})` déshabille tout le monde : ce sont les captures `Nu_front` et `Nu_back`.
4. **Sortir les planches :** `python3 tools/tenues/planche.py <captures> tools/tenues/rendus/<date>_<place> "<place>"`.
5. **Comparer deux places :** `python3 tools/tenues/planche.py --avant-apres <captures avant> <captures après> tools/tenues/rendus/avant-apres-<date>.jpg`. La planche met les tenues côte à côte, de face puis de dos.

## Les rendus du 20/11

| Dossier | Place | Tenues |
|---|---|---|
| `rendus/2026-11-20_avant` | ND-JEU `699d331d`, sources `053395e4`, avant les corrections de l'ANIMATEUR | 12 tenues |
| `rendus/2026-11-20_apres` | ND-JEU `29a59f15`, sources `9311e840`, construite par la place commune, après ses corrections et la garde-robe | 19 tenues |
| `rendus/avant-apres-2026-11-20-face.jpg`, `-dos.jpg` | Les deux places côte à côte | Les 12 tenues communes |

Ces rendus sont des observations de Claude : captures Studio en mode Édition, pose de repos (TECHNICAL / NATIVE_STUDIO). Ce n'est pas l'avis de François. Les références à comparer restent celles de l'ANIMATEUR, qui a choisi de n'afficher aucun logo.

### Ce que les corrections de l'ANIMATEUR changent en jeu

Toutes les corrections se voient dans Studio, sur les 7 corps :

| Tenue | Ce qui se voit maintenant |
|---|---|
| Naruto | Le holster de la cuisse et la sacoche dans le dos |
| Sasuke | Les mollets nus, qui montrent les jambes propres de l'avatar : le pantalon peint du garçon, la peau de François |
| Lee | La plaque sur la ceinture rouge |
| Neji | Le holster |
| Gaara | La plaque sur la sangle |
| Kakashi | Le masque jusque sous les yeux, et les gants à plaque |
| Cape de voyage | Une cape courte aux épaules (avant : un pan raide jusqu'au sol, sous la tunique) |
| Rouleau | Porté en travers du dos |

### Ce qui reste

1. **Un corps à armure transforme toute tenue en boîte.**
   - Mesures : le `UpperTorso` de Korblox fait 3,25 × 6,30 × 3,02 studs (le maillage inclut l'armure), contre 2,3–2,5 × 1,9–2,4 × 1,2–1,4 pour les six autres.
   - Effet : les pièces se mettent à l'échelle du torse (`OutfitDress`, `body.Size / Ref`). Avec le set Naruto, Korblox mesure 8,33 studs de haut et 4,92 de profondeur. Les six autres : 6,6 à 7,2 de haut, 2 à 2,4 de profondeur.
   - Conséquences : la tête est cachée, et le sabre, le rouleau et l'écharpe sortent très loin du corps.
   - Pistes :
     - DEV : dans `AvatarBody`, remettre le torse standard quand le torse dépasse une taille plausible ;
     - ANIMATEUR : plafonner l'échelle des pièces.
   - Test : refaire la planche ; Korblox doit avoir la silhouette des autres.
2. **Deux bandeaux sur une tête.** Ember Monk (hachimaki), Storm Courier (bandeau classique), Leaf Medic (bandeau au cou) et Lee (la plaque de ceinture) portent déjà leur bandeau. Le bandeau choisi dans son emplacement s'ajoute par-dessus : chez Ember Monk, le hachimaki blanc recouvre la plaque.
   - Règle à trancher (DEV / ANIMATEUR) : un set qui porte un bandeau remplace-t-il l'emplacement « bandeau » ?
3. **La capuche est traversée.** C'est la cape à capuche (Accessoires 2, Sand Nomad). De dos, les nœuds du bandeau et les yeux du masque sortent à travers le tissu de la capuche.
4. **Le bandeau au cou** choisi dans son emplacement s'affiche sur le front. `Server/Headband` ne connaît pas encore les modèles : c'est la demande de l'ANIMATEUR au DEV.
5. **Le visage :**
   - le col blanc de Naruto monte jusqu'à la bouche sur les sept avatars ;
   - sur les têtes Rthro, le masque de Kakashi et le masque en tissu font un bloc devant un visage long.
6. **Les cheveux :** Femme, Vanessa et Big Bill sortent chauves. (Corrigé le 21/11 : ce n'était pas `Outfit.strip`. Leurs paquets n'ont pas de cheveux du tout ; voir les rendus du 21/11.) François garde les siens.
7. **Le bandeau bleu** se lit noir à cette distance (`Band = 46, 64, 120`). Le rouge se lit rouge. Le bleu (base A) et le noir (base B) se confondent.
8. **Détails :**
   - Lee : la ceinture rouge disparaît dans le dos du garçon Roblox, dont le torse est étroit ;
   - Neji : sur les corps larges, le bas sombre dépasse sur les côtés de la robe ;
   - Base B : de dos, les protège-bras ne montrent que deux sangles.

## Les rendus du 21/11

| Dossier | Place | Tenues |
|---|---|---|
| `rendus/2026-11-21_632931f2` | ND-JEU `632931f2`, copie LAB, après `AvatarBody.plainTorso`, les cheveux gardés et le bandeau unique | 19 tenues, et sans tenue |
| `rendus/avant-apres-2026-11-21-face.jpg`, `-dos.jpg` | `29a59f15` (20/11) à gauche, `632931f2` (21/11) à droite | Les 19 tenues |

Ce sont des observations de Claude (TECHNICAL / NATIVE_STUDIO), pas l'avis de François.

| Correctif du 20/11 | Ce qui se voit |
|---|---|
| Le torse de Korblox (`plainTorso`) | Le torse est remis au standard (2,5 × 2 × 1,25). La tunique a la largeur des autres |
| Les cheveux | Femme et Vanessa gardent les leurs, sur toutes les tenues. **Big Bill sort encore chauve** (ci-dessous) |
| Un seul bandeau | Ember Monk (hachimaki), Storm Courier, Leaf Medic (au cou) et Lee n'ont plus de second bandeau sur le front |

Ce qui reste :
1. **Big Bill chauve : un chapeau-cheveux déplacé vers les cheveux ne s'affiche plus.**
   - Avant le déshabillage, `desc:GetAccessories(true)` est vide et `HatAccessory` vaut `15656347831`.
   - `Outfit.strip` reconnaît des cheveux à son nom et le déplace vers `HairAccessory`.
   - Essai dans Studio, même objet : depuis `HatAccessory`, Roblox construit 1 accessoire ; depuis `HairAccessory`, 0. Les cheveux de Vanessa (1772336109) passent, ceux de Big Bill non : cela dépend du type de l'objet.
   - Piste (DEV, `Server/Outfit`) : garder les chapeaux-cheveux dans `HatAccessory` (`desc.HatAccessory = table.concat(hair, ",")`) au lieu de les déplacer.
   - Test : Big Bill garde sa coiffure sur la planche.
2. **Korblox : les bras de l'armure.** Le torse est réglé, pas les bras : `RightUpperArm` fait 1,53 × 3,28 × 1,58 (un bras normal : environ 1 × 1,2 × 1). Les pièces de bras se mettent à cette échelle : sur 17 tenues sur 19 (toutes sauf Itachi et Base C), deux blocs montent au-dessus des épaules, plus haut que la tête.
   - Pistes :
     - DEV : faire pour les bras ce que `plainTorso` fait pour le torse ;
     - ANIMATEUR : plafonner l'échelle des pièces de bras.
   - Test : refaire la planche ; plus aucun bloc au-dessus des épaules de Korblox.
3. Les points 3, 5, 7 et 8 du 20/11 (capuche traversée, visage, bandeau bleu, détails) n'ont pas été repris par les correctifs ; ils se voient encore sur la planche.

## Les coiffures et les couleurs de cheveux (étape 3, 22/11)

Les looks de cheveux viennent de la boutique (`Cabine.hairLooks`) : un look par article des emplacements de cheveux (`Cabine.HAIR_SLOTS` : `hair`, `hairColor`), sur la tenue de base A. `dress("Hair_<id>")` les met, comme les autres looks.

```sh
python3 tools/tenues/studio_code.py hairs                 # Edit : la liste des looks de cheveux
python3 tools/tenues/planche.py --cheveux <captures> <sortie>.jpg [<place>]   # le nuancier, une ligne par couleur
```

Rendu : `rendus/2026-11-21_554f1dec/couleurs-cheveux.jpg`. Place LAB ND-JEU `554f1dec`, mode Édition, captures de face Hair_<id>_front.jpg.

| | |
|---|---|
| Ce qui existe | L'emplacement `hair` n'a qu'un article, « la sienne » (`HairOwn`) : il n'y a pas encore de coiffure à essayer, elles viendront de l'ANIMATEUR. L'emplacement `hairColor` a 11 articles : la sienne et 10 couleurs (`Shared/CatalogStyle`). |
| Ce qui marche | Les 10 couleurs se posent sur les 4 avatars qui ont des cheveux (François, Femme, Vanessa, Big Bill), y compris les cheveux rangés comme un chapeau (Vanessa, Big Bill). Revenir à « la sienne » rend la couleur et la texture d'origine. Les correctifs du DEV (b3715830) tiennent : Big Bill garde sa coiffure, le torse de Korblox est remplacé. |
| À regarder | Korblox, Garçon Roblox et Bloc R15 n'ont pas de cheveux : la couleur ne se voit pas sur eux. Un joueur chauve peut acheter une couleur pour rien. |
| | ANBU SILVER (Robux) et SNOW WHITE (800 Ryō) sont presque pareils à la taille du jeu. |
| | Les cheveux de Big Bill (Snowfall Hair) portent un nuage au-dessus de la tête, qui prend la couleur aussi. |
