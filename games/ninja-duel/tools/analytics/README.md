# Lecteur de l'entonnoir (OUTILLEUR, 19/11)

Il dit **à quelle étape les nouveaux joueurs partent**. Il lit le fichier exporté de l'analytique Roblox (tableau de bord créateur, page Entonnoirs), sans clé API. Il lit aussi la sortie du serveur pendant un test (lignes `[NinjaDuelFirst]`).

La demande vient de `claude/vague-2-taches-2026-11-19`, § 2 OUTILLEUR 1.

```sh
# depuis games/ninja-duel
python3 tools/analytics/entonnoir.py --etapes                 # les étapes que le jeu envoie
python3 tools/analytics/entonnoir.py ~/Downloads/export.csv   # le rapport
python3 tools/analytics/entonnoir.py sortie_serveur.log       # un test dans Studio ou avec de vrais joueurs
python3 tools/analytics/entonnoir.py export.csv --json        # en JSON
python3 tools/analytics/test_entonnoir.py                     # les tests
```

Le rapport ressemble à ceci (exemple inventé, `exemples/export_etapes_en.csv`) :

```
Entonnoir des nouveaux joueurs (export_etapes_en.csv, Date range Nov 13 2026 - Nov 19 2026)
  1 arrivée           1 240  100 %
  2 première entrée   1 180   95 %   −5 % (60 partent)
  3 premier jutsu       610   49 %   −48 % (570 partent)
  4 premier duel        520   42 %   −15 % (90 partent)
Où ils partent le plus : entre « première entrée » et « premier jutsu » (570 joueurs, 48 % de ceux qui arrivent à « première entrée »).
```

Avec une répartition (plateforme, âge...), il donne d'abord le total, puis un entonnoir par groupe. Il dit aussi :
- la plus forte part de départs, quand ce n'est pas l'étape où le plus de joueurs partent ;
- les étapes du jeu absentes de l'export ;
- les étapes de l'export que le jeu ne connaît pas ;
- un échantillon trop petit (moins de 30 joueurs) : c'est une piste, pas une preuve.

## Les étapes

Elles sont lues dans le jeu, pas recopiées dans l'outil. Il cherche une table `FUNNEL` (aujourd'hui `Matches.FUNNEL`), ou des appels `LogOnboardingFunnelStepEvent(joueur, n, "nom")` dans `src/`. Quand le DEV enverra les étapes de la vague 2 (DEV 4), le lecteur les suivra sans changement.

| Aujourd'hui (`Matches.FUNNEL`) | Prévu (DEV 4) |
|---|---|
| 1 `joined` arrivée | arrivée |
| 2 `input` première entrée | tenue |
| 3 `jutsu` premier jutsu | inspiration |
| 4 `duel` premier duel fini | premier duel |
| | premier coup |
| | première victoire |
| | premier achat |

Le nom affiché vient de `LABELS`. Un nom inconnu s'affiche tel quel.

## Récupérer le fichier

1. Ouvrir le [tableau de bord créateur](https://create.roblox.com/dashboard/creations), puis l'expérience, puis **Analytique**, puis **Entonnoirs**, puis l'onglet **Onboarding**.
2. Choisir la plage de dates.
3. Exporter le graphique en CSV. La documentation Roblox dit que l'export d'un graphique donne « les dates et les valeurs de chaque point ». Elle ne décrit pas les colonnes de l'entonnoir.

Le lecteur accepte donc plusieurs formes :
- une ligne par étape ;
- une ligne par jour et par étape ;
- une colonne par étape ;
- avec ou sans répartition ;
- en nombres de joueurs, ou en pourcentages de la première étape ;
- virgule, point-virgule ou tabulation, UTF-8 ou UTF-16, en anglais ou en français.

S'il n'y a pas de bouton d'export, on peut recopier les nombres de l'écran dans un fichier texte, une étape par ligne (`exemples/saisie.txt`) :

```
arrivée 120
première entrée 115
```

Si un vrai export n'est pas reconnu, l'outil le dit : envoyer le fichier à l'OUTILLEUR. Le premier vrai export servira à vérifier ces hypothèses.

## La sortie du serveur

Le serveur écrit une ligne `[NinjaDuelFirst]` à chaque étape (`Matches.measure`), et une ligne `left` quand un joueur part avant la fin de son premier duel. Le lecteur en tire :
- le même entonnoir ;
- le temps médian de chaque étape depuis l'arrivée ;
- l'étape de la première minute pendant laquelle les joueurs sont partis.

C'est utile pour le test avec de vrais joueurs (tâche du CM) et pour les essais dans Studio. Il suffit de copier la sortie dans un fichier.

## Ce qu'il ne fait pas

- Il ne se connecte pas à Roblox : pas de clé API, pas de lecture du site.
- Il ne lit que l'entonnoir d'arrivée. L'économie, les achats et la rétention n'en font pas partie.
- Les fichiers de `exemples/` sont **inventés**, pour les tests. Ce ne sont pas des données de joueurs.

## Le 19/11

La page Entonnoirs du jeu publié (« Ninja Duel: Prodigy Tournament [BETA] ») n'a encore aucun événement. La page Présentation affiche 0 visite sur 7 jours, et la dernière mise à jour date du 04/11/2026. Les événements d'entonnoir ne partent que d'un jeu publié : il n'y aura rien à lire avant une publication décidée par François, puis des joueurs.
