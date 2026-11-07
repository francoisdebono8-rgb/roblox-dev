> Rapport d'audit (mission « game feel et cohérence des combats », 07/11). État et règles : [sources actives](../../active/EXECUTION_RULES.md).

# Audit visuel du combat dans Studio — 7 novembre 2026

Demande : « des défauts observés dans Roblox Studio, avec des exemples précis »,
classés par gravité, avant toute correction.

## Méthode

| Point | Valeur |
|---|---|
| Code | référence `9f235b2` (sources `0e579bf`, RUNTIME `aec22310b144`) |
| Place | `ND-FEEL` : copie exacte de `PLACES/ND-DEV` (même sha256), ouverte dans une fenêtre Studio à part. Une autre session pilotait `ND-DEV` en même temps (duels relancés sans moi, 900 PV, bot figé) : une mesure faite dans `ND-DEV` a été écartée. |
| Matchs | Naruto–Kakashi, Minato–Itachi, Sasuke–Naruto, 60 s chacun, l'IA du jeu aux deux places (`autopilot`) |
| Mesure | `tools/studio/probes/feel_audit.luau` : à chaque image serveur, position, regard, état, coup, réaction des deux corps. Il relève l'orientation au départ et à la sortie de chaque coup, les coups dans le vide, les glissades, les pivots, les téléportations, les corps l'un dans l'autre, la direction des reculs et le temps mort. |
| Images | captures de la caméra de jeu (Studio) pendant les matchs, et une vidéo OBS de Naruto–Kakashi (rangée dans `LAB/feel-audit`, à supprimer une fois les corrections faites) |

**Limites.**
- Le siège « joueur » joué par l'IA garde le regard caméra du client au moment du lancement (`scripted`) : c'est un joueur qui regarde ailleurs. C'est utile pour tester la caméra libre, mais ce n'est pas une vraie main.
- Les clones de Naruto ne sont pas des acteurs serveur. Leurs coups comptent « par none » et faussent les mesures de distance et d'angle des matchs avec Naruto.
- Le serveur tournait entre 29 et 52 images/s, avec trois Studio ouverts. Un pivot est donc compté à partir de 60° par image, pas en dessous.

## Défauts observés, par gravité

### Critiques (on les voit à chaque échange)

| # | Défaut | Exemple précis | Cause | Qui |
|---|---|---|---|---|
| C1 | **Coups qui touchent de côté.** En caméra libre, le corps frappe tourné vers la caméra, pas vers l'adversaire, et le coup touche quand même. | Minato–Itachi : 12 coups par minute sortent à plus de 35° de l'adversaire (Light1 en moyenne à 23°, DashAttack à 24°, jusqu'à 86°) et touchent. Sasuke–Naruto : 12 par minute (DashAttack à 86°, StepBackStrike à 133°). | Cône de contact à ±87° (`targetValid … .05`). Le soft-lock ne finit pas son virage dans la mise en garde. Entre deux coups, le corps libre revient vers la caméra. | DEV — **lot 1** |
| C2 | **Clones et foule qui cachent tout.** | Naruto–Kakashi : Kakashi entièrement caché par les 10 clones ; un clone de Kakashi au premier plan masque Naruto (capture `nk6`). | La caméra n'efface pas les corps secondaires comme elle efface le décor. | DEV (caméra), lot 6 |
| C3 | **Caméra en l'air et au mur.** | Minato coupé en haut du cadre pendant un aérien, Itachi hors cadre (`mi2`). Itachi et Naruto cachés derrière le HUD en haut (`L1-mi1`, `sn2`). Caméra écrasée contre le mur, la tête de Sasuke remplit le bas de l'image (`sn3`). | Le cadrage vertical ne tient pas compte du bandeau du HUD ; le recul est trop court au mur. | DEV (caméra), lot 6 |

### Majeurs

| # | Défaut | Exemple précis | Cause | Qui |
|---|---|---|---|---|
| M1 | **Glissades.** Le corps se déplace dans une pose fixe. | 28 à 38 par minute et par match. Exemples : Sasuke glisse 2,9 studs en 0,18 s à 18 studs/s en récupération d'un Light1 (t 6,68) ; Minato 3,8 studs à 33 studs/s en garde (t 5,85) ; Minato étourdi, 4,8 studs à 39 studs/s (t 20,35). | En récupération, le stick déplace le corps à `AttackWalkSpeed` 14 studs/s, avec un reste de course. La poussée en garde va jusqu'à 33 studs/s. Les jambes doivent suivre ce déplacement. | DEV (vitesses) + ANIMATEUR (pas de dérive, glissé de garde) |
| M2 | **Corps l'un dans l'autre.** | Sasuke debout dans Naruto à terre (`sn1`). Les poings de Naruto rentrent dans le torse de Kakashi (`nk2`). 7 épisodes par minute (Minato–Itachi, après lot 1 : 0,38 s au total). | Pas de séparation avec un corps au sol ; contact à 2 studs. | DEV, lot 2 |
| M3 | **Victimes retournées d'un coup.** | Itachi lancé par Minato : 176° en une image, puis projeté **vers** l'attaquant (9 studs, t 13,25). Sasuke saisi de dos : 179° en une image (t 20,80). Kakashi en HitStun : 155° (t 57,98). | Écriture directe de l'orientation (prise : `lookAt` à chaque image). Le client lisse à 1 500°/s, ce qui reste un coup de fouet. | DEV — prise : **lot 1** ; réactions de dos : lot 2 + ANIMATEUR (poses de coup reçu dans le dos) |
| M4 | **Coups dans le vide.** | Kakashi lance Light1 à 25 studs (t 2,76) ; Light1 à 8–11 studs, Light2 de Minato à 9,1 studs. | Choix de l'IA hors de portée. | DEV (IA), lot 2 |
| M5 | **Jutsu de déplacement sans trajet.** | LightningStrike de Minato : 10,9 à 13,6 studs en une image. LightningCut de Kakashi : 17,8 studs en une image. | Le déplacement est écrit d'un bloc. Le corps disparaît puis réapparaît, sans traînée pour faire le lien. | DEV + ANIMATEUR (traînée, pose d'arrivée), lot 5 |

