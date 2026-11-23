# Le pré-vol de publication (OUTILLEUR, étape 5 « Ouverture », DEC-049)

C'est la liste « prêt à publier » du DEV (doc projet `claude/etape5-ouverture-taches-2026-11-23`, § 1), passée par un outil. Chaque point sort **VERT**, **ROUGE** (la publication est bloquée) ou **ORANGE** (à regarder, ne bloque pas), avec sa preuve et ce qu'il faut faire.

```sh
python3 tools/preflight/preflight.py                      # le rapport ; code 1 si un point est ROUGE
python3 tools/preflight/preflight.py --build              # reconstruit la release d'abord
python3 tools/preflight/preflight.py --md R.md --html R.html --json R.json
python3 tools/preflight/preflight.py --today 2026-11-27   # les codes, vus à cette date
python3 tools/preflight/preflight.py --reference          # enregistre les noms des DataStore d'aujourd'hui
```

Il lit la place qui serait publiée (`dist/NinjaDuel.rbxlx`, la build release) et les sources. Il ne change rien.

| Domaine | Ce qu'il vérifie |
|---|---|
| Offres | Chaque offre affichée a un ID : les passes de `Shared/Shop`, les apparences en Robux de `Shared/Catalog` et `CatalogStyle`, les paquets de Ryō, les lots (`Config.Shop.Bundles`) dès qu'un écran les montre. Les kits sans ID ne sont pas affichés en vente : ils sortent en ORANGE. Aucune offre retirée n'est encore affichée (DEC-049 : EARLY ACCESS, MORE BUILDS, les auras en Robux). Aucun ID en double. Chaque produit passe par le reçu (`Progression.processReceipt`), chaque passe est lue côté serveur. |
| Outils | Aucun module Studio (la liste de `build.py`, `DEBUG_SOURCES`), aucun outil de tournage, aucun marqueur de debug (`tests/test_build_isolation.py`), pas de drapeau `NinjaDuelDebug` / `NinjaDuelQA`, profil `release`. |
| Test | Aucun spec, banc de test, robot ni outil de cabine dans la place. |
| Version | La ligne de version de la place (`SourceCommit`) est le commit des sources, ou un commit qui livre le même jeu ; rien de non commité ; même moteur que les autres profils. |
| DataStore | Les noms des DataStore sont ceux de la référence (`datastores.json`) : un nom changé, ce sont les données des joueurs perdues. Le jeu publié sauvegarde (`Config.Progression.Live`), et Studio écrit ailleurs (`…_DEV`). |
| Codes | 3 codes actifs au plus en même temps (la règle du CM), des dates valides. |

Ce que le pré-vol ne prouve pas est listé en bas du rapport, avec l'endroit où se trouve la preuve : données à la fermeture, fluidité (`tools/perf`), premières minutes (`tools/newplayer`), contenu (`tools/kits`), page, test à plusieurs (`tools/testread`).

## Le 24/11, minuit (sources `e9d9bc64`, passe commune 1) : PAS PRÊT, 1 rouge

- **En rouge** : les 26 offres affichées n'ont pas d'ID. Elles attendent que François crée les produits sur Roblox (DEC-049).
- **Plus en rouge** :
  - EARLY ACCESS et MORE BUILDS sont retirés (DEV) ;
  - les deux auras se vendent en Ryō (ANIMATEUR) ;
  - il reste 3 codes actifs au plus (CM).
- **En orange** :
  - les 8 kits sans ID, qui ne sont pas vendus ;
  - le lot des 8 tenues, pas encore affiché.
- **La référence des DataStore** porte maintenant `NinjaDuelReports`, gardé dans le jeu publié : le DEV n'y écrit que sur la place de test.
- **Le pré-vol refuse aussi** les robots de la passe 1 (`NDCollisionBot`, `NDScreenTour`) et la sonde `NDPerfProbe`, s'ils étaient un jour dans la place.

## Le 23/11 au soir (sources `9750dbbc`, après le DEV et la DESIGN de l'étape 5) : PAS PRÊT, 4 rouges

- **Offres** :
  - les 30 offres affichées montrent SOON : aucun ID n'est encore créé ;
  - EARLY ACCESS, MORE BUILDS et les auras THUNDER HALO et SHADOW VEIL sont encore en vente. Les auras sont à 0 dans `Config` (DEV, 166ccab1), mais leur clé Robux est encore dans `Shared/Catalog` : c'est l'ANIMATEUR qui les change en récompense ou en Ryō ;
  - les passes EARLY ACCESS et MORE BUILDS ne font rien côté serveur. VIP est lu depuis 0d05d0e1.
- **Codes** : du 27/11 au 06/12, 4 codes sont actifs en même temps (NINJADUEL, MYNINJA, FIRSTDUEL, EXAM1).
- **En vert** : pas d'outil de debug, pas de code de test, la ligne de version (les 4 profils au même commit), la sauvegarde.
- **En orange** :
  - les 8 kits n'ont pas d'ID ; ils ne sont pas vendus ;
  - le lot des 8 tenues (`Config.Shop.Bundles`, `SetPrologue8`) n'est pas encore affiché. Il comptera dans les ID quand la boutique le montrera ;
  - un DataStore nouveau depuis la référence, `NinjaDuelReports` (le bouton SIGNALER, `Server/Reports`). Si le DEV le garde dans le jeu publié : `--reference`.
