> Rapport de l'issue #45, phase locale (Mac). Inventaire de départ : [MAC_LOCAL_INVENTORY](MAC_LOCAL_INVENTORY.md). Mode d'emploi des discussions : [RUNBOOK](../../tools/RUNBOOK_4_DISCUSSIONS.md).

# MAC_CLEANUP_RESULT — ce qui a été fait sur le Mac (07/11/2026)

Actions faites le 07/11/2026 entre 12 h 45 et 13 h 15 UTC, depuis la session
liée au Mac. **Aucune suppression** : seulement des déplacements à l'intérieur
de `~/Documents`, des copies et des fichiers ajoutés. La liste des suppressions
possibles attend l'accord du propriétaire (§ 6).

## 1. Statut par élément

| Élément | Statut |
|---|---|
| 4 716 fichiers Ninja Duel (14,37 Go) | **INVENTORIED** : sha1 de chaque fichier avant (`_maintenance/manifest_before.tsv`) et après (`manifest_after.tsv`). Comparaison : 0 fichier introuvable, 0 contenu changé. |
| Fichiers présents seulement sur le Mac | **ARCHIVED** sur GitHub, branche `archive/mac-local-2026-11-07` (`23f33f3`). Les originaux restent sur le Mac. |
| 45 places : v22, v30 à v39 (Jeu, Labo, Test), Clips, passe jutsu | **ARCHIVED** dans `NinjaDuel/ARCHIVES/places/` (déplacées) |
| 11 builds d'octobre des Téléchargements | **ARCHIVED** : copiés dans `ARCHIVES/telechargements/` (sha1 identique). Les originaux sont toujours dans Téléchargements. |
| `NinjaDuelMedia`, `NinjaDuelBlender`, `NDLooks`, `NinjaDuelVFX`, `Roblox/repro` | **ARCHIVED** au sens rangés : déplacés sous `NinjaDuel/` avec un alias à l'ancien chemin |
| 3 verrous Studio périmés, dossier de test Git, `server.rbxl`, doublons exacts, `.blend1` | **INVENTORIED**, suppression proposée (§ 6) |
| Archives en lecture seule | **BLOCKED** : le partage du Mac ignore `chmod` depuis la session. Le propriétaire peut les verrouiller dans le Finder (Lire les informations → Verrouillé). |
| Dépôt Git sur le Mac | **BLOCKED** : un clone dans un dossier partagé laisse des verrous `.lock` (pas de droit de suppression, testé). Les places sont reconstruites depuis GitHub dans un clone temporaire (§ 3). |
| `Roblox/ND-Test-Sharingan.rbxlx` | **BLOCKED** : laissée en place, c'est le fichier actif de la discussion « perception-sharingan », réécrit à 12 h 18. |
| `MEDIA/ND-Clips-integ-0611.rbxlx` | **BLOCKED** : ouverte dans Studio, laissée en place (archiver une fois fermée) |
| 6 captures et 2 enregistrements d'écran à la racine de Documents | **INVENTORIED**, laissés en place : le propriétaire doit confirmer qu'ils sont Ninja Duel |
| Rushes OBS `.mov` (32 dans MEDIA, 10,3 Go) | **DELETED WITH APPROVAL** (reprise 07/11, § 7) : tous rattachés à un clip terminé (export final vérifié) ou à un travail clos |
| **DELETED WITH APPROVAL** | 3 063 fichiers, 12,9 Go, lots A à G validés par le propriétaire (« tous », 07/11 14 h 35) : § 7 |

## 2. Avant / après

