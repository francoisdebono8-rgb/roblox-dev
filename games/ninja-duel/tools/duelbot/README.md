# Le joueur simulé : le robot débutant et la durée des manches (OUTILLEUR, 21/11)

Ce sont les tâches OUTILLEUR 2 et 3 de l'étape 3 (DEC-047) :
- un robot débutant qui joue le premier combat comme un nouveau joueur ;
- la durée réelle des manches, avec un joueur simulé contre l'IA.

## Le joueur simulé (`PlayerSim.luau`)

Ce n'est pas une IA : il ne lit que ce qu'un joueur voit à l'écran (les deux corps, la vie, le chakra, la consigne du coach). Il voit tard, appuie tard et pas toujours sur la bonne touche. Il marche vers l'adversaire un peu de travers et martèle la frappe. Il lit la consigne au bout d'un moment, puis la fait, ou pas.

| Profil | Pour | Réaction | Lecture d'une consigne | Frappe | Ce qu'il sait faire |
|---|---|---|---|---|---|
| `debutant` | le premier combat | 0,45 à 1 s | 0,9 à 1,8 s, et il en suit 85 % | une frappe toutes les 0,28 à 0,5 s, une sur dix devient le coup lourd | garder et esquiver, une fois que la consigne les lui a montrés (une fois sur quatre) ; un jutsu au hasard toutes les 9 à 15 s |
| `joueur` | la durée des manches | 0,22 à 0,38 s | 0,5 à 0,9 s | une chaîne toutes les 0,17 à 0,24 s, finie parfois par le coup lourd | garder un coup armé une fois sur deux, s'échapper d'une chaîne, saisir une garde, esquiver un jutsu, le meilleur jutsu à portée, le kunai de loin |

Le même code joue :
- **sans Studio** (`Sim.luau`), sur le vrai combat, la vraie IA et le vrai coach du banc de test (`tests/Harness`), comme le serveur prend les appuis d'un joueur (`Matches:act`) ;
- **dans Studio**, comme client, par le remote du jeu (`studio_bot.luau`) : le stick à 15 Hz, chaque appui avec son stick, sa visée et son heure.

Une graine donne la même partie des deux côtés.

## Les commandes

```sh
lune run tests/DuelBot.spec.luau                       # le premier combat, 8 kits x 3 graines (dans tests/run.sh)
lune run tools/duelbot/rounds.luau 2 0.6,0.7,0.8,1 joueur,debutant easy,normal   # la durée des manches

python3 tools/duelbot/studio_code.py --module          # Studio, Edit (ou Client) : installe ReplicatedStorage.NDDuelBot
python3 tools/duelbot/studio_code.py --first debutant 2 Lion,Legion,Leaf        # Client, pendant un Play : le plan
python3 tools/duelbot/studio_code.py --duel joueur easy 1 Lion:Sand,Lion:Leaf
python3 tools/duelbot/studio_code.py --read            # Client : l'état et les résultats (JSON)
```

Sans lune dans la session, la suite tourne sur GitHub à chaque envoi. Une mesure à part (`rounds.luau`) se lance sur une branche de travail, jamais la branche commune, avec `gh workflow run ninja-duel-suite.yml --ref <branche>`. Dans Studio, on travaille dans une copie de ND-JEU dans `LAB/robots`.

## Ce que le robot ne prouve pas

- Le ressenti : un robot ne dit pas si c'est amusant, ni si les consignes se lisent bien à l'écran.
- Un vrai débutant hésite, regarde autour de lui, essaie des touches au hasard. Le profil en est une approximation, réglée sur une seule vraie partie : celle de François, le 21/11 (environ 47 s de combat).
- Sans Studio, le banc de test n'a pas de physique : les corps glissent à leur vitesse. Les manches y sont un peu plus courtes que dans Studio (voir les mesures).
