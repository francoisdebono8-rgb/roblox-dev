# Konoha en modèles Blender : le contrat (HUB-001, 14/11)

**Demande de François, 14/11 à 12 h 20 :** « les models 3d peuvent être fait par l'animateur ». L'ANIMATEUR modélise, la discussion DEV boucle pose les modèles en jeu.

## Qui fait quoi
- **ANIMATEUR :** `tools/blender/konoha_models.py`. Il écrit `src/Client/HubMeshData.luau` et `HubMeshData1..n.luau`, au format `nd_mesh.model_luau`, en morceaux de moins de 110 ko. Les `MeshData*.luau` des armes ne bougent pas.
- **DEV boucle :**
  - `Server/Hub` découpe le village en unités ;
  - `Client/MeshKit` construit `HubMeshData` après les armes ;
  - `Client/HubDress` pose les modèles ;
  - `tests/Hub.spec.luau` vérifie le contrat.

## Blender sans le Mac
Dans le conteneur cloud (testé le 14/11 : Blender 5.3, un rendu Cycles CPU en 2 s) :

```
NO_PROXY="" no_proxy="" pip install --break-system-packages --proxy "$HTTPS_PROXY" bpy==5.3.0
python3 -c "import bpy; print(bpy.app.version_string)"
```

`pypi.org` figure dans `NO_PROXY`, mais le DNS direct échoue : il faut forcer le proxy. Ensuite, `python3 tools/blender/fx_models.py render <dossier> Shuriken` marche tel quel.

## Comment le jeu pose un modèle
- `Server/Hub` construit le village en Parts. Chaque bâtiment ou objet est une **unité** : un `Model` avec ces attributs :
  - `Dress` : le nom du modèle ;
  - `DressAt` : un `CFrame` ;
  - `DressScale` : un `Vector3`, s'il y a lieu ;
  - `DressLength` : pour un mur.
