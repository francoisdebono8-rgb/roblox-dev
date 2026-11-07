> Guide technique (issue #45). État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md). Ce guide ne définit ni état ni priorité ; il dit comment les quatre discussions travaillent sur la même source.

# Les quatre discussions Claude — une source, quatre places

Le propriétaire travaille avec **quatre discussions Claude** dans le même projet :
DEV, CM (clips), ANIMATEUR (animation/VFX), OUTILLEUR. Ce ne sont pas des agents reliés entre eux : une
discussion ne voit ni la mémoire ni le travail des autres. Leur continuité passe
**uniquement** par Git (GitHub), les fichiers du Mac, les issues et les builds.

## 1. La règle

- **Une branche d'intégration** : `claude/ninja-duel-2026-10-14` (la
  référence vérifiée le 07/11 ; `main` a 530 commits de retard). Une discussion
  vérifie HEAD au début (`git fetch && git log -1 origin/claude/ninja-duel-2026-10-14`).
- **Des branches courtes** partent de la référence : `work/dev-…`,
  `work/anim-…`, `work/capture-…`, `work/tools-…`. Une PR par lot, suite headless
  et `test_build_isolation` avant la fusion. Pas de branche permanente qui se dit
  « la dernière version ».
- **Quatre places, un commit.** `build.py` fabrique les quatre variantes du même
  commit ; personne ne copie une place à la main.
- **Rien ne se corrige dans une place.** Une modification faite dans Studio
  (hot push, `multi_edit`) sert à essayer ; elle remonte dans `src/` avec un test,
  puis on reconstruit. Une place enregistrée à la main n'est plus le même jeu.
- **Publication Roblox** : jamais sans l'accord explicite du propriétaire.

## 2. Matrice des places

| Usage | Place sur le Mac | Build | Contient en plus du jeu | Qui |
|---|---|---|---|---|
| GAME (tester comme un joueur) | `~/Documents/NinjaDuel/PLACES/ND-JEU.rbxlx` | `build.py` | rien | propriétaire, DEV |
| DEV | `PLACES/ND-DEV.rbxlx` | `build.py --debug` | DevHooks, inspecteur, F6, `devcall` | DEV, OUTILLAGE |
| QA | `PLACES/ND-QA.rbxlx` | `build.py --qa` | DEV + batterie NativeQA au Play | agents |
| CAPTURE (filmer) | `PLACES/ND-FILM.rbxlx` | `build.py --capture` | DEV + `tools/capture/studio` (ClipKit, ShotRunner, Sets…) | CLIPS |
| LAB VFX | `NinjaDuel/LAB/VFX/ND-VFX-Lab.rbxlx` | bac à sable, hors build | essais d'effets | ANIMATION/VFX |
| Repro | `NinjaDuel/LAB/repro/` | `tools/make_repro_place.py` | un bug figé | DEV |

Les quatre premières portent le même `runtimeFingerprint` ; Studio l'affiche au
Play : `[NinjaDuel] BUILD … | RUNTIME … | <profil> @ <commit>`. Détails :
[tools/capture](../../tools/capture/README.md).

## 3. Mettre les places du Mac à jour

```sh
bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh            # HEAD de la référence
bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh <sha|branche>
```

Depuis une session liée au Mac, `device_bash` lance la même commande (le script
voit `~/mnt/Documents`). Il clone GitHub dans un dossier temporaire, construit les
quatre profils, vérifie qu'ils ont le même runtime, et refuse d'écraser une place
ouverte (`.lock`). Une place modifiée dans Studio est mise de côté, pas écrasée.
Source : [tools/mac/actualiser_places.sh](../../tools/mac/actualiser_places.sh).
Plus de `ND-Test-vNN` : une ancienne version se reconstruit par son commit.

## 3 bis. Une modification n'est disponible qu'une fois intégrée

