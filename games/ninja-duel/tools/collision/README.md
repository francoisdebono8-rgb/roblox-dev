# Le robot de collision : ce qu'on traverse dans Konoha (OUTILLEUR, passe commune 1, DEC-051)

François, 23/11 : « les murs sont intangibles, comme les toits ».

Le village est fait deux fois :
- **le solide** : les parts du serveur (`Server/Hub`), qui arrêtent le corps ;
- **le dessin** : les modèles de l'ANIMATEUR, que chaque client pose à leur place en cachant les parts (`Client/HubDress`, `Client/MeshKit`).

Depuis le 23/11 au soir (DEV, `bba7af8c`), le client rend solides les morceaux dessinés eux-mêmes (`HubDress.solidify`) : pour un bâtiment ou un mur, les copies de `NinjaDuelHubDress` collisionnent, et la boîte du serveur ne bloque plus.

Là où le dessin et ce qui arrête le corps ne coïncident pas, le joueur entre dans ce qu'il voit, ou bute sur ce qu'il ne voit pas. Le robot (`NDCollisionBot`) le mesure de trois façons. Il est envoyé dans le client d'un Play de la place du jeu (DEC-052, `PLACES/NinjaDuel.rbxlx`, sans copie) : `python3 tools/robots/inject.py collision`.

1. **Le relevé** (`--survey`, quelques secondes pour tout le village).
   - Pour chaque unité habillée (maison, monument, objet), il reconstruit les triangles du dessin exactement là où `HubDress` les pose, à partir des données de `MeshKit`. Il les compare aux parts solides de l'unité, dans les deux sens :
     - **traversable** : un point du dessin à plus de 1,5 stud de tout solide. Le corps y entre avant d'être arrêté : une façade devant sa boîte, un toit au-dessus, un réservoir, un avant-toit, un balcon ;
     - **fantôme** : un point d'une face solide à plus de 1,5 stud du dessin. On y bute sur du vide.
   - Il range ces points par façade (normale horizontale) et par toit (normale vers le haut).
2. **Les rayons** (`--rays`, quelques secondes ; 24/11). La même mesure avant et après la passe, quoi que ce soit qui rende la place solide (les parts du serveur ou les morceaux dessinés). Pour chaque bâtiment :
   - des rayons de 16 directions, à 1, 3, 5 et 8 studs du sol, vers son milieu ;
   - 7 × 7 rayons d'en haut, sur son emprise.
   - Pour chaque rayon, le premier triangle du dessin contre le premier solide :
     - **traversé** : le dessin vient d'abord, et le solide plus de 1,5 stud derrière (ou pas du tout) ;
     - **fantôme** : le solide vient plus de 1,5 stud avant le dessin (un mur invisible, un toit invisible au-dessus du dessin).
3. **La marche** (`--walk`, environ 2 s par bâtiment, Studio au premier plan). Pour chaque bâtiment du plan et chaque monument, le vrai corps, avec la physique du promeneur :
   - **marche contre la façade côté rue**, jusqu'à ce que le solide l'arrête. Le robot note de combien l'avant du corps est entré dans la façade dessinée ;
   - **tombe sur le toit**, au milieu. Le robot note à combien de studs sous le toit dessiné ses pieds se posent.

```sh
python3 tools/collision/collision.py --survey            # Client, dans Konoha : le relevé de tout le village
python3 tools/collision/collision.py --walk              # Client : la marche (en fond, ~25 min ; --walk 20 pour un essai)
python3 tools/collision/collision.py --state             # où il en est
python3 tools/collision/collision.py --by-model          # le relevé, une ligne par modèle  -> mesures/<date>_<commit>_par_modele.txt
python3 tools/collision/collision.py --walk-lines 1 120  # la marche, une ligne par bâtiment -> mesures/<date>_<commit>_marche.txt
python3 tools/collision/collision.py --report PAR_MODELE.txt MARCHE.txt [--avant OLD_PAR_MODELE.txt OLD_MARCHE.txt] --html R.html
python3 tools/collision/collision.py --rays              # Client : les rayons
python3 tools/collision/collision.py --rays-lines 1 120  # les rayons, une ligne par bâtiment -> mesures/<date>_<commit>_rayons.txt
python3 tools/collision/collision.py --compare AVANT_rayons.txt APRES_rayons.txt --marche AVANT_marche.txt APRES_marche.txt --html R.html
```