| | Avant | Après |
|---|---|---|
| Où ouvrir pour développer | `Roblox/ND-Test-travail.rbxlx` (build Debug de `9a52e70`, 06/11, deux commits de retard) ou `ND-Test-v39`, ou une place de clips | `NinjaDuel/PLACES/ND-DEV.rbxlx` (Debug de `9fdc528`) |
| Où ouvrir pour tester comme un joueur | `ND-Jeu-v39.rbxlx` (5/11) ou `ND-Jeu.rbxlx` (v22) | `PLACES/ND-JEU.rbxlx` (release du même commit) |
| Où ouvrir pour filmer | `NinjaDuelMedia/ND-Clips-integ-0611` ou `-v39` ou `-v32` ou `ND-Clips2`, faites à la main à partir d'une place de test | `PLACES/ND-FILM.rbxlx`, construite par `build.py --capture` à partir du même commit |
| Places `.rbxlx` dans `~/Documents/Roblox` | 39 places + `server.rbxl` | `ND-Test-Sharingan` (autre discussion) + `server.rbxl` |
| Dossiers Ninja Duel à la racine de Documents | 4 (`NinjaDuelMedia`, `NinjaDuelBlender`, `NinjaDuelVFX`, `NDLooks`) + places dans `Roblox` | 1 dossier `NinjaDuel`, plus 4 alias de compatibilité |
| Même jeu dans DEV, JEU, FILM ? | non vérifiable (fingerprints différents par profil, places de clips faites à la main) | oui : `runtimeFingerprint` `1dfa3dbc4a16` dans les 4 places, affiché au Play |
| Volume Ninja Duel | 14,37 Go | 14,45 Go après rangement, **1,3 Go** après les suppressions validées |
| Doublons exacts | 177,6 Mo | supprimés (lots D et G) |

## 3. GitHub = Mac = Studio

- Branche canonique : `claude/ninja-duel-2026-10-14`. Lot 1 de #45 fusionné par la PR #46 :
  profil `--capture`, `runtimeFingerprint`, `sourceCommit`, `headCommit`, `profile` dans les manifestes.
  Les sources sont celles du commit `9fdc528` et le build `b64ce82` (`dist/` des 4 profils).
- `PLACES/` a été reconstruit **sur le Mac** depuis GitHub par `_outils/actualiser_places.sh`
  (clone temporaire, `build.py` ×4). Résultat octet pour octet identique au `dist/` de GitHub :

| Place | Profil | buildFingerprint | sha256 (Mac = GitHub `dist/`) |
|---|---|---|---|
| `ND-JEU.rbxlx` | release | `1dfa3dbc4a16` | `3468610f6169` |
| `ND-DEV.rbxlx` | debug | `1c075025910d` | `8d5a3a8a4652` |
| `ND-QA.rbxlx` | qa | `a75e4a26088d` | `3f45df1483a3` |
| `ND-FILM.rbxlx` | capture | `76e571354055` | `7fbb70429934` |