### Moyens

| # | Défaut | Exemple précis | Qui |
|---|---|---|---|
| m1 | **Temps mort.** Les deux restent en neutre à plus de 16 studs l'un de l'autre : 7 à 15 s par minute (Minato–Itachi : 25 % du temps), avec des pauses de 2 à 3 s à 60–67 studs. | DEV (IA), lot 2 |
| m2 | **Clones tournés dans le mauvais sens.** Certains courent ou se tiennent dos au combat (`nk4`, `nk7`). | DEV (contrôleur des corps) |
| m3 | **Ressenti d'un coup reçu de dos.** Coups reçus de dos (4 à 9 par minute) : le recul part bien dans l'axe du coup, mais la réaction est celle d'un coup reçu de face. | ANIMATEUR (variantes dos/côté) |
| m4 | **PV affichés.** Avec la vie forcée par l'outil, le HUD affiche « 700 / 150 ». Ce n'est pas un défaut du jeu, seulement une alerte pour les tests. | — |

## Lot 1 — orientation (fait)

| Correction | Fichier |
|---|---|
| **Engagé** : à moins de 12 studs, juste après son coup ou sa réaction (0,8 s), ou quand l'adversaire arme un coup, le corps libre garde la poitrine sur lui au lieu de suivre la caméra. | `Server/Combat` (`Combat.engaged`) |
| Le coup d'un joueur en caméra libre finit son virage dans sa mise en garde (au plus 1 800°/s). | `Server/Combat` (`Combat.finishTurn`) |
| Un coup ne touche que ce qui est devant lui : ±60° au lieu de ±87° (coups et prises). | `Shared/Config` (`Contact`), `Server/BanglaCombat`, `Server/Brawler` |
| Le corps saisi est ramené vers celui qui le tient en 0,2 s environ, au lieu d'un demi-tour en une image. | `Server/Brawler` (`GRAB_TURN`) |

Tests : `tests/Engagement.spec.luau`, 5 tests qui échouent tous sur l'ancien code.

**Avant / après, mesuré dans Studio (même enregistreur, même match, Minato au siège joueur, caméra libre) :**

| Coup de Minato | angle avec l'adversaire à la sortie du coup, avant | après |
|---|---|---|
| Light1 | 23° en moyenne | 4° |
| Light2 | 9° | 4° |
| Light3 / Light4 | — | 3–4° |
| AngleStep | 64° | 16° |
| Coups sortis à plus de 35° de l'adversaire (tous coups confondus, Minato) | 9 par minute | 7 par minute, tous des jutsu, des coups aériens ou des téléportations (voir ci-dessous) |

**Ce qui reste.**
- Le Launcher de Minato sort à 180°, puisqu'il passe derrière l'adversaire.
- Air2 sort à 169°.
- Flashstep et LightningStrike sortent à 44–51°.
- Le DashAttack lancé à 2,3 studs sort à 97° : les corps sont presque l'un dans l'autre.
- Avec Naruto, les mesures sont faussées par ses clones (voir les limites).

## Besoins pour l'ANIMATEUR (zones : [RUNBOOK § 3 quater](../../tools/RUNBOOK_4_DISCUSSIONS.md))

1. **Coup qui pivote** : un revers ou un coup de pied tournant pour un coup lancé à plus de 90° de l'adversaire. Le moteur tourne maintenant le corps jusqu'à 1 800°/s pendant la mise en garde ; sans animation tournante, ce virage se lit comme un pivot mécanique.
2. **Coups reçus de dos et de côté** (HitStun, Launched, saisie), pour que le moteur arrête de retourner la victime.
3. **Dérive en récupération** : des jambes qui marchent pendant la fin d'un coup (le corps peut avancer à 14 studs/s), et une garde qui recule en glissant les pieds.
4. **Arrivée des jutsu de déplacement** (LightningStrike, LightningCut) : une pose d'arrivée et une traînée pour faire le lien entre le départ et l'arrivée.

## Pour le CM

- Ne pas filmer le multiclonage de près en caméra de jeu tant que le défaut C2 existe : la foule cache l'adversaire. Utiliser un plan large de `ND-FILM`.
- Vidéo d'audit : `LAB/feel-audit/2026-11-07_15-50-52_audit-avant_Naruto-Kakashi.mov` (1,4 Go, à supprimer après correction, règle § 3 ter).
