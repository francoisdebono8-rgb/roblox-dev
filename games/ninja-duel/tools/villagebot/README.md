# Le robot qui parcourt Konoha (OUTILLEUR, 21-22/11)

C'est la tâche OUTILLEUR 1 de l'étape 3 (DEC-047) : un robot qui parcourt le village. Il mesure :
- les temps entre les lieux ;
- le temps réel de la course des toits ;
- si les toits et les maîtres en hauteur sont atteignables ;
- si quelqu'un reste coincé.

Le prouveur de carte (`tools/syphodev`) le dit sur le papier : ce qu'on peut atteindre, les pièges, les chevauchements. Le robot le vérifie dans le jeu, avec la vraie physique de Roblox.

## Ce qu'il fait

Il joue comme client, dans un Play d'une copie de ND-JEU dans `LAB/robots`, jamais dans la place d'une autre discussion. Il bouge l'avatar comme un joueur :
- `Humanoid:Move` à chaque image, après les commandes par défaut ;
- la vitesse de course de `Client/HubMove` (36) ;
- le saut et le second saut.

La course sur les murs, c'est le jeu qui la fait (`Client/HubMove`) quand le robot saute dans un mur.

| Mesure | Comment | Ce qu'il rapporte |
|---|---|---|
| **Les trajets** (`routes`) | Il fait le tour de tous les lieux, du plus proche au plus proche, puis revient à la porte. Le chemin est calculé par `PathfindingService` ; il saute là où le chemin le dit, et là où il n'avance plus. | Pour chaque trajet : le temps en courant, la longueur, le temps à la marche (longueur / 16), arrivé ou non. Chaque blocage : où, contre quelle pièce. Une chute hors de la carte. |
| **La course des toits** (`race=n`) | Il va au poteau de départ, lance la course (`SoloRace`, comme le client), puis va d'anneau en anneau tout droit. Un mur sur la route : il saute dedans, le jeu le fait courir jusqu'au toit. Un bord de toit : il saute et fait le second saut. Quelque chose au-dessus de sa tête : il en sort d'abord. | Le temps du serveur (`NinjaSoloTime`), le temps de chaque anneau, l'anneau où il a échoué. |
| **Les toits** (`roofs=n`) | Un échantillon de toits, du plus bas au plus haut. Pour un bâtiment aux murs courables (`NinjaWall`), il court au mur et saute dedans. Sinon, il se place juste hors de l'avant-toit, saute, fait le second saut en haut du saut et entre au-dessus du toit. Trois essais. | Atteint ou non, en combien d'essais et de secondes, la hauteur des pieds la plus haute. |
| **Le saut** (`jump=true`) | Sur place : un saut, le second saut en haut du premier, le second saut le plus tôt possible. | La montée des pieds dans chaque cas. |

Les lieux viennent de `HubMap` : les apparitions, l'examinateur, les maisons des huit maîtres, le terrain d'entraînement, le marché. Dans le nouveau Konoha (`Config.Hub.Layout = "konoha2"`), les points d'intérêt du plan (`KonohaLayout.Pois`) s'y ajoutent. Un point d'intérêt est souvent un bâtiment : il compte comme atteint à 14 studs.

`Bot.toward(goal, limite, fini)` est la façon « ninja » d'aller quelque part ; la course et les maîtres en hauteur s'en servent. `Bot.climb(toit)` monte sur un toit donné.

## Les commandes

```sh
python3 tools/villagebot/studio_code.py --module                          # Edit ou Client : installe ReplicatedStorage.NDVillageBot
python3 tools/villagebot/studio_code.py --start '{"routes":true,"race":2,"roofs":10,"jump":true}'   # Client, pendant un Play, dans le village
python3 tools/villagebot/studio_code.py --read                            # Client : l'état et les résultats (JSON)
```

Dans un Play, un nouveau profil commence par le premier combat. Il faut le finir (ou le gagner avec le robot débutant, `tools/duelbot`) avant de lancer le robot du village.

## Les mesures

### Le village généré, acfb00d6 (23/11, étape 4)

Fichier : `mesures/2026-11-23_studio_acfb00d6_village_genere.json`. C'est le village de 225 maisons, avec 245 toits de plus de 8 studs.

- **La course des toits**, prise du robot nouveau joueur (`tools/newplayer`) dans le même Play :
  - 14 courses, les 10 anneaux à chaque fois ;
  - de 19,5 à 28,7 s, médiane 22,7 s, meilleur temps 19,5 s.

  **Les médailles du DEV (or 27 s, argent 34 s, bronze 45 s) tiennent.** Le robot fait le meilleur temps d'un joueur qui connaît le parcours et ne rate rien. L'or demande de le connaître ; le bronze laisse le temps de chercher.
