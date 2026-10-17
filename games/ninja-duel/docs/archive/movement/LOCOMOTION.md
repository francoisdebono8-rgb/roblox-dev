# Mouvement — contrat actif

IDs : MOV-001 à MOV-005, COM-002/003, CAM-002, RES-001. Implémentation : `src/Server/Motor.luau`, Place1Movement/Place1Parkour, Animation, `src/Client/Presentation.luau` et VelmoraMotionEngine. Les tests prouvent des routes/valeurs, pas la crédibilité des appuis.

## Exigences cumulatives

Course avant/arrière, vraie course latérale gauche/droite, diagonales, retournements et changements de vitesse ; orbit/reentry/poursuite/sprint lisibles. La tête et le torse peuvent suivre partiellement l’adversaire pendant que le bassin et les jambes suivent le déplacement. Ne pas appliquer une simple pose tournée qui fait glisser les pieds.

Cadence et amplitude suivent la vitesse réelle ; pied posé et jambe de poussée cohérents. Centre de gravité, balancement et transfert bassin/torse rendent freinage, feinte et accélération compréhensibles. Dash vient d’un appui et d’une impulsion, avec réception/recovery, pas d’un root qui glisse sous une statue.

### Sensation de vitesse — exigence prioritaire de game feel

La vitesse ne doit pas seulement être correcte en studs/seconde : **le joueur doit la ressentir immédiatement**. Une course normale et un sprint doivent produire deux sensations clairement différentes avant même de comparer les distances parcourues. Construire cette impression avec l’ensemble du corps et de la présentation : cadence des pas, longueur de foulée, inclinaison du torse, poussée des bras, amplitude, accélération/freinage, réponse directionnelle, proximité du sol, mouvement relatif du décor, caméra et audio si utile.

Ne pas résoudre ce besoin uniquement en augmentant `WalkSpeed` ou avec un FOV excessif. La caméra peut contribuer à la sensation de vitesse via framing, léger recul/avance, FOV borné, inertie contrôlée et lecture du décor, mais elle doit préserver la précision des appuis, la cible et le confort. Le sprint doit donner une vraie impression de shinobi qui traverse rapidement l’arène ; la course normale doit rester vive, athlétique et contrôlable sans devenir un sprint permanent.

Tester séparément : départ arrêté → course, course → sprint, sprint → virage fort, sprint → freinage, sprint → attaque, sprint → saut, sprint → wall run, poursuite longue et réentrée vers l’adversaire. La sensation de vitesse doit survivre en lock-on comme en déplacement libre.

### Sauts et traversal ninja

Les sauts ordinaires ne doivent pas lire comme un petit hop Roblox presque vertical suivi d’une retombée lourde. La locomotion aérienne doit évoquer un jeune ninja athlétique : anticipation courte mais lisible, impulsion franche depuis les jambes, conservation de l’intention horizontale et du momentum, trajectoire utile, corps étendu/organisé dans l’air, contrôle raisonnable de direction, préparation de réception puis landing proportionné à la hauteur et à la vitesse réelles.

Éviter une gravité visuelle exagérée sur les petits sauts et déplacements standards. Une grosse retombée doit être réservée aux vraies chutes, slams ou impacts lourds. Un saut de traversal doit pouvoir naturellement mener à poursuite, attaque aérienne, wall approach, wall run/rebound ou repositionnement sans pause ni sensation de personnage « aspiré vers le sol ».

Différencier : saut neutre, saut avec élan, saut sprint, poursuite aérienne, wall jump/rebound et chute/landing lourde. Le momentum horizontal ne doit pas être artificiellement perdu à chaque impulsion. La caméra accompagne l’arc sans transformer la verticalité en secousse ni masquer la réception.

Saut : anticipation/poussée, ascension, apogée, chute, landing et reprise. Même règle en attaque, knockback, air pursue, slam, wall run/jump/rebound/detach/mantle. Les états changent sans cuts ou membres figés. Reproduire jumpattack/attackjump, launcher chase, repeated input, vertical camera et landing avant de rouvrir un ancien bug.

Frappes : pied d’appui → hanches → torse → épaule → membre → transfert de poids → followthrough → recovery. Jab/cross/hook/uppercut/elbow/knee/kicks/sweep/spin360/projection/air/wall ont des chaînes physiques différentes. Corps réactif aussi en défense, prise, throw, réception, KO et retour neutre. Ne pas couvrir un contact décalé avec un effet lumineux.

Quatre expressions : Minato vif et orienté angles ; Itachi calme/précis/minimal ; Neji paumes/rotation/appuis circulaires ; Sasuke agressif/kicks/air/mix range. La continuité compte plus qu’un nombre de clips ou un nouveau système d’animation.

## Acceptation

Capture avant/après native pour huit directions et chaque transition clé, vitesse normale puis ralenti ; observer pieds/hanches/contact/cible, tester duel/manette/caméra. Ajouter une comparaison dédiée course normale vs sprint : départ, accélération, vitesse stabilisée, virage, freinage et retour combat. Le sprint doit paraître nettement plus rapide sans dépendre d’un artefact de caméra inconfortable.

Pour les sauts, comparer au minimum saut neutre, saut avec élan/sprint, saut vers mur, wall rebound et landing depuis faible puis grande hauteur. Refuser le petit hop vertical + chute lourde sur traversal standard ; vérifier conservation du momentum horizontal et reprise immédiate du mouvement/combat.

Conserver les timings gameplay durant une correction de présentation sauf changement approuvé et testé. Comparer les mêmes scènes et profils neutres avant spécialisation DNA. Intégrer une variante Lab manuellement après validation.

Détails préservés : [mission mouvement intégrale](../missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md), [mission finale](../missions/CLAUDE_FINAL_PASS.md), [pipeline recherche](../design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md).
