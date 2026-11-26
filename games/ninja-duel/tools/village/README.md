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

**Ni fente ni lampadaire devant un mur** (23/11, le robot de l'OUTILLEUR) :
- À côté d'un monument, une maison est collée (à moins de 1) ou à une ruelle (plus de 3, soit 3,9 studs dans le jeu). Jamais entre les deux : un corps s'y coince. C'est ce qui bloquait le robot entre l'hôpital et une tour, à 1,9 l'un de l'autre.
  - La maison est étirée jusqu'au monument, ou rétrécie jusqu'à la ruelle, dans les tailles de son modèle (0,8 à 1,15).
  - Si aucune des deux n'est possible, la fente est murée : la liste `Fills`, que `Server/Hub` construit en plâtre à la hauteur du plus bas des deux.
  - Sur la graine 5 : 19 maisons ajustées, aucune fente murée.
- Un lampadaire ne se tient jamais devant le milieu d'un mur qu'on court : il est à 3,5 au moins de chaque mur, ou à la jointure de deux maisons (à 1,5 du bout d'un mur). Le robot butait sur un lampadaire à 2,7 devant une machiya et ne touchait pas le mur.
  - Le lampadaire glisse le long de sa rue, jusqu'à 14, à 8 au moins d'un autre. S'il ne trouve pas de place, il est retiré.
  - Sur la graine 5 : 54 lampadaires glissés, aucun retiré.
- Aucune maison sur un mur d'enceinte (Uchiha, Hyūga) : les murs sont tenus libres comme les rues. Le prouveur de l'OUTILLEUR en trouvait 12 qui traversaient une maison.
- **Le village du jeu est passé de la graine 9 à la graine 5** (23/11 soir). Avec cette règle, la graine 9 tombait à 8,9/10. La graine 5 a 9,33/10 : un seul réseau de toits (100 %), tous les toits accessibles. Sa course fait 325 studs d'anneaux ; les médailles calculées sont 25/31/42, à mesurer de nouveau avec le robot.

**Passe commune 1 (23/11, François : « la ville est aléatoire, rien n'est cohérent » ; « un mix entre le vrai et le généré »)** :
- **Les quartiers d'une ville d'Edo.**
  - Les rues principales : des rangées de maisons de bois à deux étages et grands avant-toits (Tsumago, Kyoto).
  - Les résidences : des maisons en retrait dans leurs jardins (Ōuchi-juku).
  - Les grands blocs de Konoha à réservoir rond : seulement autour du quartier du Hokage (Civic).
- **Une rangée garde son modèle** et sa ligne de toits monte ou descend doucement (0,3 à 1,6 d'une maison à l'autre). Elle ne change de modèle qu'après une ruelle.
- **La densité par quartier** (`DENSE`) : le nombre de rangées derrière la rue. Le reste de l'îlot est en jardins et en arbres (jusqu'à 160). Seuls les quartiers denses comblent leurs trous par des maisons.
- **4 tours au plus** (des tours de guet), dans le marché, le centre et le quartier du Hokage.
- **Aucune maison sur un point du jeu** (maître, arrivée, surveillant, duel de rue), et aucune n'est étirée sur une rue ou une place.
- **Graine 13**, 8,67/10. Les toits forment deux réseaux, et non plus un seul : les rangées s'arrêtent devant les points du jeu.

### 5. On ne garde que ce qui bat l'existant

`write` refuse d'écrire un candidat dont la note ne dépasse pas celle du plan du jeu.

**Passe 3 (26/11, DEC-055 : « porte → salle de l'Examen sans toucher le sol »)** : une passe `landmark_links`, après la course des toits, qui ne la change donc pas.
- Chaque aile de la salle de l'Examen reçoit une passerelle venue du toit le plus proche, quand ce toit est plus loin que le second saut (22,3), à 28 au plus, et jamais au-dessus d'une place ouverte.
- Mesuré dans Studio : la salle était à 25,5 studs de base des toits de la ville, il n'y avait pas de route. Sur la graine 13, deux passerelles sont ajoutées : l'aile ouest par-dessus l'Avenue, l'aile est depuis le quartier du Hokage. La note passe de 8,67 à 8,68.
- Les deux lignes sont écrites à la main à la fin de `M.Bridges`, sans réécrire le fichier. Une réécriture complète (`write`) ajouterait 5 modèles du catalogue (edo_townhouse…) et perdrait la ligne `Forest` des lieux (DEC-054), écrite à la main elle aussi : il faut la remettre après un `write`.

## Les commandes

Depuis `games/ninja-duel` :

```sh
python3 tools/village/konoha_village.py search 24    # 24 candidats, la planche du meilleur
python3 tools/village/konoha_village.py write 13     # écrit src/Shared/KonohaLayout.luau (graine 13)
python3 tools/village/konoha_village.py score        # la note du plan du jeu

# puis, comme pour tout plan : le village que Hub.build construit, prouvé et rendu en gris
lune run tools/syphodev/konoha_dump.luau work/map/konoha.json
python3 tools/syphodev/konoha_spec.py work/map/konoha.json work/map/konoha_spec.json
python3 tools/syphodev/konoha_prove.py work/map/konoha_spec.json work/map/konoha_report.json > work/map/konoha_report.txt
python3 tools/village/render_village.py work/map/konoha.json work/village --rings work/village/rings.json
```

## Ce que le jeu en lit

`src/Shared/KonohaLayout.luau` garde son format. Il gagne trois listes :
- `Bridges` : les passerelles. `Server/Hub` les pose en planches entre les deux toits.
- `Fills` : les fentes murées à côté d'un monument (vide sur la graine 5).
- `Race` : la course des toits. C'est une boucle qui part des terrasses de THE ROOFTOPS, avec 10 anneaux sur des toits.
  - Les médailles sont calculées à partir de sa longueur, au rythme où le robot de l'OUTILLEUR a couru la première course. Il faut les mesurer à nouveau avec `tools/villagebot`.
  - `Shared/Solo` prend ces anneaux et ces médailles à la place des siens.
