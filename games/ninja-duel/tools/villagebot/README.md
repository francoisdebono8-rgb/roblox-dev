# Le robot qui parcourt Konoha (OUTILLEUR, 21/11)

C'est la tâche OUTILLEUR 1 de l'étape 3 (DEC-047) : un robot qui parcourt le village. Il mesure les temps entre les lieux, vérifie que les toits sont atteignables et que personne ne reste coincé.

Le prouveur de carte (`tools/syphodev`) le dit sur le papier : ce qu'on peut atteindre avec le saut et le second saut, les pièges, les chevauchements. Le robot le vérifie dans le jeu, avec la vraie physique de Roblox.

## Ce qu'il fait

Il joue comme client, dans un Play d'une copie de ND-JEU dans `LAB`, jamais dans la place d'une autre discussion. Il bouge l'avatar comme un joueur :
- `Humanoid:Move` à chaque image, après les commandes par défaut ;
- la vitesse de course de `Client/HubMove` (36) ;
- le saut et le second saut (vitesse verticale 54, une fois par saut, après 0,18 s).

| Mesure | Comment | Ce qu'il rapporte |
|---|---|---|
| **Les trajets** | Il fait le tour de tous les lieux, du plus proche au plus proche, puis revient à la porte. Le chemin est calculé par `PathfindingService` ; il saute là où le chemin le dit, et là où il n'avance plus. | Pour chaque trajet : le temps en courant, la longueur, le temps à la marche (longueur / 16), arrivé ou non, et chaque blocage : où, contre quelle pièce. Une chute hors de la carte. |
| **Les toits** | Un échantillon de toits, du plus bas au plus haut : les pièces dont le nom contient « roof », à plus de 8 studs du sol et assez larges pour s'y tenir. Il va au pied du bâtiment, court vers son milieu, saute, puis fait le second saut en haut du saut. Trois essais. | Atteint ou non, en combien d'essais, la hauteur la plus haute atteinte. |

Les lieux viennent de `HubMap` :
- les apparitions (la porte, la salle) ;
- l'examinateur ;
- les maisons des huit maîtres ;
- le terrain d'entraînement ;
- le marché.

Quand le nouveau village sera construit à partir de `KonohaLayout`, ses points d'intérêt s'y ajoutent (`pois=true` dans le plan).

## Les commandes

```sh
python3 tools/villagebot/studio_code.py --module                          # Edit : installe ReplicatedStorage.NDVillageBot
python3 tools/villagebot/studio_code.py --start '{"routes":true,"roofs":16}'  # Client, pendant un Play, dans le village
python3 tools/villagebot/studio_code.py --read                            # Client : l'état et les résultats (JSON)
```

## Ce qu'il ne prouve pas

- Le chemin est celui de `PathfindingService`, pas celui d'un joueur qui connaît le village. Un trajet qui échoue peut avoir une autre route.
- Les toits : un échec du robot n'est pas une preuve qu'on ne peut pas y monter. Le prouveur en donne la liste complète ; le robot vérifie un échantillon dans le jeu.
- La course sur les murs et les toits du nouveau parcours (DEV 3) n'existe pas encore : le robot l'apprendra quand elle sera dans le jeu.
