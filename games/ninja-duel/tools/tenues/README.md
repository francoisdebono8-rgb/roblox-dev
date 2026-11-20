# La cabine d'essayage (OUTILLEUR, 20/11)

Les tenues du jeu sur des avatars Roblox types, de face et de dos. C'est le contrôle des tenues de l'étape 1 (DEC-043, OUTILLEUR 3). L'ANIMATEUR s'en sert pour comparer les tenues et les bandeaux aux vraies références, puis les corriger sur l'avatar (ANIMATEUR 4).

| Fichier | Rôle |
|---|---|
| `cabine.luau` | La cabine, dans Studio (Edit) : elle construit les avatars et les habille |
| `studio_code.py` | Sort le code Luau à coller (ou à passer à `execute_luau`) pour une étape |
| `planche.py` | Recadre les captures, nomme chaque avatar sous sa silhouette et sort les planches |
| `rendus/2026-11-20/` | Les premières planches : une par tenue (face au-dessus, dos dessous), plus `tout-face.jpg` et `tout-dos.jpg` |
| `test_planche.py` | Les tests de la planche (sans Studio) |

## Les avatars

Sept corps, de gauche à droite sur la planche de face :

- **Korblox** (paquet 192), un corps dont le torse porte une armure ;
- **Rthro Big Bill** (paquet 363) et **Rthro Vanessa** (paquet 551), deux grandes têtes Rthro ;
- **Garçon Roblox** (paquet 109), un torse avec un débardeur peint ;
- **Femme** (paquet 239) ;
- **Bloc R15**, le corps par défaut ;
- **François**, l'avatar du propriétaire.

De dos, l'ordre est inversé.

Chaque avatar est construit comme le jeu construit celui du joueur (`Server/AvatarBody`) :

- les échelles standard ;
- les vêtements et accessoires retirés, sauf les cheveux (`Outfit.strip`) ;
- le corps grandi d'un bloc à la taille des prodiges (6,5 studs).

Studio ne résout aucune articulation en mode Édition : une tête Rthro restait 2 studs dans le torse. La cabine pose donc chaque pièce à son repos depuis la racine (C0/C1), comme le squelette du jeu en partie.

Ensuite, l'avatar est habillé comme en duel :

1. les pièces de tissu de `Server/Outfit` ;
2. par-dessus, les pièces modelées de l'ANIMATEUR (`Client/OutfitDress`), avec le tissu d'une tenue modelée caché comme sur le client ;
3. le bandeau de `Server/Headband`.

## Les tenues

- les 8 sets des inspirations, avec le bandeau bleu, sauf Gaara ;
- trois tenues de base du catalogue ;
- une tenue avec les trois accessoires : masque, cape, rouleau.

La gourde de Gaara n'apparaît pas : c'est l'objet de son kit, gagné sur l'arbre Sand et posé hors du vêtement.

## Refaire les rendus

1. Ouvrir une **copie LAB** d'une place du jeu, jamais la place d'une autre discussion. Studio en mode Édition. Rien n'est enregistré : la cabine est loin de la carte (`Cabine.ORIGIN`).
2. `python3 tools/tenues/studio_code.py setup` : coller le code dans Studio, ou le passer à `execute_luau`. L'appel attend le chargement des avatars, environ une minute.
3. Pour chaque tenue :
   - `python3 tools/tenues/studio_code.py dress SetNaruto` (le nom vient de `Cabine.ORDER`) ;
   - capturer depuis `studio_code.py camera front`, puis `camera back` (`Roblox_Studio screen_capture`, position et cible données) ;
   - enregistrer les captures sous `SetNaruto_front.jpg` et `SetNaruto_back.jpg`.

   `Cabine.dress({})` déshabille tout le monde : ce sont les captures `Nu_front` et `Nu_back`.
4. `python3 tools/tenues/planche.py <captures> tools/tenues/rendus/<date>`. Les noms, l'ordre et la caméra sont lus dans `cabine.luau`.

## Ce que montrent les rendus du 20/11

Ce sont des observations de Claude sur des captures Studio en mode Édition, en pose de repos (TECHNICAL / NATIVE_STUDIO). Ce n'est pas l'avis de François. Les références à comparer restent celles de l'ANIMATEUR.

### 1. Un corps à armure transforme toute tenue en boîte

| | Torse (`UpperTorso.Size`) | Boîte de l'avatar |
|---|---|---|
| Korblox | 3,25 × 6,30 × 3,02 studs : le maillage du torse inclut l'armure | Avec le set Naruto : 8,33 studs de haut, 4,92 de profondeur |
| Les six autres | 2,3–2,5 × 1,9–2,4 × 1,2–1,4 | 6,6 à 7,2 de haut, 2 à 2,4 de profondeur |

Les pièces de tenue se mettent à l'échelle du torse (`OutfitDress`, `body.Size / Ref`). Chez Korblox, toutes les tenues deviennent donc une boîte qui cache la tête, et le rouleau sort très loin du dos.

Tout joueur qui porte un corps de ce genre se verra ainsi en duel. Le changement minimal relève du DEV :

- dans `AvatarBody`, remettre le torse standard quand le torse dépasse une taille plausible ;
- ou, côté ANIMATEUR, plafonner l'échelle des pièces.

Test : refaire la planche, Korblox doit avoir la silhouette des autres.

### 2. Le visage

- **Col blanc de Naruto.** Il monte jusqu'à la bouche sur les sept avatars, plus haut encore sur les têtes Rthro.
- **Masque en tissu.** C'est un bloc sombre plus large que le visage, du nez au menton : il se lit comme une boîte.
- **Cheveux.** Femme, Vanessa et Big Bill sortent chauves : leurs cheveux ne passent pas `Outfit.strip`. François garde les siens. Le bloc et le garçon n'en ont pas.
- **Bandeau bleu.** Il se lit noir à cette distance (`Band = 46, 64, 120`). Le rouge se lit rouge. Le bleu (base A) et le noir (base B) se confondent.

### 3. Le dos, ce que le joueur voit tout le duel

En troisième personne, le joueur voit le dos de son ninja tout le temps. Les dos n'ont aucun emblème, alors que les références en ont un ; c'est à vérifier par l'ANIMATEUR :

- l'éventail Uchiha (Sasuke) ;
- la spirale rouge du gilet (Kakashi) ;
- les kanji du Quatrième (Minato). Le manteau de Minato s'arrête en haut des cuisses.

La cape de voyage passe sous la tunique : elle n'apparaît qu'à partir du milieu du dos et tombe raide jusqu'au sol.

### Détails, tenue par tenue

- **Lee** : le bandeau est au front, comme le choisit un joueur. La référence le porte en ceinture. La ceinture rouge du set disparaît dans le dos du garçon Roblox (torse étroit).
- **Neji** : sur les corps larges, le bas sombre dépasse sur les côtés de la robe.
- **Base B** : les protège-bras n'ont une plaque que devant ; de dos, on ne voit que deux sangles.
- **Garçon Roblox** : son débardeur bleu est peint sur le maillage du torse (planche « sans tenue »). Toutes les tenues le couvrent.
