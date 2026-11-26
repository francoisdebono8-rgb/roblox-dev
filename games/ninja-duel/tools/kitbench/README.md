# Le banc des kits (OUTILLEUR, passe commune 3, 26/11, DEC-055)

La demande : « le banc des kits : un robot joue chaque coup et chaque technique de chaque kit dans la place, et sort une planche et une courte vidéo par kit. C'est le juge commun de l'ANIMATEUR, du DEV et du CM. »

`NDKitBench` (`kit_bench.luau`, client) montre les coups de rue de chaque kit sur le corps du promeneur : l'avatar du joueur, avec sa tenue. Ces coups sont ceux de `Shared/HubFight.Moves` : les trois légers, le lourd, le coup en l'air, l'esquive, la garde.

- **La planche** (`sheet`) pose 16 à 30 copies du corps, chacune dans sa vue, chacune à un instant du clip (tous les 0,13 s). Le clip est celui que le jeu joue : `HubBody.clipName`, puis `Authored.sample`, écrit sur les articulations comme `HubBody` le fait. Une seule capture d'écran donne toute la planche, aux instants exacts.
  - Capturer le promeneur en direct (`HubFightClient.current:hold`, la commande du DEV) ne donnait pas les bons instants : le 26/11, une capture « toutes les 0,45 s » tombait toutes les 1,8 s.
- **La vidéo** : les cases de la planche, mises bout à bout à 7,7 images par seconde (une image tous les 0,13 s de clip), passent à la vitesse réelle du coup.
- **`clips()`** dit, pour chaque kit et chaque coup, le clip joué et s'il est au kit ou emprunté. `HubBody.clipName` prend celui de Lion quand un kit n'a pas le sien.
- `play(kit, …)` tient aussi une pose sur le promeneur en direct, dans la rue.

```sh
python3 tools/robots/inject.py bench               # Client
python3 tools/kitbench/report.py --clips           # Client : le tableau des clips
python3 tools/kitbench/report.py --sheet Lion 1    # Client : la planche (30 images, 10 par ligne, comme celles du 26/11), puis capture_screenshot (attendre 3 s le rendu)
python3 tools/kitbench/report.py CLIPS.json --md RAPPORT.md
```

Les techniques (jutsus, outils) ne sont pas encore dans la rue (HUB-002 phase 2, DEV). Le banc les prendra quand elles y seront ; d'ici là, elles se voient en duel (`tools/duelaudit`).

## Le 26/11 (place `6c673043`)

Fichiers : `mesures/2026-11-26_6c673043/` : une planche et une vidéo par kit (`sasuke_planche_1.jpg`, `sasuke_coups.mp4`…), `clips.json`, `rapport_clips.md`.

- **Chaque kit a ses clips, sauf le lourd de Gaara**, qui est celui de Sasuke (`Lion.Heavy`, le coup de pied retourné).
- Ce qu'on voit sur les planches (observations de Claude, pas l'avis de François) :
  - **L'esquive est la même silhouette pour les huit** : penché en avant, un bras en arrière.
  - **La garde ressemble à la pose de repos** pour chacun : rien ne la distingue à l'image.
  - **Les légers de Gaara bougent à peine le corps**, puisque c'est le sable qui frappe ; le sable n'est pas sur le banc.
  - **Le premier léger** de Sasuke, Neji, Kakashi et Minato sort peu le bras.
  - Les poses de repos se distinguent surtout chez Gaara (bras croisés), Itachi (bras ouverts) et Lee (une main en avant). Les autres se ressemblent.
