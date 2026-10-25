# Combat Convergence Breakthrough — rapport d'étape (brief 2026-10-25, §18)

Branche `claude/ninja-duel-2026-10-14`. Brief : [2026-10-25-combat-convergence-breakthrough](../../archive/requests/2026-10-25-combat-convergence-breakthrough.md).

**Statut : rapport d'étape, pas de verdict de rupture.** Le lot 1 a été vu à l'écran en Studio, image par image. Les lots 3 à 5 ont été mesurés en Studio côté serveur, mais pas encore regardés : le client Studio ne rend plus d'images depuis le lot 2 (écran du Mac en veille, RenderStepped à 0). Les combats d'acceptation A–E à vitesse normale restent à faire à l'écran. Le brief juge cette mission à l'écran ; ce document ne vend donc pas ces lots comme une rupture.

## Méthode

Place de debug ouverte dans Studio. Les modules sont patchés à chaque lot dans le datamodel Edit, et leur taille est vérifiée à l'octet contre le dépôt.

Combats IA contre IA pilotés par le bindable de dev. Le chakra est bloqué à 18, ce qui force du taijutsu pur : en dessous de 18, l'IA recule. Les nouvelles opérations de dev sont `chakra` (commit 8bbf439) et `move`. Paires jouées : Lee–Itachi, Minato–Itachi, Zabuza–Lee.

Sondes utilisées :
- **Sonde serveur à chaque Heartbeat** : position de la racine, état, coup, réaction, vitesse, écart entre racines, rotation par frame.
- **Planches image par image** (lot 1, rendu actif) : fantômes surélevés pour un fond propre, caméra placée du côté du centre de l'arène.

## 1. Problèmes de départ (Studio)

**Réactions**
- Un jab ne pliait que la tête.
- Un knockback glissait debout.
- Entre deux coups d'une chaîne, le corps revenait vers sa garde.

**Rotations**
- Claquages de la racine au départ des frappes : 1400 à 1900 °/s.
- Au moment où le rush s'engage sur sa ligne : 3000 °/s.

**Contact**
- L'étincelle de contact apparaissait au centre du torse.
- Le kunai apparaissait décalé de la main, une frame en retard.

**Air et garde**
- Les frappes aériennes planaient pendant leur récupération.
- La garde était repoussée d'un bloc, en une seule frame.

**Corps au sol et géométrie** (révélé par les traces serveur du lot 3)
- Un corps projeté au ras du sol ne touchait jamais le sol. Le sol réel est 3 studs sous la racine ; le rayon de vol ne porte qu'à 1,4 stud au-delà du déplacement de la frame. Résultat : 18 studs glissés à hauteur debout, à 30 studs/s constants.
- Le corps glissait encore pendant le relevé : 8,3 studs.
- Un spike tombant de près ne rebondissait jamais.
- Le harness de test cachait le bug : son sol répondait à tout rayon portant à 1,9 stud.
- Corps fusionnés : écart minimal de 0,23 à 0,34 stud entre racines, 13 à 24 frames sous une largeur de corps par combat de 20 s.

**Whiff**
- Une frappe dans le vide récupérait exactement comme une frappe qui touche.

## 2. Changements