- Sur chaque client, `Client/HubDress` place chaque pièce du modèle à `DressAt * CFrame.new(o * scale)`, à la taille `taille × scale`. Il rend ensuite invisibles les Parts de l'unité.
- **Les Parts restent solides :** ce sont les collisions (la marche, les toits, les marches). Si un modèle manque, ses Parts restent visibles.
- **Les Parts marquées `Keep` restent visibles :** `GatePlate`, `HallPlate`, `IchirakuSign`, les `Sign` des boutiques, `HallFloor`. Ne les modélise pas et laisse leur place libre.
- **Les murs :** un mur long est découpé en segments d'environ 10, étirés pour remplir sa longueur.
- **Une unité dans une unité** (la lanterne d'une maison) est habillée à part.

## Règles de modélisation
- **Repère :** Roblox, en studs, y = 0 au sol. Dans Blender, comme dans `nd_mesh` : x à droite, y = devant (−z Roblox), z en haut.
- **Pièces :**
  - archi en `flat=True` ;
  - un matériau par pièce : Wood, Slate, Concrete, Rock, Fabric, Grass, SmoothPlastic ;
  - le détail vient de la géométrie et des couleurs de sommets ; pas d'UV.
- **Limites EditableMesh :**
  - moins de 20 000 triangles et moins de 60 000 sommets par pièce ;
  - environ 150 000 triangles de gabarits pour tout le hub.
- **Collisions :** ce qu'on touche ou sur quoi on marche doit coller aux boîtes de `Server/Hub` (murs, toits plats, balcons, marches, terrasse, troncs).
- **Direction artistique (François) :**
  - anime moderne, pas cartoon ;
  - moins de blanc et de lumière, plus de détails ;
  - tuiles, poutres, chevrons sous les avant-toits, lanternes en papier, bois patiné.
- **Droits :**
  - les 4 têtes de la falaise sont des têtes sculptées génériques, pas des portraits reconnaissables ;
  - aucun logo (feuille, éventail) dans les modèles.

## Les noms

### A. Pièces uniques
Elles sont modélisées aux coordonnées de `Server/Hub`, relatives à `HubMap.Origin`. L'origine du modèle est `Origin`.

| Nom | Ce qu'il remplace |
|---|---|
| KonohaGate | piliers, pieds, poutre, toit, les 2 portes ouvertes |
| GateBooth | la guérite des gardes |
| Ichiraku | cuisine, comptoir, 5 tabourets, poteaux, auvent incliné, noren |
| ExamHall | tout `ExamHall` sauf `HallFloor`, `HallPlate` et `HallLight` : murs, colonnes, porte rouge, toit, 2 balcons, rambardes, escaliers, bannières, piédestal, statue des mains |
| TrainingProps | mannequin, cible et son poteau |
| MemorialStone | socle et stèle |
| HyugaCompound | maison 34 × 96, engawa, portail (2 poteaux et toit), poteau d'entraînement et ses marques |
| UchihaGate | 2 poteaux et la poutre (les éventails restent en Parts) |
| UchihaPier | ponton et pilotis |
| NakaShrine | socle et sanctuaire |
| Torii | le torii ; un maître se tient dessus à y = 14,9, le dessus de la poutre reste à cette hauteur |
| HokageCliff | falaise et 4 têtes ; les têtes sont solides (26 × 30 × 8) |
| FacesTerrace | terrasse, rambardes, 24 marches |

### B. Pièces répétées
Elles sont modélisées dans leur propre repère, que le poseur place et met à l'échelle.

| Nom | Origine | Référence |
|---|---|---|
| HouseGable_24x20x2, HouseShop_24x20x2, HouseShop_24x20x1, HouseBack_22x20x2, HouseUchiha_26x20x2 | centre du pied ; façade côté rue vers +x ; faîtage le long de z | murs w × (8 par étage) × d ; toit à pignon à 24°, débord 1,6, tuiles de 0,9 d'épaisseur centrées sur la ligne de pente (`roof()`) ; Shop = porte et noren ; Back = sans porte |
| HouseFlat_24x20x2, HouseFlat_22x18x3 | même repère | toit plat où l'on court : dessus à y = 8 × étages + 1,0, sur (w + 1,2) × (d + 1,2), rebord décoratif ; 22x18x3 n'a pas de porte |
| WaterTank | pied, au centre | cuve de rayon 3 et de 5 de haut sur des pieds de 2 ; solide, sur le coin arrière des toits hauts |
| TreeA, TreeB, TreeC | pied du tronc | hauteur 14, tronc d'environ 2,2 de diamètre, houppier centré vers y = 15, de rayon 6 à 9 ; échelle : y × hauteur/14, x et z × spread/6 |
| PaperLantern | centre | 1,6 de large, 2,2 de haut, chapeau en haut |
| LampPost | pied | poteau de 0,6 × 7, crochet en haut (la lanterne est à y = 7,6) |
| StoneLantern | pied | fût de 2,4, toit de 3,6 de large à y = 5,4 |
| Bench | pied, au centre | assise de 8 × 2,4 à y = 1,6 |
| Crate | centre | 4 × 4 × 4, étirée en 4 × 8 × 4 et 4 × 12 × 4 |
| Stump | pied | 5 de haut, 3 de diamètre |
| FenceSegment | centre au sol, le long de x | 8 de long, lisse à y = 2,4, poteau de 3 de haut à x = −4 |
| VillageWall | centre au sol, le long de z | segment de 10 de long, 2 d'épais, 26 de haut, plus un chaperon de 3 × 0,8 |
| CompoundWall | même repère | segment de 10 de long, 2 d'épais, 10 de haut, plus le chaperon |
| Ladder | centre | échelle de 2 × 16 × 2 (la TrussPart reste pour grimper) |

## Voir le village assemblé sans Studio
Depuis `games/ninja-duel` :

```
lune run tools/hub_layout.luau /tmp/layout.json
python3 tools/blender/konoha_village.py /tmp/layout.json /tmp/village [gate street plaza hall uchiha faces rooftops air]
```

- `hub_layout.luau` construit le village sans écran. Il écrit chaque copie à l'endroit où `Client/HubDress` la pose, et les Parts qui restent visibles.
- `konoha_village.py` construit chaque modèle de `konoha_models.py` une fois, le duplique à chaque emplacement et rend les vues demandées (Cycles CPU, environ une minute par vue).

## Livraison
- une PR empilée sur `claude/konoha-habillage`, avec les rendus de contrôle et une ligne dans HUB-001 ;
- aucune publication Roblox sans l'accord de François ;
- si un nom ou une taille gêne, le dire dans la PR : le poseur s'adapte ;
- `tests/Hub.spec.luau` refuse un modèle exporté que rien n'utilise, et un nom du contrat qui n'est plus utilisé.
