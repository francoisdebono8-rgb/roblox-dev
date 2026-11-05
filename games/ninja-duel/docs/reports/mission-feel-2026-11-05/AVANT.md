# Mission FEEL (issue #44) — rapport AVANT, passe A

5 novembre 2026, 19:05–19:33 (heure de Paris). Rédigé par Claude après les prises Studio.

## Ce qui a été mesuré

| Point | Valeur |
|---|---|
| Code de gameplay | `8d102be` (baseline de la mission). `02b3381` y ajoute seulement l'outillage : le canal de commandes dev (Studio uniquement), `tools/feel/` et un fichier de tests. |
| Build chargé | ND-Test-travail, build Debug. Hash `0167bd60…dc293f3` (console Studio). |
| Studio | 0.746.0.7461264, macOS, instance `558350fe` (copie de travail en lecture seule) |
| Contrôles | manette simulée par le plugin MCP de Studio (□ △ ○ × R1 L2 R3) ; clavier (ZQSD physiques sur AZERTY) |
| Sources | journal serveur `DevFlight` (chaque appui, son verdict, sa raison, les gels), enregistreur client `tools/feel/recorder.client.luau` (états, caméra image par image, FPS), simulation sans rendu `tools/feel/novice.luau` |

## État des preuves

| Preuve | État |
|---|---|
| NATIVE_STUDIO (journaux) | **obtenue** : 2 prises, 3 scènes |
| Vidéo brute | **échec**. Voir « Limites du banc de test » : OBS a ignoré 99,2 % des images à la prise 1 et 89,3 % à la prise 2. La vidéo n'a pas de valeur de mouvement. Les images fixes ci-dessous restent valables pour une situation statique. |
| HUMAN_VISUAL_FEEL | **PENDING** : il faut une partie à la vraie manette |
| LIVE_ROBLOX | non testé (et distinct de NATIVE_STUDIO) |

Scènes jouées :
- **S1, corps en mouvement** : Neji ; course, angle, esquive, saut, mur, rebond, attaque aérienne, atterrissage, course.
- **S2, novice Neji contre l'IA** : niveau facile seulement. Le niveau normal ne peut pas se régler depuis l'outil.
- **S3a, Heavy chakra de Neji.**
- **S3b, Minato** : kunai marqué, Dieu du Tonnerre Volant (FTG), frappe d'arrivée.

## Les 5 plus gros trous dans le plaisir

Fréquence × gravité. « Entrée → moteur → rendu » indique où la chaîne casse.

