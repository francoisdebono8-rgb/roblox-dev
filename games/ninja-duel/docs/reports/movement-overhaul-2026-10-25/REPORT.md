# Movement Overhaul — rapport (brief 2026-10-24, §23)

Branche `claude/ninja-duel-2026-10-14`. Les commits sont listés en fin de document.

Carte vidéos → principes : [MOVEMENT_OVERHAUL_AUDIT](../../movement/MOVEMENT_OVERHAUL_AUDIT.md). Brief : [2026-10-24-movement-overhaul-reference](../../archive/requests/2026-10-24-movement-overhaul-reference.md).

## Méthode Studio

Place de debug ouverte dans Studio, les modules patchés à chaque étape (source identique au dépôt, vérifiée à l'octet).

Deux façons de piloter :
1. **Vraies entrées** clavier/souris dans le client. Utilisées pour : flips (pass 2), cartwheel, course + Light, course + Heavy, saut + Light, esquive latérale en sprint.
2. **Stick serveur** via le bindable de dev (`scripted`, `move`, `sprint`, `act`). Utilisé pour la route continue du §20, rejouable à l'identique.

Deux sondes, lues à chaque frame :
- côté serveur : état, coup, mode de déplacement, vitesse plane et verticale ;
- côté client : orientation du `LowerTorso` et transform du joint `Root` (salto, roue, inclinaison).

Studio doit être au premier plan : en arrière-plan, le client tombe à ~5 fps et les sondes ne voient plus rien.

## Systèmes modifiés

| Système | Fichier |
|---|---|
| Acrobaties contextuelles, réception ninja, roue / flip arrière, course le long du mur, sprint par fighter | `Client/VelmoraMotionEngine.luau` |
| Traînée de dash par fighter | `Client/Effects.luau` |
| Esquive : élan rendu, orientation conservée, pas de pivot | `Server/BanglaEvade.luau` |
| Restitution de l'élan (esquive, frappe en course), contrôle aérien sans perte de vitesse, accélération par fighter | `Server/Place1Movement.luau` |
| Murs : course horizontale / montée, joints du mur circulaire, wall-jump tangentiel, limite des frappes aériennes | `Server/Motor.luau` |
| Glissade des frappes en course, orientation en l'air | `Server/Combat.luau` |
| Frappes en course, hover aérien seulement à portée, frappe depuis un mur | `Server/Brawler.luau` |
| Mode de mur dans le snapshot | `Server/Matches.luau` |
| `runStrike` | `Shared/MoveGraphs.luau` |
| Inertie de Zabuza | `Shared/Wave1.luau` |

Pas de second moteur de locomotion. L'invariant du premier coup confirmé est préservé : seuls les *openers* sont des entrées de course.

## Avant / après (mesures Studio)

| Problème | Avant | Après |
|---|---|---|
| Saltos | Jamais : vitesses de recul et de pas latéral sous le seuil | Salto arrière up −1,00 à l'apex ; salto latéral roulis +0,97 → −0,98 ; salto en sortie de mur up −0,97 ; les sauts longs restent des bonds |
| Torsion en l'air | Le corps se retournait de 180° en plein salto | Le buste reste face à l'adversaire pendant tout le vol |
| Esquive → course | Vitesse remise à zéro | Sprint 54 → esquive 89 → 50–53 à la sortie |
| Pivot d'esquive en sprint | Le root tournait de 90° puis revenait en 0,3 s | Orientation gardée, vitesse 64 → 38 → 47 (Lee, vraies entrées) ; roue complète sur une esquive latérale en sprint (up −0,98) |
| Roue / flip arrière | Seule la première esquive tournait ; ensuite le corps restait droit, l'horloge de l'esquive n'étant jamais remise à zéro | Chaque esquive tourne (up −0,98 sur trois esquives d'affilée) |
| Sprint + Light | Arrêt | Coup de pied sauté 54 → 99, glissade 33 → 16, reprise à 40 → 58 sans arrêt (vraies entrées) |
| Sprint + Heavy | Arrêt sec 112 → 12 en une frame | Balayage glissé 85 → 56 → 25 → 12, plus d'engagement que le Light |
| Saut + Light hors portée | Le hover gelait le saut : 55 → 0, puis la récupération était freinée à ~12–30 | 62 → 57 tout le long du coup, 54 à la réception |
| Course sur le mur | Décrochait toutes les 0,1 s : le mur circulaire est fait de segments de 8 studs | Suit la courbe ~1,5 s, 54 → 20, arc jusqu'à ~10 studs, corps incliné de 26° vers le mur (roulis 0,44) |
| Montée du mur | Montée fixe de 23 | Montée = élan d'entrée (≈ 22 studs depuis un sprint) |
| Wall-jump | ~12 studs/s le long du mur | 62 au départ, 54 tenu ; salto si aucune frappe ne l'annule |
| Frappe depuis la montée | Frappait le mur | Le corps se retourne et part du mur (face 1,00) |
| Arc en l'air | Infléchir à 90° faisait chuter de 54 à 20 | La vitesse est gardée ; seul un contre-appui freine |
| Fin de course sur le mur | Rejeté du mur à 12 | La foulée continue le long du mur |
| Poursuite → combo aérien | — | Pas de pause : Poursuite → Air1 (appui tamponné) → Air2 → retombée → marche |
| Sprint | Le même pour tous | Lee bas et engagé, Itachi droit aux bras bas (captures) ; Zabuza, Bee bras qui pompent ; Haku bras qui glissent ; Nagato, Sasori sobres |
| Traînée de dash | Le même rouge pour tous | Teinte, durée, opacité et largeur propres à Lee, Itachi, Shisui, Gaara, Haku, Zabuza et Nagato |
| Zabuza | Inertie identique aux autres | Accélération ×0,86 (départ et virages), contrôle aérien ×0,85, saut ×0,96 |

