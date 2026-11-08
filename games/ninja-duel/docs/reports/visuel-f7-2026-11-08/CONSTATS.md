# Premiers constats de l'outil visuel F7 — 08/11/2026

Place : copie DEV `LAB/repro/ND-DEV-outil-F7.rbxlx` (build de `work/tools-visual-qa`, base `00f5d49`), Studio sur le Mac du propriétaire. Duels IA contre IA (Sasuke contre Minato, autopilote), 4 parties de 20 à 40 s. Outil : [OUTIL_VISUEL_F7](../../tools/OUTIL_VISUEL_F7.md).

Ces constats sont des **observations dans Studio**, pas des corrections. Chaque ligne dit à quelle discussion elle revient (RUNBOOK § 3 quater).

| # | Constat | Preuve | Pour |
|---|---|---|---|
| 1 | **Le jeu n'a aucune ombre.** `Lighting.GlobalShadows` vaut `false` dans la place construite (`build.py` ne fixe pas la propriété ; aucun script ne la met). Le soleil bas de `Client/WorldLook` (16 h 54) et ses « longues ombres » ne s'affichent donc jamais. | Lecture serveur et client : `GlobalShadows=false`. Captures « ombres OFF / ON ». | propriétaire (choix visuel), puis OUTILLEUR (`build.py`) |
| 2 | Avec les ombres allumées à 16 h 54, **le mur du stade met toute l'arène dans l'ombre** (image grise). Vers 14 h 30, l'arène est au soleil, les corps et les arbres portent leur ombre : l'image gagne du relief. Il faut choisir l'heure avec les ombres, pas seulement les allumer. | Captures F7 « Heure » et préréglages. | propriétaire, puis qui tient `WorldLook` |
| 3 | **Un cratère flotte à 33 studs dans le ciel**, collé au mur invisible du bord de l'arène (`Courtyard.Boundary`, transparence 1). Les marques au sol se posent aussi sur ce mur invisible. | Ligne « Marque au sol en l'air » ; capture de la caméra pointée sur `WorldMemory.Scar crater` (y = 33,2). | DEV (`Server/WorldReaction`) — **corrigé 08/11** (aucune marque sur une pièce de transparence ≥ 0,95 ; test `Embodiment`) ; reste côté client : `Effects.floorUnder` (ANIMATEUR) |
| 4 | **Des images d'effet échouent au premier chargement** : `74803998450943` (fumée), `126225681093802` (anneau), `79205682571618` (étincelle), `139199375333619` (sceau 飛雷神), message Roblox « Asset content representation is being generated ». L'effet est invisible les premières fois, puis l'image se charge. À vérifier en jeu publié (peut-être propre à Studio). | Lignes « Image ou maillage qui ne charge pas » puis statut `Success` quelques secondes plus tard. | ANIMATEUR |
| 5 | Jusqu'à **17 à 19 lumières d'effet allumées en même temps** pendant un duel (feu, chakra) : coût et image délavée. | Ligne « Trop de lumières d'effet en même temps ». | ANIMATEUR |
| 6 | `NinjaDuelFX.KatonCharge` reste en place 26 à 46 s (à 120 studs des combattants à la fin). | Ligne « Effet qui ne disparaît pas ». | ANIMATEUR |
| 7 | La caméra passe parfois derrière un tronc d'arbre et cache le joueur. | Capture à 14 h 30 ; l'outil le signale désormais (« Le décor cache le joueur »). | DEV (`Client/Camera`) — **corrigé 08/11** (la boîte invisible de l'arbre fait fondre son maillage ; fondu décor sur toute la hauteur ; tests `CameraFeel`) |

Faux positifs corrigés dans l'outil pendant ce passage : blocs de sol solides (`GroundBlock`) et bûche de substitution comptés comme « effet qui projette une ombre » ; marques posées sur un mur comptées « en l'air » ; lumières du décor du menu ; kunaï marqués de Minato pris pour des marques ; surbrillance `HitTint` réutilisée comptée « restée allumée » ; gel de Studio au lancement compté comme saccade.

Non vérifié : comportement à la manette, et performances sur une machine sans les autres places Studio ouvertes (le Mac avait quatre places ouvertes : les FPS mesurés, 15 à 60, ne sont pas représentatifs).
