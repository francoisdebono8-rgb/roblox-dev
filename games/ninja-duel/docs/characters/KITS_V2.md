# Kits v2 — chakra propre, combos libres, signes des mains (DEC-032, 03/11)

Utilisateur, 03/11 : « le chakra pour l'instant c'est nul, tu frappes plus fort mais pas de trucs » ; « des techniques ne sont pas adaptées au personnage, propose-en plus : Kakashi jeune est un expert du Doton, Gaara a du sable de partout et devrait pouvoir faire ce qu'il veut avec, Lee envoie des patates super vite, Naruto a le Rasengan, la métamorphose ».

## 1. Le chakra change le coup selon le perso

Chakra chargé (Z au clavier QWERTY, W en AZERTY, L2 à la manette), puis l'action. Aujourd'hui (`Server/ChakraFlow`), le coup chargé est seulement plus fort et un peu plus long, avec un petit effet de nature. En v2, chaque perso a sa **signature** : le coup chargé devient autre chose.

| Perso | Coup léger chargé | Coup lourd chargé | Saut chargé | Esquive chargée |
|---|---|---|---|---|
| Sasuke | Chidori Nagashi : la foudre traverse la garde, et le corps reste paralysé un instant | coup de pied de feu : la cible brûle, et une gerbe de feu part devant | saut de chakra | ruée vers lui |
| Naruto | un clone surgit à côté de lui et frappe à la suite | trois clones le soulèvent (U-ZU-MA-KI) | rebond sur un clone : double saut | clone-leurre : Naruto part sur le côté, le clone reste |
| Gaara | poing de sable jusqu'à 8 studs | la main de sable saisit les jambes : immobilisé 0,8 s | nuage de sable : il plane | glissement de sable (déjà là) |
| Lee | rafale : 4 « patates » en un éclair, la dernière projette | Konoha Senpū qui casse la garde | saut énorme, sans chakra (la force pure) | pas éclair dans son dos (image résiduelle) |
| Neji | Jūken : ferme un point de chakra ; à 3 points, l'adversaire ne peut plus charger | paume à vide à distance | saut | mini Rotation qui renvoie lames et coups |
| Itachi | les corbeaux s'envolent de l'impact et aveuglent un instant | paume de feu | saut | il se disperse en corbeaux et réapparaît à 6 studs |
| Minato | le coup pose une marque du Dieu du Tonnerre Volant sur lui | Rasengan au corps (il l'a inventé) | saut | éclair jusqu'à la marque la plus proche |
| Kakashi | lame de foudre sur le tantô ou le poing | Doton : un pic de terre jaillit sous lui et le soulève | saut | plongée sous terre et ressortie dans son dos |

## 2. Des combos libres

- **Fin des chaînes fixes** de 3 à 5 coups (`Light1 → Light2 → Light4 → Light3`). Chaque coup qui touche ouvre une fenêtre : léger, lourd, coup chargé, saut, dash, saisie ou jutsu peuvent suivre, dans tous les ordres.
- **Chaque coup a sa variante selon le stick** :
  - vers lui : pousse et lance ;
  - en arrière : balayage ;
  - sur le côté : angle ;
  - au sol, en l'air, contre un mur.
- **Les coups propres à chaque perso** remplacent les chaînes génériques :
  - Lee enchaîne vite et longtemps ;
  - Gaara frappe lentement mais de loin ;
  - Neji compte ses trigrammes (2, 4, 8…) ;
  - Naruto passe le relais à ses clones.
- **La défense reste possible** :
  - rythme : un coup répété trop vite sort plus lentement ;
  - réduction des dégâts dans le combo ;
  - plafond du combo ;
  - substitution ;
  - garde et esquive aux points d'annulation.

## 3. Plus que 4 cases : les signes des mains

- **Touche de signe tenue** (C au clavier, L1 + R1 à la manette), puis 2 ou 3 signes avec les touches 1 à 4 (Rat, Bœuf, Tigre, Serpent…). Le jutsu part au dernier signe, et chaque signe se voit dans les mains.
- **Les 4 cases rapides restent** : ce sont les favoris, et la manette en a besoin.
- **8 à 12 jutsu par perso**, tirés de l'histoire. Chaque jutsu a ses variantes : en l'air, en courant, depuis un mur, après un coup, chargé.

## 4. Les kits (âges du tournoi : 12 à 14 ans)

Les techniques déjà en jeu sont en **gras**.

- **Sasuke** : **Grande Boule de Feu**, **Fleur de Phénix**, **Chidori**, **Piège de fil (Dragon de Flammes)**, Lion Combo, Shuriken Ombre, Moulin à trois lames, Sharingan (lecture), marque maudite (éveil).
- **Naruto** : **Clone**, **Rasengan avec un clone**, **Multi-clonage**, **Rendan**, métamorphose (en objet pour esquiver, en l'adversaire pour tromper), Fuma Shuriken caché, chakra de Kyūbi (éveil).
- **Gaara** : **Shuriken de sable**, **Cercueil de sable**, **Vague du désert**, **Armure de sable**, bouclier automatique, saisie de sable à distance, pics de sable, clone de sable, sables mouvants, nuage de sable, troisième œil, Funérailles impériales (ultime).
- **Lee** : **Grand Tourbillon**, **Lotus primaire**, **Poids retirés**, **Entrée dynamique**, rafale de la Feuille (les « patates »), Konoha Senpū, Poing de l'homme ivre, portes 1 à 5, Lotus caché (ultime).
- **Neji** : **Paume à vide**, **64 Paumes**, **Rotation**, **Byakugan**, 128 paumes (ultime), points de chakra fermés par le Jūken.
- **Itachi** : **Shuriken en éventail**, **Boule de feu**, **Mirage (genjutsu)**, **Lecture**, clone de corbeaux, clone explosif, tir de shuriken à l'aveugle (ricochet), Tsukuyomi (ultime).
- **Minato** : **Kunai marqué**, **Lightning Strike**, **Dieu du Tonnerre Volant**, **Lame de vent**, Rasengan, marques multiples, coupe du Dieu du Tonnerre Volant.
- **Kakashi** : **Dragon d'eau**, **Lame de foudre**, **Crocs de traque**, **Coupe de foudre (tantô)**, Doton : mur de terre (arrête coups et projectiles, et devient un mur où courir), Doton : chasseur de têtes (sous terre, il saisit les jambes), Doton : dragon de terre, copie (le Sharingan rejoue le dernier jutsu subi), tantô de chakra blanc.

## Ordre de construction

1. Signatures de chakra pour les 8 (tableau 1).
2. Kits : les nouveaux jutsu, chacun vérifié dans Studio.
3. Signes des mains : saisie, HUD, au-delà de 4.
4. Combos libres : un graphe de liens à la place des chaînes, d'abord sur Sasuke.
5. Le corps avec Mixamo, en parallèle dès que le compte Adobe est prêt.
