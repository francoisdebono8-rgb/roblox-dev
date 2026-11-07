> Rapport de l'issue #45, phase locale (Mac). État et règles : [sources actives](../../active/EXECUTION_RULES.md). Résultat des actions : [MAC_CLEANUP_RESULT](MAC_CLEANUP_RESULT.md).

# MAC_LOCAL_INVENTORY — fichiers Ninja Duel du Mac (07/11/2026)

Inventaire **réel** fait sur le Mac du propriétaire (`air-de-francois-home`)
via la session liée (shell sur les dossiers connectés Documents, Bureau,
Téléchargements + Studio MCP), le 07/11/2026 entre 12 h 20 et 13 h 00 UTC.
Recherche limitée aux éléments Ninja Duel : dossiers `NinjaDuel*`, `NDLooks`,
`Roblox`, ancien clone `ChatGPT/roblox debv`, fichiers `NinjaDuel*`/`mixamo_*`
des Téléchargements, captures d'écran récentes de Documents. Rien sur le
Bureau (aucun nom lié à Ninja Duel). Aucun autre fichier personnel ouvert.

Méthode : sha1 de **chaque** fichier (4 716 fichiers, 14,37 Go,
`_maintenance/manifest_before.tsv`) ; pour chaque place `.rbxlx`, lecture du
`BuildFingerprint` et de chaque script, comparés aux builds de tous les commits
depuis le 08/10 (Release / Debug / QA) et aux blobs Git de toutes les branches
d'`origin`. Doublons = mêmes octets (sha1), jamais le nom ou la date.

## 1. Emplacements trouvés

