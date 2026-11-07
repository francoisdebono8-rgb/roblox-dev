> Outils de tournage (profil CAPTURE, issue #45). État, priorités et règles : [sources actives](../../docs/active/EXECUTION_RULES.md).

# Capture — la place de tournage, construite comme les autres

La place de tournage n'est plus une copie faite à la main d'une ancienne place
de test : c'est **le quatrième profil de `build.py`**, construit depuis le même
commit que le jeu, la place de développement et la place QA.

```sh
python3 build.py              # GAME    dist/NinjaDuel.rbxlx          (ce que les joueurs ont)
python3 build.py --debug      # DEV     dist/NinjaDuel-Debug.rbxlx    (outils de dev, devcall, F6)
python3 build.py --qa         # QA      dist/NinjaDuel-QA.rbxlx       (Debug + batterie native au Play)
python3 build.py --capture    # FILM    dist/NinjaDuel-Capture.rbxlx  (Debug + outils de tournage)
```

Les quatre places embarquent **les mêmes scripts de jeu**. Leur manifeste
(`dist/*.json`) porte `profile`, `sourceCommit`, `sourceDirty`,
`runtimeFingerprint` (le même dans les quatre profils d'un commit) et
`buildFingerprint` (propre à chaque profil). Au Play, la sortie Studio affiche :

```
[NinjaDuel] BUILD <buildFingerprint> | RUNTIME <runtimeFingerprint> | capture @ <commit>
```

Deux prises filmées avec le même `RUNTIME` montrent le même jeu.
`tests/test_build_isolation.py` vérifie que les outils de tournage ne sont que
dans la place FILM et que les quatre profils partagent runtime et commit.

## Ce que la place FILM contient en plus de DEV

| Emplacement dans la place | Fichier source |
|---|---|
| `ReplicatedStorage.NDFactory.ClipKit` | `studio/ClipKit.client.luau` |
| `ReplicatedStorage.NDFactory.HiraishinKunai` | `studio/HiraishinKunai.luau` |
| `ServerStorage.NDFactory.ShotRunner` | `studio/ShotRunner.server.luau` |
| `ServerStorage.NDFactory.Sets` | `studio/Sets.luau` |
| `ServerStorage.NDFactory.SetSnapshot` | `studio/SetSnapshot.luau` |
| `ServerScriptService.NDFactoryBoot` (Script, Studio seulement) | `studio/NDFactoryBoot.server.luau` |

C'est la disposition qu'utilisait `make_clip_place.py` de la fabrique CLIPS.
Les décors se construisent dans Studio : `require(game.ServerStorage.NDFactory.Sets).all()`.

`command-bar/` : les deux aides du CM à coller dans la barre de commande pendant
un Play (cadrages caméra côté client, prises dirigées côté serveur). Elles ne
sont dans aucune place.

`video_qc.py` : prévol des vidéos (images noires ou figées possibles, planche
contact ; ne juge ni l'animation ni le combat). Demande ffmpeg/ffprobe.

## Provenance (copié le 07/11/2026, sans réécriture)

| Fichiers | Origine |
|---|---|
| `studio/*.luau` | branche `claude/ninja-duel-tutorial-v2`, commit `26008f1` (05/11, « FILM01: shot maps v2… »), dossier `games/ninja-duel/tools/marketing/factory/studio/` |
| `command-bar/*.luau`, `video_qc.py` | branche `media-clips` (historique séparé, jamais fusionné), dossier `cm_tools/` |

Les places de tournage du Mac (`ND-Clips-v39`, `ND-Clips-integ-0611`)
contiennent une version plus ancienne de `ClipKit` et `ShotRunner` (commit
`768bbad` de la même branche) ; celles-ci sont les versions les plus récentes
de la fabrique. Le reste de la fabrique (scripts Python de montage, textes,
voix) reste sur `claude/ninja-duel-tutorial-v2` et dans le dossier média.

## Règles

- Ne jamais corriger le jeu dans la place FILM : un bug vu au tournage remonte
  à la discussion DEV avec l'heure, la ligne `[NinjaDuel] BUILD …` et la prise.
- Un outil de tournage modifié se modifie ici, puis on reconstruit avec `--capture`.
- La place FILM n'est jamais publiée.
