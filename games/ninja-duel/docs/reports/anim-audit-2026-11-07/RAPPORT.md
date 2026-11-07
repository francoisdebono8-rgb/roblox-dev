# Audit animation et lot 1 — 7 novembre 2026

Demande (07/11, 15 h 46) : « Lance l'audit et la première passe d'amélioration dès maintenant », grande passe d'amélioration des animations, méthode obligatoire (auditer, filmer, problèmes transversaux, premier lot, PR, rejouer, comparer).

## État des preuves

| Preuve | État |
|---|---|
| Base | `claude/ninja-duel-2026-10-14` @ `9f235b2` ; place `ND-DEV` (`debug @ 0e579bf`, RUNTIME `aec22310`) |
| Mesures Studio (ND-DEV, avant) | **obtenues** : duel IA Naruto–Kakashi 47 s ; parcours scriptés de déplacement (Naruto, Lee, Kakashi) ; parcours de combat Kakashi→Naruto |
| Mesures sur les données des clips | **obtenues** (les 714 clips Blender des 8 persos de la bêta) |
| Tests headless (lot 1) | **obtenus** : nouvelle suite `Locomotion` (3 PASS, échoue sur l'ancien moteur) ; `Animation` 32/32 avant et après (lancée avec un équivalent de `CFrame:FuzzyEq`, absent de lune 0.10.4) ; `test_build_isolation` 11/11 |
| Studio après (lot 1) | **partiel** : poussé à chaud dans ND-DEV (non enregistré), mais Studio est tombé à 13–15 i/s (fenêtre en arrière-plan) pendant la comparaison : chiffres après inutilisables |
| Vidéo avant / après | **non faite** : OBS non joignable (WebSocket) |
| Ressenti humain | PENDING |

## 1. Inventaire

714 clips Blender pour les 8 persos (83 à 96 chacun). Ont tous les huit : marche et course dans 4 directions, sprint, départ, freinage, saut (impulsion, air), réception, Light1–4, DashAttack, Slam, Air1–2, projection, saisie, garde, 10 réactions (tête, ventre, côté, dos, jambes, chaque côté), éjection, chute, relevé, roue, salto, intro, victoire, éveil, ultime.

**Pas de clip dédié** (dessiné par le moteur ou par un autre clip) : course sur le mur, dash latéral et arrière, demi-tour brusque, saut de chakra, boucle de chute.

## 2. Classement

Mesure : écart angulaire moyen, articulation par articulation et dans le temps, entre deux clips de même nom. En dessous de ~10°, deux persos font le même geste.

### Bon — à garder

- **Réactions aux coups.** Le moteur choisit bien le clip selon le coup reçu (Studio, Kakashi sur Naruto) : Light1 → zone tête, Light2 → coup de pied au ventre, Light3 → éjection, lourd → chute, plongée → chute. Chaque côté a son clip (`.L`).
- **Gardes et postures de repos** : différentes d'un perso à l'autre (12 à 32° de Sasuke).
- **Light2, Light3, Light4, Heavy, Slam, Launcher** : propres à chaque perso (plus de 15° entre deux persos, sauf Itachi–Kakashi au Light2, 10°, et Sasuke–Minato au Light3, 14°).
- **Mécanique des transitions** (inertisation, pieds plantés dans les coups) : les 32 tests d'animation passent ; pas de saut de pose aux changements de clip dans les tests.

### Moyen — à améliorer

| Clip | Persos qui font le même geste (écart) |
|---|---|
| Light1 | Sasuke, Itachi, Minato, Kakashi (7–10°), Lee (13°) |
| DashAttack | Itachi–Kakashi 4°, Naruto–Kakashi 6°, Naruto–Itachi 6° |
| Air1 | 7 persos sur 8 entre 4 et 9° |
| Projection, saisie | 3 à 8° entre la plupart |
| Dash.F | 2 à 8° entre la plupart |
| Réactions | 8 à 14° de Sasuke (base commune ; acceptable pour une réaction, pas pour l'identité) |

### À remplacer

- **La locomotion de 6 persos est celle de Sasuke.** Course, sprint, saut et réception de Naruto, Kakashi, Minato, Neji et Itachi sont à 1–2° de Sasuke (Lee : sprint, saut et réception à 1°). Cause : `tools/blender/job_mocap_loco.py` applique la même capture Mixamo à tous ; le style propre à chacun (`nd_style`) ne change presque rien. C'est contraire à la règle « Mixamo seulement comme matière première » et à la fiche (Naruto ample, Kakashi économe, Minato court et rapide…).
- **Strictement identiques chez les 8** : roue, poursuite, au sol, roulade arrière (handspring), chute ; salto à 0–5°.
- **Le sprint est une course jouée 2,4 fois trop vite** : le clip est fait pour 18,9 studs/s, le jeu sprinte à 45. Il faut une vraie course ninja à grandes foulées (temps de vol long), pas un réglage.

### Défauts du moteur (pas des clips)

1. **Le corps glisse sur le sol en courant.** La foulée écrite par la chaîne mocap (`meta.stride`) est le déplacement de la capture ; sur les jambes R15, le pied au sol balaie bien moins (course : 9,2 studs/s pour une foulée qui en annonce 13,3). Le cycle était joué sur cette foulée : **chaque pied posé glissait vers l'avant à ~46 % de la vitesse du corps** (Gaara : 64 %). Corrigé au lot 1.
2. **Les jambes du sprint vivent au plafond de vitesse des articulations.** Genou du clip à 2 546°/s une fois joué à 45 studs/s, plafond du moteur 2 200°/s : la jambe dessinée prend du retard puis rattrape. Studio : 15 à 19 sauts de genou au-delà de 35° par image en 1,4 s de sprint (Naruto, Lee, Kakashi). Atténué au lot 1 ; le vrai remède est le clip (ci-dessus).
3. **Duel IA Naruto–Kakashi, 47 s (Studio, 56 i/s)** : 129 cassures de vitesse du corps de Naruto et 51 de Kakashi, 85 % en neutre ; mains qui sautent de 2,9 studs au départ du DashAttack ; genoux, chevilles et épaules au-delà de 35° par image 40 à 128 fois par articulation, surtout en neutre et en départ de coup. Les correctifs du 06/11 (fondu de trajectoire, orientation) n'ont toujours pas été vérifiés à 60 i/s dans Studio ; les cassures restent nombreuses.

## 3. Lot 1 — la foulée réelle (`Client/VelmoraMotionEngine`)

- La cadence d'un cycle se règle sur **la distance que son pied posé couvre vraiment** (mesurée une fois par clip : balayage de la cheville au sol × durée), plus sur le déplacement de la capture.
- La cadence ne dépasse jamais **1,8 fois** la vitesse dessinée du clip. Au-delà, le pied posé **tient le sol** là où il a atterri et repart en pas quand le corps l'a emporté trop loin (`authoredFeet` en mode cycle). Seulement pour un corps qui avance vraiment (pas contre un mur).

| Mesure headless (8 persos, 2,5 s en ligne droite) | Avant | Après |
|---|---|---|
| Course 19 studs/s : vitesse du pied posé / vitesse du corps | 44–49 % (Gaara 64 %) | **10–14 %** (Gaara 35 %) |
| Sprint 45 studs/s : idem | 44–49 % (Gaara 57 %) | **24–34 %** (Gaara 12 %) |
| Sprint : images de jambe au plafond de vitesse | 7 % | 2–14 % |

Test : `tests/Locomotion.spec.luau` (ajouté à `run.sh`) ; il échoue sur l'ancien moteur (moyenne 46 % > 18 %).

**À juger à l'œil** : le sprint, maintenant fait de longues poussées au sol, et le passage course ↔ arrêt.

## 4. Lot 2 proposé (dans l'ordre)

1. **Locomotion propre à chaque perso** (Blender) : partir de la capture comme matière première et donner à chacun sa foulée, son buste et ses bras (Naruto ample et penché, Kakashi économe, mains basses, Minato foulée courte et très rapide, Itachi droit et posé, Lee engagé, Sasuke appuis précis), avec la foulée mesurée juste. Commencer par Naruto et Kakashi (clip « WHO WINS? » de la CM).
2. **Une vraie course ninja à 45 studs/s** par perso : grandes foulées, temps de vol, bras en arrière.
3. **Light1, DashAttack, Air1** distincts pour Sasuke, Itachi, Minato, Kakashi, Lee.
4. **Vérifier à 60 i/s dans Studio** les correctifs du 06/11 et ce lot, avec les sondes du dépôt, et filmer avant/après (OBS).

## Données

- Parcours Studio : `NDSeg` (idle, course, freinage, sprint, demi-tour, latéral, arrière, sauts, esquives ; combat : chaîne L1–L4, lourd, course→coup, sprint→coup, saisie, saut→coup).
- Studio est tombé à 13–15 i/s pendant une partie des mesures (fenêtre en arrière-plan) : seules les mesures prises à 55 i/s sont citées.