| Lot | Commit | Quoi |
|---|---|---|
| 1 | e3b2932 | Réactions du défenseur (pli du corps, tête, jambes, knockback projeté à plat), frappes engagées après le startup, rotations bornées (startup 900 °/s, actif 420 °/s), rush et poursuite tournés à 1440 °/s, garde repoussée sur plusieurs frames, étincelle au point de contact, hover aérien limité à la frappe, kunai/shuriken/fil visibles dès la main |
| 2 | 8bbf439 | Identité dans l'échange (`StrikeTurnScale` en données : Itachi esquive plus court et tourne un peu plus vite, le couperet de Zabuza tourne lentement) ; réaction maintenue jusqu'à 90 ms quand le serveur la laisse retomber entre deux coups ; op dev `chakra` |
| 3 | 1758922 | Corps projetés : sonde du sol sous la racine pendant la descente, posé sur le sol, dérapage de 60 % de l'élan qui s'éteint ; harness fidèle au sol réel |
| 4 | 01388bd | Pas de fusion : l'arrivée du rush lit la vitesse de rapprochement des deux corps et freine sur la frame d'arrivée ; une frappe lancée depuis un rush ou une poursuite (et une poursuite qui se termine) freine l'élan ; sous 2,6 studs, aucune racine ne garde de vitesse vers l'autre (l'esquive et le dash en ligne passent) |
| 5 | 307f731 | Whiff : le serveur marque la frappe dans le vide (`whiffed` dans le snapshot pendant la récupération) ; le client emporte le corps au-delà du contact (hanches basses et vers l'avant, buste au-dessus du pied avant) puis le ramène ; pieds plantés conservés |

Contraintes respectées :
- autorité serveur ;
- invariant du coup confirmé intact ;
- tout ce qui est propre à un personnage passe par les données ;
- aucun `if fighterId` ajouté ;
- pas de second moteur de locomotion.

## 3. Combats joués

| Combat | Comment | Rendu à l'écran |
|---|---|---|
| A — taijutsu pur 20 s | IA–IA, chakra 18 : Lee–Itachi, Zabuza–Lee | Lot 1 oui (planches) ; lots 3–5 non |
| B — Minato–Itachi | IA–IA, chakra 18 | Lot 1 oui ; lots 3–5 non |
| C — attaquant/défenseur | Module FightC : coups placés, réactions | Lot 1 oui (pli, tête, knockback) |
| D — air et murs | Chaîne aérienne Air1→Air2→Air1→Slam | Lot 1 oui (la chaîne connecte toujours) ; murs non rejoués |
| E — armes | Kunai lancé à l'arrêt | Lot 1 oui (main → lame, 0,04 stud, même frame) ; en course, en saut, après esquive : non |

## 4. Ce qui s'est vu ou mesuré, par combat

**A et B**
- Le knockback est maintenant un corps jeté à plat (vu).
- Le pli du corps et la tête qui part sont visibles à vitesse de planche (vu).
- Mesures serveur, avant → après :
  - relevé : 8,3 → 0,1 stud parcouru ;
  - frames sous 2 studs entre racines : Lee–Itachi 24 → 0, Minato–Itachi 13 → 0, Zabuza–Lee 19 → 0 ;
  - écart minimal : 0,23–0,34 → 2,38–3,18 studs.
- Rotations au-dessus de 1000 °/s qui subsistent (traces serveur) :
  - canal NeedleFan d'Itachi, borné à 1440 °/s ;
  - téléport du Flashstep (un warp, voulu) ;
  - rush à 1440 °/s ;
  - spin du Great Whirlwind (voulu).

**C**
- Le défenseur répond au coup par zone : la tête pour un coup à la tête, le buste pour un coup au corps, les jambes pour un coup bas.
- La garde recule sur plusieurs frames.

**D**
- Le hover aérien ne dépasse plus la fenêtre de la frappe (test).
- La chaîne aérienne connecte.

**E**
- Le kunai part de la main, sans frame vide.

## 5. Défauts de frame corrigés

- Claquages de la racine au départ des frappes et du rush (lot 1).
- Frame de kunai invisible et décalage de 0,7 stud depuis la main (lot 1).
- Retour vers la garde entre deux coups d'une chaîne (lot 2).
- Glisse à hauteur debout et glisse pendant le relevé (lot 3).
- Spike sans rebond (lot 3).
- Corps l'un dans l'autre (lot 4).

## 6. Tests

- Suite complète PASS (30 suites) après chaque lot.
- `CombatFeel` compte 18 cas, dont 12 contrôlés par mutation (le message du lot 6 annonce 19 cas : c'est 17 à ce stade). Le cas « réaction maintenue » échoue sans la traîne ; « dérapage au sol » échoue sans le correctif (17,7 studs glissés) ; les deux cas dash échouent sans freinage (1,04 et 2,30 studs) ; « whiff » échoue sans le geste.
- Les deux cas de dash ajoutent à la main l'avance du solveur, que le harness n'a pas.
- Le harness fidèle au sol a fait apparaître cinq échecs, tous des bugs réels en Studio ou des tests qui dépendaient du faux sol :
  - rebond du spike dans Branches, ComboModel et Progression ;
  - knockdown jamais posé dans Animation ;
  - lame de Gaara.
- Contrôles du dépôt PASS : trois builds, isolation des builds, documentation, architecture.

## 7. Faiblesses restantes

**Pas encore validé à l'écran**
- Combats A–E à vitesse normale pour les lots 2 à 5 : le dérapage au sol, l'écart à longueur de bras et le geste du whiff n'ont pas été vus.
- Nouvelles planches avant/après.

**Pieds**
- Pas d'audit fiable. Une sonde client pilotée au Heartbeat (sans rendu) trouve des glissements de pied planté et des sauts de genou en Neutral chez Itachi. Ces mesures mélangent le lissage de la racine dessinée et le cycle de course : non concluantes, aucun correctif tiré.
- La glisse de pied d'appui en sprint (`slip`) reste un compromis assumé du moteur.

**VFX**
- Seule l'étincelle a été déplacée au point de contact. Pas d'audit des autres effets.

**Identité**
- Seulement Itachi et Zabuza dans l'échange.
- Lee (jambes), Sasuke et Gaara : rien de neuf dans cette mission.

**Lisibilité à grande vitesse**
- Non traitée.

**Gameplay**
- Le dérapage au sol raccourcit fortement les knockbacks (de ~18 studs à ~5 au ras du sol), donc moins de murs atteints. C'est plus juste physiquement, mais c'est un changement de jeu à confirmer manette en main.

## 7 bis. Combats libres IA contre IA (lots 6–7, demande du 25/10 au soir)

Banc Studio : deux IA, chakra plein, jutsus permis, 25 paires sur 20 à 25 s. Pour chaque frame serveur, le banc relève :
- écart entre racines ;
- vol au ras du sol ;
- grands pas et rotations ;
- états bloqués ;
- sorties d'arène ;
- dégâts.

Côté client, avec le rendu actif :
- caméra de profil sur les deux corps ;
- enregistreur image par image ;
- mesure d'interpénétration pièce par pièce (centres de torse et de tête ; mains et pieds dans le torse ou la tête de l'autre).

Défauts trouvés et corrigés :

| Vu | Correctif |
|---|---|
| La substitution standard glissait de 8 studs en tournant de 180° sur trois frames | Marquée comme coupe (`warpSerial`) |
| Plongeon depuis un mur : 125–165° en une frame | Rotation sur la préparation (2400 °/s), un seul propriétaire |
| Chaîne aérienne tenue à 2,7 studs : le corps jonglé et le couperet de Zabuza traversaient Lee | Tenue à la distance de contact (3,6) |
| Coup de Minato à travers la tête d'Itachi ; dash attack : torses à moins de 1,4 stud pendant une douzaine de frames | Le client recule les hanches du frappeur du manque (portée de la main à 3,9 ; poitrine à 2,6 de l'adversaire), pieds plantés conservés |
| Main du corps frappé dans la tête du frappeur (réaction tête, bras projetés vers l'avant) | Bras ouverts sur les côtés |
| Projection arrière de Neji : Hinata à 0,46 stud, à travers lui | Un stick tiré en arrière projette sur ce côté |

Mesures :
- Écart sous 2 studs : 0 frame dans 24 des 25 paires. Seule exception, la projection arrière, depuis corrigée.
- Les chaînes aériennes connectent toujours (AirHit 4/2, 5/0, 1/0 sur trois paires après le correctif).
- Le Mac s'est remis en veille avant la mesure client après les correctifs du lot 7 : l'effet sur les torses et les mains n'est pas encore mesuré à l'écran.

Non retenus comme défauts :
- les téléports voulus (Flashstep, Silent Killing, Body Flicker, arrivée des lotus) ;
- les vols bas de 0,1–0,2 s des knockbacks peu levés, qui atterrissent bien ;
- la perte de 884 PV de Nagato, un artefact du banc : ses 999 PV de test sont ramenés au maximum par un soin ;
- les à-coups serveur vus pendant le traçage, causés par le traceur lui-même (aucune frame au-dessus de 40 ms sans lui).

## 8. Commits

- `e3b2932` — lot 1
- `d932ab5` — classement du brief
- `8bbf439` — lot 2
- `1758922` — lot 3
- `01388bd` — lot 4
- `307f731` — lot 5
- `a921c9b` — lot 6 (combats libres)
- `48cb469` — lot 7 (combats libres, pièce par pièce)
