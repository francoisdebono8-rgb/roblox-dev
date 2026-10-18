# R15 commun — appuis, pas latéraux et sortie de course — 18 octobre 2026

Demande directe utilisateur : « fais une passe sur les mouvements communs R15 ». Base distante Claude `b445df5fb4a369f1620e38b69dcc3cda8695a56f`, travail isolé sur `codex/ninja-r15-common-pass`. Autorisation client ponctuelle ; pas de remplacement du travail roster de Claude.

## Corrections

- Le contre-mouvement des bras/bassin suit maintenant l’écartement des pieds projeté dans la direction de déplacement. Avant, seule la profondeur Z était mesurée : un strafe pur donnait zéro mouvement alterné du haut du corps. Gardes et bras propres aux familles restent prioritaires.
- Course → marche/arrêt/attaque : le pied en vol repart de sa position réellement dessinée, hauteur comprise. L’ancien code supprimait la hauteur de vol et pouvait reprendre un ancien timer de marche. La pose descend désormais progressivement en terminant le pas.
- Reset dur : appuis, cycle de course, accélération et mémoire de transition sont vidés avec les poses. Les ancrages d’une vie précédente ne se réutilisent plus.
- Équilibre latéral : inclinaison permanente réduite (Minato pur strafe : 18° → 8°, hors accélération), contre-inclinaison du torse 5° → 3°, réaction latérale à l’accélération plafonnée à 6° au lieu de 10°. Réglage après observation native rapprochée ; pas une nouvelle règle de déplacement.

Un module client modifié. Aucun serveur, hitbox, timing d’attaque, dégât, graphe, vitesse ou jutsu modifié ; les clips Wave1/Wave3/Wave4 sont préservés. Ce travail ne prétend pas corriger toutes les chorégraphies de jambes des vingt personnages.

## Preuves

Trois nouvelles régressions d’animation : alternance corporelle en strafe, continuité du pied en sortie de course puis repos, reset sans ancien appui. Animation : 20 PASS, suite complète : 28 suites PASS pour chacune des trois variantes. Neuf tests d’isolation Python PASS ; checker architecture PASS (416 fichiers).

Comparaison déterministe dans Roblox Studio, mêmes scénarios et vraie arithmétique CFrame/Vector3, modules avant/après isolés :

| Mesure | Avant | Après |
|---|---:|---:|
| Signal alterné de strafe, min/max | 0 / 0 | -1 / 1 |
| Discontinuité du pied à la sortie de course, dt=0 | 0,8716 stud | 0 |
| Erreur de pose des pieds après reset | 1,1478 stud | ~0 (9,5e-8) |

[NATIVE.json](NATIVE.json) contient les retours bruts. Ce sont des sondes de présentation, pas un duel humain. Le module baseline temporaire a été retiré sans enregistrement dans le build.

Parcours réel clavier/souris sur Debug avant le dernier réglage de roulis : A/D, course, saut et réception ; trace de 716 frames avec sommet Y=13,707 et retour au sol Y≈3. Trois clics espacés de 230 ms : Light1/2/3 et Hit chacun +1, 30,84 dégâts sur Itachi, retour Neutral. Sélection/mise en place via DevHooks, donc pas revendiqué comme parcours menu continu. Caméra de profil/front et masquage HUD sont uniquement des instruments de QA.

Le dernier réglage de roulis a passé Animation20 et les trois builds complets. Copie exacte du Debug final ouverte séparément dans `ND-R15Common-Final.rbxlx`, SHA256 et fingerprint `55c5eec4…6d4f5` vérifiés ; aucun module baseline. Vraies touches A/D/S/W puis saut/réception, suivies de trois clics espacés de230ms : trois contacts Light1/2/3,30,84dégâts, retour Neutral. Trace finale73frames, apexY14,491 ; cadence de capture basse en arrière-plan, aucun benchmark de fluidité déduit. [Retours finaux](FINAL_NATIVE.json). Observation du strafe via mise en situation DevHooks et [capture interne finale](STRAFE_FINAL.png), HUD masqué et caméra d’analyse. Ce parcours ciblé ne valide ni les vingt identités ni une session PvP. Aucun PASS ressenti humain, manette, réseau ou LIVE_ROBLOX.

## Artefacts finaux

- `NinjaDuel-Debug.rbxlx` : SHA256 `72bc31a9b43cb6f97eef9fe5b85e1c805c5e9327c5f9468622c73eb21614be9c`, fingerprint `55c5eec4b25178ce004cebdf632825ab918166d27ce5275fb0ba591e0ac6d4f5`.
- `NinjaDuel-QA.rbxlx` : SHA256 `6ebcf3de2e7304da439d05a254eaa8010fa6fe8ff34c65fb3f979fe8152d902a`, fingerprint `cf87b23481df3b2ff0ead67db2872a8c0a3ef67424c8af3c621af051ac63cfe0`.
- `NinjaDuel.rbxlx` : SHA256 `ae3701bdfc39165c0221f8ae12838a9d169280bb108f8d87bd4048e301a26f38`, fingerprint `45f4dc3f045afde0ccec32614b31805ecf2ea3b9ffcdee99b2c63fabbae0e700`.

Sources/artefacts vérifiés contre chaque manifest : PASS. Les statuts nativeQA/visualAcceptance des manifests restent PENDING ; aucune acceptation humaine déduite des tests.

## Reprise

MOV-001/002/003/004 restent PARTIAL et MOV-005 reste IN_PROGRESS. Intégrer ce petit changement client sans remplacer les gestes de personnages ; les lots DEC-026 conservent leurs gates propres. Vérifier aux vraies touches les déplacements diagonaux, freinages, changements d’angle et sorties de course en attaque sur le build intégré.