## Route continue du §20 (une seule prise, même fighter)

`sprint → changement de direction → saut long → Light aérien → réception en sprint → esquive latérale → Heavy en course → saut vers le mur → montée → wall-jump → attaque aérienne → réception → course horizontale sur le mur → salto de sortie → poursuite → string → lanceur → combo aérien → retour au sol`

Vitesse plane par segment, en studs/s (min…max) :

| Segment | Lee (Leaf) | Sasuke (Lion) | Zabuza (Mist) | Gaara (Sand) |
|---|---|---|---|---|
| Sprint | 0…64 | 0…58 | 0…58 | 0…48 |
| Changement de direction | 43…59 | 43…56 | 42…57 | 35…42 |
| Saut long | 51…77 | 45…69 | 46…71 | 36…58 |
| Light aérien | 49…63 | 43…62 | 40…58 | 32…48 |
| Réception en sprint | 50…58 | 39…59 | 37…62 | 34…44 |
| Heavy en course | 2…89 | 2…114 | 2…89 | 2…65 |
| Wall-jump | 49…60 | 44…67 | 45…61 | 36…65 |
| Attaque aérienne | 43…63 | 42…62 | 37…59 | 29…60 |
| Course sur le mur | 30…59 | 22…72 | 27…58 | 14…47 |
| Salto de sortie | 44…64 | 41…68 | 45…77 | 30…72 |
| Poursuite | jusqu'à 154 | jusqu'à 150 | jusqu'à 152 | jusqu'à 98 |

La route est enchaînée d'un bout à l'autre pour les quatre fighters.

Pour Lee, la sonde client voit :
- le corps couché sur le mur pendant la montée ;
- l'inclinaison pendant la course horizontale ;
- le salto de sortie ;
- aucun salto sur le saut long, qui reste un bond.

Après le premier wall-jump, la frappe tamponnée annule le salto, comme prévu.

Sur cette route, Gaara n'enchaîne pas de lanceur et ne fait aucun salto ; son esquive est un shunshin de sable (pic à 720).

## Fighters rejoués

| Fighter | Ce qui a été rejoué |
|---|---|
| Lee | Tout, vraies entrées et route |
| Sasuke, Zabuza, Gaara | Route complète |
| Itachi | Course comparée à Lee (captures) |
| Leaf en bot | Esquives répétées (roue et flip) |

Bee et Haku ne sont validés que headless, par la course et la traînée.

## Défauts restants (honnêtes)

- **Pas de validation humaine** du ressenti. Les mesures et captures ne remplacent pas une session de jeu. HUMAN_VISUAL/FEEL : PENDING.
- **Départ de Zabuza** : à peine plus lent mesuré (atteint 40 studs/s en 0,24 s contre 0,25 s pour Lee). L'impulsion de départ domine ; c'est l'air et les virages qui le distinguent vraiment.
- **Fin de combo aérien** : le dernier coup tient le corps ~0,4 s en l'air avant la chute. C'est le hover de jonglage du combat, non retouché.
- **Saut vers le mur, stick toujours tenu vers le mur** : l'air control freine, et c'est voulu (contre-appui). En jeu, le joueur oriente.
- **Haku et Bee** : rien n'a été rejoué en Studio (sprint et traînée validés headless seulement).
- **Pieds** : pas d'audit dédié du glissement des pieds au-delà des captures.
- **Caméra** : le FOV de sprint, l'avance de cadrage et la remontée au contact du mur existaient déjà. Rien n'a été ajouté.
- **Course sur le mur depuis le sol, scénario scripté** : en tenant le stick en diagonale, on peut ré-accrocher le mur en montée juste après la course (artefact du stick tenu).

## Tests

`tests/Movement.spec.luau` : 17 cas. Couvert notamment :
- les murs avec de vrais plans et un changement de segment ;
- la hauteur de montée selon l'élan ;
- le wall-jump tangentiel ;
- l'esquive : orientation, absence de pivot, seconde esquive qui tourne bien ;
- le sprint propre à chaque fighter.

Contrôles négatifs vérifiés par mutation :
- joint de mur : échoue sans la correction ;
- horloge d'esquive : échoue sans la correction (up 1,00).

Résultats : 29 suites PASS, isolation des builds PASS, docs PASS.

## Commits

- `1cd3f13` pass 1 : acrobaties contextuelles, élan de l'esquive.
- `396c881` pass 2 : corrections issues de Studio, frappes en course.
- `aba5212` pass 3 : frappes aériennes, murs, wall-jump.
- Pass 4 (ce rapport) : esquive sans pivot, horloge d'esquive, frappe depuis la montée, glissades sans arrêt, sprint et traînée par fighter, inertie de Zabuza.
