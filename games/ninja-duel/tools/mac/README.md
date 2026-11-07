> Outils du Mac du propriétaire (issue #45). État et règles : [sources actives](../../docs/active/EXECUTION_RULES.md). Mode d'emploi : [RUNBOOK](../../docs/tools/RUNBOOK_4_DISCUSSIONS.md).

# Mac — l'espace `~/Documents/NinjaDuel`

| Fichier | Rôle |
|---|---|
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