| # | Ressenti du joueur | Preuve (timecode / log) | Entrée → moteur → rendu | Cause probable | Classement |
|---|---|---|---|---|---|
| 1 | **Dos au mur, je ne me vois plus.** La caméra s'enfonce dans le mur ou dans les buissons et le perso disparaît du cadre. | Prise 2, S1 : le WALL RUN démarre à +7,26 s. De +7,0 s à +12 s, le joueur est hors cadre sur **100 % des images**, caméra à 9 studs. Prise 1, vidéo 1:12–2:08 : caméra derrière un buisson contre le mur rouge, les deux corps à moitié cachés (`media/still_camera_mur_buisson_1m40.jpg`). | entrée OK → moteur OK (course murale engagée) → **rendu KO** | Le cadrage verrouillé place la caméra derrière le joueur, sur l'axe adversaire → joueur. Quand le joueur est dos au mur, le bras de caméra heurte le mur, raccourcit (9 studs) et garde sa visée : le joueur sort du champ. Les buissons de bordure ne sont ni écartés ni rendus transparents. | ILLISIBLE À METTRE EN VALEUR (la course murale est un bon moment) |
| 2 | **Le Heavy chakra de Neji envoie l'adversaire hors de l'écran.** | Sans rendu : 2 coups puis L2+△ → lancer chakra à **66 studs** (Heavy normal : 20,6), **2,44 s** en l'air. Studio, prise 1 (2:37–2:40) : le bot monte à y 67,5, repère « VACUUM PALM », adversaire hors cadre **109 images sur 540 (≈1,8 s)**. | entrée OK → moteur OK → **rendu KO** (la caméra ne suit pas l'extrême vertical) | La charge chakra du Launcher empile l'impulsion Vacuum ×1,5 ×1,2. Le cadrage « Launcher » (15,5 / 68°) n'élargit pas pour une hauteur pareille. | AMUSANT À CONSERVER **et** ILLISIBLE. À cadrer, pas à réduire par réflexe. Reste à vérifier si les 2,4 s de vol cassent le rythme du duel (test de riposte en passe C). |
| 3 | **J'appuie et rien ne se passe, sans savoir pourquoi.** | Prise 1 : 47 appuis d'action → 8 refus par les règles (Reacting ×4, Committed ×3, Cooldown ×1), 2 refus par la fenêtre anti-triche (GATE, âges 301 et 473 ms), 5 relâchements de sceau perdus (sans effet). Prise 2 : Esquive puis Attaque refusées (GATE, âges 402 et 403 ms), juste après un à-coup client de **379 ms** déclenché par l'appui d'esquive. Novice simulé : **≈30 %** des appuis refusés, surtout Committed. | entrée OK → **moteur refuse** → rendu muet ou prédiction annulée | Deux causes : (a) les règles d'engagement (pendant son coup, pendant un coup reçu) refusent sans retour lisible au moment de l'appui ; (b) la fenêtre de fraîcheur de l'anti-triche (`History` 0,2 + `TimestampWindow` 0,1 = **300 ms**) jette en silence un appui arrivé en retard. Un à-coup ou un pic de ping mange l'esquive. | À ENCADRER (retour discret) ; la fenêtre de 300 ms est à revoir |
| 4 | **Mon saut est un petit sautillement.** | Prise 1 : PadJump puis JumpOff 0,12 à 0,30 s plus tard (journal serveur 211,68 → 211,80 ; 101,12 → 101,42). Un appui court sur × donne un saut minuscule ; il faut tenir 250–300 ms pour un vrai saut. | entrée OK → moteur coupe le saut → rendu faible | La hauteur dépend de la durée d'appui, sans saut minimum assez haut pour un appui bref (cas typique du novice). | ILLISIBLE À METTRE EN VALEUR |
| 5 | **Le décor de bordure me bloque ou m'avale.** | Prise 1, S1 : après course et saut, le corps reste posé sur un élément de décor à y 14,8 pendant 1,7 s. Prise 2 : gel de 0,39 s contre le mur (bloqueurs « Boundary, Boundary »). Prise 1 : les corps entrent dans les buissons (`media/still_course_vers_decor_1m12.jpg`, `still_camera_mur_buisson_1m40.jpg`). Balayage de l'arène : décor collidable dans 5 des 36 secteurs de 10° près du mur. | entrée OK → moteur (collision) → rendu caché | Décor de bordure placé sur les trajectoires de course murale ; certains éléments sont solides, d'autres seulement opaques. | CASSE LE DUEL À ENCADRER (une course murale ne devrait pas finir sur un buisson) |

### Points plus petits, notés pour la passe D

- **Minato.** Après un kunai qui touche, le repère dit « SEAL ON TARGET • 2 TO FOLLOW ». La technique 2 est Lightning Strike, qui n'utilise pas le sceau. Le sceau sert au FTG, technique 3 (R1+○). L'enseignement est ambigu.
- **Minato.** Un second FTG moins de 6 s après le premier donne « COOLDOWN ». Le □ suivant devient AngleStep (direction tenue) : une action non voulue après un refus.
- **Gels.** 4 gels de 0,5 à 1,0 s (stick tenu, vitesse 0, état Neutral). 2 suivent un déplacement de l'outil dev (artefact). 2 en combat restent inexpliqués ; cause non établie.
- **Écran clavier AZERTY.** Vérifié, pas de défaut : `GetStringForKeyCode` renvoie Q→A, Z→W, W→Z, et les textes passent par `Controls.useLayout`.

