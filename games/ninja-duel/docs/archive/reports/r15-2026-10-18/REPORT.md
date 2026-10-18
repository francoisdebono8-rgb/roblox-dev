# R15 — réception et mouvement mural — 18 octobre 2026

Demande directe utilisateur : améliorer visuellement les mouvements/animations R15 en jeu (combat, mouvement, mur), choix de méthode laissé à Codex, sans casser le jeu. Cette autorisation ponctuelle ouvre cette passe client ; elle ne remplace pas Claude comme implémenteur principal du roster.

Base Git : `1792c40`. Deux fichiers client modifiés, trois régressions d’animation ajoutées ; aucune modification serveur, définition d’attaque, graphe, hitbox, statistique ou règle de déplacement. Les trois places sont reconstruites depuis ces sources. Pas de nouveau framework, asset importé ni dépendance.

## Changements retenus

- Réception isolée par acteur : le timer global `landingUntil` faisait accroupir le joueur quand l’adversaire se posait. Horloge par human/bot, annulée au nouveau saut et vidée au changement d’epoch.
- Réception décomposée : charge rapide, puis relâchement progressif des hanches avant retour en locomotion. En course, la foulée reste active ; cela améliore aussi les retours au sol après un échange aérien, sans changer la fenêtre d’action serveur.
- Mur : la cadence suit le déplacement réellement dessiné, avec genoux/chevilles, coudes et léger contre-mouvement du torse. Le déplacement mural serveur impose des positions et annule la vitesse d’assemblage : la présentation lit maintenant aussi la composante Y du suivi visuel pendant wall. À vitesse nulle, le cycle ne pédale plus. La trajectoire, les durées, le rebond et les règles de contact restent ceux du serveur.

## Validation technique

Chacune des trois reconstructions : 28 suites /511 cas PASS (Animation17, dont trois nouveaux). Neuf tests Python d’isolation PASS ; frontières409 fichiers PASS ; contrôle documentaire PASS. Hash de chaque source et du fichier artefact comparé au manifest : PASS pour les trois variantes. Les nouveaux tests vérifient l’indépendance des deux acteurs/expiry/takeoff/reset, le relâchement de la compression et l’arrêt du cycle mural à vitesse nulle.

- NinjaDuel : SHA256 `e52317fc21e6bf57ce49d92a595ea88f4a9725e752bc802557a8109373df176e`, fingerprint `cc28f26fd0343160e0cb892fd682c545139990c8dc0e0e49290de410dafab762`.
- NinjaDuel-Debug : SHA256 `cc2e33d505d55f5cb89908819153896c0ea48beda8f07d6ddbbe7ef6958d295d`, fingerprint `ea3b2dc525073dbc3167811a752c7a6333ab765dcafa74224e1293592dfe765b`.
- NinjaDuel-QA : SHA256 `203cab3694a905476a86758b7d9177c43cc60dd0d1a390cbce3fe2d5270d985b`, fingerprint `96030e60be149eec2963a1742161c29a7c5640964258e396cecdcf493d0a1ca5`.

## Studio natif et portée des preuves

Préparation dans `ND-Debug-new3.rbxlx` : cette session contenait des ajouts Wave4 de Claude non présents au HEAD distant. Les deux patches ont été appliqués par contexte, puis intégralement retirés dans cette session avant livraison. Vérification finale : Presentation15027octets, Motion153565octets, notre helper landing absent, hook Wave4Motion toujours présent. Aucun autre module de ce brouillon modifié, aucune sauvegarde écrasant son fichier. Les anciens brouillons ne servent pas de preuve du build final.

Build final ouvert séparément via le binaire Studio et son fichier local, session `NinjaDuel-Debug.rbxlx`, fingerprint Debug ci-dessus relu dans le DataModel serveur. Les essais suivants ont été faits sur ce build final :

1. Joueur immobile, saut adverse accepté, observation de181 frames : bassin Root Y entre -0.495916 et -0.381414 (amplitude0.114502stud). Lors de la préparation avant patch, une sonde analogue donnait -1.046188 à -0.390879 (amplitude0.655310) ; cette première mesure comportait une mise en place initiale et provenait du brouillon, donc ce n’est pas un benchmark strict avant/après sur le même artefact. L’indépendance est en plus vérifiée par test déterministe.
2. Vraies touches W tenu350ms, Space, relâchement W : état serveur airborne=true, Y14.0404, vitesse horizontale environ19.5 ; réception ensuite avant le test suivant.
3. Vrais clics souris : trois Light espacés230ms, Light1/2/3 et Hit chacun +1/+3hits, dégâts30.84 sur Itachi (145→114.16), retour Neutral. [États bruts](NATIVE_INPUTS.json).
4. Vrai moteur mural, mise en place Debug devant le mur de l’enceinte : wall=true, montée jusqu’à Y13.39 après0.45s. Boucle de mise en situation pour observer les poses et capturer [l’image finale](WALL_FINAL.png), HUD masqué. Les placements sont des outils d’observation, pas présentés comme un parcours joueur continu. Animation observée dans Studio ; image isolée seule insuffisante pour conclure au feel.

Les timers de caméra et HUD des essais sont temporaires et ne figurent dans aucun runtime livré. La session finale revient au menu normal après QA. Aucun nouveau PASS manette, latence online ou LIVE_ROBLOX. Pas de revendication de nouvelle chorégraphie complète des vingt personnages ni de validation de tous les matchups. Le rendu mural reste procédural, sans verrouillage IK des pieds sur chaque pierre/relief ; ce travail n’ajoute pas un nouveau système de parkour.

## Reprise Claude

MOV-005 reste IN_PROGRESS : cette passe ferme trois défauts/précisions de présentation, pas tous ses critères. Préserver ces modifications en fusionnant les hooks Wave4 du brouillon. Les bibles DEC-026 restent la cible des futures identités ; aucune réécriture de kits ici. Les réserves M7 et S20 de l’audit précédent ne sont pas corrigées par cette passe. Le précédent artefact QA ancien a été reconstruit et concorde maintenant avec ces sources.
