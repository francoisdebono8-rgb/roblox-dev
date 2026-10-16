# Convergence — distance de contact et réactions aux coups

Mission : [COMBAT_CONVERGENCE_ONLINE_ROSTER](../../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §9 (continuité des combos) et §10 (« appui → transfert de poids → accélération → contact → réaction → récupération »).

## Méthode : chronophotographie

Outil Studio (debug seulement, jamais livré) : chaque image rendue, les pièces des deux combattants sont enregistrées ; ensuite des copies figées de plusieurs instants sont posées côte à côte et vues de profil (`tools/studio/probes/film_*.luau`, scénario `exchange.luau`). Une capture montre ainsi 6 à 9 instants d’un même échange, au lieu d’une capture au hasard toutes les 3 s. `film_distances.luau` mesure, image par image, la distance entre bassins, torses, têtes et les deux pièces les plus proches.

Scénario : Minato contre Itachi immobile (il encaisse sans agir), chaîne Light1 → Light2 → Light3.

## Constat (avant)

[Avant](string_before.jpg) : dès le deuxième coup, Minato rentre dans le corps d’Itachi. Mesures : bassins à 3,0 studs, torses à 2,1, têtes à 1,4 (elles se chevauchent), pièces les plus proches à 0,1. Deux causes dans le code :

- l’avancée d’une frappe au sol s’arrêtait à 2,6 studs de centre à centre (`Combat`), alors qu’un coup léger ne faisait reculer la victime que de ~0,5 stud (amortissement très fort dans `Brawler`) : chaque coup avançait l’attaquant de 3,2–3,5 studs et l’écart s’effondrait ;
- la réaction à un coup léger debout valait 9° de flexion du torse (force 0,35 pour 5 dégâts) : illisible à vitesse réelle.

Piège trouvé en corrigeant : la boîte de touche des coups légers ne s’étend que de 1 à 3 studs devant le bassin (la « portée 7,8 » n’est qu’un filtre). À 3,9 studs, toute la chaîne ratait ; la boîte suit maintenant la distance de contact.

## Changements

- `Attacks` : distance de contact par frappe (bassin à bassin) : 3,6 pour les poings, 4,0 pour les coups de pied (Light3, coup de pied sauté), 3,9 lourd, 3,7 paume, 3,2 genou, 3,5 balayage, 2,6 saisie/projection. La boîte des coups légers va jusqu’au contact + 0,25.
- `Combat` : l’avancée d’une frappe et l’arrivée du Rush s’arrêtent à cette distance (au lieu de 2,6 et 2,8).
- `Brawler` : un coup léger (HitStun) fait glisser la victime d’environ 0,9 stud au lieu de 0,5 : la chaîne pousse vers l’avant au lieu de faire marcher l’attaquant dans sa cible.
- `VelmoraMotionEngine` : plancher de force pour les réactions debout (0,62), torse plié de 32° au lieu de 26, hanches repoussées (0,6 au lieu de 0,4), torsion et tête plus marquées ; coup au visage : tête qui part plus loin.

## Résultat (après)

[Après](string_after.jpg), [zoom sur la deuxième touche](hit_reaction_after.jpg) : bassins à 3,65, torses à 2,7–3,1, têtes à 2,0–2,9, les trois coups touchent. Itachi se plie sur la paume et tourne le torse sur la taillade.

| Même scénario | Avant | Après |
|---|---|---|
| bassins pendant la chaîne | 3,0 | 3,65 |
| torses (minimum) | 2,13 | 2,74 |
| têtes (minimum) | 1,44 | 2,04 |
| coups touchés | 3 / 3 | 3 / 3 |

Garde-fou : `Regression` « a string steps in to an arm's length… » (échoue sur l’ancien code : l’attaquant s’approche à 3,00 studs). Sonde de combat IA après changement : sauts du corps restants = substitution (voulue) et plongée du slam.

## Limites

Les combos aériens, le lancer et la poursuite n’ont pas encore été filmés ainsi ; les réactions de recul (Knockback) et au sol non retouchées. Pas d’acceptation humaine.
