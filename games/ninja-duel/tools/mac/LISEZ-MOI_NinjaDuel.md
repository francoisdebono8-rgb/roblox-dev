# Ninja Duel — quel fichier ouvrir

| Je veux… | J'ouvre dans Studio |
|---|---|
| **Développer, corriger, essayer un réglage** | `PLACES/ND-DEV.rbxlx` |
| **Tester le jeu comme un joueur** | `PLACES/ND-JEU.rbxlx` |
| **Filmer** (prises, caméras, décors de tournage) | `PLACES/ND-FILM.rbxlx` |
| (agents) lancer la batterie de tests natifs | `PLACES/ND-QA.rbxlx` |

Les quatre sortent **du même commit GitHub** : même jeu, seuls les outils
changent. Le commit et les empreintes sont dans `PLACES/VERSION.md`. Au Play,
la sortie de Studio affiche la même chose :
`[NinjaDuel] BUILD … | RUNTIME … | debug @ <commit>`.

**Mettre les places à jour** (fermer d'abord la place dans Studio) :

```
bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh            # dernière version
bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh <commit>   # une version précise
```

Le script reconstruit les quatre places depuis GitHub. Il ne remplace jamais
une place modifiée dans Studio : il la met de côté dans `_maintenance/`.

## Les dossiers

| Dossier | Contenu | Ancien chemin (encore valable, c'est un alias) |
|---|---|---|
| `PLACES/` | les 4 places actives, rien d'autre | `~/Documents/Roblox/ND-…` |
| `MEDIA/` | rushes OBS, montages, exports, voix, fabrique de clips | `~/Documents/NinjaDuelMedia` |
| `BLENDER/` | `.blend`, exports `out/`, `mixamo/`, `NDLooks/` | `~/Documents/NinjaDuelBlender`, `~/Documents/NDLooks` |
| `LAB/VFX` | bac à sable VFX (`ND-VFX-Lab`, `ND-VFX-Coups`) | `~/Documents/NinjaDuelVFX` |
| `LAB/repro` | places de reproduction de bugs | `~/Documents/Roblox/repro` |
| `ARCHIVES/` | anciennes places (v22, v30 à v39, Labo, Test, Clips, passe jutsu), copies des Téléchargements, vidéo showcase : **on ne travaille pas dedans** | — |
| `_maintenance/` | inventaire (sha1 de chaque fichier avant/après), journal des déplacements, `restaurer.sh`, proposition de suppression | — |
| `_outils/` | `actualiser_places.sh` | — |

## Règles

- On ne corrige pas le jeu dans une place. Une correction passe par GitHub,
  puis `actualiser_places.sh`. Une place enregistrée à la main n'est plus le
  même jeu que les autres.
- Plus de nouvelles places numérotées (`ND-Test-v40`…). Une ancienne version
  se reconstruit : `actualiser_places.sh <commit>`.
- Un bug vu en jouant ou au tournage : noter l'heure et la ligne
  `[NinjaDuel] BUILD … @ <commit>` de la sortie Studio, et l'envoyer à la
  discussion DEV.

## Encore en dehors (07/11/2026)

- `~/Documents/Roblox/ND-Test-Sharingan.rbxlx` : fichier de la discussion
  « perception-sharingan ». Sa branche n'est pas intégrée, elle fait échouer
  9 suites de tests. À archiver quand elle sera intégrée.
- `MEDIA/ND-Clips-integ-0611.rbxlx` : était ouverte dans Studio pendant le
  rangement. Remplacée par `ND-FILM`, à archiver une fois fermée.
- `~/Documents/Roblox` garde les dossiers de Studio (plugins, réglages) : ne
  pas les déplacer.

Rangement du 07/11/2026 (issue GitHub #45). Annuler :
`bash ~/Documents/NinjaDuel/_maintenance/restaurer.sh`.
