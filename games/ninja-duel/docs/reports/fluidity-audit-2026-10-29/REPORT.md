# Audit de fluidité — 29/10 (nuit)

Demande (29/10, 02 h 06 puis 02 h 17) : « on parle de vrais bugs », « je pouvais plus bouger », « audit tout ce qui pourrait impacter la fluidité gameplay ».

## Méthode

Trois relecteurs indépendants ont lu le code, chacun sur une partie, sans rien modifier :
- le trajet d'une touche jusqu'au serveur ;
- les états du perso côté serveur ;
- l'affichage côté client.

Pour mesurer, un joueur manette scripté affronte la vraie IA avec les 8 persos principaux (`tests/Control.sim.luau`). Il court, enchaîne, martèle une touche, saute et frappe en redescendant, esquive et lance des jutsu. Chaque pression passe par la même porte que celle du jeu (anti-triche), puis par `Combat:request`.

Ce que la mesure relève :
- **pressions mangées** : refusées moins de 0,25 s avant que le corps redevienne libre, sans que rien ne sorte ;
- **freezes** : stick tenu, état neutre, rien ne retient le corps, et il ne bouge pas ;
- **faux « en l'air »** : le corps est au sol mais le jeu le croit en l'air ;
- **états figés** : le même état plus de 2 s ;
- **temps en réaction**.

## Mesures (48 min de jeu simulé, 8 persos)

| | avant | après |
|---|---|---|
| pressions mangées | 7 % (~12 par minute) | 2 % (reste : pressions faites pendant un stun plus de 0,12 s avant la fin, voulu) |
| faux « en l'air » au sol | 137 (sans le correctif d'atterrissage) puis 13 | 0 |
| freezes, états figés | 0 / 0 | 0 / 0 |

La partie headless de cette mesure est maintenant dans la release (`tests/Control.spec.luau`).

## Causes trouvées et corrigées (test qui la tient : `tests/Fluidity.spec.luau`, 12 tests qui échouaient tous avant)

1. **Le stick ne marchait qu'en état neutre** (`Place1Movement`).
   - En garde, en canalisation et en récupération, le corps était freiné à 0.
   - Les vitesses prévues (garde 8, canalisation 7, marche en attaquant 14) ne servaient jamais.
   - Maintenant on se déplace en garde, en canalisation, et en récupération une fois passé le point d'annulation (là où garde, esquive et saut sont déjà permis).
   - Le bot garde sa garde plantée, comme il a été réglé.
2. **L'atterrissage n'était détecté que dans `Motor.step`**, sauté pendant les coups, les stuns, l'esquive et l'arrêt sur coup.
   - Le corps restait « en l'air » au sol, et le maintien aérien le figeait.
   - Corrigé par `Motor.settle`, appelé à chaque image.
   - Ce correctif posait le chase dès sa 1re image : chaque départ en l'air a maintenant 0,15 s de grâce.
3. **Anti-triche** : un écart minimal de 0,42 s entre deux dodges, 0,24 s entre deux heavy et 0,55 s entre deux saisies.
   - Il comptait aussi une pression refusée par le combat, donc la 2e pression était jetée sans rien dire.
   - Écarts ramenés sous ce qu'une main peut faire (0,05–0,07 s).
   - Le stick a aussi son propre budget réseau : jusqu'à 30 paquets par seconde à la manette, qui vidaient celui des touches.
4. **Pas de mémoire des touches**, sauf coup léger, lourd et saisie pendant un coup.
   - Ajouté `Config.Late` : une pression refusée parce que le corps est occupé sort à la 1re image libre.
   - Elle reste valable 0,2 s après son propre engagement, 0,12 s à la fin d'un stun, et couvre le relevé après un K.-O. au sol.
   - Joueurs seulement : l'IA planifie elle-même.
5. **Saut refusé « Airborne » debout** : une fois le point d'annulation d'un coup passé, le saut repartait d'un état non neutre et le saut au sol le refusait.
6. **Suspension après un chase.**
   - L'arrivée gardait tout le maintien du chase, jusqu'à 1 s.
   - Une esquive aérienne ne l'annulait pas.
   - Un coup sauté près d'un corps en l'air se figeait : `Motor.flight` remettait sa vitesse à 0 à chaque image, même sans maintien.
