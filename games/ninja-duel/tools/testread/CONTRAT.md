# Ce que la page de lecture du test lit (OUTILLEUR, 23/11, étape 5)

La page `tools/testread` est faite des **signalements** (le bouton SIGNALER) et des **relevés par joueur** de la place de test privée. C'est le DEV qui les écrit (étape 5, DEV n° 4). Voici le format que la page lit. S'il change, c'est la page qui s'adapte : le DEV me le dit dans `SINCE_LAST_CLAUDE`.

## Où

- Un DataStore de la place de test, `NinjaDuelTest`. Il est propre à l'univers de test, donc jamais celui du vrai jeu.
- Deux sortes de clés :
  - `report_<UserId>_<horodatage>` : un signalement ;
  - `session_<UserId>_<horodatage>` : un relevé, écrit quand le joueur part (et toutes les 2 minutes, au cas où le serveur ferme).
- Pour la lecture, on ouvre la place de test dans Studio (Édition, accès aux API activé). On colle le code de `python3 tools/testread/testread.py --dump`, qui rend un JSON. Ce JSON va dans la page.

## Un signalement

```json
{"kind": "report", "userId": 123, "name": "Pseudo", "at": 1795400000, "session": 412,
 "text": "je reste bloqué sous le toit", "where": "Konoha", "phase": "Selection",
 "position": [120.4, 3.0, -88.1], "kit": "Legion", "build": "acfb00d6"}
```

| Champ | Ce que c'est |
|---|---|
| `at` | l'heure (os.time) |
| `session` | les secondes depuis son arrivée |
| `text` | sa phrase, telle quelle (le filtre de texte de Roblox appliqué) |
| `where` | l'écran ou le lieu : `Konoha`, `Duel`, `Shop`, `Market`, `Tree`, `Wardrobe`, `Race`… |
| `phase` | la phase du serveur (`Selection`, `Duel`, `Result`) |
| `position` | où est son corps (x, y, z), s'il en a un |
| `build` | la ligne de version (SourceCommit) |

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
