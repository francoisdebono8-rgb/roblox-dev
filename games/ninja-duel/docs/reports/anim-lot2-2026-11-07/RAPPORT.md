# Lot 2 animation — la course ninja par personnage (07/11 nuit)

Branche `work/anim-lot2-locomotion` (depuis `claude/ninja-duel-2026-10-14` @ `d3ad45c`). Fichiers ANIMATEUR seulement : `src/Client/AuthoredClips*.luau` (72 clips réécrits), `tools/blender/loco_v2.py` (nouveau), `tests/Locomotion.spec.luau` (seuils resserrés). **Le moteur (`VelmoraMotionEngine`, DEV) n'est pas touché.**

## Le défaut visé

Les 8 persos couraient avec la même capture Mixamo (écart 1–2° avec Sasuke) : un jogging humain qui reste au sol presque tout le cycle, dessiné pour ~8 studs/s alors que le jeu court à 19 et sprinte à 45. Le moteur le jouait 2,3× (course) à 3,8× (sprint) plus vite que dessiné, et le pied posé glissait.

## Ce qui change (par clip, dans `loco_v2.py`)

1. **Allure du perso** (`GAIT`) : amplitude des jambes et genoux, torsion du buste, bras, coudes, buste penché, tête, rebond. Naruto ample et bondissant, Kakashi bras bas économe (coude plié), Minato penché et court, Itachi buste droit sans balancier, Lee jambes hautes et poussée, Neji droit, Gaara inchangé (le sable le porte).
2. **Le bond ninja** (`BOUND`) : appui raccourci, vol allongé, arc balistique de la hanche pendant le vol. Ajusté par perso sous trois limites : vitesse des jambes ≤ max(2000°/s, celle du clip d'origine), appui ≥ 0,05 s, et **cadence gardée au plafond 1,8× du moteur** pour que le moteur continue à tenir le pied posé (sans ça, mesuré : la glisse remontait à 20–95 %).
3. Rééchantillonnage à 60 i/s, pieds recalés au sol.
4. Directions L/R/B : moitié de l'effet ; marches : 60 % sans bond.

## Mesures headless (moteur réel, `tests/Locomotion.spec.luau`)

Glisse du pied posé, en % de la vitesse du corps :

| Perso | Course avant → après | Sprint avant → après |
|---|---|---|
| Sasuke | 12 → 8 | 29 → 6 |
| Naruto | 12 → 6 | 16 → 7 |
| Gaara | 35 → 5 | 11 → 12 |
| Lee | 10 → 6 | 16 → 5 |
| Neji | 12 → 2 | 29 → 9 |
| Itachi | 12 → 2 | 29 → 8 |
| Kakashi | 12 → 3 | 29 → 9 |
| Minato | 10 → 8 | 35 → 6 |
| **Moyenne** | **~15 → ~5** | **~24 → ~8** |

Cadence jouée / dessinée (`report.txt`) : course ×2,3 → ×1,9–2,5, sprint ×3,8 → ×2,4–2,8. Images de jambes au plafond de vitesse : ≤ 17 % (Gaara sprint), le reste ≤ 11 %.

Tests : suite headless **44/44 PASS** (lune 0.10.4 avec un équivalent local de `CFrame:FuzzyEq` ; le dépôt n'est pas modifié pour ça), `test_build_isolation` 11/11. `Locomotion` resserré : course < 20 % par perso et < 10 % en moyenne, sprint < 20 %.

Planches avant/après (profil, 8 images par cycle, course et sprint) : `planches/*.png`.

## Pas prouvé

- **Rien vu dans Studio** ni filmé : ce lot est entièrement hors Studio. À faire dans ND-DEV : course et sprint des 8 persos, sonde des chevilles à 60 i/s, vidéo avant/après.
- Ressemblance avec Sasuke encore modeste (hors Gaara et Lee : course 1–5° → 4–7°, sprint 0–2° → 2–3°) : la base reste la même capture ; une vraie différence demande des courses capturées ou animées pose par pose par perso.
- Itachi (course) et Minato (sprint) gardent un appui non raccourci (aucune valeur ne passait les limites).
