# CM — DIRECTIVE PRIORITAIRE : TOURNER VRAIMENT, REJETER LES BUGS
05/11/2026. À lire après CM_THREE_SERIES_PRODUCTION_BIBLE_2026-11-05.md et CM_EXECUTION_RUNBOOK_SHOTS_AND_BUG_QA.md. **Le livrable est une vidéo convaincante, pas un script qui compile.** Aucune publication sans validation utilisateur.

## ÉTAPE 0 : tester les outils EXISTANTS en Studio, ne pas réécrire le jeu
Les outils cm_tools/NDCM_DIRECTED_TAKES.server.luau, cm_tools/NDCM_CAMERA_PRESETS.client.luau et cm_tools/video_qc.py ont été poussés, mais **pas encore certifiés en Studio**. Ouvrir le build Debug de la branche gameplay actuelle, relever son SHA. Play F5. Command Bar SERVER : runner SCENE=mark, LEAD=8. Command Bar CLIENT : caméra PRESET=wide. OBS : capture 10 s ; vérifier Minato, Neji, kunai, audio, fluidité, aucun HUD/Output. Tester shared.CM_CAMERA_STOP() et le retour normal de l'UI.

**Attention au vrai risque du kit :** la caméra suppose un bot nommé AIFighter sous le parent du Character ; vérifier son existence réelle. Dans teleport_counter, le runner demande la Rotation environ 0,075 s après l'Attack : cela NE PROUVE PAS qu'elle intercepte la frappe. Tester la vraie collision et la vraie fenêtre active avec logs + capture HUD. Une action « ok » peut ne pas toucher. Si les outils échouent, corriger UNIQUEMENT le kit Studio CM et prouver le nouveau fonctionnement ; ne pas modifier la release Roblox. Si le CM n'a pas accès à Studio, indiquer BLOCKED / NO STUDIO ACCESS avec la demande exacte.

## ÉTAPE 1 : prises du film Minato–Neji dans l'ORDRE DE TOURNAGE
Chaque plan = 2 prises d'abord, OBS démarré avant le compte à rebours, marge de 2 s avant/après action. Faire un crop 9:16 TEST dès le premier plan, pas à la fin. Les timecodes sont ceux du FILM MONTÉ.

| Capture | Temps final | Configuration Studio | Preuve visuelle obligatoire | Refus immédiat |
|---|---|---|---|---|
| B THROW | 1,15–3,70 s | SCENE=mark ; caméra wide | vrai geste du bras, projectile, Neji et trajectoire visibles | bras cassé, kunai surgit hors main |
| A HOOK | 0–1,15 s | SCENE=mark ; caméra low | marque réellement plantée, lisible sur téléphone | lame flottante ou invisible |
| C BAIT | 3,70–5,60 s | SCENE=mark ; caméra threequarter | Minato/Neji/marque dans un espace cohérent | géographie contradictoire |
| D WARP | 5,60–8,20 s | SCENE=preflight ; caméra threequarter | vraie disparition et réapparition FTG près de marque | pop dans mur, refus d'action |
| E STRIKE | 8,20–10,25 s | SCENE=preflight ; caméra impact | vraie frappe APRÈS FTG, contact réel | faux hit, animation cassée |
| F COUNTER | 10,25–13,10 s | SCENE=preflight ; caméra wide | Rotation active AU CONTACT, vraie défense | Rotation décorative hors timing |
| G PAYOFF | 13,10–15,20 s | suite d'une F réellement valide ; wide | les deux corps après le contre, VFX disparus | faux résultat, effets collés |
| H CTA | 15,20–17,50 s | vrai plan propre de l'arène | titre Ninja Duel et CTA exacts | build test présenté comme live |

**Fallback obligatoire :** si F n'est pas réalisable proprement, couper le film à 12–14 s après la téléportation avec « WOULD YOU HAVE SEEN IT? ». Ne pas fabriquer un faux contre. Les prises répétées doivent rester spatialement cohérentes.

