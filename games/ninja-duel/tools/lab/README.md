# La copie LAB avec les robots (OUTILLEUR, 23/11, étape 5)

```sh
python3 tools/lab/lab_place.py PLACES/ND-JEU.rbxlx LAB/robots/ND-JEU-robots-<commit>.rbxlx
```

Il écrit une copie de la place avec quatre ModuleScripts dans `ReplicatedStorage`. Un Play de la copie les a, sans rien coller dans Studio :

| Module | Ce que c'est | Ses commandes |
|---|---|---|
| `NDDuelBot` | le joueur simulé : débutant ou joueur, premier combat ou duel | `tools/duelbot` |
| `NDVillageBot` | le robot du village : trajets, course des toits, toits, saut | `tools/villagebot` |
| `NDNewPlayerBot` | les 10 premières minutes d'un nouveau joueur | `tools/newplayer` |
| `NDPerfProbe` | la sonde de fluidité | `tools/perf` |

La copie a aussi un `StringValue` `NDLabTools`, qui porte le commit des outils.

- **Le jeu n'est pas touché.** Seule la copie reçoit les robots. La source ne peut pas être la sortie, et rien n'est écrit dans `PLACES/`.
- **Le jeu publié ne les contient jamais.** Le pré-vol (`tools/preflight`) le vérifie : aucun code de test ni robot dans la place.
- **Une copie déjà ouverte se met à jour sans être refaite.** En Édition, on remplace le `Source` du module dans `ReplicatedStorage`. Les sources y sont sans commentaires, comme `lab_place.py` les écrit.

Les tests : `python3 tools/lab/test_lab_place.py`.
