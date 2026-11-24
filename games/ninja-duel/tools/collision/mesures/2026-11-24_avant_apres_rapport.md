# Collisions de Konoha : avant (23/11) et après (24/11)

Les mêmes rayons dans les deux places, quel que soit ce qui rend la place solide. Pour chaque bâtiment, des rayons de tout autour, à hauteur du corps (1, 3, 5 et 8 studs), vers son milieu, et des rayons d'en haut sur son emprise. Un rayon **traverse** quand le dessin vient d'abord et le solide plus de 1.5 stud derrière (ou pas du tout) : le corps entre dans ce qu'il voit. Il est **fantôme** quand le solide vient plus de 1.5 stud avant le dessin : un mur invisible. Sur les toits, même seuil : les pieds dans le toit, ou posés au-dessus du dessin.

| Groupe | Bâtiments avant (23/11) / après (24/11) | Façades traversées avant (23/11) | après (24/11) | Murs invisibles avant (23/11) | après (24/11) | Toits où l'on s'enfonce avant (23/11) | après (24/11) | Toits invisibles avant (23/11) | après (24/11) |
|---|---|---|---|---|---|---|---|---|---|
| bâtiments | 228 / 189 | 3 % | **0 %** | 10 % | **16 %** | 56 % | **1 %** | 2 % | **5 %** |
| objets et murs | 2 / 2 | 4 % | **4 %** | 0 % | **22 %** | 0 % | **0 %** | 0 % | **55 %** |
| arbres | 1 / 1 | 0 % | **0 %** | 100 % | **0 %** | 77 % | **3 %** | 18 % | **5 %** |

## Par modèle

| Modèle | Bâtiments avant (23/11) / après (24/11) | Façades traversées avant (23/11) | après (24/11) | au pire (après (24/11)) | Toits où l'on s'enfonce avant (23/11) | après (24/11) | au pire (après (24/11)) | Murs invisibles après (24/11) |
|---|---|---|---|---|---|---|---|---|
| machiya | 47 / 60 | 3 % | **0 %** | 0.0 | 97 % | **2 %** | 8.2 | 15 % |
| exam_hall | 1 / 1 | 0 % | **6 %** | 16.0 | 71 % | **14 %** | 20.0 | 17 % |
| exam_hall_wing | 2 / 2 | 0 % | **0 %** | 0.0 | 29 % | **8 %** | 20.0 | 34 % |
| pier | 1 / 1 | 27 % | **27 %** | 20.0 | 0 % | **0 %** | 0.0 | 64 % |
| hospital | 1 / 1 | 0 % | **0 %** | 0.0 | 7 % | **13 %** | 10.7 | 17 % |
| hyuga_gate | 1 / 1 | 0 % | **0 %** | 0.0 | 49 % | **6 %** | 5.4 | 0 % |
| uchiha_police | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **4 %** | 5.2 | 0 % |
| water_tower | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **2 %** | 1.5 | 53 % |
| market_hall | 1 / 1 | 0 % | **0 %** | 0.0 | 43 % | **0 %** | 0.0 | 11 % |
| clan_house | 36 / 24 | 1 % | **0 %** | 0.0 | 76 % | **0 %** | 0.0 | 29 % |
| memorial_stone | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 25 % |
| hyuga_hall | 2 / 2 | 8 % | **0 %** | 0.0 | 90 % | **0 %** | 0.0 | 23 % |
| tank_house | 50 / 21 | 0 % | **0 %** | 0.0 | 11 % | **0 %** | 0.0 | 4 % |
| small_house | 20 / 34 | 1 % | **0 %** | 0.0 | 99 % | **0 %** | 0.0 | 12 % |
| torii | 1 / 1 | 0 % | **0 %** | 0.0 | 22 % | **0 %** | 0.0 | 0 % |
| ichiraku | 1 / 1 | 0 % | **0 %** | 0.0 | 14 % | **0 %** | 0.0 | 0 % |
| naka_shrine | 1 / 1 | 2 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 48 % |
| apartment | 27 / 1 | 3 % | **0 %** | 0.0 | 19 % | **0 %** | 0.0 | 30 % |
| great_gate | 1 / 1 | 12 % | **0 %** | 0.0 | 100 % | **0 %** | 0.0 | 75 % |
| academy_annex | 1 / 1 | 0 % | **0 %** | 0.0 | 49 % | **0 %** | 0.0 | 19 % |
| hokage_residence | 1 / 1 | 0 % | **0 %** | 0.0 | 0 % | **0 %** | 0.0 | 47 % |
| tower_house | 14 / 4 | 0 % | **0 %** | 0.0 | 30 % | **0 %** | 0.0 | 11 % |
| shop_house | 16 / 27 | 18 % | **0 %** | 0.0 | 71 % | **0 %** | 0.0 | 15 % |

