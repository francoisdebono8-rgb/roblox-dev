# Essai à deux joueurs dans Studio (OUTILLEUR, 19/11)

Deux joueurs dans Konoha : l'un défie l'autre, l'autre accepte, ils se battent dans la rue, puis chacun revient dans le village. L'essai se joue dans Studio, avec deux clients, et il est mesuré automatiquement. La demande vient de `claude/vague-2-taches-2026-11-19`, § 2 OUTILLEUR 3.

| Fichier | Rôle |
|---|---|
| `recorder.luau` | À poser dans **chaque** client. Il note, à l'heure du serveur (la même pour les deux clients) : ce que dit le lobby, les phases (avec le lieu du duel), les manches, les PV perdus par l'adversaire, le corps du joueur (dans Konoha ou celui du duel) et les entrées |
| `report.py` | Lit les deux enregistrements et donne la chronologie du défi |

## Le déroulé

Il se joue dans une **copie LAB** de ND-JEU, jamais dans la place d'une autre discussion. Le 19/11, c'était `LAB/loopbot/ND-JEU-duo.rbxlx`, copié de `PLACES/ND-JEU.rbxlx` (`3516f3d9`).

1. Lancer deux joueurs : `multiplayer_playtest start`, avec `numPlayers` à 2.
2. Poser `recorder.luau` dans chaque client. Avec le MCP officiel de Studio (`Roblox_Studio`), chaque client est une fenêtre à part, appelée en `Client`.
3. Chacun choisit son inspiration, comme un nouveau joueur.
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

## Ce que l'essai ne dit pas

- La tension d'un vrai duel entre deux personnes : le joueur 1 est piloté, le joueur 2 ne se défend pas.
- Le réseau réel : les deux clients et le serveur tournent sur la même machine.
- Le temps d'un joueur entre deux gestes : on lit la part du jeu (l'écart entre une entrée et ce qu'elle déclenche).
