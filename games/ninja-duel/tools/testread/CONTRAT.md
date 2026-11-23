# Ce que la page de lecture du test lit (OUTILLEUR, 23/11, étape 5)

La page `tools/testread` est faite des **signalements** (le bouton SIGNALER) et des **relevés par joueur** de la place de test privée. C'est le DEV qui les écrit (étape 5, DEV n° 4). Voici le format que la page lit. S'il change, c'est la page qui s'adapte : le DEV me le dit dans `SINCE_LAST_CLAUDE`.

## Où

- **Les signalements** : le DataStore `NinjaDuelReports`, écrit par le DEV depuis le 23/11 (`Server/Reports`), une clé par signalement : `r_<horodatage>_<UserId>_<n>`.
- **Les relevés par joueur** : ce que la page demande encore au DEV. Une clé `s_<UserId>_<arrivée>` dans le même DataStore (ou `session_…` dans `NinjaDuelTest`), écrite quand le joueur part, et toutes les 2 minutes au cas où le serveur ferme.
- Pour la lecture, on ouvre la place de test dans Studio (Édition, accès aux API activé). On colle le code de `python3 tools/testread/testread.py --dump`. Il lit les deux DataStore et ajoute les pseudos (`GetNameFromUserIdAsync`), puis rend un JSON. Ce JSON va dans la page.

## Un signalement (le format du DEV, `Server/Reports`)

```json
{"user": 123, "text": "je reste bloqué sous le toit", "at": 1795400000, "phase": "Selection",
 "kit": "Legion", "where": "Konoha @ 120,3,-88", "version": "acfb00d6…"}
```

| Champ | Ce que c'est |
|---|---|
| `user` | son UserId |
| `text` | sa phrase, de 3 à 300 caractères |
| `at` | l'heure (os.time) |
| `phase` | la phase du serveur (`Selection`, `Duel`, `Result`) |
| `kit` | son kit (`NinjaKit`) |
| `where` | l'écran que le client dit (`Konoha`, `Duel`, `Shop`…), puis `@` et la position du corps (x, y, z) s'il en a un |
| `version` | la ligne de version (`SourceCommit`) |

La page en tire le lieu, la position et la version. Elle calcule les secondes depuis l'arrivée quand le relevé du joueur existe. Elle lit aussi l'ancienne forme de ce contrat (`userId`, `name`, `session`, `position`, `build`).

## Un relevé par joueur

```json
{"kind": "session", "userId": 123, "name": "Pseudo", "joined": 1795399588, "left": 1795401388, "seconds": 1800,
 "screens": {"Konoha": 940, "Duel": 520, "Shop": 120, "Tree": 60},
 "funnel": {"joined": 0, "started": 41, "hit": 49, "duel": 96, "won": 96, "inspiration": 130, "dressed": 162, "bought": 900},
 "duels": {"played": 6, "won": 3, "lost": 2, "left": 1},
 "quit": [{"what": "duel", "at": 1210}],
 "race": {"runs": 3, "best": 31.2}, "kit": "Legion", "build": "acfb00d6"}
```

| Champ | Ce que c'est |
|---|---|
| `screens` | les secondes passées dans chaque écran ou lieu |
| `funnel` | les secondes depuis l'arrivée à chaque étape de l'entonnoir (`Matches.FUNNEL`) |
| `duels` | les duels joués, gagnés, perdus, quittés avant la fin |
| `joined`, `left` | l'arrivée et le départ (os.time) |
| `quit` | ce qu'il a quitté avant la fin (`duel`, `race`, `tutorial`…), et à quelle seconde |
| `race` | la course des toits : essais et meilleur temps |

## Ce que François ajoute à la main

Les réponses aux trois questions de la méthode, après la partie. C'est un fichier `reponses.json` à côté du dump :

```json
{"123": {"pensait": "…", "perdu": "…", "retenter": "…"}}
```

- `pensait` : « Qu'est-ce que tu pensais pouvoir faire ? »
- `perdu` : « Pourquoi as-tu perdu ? »
- `retenter` : « Qu'as-tu envie de retenter ? »