7. **Boucle garde → stun → garde** : la garde tenue se relevait toute seule à 8 d'endurance. Elle attend maintenant 30.
8. **Les réactions aériennes finissaient sur un minuteur.**
   - Le corps s'arrêtait net en l'air, puis tombait.
   - Une chute au sol se relevait en l'air.
   - Maintenant la vitesse de vol est transmise, et le relevé attend le sol.
9. **Un coup lancé au réveil ne pouvait pas toucher**, et un dodge pendant le relevé était refusé comme « substitution ». Les deux sortent maintenant après le relevé.
10. **Embardée après un stun** : l'élan d'un coup en courant restait en mémoire. Un coup reçu l'efface.
11. **Manette :**
    - R1 tenu en choisissant un jutsu chargeait du chakra : le seuil passe à 0,5 s, et un jutsu consomme la charge ;
    - × décidait « chase » d'après un état vieux d'un aller-retour : c'est maintenant `PadJump`, que le serveur résout, et si le chase est refusé on saute ;
    - les techniques tenues se chargeaient toujours à fond : le relâchement est maintenant envoyé.
12. **Nouveau round** : les touches tenues étaient oubliées. Elles sont relues (`Input:resync`).
13. **Gaara : un léger au corps à corps était le Pilier de sable** (le lanceur). Un léger de près n'est plus jamais un lanceur par défaut.
14. **Caméra :**
    - elle perdait le corps au K.-O. : les racines ancrées n'étaient pas suivies ;
    - elle fouettait quand les deux persos étaient l'un sur l'autre ;
    - elle changeait de cadre entre deux coups aériens : un cadre est maintenant gardé au moins 0,4 s ;
    - en lock, une poussée du stick droit ne revenait jamais.
15. **Coût client** : GaleFX, IdentityFX et le voile de Wave1 tournaient deux fois par image. L'état réseau envoyait les 80 compteurs d'événements 30 fois par seconde ; il n'envoie plus que les 4 que le client lit.

## Pourquoi on stagnait

- **Mes tests ne jouaient pas comme un joueur.** Ils appellent `Combat:request` directement : pas d'anti-triche, pas de réseau, pas de manette, une physique simulée. Les causes 3, 11 et 12 leur échappaient par construction.
  - La mesure joueur (`Control.spec`) passe maintenant par la porte d'entrée.
  - Restent hors de portée du headless : le réseau réel et la physique Roblox. Il faut tester en Studio avec une latence simulée.
- **Trois suites existaient hors de la release**, dont Mouvement. `CombatFeel` échouait depuis le 28/10 sans que personne ne le voie. Elles sont maintenant dans la release.
- **Aucune autorité unique ne décide « est-ce que je peux bouger ou agir ».** On compte 37 minuteurs `*Until` différents sur un perso et 188 écritures directes de son état côté serveur. Chaque correctif ajoute un cas, et les cas se contredisent ; les causes 2, 5, 6 et 9 en viennent toutes.
  - Prochain chantier proposé : une fonction `Control.of(a)` qui dit, pour chaque image, si le perso peut se déplacer, à quelle vitesse, et quelles actions sont permises. Tous les systèmes la lisent, et les tests la vérifient.
- **On a poli les animations avant de mesurer la fluidité.** La mesure existe maintenant et bloque la release.

## Restent ouverts (pas encore corrigés)

- **Prédiction locale limitée** au léger et au lourd, et elle se trompe sur les routes, les aériens et les coups lourds propres à chaque perso. Les dodges, sauts et gardes n'apparaissent qu'après l'aller-retour serveur. Invisible en Studio (ping ≈ 0), sensible en ligne.
- **Pose et position désynchronisées** : les poses partent de l'état réseau, sans tampon ; les positions passent par la réplication Roblox, avec 45 ms de lissage en plus.
- **Coût des effets** : un coup lourd crée 30 à 80 objets en une image (sprites scriptés, sans limite ni recyclage), et les afterimages d'un dash sont doublées.
- **Routes au stick mémorisé** : avancer en martelant le léger lance au 3e coup, parce que la poussée vers l'avant est retenue 0,22 s. C'est une décision de design à prendre avec l'utilisateur.
- **Corps qui se chevauchent au contact** : à mesurer.
