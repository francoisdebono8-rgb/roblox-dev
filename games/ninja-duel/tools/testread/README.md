# La page de lecture du test à 3–5 joueurs (OUTILLEUR, étape 5 « Ouverture », DEC-049)

Une page faite des **signalements** (le bouton REPORT A PROBLEM de la place de test) et des **relevés par joueur**. François y ajoute, à la main, les réponses aux trois questions de la méthode. Le format lu est dans `CONTRAT.md` ; c'est le DEV qui écrit ces données côté serveur.

```sh
python3 tools/testread/testread.py --dump                       # le code à coller dans Studio (Édition de la place de test, accès aux API)
python3 tools/testread/testread.py DUMP.json --reponses R.json --html page.html --md page.md
python3 tools/testread/testread.py --exemple DUMP.json          # un dump d'exemple, aux données inventées
```

## Ce que la page montre

- **L'entonnoir** : combien de joueurs atteignent chaque étape (arrivé, premier combat, premier coup, duel gagné, inspiration, habillé, achat, nœud), et en combien de temps (médiane, plus court, plus long).
- **Chaque joueur** :
  - son temps par écran, ses duels (joués, gagnés, perdus, quittés), ce qu'il a quitté avant la fin, la course des toits ;
  - ses signalements ;
  - ses réponses aux trois questions.
- **Tous les signalements**, rangés par lieu, dans l'ordre.
- **Ce qui revient** : un lieu signalé par plusieurs joueurs.

Elle ne décide pas ce qui est bloquant. C'est au DEV de le dire, avec François. Un dump d'exemple porte un bandeau **EXEMPLE** sur la page : on ne le prend pas pour un vrai test.

## Avec le bouton de la place de test (DESIGN, 993254c9)

Le bouton envoie l'action `Report` avec `{text, where}`. Le serveur ajoute le reste avant d'écrire dans `NinjaDuelTest` :
- qui : `userId` et `name` ;
- quand : `at` et `session` ;
- où en est le joueur : `phase`, `position`, `kit` ;
- la version : `build`.

C'est la forme de `CONTRAT.md`. Le relevé par joueur (`session_…`) est écrit par le serveur seul.

Les tests : `python3 tools/testread/test_testread.py`.
