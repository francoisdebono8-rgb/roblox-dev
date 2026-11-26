# Collisions de Konoha : 24/11 c40cc16d et 26/11 f28b8ba1

Les mêmes rayons dans les deux places, quel que soit ce qui rend la place solide. Pour chaque bâtiment, des rayons de tout autour, à hauteur du corps (1, 3, 5 et 8 studs), vers son milieu, et des rayons d'en haut sur son emprise. Un rayon **traverse** quand le dessin vient d'abord et le solide plus de 1.5 stud derrière (ou pas du tout) : le corps entre dans ce qu'il voit. Il est **fantôme** quand le solide vient plus de 1.5 stud avant le dessin : un mur invisible. Sur les toits, même seuil : les pieds dans le toit, ou posés au-dessus du dessin.

| Groupe | Bâtiments 24/11 c40cc16d / 26/11 f28b8ba1 | Façades traversées 24/11 c40cc16d | 26/11 f28b8ba1 | Murs invisibles 24/11 c40cc16d | 26/11 f28b8ba1 | Toits où l'on s'enfonce 24/11 c40cc16d | 26/11 f28b8ba1 | Toits invisibles 24/11 c40cc16d | 26/11 f28b8ba1 |
|---|---|---|---|---|---|---|---|---|---|
| bâtiments | 189 / 189 | 0 % | **1 %** | 16 % | **4 %** | 1 % | **0 %** | 5 % | **1 %** |
| objets et murs | 2 / 2 | 4 % | **4 %** | 22 % | **6 %** | 0 % | **0 %** | 55 % | **36 %** |
| arbres | 1 / 1 | 0 % | **0 %** | 0 % | **0 %** | 3 % | **3 %** | 5 % | **5 %** |

## Par modèle

| Modèle | Bâtiments 24/11 c40cc16d / 26/11 f28b8ba1 | Façades traversées 24/11 c40cc16d | 26/11 f28b8ba1 | au pire (26/11 f28b8ba1) | Toits où l'on s'enfonce 24/11 c40cc16d | 26/11 f28b8ba1 | au pire (26/11 f28b8ba1) | Murs invisibles 26/11 f28b8ba1 |
|---|---|---|---|---|---|---|---|---|
| shop_house | 27 / 27 | 0 % | **4 %** | 7.5 | 0 % | **0 %** | 0.0 | 1 % |
| machiya | 60 / 60 | 0 % | **1 %** | 4.7 | 2 % | **0 %** | 0.0 | 2 % |
| small_house | 34 / 34 | 0 % | **1 %** | 3.0 | 0 % | **0 %** | 0.0 | 0 % |
| exam_hall | 1 / 1 | 6 % | **6 %** | 16.0 | 14 % | **14 %** | 20.0 | 12 % |
| exam_hall_wing | 2 / 2 | 0 % | **0 %** | 0.0 | 8 % | **8 %** | 20.0 | 8 % |
| hospital | 1 / 1 | 0 % | **0 %** | 0.0 | 13 % | **13 %** | 10.7 | 9 % |
| pier | 1 / 1 | 27 % | **27 %** | 20.0 | 0 % | **0 %** | 0.0 | 64 % |
| hyuga_gate | 1 / 1 | 0 % | **0 %** | 0.0 | 6 % | **6 %** | 5.4 | 0 % |
| uchiha_police | 1 / 1 | 0 % | **0 %** | 0.0 | 4 % | **4 %** | 5.2 | 0 % |
| water_tower | 1 / 1 | 0 % | **0 %** | 0.0 | 2 % | **2 %** | 1.5 | 53 % |
| academy_annex | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 9 % |
| clan_house | 24 / 24 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 0 % |
| tank_house | 21 / 21 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 7 % |
| tower_house | 4 / 4 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 7 % |
| torii | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 0 % |
| hokage_residence | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 59 % |
| memorial_stone | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 15 % |
| naka_shrine | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 48 % |
| hyuga_hall | 2 / 2 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 23 % |
| market_hall | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 11 % |
| ichiraku | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 0 % |
| apartment | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 12 % |
| great_gate | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 75 % |

### 26/11 f28b8ba1 : les bâtiments dont un quart des façades ou plus se traverse

| Bâtiment | Plan (x, z) | Rayons traversés | au pire (studs) | Solides |
|---|---|---|---|---|
| TrainingProps (TrainingProps) | -203.1,29.2 | 3 / 8 | 20.0 | 2 |
| UchihaPier (pier) | 230.1,-78 | 6 / 22 | 20.0 | 2 |

## Le corps : la marche contre la façade, la chute sur le toit

Le corps du joueur marche vers la façade côté rue jusqu'à ce que le solide l'arrête ; puis il tombe au milieu du toit.