## Les interactions, classées pour la passe C

| Interaction | Classement | Ce qu'on a vu |
|---|---|---|
| Neji : 2 coups puis Heavy chakra (lancer Vacuum) | AMUSANT À CONSERVER + ILLISIBLE | Spectaculaire, mais l'adversaire sort du cadre ~1,8 s (défaut 2) |
| Minato : kunai marqué → sceau → FTG → frappe d'arrivée (FlashStrike) → Light2 → Light4 | AMUSANT À CONSERVER | Prise 1, 3:08–3:13 : la chaîne passe, la caméra garde l'adversaire sur 566 images sur 566. HP du bot : 126 → 121 → 115 → 113. |
| Course murale (WALL RUN) | AMUSANT, mais ILLISIBLE au mur | Le moteur l'engage. L'entrée est tardive dans le script, et la caméra perd le joueur (défaut 1). |
| Attaque aérienne (Air1) qui plonge ~10 studs vers l'adversaire | AMUSANT À CONSERVER (à confirmer à l'œil) | Fonce bien sur la cible ; lisibilité non vérifiable sans vidéo valable |
| Refus pendant son propre coup / pendant un coup reçu | À ENCADRER | Fréquent chez le novice (défaut 3) |

## Limites du banc de test (à lire avant de comparer)

1. **Capture vidéo.** OBS (profil « Sans nom ») enregistrait en 2940×1912, 60 i/s, qualité « indiscernable » : **99,2 % des images ignorées** (« retard d'encodage »). J'ai refait une prise avec un profil à part, « ND-FEEL » (1470×956, H.264 matériel, haute qualité) : **89,3 % ignorées**. Le Mac est saturé (plusieurs Studio ouverts, dont ceux d'une autre session, plus OBS). Le profil « Sans nom » n'a pas été modifié et OBS est revenu dessus.
2. **Retards d'entrée du banc.** Sur la machine saturée, les appuis arrivaient au serveur avec 1 à 6 s de retard, au clavier réel comme avec le plugin. Ces âges-là ne sont **pas** comptés comme défauts du jeu. Seuls les âges de 300 à 470 ms, observés sur une machine moins chargée, sont retenus (défaut 3). Le défaut de conception reste : un refus pour fraîcheur est silencieux.
3. **Studio en arrière-plan.** Quand Studio n'est pas l'application au premier plan, il tombe à ~16 i/s. Au premier plan : 58,5 i/s. La prise 1 moyenne 27,7 i/s, ce qui pollue les mesures de FPS.
4. **Niveau de l'IA.** Le niveau normal ne se règle pas depuis l'outil dev. Il faudrait passer par l'écran de sélection ou ajouter une commande.

## Réponse provisoire à la question finale

Pas encore tranchable. Une partie à la vraie manette manque, et les deux plus gros trous (caméra dos au mur, lancer hors cadre) touchent précisément « courir, esquiver, une technique impressionnante ». Avec ces deux trous, un novice perd son perso de vue au moment où il fait la chose la plus spectaculaire.

## Suite (tranche verticale B+C+D, Neji et Minato, Lee en témoin)

1. Caméra : mode « acculé » (dos au mur ou au décor, la caméra passe sur le côté ou en hauteur) ; le décor de bordure ne bloque plus la vue.
2. Caméra : extrêmes verticaux (lancer chakra, téléportation) ; on élargit pour garder les deux corps, sans cinématique forcée.
3. Refus : retour discret au moment de l'appui ; fenêtre de fraîcheur revue (accepter en retard plutôt que jeter, ou au moins le signaler).
4. Saut : hauteur minimum lisible pour un appui court.
5. Décor : retirer les collisions de bordure sur les lignes de course murale.

Données brutes : `logs/AVANT_journaux.md`. Vidéos et planches : `~/Documents/NinjaDuelMedia/FEEL/AVANT/` sur le Mac (prise 1) et `FEEL/_junk/` (prise 2).
