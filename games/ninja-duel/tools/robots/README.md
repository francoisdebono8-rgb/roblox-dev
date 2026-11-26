# Les robots, envoyés dans le jeu pendant un Play (OUTILLEUR, passe commune 1, DEC-052)

DEC-052 : une seule place, `~/Documents/NinjaDuel/PLACES/NinjaDuel.rbxlx`, et on teste dans le jeu. Il n'y a plus de copie LAB : `tools/lab/lab_place.py` est retiré.

Les robots sont envoyés comme du code dans le client d'un Play de cette place (robloxstudio-mcp `eval_client_runtime`). Ils vivent dans `_G` jusqu'à la fin du Play.

```sh
python3 tools/robots/inject.py collision screens   # le code à lancer dans le Client
python3 tools/robots/inject.py all                 # tous les robots
python3 tools/robots/inject.py --check             # Client : quels robots sont là, de quel commit
python3 tools/robots/inject.py --list
python3 tools/robots/inject.py --server serverlog  # le code à lancer dans le Serveur (eval_server_runtime)
python3 tools/robots/inject.py --check-server
```

| Nom | Dans `_G` | Ce que c'est | Ses commandes |
|---|---|---|---|
| `duel` | `NDDuelBot` | le joueur simulé : débutant ou joueur, premier combat ou duel | `tools/duelbot` |
| `village` | `NDVillageBot` | le robot du village : trajets, course des toits, toits, saut | `tools/villagebot` |
| `newplayer` | `NDNewPlayerBot` | les 10 premières minutes d'un nouveau joueur (amène `duel` et `village`) | `tools/newplayer` |
| `perf` | `NDPerfProbe` | la sonde de fluidité | `tools/perf` |
| `collision` | `NDCollisionBot` | ce qu'on traverse dans Konoha : le dessin contre le solide, la marche contre les façades, la chute sur les toits | `tools/collision` |
| `screens` | `NDScreenTour` | ce qui est à l'écran et les lignes rouges, pour le relevé des écrans | `tools/screens` |
| `audit` | `NDDuelAudit` | (passe 2) le témoin des duels : corps bloqué, coup qui traverse, coup de loin, corps dans le sol, caméra dans un mur, erreurs rouges | `tools/duelaudit` |
| `training` | `NDTrainingBot` | (passe 2) le robot d'entraînement : chaque étape de l'entraînement de chaque kit, jouée par la télécommande (amène `duel`) | `tools/training` |
| `outfit` | `NDOutfitCheck` | (passe 2) le contrôle des tenues : quelle pièce traverse ou flotte, sur quel corps | `tools/outfitcheck` |
| `street` | `NDStreetBot` | (passe 3) les coups de rue pressés comme un joueur : mannequin, caisse, voyou, prodige, Ōtsutsuki, et le défi par le coup entre deux clients (riposte armée) | `tools/streetfight` |
| `sound` | `NDSoundCheck` | (passe 3) le contrôle des sons : chargé, durée, sonie, ce qui joue | `tools/sounds` |
| `bench` | `NDKitBench` | (passe 3) le banc des kits : une planche par kit, chaque coup à chaque instant, sur le corps du joueur | `tools/kitbench` |

Côté serveur (`--server`, avec `eval_server_runtime`) :

| Nom | Dans `_G` du serveur | Ce que c'est | Ses commandes |
|---|---|---|---|
| `serverlog` | `NDServerLog` | les lignes rouges du serveur, le verdict de chaque étape d'entraînement (`[NinjaDuelTutorial]`), les images du serveur (à-coups) | `tools/duelaudit` |
| `outfitbodies` | `NDOutfitBodies` | la rangée des avatars Roblox types, dans leur corps de duel (`AvatarBody.rig`), habillés d'une tenue | `tools/outfitcheck` |
| `streetlog` | `NDStreetLog` | (passe 3) ce que chaque coup de rue touche, chaque défi, les sessions des joueurs, les objets cassés et remis | `tools/streetfight` |

- **Rien n'est écrit dans la place.** Ni dans l'Édition, ni dans le fichier. Un Play arrêté emporte les robots : on les renvoie au Play suivant. `--module` de `tools/duelbot` et `tools/villagebot` ne pose plus rien dans l'Édition ; il renvoie ici.
- **Chaque commande des outils les cherche dans `_G`.** C'est le cas de `collision.py`, `releve.py` et des `studio_code.py`. Quand un robot n'est pas là, l'erreur donne la ligne à lancer.
- **Le jeu publié ne les a jamais.** Le pré-vol (`tools/preflight`) refuse leurs noms dans la place.
- **Une Studio à soi.** Plusieurs discussions lancent des Plays dans la même place commune. Le 26/11, un Play de l'OUTILLEUR a été arrêté par un autre au bout de deux minutes. Les longues séries de robots tournent donc dans une seconde fenêtre Studio ouverte sur le même fichier (`RobloxStudio -task EditFile -localPlaceFile …/PLACES/NinjaDuel.rbxlx`), sans rien enregistrer ; les outils prennent alors `instance_id`.
- **Ne jamais bloquer le client longtemps.** Un appel qui attend plus de quelques secondes (une boucle de `task.wait`) gèle le corps du joueur pendant ce temps : les robots qui marchent ne bougent plus. On lance, puis on relit par appels courts.
- **Pas l'écran ni la souris de François.** Tout passe par les outils de Studio : `eval_client_runtime`, `capture_screenshot`, `get_runtime_logs`, et `simulate_mouse_input` / `simulate_keyboard_input`, qui jouent dans le Play et pas sur le Mac.

Les tests : `python3 tools/robots/test_inject.py`. Ils vérifient aussi qu'aucun outil ne cherche plus un robot dans `ReplicatedStorage`.
