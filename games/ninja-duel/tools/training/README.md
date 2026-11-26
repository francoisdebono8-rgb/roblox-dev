# Le robot d'entraînement (OUTILLEUR, passe commune 2, 26/11, DEC-054)

La demande : « un robot d'entraînement qui joue chaque étape des tutos jusqu'au bout et dit où il bloque ».

Le robot ouvre l'entraînement d'un kit, comme l'écran de sélection le fait (action `Tutorial` de la télécommande). Puis il joue chaque étape comme un joueur, uniquement par la télécommande du jeu :
- le stick à 15 Hz ;
- chaque appui avec son stick et sa visée.

Les gestes de chaque étape sont ceux de `Server/TutorialBot` (le robot serveur des places de débogage), envoyés comme des appuis de joueur.

Une étape non réussie en 22 s est sautée, comme un joueur peut le faire avec le bouton du panneau. Le robot la note « abandonnée ». La dernière étape (gagner le duel d'entraînement) est jouée par le joueur simulé du robot de duel (`NDDuelBot.PlayerSim`), 90 s au plus.

Le verdict du jeu sur chaque étape vient du serveur, par ses lignes `[NinjaDuelTutorial]` : PASS, STUCK ou SKIP, avec les refus et les gels. Le journal du serveur (`NDServerLog`, `tools/duelaudit/server_log.luau`) les garde.

## Lancer

Pendant un Play de la place du jeu (DEC-052). Les longues séries se lancent dans une Studio à soi : voir `tools/robots/README.md`.

```sh
python3 tools/robots/inject.py --server serverlog     # Serveur : puis _G.NDServerLog.start()
python3 tools/robots/inject.py training               # Client (amène duel)
python3 tools/training/report.py --start              # Client : les 8 kits, chacun contre le suivant
python3 tools/training/report.py --read               # Client : le JSON du robot
```

Côté serveur, `_G.NDServerLog.read()` donne les lignes. On met les deux JSON dans un fichier `{"robot": …, "server": …}`, puis :

```sh
python3 tools/training/report.py MESURE.json --md RAPPORT.md
```

## Ce qu'il ne prouve pas

- **Le robot sait la bonne touche.** Il joue ce que `TutorialBot` sait réussir. Il ne lit pas la consigne de l'écran. Une étape qu'il réussit peut rester obscure pour un joueur ; la consigne affichée est dans le rapport, à côté du résultat.
- **Une étape « abandonnée »** veut dire : ces gestes, envoyés par la télécommande, ne la passent pas en 22 s. Ce peut être un défaut du jeu, ou un geste que le robot ne sait pas faire. Le rapport donne :
  - ce que l'écran a dit (les refus : `COOLDOWN`, `NO CHAKRA`…) ;
  - la ligne du serveur.

Les résultats du 26/11 sont dans `tools/duelaudit/mesures/` et dans `docs/active/CURRENT_STATE.md`.
