> Outils du Mac du propriétaire (issue #45). État et règles : [sources actives](../../docs/active/EXECUTION_RULES.md). Mode d'emploi : [RUNBOOK](../../docs/tools/RUNBOOK_4_DISCUSSIONS.md).

# Mac — l'espace `~/Documents/NinjaDuel`

| Fichier | Rôle |
|---|---|
| `place_commune.py` | **La place commune automatique** (DEC-043, 20/11). Un agent macOS la lance toutes les 2 min : après chaque lot poussé sur la branche commune, il reconstruit les 4 places au même commit et les pose dans `PLACES` (voir plus bas). Tests : `test_place_commune.py`. |
| `actualiser_places.sh` | Copié dans `~/Documents/NinjaDuel/_outils/`. Reconstruit `PLACES/ND-JEU`, `ND-DEV`, `ND-QA`, `ND-FILM` depuis GitHub (même commit), sans écraser une place ouverte ou modifiée dans Studio. |
| `LISEZ-MOI_NinjaDuel.md` | Copié en `~/Documents/NinjaDuel/00_LISEZ-MOI.md` : quel fichier ouvrir. |
| `rangement_2026-11-07.py` | Le rangement exécuté le 07/11 (déplacements dans `~/Documents`, alias, `moves.tsv`, `restaurer.sh`). Gardé pour mémoire : ne pas relancer. |
| `manifest_sha1.py` | sha1 de chaque fichier d'une liste de dossiers (reprenable), pour comparer avant/après. |
| `scan_places.py` | Pour chaque `.rbxlx` : sha1, `BuildFingerprint`, blob Git de chaque script. |
| `extraire_scripts_uniques.py` | Extrait des places les scripts absents de Git (ceux du 07/11 sont sur la branche `archive/mac-local-2026-11-07`). |

Ces scripts tournent dans le shell de la session liée au Mac (`~/mnt/Documents`)
ou dans un Terminal macOS (`~/Documents`). Un dépôt Git ne peut pas vivre dans un
dossier partagé avec la session : git y laisse des verrous faute de droit de
suppression. D'où le clone temporaire d'`actualiser_places.sh`.

Rapport : [inventaire](../../docs/reports/mac-local-2026-11-07/MAC_LOCAL_INVENTORY.md),
[résultat](../../docs/reports/mac-local-2026-11-07/MAC_CLEANUP_RESULT.md).

## La place commune automatique (`place_commune.py`)

Après chaque lot poussé sur `claude/ninja-duel-2026-10-14`, les 4 places sont reconstruites au même commit et posées dans `~/Documents/NinjaDuel/PLACES`. Personne n'a à le lancer.

1. Un agent macOS (`~/Library/LaunchAgents/com.ninjaduel.placecommune.plist`) lance `_outils/place_commune.py --une-fois` toutes les 2 min.
2. Il lit le dernier commit de la branche sur GitHub. Il attend que la branche n'ait pas bougé depuis 3 min : un lot de plusieurs poussées n'est construit qu'une fois.
3. Il construit les 4 profils dans son clone (`~/Library/Caches/ninja-duel-place-commune`) et vérifie qu'ils ont le même runtime. Il les range dans `PLACES/_prochaine/` : elles sont prêtes.
4. Si aucune des 4 places n'est ouverte dans Studio, il les pose et récrit `VERSION.md`. Sinon, il prévient par une notification (« fermer ND-JEU… ») et les pose au premier passage où plus rien n'est ouvert.
   - Une place modifiée dans Studio est mise de côté dans `_maintenance/places-modifiees-dans-studio/`, comme avec `actualiser_places.sh`.
   - Un commit qui ne change pas le jeu (mêmes places à l'octet près) ne touche pas aux places : seul `VERSION.md` change de commit.
5. Rien n'est effacé : les places sont déplacées.

```sh
python3 ~/Documents/NinjaDuel/_outils/place_commune.py --etat          # où en est la place commune
python3 ~/Documents/NinjaDuel/_outils/place_commune.py --une-fois      # un passage tout de suite
python3 ~/Documents/NinjaDuel/_outils/place_commune.py --desinstaller  # arrêter l'agent
python3 games/ninja-duel/tools/mac/place_commune.py --installer        # (ré)installer l'agent et copier le script dans _outils
```

Journal : `_maintenance/place-commune/journal.log`. `actualiser_places.sh` reste là pour une autre version (`<sha|branche>`).