### après (24/11) : les bâtiments dont un quart des façades ou plus se traverse

| Bâtiment | Plan (x, z) | Rayons traversés | au pire (studs) | Solides |
|---|---|---|---|---|
| TrainingProps (TrainingProps) | -203.1,29.2 | 3 / 8 | 20.0 | 2 |
| UchihaPier (pier) | 230.1,-78 | 6 / 22 | 20.0 | 2 |

## Le corps : la marche contre la façade, la chute sur le toit

Le corps du joueur marche vers la façade côté rue jusqu'à ce que le solide l'arrête ; puis il tombe au milieu du toit.

| | avant (23/11) | après (24/11) |
|---|---|---|
| Façades où le corps entre de plus de 0.5 stud | 41 sur 212 | **23 sur 175** |
| dont rien ne l'arrête à hauteur du corps | 21 | **0** |
| Toits où les pieds finissent à plus de 0.75 stud sous le dessin | 140 sur 229 | **0 sur 190** |
| enfoncement médian des pieds (toutes les chutes) | 4.6 studs | **0.0 studs** |
| chutes à plus de 6 studs sous le toit | 63 | **0** |

### après (24/11) : les façades où le corps entre

| Bâtiment | Plan (x, z) | Façade dessinée à | Solide à | Le corps entre de |
|---|---|---|---|---|
| small_house (small_house) | -148.3,234.8 | 6.0 | 6.0 | **31.8** |
| machiya (machiya) | 162.2,-141.2 | 6.3 | 6.3 | **30.5** |
| small_house (small_house) | -90.7,215 | 6.0 | 6.0 | **30.3** |
| tank_house (tank_house) | -70.7,-85.5 | 6.3 | 6.0 | **29.9** |
| shop_house (shop_house) | 285.2,164.1 | 8.1 | 8.1 | **27.5** |
| machiya (machiya) | 256.9,16.5 | 10.0 | 9.8 | **24.2** |
| machiya (machiya) | 194.2,174.7 | 9.6 | 9.6 | **24.0** |
| machiya (machiya) | -63.1,138.1 | 10.7 | 10.7 | **23.7** |
| shop_house (shop_house) | 168.2,218.5 | 10.7 | 10.7 | **23.6** |
| clan_house (clan_house) | -239.5,140.3 | 7.3 | 7.3 | **23.5** |
| machiya (machiya) | 313.4,50 | 11.5 | 11.5 | **23.1** |
| clan_house (clan_house) | 361.6,-107.2 | 7.2 | 7.2 | **22.7** |
| clan_house (clan_house) | -356.5,216.8 | 13.4 | 13.4 | **18.4** |
| clan_house (clan_house) | -322.4,216.9 | 16.9 | 15.8 | **15.7** |
| clan_house (clan_house) | 202.2,-167.6 | 19.2 | 17.8 | **13.5** |
| NakaShrine (naka_shrine) | 329.9,-140.4 | 6.8 | 6.4 | **8.6** |
| ExamHallWest (exam_hall_wing) | -53.3,-87.1 | 7.3 | 7.3 | **7.6** |
| SwingTree (academy_tree) | -29.4,-18.5 | 14.5 | 14.5 | **5.6** |
| clan_house (clan_house) | 333,-173.7 | 6.0 | 6.0 | **4.0** |
| clan_house (clan_house) | 332.5,-106.7 | 6.0 | 6.0 | **3.6** |

