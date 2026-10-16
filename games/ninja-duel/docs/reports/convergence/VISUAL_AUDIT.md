# Convergence — audit visuel natif et grille 0–2

Mission : [COMBAT_CONVERGENCE_ONLINE_ROSTER](../../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §3–§6, grille de [GOLDEN_VISUAL_SET_READY](../../research/GOLDEN_VISUAL_SET_READY.md).

Méthode : Studio piloté par MCP sur l’artefact debug du HEAD ([outillage](../../../tools/studio/README.md)), Minato contre Itachi, scénarios scriptés (course en couloir, sprint, tour de piste continu, zigzag, saut en course, strafe, recul, frappes) ; captures caméra de jeu et caméra latérale d’analyse (outil de mesure seulement, jamais livrée) ; sonde par image (prédiction à vitesse constante, seuil 0,8 stud monde / 0,5 stud pied relatif au corps). Les références ouvertes : 04 (garde kunai) et la grille de comparaison.

## Grille (observée en Studio, acceptation humaine en attente)

| Catégorie | Avant | Après ce bloc | Constat |
|---|---|---|---|
| Course/sprint, intention du corps | 1 | 2 sur captures | Avant : genoux pliés, pieds sous le bassin, pas de vol visible (« trottinement accroupi »). Après : talon qui remonte, genou qui passe haut, jambe d’appui tendue derrière, bras qui pompent sur toute leur amplitude. |
| Changement de direction | 1 | 1 | Rotations bornées et inclinaison dans l’accélération ; zigzag mesuré sans saut (racine 0 %, pied 0,3 %). |
| Saut / traversée | 1 | 1 (amélioré) | Avant : corps droit, jambes repliées (saut Roblox) même en course. Après : bond en ciseaux en course (jambe arrière tendue, genou avant, buste penché), saut latéral incliné, saut arrière assis garde haute ; réception en course sans arrêt-accroupi. Pas encore d’anticipation (impulsion instantanée). |
| Mur, combos sol/air, défense, arme | — | — | Non notés dans ce bloc (pas encore observés image par image). |
| Kunai/shuriken | 1 | 1 | Intégrés au neutral mais encore peu décisionnels. |
| Caméra | 1 | 1 | Correcte ; à longue distance le cadrage à deux réduit fortement les combattants (à revoir avec l’arène). |

Captures latérales avant/après (même scénario, même artefact sauf le moteur d’animation) :

- course : [avant](run_side_before.jpg), [après](run_side_after.jpg)
- saut en course : [avant](runjump_side_before.jpg), [après](runjump_side_after.jpg)

## Mesures (sonde par image, ~57 i/s)

| Scénario | Mesure | Ancien moteur | Nouveau |
|---|---|---|---|
| Tour de piste en sprint (45 studs/s) | images où le pied « saute » par rapport au corps | 11,7 % | 4,8 % |
| Tour de piste en course (19 studs/s) | idem | 0,1 % | 0,1 % |
| Tours de piste | sauts caméra / racine | 0 / 0 | 0 / 0 |
| Zigzag (changements de direction) | caméra / racine / pied | — | 0 / 0 / 0,3 % |

Cause du scintillement en sprint : un pied verrouillé au sol ne restait posé que 2–3 images (à 45 studs/s il balaie toute sa foulée sous le corps en 50 ms), ce qui se lit comme un pied qui se téléporte. Correctif : appui minimal de 85 ms, le pied d’appui glisse légèrement avec le corps au sprint (masqué par la vitesse) ; à la course il reste strictement verrouillé (test Animation mis à jour : aucun glissement sous 28 studs/s, appui de sprint ≥ 4 images et glisse < moitié de la vitesse).

## Reste à faire (mission §3–§6)

Anticipation du saut (impulsion), lecture des frappes image par image (jab, kick, combos, air), transitions mur, réactions corporelles ; à-coups de l’IA en l’air pendant ses techniques ; rotations au début des techniques.
