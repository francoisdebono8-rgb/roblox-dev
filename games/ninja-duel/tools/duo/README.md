# Essai à deux joueurs dans Studio (OUTILLEUR, 19/11)

Deux joueurs dans Konoha : l'un défie l'autre, l'autre accepte, ils se battent dans la rue, puis chacun revient dans le village. L'essai se joue dans Studio, avec deux clients, et il est mesuré automatiquement. La demande vient de `claude/vague-2-taches-2026-11-19`, § 2 OUTILLEUR 3.

| Fichier | Rôle |
|---|---|
| `recorder.luau` | À poser dans **chaque** client. Il note, à l'heure du serveur (la même pour les deux clients) : ce que dit le lobby, les phases (avec le lieu du duel), les manches, les PV perdus par l'adversaire, le corps du joueur (dans Konoha ou celui du duel) et les entrées |
| `report.py` | Lit les deux enregistrements et donne la chronologie du défi, avec la part du jeu (de l'entrée à son effet) |
| `studio_lobby_patch.luau` | **Pour l'essai seulement**, dans le serveur en cours d'une copie LAB : laisse passer le défi entre les joueurs de test de Studio (voir plus bas) |
| `essais/2026-11-19/` | Les deux enregistrements du 19/11 et leur rapport |

## Le déroulé

Il se joue dans une **copie LAB** de ND-JEU, jamais dans la place d'une autre discussion. Le 19/11, c'était `LAB/loopbot/ND-JEU-duo.rbxlx`, copié de `PLACES/ND-JEU.rbxlx` (`3516f3d9`).

1. Lancer deux joueurs : `multiplayer_playtest start`, avec `numPlayers` à 2.
2. Poser `recorder.luau` dans chaque client. Avec le MCP officiel de Studio (`Roblox_Studio`), chaque client est une fenêtre à part, appelée en `Client`.
3. Dans le serveur, poser `studio_lobby_patch.luau` (`eval_server_runtime`). Sans lui, aucun défi ne part dans Studio.
4. **Défi** : le joueur 1 marche jusqu'au joueur 2. À moins de 10 studs, il tient E sur CHALLENGE (`Client/HubPlayers`).
5. **Acceptation** : le joueur 2 reçoit la carte d'invitation (`Client/LobbyPanel`) et appuie sur Entrée (ACCEPT).
6. **Choix du combattant**, puis **duel**. Le serveur le place dans la rue la plus proche (`Matches:streetSite`, `Config.Hub.VillageDuels`). Pour finir le duel sans des centaines de clics pilotés, `shared.NDDuo.pilot(true)` fait combattre le joueur 1 : il avance vers l'adversaire et frappe, par le même message que le clavier (`Action`). Le serveur valide comme pour un joueur.
7. **Retour** : à l'écran de résultat, chacun clique pour revenir. Le serveur le remet dans Konoha, de son côté de la rue (`returnTo`).
8. Récupérer `shared.NDDuo.json()` dans chaque client, l'écrire dans un fichier, puis :

```sh
python3 tools/duo/report.py client1.json client2.json
```

Exemple de sortie (inventé, pour la forme) :

```
Défi dans Konoha : Player1 défie Player2
    0.00 s   (+0.00)  défi envoyé [Player1]
    0.10 s   (+0.10)  invitation reçue [Player2]
    3.20 s   (+3.10)  invitation acceptée [Player2]
    3.30 s   (+0.10)  choix du combattant [les deux]
    8.80 s   (+5.50)  duel [les deux] : dans la rue « market », Leaf contre Lion
   ...
   80.80 s   (+1.70)  retour à Konoha [Player2] : à [-5, 3, -2210]
Parcours complet.
```

Le rapport sort en erreur si une étape n'a pas été vue.

## Le 19/11

Sur `LAB/loopbot/ND-JEU-duo.rbxlx` (ND-JEU `3516f3d9`, RUNTIME `ee9528aa31e9`). Le rapport complet est dans `essais/2026-11-19/rapport.txt`. Dans `client1.json`, une partie des pertes de PV a été retirée pour l'alléger ; les étapes y sont toutes.

| Étape | Depuis le défi | Part du jeu |
|---|---|---|
| Défi envoyé (E tenu 0,4 s sur CHALLENGE) | 0 s | 0,05 s après la fin de l'appui |
| Invitation reçue chez l'autre | 0,01 s | |
| Acceptée (Entrée) | 7,7 s | 0,05 s |
| Choix du combattant | 7,7 s | dure 15 s si personne ne clique READY |
| **Duel dans la rue** « Legion », devant ICHIRAKU RAMEN | 23,4 s | les corps changent en 0,02 s |
| Premier coup | 29,0 s | |
| Résultat 2-0 | 323 s | durée faussée par le pilote (ci-dessous) |
| Retour à Konoha, joueur 1 | | 0,67 s après le clic sur BACK TO KONOHA, dans la même rue |
| Retour à Konoha, joueur 2 | | 0,65 s, dans la même rue, de l'autre côté |

**Ce qu'on a trouvé (NATIVE_STUDIO, vu par Claude, pas par François) :**
- **Aucun défi ne part dans Studio.** Les joueurs de test ont des UserId négatifs (-1, -2), et `Server/Lobby` ne prend un défi que si `to>0`. Le serveur l'ignore sans rien dire. En ligne, les UserId sont positifs : seul l'essai est touché. Contournement : `studio_lobby_patch.luau`.
- **Pas de progression dans Studio à plusieurs** : « profile not loaded (Profile id required): every kit open ». Les deux joueurs arrivent sans fiche d'inspiration, avec tous les kits ouverts. Le choix du combattant propose Minato aux deux.
- **Bloqué sur un toit de la rue.** Les coups de Minato envoient l'adversaire en l'air, jusque sur les toits d'Ichiraku. Le joueur 2 s'est retrouvé sur `Ichiraku.StandRoof`, à 11 studs de haut, en état Neutral. Là, ni un déplacement dans quatre directions, ni un saut ne l'ont fait bouger (position identique pendant plus de 30 s). Le joueur 1, en bas, ne l'atteignait plus. Le duel n'a fini que par le kunai marqué puis le Dieu du Tonnerre Volant de Minato.
- **TALK pendant le duel** : une bulle TALK de Konoha s'est affichée plusieurs fois chez le joueur 1, pendant le duel de rue et au retour.
- **Le premier duel en ligne ne compte pas dans l'entonnoir** : la sortie du serveur n'a que `joined` et `input` (le duel en ligne n'est pas un « premier duel fini »). Lue par `tools/analytics/entonnoir.py` : « personne ne part entre les étapes lues ».

## Ce que l'essai ne dit pas

- La tension d'un vrai duel entre deux personnes : le joueur 1 est piloté, le joueur 2 ne se défend pas.
- Le réseau réel : les deux clients et le serveur tournent sur la même machine.
- Le temps d'un joueur entre deux gestes : on lit la part du jeu (l'écart entre une entrée et ce qu'elle déclenche).
