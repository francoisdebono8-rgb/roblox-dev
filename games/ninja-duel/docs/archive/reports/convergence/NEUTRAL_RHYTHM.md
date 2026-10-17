# Convergence — rythme du neutre (IA)

Mission : [COMBAT_CONVERGENCE_ONLINE_ROSTER](../../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §8 et §23 (« 60 secondes de combat contiennent naturellement mouvement, outils, défense, échanges, poursuite, conversions air/mur et désengagement »).

## Mesure

- Studio : sonde de 60 s IA contre IA (Minato piloté par l’IA contre Itachi), santé remise à 400 sous 80 PV sans toucher au chakra ni aux temps de recharge, échantillonnage 10 Hz, compteurs d’événements de combat.
- Headless : `lune run tests/Neutral.sim.luau [graines] [secondes]`, les 12 affrontements ordonnés CORE4, mêmes règles (pas de murs circulaires dans le harnais : les murs ne se mesurent qu’en Studio).

## Diagnostic (avant)

| Studio, 60 s | Minato | Itachi |
|---|---|---|
| techniques | 27 | 15 |
| gardes / coups gardés / parades | 4 / 2 / 1 | 4 / 0 / 0 |
| feintes d’approche | 0 | 1 |
| temps sur un mur | 0 % | 0 % |

Distance : corps à corps (< 7 studs) 46 % du temps. Causes dans `AI.luau` : chaque tick (0,18 s) tentait une technique dès que sa condition était vraie (le temps de recharge était la seule limite) ; la défense ne réagissait qu’après 0,38 s de latence, plus long que le démarrage d’un coup léger, donc jamais contre eux ; le strafe était une sinusoïde ; les replis reculaient droit jusqu’au mur.

## Changements (serveur, `AI.luau`, réglages `Config.AI`)

- Jutsus espacés : 2,6–5,2 s entre deux, sauf punition au contact (étourdi, lié, ou en récupération à moins de 7 studs). La téléportation de Minato sur son propre sceau reste une conversion du kunai.
- Lectures : une entrée en portée de mêlée est lue une fois, avant le coup (garde → parade si le timing tombe, pas de côté, contre-coup) ; au contact face à un adversaire qui ne frappe pas encore, garde d’anticipation occasionnelle. C’est une supposition, pas une réaction : aucune triche de latence.
- Feinte d’approche en sondage (deux pas dedans, ressortie, souvent avec une lame) ; outils plus fréquents en sondage.
- Strafe engagé par séquences (0,6–1,8 s) puis changement de côté ; touché puis libéré → retour au neutre (45 %).
- Replis qui dérivent vers le centre près du bord : le mur devient un choix (course au mur à 35 % près du bord), pas la fin de chaque repli.

## Résultat

| Studio, 60 s | Avant (Minato / Itachi) | Après (Minato / Itachi) |
|---|---|---|
| techniques | 27 / 15 | 18 / 13 (12 / 11 sur une autre partie) |
| gardes | 4 / 4 | 10 / 7 |
| parades | 1 / 0 | 5 / 4 |
| feintes d’approche | 0 / 1 | 8 / 6 |
| conversions murales | — | WallSplat 1, WallPin 2, WallConvert 1 ; Itachi sur un mur 2–9 % |
| poursuites (Chase / Rush) | 2 / 1 et 3 / 0 | 0 / 3 et 5 / 4 |

Distance : corps à corps 46 % → 23 %, mi-distance 24 % → 39 %, loin 28 % → 30 % ; près du mur 22 % / 9 % → 31 % / 30 % ; au centre 16 % → 35 % / 31 %.

Headless, 12 affrontements, par combattant et par minute : techniques 16,3 → 10,3 ; outils 7,5 → 11,0 ; gardes 3,1 → 4,5 ; esquives 2,0 → 2,5 ; feintes d’approche ≈ 0 → 2,0.

Garde-fou : `Regression` « AI neutral rhythm » (graine fixe, une minute) échoue sur l’ancien code (34 jutsus + 13 téléportations, 6 gardes) et passe sur le nouveau (22 + 5, 10 gardes).

## Limites

Mesures techniques sur l’IA ; pas d’acceptation humaine. Les combos subis restent peu défendables une fois le premier coup reçu (normal) ; la défense humaine contre l’IA n’est pas évaluée ici. L’arène (élévation, couloirs) n’a pas changé dans ce bloc.
