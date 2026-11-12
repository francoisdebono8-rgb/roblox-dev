# Effets : les 3 constats de l'outil F7 (OUTILLEUR, 08/11)

Branche `work/anim-fx-fixes` depuis `claude/ninja-duel-2026-10-14` @ `00f5d49`. Constats 4 à 6 de [visuel-f7-2026-11-08/CONSTATS.md](../visuel-f7-2026-11-08/CONSTATS.md) (PR #55).

## 4. Images d'effet invisibles au premier chargement
- **Cause.** Les images en cause sont celles des éveils (lot 3, envoyées le 06/11). Roblox répond « Asset content representation is being generated » à la première demande, puis les sert quelques secondes plus tard.
- **Correction (`Client/AwakenFX`).**
  - Les images sont demandées au lancement du client (`ContentProvider:PreloadAsync`), pendant le menu et l'intro, et plus au premier éveil.
  - Celles qui échouent sont redemandées 3 s après.
  - Une image que Roblox ne sert toujours pas est remplacée par une texture intégrée, pour que l'effet ne sorte jamais vide. Un avertissement est écrit une fois.
- **Vérifié dans ND-DEV (édition, 08/11 vers 21 h).**
  - 7 images se chargent tout de suite : fumée, anneau, poussière, gerbe de feu, flamme, feuille, plume.
  - 4 restent en `Failure` après trois essais espacés de 2 s : étincelle `79205682571618`, sceau 飛雷神 `139199375333619`, éclair `100625761935181`, éclats `80574510604813`.
  - Cause probable : un refus ou une attente de modération côté Roblox. Pas vérifiable d'ici : la permission Open Cloud `asset:read` n'est pas accordée.
  - Ces quatre images passent sur les textures intégrées tant que Roblox ne les sert pas.
- **Jeu publié : non vérifié** (pas d'accès au jeu en ligne). Le préchargement et le remplacement valent aussi en ligne.

## 5. Trop de lumières d'effet (17 à 19)
- **`Client/LightBudgetFX` (nouveau), une ligne d'installation dans `Effects`.**
  - Il suit les lumières qui apparaissent sous `NinjaDuelFX`, `NinjaDuels` et `NinjaDuelBodies`. Le décor n'est pas touché : cour, scène du menu, habillage de l'arène.
  - Il en garde au plus 8 allumées : les plus fortes, les plus larges et les plus proches de la caméra. Les autres sont éteintes jusqu'à ce qu'une place se libère.
  - Une lumière d'effet n'a jamais d'ombre.
- **Règle pour les modules.** C'est la couche qui décide si une lumière est allumée ou éteinte. Pour éteindre une lumière, un module met sa luminosité à 0. `AwakenFX` le fait déjà.

## 6. `NinjaDuelFX.KatonCharge` qui restait 26 à 46 s
- **Correction (`Client/Effects`, la charge du Katon).** La boule de charge est détruite dès que la charge ou le jutsu finit, y compris quand il est interrompu, puisqu'on sort de l'état de lancement. Ses dernières flammes s'éteignent en 0,5 s. Avant, elle était seulement rendue transparente et restait jusqu'à la fin du duel.

## Point mineur (ombres des blocs de sol et de la bûche)
Pas traité : les ombres sont coupées dans le jeu aujourd'hui. À reprendre quand elles seront rallumées.

## Preuves
- Suite headless **46/46 PASS** (lune 0.10.4 avec un équivalent local de `FuzzyEq`) :
  - `LightBudget.spec`, nouveau : choix des 8 lumières, ombres coupées, les lumières en attente se rallument ;
  - `AwakenFX.spec` : test du préchargement et du remplacement.
- `test_build_isolation` OK.
- **Studio : pas rejoué en duel.** ND-FILM tournait sur le Mac, et le 08/11 après-midi un duel dans ND-DEV pendant un tournage avait déjà fait échouer les captures. À vérifier avec F7 une fois #55 et cette PR fusionnées : duel, F7, onglet Problèmes.