## ÉTAPE 2 : GATE ANTI-BUG, AVANT TOUT MONTAGE
1. Nommer chaque prise SHOT_ANGLE_BUILD_TAKE.mp4 et conserver une preuve continue HUD ON de l'action réelle.
2. Exécuter python3 cm_tools/video_qc.py /chemin/prise.mp4. Ouvrir report.json et les planches sheet_*.jpg. Ce script détecte des candidats noirs/freezes, PAS les bugs de rig, de VFX, de contact ni de caméra.
3. Visionner la prise EN ENTIER à 1x, puis image par image autour du lancer, de l'atterrissage, du warp, de la frappe et du contre. Comparer la vidéo aux logs (act accepté ≠ hit réussi).
4. Inspecter le crop vertical sur téléphone, en muet puis avec son.
5. Marquer PASS / RETAKE / BLOCKED. **Seules les prises PASS entrent dans CapCut.** Refuser et retourner en Studio pour tout P0 : membre tordu, arme détachée, kunai qui flotte, VFX resté à l'ancien emplacement, téléport dans le mur, caméra qui traverse les personnages, freeze non intentionnel, coup qui ne touche pas mais présenté comme touché, Rotation hors timing, HUD debug, pop-up, écran noir, audio cassé. Ne JAMAIS masquer un P0 par flash, blur, zoom, shake ou SFX.
6. P1 = cadre 9:16 raté, silhouettes trop petites, kunai illisible, caméra molle, mauvaise continuité, texte sur l'action : reprendre ou recadrer AVANT export. P2 seulement = petites corrections de couleur, typo, son.

### Feuille de contrôle OBLIGATOIRE (remplir pour chaque shot)
| Shot | Nom prise | SHA/build | Logs action | QC noir/freeze | Vue 1x | Frame contact 0,25x | 9:16 téléphone | PASS/RETAKE/BLOCKED | Preuve |
|---|---|---|---|---|---|---|---|---|---|
| A | | | | | | | | | |
| B | | | | | | | | | |
| C | | | | | | | | | |
| D | | | | | | | | | |
| E | | | | | | | | | |
| F | | | | | | | | | |
| G | | | | | | | | | |
| H | | | | | | | | | |

## ÉTAPE 3 : pilotes des deux autres formats, aussi précis
**PRODIGY FILES / ITACHI, 16 s :** 0–1,4 portrait du vrai rig Studio, contrôler visage/yeux/mains/cheveux ; 1,4–3,5 révélation affiche ITACHI ; 3,5–5,3 READ/DECEIVE/PUNISH ; 5,3–8,1 vrai MirageCast avec SCENE=itachi_mirage, caméra threequarter, inspecter illusion et VFX ; 8,1–11 seconde action réellement jouée (Shadow Shuriken/Read) et contrôlée ; 11–13,7 retour affiche ; 13,7–16 WOULD YOU MAIN HIM? Ne pas vendre Blender/IA/concept comme gameplay ; refuser arme flottante, Sharingan qui clippe, illusion qui persiste, pose cassée.

**BUILDING THE IMPOSSIBLE / CAMERA, 30 s :** 0–2 vrai ancien rush caméra ratée ; 2–6 montrer le bug et l'entourer ; 6–10 vraie capture Studio et correction ; 10–15 BEFORE/AFTER avec builds et conditions comparables ; 15–23 vrai nouveau rush sans caméra qui décroche ; 23–29 « IS IT ACTUALLY BETTER? » ; 29–32 CTA et statut TEST/LIVE véridique. Pas de faux « before », pas de V39 TEST présentée comme publiée. Si aucun vieux rush : « WE'RE REWORKING OUR CAMERA » avec une démonstration honnête, sans comparaison inventée.

## ÉTAPE 4 : livrables, pas de progrès imaginaire
Pour chaque pilote : master MP4 1080x1920, cover, preuve HUD ON, projet CapCut, rapport PASS/RETAKE avec build SHA et anomalies, puis visionnage du master 1x muet, 1x sonore, 0,25x aux contacts. Statut READY FOR USER REVIEW uniquement si tous les plans ont passé les gates. Si impossible, BLOCKED avec capture/erreur exacte et plan B. **Ne pas poster, déployer ni acheter sans accord.**