| Emplacement (avant) | Contenu | Taille | Rôle |
|---|---|---|---|
| `~/Documents/Roblox` | 39 places ND (v30–v39 et v35b ×3 profils, ND-Jeu/ND-Labo de la v22, ND-Test-travail, ND-Test-Sharingan, repro B01–B03), `server.rbxl`, `ninja-duel-roster.bundle`, `showcase itachi.MP4`, 3 verrous `.lock` ; **dossiers système de Studio** (`Plugins`, `0/InstalledPlugins`, `10699076432/InstalledPlugins`, `DefaultInstances`) | 0,7 Go | places de travail successives + réglages Studio |
| `~/Documents/NinjaDuelMedia` | FILM01 (5,8 Go), FILM02 (2,2 Go), jobs (2,1 Go), B1 (1,5 Go), Tournoi, Clips, FEEL, FILM03, Overlays, PageRoblox, factory, cm_tools, places `ND-Clips*` et `JUTSU_PASS/ND-Jutsu-Debug*` ; 34 rushes OBS `.mov` (10,3 Go) | 13 Go | domaine CLIPS |
| `~/Documents/NinjaDuelBlender` | 19 `.blend`, 10 `.blend1`, `out/` (2 606 PNG rendus, 68 JSON, 10 FBX), `mixamo/` (87 FBX), `lib/`, `jobs/`, `ref/`, `runner.py` | 0,41 Go | domaine ANIMATION |
| `~/Documents/NinjaDuelVFX` | `ND-VFX-Lab` (bac à sable), `ND-VFX-Coups` (build release de `claude/vfx-redesign` `907d285`), textures `nd_*.png`, `meshes/`, `v2/`, `v4/` | 16 Mo | domaine VFX |
| `~/Documents/NDLooks` | 9 FBX (mêmes octets que `NinjaDuelBlender/out/*.fbx`) + JSON (dans Git) | 4 Mo | looks |
| `~/Documents/ChatGPT/roblox debv` | ancien clone Codex sur `main` (11/10), aussi espace Forge : **laissé en place** ; fichiers ND non suivis : `assets/animations/chidori-blender`, `dist/fluidity-2026-10-27`, `docs/current/PROGRESSION_SKILL_TREES_FOR_CLAUDE.*` | — | historique Codex |
| `~/Downloads` | `NinjaDuel-2…9.rbxlx`, `NinjaDuel.rbxlx`, `NinjaDuel-Debug.rbxlx`, `NinjaDuel.rbxlx.html` (builds d'octobre), 16 `mixamo_*.fbx` + `mixamo_lot1.zip` | 72 Mo | téléchargements |
| `~/Documents` (racine) | 6 captures d'écran (29/10, 04/11, 06/11) et 2 enregistrements d'écran (06/11, 51 Mo) | 61 Mo | probablement ND : **à confirmer par le propriétaire**, laissés en place |

Aucun dépôt Git Ninja Duel à jour sur le Mac (seul l'ancien clone Codex). Un
clone Git dans un dossier partagé ne fonctionne pas depuis la session
(git y laisse des verrous sans droit de suppression, testé) : le workspace Git
de référence reste GitHub ; le Mac reçoit des places **reconstruites depuis
GitHub** par `_outils/actualiser_places.sh` (clone temporaire hors du dossier).

## 2. Studio au moment de l'inventaire

Un seul Studio ouvert : `NinjaDuelMedia/ND-Clips-integ-0611.rbxlx` (build Debug
de `bc98ec6` + fabrique de clips). Verrous périmés : `ND-Jeu-v30` (03/11),
`ND-Labo` (03/11), `ND-VFX-Lab` (06/11). `ND-Test-Sharingan.rbxlx` réécrit à
12 h 18 UTC par la discussion « perception-sharingan » (fichier actif d'une
autre discussion, non ouvert).

## 3. GitHub au même moment

Branche canonique de fait : `claude/ninja-duel-2026-10-14` (HEAD `bc98ec6` au
début, `b64ce82` à la fin). `main` a 530 commits de retard et n'est pas la
référence. Branches avec du travail non intégré :

| Branche | Commits absents de la canonique | Contenu | Décision |
|---|---|---|---|
| `claude/perception-sharingan` | 10 (07/11 13 h 17) | Sharingan qui copie, ninken, Byakugan, clones | **non intégrée** : 9 suites headless en échec (Combat:130, Regression:315 « slam teleported 5.8 studs », ComboModel, Identity, Chakra, Lee:313, Naruto, Kakashi, Roster20) contre 2 sur la canonique. À corriger dans sa discussion puis PR. |
| `claude/ninja-duel-tutorial-v2` | 17 (05/11) | fabrique de clips (`tools/marketing/factory`), brand, page, graphify | outils Studio de la fabrique **portés** dans `tools/capture/` (profil FILM) ; le reste attend une PR de la discussion CLIPS |
| `claude/vfx-redesign` | 7 (06/11) | assets `vfx2`, `vfx3`, `tools/vfx`, 5 modules client | non intégrée (revue VFX ciblée, phase 1 de #45) |
| `claude/b1-lot4-paused` | 2 (05/11) | lot B1 en pause, bloque sur Online.spec | inchangé |
| `claude/nd-v35-correctifs` | 2 (05/11) | correctifs v35, 56 commits de retard | inchangé (à relire avant tout portage) |
| `claude/minato-hiraishin-kunai` | 1 (04/11) | kunai de Minato | inchangé |
| `claude/jutsu-anim-pass` | 0 | — | déjà intégrée (`9a52e70`) |
| `media-clips` | historique sans ancêtre commun | briefs CM, `cm_tools/` | jamais fusionnée ; `cm_tools/*.luau` et `video_qc.py` copiés dans `tools/capture/` |

## 4. Ce qui n'existait que sur le Mac (modifications locales non synchronisées)

Tout ce qui suit est maintenant sauvegardé sur GitHub, branche d'archive
orpheline `archive/mac-local-2026-11-07` (`23f33f3`, 211 fichiers, 33 Mo), en
plus des originaux restés sur le Mac.

| Élément | Où | Nature |
|---|---|---|
| `VfxDesign`, `VfxMesh`, `VfxHit`, 2 × `Animate` | dans `ND-VFX-Lab.rbxlx` | scripts du bac à sable VFX, jamais commités |
| `PhotoLoad`, `PhotoMode` | dans `ND-Clips2.rbxlx` | outils photo de la place de tournage n° 2 |
| `Effects`, `FamilyFX`, `UltimateFX` | dans `ND-Jutsu-Debug-v3.rbxlx` | état intermédiaire modifié à chaud (05/11 23 h 07), dépassé par v4 `408cb1e` |
| `VelmoraMotionEngine` | dans `Downloads/NinjaDuel-5.rbxlx` et `NinjaDuel-Debug.rbxlx` (16/10) | modifié à chaud après le build `5c6f3be`, dépassé |
| `factory/studio/ShotRunner.server.luau` | `NinjaDuelMedia/factory/studio` | copie locale de la fabrique, différente de Git |
| 59 JSON `out/clips_*`, `poses_*`, `centres`, `runner.py`, `lib/posing.py` | `NinjaDuelBlender` | exports et outils Blender jamais commités |
| `nd_*.png` (9), `meshes/*.fbx` (3) | `NinjaDuelVFX` | textures et maillages VFX |
| 9 FBX de looks | `NDLooks` | exports des looks |
| rapports QC, listes de coupe, scripts de montage (`*.json`, `*.txt`, `*.md`, `*.py`, `*.sh`) | `NinjaDuelMedia` | fichiers de travail CLIPS |
| `chidori-blender`, `dist/fluidity-2026-10-27`, `PROGRESSION_SKILL_TREES_FOR_CLAUDE.*` | ancien clone Codex | non suivis dans ce clone |

Restent **uniquement sur le Mac** (trop lourds pour Git, conservés) : les
rushes et exports vidéo, les sons, les 2 606 rendus PNG Blender, les 176 images
de `chidori-blender/frames`, les `.blend`.

## 5. Doublons exacts (mêmes octets)

116 groupes, 177,6 Mo récupérables, dont :

| Où | Volume | Exemple |
|---|---|---|
| `NinjaDuelMedia/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(n)/…` | 153,4 Mo (14 fichiers) | copies des exports B1 (`B1_PRODIGY_ITACHI/04_EXPORT/…_9x16.mp4`) et des masters « The Kunai Was Bait (n) » |
| `~/Downloads/mixamo_*.fbx` (16) et `mixamo_lot1.zip` | 53 Mo | tout est déjà, octet pour octet, dans `NinjaDuelBlender/mixamo` (y compris les 71 FBX du zip) |
| `NDLooks/*.fbx` | 4,1 Mo | mêmes octets que `NinjaDuelBlender/out/*.fbx` (laissés : la chaîne des looks lit `NDLooks`) |
| petits fichiers (`jobs/*.done`, overlays, sons communs) | < 2 Mo | laissés |

Les places v30–v39 ne sont **pas** des doublons octet pour octet (chaque
fichier diffère) ; v35 et v35b ont le même code (même fingerprint).

## 6. Toutes les places `.rbxlx` / `.rbxl` (65)

« Build : commit / profil » = le commit dont le build reproduit exactement le
`BuildFingerprint` de la place ; « NO MATCH » = place modifiée après son build.
`Main` du serveur diffère toujours (préfixe Debug/QA injecté par `build.py`) et
n'est pas compté.

#### Places de jeu (release) `ND-Jeu*` (12)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Documents/Roblox/ND-Jeu-v30.rbxlx` | 03/11 20:56 | 10.5 Mo | `8b2565177100` | 2e5526bcd/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v30.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v31.rbxlx` | 04/11 15:32 | 10.6 Mo | `59a56c999838` | c8ef0b639/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v31.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v32.rbxlx` | 04/11 15:42 | 10.6 Mo | `e1bf88ba01cc` | 23f472a64/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v32.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v33.rbxlx` | 04/11 16:32 | 10.6 Mo | `1b0553b6df6e` | 42986d132/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v33.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v34.rbxlx` | 04/11 19:32 | 10.7 Mo | `0655ea70c4ba` | 158708bb9/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v34.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v35.rbxlx` | 04/11 20:09 | 10.8 Mo | `d7bd62a71e58` | d9eda379c/release,5ceb884d7/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v35.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v35b.rbxlx` | 04/11 20:25 | 10.8 Mo | `1d21a2eebf75` | d9eda379c/release,5ceb884d7/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v35b.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v36.rbxlx` | 04/11 22:01 | 10.8 Mo | `c77813988caa` | f3b962eb9/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v36.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v37.rbxlx` | 04/11 23:16 | 11.5 Mo | `41c59105ac73` | bc493753f/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v37.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v38.rbxlx` | 04/11 23:49 | 11.5 Mo | `ac54c79e8c69` | 26609e35a/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v38.rbxlx |
| `~/Documents/Roblox/ND-Jeu-v39.rbxlx` | 05/11 00:49 | 11.5 Mo | `2a709e182ed6` | 4b597d133/release | — | ARCHIVES/places/jeu-release/ND-Jeu-v39.rbxlx |
| `~/Documents/Roblox/ND-Jeu.rbxlx` | 03/11 15:02 | 11.3 Mo | `f5b46fe2afa6` | 629817def/release | — | ARCHIVES/places/jeu-release/ND-Jeu.rbxlx |

#### Places Labo (QA) `ND-Labo*` (11)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Documents/Roblox/ND-Labo-v30.rbxlx` | 03/11 20:56 | 10.7 Mo | `c9bfd13fe95e` | 2e5526bcd/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v30.rbxlx |
| `~/Documents/Roblox/ND-Labo-v31.rbxlx` | 04/11 15:32 | 10.8 Mo | `45339c54092d` | c8ef0b639/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v31.rbxlx |
| `~/Documents/Roblox/ND-Labo-v32.rbxlx` | 04/11 15:42 | 10.8 Mo | `2dde226f4e46` | 23f472a64/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v32.rbxlx |
| `~/Documents/Roblox/ND-Labo-v33.rbxlx` | 04/11 16:32 | 10.8 Mo | `15f8a7775322` | 42986d132/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v33.rbxlx |
| `~/Documents/Roblox/ND-Labo-v34.rbxlx` | 04/11 19:32 | 10.9 Mo | `98834e86447a` | 158708bb9/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v34.rbxlx |
| `~/Documents/Roblox/ND-Labo-v35.rbxlx` | 04/11 20:09 | 10.9 Mo | `75b0bbbe4511` | d9eda379c/qa,5ceb884d7/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v35.rbxlx |
| `~/Documents/Roblox/ND-Labo-v36.rbxlx` | 04/11 22:01 | 10.9 Mo | `e23452d7f89d` | f3b962eb9/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v36.rbxlx |
| `~/Documents/Roblox/ND-Labo-v37.rbxlx` | 04/11 23:16 | 11.7 Mo | `1e7f66896306` | bc493753f/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v37.rbxlx |
| `~/Documents/Roblox/ND-Labo-v38.rbxlx` | 04/11 23:49 | 11.7 Mo | `e738402259e6` | 26609e35a/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v38.rbxlx |
| `~/Documents/Roblox/ND-Labo-v39.rbxlx` | 05/11 00:49 | 11.7 Mo | `fa0ce1b3463a` | 4b597d133/qa | — | ARCHIVES/places/labo-qa/ND-Labo-v39.rbxlx |
| `~/Documents/Roblox/ND-Labo.rbxlx` | 03/11 15:03 | 11.5 Mo | `b4784141a07d` | 629817def/qa | — | ARCHIVES/places/labo-qa/ND-Labo.rbxlx |

#### Places de test (Debug) `ND-Test*` (13)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Documents/Roblox/ND-Test-travail.rbxlx` | 06/11 13:35 | 12.0 Mo | `5d28fe5f29e4` | 9a52e70e3/debug | — | ARCHIVES/places/test-debug/ND-Test-travail.rbxlx |
| `~/Documents/Roblox/ND-Test-v30.rbxlx` | 03/11 20:56 | 10.7 Mo | `fe3d541dc1a1` | 2e5526bcd/debug | — | ARCHIVES/places/test-debug/ND-Test-v30.rbxlx |
| `~/Documents/Roblox/ND-Test-v31.rbxlx` | 04/11 15:32 | 10.7 Mo | `21aa5f03009c` | c8ef0b639/debug | — | ARCHIVES/places/test-debug/ND-Test-v31.rbxlx |
| `~/Documents/Roblox/ND-Test-v32.rbxlx` | 04/11 15:42 | 10.7 Mo | `73b3c31f409a` | 23f472a64/debug | — | ARCHIVES/places/test-debug/ND-Test-v32.rbxlx |
| `~/Documents/Roblox/ND-Test-v33.rbxlx` | 04/11 16:32 | 10.8 Mo | `7da5146e2cac` | 42986d132/debug | — | ARCHIVES/places/test-debug/ND-Test-v33.rbxlx |
| `~/Documents/Roblox/ND-Test-v34.rbxlx` | 04/11 19:32 | 10.9 Mo | `7015808c466d` | 158708bb9/debug | — | ARCHIVES/places/test-debug/ND-Test-v34.rbxlx |
| `~/Documents/Roblox/ND-Test-v35.rbxlx` | 04/11 20:09 | 10.9 Mo | `36a29a2d5c8e` | d9eda379c/debug,5ceb884d7/debug | — | ARCHIVES/places/test-debug/ND-Test-v35.rbxlx |
| `~/Documents/Roblox/ND-Test-v35b.rbxlx` | 04/11 20:25 | 10.9 Mo | `e1722f5ffd65` | d9eda379c/debug,5ceb884d7/debug | — | ARCHIVES/places/test-debug/ND-Test-v35b.rbxlx |
| `~/Documents/Roblox/ND-Test-v36.rbxlx` | 04/11 22:01 | 10.9 Mo | `9850f9f89d78` | f3b962eb9/debug | — | ARCHIVES/places/test-debug/ND-Test-v36.rbxlx |
| `~/Documents/Roblox/ND-Test-v37.rbxlx` | 04/11 23:16 | 11.6 Mo | `fbbe1b5f2da1` | bc493753f/debug | — | ARCHIVES/places/test-debug/ND-Test-v37.rbxlx |
| `~/Documents/Roblox/ND-Test-v38.rbxlx` | 04/11 23:49 | 11.6 Mo | `88defdff6b73` | 26609e35a/debug | — | ARCHIVES/places/test-debug/ND-Test-v38.rbxlx |
| `~/Documents/Roblox/ND-Test-v39.rbxlx` | 05/11 12:27 | 11.8 Mo | `94fcc1f25784` | 4b597d133/debug | — | ARCHIVES/places/test-debug/ND-Test-v39.rbxlx |
| `~/Documents/Roblox/ND-Test-Sharingan.rbxlx` | 07/11 12:18 | 11.9 Mo | `9dfd1e71d07e` | 98f28a087/debug | — | ~/Documents/Roblox/ND-Test-Sharingan.rbxlx (laissée en place) |

#### Places de tournage `ND-Clips*` (4)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Documents/NinjaDuelMedia/ND-Clips-v32.rbxlx` | 04/11 15:47 | 10.8 Mo | `a007d6baa6c3` | 23f472a64/debug + fabrique NDFactory | — | ARCHIVES/places/clips/ND-Clips-v32.rbxlx |
| `~/Documents/NinjaDuelMedia/ND-Clips-v39.rbxlx` | 05/11 12:26 | 11.7 Mo | `2b982f786647` | 4b597d133/debug + fabrique NDFactory | — | ARCHIVES/places/clips/ND-Clips-v39.rbxlx |
| `~/Documents/NinjaDuelMedia/ND-Clips2.rbxlx` | 04/11 02:14 | 11.1 Mo | `f98c139ce79c` | ee356ca88/debug | PhotoLoad, PhotoMode | ARCHIVES/places/clips/ND-Clips2.rbxlx |
| `~/Documents/NinjaDuelMedia/ND-Clips-integ-0611.rbxlx` | 06/11 12:15 | 11.9 Mo | `1c9f9cf1162b` | bc98ec641/debug + fabrique NDFactory | — | MEDIA/ND-Clips-integ-0611.rbxlx (ouverte dans Studio, laissée) |

#### Passe jutsu `ND-Jutsu-Debug*` (7)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug-v2.rbxlx` | 05/11 22:57 | 11.7 Mo | `dec67ecec6d6` | d67c1ffaf/debug | — | ARCHIVES/places/jutsu-pass/ND-Jutsu-Debug-v2.rbxlx |
| `~/Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug-v3.rbxlx` | 05/11 23:07 | 11.7 Mo | `dfd131d8649b` | NO MATCH | Effects, FamilyFX, UltimateFX | ARCHIVES/places/jutsu-pass/ND-Jutsu-Debug-v3.rbxlx |
| `~/Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug-v4.rbxlx` | 05/11 23:22 | 11.7 Mo | `5832d4afcd81` | 408cb1ee1/debug | — | ARCHIVES/places/jutsu-pass/ND-Jutsu-Debug-v4.rbxlx |
| `~/Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug-v5.rbxlx` | 05/11 23:29 | 11.7 Mo | `1619735ed920` | e4eff25ce/debug | — | ARCHIVES/places/jutsu-pass/ND-Jutsu-Debug-v5.rbxlx |
| `~/Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug-v6.rbxlx` | 05/11 23:56 | 11.8 Mo | `a1aab26d0564` | b72058a9a/debug | — | ARCHIVES/places/jutsu-pass/ND-Jutsu-Debug-v6.rbxlx |
| `~/Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug-v7.rbxlx` | 06/11 00:05 | 11.8 Mo | `25447175c621` | 7b181cec8/debug | — | ARCHIVES/places/jutsu-pass/ND-Jutsu-Debug-v7.rbxlx |
| `~/Documents/NinjaDuelMedia/JUTSU_PASS/ND-Jutsu-Debug.rbxlx` | 05/11 22:26 | 11.9 Mo | `c888c7109fb1` | 42939bd65/debug | — | ARCHIVES/places/jutsu-pass/ND-Jutsu-Debug.rbxlx |

#### Repro de bugs et labo VFX (5)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Documents/NinjaDuelVFX/ND-VFX-Coups.rbxlx` | 06/11 13:20 | 11.7 Mo | `449d2e5a805d` | 907d285aa/release | — | LAB/VFX/ND-VFX-Coups.rbxlx |
| `~/Documents/NinjaDuelVFX/ND-VFX-Lab.rbxlx` | 06/11 13:31 | 1.1 Mo | `d0827780bfe1` | no fp | Animate, VfxDesign, VfxHit, VfxMesh | LAB/VFX/ND-VFX-Lab.rbxlx |
| `~/Documents/Roblox/repro/ND-Bug-B01.rbxlx` | 03/11 14:34 | 11.5 Mo | `87f92fd65c67` | faba0c4bd/debug | — | LAB/repro/ND-Bug-B01.rbxlx |
| `~/Documents/Roblox/repro/ND-Bug-B02.rbxlx` | 03/11 14:34 | 11.5 Mo | `9be72b2b6c86` | faba0c4bd/debug | — | LAB/repro/ND-Bug-B02.rbxlx |
| `~/Documents/Roblox/repro/ND-Bug-B03.rbxlx` | 03/11 14:34 | 11.5 Mo | `4c41983f83e7` | faba0c4bd/debug | — | LAB/repro/ND-Bug-B03.rbxlx |

#### Téléchargements (10)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Downloads/NinjaDuel-2.rbxlx` | 10/10 22:36 | 0.5 Mo | `0560e77a6007` | 3e6397815/release,3e6397815/debug | — | ARCHIVES/telechargements/NinjaDuel-2.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-3.rbxlx` | 10/10 22:32 | 0.5 Mo | `af21b1c478fe` | NO MATCH | — | ARCHIVES/telechargements/NinjaDuel-3.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-4.rbxlx` | 10/10 23:48 | 0.6 Mo | `a8309f49c607` | NO MATCH | — | ARCHIVES/telechargements/NinjaDuel-4.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-5.rbxlx` | 16/10 01:06 | 0.8 Mo | `6dae32b25374` | 5c6f3bef4/release | VelmoraMotionEngine | ARCHIVES/telechargements/NinjaDuel-5.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-6.rbxlx` | 17/10 01:44 | 1.3 Mo | `9651806d7f03` | 69808f4fd/release | — | ARCHIVES/telechargements/NinjaDuel-6.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-7.rbxlx` | 17/10 22:34 | 1.4 Mo | `399294f694b5` | bc7faa3ad/release | — | ARCHIVES/telechargements/NinjaDuel-7.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-8.rbxlx` | 25/10 22:41 | 1.6 Mo | `10d03b1ac497` | NO MATCH | — | ARCHIVES/telechargements/NinjaDuel-8.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-9.rbxlx` | 26/10 13:27 | 1.7 Mo | `95509980891a` | 936ab3483/release | — | ARCHIVES/telechargements/NinjaDuel-9.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel-Debug.rbxlx` | 16/10 01:03 | 0.8 Mo | `24af51ab9149` | 5c6f3bef4/debug | VelmoraMotionEngine | ARCHIVES/telechargements/NinjaDuel-Debug.rbxlx (copie ; original dans Téléchargements) |
| `~/Downloads/NinjaDuel.rbxlx` | 10/10 19:27 | 0.4 Mo | `11b83cec478b` | 8d7023d0b/release,8d7023d0b/debug | — | ARCHIVES/telechargements/NinjaDuel.rbxlx (copie ; original dans Téléchargements) |

#### Ancien clone Codex et divers (3)

| Chemin d'origine | Date (UTC) | Taille | sha1 | Build : commit / profil | Scripts absents de Git | Décision → nouveau chemin (sous `~/Documents/NinjaDuel/`) |
|---|---|---|---|---|---|---|
| `~/Documents/Roblox/server.rbxl` | 06/11 11:42 | 2.0 Mo | `118eef428e58` | fichier Studio (binaire), pas un build | — | ~/Documents/Roblox/server.rbxl (laissé : fichier de Studio ; suppression proposée) |
| `~/Documents/ChatGPT/roblox debv/games/ninja-duel/dist/NinjaDuel-QA.rbxlx` | 11/10 19:34 | 0.3 Mo | `6a0abd987b94` | bc074ee23/qa | — | ~/Documents/ChatGPT/roblox debv/games/ninja-duel/dist/NinjaDuel-QA.rbxlx (laissé : ancien clone) |
| `~/Documents/ChatGPT/roblox debv/games/ninja-duel/dist/NinjaDuel.rbxlx` | 11/10 19:34 | 0.3 Mo | `8fc600222bae` | bc074ee23/release,bc074ee23/debug | — | ~/Documents/ChatGPT/roblox debv/games/ninja-duel/dist/NinjaDuel.rbxlx (laissé : ancien clone) |

## 7. Plan de rangement (exécuté, voir le résultat)

```
~/Documents/NinjaDuel/
  00_LISEZ-MOI.md       quel fichier ouvrir pour développer, tester, filmer
  PLACES/               ND-DEV, ND-JEU, ND-QA, ND-FILM (+ manifestes, VERSION.md) : un seul commit
  MEDIA/                ← NinjaDuelMedia (inchangé à l'intérieur, sauf places archivées)
  BLENDER/              ← NinjaDuelBlender ; BLENDER/NDLooks ← NDLooks
  LAB/VFX               ← NinjaDuelVFX ; LAB/repro ← Roblox/repro
  ARCHIVES/places/      jeu-release, labo-qa, test-debug, clips, jutsu-pass (+ LISEZ-MOI de provenance)
  ARCHIVES/telechargements, media, git
  _maintenance/         manifestes sha1 avant/après, journal moves.tsv, restaurer.sh, proposition de suppression
  _outils/              actualiser_places.sh
```

Les anciens chemins de dossiers deviennent des liens (alias) vers les
nouveaux : `NinjaDuelMedia`, `NinjaDuelBlender`, `NinjaDuelVFX`, `NDLooks`,
`Roblox/repro`. Restent à leur place : les dossiers système de Studio dans
`~/Documents/Roblox`, `ND-Test-Sharingan.rbxlx` (discussion en cours),
`ND-Clips-integ-0611.rbxlx` (ouverte dans Studio), `server.rbxl`, l'ancien
clone Codex, les captures de la racine de Documents, les originaux des
Téléchargements (copiés dans les archives).
