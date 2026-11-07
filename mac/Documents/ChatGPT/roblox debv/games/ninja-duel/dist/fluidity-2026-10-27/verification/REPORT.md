# Ninja Duel — fluidité et commandes, 27 octobre 2026

Demande directe : corriger la version jouable, observer 1–5 combats IA, puis traiter les échanges aériens incohérents, les touches qui perturbent une action, les projections involontaires en approche, les raccords et les lumières. Base `04ac9bf31cbe50ea8a4a6c8eb1a361872ac2baed`, branche `codex/ninja-playable-fluidity-20261027`. Travail isolé du checkout principal et de Forge.

## Corrections

- Une approche marchée n'est plus remplacée implicitement par une frappe de course, un genou projetant ou une finition contre le mur. Les variantes latérales sans projection restent possibles. Le deuxième appui dans la marge après récupération avance à Light2 au lieu de recommencer une ouverture contextuelle. Light3, les lourds et les approches sprintées conservent leur rôle.
- Les branches directionnelles demandent un nouvel input après le début de la chaîne. Les axes physiques sont envoyés séparément du déplacement relatif à la caméra, puis validés côté serveur. Une rotation de caméra avec W maintenu ne devient plus une demande de Launcher/LionKick. Les buffers conservent cette distinction et l'IA garde son intention explicite.
- Une frappe en l'air ne suspend plus le saut en attirant son auteur vers un adversaire qui saute librement. L'assistance ne suit qu'une victime effectivement lancée/jonglée, encore vivante et aérienne. Choc simultané, interruption, garde et esquive libèrent les anciens temps de suspension.
- Déplacements discrets envoyés dès l'appui/relâchement ; saut en fin de récupération réellement transmis au moteur ; relâchement du saut idempotent. Les relâchements de garde/saut/jutsu passent même si le budget d'appuis est saturé. Une touche de jutsu refusée ne remplace plus la charge tenue ; relâcher une autre touche ne termine plus cette charge. Le coût dépend du temps réel, indépendamment de la fréquence serveur.
- Corps, pose, projectile et impact partagent une horloge visuelle retardée de 60 ms. Objets lancés depuis la main visible ; volées suivant les sorties réelles ; un projectile terminé ne réapparaît plus sur un ancien snapshot. Nettoyage des effets attachés aux changements de duel et interruptions ; couches d'effets avancées une seule fois par frame.
- Lumières ordinaires limitées à 0,65/5 studs ; fortes à 1,8/9 studs. Pas de lumière de coup pour whiff/esquive/réception/flow. Teinte des victimes atténuée ; pulsation continue du Chidori et des infusions. Le croissant de lame exige un contact slash : les poings ne dessinent plus le même coup de sabre.

Clips Blender et gestes des familles conservés. Cette passe corrige leur déclenchement et leur lisibilité ; elle n'ajoute pas une bibliothèque d'animations ni ne certifie la variété des vingt personnages.

## Tests et artefacts

Normal, Debug et QA : **34 suites / 610 cas PASS chacun**, sourceEquality PASS. Neuf tests d'isolation PASS ; architecture PASS (452 fichiers) ; `git diff --check` PASS. Les gates natives/globales des manifests restent PENDING : une vérification ciblée n'est pas la gate complète des vingt kits.

Movement, CombatFeel et Embodiment étaient absentes du gate de build : désormais incluses avec Fluidity, EffectsContinuity, PresentationContinuity et Input étendue. Fixtures corrigées : vols de Roster avec identifiants uniques ; Roster20 ne transmet plus le second retour de `slot` (table de technique) comme vecteur de déplacement. Aucun verdict de mécanique propre aux personnages supprimé pour faire passer les suites.

| Artefact | SHA-256 |
|---|---|
| NinjaDuel.rbxlx | `0b23b9ff90656e2dbc8ad53efe16215e16e21575ef0cfa86fa31a6278d8c95a3` |
| NinjaDuel-Debug.rbxlx | `ce1e7695d9152c168bc0059c4069af43e24001e58d35dbaef20fe554e20c974b` |
| NinjaDuel-QA.rbxlx | `816fd0ae117cfcc3fbae590eac0075ff767af15758adf393b722ced1e73b1312` |

## Studio

Cinq sessions de combat IA lancées : trois baselines Sasuke–Minato (une aux entrées espacées, deux avec autopilot), une Sasuke–Minato après premières corrections mêlant clavier/souris et autopilot, puis Lee–Zabuza avec autopilot. Quatrième résultat dans `match4.json` : défaite 0–2, adversaire 39,276 HP. Cinquième observée en combat ; après interruption du travail, l'état Result disponible avait des événements/paires différents possibles : aucun score final Lee–Zabuza ne lui est attribué. Les derniers ajustements approche/lumière sont vérifiés ensuite sur des séquences ciblées ; ce ne sont pas cinq matchs manuels sur l'artefact final.

Debug final : 112 scripts comparés par longueur et Adler32 aux sources exactes, aucune différence (`source-verification.json`). Fingerprint `790f1bc0beb8686190f239da801dccd9204f0c28a6339565fa21105884c1f83c`. Assets inchangés depuis la base. Instance ND-Blender5 : `61d147c0-82f5-404d-9a9e-321b8cc45cd9`.

- **Clavier/souris, W maintenu et trois frappes** : premier essai encore LionKick à cause de la caméra. Après séparation des axes physiques : VaultKick latéral (HitStun), Light2, Light3 ; aucune branche de lancement. Les trois requêtes gardent `steering=(0,0,1)` malgré des directions mondiales différentes. Trois lumières à 0,65, portée 5, sans ombres ; zéro erreur. Preuves `final_approach_client.json`, `final_approach_server.json`, `native-approach.png` (capture après séquence avec overlay QA, pas une preuve vidéo du ressenti).
- **Second appui tardif** : dummy sans tutoriel, Light1 confirmé, retour Neutral avec combo=1, second Attack → Light2. API diagnostic utilisant les vraies requêtes combat. Preuve `final_native_cases.json`.
- **Deux sauts et frappes simultanées** : un Clash chacun et airHold=0 sur les 35 échantillons finaux ; montée, sommet et chute continus (joueur environ 13,85 → 21,00 → 3 studs). La baseline perdait brutalement sa vitesse verticale (52,62 → −2,33) ; première correction conservait 43,87 après contact. Preuves `air_before.json`, `air_after.json`, `final_native_cases.json`.
- **Jutsu superposés aux vraies touches** : Technique1 acceptée, Technique2 refusée, release slot2 conserve FireBloom, release slot1 termine sa charge ; transitions WASD immédiates. `physical_inputs.json`, `command_results.json` : version intermédiaire, mécanisme inchangé dans le final et tests rejoués.
- Derniers observateurs serveur/client et clientlog : zéro erreur de jeu. Un ancien observateur temporaire avait traité un payload table comme une chaîne ; retiré avant les validations finales. C'était une erreur d'instrumentation, pas du runtime livré.

## Limites

Studio souvent à 15 FPS en arrière-plan (une mesure 23,3) : aucun gain de FPS ni objectif 60 FPS revendiqué. Pas de session deux clients avec latence, de manette physique, d'acceptation humaine du ressenti ou de revue animée exhaustive des vingt kits. Light3 projette toujours ; une variante latérale légère peut être un coup de pied. Le critère corrigé est la conversion involontaire de l'approche en lancement.

TECHNICAL PASS ; NATIVE ciblé PASS ; HUMAN_FEEL et LIVE/ONLINE non clôturés. Rejouer la gate native complète et la revue de ressenti avant de clôturer le bloc général de continuité visuelle.