- **Les toits** :
  - Avec l'ancienne montée, 2 toits sur 10. Dans le village généré, une clôture, une caisse ou un jardin est souvent entre la rue et le mur : le robot ne touchait pas le mur et ne sautait pas.
  - **La montée corrigée** : il saute contre tout mur courable (`NinjaWall`), ou après une demi-seconde sans avancer ; deux sauts au plus. Il monte alors sur **9 toits sur 10**, de 10,4 à 32,5 studs, chaque fois au premier essai, en 0,8 à 2,5 s.
  - Le seul échec est une machiya à 16,9 : les pieds restent à 10,3 en trois essais.
  - Les toits, par hauteur d'avant-toit :

    | Avant-toit | ≤ 12 | 12–15 | 15–18 | 18–21 | 21–25 | > 25 |
    |---|---|---|---|---|---|---|
    | Toits | 13 | 27 | 45 | 32 | 67 | 61 |
- **Le tour** : 35 lieux, aucune chute ; 29 atteints.
  - Les trajets les plus longs :
    - du château d'eau au sanctuaire, 19,5 s (470 studs) ;
    - du maître Sand à la porte, 19,2 s (374 studs) ;
    - du sanctuaire à la salle d'examen, 13,7 s.
  - **L'hôpital** : il reste coincé 4 fois contre les murs d'une `tower_house`, au même endroit (−109,7 ; −228,7 du plan). Le chemin du moteur passe par là.
  - La résidence et les archives sont des bâtiments : il n'arrive pas à 14 studs de leur centre.
  - Les visages : il arrive au-dessus (46 studs plus haut). Le point est au pied de la falaise.
  - Les maîtres Mirage (sur le torii, 18,6 plus haut) et Sand (sur son balcon) : pas de chemin pour le moteur, il y va tout droit sans arriver. Le mode qui y saute (`high`, par `Bot.toward`) n'a pas été relancé sur le village généré ; le 22/11, il les atteignait.
- **Le saut** : le second saut en haut du premier monte les pieds de 26,3 studs ; le plus tôt possible, de 22,7.
- **Le promeneur ninja** du DEV (`HubBody`) n'est qu'une apparence. Il bouge avec la même physique (`HubMove`) : les temps du robot valent pour lui.

### Le nouveau Konoha, 554f1dec (22/11)

Fichier : `mesures/2026-11-22_studio_554f1dec_nouveau_konoha.json`.

- **La course des toits** : les 10 anneaux passés, deux fois. 22,3 s puis 23,5 s (temps du serveur). C'est le temps d'un joueur qui connaît le parcours et ne rate rien. L'anneau 7 (« back west over the cross lane ») est le plus long : 3,6 à 4,2 s.
- **Les toits** : 10 toits de 10,4 à 28,6 studs, tous atteints, en 1 à 1,5 s par la course sur le mur (un en 6 s, au second essai).
- **Les maîtres en hauteur**, tous atteints :
  - Sand, sur le balcon de la salle d'examen (16,2) : par le double saut, en 1,9 s ;
  - Mirage, sur le torii du sanctuaire (20,8) : par le mur du torii, au second essai ;
  - Flashstep, sous les visages (31,2) : en 13,5 s depuis la rue.
- **Le tour** : 35 lieux, aucune chute.
  - Les lieux au sol sont atteints, sauf :
    - trois points d'intérêt qui sont des bâtiments (l'hôpital, la résidence du Hokage, les archives) : il n'arrive pas à 14 studs de leur centre ;
    - deux lieux du marché, où il a fini sur un toit voisin.
  - Le plus long trajet : du château d'eau au sanctuaire, 16,4 s en courant (423 studs, 26,5 s à la marche).
  - Une fois coincé : contre les murs de la résidence du Hokage, en voulant passer tout droit vers les visages. La course sur le mur le monte à 34-37 studs, sous son toit (52).
  - Le chemin du moteur ne trouve pas de route vers les visages derrière la résidence. Le robot y arrive en la contournant.
- **Le double saut** monte les pieds de 26 studs dans cette place (18 dans l'ancienne, 8aaa6fd4). Le simple saut reste à 12,7. C'est à confirmer, car le robot fait son second saut lui-même, à côté de celui du jeu.

### L'ancien Konoha, 8aaa6fd4 (21/11)

Fichier : `mesures/2026-11-21_studio_8aaa6fd4_ancien_konoha.json`.

- Les 14 trajets entre les lieux sont arrivés, sans blocage ni chute.
- Le plus long est le retour de Flashstep à la porte : 19,4 s en courant, 618 studs (38,6 s à la marche).
- Le double saut montait les pieds de 18 studs.
- Les toits des maisons commençaient à 21 studs : aucun n'était atteignable depuis la rue sans marchepied. Le robot a atteint 7 des 10 toits bas (avant-toit à 11-13 studs).

## Ce qu'il ne prouve pas

- Le chemin du tour est celui de `PathfindingService`, pas celui d'un joueur qui connaît le village. Un trajet qui échoue peut avoir une autre route.
- Les toits : un échec du robot n'est pas une preuve qu'on ne peut pas y monter. Le prouveur donne la liste complète ; le robot vérifie un échantillon dans le jeu.
- La course : c'est le meilleur temps d'un joueur sans hésitation. Il ne cherche pas la caméra et ne rate pas de saut. Un vrai joueur mettra plus.
