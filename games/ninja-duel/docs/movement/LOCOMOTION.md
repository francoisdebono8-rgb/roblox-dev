# Mouvement — contrat actif

IDs : MOV-001 à MOV-005, COM-002/003, CAM-002, RES-001. Implémentation : `src/Server/Motor.luau`, Place1Movement/Place1Parkour, Animation, `src/Client/Presentation.luau` et VelmoraMotionEngine. Les tests prouvent des routes/valeurs, pas la crédibilité des appuis.

## Exigences cumulatives

Course avant/arrière, vraie course latérale gauche/droite, diagonales, retournements et changements de vitesse ; orbit/reentry/poursuite/sprint lisibles. La tête et le torse peuvent suivre partiellement l’adversaire pendant que le bassin et les jambes suivent le déplacement. Ne pas appliquer une simple pose tournée qui fait glisser les pieds.

Cadence et amplitude suivent la vitesse réelle ; pied posé et jambe de poussée cohérents. Centre de gravité, balancement et transfert bassin/torse rendent freinage, feinte et accélération compréhensibles. Dash vient d’un appui et d’une impulsion, avec réception/recovery, pas d’un root qui glisse sous une statue.

Saut : anticipation/poussée, ascension, apogée, chute, landing et reprise. Même règle en attaque, knockback, air pursue, slam, wall run/jump/rebound/detach/mantle. Les états changent sans cuts ou membres figés. Reproduire jumpattack/attackjump, launcher chase, repeated input, vertical camera et landing avant de rouvrir un ancien bug.

Frappes : pied d’appui → hanches → torse → épaule → membre → transfert de poids → followthrough → recovery. Jab/cross/hook/uppercut/elbow/knee/kicks/sweep/spin360/projection/air/wall ont des chaînes physiques différentes. Corps réactif aussi en défense, prise, throw, réception, KO et retour neutre. Ne pas couvrir un contact décalé avec un effet lumineux.

Quatre expressions : Minato vif et orienté angles ; Itachi calme/précis/minimal ; Neji paumes/rotation/appuis circulaires ; Sasuke agressif/kicks/air/mix range. La continuité compte plus qu’un nombre de clips ou un nouveau système d’animation.

## Acceptation

Capture avant/après native pour huit directions et chaque transition clé, vitesse normale puis ralenti ; observer pieds/hanches/contact/cible, tester duel/manette/caméra. Conserver les timings gameplay durant une correction de présentation sauf changement approuvé et testé. Comparer les mêmes scènes et profils neutres avant spécialisation DNA. Intégrer une variante Lab manuellement après validation.

Détails préservés : [mission mouvement intégrale](../archive/missions/CLAUDE_MOVEMENT_SYSTEM_FINAL_FIX.md), [mission finale](../archive/missions/CLAUDE_FINAL_PASS.md), [pipeline recherche](../../design_research/04_research/MOVEMENT_SOURCE_PIPELINE.md).