- Suite headless sur ces sources : 39 PASS, 2 FAIL déjà présents sur `bc98ec6` (`Chakra.spec` « client: marks… », `Identity.spec:1169`). `test_build_isolation` : 11/11. Les manifestes portent `automatedQA: SKIPPED` (le build lui-même n'a pas lancé les suites), ce qui ne vaut pas PASS.

## 4. Validation dans Studio (vraie ouverture des fichiers)

| Place | Ouverte depuis | Résultat |
|---|---|---|
| `PLACES/ND-DEV.rbxlx` | Studio, Fichier → Ouvrir | Play : `[NinjaDuel] BUILD 1c075025… \| RUNTIME 1dfa3dbc… \| debug @ 9fdc5283213c`. Duel IA contre IA lancé par `devcall` (start + autopilot), Minato contre Itachi ; Itachi tombe à 118/130 en 12 s, cratère au sol vu dans la capture. Outils de dev : OK. |
| `PLACES/ND-FILM.rbxlx` | Studio, Fichier → Ouvrir | Play : `… \| RUNTIME 1dfa3dbc… \| capture @ 9fdc5283213c`, même runtime que DEV. `ReplicatedStorage.NDFactory` (ClipKit, HiraishinKunai), `ServerStorage.NDFactory` (ShotRunner, Sets, SetSnapshot), `NDFactoryBoot` présents. Le canal de la fabrique (`workspace.NDRun`) a lancé un duel Sasuke contre Kakashi et l'autopilote, puis a renvoyé l'état. Outils de tournage : OK. Fermée sans enregistrer. |
| `ND-JEU`, `ND-QA` | — | pas ouvertes dans Studio. Mêmes octets que GitHub ; la batterie QA native n'a pas été lancée (**NEEDS STUDIO**). |

Studio garde `ND-DEV` ouverte et la place de clips du 06/11 intacte ; `ND-DEV`
et `ND-FILM` sont en tête des récents de Studio.

## 5. Raccourcis et chemins

- `~/Documents/NinjaDuel/00_LISEZ-MOI.md` : quel fichier ouvrir, quels dossiers.
- `~/Documents/Roblox/LISEZ-MOI-NinjaDuel.txt` : renvoie vers `NinjaDuel/PLACES`.
- Alias (liens symboliques relatifs, vus comme tels par macOS) : `NinjaDuelMedia → NinjaDuel/MEDIA`,
  `NinjaDuelBlender → NinjaDuel/BLENDER`, `NinjaDuelVFX → NinjaDuel/LAB/VFX`,
  `NDLooks → NinjaDuel/BLENDER/NDLooks`, `Roblox/repro → ../NinjaDuel/LAB/repro`.
  Les outils Blender (25 références à `~/Documents/NinjaDuelBlender`), OBS et les
  autres discussions continuent de marcher sans changement.
- Mise à jour des places : `bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh [branche|commit]`
  (source versionnée : `games/ninja-duel/tools/mac/actualiser_places.sh`).
- Annulation complète du rangement : `bash ~/Documents/NinjaDuel/_maintenance/restaurer.sh`
  (dans un Terminal macOS ; il retire les alias puis remet chaque élément en place).

## 6. Première proposition (599 Mo), remplacée par les lots du § 7

Rien n'est supprimé sans un « oui » du propriétaire, avec la liste exacte
ci-dessous. Fichier sur le Mac : `NinjaDuel/_maintenance/PROPOSITION_SUPPRESSION.tsv`.

- **Niveau 1, 56 éléments, 212 Mo.** Copies exactes dont l'original est gardé : Téléchargements copiés dans les archives, mixamo identiques à `BLENDER/mixamo`, exports vidéo en double dans `FILM01/04_EXPORT`. Plus des fichiers sans valeur : `.blend1`, verrous périmés, dossier de test, `server.rbxl`.
- **Niveau 2, 35 éléments, 387 Mo.** Les places archivées `jeu-release`, `labo-qa` et `test-debug` (v22, v30 à v39). Ce sont des builds de commits connus et tous leurs scripts sont dans Git. Les garder ne coûte que de la place. À ne supprimer que si le propriétaire le souhaite.
- **Jamais proposés.** Les rushes `.mov`, les montages, les `.blend`, les places de clips et de la passe jutsu (`ND-Jutsu-Debug-v3` contient des scripts uniques), le labo VFX, les fichiers du Bureau et des Téléchargements sans lien avec le jeu.

#### Niveau 1

| Chemin (sous `~/`) | Taille | Pourquoi |
|---|---|---|
| `Downloads/NinjaDuel-2.rbxlx` | 0.5 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-2.rbxlx |
| `Downloads/NinjaDuel-3.rbxlx` | 0.5 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-3.rbxlx |
| `Downloads/NinjaDuel-4.rbxlx` | 0.6 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-4.rbxlx |
| `Downloads/NinjaDuel-5.rbxlx` | 0.8 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-5.rbxlx |
| `Downloads/NinjaDuel-6.rbxlx` | 1.3 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-6.rbxlx |
| `Downloads/NinjaDuel-7.rbxlx` | 1.4 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-7.rbxlx |
| `Downloads/NinjaDuel-8.rbxlx` | 1.6 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-8.rbxlx |
| `Downloads/NinjaDuel-9.rbxlx` | 1.7 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-9.rbxlx |
| `Downloads/NinjaDuel-Debug.rbxlx` | 0.8 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel-Debug.rbxlx |
| `Downloads/NinjaDuel.rbxlx` | 0.4 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel.rbxlx |
| `Downloads/NinjaDuel.rbxlx.html` | 1.4 Mo | copie exacte de NinjaDuel/ARCHIVES/telechargements/NinjaDuel.rbxlx.html |
| `Downloads/mixamo_aerial_backflip.fbx` | 0.5 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_aerial_backflip.fbx |
| `Downloads/mixamo_big_jump_roll.fbx` | 0.5 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_big_jump_roll.fbx |
| `Downloads/mixamo_fall_roll.fbx` | 0.5 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_fall_roll.fbx |
| `Downloads/mixamo_fight_idle.fbx` | 0.5 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_fight_idle.fbx |
| `Downloads/mixamo_front_flip.fbx` | 0.5 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_front_flip.fbx |
| `Downloads/mixamo_hop.fbx` | 0.5 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_hop.fbx |
| `Downloads/mixamo_idle_to_sprint.fbx` | 0.3 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_idle_to_sprint.fbx |
| `Downloads/mixamo_jump_run.fbx` | 0.4 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_jump_run.fbx |
| `Downloads/mixamo_jump_run_forward.fbx` | 0.4 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_jump_run_forward.fbx |
| `Downloads/mixamo_jump_up.fbx` | 0.3 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_jump_up.fbx |
| `Downloads/mixamo_mma_idle.fbx` | 0.6 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_mma_idle.fbx |
| `Downloads/mixamo_run_stop.fbx` | 0.4 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_run_stop.fbx |
| `Downloads/mixamo_run_turn180.fbx` | 0.5 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_run_turn180.fbx |
| `Downloads/mixamo_sneak_walk.fbx` | 0.3 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_sneak_walk.fbx |
| `Downloads/mixamo_walk.fbx` | 0.4 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_walk.fbx |
| `Downloads/mixamo_walk_back.fbx` | 0.4 Mo | copie exacte de NinjaDuel/BLENDER/mixamo/mixamo_walk_back.fbx |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(6)/1105 (1)(6).mp4` | 26.9 Mo | copie exacte de NinjaDuel/MEDIA/B1_PRODIGY_ITACHI/04_EXPORT/NINJA_DUEL_ITACHI_VS_KAKASHI_CLEAN_9x16.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(5)/1105 (1)(5).mp4` | 26.9 Mo | copie exacte de NinjaDuel/MEDIA/B1_PRODIGY_ITACHI/04_EXPORT/NINJA_DUEL_ITACHI_VS_KAKASHI_MASTER_9x16.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(2)/1105 (1)(2).mp4` | 20.5 Mo | copie exacte de NinjaDuel/MEDIA/B1_PRODIGY_ITACHI/04_EXPORT/v1/NINJA_DUEL_ITACHI_VS_KAKASHI_CLEAN_9x16.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(1)/1105 (1)(1).mp4` | 20.6 Mo | copie exacte de NinjaDuel/MEDIA/B1_PRODIGY_ITACHI/04_EXPORT/v1/NINJA_DUEL_ITACHI_VS_KAKASHI_MASTER_9x16.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(2)/1105 (1)(2).AAC` | 0.3 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(1)/1105 (1)(1).AAC |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(4)/1105 (1)(4).AAC` | 0.4 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(3)/1105 (1)(3).AAC |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(6)/1105 (1)(6).AAC` | 0.4 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/1105 (1)(5)/1105 (1)(5).AAC |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/FILM01 The Kunai Was Bait/FILM01 The Kunai Was Bait.mp4` | 10.8 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/v4/NINJA_DUEL_KUNAI_TRAP_MASTER_9x16_v4.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/FILM01 The Kunai Was Bait(1)/FILM01 The Kunai Was Bait(1).mp4` | 12.1 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/v5/NINJA_DUEL_KUNAI_TRAP_MASTER_9x16_v5.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/FILM01 The Kunai Was Bait(2)/FILM01 The Kunai Was Bait(2).mp4` | 16.9 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/v6/NINJA_DUEL_KUNAI_TRAP_MASTER_9x16_v6.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/FILM01 The Kunai Was Bait(3)/FILM01 The Kunai Was Bait(3).mp4` | 17.1 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/v7/NINJA_DUEL_KUNAI_TRAP_MASTER_9x16_v7.mp4 |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/LeeItachi_SpeedIsntEnough_v5/LeeItachi_SpeedIsntEnough_v5.AAC` | 0.3 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/LeeItachi_SpeedIsntEnough_v4/LeeItachi_SpeedIsntEnough_v4.AAC |
| `Documents/NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/NINJA_DUEL_KUNAI_TRAP_MASTER_9x16_v3/NINJA_DUEL_KUNAI_TRAP_MASTER_9x16_v3.AAC` | 0.1 Mo | copie exacte de NinjaDuel/MEDIA/FILM01_KUNAI_TRAP/04_EXPORT/NINJA_DUEL_KUNAI_TRAP_CLEAN_9x16_v3/NINJA_DUEL_KUNAI_TRAP_CLEAN_9x16_v3.AAC |
| `Downloads/mixamo_lot1.zip` | 35.4 Mo | son contenu (71 FBX) est déjà dans NinjaDuel/BLENDER/mixamo, octet pour octet |
| `Documents/NinjaDuel/BLENDER/ND_VFX_meshes.blend1` | 0.1 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Lee_v1.blend1` | 0.4 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Minato_Loco.blend1` | 0.3 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Minato_v2.blend1` | 0.7 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Naruto_v1.blend1` | 0.4 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Sasuke.blend1` | 0.2 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Sasuke_Loco.blend1` | 0.4 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Sasuke_v2.blend1` | 0.4 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/NinjaDuel_Sasuke_v3.blend1` | 0.4 Mo | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/BLENDER/Untitled.blend1` | 99 Ko | sauvegarde automatique Blender de la version précédente du .blend voisin |
| `Documents/NinjaDuel/_maintenance/verrous-studio-perimes/ND-Jeu-v30.rbxlx.lock` | 0 Ko | verrou Studio périmé (place fermée) |
| `Documents/NinjaDuel/_maintenance/verrous-studio-perimes/ND-Labo.rbxlx.lock` | 0 Ko | verrou Studio périmé (place fermée) |
| `Documents/NinjaDuel/_maintenance/verrous-studio-perimes/ND-VFX-Lab.rbxlx.lock` | 0 Ko | verrou Studio périmé (place fermée) |
| `Documents/NinjaDuel/_maintenance/sondes-2026-11-07/gt-test-git-sans-suppression` | 25 Ko | dossier de test créé pendant l’inventaire |
| `Documents/Roblox/server.rbxl` | 2.0 Mo | fichier binaire écrit par Studio le 06/11, pas un build |

#### Niveau 2

| Chemin (sous `~/`) | Taille | Pourquoi |
|---|---|---|
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v30.rbxlx` | 10.5 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v31.rbxlx` | 10.6 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v32.rbxlx` | 10.6 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v33.rbxlx` | 10.6 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v34.rbxlx` | 10.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v35.rbxlx` | 10.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v35b.rbxlx` | 10.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v36.rbxlx` | 10.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v37.rbxlx` | 11.5 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v38.rbxlx` | 11.5 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu-v39.rbxlx` | 11.5 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/jeu-release/ND-Jeu.rbxlx` | 11.3 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v30.rbxlx` | 10.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v31.rbxlx` | 10.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v32.rbxlx` | 10.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v33.rbxlx` | 10.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v34.rbxlx` | 10.9 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v35.rbxlx` | 10.9 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v36.rbxlx` | 10.9 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v37.rbxlx` | 11.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v38.rbxlx` | 11.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo-v39.rbxlx` | 11.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/labo-qa/ND-Labo.rbxlx` | 11.5 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-travail.rbxlx` | 12.0 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v30.rbxlx` | 10.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v31.rbxlx` | 10.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v32.rbxlx` | 10.7 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v33.rbxlx` | 10.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v34.rbxlx` | 10.9 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v35.rbxlx` | 10.9 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v35b.rbxlx` | 10.9 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v36.rbxlx` | 10.9 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v37.rbxlx` | 11.6 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v38.rbxlx` | 11.6 Mo | build d’un commit connu, tous ses scripts sont dans Git |
| `Documents/NinjaDuel/ARCHIVES/places/test-debug/ND-Test-v39.rbxlx` | 11.8 Mo | build d’un commit connu, tous ses scripts sont dans Git |


## 7. Reprise du 07/11 : les rushes triés, 12,9 Go supprimés

Demande du propriétaire (issue #45, reprise) : clip terminé → garder l'export
final, supprimer rushes et intermédiaires ; ne rien « archiver » sur le même
disque. Méthode :
- les 32 `.mov` ouverts un par un (deux images chacun, durée, date de prise) ;
- chacun rattaché à son clip ;
- les 11 exports finaux relus en entier (`ffmpeg -f null`), sans erreur ;
- alias des exports finaux dans `MEDIA/00_CLIPS_FINAUX/`.

| Clip | Export final gardé | Vérifié |
|---|---|---|
| FILM01 Minato vs Neji « The Kunai Was Bait » | `FILM01_KUNAI_TRAP/04_EXPORT/v7/…_MASTER_9x16_v7.mp4` (+ preuve de gameplay non coupée) | 11,1 s, 1080×1920, 0 erreur |
| FILM02 Lee vs Itachi « Speed isn't enough » (v5 livrée) | `…/LeeItachi_SpeedIsntEnough_v5.mp4` | 29,7 s, 0 erreur |
| FILM03 Naruto vs Minato « Who Wins? » (v1) | `…/NarutoMinato_WhoWins_v1.mp4` | 23,4 s, 0 erreur |
| B1 Itachi vs Kakashi | `…_MASTER_9x16.mp4`, `…_CLEAN_9x16.mp4` | 17,7 s, 0 erreur |
| Legend01 Naruto vs Sasuke | les deux exports du 04/11 | 18,2 s, 0 erreur |
| Who Wins 01 / 02, Tournoi « Who Wins » | les trois `_FINAL.mp4` | 0 erreur |

Lots validés (« tous ») et supprimés :

| Lot | Contenu | Volume |
|---|---|---|
| A | 22 rushes OBS des clips terminés, dont 5 prises vides ou noires | 8,41 Go |
| B | 2 rushes de FILM03 (rangés par erreur dans FILM02) | 1,03 Go |
| C | 8 enregistrements hors clip : mission FEEL, revue des jutsu du 05/11 au soir | 0,83 Go |
| D | 347 exports intermédiaires, plans découpés, sélections, copies d'exports | 1,84 Go |
| E | 35 anciennes places v22, v30–v39 | 0,39 Go |
| F | 2 606 rendus PNG de revue Blender | 0,35 Go |
| G | 43 doublons et déchets (Téléchargements, mixamo, `.blend1`, verrous, `server.rbxl`) | 0,06 Go |

Résultat mesuré (`df` sur le volume) :
- espace libre : 27 087 512 Kio avant, 38 285 852 Kio après (de 25,8 à 36,5 Gio, soit **+11,5 Go**) ;
- fichiers supprimés : 3 063, pour 12,9 Go ;
- 55 dossiers vidés retirés ;
- 0 fichier ignoré.

L'écart entre les deux chiffres était en train de se résorber au fil des
mesures. Nous ne l'avons pas vérifié, mais il vient probablement de la gestion
d'espace de macOS.

Le journal ligne par ligne est dans `_maintenance/SUPPRIME_2026-11-07.tsv`, les lots dans
`_maintenance/LOTS_SUPPRESSION_2026-11-07.tsv`. Restent gardés :
- les exports finaux ;
- `jobs/devlog01` : aucun export final n'a été trouvé ;
- les miniatures, textes et scripts ;
- les places de clips et de la passe jutsu (des scripts uniques) ;
- les copies d'octobre dans `ARCHIVES/telechargements`.

La règle est inscrite pour les tournages futurs dans le [RUNBOOK](../../tools/RUNBOOK_4_DISCUSSIONS.md) (§ 3 ter).
