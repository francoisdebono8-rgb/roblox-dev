# Les robots, envoyés dans le jeu pendant un Play (OUTILLEUR, passe commune 1, DEC-052)

DEC-052 : une seule place, `~/Documents/NinjaDuel/PLACES/NinjaDuel.rbxlx`, et on teste dans le jeu. Il n'y a plus de copie LAB : `tools/lab/lab_place.py` est retiré.

Les robots sont envoyés comme du code dans le client d'un Play de cette place (robloxstudio-mcp `eval_client_runtime`). Ils vivent dans `_G` jusqu'à la fin du Play.

```sh
python3 tools/robots/inject.py collision screens   # le code à lancer dans le Client
python3 tools/robots/inject.py all                 # tous les robots
python3 tools/robots/inject.py --check             # Client : quels robots sont là, de quel commit
python3 tools/robots/inject.py --list
```

| Nom | Dans `_G` | Ce que c'est | Ses commandes |
|---|---|---|---|
| `duel` | `NDDuelBot` | le joueur simulé : débutant ou joueur, premier combat ou duel | `tools/duelbot` |
| `village` | `NDVillageBot` | le robot du village : trajets, course des toits, toits, saut | `tools/villagebot` |
| `newplayer` | `NDNewPlayerBot` | les 10 premières minutes d'un nouveau joueur (amène `duel` et `village`) | `tools/newplayer` |
| `perf` | `NDPerfProbe` | la sonde de fluidité | `tools/perf` |
| `collision` | `NDCollisionBot` | ce qu'on traverse dans Konoha : le dessin contre le solide, la marche contre les façades, la chute sur les toits | `tools/collision` |
| `screens` | `NDScreenTour` | ce qui est à l'écran et les lignes rouges, pour le relevé des écrans | `tools/screens` |

- **Rien n'est écrit dans la place.** Ni dans l'Édition, ni dans le fichier. Un Play arrêté emporte les robots : on les renvoie au Play suivant. `--module` de `tools/duelbot` et `tools/villagebot` ne pose plus rien dans l'Édition ; il renvoie ici.
- **Chaque commande des outils les cherche dans `_G`.** C'est le cas de `collision.py`, `releve.py` et des `studio_code.py`. Quand un robot n'est pas là, l'erreur donne la ligne à lancer.
- **Le jeu publié ne les a jamais.** Le pré-vol (`tools/preflight`) refuse leurs noms dans la place.
- **Ne jamais bloquer le client longtemps.** Un appel qui attend plus de quelques secondes (une boucle de `task.wait`) gèle le corps du joueur pendant ce temps : les robots qui marchent ne bougent plus. On lance, puis on relit par appels courts.
- **Pas l'écran ni la souris de François.** Tout passe par les outils de Studio : `eval_client_runtime`, `capture_screenshot`, `get_runtime_logs`, et `simulate_mouse_input` / `simulate_keyboard_input`, qui jouent dans le Play et pas sur le Mac.

Les tests : `python3 tools/robots/test_inject.py`. Ils vérifient aussi qu'aucun outil ne cherche plus un robot dans `ReplicatedStorage`.