## Avant la passe (23/11 au soir, place commune `d0678d90` de `890f237a`)

Fichiers : `mesures/2026-11-23_avant_d0678d90_par_modele.txt`, `…_marche.txt`, `…_rapport.md`.

Le résultat est dans `mesures/2026-11-23_avant_d0678d90_rapport.md`.

## Après la passe (24/11, place commune `c40cc16d`, sources `db13098f`, `PLACES/NinjaDuel.rbxlx`)

Fichiers : `mesures/2026-11-24_apres_c40cc16d_rayons.txt`, `…_marche.txt`, et la comparaison `mesures/2026-11-24_avant_apres_rapport.md` (et `.html`). Les rayons d'avant ont été pris le 24/11 dans la copie du 23/11, rouverte pour la même mesure (`mesures/2026-11-23_avant_d0678d90_rayons.txt`). La ville a changé entre les deux (`7c6c9c57`) : 228 bâtiments avant, 189 après ; on compare par modèle.

- **Les toits tiennent.** Les pieds ne s'enfoncent plus : 0 chute sur 190 finit sous le toit dessiné (avant : 140 sur 229, médiane 4,6 studs). Par les rayons, 1 % des points de toit (avant : 56 %).
- **Les façades ne se traversent plus aux rayons** : 0 % (avant : 3 %, jusqu'à 18 % pour `shop_house`). À la marche, aucun bâtiment n'est sans solide à hauteur du corps (avant : 21).
- **Il reste 23 façades où le corps entre** (avant : 41 sur 212), dont 18 de 13 à 32 studs. Le robot ne distingue pas un passage ouvert (une boutique, une porte, une cour) d'un mur qui ne tient pas, et la façade « dessinée » peut être un détail bas que le corps enjambe. Exemple refait à la main, `small_house` (-148.3, 234.8), depuis le côté de sa boîte : à 3 et 5 studs du sol, aucun solide sur 40 studs ; à 1 stud, un morceau `Tiles` à 4,5 studs, que le corps passe. La liste est dans le rapport : à regarder en jeu.
- **Les murs invisibles augmentent** : 16 % des rayons de façade (avant : 10 %), et le corps s'arrête à plus de 1,5 stud avant la façade dessinée devant 39 bâtiments (avant : 36). Deux causes trouvées :
  - **La collision des morceaux.** `MeshKit` crée les morceaux venus d'un asset avec `CollisionFidelity.Box` (`fromAsset`), et ceux qu'il cuit d'un `EditableMesh` avec la fidélité par défaut. Tant qu'ils ne collisionnaient pas, c'était sans effet. Solides, une boîte ou une enveloppe convexe dépasse le dessin.
    - Exemple, `clan_house` (203.4, -235.9) : un rayon à 3 studs bute sur l'enveloppe du morceau `Walls` à 4,3 studs ; le mur dessiné est à 11,5.
  - **Les grandes boîtes de la falaise et de l'escalier des Hokage.** `Stone` (110 × 32 × 122), `Rails` (108 × 30 × 109), `Lanterns` et `Caps`, centrés en (0, -241), sont en `Box`. Ils couvrent les trois `tank_house` de la rangée sud (-32.9, -240.6), (-1.6, -240.6), (32.3, -239.5) : on s'y tient debout 7,5 à 12 studs au-dessus du toit dessiné. Les échafaudages des visages (`Block`, `Scaffold`, `Rope`, en `Box`) et la falaise (`Cliff`, 429 × 121 × 90) aussi.

## Le 26/11 (place commune `f28b8ba1`, sources `9e8db7dc`, une Studio à soi)

Demande du DEV (INBOX-DEV-PASSE1-B) : relancer les rayons et la marche sur `6ae41cb3`. Cette place commune en descend ; elle porte les solides de chaque maison (`a1713839`, `Shared/HubSolids` de l'ANIMATEUR) et les monuments selon leur forme (`81986fbb`). Fichiers : `mesures/2026-11-26_f28b8ba1_rayons.txt`, `…_marche.txt`, la comparaison avec le 24/11 `mesures/2026-11-26_f28b8ba1_comparaison.md` (et `.html`), l'image `mesures/2026-11-26_f28b8ba1_images/`.

- **Les maisons collisionnent par des boîtes à elles** (4 à 15 parts `Solid1…`, plus de maillages) : les murs invisibles tombent de 16 % à 4 % des rayons de façade ; les toits invisibles de 5 % à 1 %.
- **Les rayons trouvent un peu de façade traversée** : 1 % (24/11 : 0 %), surtout `shop_house` (4 %, jusqu'à 7,5 studs). Ce sont des rayons, pas le corps : la marche n'y entre pas.
- **À la marche, 16 façades sur 160 où le corps entre de plus de 0,5 stud** (24/11 : 23 sur 175), et aucune sans solide à hauteur du corps. Six `clan_house` de 6,2 à 6,7 studs : c'est la véranda sous l'avant-toit, le corps s'arrête aux shōji (image `clan_house_veranda_333_-173.jpg`). Restent à regarder en jeu : `MemorialStone` (-223.6, 101.4), 25,4 studs, et `NakaShrine`, 8,6.
- **Les toits des `small_house` sont 1 stud trop bas** : 34 chutes sur 190 finissent 1,0 à 1,3 stud sous le toit dessiné, toutes sur des `small_house` (24/11 : aucune). Le toit solide (`Solid3`, `Solid4`) est environ 1 stud sous le dessin.
- **Le robot corrigé.** Entre deux maisons proches, le rayon qui cherchait la rue depuis 25 studs plus haut tombait sur le toit ou l'avant-toit du voisin. Le corps partait de là et marchait sur les toits : 18 « entrées » de 17 à 33 studs étaient fausses. La rue est maintenant cherchée depuis le pied du bâtiment, et la colonne `startY` dit où étaient les pieds au départ. Les 34 façades ont été remarchées ainsi. Celles qui partent à -3,5 studs avec un corps immobile n'ont pas de rue (le départ est dans la maison voisine) : elles comptent comme mesures ratées.
- `Bot.walk({at={{x,z},…}})` ne marche que les bâtiments à ces places du plan.

## À savoir pour le lancer

- **Studio en arrière-plan avance à peine.** Le 24/11, avec la fenêtre de Studio derrière les autres, la marche n'avançait que pendant les appels du pont (d'un bâtiment par appel court à 4 par minute sans appel). Il a fallu la suivre par appels courts, l'un après l'autre (`--state`). On ne met pas Studio au premier plan à la place de François (DEC-052).
- **Pendant la marche, ne pas garder Studio occupé.** Une commande du pont (`eval_client_runtime`) qui attend plusieurs secondes fige le corps du client tant qu'elle attend. Le 23/11, 47 marches ont rendu « 0 stud parcouru » pendant des attentes de 20 s. Il faut demander l'état par des appels courts (`--state`), espacés.
- Le rapport écarte les marches où le corps n'a pas bougé (moins de 0,2 stud) : elles sont comptées à part, comme mesures ratées.

## Ce qu'il ne prouve pas

- Le relevé compare le dessin aux parts solides de la même unité. Un toit posé sur la boîte d'une autre unité compterait comme traversable : ce n'est pas le cas des maisons du plan.
- Les feuilles des arbres se traversent par nature. Elles sont comptées à part et ne sont pas un défaut.
- La marche ne prend qu'une façade par bâtiment (côté rue) et un point de chaque toit (le milieu). Sa façade « dessinée » est la plus proche des trois hauteurs (1, 3 et 5 studs) : un détail bas que le corps enjambe compte comme la façade.
- Les rayons ne voient pas l'intérieur d'une porte ouverte : un passage ouvert dans le dessin et sans solide n'est pas compté comme traversé s'il n'est pas sur un rayon.
- Ce que le joueur ressent devant un mur : c'est à François de le dire en jouant.