Une modification de gameplay faite par une discussion (DEV, ANIMATEUR, OUTILLEUR
ou CM) n'existe pour les autres qu'une fois **fusionnée dans la branche de
référence, suite headless verte et vérifiée dans Studio**. Avant cela, elle vit
sur sa branche `work/…` et personne ne la prend comme base. Exemple du 07/11 :
`claude/perception-sharingan` (10 commits) avait été faite sans lancer les
suites ; à l'intégration, sept suites tombaient (deux régressions de gameplay,
trois bugs réels, deux défauts du banc de test). Voir
[le rapport d'intégration](../reports/sharingan-integration-2026-11-07/RAPPORT.md).

Avant de pousser une branche à intégrer : `bash games/ninja-duel/tests/run.sh`
(luau et lune installés), `python3 -m unittest discover -s games/ninja-duel/tests -p test_build_isolation.py`.
Une suite non lancée s'écrit « non lancée », jamais « passe ».

## 3 ter. Tournages : les rushes sont temporaires

Règle du propriétaire (07/11) :
- un enregistrement OBS sert à fabriquer un clip ; **clip terminé → on garde
  l'export final** (alias dans `MEDIA/00_CLIPS_FINAUX/`) **et on supprime ses
  rushes et exports intermédiaires**, après avoir montré la liste au
  propriétaire ;
- les seuls enregistrements longs qu'on garde sont ceux qu'on est en train
  d'analyser pour voir ce qui cloche ; une fois corrigé, on les supprime ;
- une prise ratée (noire, écran de bureau, défaite, autre fenêtre devant) se
  supprime dans la journée ;
- archiver sur le même disque ne libère rien : on ne déplace pas les rushes
  dans `ARCHIVES`.

Le 07/11, cette règle appliquée aux anciens tournages a libéré 12,9 Go
(32 rushes `.mov`, 347 exports intermédiaires, etc.) : voir
[MAC_CLEANUP_RESULT](../reports/mac-local-2026-11-07/MAC_CLEANUP_RESULT.md).

## 3 quater. DEV et ANIMATEUR : qui touche quoi (07/11, mission « game feel »)

Les deux discussions travaillent sur le combat en même temps. Pour ne jamais modifier
le même fichier chacune de son côté :

| Domaine | Propriétaire | Fichiers |
|---|---|---|
| Moteur du combat : orientation, distances, timing des coups, contacts, réactions, états, combos, IA | **DEV** | `src/Server/*` (Combat, Brawler, Motor, BanglaCombat, Bodies, Legion, Hounds, Copy, Interactions, AI…), `src/Shared/Config.luau`, `Shared/Attacks.luau`, `Shared/Fighters.luau` (valeurs de combat : startup, active, recovery, portée, recul) |
| Rendu des corps, caméra, prédiction | **DEV** | `src/Client/Camera.luau`, `Presentation.luau`, `BodyViews.luau`, `VelmoraMotionEngine.luau` (le moteur qui pose les clips), `Input.luau` |
| Poses, clips, transitions corporelles, mouvements de jutsu | **ANIMATEUR** | `src/Client/AuthoredClips*.luau`, `AuthoredJutsu*.luau`, `AuthoredMotion.luau`, `~/Documents/NinjaDuel/BLENDER`, `motion-lab/` |
| Effets visuels des jutsu | **ANIMATEUR** | `src/Client/*FX.luau` (ChakraFX, LeeFX, UltimateFX, ElementFX…), `assets/` des effets |

Règles :
- **Le timing appartient au DEV.** Un clip s'aligne sur la mise en garde, la phase active et la récupération de `Shared/Attacks`. Si l'ANIMATEUR a besoin d'un autre timing, il le demande au DEV (issue étiquetée `besoin-dev`) au lieu de changer les chiffres.
- **Le moteur de pose appartient au DEV.** Si l'ANIMATEUR a besoin d'une fonction dans `VelmoraMotionEngine`, il ouvre une issue ou une PR ne contenant que cette fonction, que le DEV relit.
- **Le DEV demande des poses par issue** (étiquette `besoin-animateur`). Il cite le défaut vu dans Studio, l'heure, le build et le coup concerné. La liste du 07/11 : [audit du combat](../reports/feel-audit-2026-11-07/AUDIT.md#besoins-pour-lanimateur-zones--runbook--3-quater).
- **L'intégration finale passe par le DEV.** Une PR de l'ANIMATEUR est fusionnée par le DEV après la suite headless et un passage dans `ND-DEV`.
- **Studio : une discussion par place.** Pendant qu'une discussion joue une place, aucune autre ne lance de duel dedans. Pour mesurer, faire une copie dans `LAB/repro/` et ouvrir cette copie. Le 07/11, deux sessions ont piloté `ND-DEV` en même temps et les duels de l'une ont relancé ceux de l'autre.

## 4. Remonter un bug

Une ligne, dans l'issue ou le message au DEV : date et heure, place
(`ND-JEU`/`ND-DEV`/`ND-FILM`), la ligne `[NinjaDuel] BUILD … @ <commit>`,
personnages, ce qui a été fait, ce qui était attendu, prise vidéo ou capture.
Le DEV corrige sur une branche `work/dev-…`. Après la fusion, le CM relance
`actualiser_places.sh` et vérifie que le `@ <commit>` affiché a changé.

## 5. Fiches de démarrage (à coller au début de chaque discussion)

### DEV

```
Tu es la discussion DEV de Ninja Duel (repo francoisdebono8-rgb/roblox-dev).
1. Lis games/ninja-duel/CLAUDE_START_HERE.md puis docs/tools/RUNBOOK_4_DISCUSSIONS.md.
2. git fetch ; pars de origin/claude/ninja-duel-2026-10-14 (vérifie HEAD et CURRENT_STATE).
3. Travaille sur une branche work/dev-<sujet>. Code dans src/, test dans tests/.
4. Avant PR : bash games/ninja-duel/tests/run.sh + test_build_isolation (SKIPPED ≠ PASS).
5. Studio : ouvre ~/Documents/NinjaDuel/PLACES/ND-DEV.rbxlx ; un essai à chaud se reporte dans src/.
6. Après fusion : bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh, puis rejoue dans ND-DEV.
7. Jamais : nouvelle place numérotée, publication sans accord, force push.
8. Bugs reçus du CM : ils citent « BUILD … @ <commit> » ; reproduis sur ce commit.
9. Mets à jour CURRENT_STATE / MASTER_BACKLOG (fait prouvé, ID) à chaque lot.
10. Ton travail n'est disponible pour les autres qu'une fois fusionné dans la référence, suite verte
    et vu dans Studio. Ne pars jamais de la branche d'une autre discussion non intégrée.
11. Poses, clips et *FX sont à l'ANIMATEUR (§ 3 quater) : un besoin = une issue « besoin-animateur ».
    Tu relis et fusionnes ses PR (suite + ND-DEV). Pour mesurer dans Studio, travaille dans une copie
    LAB/repro/, jamais dans une place qu'une autre discussion joue.
```

### CM (clips)

```
Tu es la discussion CM (clips) de Ninja Duel.
1. Lis docs/tools/RUNBOOK_4_DISCUSSIONS.md et games/ninja-duel/tools/capture/README.md.
2. Tu filmes dans ~/Documents/NinjaDuel/PLACES/ND-FILM.rbxlx, rien d'autre.
3. Avant un tournage : actualiser_places.sh, puis note la ligne « RUNTIME … capture @ <commit> ».
4. Les rushes, montages et exports vont dans ~/Documents/NinjaDuel/MEDIA/<FILMxx>/ (alias : NinjaDuelMedia).
   Clip terminé : alias de l'export dans MEDIA/00_CLIPS_FINAUX/, puis liste des rushes et
   intermédiaires à supprimer montrée au propriétaire, puis suppression (pas d'archive sur le Mac).
5. Un bug au tournage → message au DEV avec heure, BUILD @ commit, prise. Tu ne corriges pas le jeu.
6. Un outil de tournage à changer : branche work/capture-<sujet>, fichiers tools/capture/, PR.
7. Ne publie rien sur Roblox ; ne refais pas de place ND-Clips-vNN à la main.
8. Les anciennes places de clips sont dans NinjaDuel/ARCHIVES/places/clips (lecture seule par convention).
```

### ANIMATEUR (animation / VFX)

```
Tu es la discussion ANIMATEUR (animation/VFX) de Ninja Duel.
1. Lis docs/tools/RUNBOOK_4_DISCUSSIONS.md.
2. Blender : ~/Documents/NinjaDuel/BLENDER (alias NinjaDuelBlender) ; ne touche pas Chidori_R15.blend.
3. Essais d'effets : ~/Documents/NinjaDuel/LAB/VFX/ND-VFX-Lab.rbxlx (bac à sable, hors build).
4. Un clip ou un effet validé entre dans le jeu par une PR : branche work/anim-<sujet>,
   données dans src/ ou assets/, tests, puis build. Pas de copie de script dans une place.
5. Exporte les JSON/FBX utiles dans Git avec la PR (le Mac n'est pas une sauvegarde).
6. Vérifie le résultat dans ND-DEV après actualiser_places.sh, jamais dans une vieille place.
7. claude/vfx-redesign n'est pas intégrée : son intégration passe par une revue ciblée (vfx2/vfx3).
8. Tes fichiers : clips, poses, jutsu animés, *FX (§ 3 quater). Le moteur (Server/*, Config, Attacks,
   Camera, Presentation, VelmoraMotionEngine) est au DEV : demande par issue « besoin-dev ».
9. Les demandes du DEV arrivent en issues « besoin-animateur » ; commence par la liste de
   docs/reports/feel-audit-2026-11-07/AUDIT.md.
```

### OUTILLEUR

```
Tu es la discussion OUTILLEUR de Ninja Duel.
1. Lis docs/tools/RUNBOOK_4_DISCUSSIONS.md, build.py, tests/test_build_isolation.py.
2. Tu gardes : build.py (4 profils, runtimeFingerprint), tools/capture, tools/mac, tools/studio.
3. Branche work/tools-<sujet>, PR, test_build_isolation + suite avant fusion.
4. Le Mac : ~/Documents/NinjaDuel (PLACES, MEDIA, BLENDER, LAB, ARCHIVES, _maintenance).
   Pas de suppression sans liste exacte + accord du propriétaire.
5. Après un changement de build : actualiser_places.sh sur le Mac et vérifie que les sha256
   de PLACES/*.json égalent ceux de dist/ du commit.
6. Inventaire et rangement de référence : docs/reports/mac-local-2026-11-07/.
```

## 6. Basculer la place publiée (plan, non exécuté)

La version publiée réelle n'est pas prouvée depuis un fichier local (CURRENT_STATE
dit v36 publiée le 04/11, à revérifier dans le Creator Hub). Quand le propriétaire
le demande, et seulement alors :

1. Noter la version publiée actuelle (Creator Hub → historique des versions).
2. Construire `ND-JEU` du commit choisi, suite et QA native verte, partie humaine.
3. Ouvrir `ND-JEU.rbxlx`, Fichier → Publier sur la place existante (même PlaceID/UniverseID).
4. Retour arrière : Creator Hub → historique → restaurer la version notée en 1.
5. Consigner commit, sha256, `runtimeFingerprint` et heure dans CURRENT_STATE.
