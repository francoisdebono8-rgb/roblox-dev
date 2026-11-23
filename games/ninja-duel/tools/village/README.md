# Le village généré pour courir en ninja (DEV, 23/11)

François, après avoir joué l'étape 3 :
- « la carte n'est vraiment pas complète et peu cohérente » ;
- « la course ninja, le double saut, le mur, ce n'est pas du tout ninja feel » ;
- « tout doit être dans cet esprit » ;
- « applique la méthode de l'ANIMATEUR et adapte-la à une génération de village ; on n'est pas obligé de prendre la vraie composition de Konoha, en gardant des éléments reconnaissables ».

## La méthode de l'ANIMATEUR, pour un village

L'ANIMATEUR fait ses mouvements avec SyphoDev (`tools/blender/syph_author.py`, `tools/syphodev`) :

1. **Des règles** tirées des références et du corps réel.
2. **Beaucoup de candidats** générés sous ces règles.
3. **Une note sur 10** faite de mesures, pas d'impressions.
4. **Une planche** regardée une fois.
5. **On ne garde que ce qui bat l'existant.**

`konoha_village.py` fait la même chose pour le village.

### 1. Les règles

Elles viennent du corps du jeu (`tools/syphodev/konoha_profile.json`). Les mesures sont en studs de base, avant `HubMap.Scale` 1,3.

**Le saut entre deux toits.** La portée est celle d'un sprint (27,7/s) pendant le temps du saut, jusqu'à la hauteur d'arrivée. On n'en demande que 60 %, parce que personne ne saute du bord exact.

| Saut | Écart | Ce qu'il demande |
|---|---|---|
| **FLUIDE** (un seul saut) | 13,3 à plat ; 11 pour une marche de 5 | Pris en courant, sans y penser. C'est le rythme du ninja sur les toits. |
| **BOND** (le second saut) | 22,3 à plat | Pour une ruelle ou un étage. |

**Les rangées.**
- Les maisons sont posées le long de chaque rue, porte vers la rue, à 0,8–2,6 l'une de l'autre. Leurs toits forment une seule surface où courir.
- Une ruelle de 6,5–9,5 coupe une rangée de temps en temps. Elle se franchit d'un saut fluide.

**Derrière les rangées.**
- D'autres rangées suivent, au-delà d'une ruelle de service, jusqu'à rencontrer celles de la rue d'en face. Cela fait un îlot fermé.
- Les trous qui restent sont remplis par des maisons tournées vers leur rue la plus proche.
- Chaque porte garde devant elle une bande libre de 6 studs : une sortie.

**La ligne des toits.**
- D'une maison à sa voisine, la hauteur change d'1 à 4 studs, dans le même sens sur quelques maisons : une montée, une descente. On ne fait jamais plus qu'une marche fluide.
- Une passe de lissage reprend les voisins qui restent trop différents.

**Les quartiers.**
- Chaque quartier a ses modèles et la bande de hauteur de ses toits : marché, quartier du Hokage, Uchiha, Hyūga, résidences…
- Les modèles de l'ANIMATEUR sont étirés au plus de 0,8–1,15 en largeur et de 0,85–1,2 en hauteur.

**Les passerelles.**
- Une planche relie deux toits qui se font face par-dessus une ruelle de 16 studs ou moins, à peu près à la même hauteur, tous les 44 studs.
- Aucune ne passe au-dessus d'une place de duel.

**La variété** (l'ANIMATEUR, 22/11, François : « le village est trop lisse ») : la `variety_pass` de `konoha_layout.py` tourne sur le tissu généré.
- Des lots deviennent des tours de 28 studs qui cassent la ligne des toits : 14 tours, à au moins 55 studs l'une de l'autre, jamais près d'un point du jeu. On y monte d'un bond depuis les toits voisins.
- Des jardinets remplissent les vides, jamais devant une porte.

### 2. Ce qui reste fixe : le Konoha qu'on reconnaît

Les repères, les rues et les places ouvertes viennent de `tools/blender/konoha_layout.py`, le fichier de l'ANIMATEUR. Ils ne bougent pas :
- le rocher et ses visages ;
- la résidence ronde ;
- la grande porte et la rue principale ;
- Ichiraku ;
- la salle d'examen ;
- les Hyūga et les Uchiha ;
- la Naka et son sanctuaire ;
- le terrain n° 3 ;
- toutes les places où se battent les maîtres et les duels de rue.

Le générateur ne touche qu'au tissu entre ces repères : les maisons, les passerelles et la course sur les toits.

### 3. La note sur 10

| Mesure | Ce qu'elle dit |
|---|---|
| un seul réseau | la part des toits reliés en un réseau, par des sauts ou des bonds |
| fluide | la part des maisons dans un îlot qu'on fait en entier sans le second saut (8 toits ou plus) |
| plus longue course | la plus longue course sans toucher le sol, rien qu'en sauts fluides, comparée à 450 |
| accès | la part des toits qu'on atteint de la rue : par la course sur le mur (27,7) ou par un voisin plus bas |
| bâti | la part du sol constructible (hors rues et places) couverte par un toit, comparée à 50 % |
| portes | la porte regarde sa rue, avec une sortie dégagée |
| ligne des toits | deux voisins diffèrent de 7 au plus |
| chevauchements | une pénalité |

### 4. La planche

`work/village/planche_village.png` montre côte à côte :
- le plan du jeu et le candidat retenu ;
- les toits colorés selon leur hauteur ;
- la plus longue course en rouge ;
- la course des toits en orange.

### 5. On ne garde que ce qui bat l'existant

`write` refuse d'écrire un candidat dont la note ne dépasse pas celle du plan du jeu.

## Les commandes

Depuis `games/ninja-duel` :

```sh
python3 tools/village/konoha_village.py search 24    # 24 candidats, la planche du meilleur
python3 tools/village/konoha_village.py write 9      # écrit src/Shared/KonohaLayout.luau (graine 9)
python3 tools/village/konoha_village.py score        # la note du plan du jeu

# puis, comme pour tout plan : le village que Hub.build construit, prouvé et rendu en gris
lune run tools/syphodev/konoha_dump.luau work/map/konoha.json
python3 tools/syphodev/konoha_spec.py work/map/konoha.json work/map/konoha_spec.json
python3 tools/syphodev/konoha_prove.py work/map/konoha_spec.json work/map/konoha_report.json > work/map/konoha_report.txt
python3 tools/village/render_village.py work/map/konoha.json work/village --rings work/village/rings.json
```

## Ce que le jeu en lit

`src/Shared/KonohaLayout.luau` garde son format. Il gagne deux listes :
- `Bridges` : les passerelles. `Server/Hub` les pose en planches entre les deux toits.
- `Race` : la course des toits. C'est une boucle qui part des terrasses de THE ROOFTOPS, avec 10 anneaux sur des toits.
  - Les médailles sont calculées à partir de sa longueur, au rythme où le robot de l'OUTILLEUR a couru la première course. Il faut les mesurer à nouveau avec `tools/villagebot`.
  - `Shared/Solo` prend ces anneaux et ces médailles à la place des siens.
