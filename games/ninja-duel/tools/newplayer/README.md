# Le robot « nouveau joueur » : les 10 premières minutes (OUTILLEUR, étape 5, DEC-049)

Il joue les dix premières minutes d'un nouveau joueur, dans un Play d'une copie LAB de ND-JEU. Studio commence chaque Play avec un profil neuf. Il fait ce que le jeu amène un nouveau joueur à faire, dans l'ordre :
1. il regarde le premier écran, puis lance le premier combat ;
2. il joue le premier combat comme un débutant (le joueur simulé de `tools/duelbot`) ;
3. il revient à Konoha, prend son inspiration (le départ) et met une tenue ;
4. il marche jusqu'au marché (le robot de `tools/villagebot`) ;
5. il fait un duel contre l'IA (easy) ;
6. il achète une apparence avec ses Ryō et apprend un nœud de son arbre ;
7. il fait la course des toits jusqu'aux 10 minutes.

À chaque étape, il note l'heure et ce qu'il voit à l'écran : les boutons visibles et les grands textes. L'entonnoir du serveur (`Matches.measure`, lignes `[NinjaDuelFirst]`) donne l'heure de chaque étape depuis l'arrivée.

```sh
python3 tools/lab/lab_place.py PLACES/ND-JEU.rbxlx LAB/robots/ND-JEU-robots-<commit>.rbxlx   # la copie, robots dedans
python3 tools/newplayer/studio_code.py --start 10 Legion     # Client, au début du Play
python3 tools/newplayer/studio_code.py --read                # Client : où il en est, le journal
python3 tools/newplayer/studio_code.py --funnel              # Server : les lignes de l'entonnoir
python3 tools/newplayer/studio_code.py --report LOG.json FUNNEL.txt
```

## Le 23/11 (ND-JEU `acfb00d6`, kit Naruto)

Fichier : `mesures/2026-11-23_studio_acfb00d6.json`.

| Étape (le serveur, depuis l'arrivée) | Temps |
|---|---|
| premier appui, premier combat lancé | 29 s |
| premier coup qui touche | 34 s |
| premier jutsu | 38 s |
| **premier combat gagné** | **1 min 14** |
| inspiration choisie | 1 min 24 |
| habillé | 1 min 28 |
| un nœud de l'arbre | 2 min 55 |
| premier achat en Ryō | **jamais en 10 minutes** |

- **Le premier combat est gagné en moins de 2 minutes** : la ligne de la liste « prêt à publier » est verte pour le robot.
  - Combat de 42,7 s, 3 consignes vues.
  - Mais le robot savait où était le combat : il a envoyé l'action directement.
  - Au premier écran, aucun des boutons à texte ne dit PLAY. On voit Konoha (« THE GREAT GATE ») avec DUELS, SHOP, QUESTS, RANKS et les noms des inspirations. Le robot ne lit que le texte : un bouton fait d'une image, ou une consigne dans le monde, lui échappe. À vérifier à l'œil : un vrai nouveau joueur trouve-t-il le combat ?
- **Après le premier combat**, l'écran de tenue s'ouvre seul (« YOUR NINJA », PICK A TOP), puis DONE.
- **Le duel contre l'IA** (easy) est gagné 2–0, en manches de 27 et 29 s. Il rapporte 215 Ryō, alors que l'apparence la moins chère coûte 250. **Le premier achat demande un deuxième duel** : en 10 minutes, le robot n'a rien pu acheter.
- **L'arbre** : 5 points après deux combats, le nœud le moins cher en coûte 4 (Chakra Flow).
- **La course des toits** : 14 courses, les 10 anneaux à chaque fois. De 19,5 à 28,7 s, médiane 22,7 s.
- Un refus : « STARTER ALREADY CHOSEN ». C'est le robot du duel qui redemande le départ ; un joueur ne le voit pas.

## Ce qu'il ne prouve pas

- Ce qu'un vrai nouveau joueur comprend : le robot ne cherche pas les boutons, il envoie l'action. Le premier écran et ses boutons sont notés pour qu'on voie ce qu'un joueur aurait eu à trouver.
- Il ne fait pas les quêtes ni la boutique en Robux.