| | 24/11 c40cc16d | 26/11 f28b8ba1 |
|---|---|---|
| Façades où le corps entre de plus de 0.5 stud | 23 sur 175 | **16 sur 160** |
| dont rien ne l'arrête à hauteur du corps | 0 | **0** |
| Toits où les pieds finissent à plus de 0.75 stud sous le dessin | 0 sur 190 | **34 sur 190** |
| enfoncement médian des pieds (toutes les chutes) | 0.0 studs | **0.1 studs** |
| chutes à plus de 6 studs sous le toit | 0 | **0** |

### 26/11 f28b8ba1 : les façades où le corps entre

| Bâtiment | Plan (x, z) | Façade dessinée à | Solide à | Le corps entre de |
|---|---|---|---|---|
| MemorialStone (MemorialStone) | -223.6,101.4 | 6.0 | 6.0 | **25.4** |
| NakaShrine (naka_shrine) | 329.9,-140.4 | 6.8 | 6.4 | **8.6** |
| clan_house (clan_house) | 333,-173.7 | 6.0 | 6.0 | **6.7** |
| clan_house (clan_house) | -322.4,216.9 | 6.0 | 6.0 | **6.4** |
| clan_house (clan_house) | 202.5,-200.9 | 6.0 | 6.0 | **6.3** |
| clan_house (clan_house) | -356.5,216.8 | 6.0 | 6.0 | **6.3** |
| clan_house (clan_house) | 332.5,-106.7 | 6.0 | 6.0 | **6.3** |
| clan_house (clan_house) | 332.3,-78 | 6.0 | 6.0 | **6.2** |
| SwingTree (academy_tree) | -29.4,-18.5 | 14.5 | 14.5 | **4.8** |
| shop_house (shop_house) | 130.6,257.9 | 9.5 | 9.5 | **2.0** |
| clan_house (clan_house) | -151.4,169 | 7.5 | 7.5 | **1.9** |
| clan_house (clan_house) | 333.3,-238.8 | 7.3 | 7.3 | **1.7** |
| clan_house (clan_house) | 361.6,-107.2 | 7.4 | 7.4 | **1.7** |
| clan_house (clan_house) | 361.5,-78 | 7.3 | 7.3 | **1.6** |
| small_house (small_house) | -313.4,175.5 | 7.5 | 8.6 | **1.0** |
| clan_house (clan_house) | 203.3,-134.7 | 7.4 | 7.4 | **0.9** |

### 26/11 f28b8ba1 : les toits où l'on s'enfonce

| Bâtiment | Plan (x, z) | Toit dessiné à | Solide à | Pieds à | Sous le toit de |
|---|---|---|---|---|---|
| small_house (small_house) | -90.7,215 | 18.1 | 17.1 | 16.8 | **1.3** |
| small_house (small_house) | -343.6,175.8 | 17.4 | 16.5 | 16.1 | **1.3** |
| small_house (small_house) | -111.2,137.5 | 19.3 | 18.2 | 18.0 | **1.3** |
| small_house (small_house) | -363,175.6 | 18.8 | 17.8 | 17.6 | **1.2** |
| small_house (small_house) | -217.6,136.5 | 18.8 | 17.8 | 17.6 | **1.2** |
| small_house (small_house) | -50.4,214.6 | 19.3 | 18.2 | 18.1 | **1.2** |
| small_house (small_house) | -189.8,137 | 17.7 | 16.7 | 16.4 | **1.2** |
| small_house (small_house) | -170.6,136.4 | 19.3 | 18.2 | 18.1 | **1.2** |
| small_house (small_house) | -308.6,151.4 | 19.0 | 18.0 | 18.0 | **1.1** |
| small_house (small_house) | -171.2,215 | 17.7 | 16.7 | 16.6 | **1.1** |
| small_house (small_house) | -69.7,214.4 | 17.0 | 16.0 | 15.9 | **1.1** |
| small_house (small_house) | -112.1,165.8 | 19.3 | 18.2 | 18.2 | **1.1** |
| small_house (small_house) | -50.4,244.2 | 16.3 | 15.4 | 15.3 | **1.0** |
| small_house (small_house) | -215.9,254 | 17.4 | 16.5 | 16.5 | **1.0** |
| small_house (small_house) | -84,239.3 | 18.3 | 17.3 | 17.3 | **1.0** |
| small_house (small_house) | -148.3,234.8 | 18.1 | 17.1 | 17.1 | **1.0** |
| small_house (small_house) | -363,145.4 | 15.6 | 14.7 | 14.6 | **1.0** |
| small_house (small_house) | -111.8,216.7 | 18.1 | 17.1 | 17.1 | **1.0** |
| small_house (small_house) | -277.9,151.4 | 17.9 | 16.9 | 16.9 | **1.0** |
| small_house (small_house) | -111.9,239.3 | 17.0 | 16.0 | 16.0 | **1.0** |

