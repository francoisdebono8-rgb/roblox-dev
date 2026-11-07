# Archive — fichiers Ninja Duel présents uniquement sur le Mac (07/11/2026)

Branche **orpheline d'archive** (issue #45, phase locale). Elle ne se fusionne
jamais dans le code du jeu : un fichier utile se **porte** à la main dans la
branche canonique, avec revue et provenance.

Ce qui est ici : chaque fichier Ninja Duel du Mac dont le contenu (hash Git du
blob) n'existait dans **aucun** commit de `origin` au moment de l'inventaire
(07/11/2026, ~13 h 40, heure de Paris), sauf les médias lourds (vidéos, sons,
rendus PNG des prises), qui restent sur le Mac et sont listés dans
`games/ninja-duel/docs/reports/mac-local-2026-11-07/MAC_LOCAL_INVENTORY.md`
de la branche canonique.

| Dossier | Origine sur le Mac | Ce que c'est |
|---|---|---|
| `mac/Documents/NinjaDuelBlender/out/*.json` | `~/Documents/NinjaDuelBlender/out` (59) | Clips/poses exportés de Blender jamais commités |
| `mac/Documents/NinjaDuelBlender/runner.py`, `lib/posing.py` | idem | Lanceur et module de pose absents de Git |
| `mac/Documents/NinjaDuelVFX/nd_*.png`, `meshes/*.fbx` | `~/Documents/NinjaDuelVFX` | Textures et maillages VFX du labo |
| `mac/Documents/NDLooks/*.fbx` | `~/Documents/NDLooks` | Exports FBX des looks (mêmes octets que `NinjaDuelBlender/out/*.fbx`) |
| `mac/Documents/NinjaDuelMedia/**` (txt, md, json, py, sh, luau) | `~/Documents/NinjaDuelMedia` | Fichiers de travail CLIPS : rapports QC, listes de coupe, scripts de montage, et une copie locale modifiée de `factory/studio/ShotRunner.server.luau` |
| `mac/Documents/ChatGPT/roblox debv/games/ninja-duel/…` | ancien clone Codex (`main`, 11/10), fichiers non suivis | `chidori-blender` (scripts, FBX, validation ; sans les 176 images rendues), `dist/fluidity-2026-10-27`, `PROGRESSION_SKILL_TREES_FOR_CLAUDE.{json,md}` |
| `mac/places-scripts/<place>/…luau` | scripts extraits de places `.rbxlx` | Scripts présents dans une place et dans aucun commit (voir `index.json`) |

Scripts extraits des places :

- `ND-VFX-Lab` (bac à sable VFX, sans BuildFingerprint) : `VfxDesign`, `VfxMesh`, `VfxHit`, deux `Animate`.
- `ND-Clips2` (build Debug `ee356ca`, branche tutoriel) : `PhotoLoad`, `PhotoMode`.
- `ND-Jutsu-Debug-v3` (passe jutsu, 05/11 23 h 07, intermédiaire entre v2 `d67c1ff` et v4 `408cb1e`) : `Effects`, `FamilyFX`, `UltimateFX` modifiés à chaud.
- `Downloads/NinjaDuel-5` et `NinjaDuel-Debug` (16/10, `5c6f3be`) : `VelmoraMotionEngine` modifié à chaud.

Les originaux restent sur le Mac (rien n'a été supprimé).

## Ajout du 07/11, 14 h 50 (heure de Paris)

`mac/places-scripts/ND-Clips-integ-0611_1346/` : la place de tournage
`ND-Clips-integ-0611` a été enregistrée sur le Mac à 14 h 46 avec deux scripts
absents de Git :
- `ByakuganFX`, une itération antérieure à celle de `claude/perception-sharingan` ;
- `ShotRunner`, la correction locale du CM : attendre l'intro d'un vrai duel.
  Elle est portée dans `games/ninja-duel/tools/capture/studio/` de la référence.

`scripts.txt` liste ses 211 scripts.
