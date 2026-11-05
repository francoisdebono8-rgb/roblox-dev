# Audit de fluidité — 5 novembre 2026 (soir)

Demande : « utilise tes nouveaux outils pour repérer tout ce qui casse la fluidité des mouvements, du jeu, des attaques ». Ce rapport **repère et explique** ; il ne corrige rien. Aucune ligne du jeu n'a changé.

## Méthode

| Point | Valeur |
|---|---|
| Code | `daff77d` (branche de travail Ninja Duel), ND-Test-travail, Play dans Studio, instance `7ed5fe09`, un seul Studio ouvert |
| Duels | 8 duels IA contre IA (l'outil dev `autopilot` fait jouer l'IA du jeu à la place du joueur), 45 à 120 s chacun, **les 8 persos** : Sasuke–Naruto (×3), Gaara–Lee (×2), Neji–Minato, Itachi–Kakashi, Minato–Gaara |
| Sonde corps (`tools/feel/fluidity_probe.client.luau`) | chaque image rendue : saut du corps, vitesse qui casse, membre qui saute, glissade, caméra qui saute, perso hors cadre, coup vu en retard, image lente ; chaque défaut noté avec l'état de jeu où il arrive |
| Sonde diagnostic (`tools/feel/fluidity_diag.client.luau`) | articulation par articulation (angle par image), orientation du corps, mains, caméra (que touche la ligne corps → ancien objectif), et de combien le tracé dessiné bouge à l'arrivée de chaque paquet réseau |
| Sonde serveur (`tools/feel/fluidity_server.server.luau`) | le trajet réel des corps côté serveur, avec la même règle que la sonde client, pour séparer ce que le serveur fait de ce que l'affichage ajoute |
| DevProfiler du jeu (`tool profile`) | millisecondes par fonction, client et serveur, sur un duel |

**Limites.**
- Pas de joueur humain : le corps « joueur » est piloté par le serveur. Sa prédiction locale (le corps dessiné en avance sur le stick) ne reçoit donc aucun stick, ce qui fausse un peu ses chiffres. Les chiffres du **bot** (l'adversaire, tel que tu le vois) sont la référence propre.
- Studio a un réseau presque parfait. En ligne, le défaut n°1 sera probablement plus fort (paquets plus irréguliers) : non mesuré.
- Un duel (Sasuke–Naruto n°2) a tourné pendant que le Mac ralentissait (160 images > 50 ms) : exclu des conclusions sur les images lentes, gardé pour la comparaison serveur / affichage.

## Ce qui ne casse PAS la fluidité

| Mesure | Résultat |
|---|---|
| Temps d'image | 16,7 ms médian, 18–20 ms au 95e centile, 0 à 2 images > 50 ms par duel (Studio lui-même ou mes commandes) |
| Coût du jeu, client | présentation 1,1 ms en moyenne (4,4 ms au 95e centile, pic 23 ms) ; effets 0,7 ms (3,9 au 95e) ; caméra 0,2 ms ; HUD 0,4 ms |
| Coût du jeu, serveur | combat 0,3 ms (0,8 au 95e), duel complet 0,5 ms (1,4 au 95e) |
| Coups vus en retard (> 120 ms après leur départ serveur) | **0** sur les 8 duels |
| Rythme réseau (Studio) | un paquet toutes les 33,5 ms (50 ms au 95e centile), âge à l'arrivée 32–40 ms |

Ce n'est donc pas un problème de performance. Ce qui casse la fluidité, c'est **la façon dont les corps, les membres et la caméra sont dessinés**.

## Ce qui casse, du plus visible au moins visible

### 1. Les corps avancent par micro-saccades, 30 fois par seconde

**Ce qu'on voit.** En course, en pas chassés, en tournant autour de l'adversaire : de petits à-coups continus, pas un gros saut. C'est le défaut le plus fréquent de loin.

**Mesure.**
- Cassures de vitesse (plus de 650 studs/s² en mouvement libre) : 95 à 1 500 par perso et par duel. **85 % en plein neutre** (« Neutral → Neutral »), pas pendant les coups.
- Même duel (Sasuke–Naruto n°2), même règle des deux côtés, tous états confondus :

| | trajet réel côté serveur | corps dessiné à l'écran |
|---|---|---|
| joueur | 102 cassures | **750** |
| bot | 98 cassures | **436** |

L'affichage ajoute donc 4 à 7 fois plus d'à-coups que le serveur n'en produit.
- À l'arrivée d'un paquet, le point que suit le corps dessiné saute de plus de 0,18 stud (le seuil d'un à-coup visible à 60 i/s) **dans 38 à 46 % des paquets** : 0,41–0,44 stud au 90e centile, jusqu'à 5–6,7 studs.
- Même mécanisme pour l'« élastique » : le bot dessiné prend jusqu'à 10 studs de retard sur le serveur (1,85 au 95e centile), puis rattrape à 60–87 studs/s. La sonde le voit comme une glissade (« dessiné 87 / serveur 18 studs/s »).

**Cause dans le code.** `Client/Presentation.luau` :
- `Presentation.snapshotRoot` place le corps sur la position du dernier paquet, prolongée par sa vitesse.
- Quand le paquet suivant arrive, ce point est **remplacé d'un coup**. La vitesse a changé entre-temps (virage, freinage), ou la vitesse du paquet ne correspondait pas exactement au trajet (erreur de 0,28–0,33 stud au 90e centile).
- `smoothRoot` interpole ensuite sur des échantillons pris **à chaque image** de ce point qui saute. Le retard de 45 ms de l'adversaire décale donc le saut de 45 ms, sans l'étaler.

**Correctifs possibles.**
- **A, sans latence ajoutée (recommandé)** : à l'arrivée d'un paquet, l'écart entre l'ancien et le nouveau point devient un décalage qui s'efface en 0,1 s environ, au lieu de passer en une image. Un saut de 0,44 stud devient une courbe. Écart maximal pendant ce temps : environ 0,4 stud ; les coups se calculent de toute façon sur le serveur.
- **B, le plus lisse** : interpoler l'adversaire entre deux paquets sur leur heure serveur, avec leurs vitesses (courbe de Hermite). Coût : environ 25 ms de retard en plus sur l'adversaire.
- Test qui le tiendra : rejouer dans Lune un flux de paquets enregistré (course qui tourne, à 30 Hz, avec gigue) dans `snapshotRoot`/`smoothRoot`, et compter les cassures avant / après.

### 2. Le corps pivote d'un coup

**Ce qu'on voit.** Le perso « tourne la tête du corps entier » sur une image : en ruée, en poursuite, quand il prend un coup, au départ d'une plongée murale.

**Mesure.**
- Corps du joueur qui pivote de plus de 15° en une image : 158 à 174 fois par duel, jusqu'à **57–71° en ruée**, **109° au départ de la plongée murale** et **159° en encaissant un coup**.
- Bot : 36 à 44 fois par duel, jusqu'à 34–46° (ruée, départ de technique).

**Deux causes.**
- **a. Côté affichage** : le corps du joueur prend l'orientation du **dernier paquet**, sans interpolation (`Presentation.smoothRoot`, `face=b.yaw`). Le serveur tourne pourtant progressivement : 520°/s en neutre, mais 1 440 à 2 400°/s en poursuite, en ruée et en technique (`Combat:turnToward`). À 30 paquets par seconde, cela fait des marches de 48 à 80°. Le bot est interpolé, mais sur des échantillons qui ont la même marche, d'où des marches plus petites.
- **b. Côté serveur** : il reste des orientations écrites d'un coup (`CFrame.lookAt` direct) :
  - à la réaction à un coup ;
  - au départ de la plongée murale ;
  - dans plusieurs routes de `Brawler.luau` (lignes 752, 891, 924, 1151, 1216, 1463) ;
  - dans `Combat.luau` (749, 996, 1576, 1895).
  Les téléportations (`ChakraFlow` « behind », Flashstep) peuvent rester instantanées.

**Correctifs possibles.**
- a : même traitement que la position (n°1), sur l'angle.
- b : passer les écritures restantes, hors téléportations, par `turnToward` avec une vitesse bornée. La réaction à un coup pourrait tourner en 3 ou 4 images.

### 3. Les jambes se téléportent au départ des coups de pied

**Ce qu'on voit.** Sur une image, la jambe d'appui ou la jambe qui frappe change de position d'un bloc.

**Mesure.**
- Le moteur d'animation plafonne chaque articulation à 2 200°/s, soit 37 à 44° par image. Presque tout reste sous ce plafond.
- Exceptions, toutes sur les jambes :

| Moment | Articulation et saut en une image |
|---|---|
| Lee, départ du DashAttack | hanche **170°**, genou **141°** |
| Lee, départ du KneeStrike | genou 130°, cheville 117°, hanche 89–111° |
| Gaara, départ du Light2 | hanche 80°, genou 61° |
| Bot en neutre ou en HitStun | cheville 97–98° |

**Cause dans le code.** `Client/VelmoraMotionEngine.luau`, `apply`, ligne 259 : un pied **planté** d'un clip Blender est écrit **sans plafond de vitesse** (`legDt=nil`) et recalculé à chaque image par le solveur à deux os (`legIK`). Le commentaire explique pourquoi : plafonnée, la jambe traînait à l'atterrissage et le pied glissait.

Ce qui fait bondir la cible du solveur au départ de ces coups n'est **pas encore prouvé**. Deux candidats :
- le passage d'un pied planté au chemin du coup de pied : le pied est soulevé entre 0,16 et 0,9 stud du sol mais reste au solveur ;
- la singularité du solveur quand le pied part droit devant à hauteur de hanche : le repère du genou se retourne.

Un test Lune sur la pose du DashAttack de Lee, image par image, tranchera.

**Correctif possible.** Garder l'écriture sans plafond pour les vrais atterrissages seulement, et plafonner les autres cas. Ou ajouter un fondu de 0,06 s au passage solveur ↔ clip.

### 4. La caméra coupe quand un jutsu touche (ou part)

**Ce qu'on voit.** L'objectif saute de 11 à 18 studs en une image, puis revient en douceur.

**Mesure.**
- 4 à 14 sauts par duel, toujours quand le joueur est en HitStun, Knockdown ou en récupération d'un jutsu à lui (Itachi).
- Ce n'est **pas** un mur : la ligne corps → ancien objectif ne touche rien, et l'objectif s'éloigne autant qu'il se rapproche (3,8 → 18,3 studs du corps).

**Cause dans le code.**
- Dans `Client/Camera.luau`, le suivi normal est limité à 8,7 studs par image, et le test de mur ne fait que rapprocher l'objectif.
- Le seul chemin qui saute plus loin dans un duel est donc la **cinématique de jutsu**, qui coupe entre ses plans (lignes 707–712 : « every later cut is a cut »).

C'est une coupe **voulue**, pas un bug. Mais pour la victime, elle arrive en plein combo.

**À décider (toi, à la manette).** Garder les coupes ? Ou, côté victime, ne garder que le premier plan, ou fondre chaque coupe sur 0,1 s ?

### 5. Des membres qui fouettent en neutre (au plafond)

**Mesure.**
- Épaules, poignets, cou, taille tournent à 38–44° par image en neutre : c'est au plafond du moteur, donc un geste tracé en 2 ou 3 images. Joueur : épaule droite 38 fois, poignet 16, cou 7, taille 7 par duel.
- Les hanches (articulation `Root`) tournent de 54 à 63° en une image **en neutre** : 23 fois pour le joueur, 13 pour le bot. Leur plafond est de 3 600°/s, prévu pour les saltos en l'air (ligne 166).

**Lecture.** Chaque fouet est un changement de pose sans transition : sortie de garde, kunai dégainé ou rengainé, changement de clip. C'est moins visible que les n°1 à 3.

**Correctif possible.** Plafonner les hanches plus bas hors des saltos aériens. Pour le reste, une transition déclarée entre poses : c'est le terrain d'Animation Graphs (voir plus bas).

### 6. La plongée murale dessinée plus vite qu'elle ne vole

**Mesure.** Pendant une dizaine d'images, le corps dessiné avance de 2,3–2,75 studs par image, soit 150 à 170 studs/s. Le serveur, lui, plonge à 92 studs/s, et au plus 118 en chute.

**Cause.** La plongée part entre deux paquets. Le corps dessiné reste un instant en l'air, puis rattrape à la vitesse maximale de l'affichage (`smoothStep`, plafond de pas). C'est le n°1 dans un cas extrême ; le correctif A le règle aussi.

### 7. Autres points, mineurs

- **Bot hors cadre** au moins 0,3 s : 2 à 14 fois par duel. Le plus souvent loin en neutre ou en course murale (Lee contre Gaara : 14).
- **Faux positifs écartés.**
  - « Glissades » (dessiné 5 / serveur 49 studs/s) : la vitesse de déplacement voulue par le serveur reste haute quand le corps est bloqué ; sans stick, l'autopilote aggrave ce cas.
  - « Pieds qui sautent » par rapport au torse : un pied planté au sol pendant que le corps tourne compte aussi.
  - Les deux sondes en tiennent compte dans leurs commentaires.

## Ordre proposé

1. **n°1 et n°2a ensemble** : une seule fonction (`Presentation.snapshotRoot` / `smoothRoot`), le plus grand gain, peu de risque, mesurable avant / après avec les mêmes sondes et un test Lune.
2. **n°3** : prouver la cause (test image par image du DashAttack de Lee), puis plafonner.
3. **n°2b** : les orientations écrites d'un coup côté serveur.
4. **n°4** : selon ta décision sur les coupes.
5. **n°5** : après les autres.

## Outils (règle du 05/11)

- **Utilisés** : le DevProfiler du jeu, l'autopilote dev, l'exécution Luau dans Studio (sondes client et serveur) et les trois sondes ci-dessus, ajoutées au dépôt.
- **AnalyticsService** : à brancher au moment du correctif. Compter par manche les cassures du n°1, les pivots du n°2 et les coupes du n°4, comme les appuis le sont déjà, pour mesurer en ligne ce que Studio ne montre pas.
- **Animation Graphs** : candidat pour les n°3 et n°5, avec des transitions déclarées au lieu de passages codés à la main. C'est un chantier à part, pas un correctif de cette tranche.
- **Jest Roblox, ClientCast, Input Action System, RoSentry** : non concernés par ce repérage.

Données brutes : `logs/journaux.md`.
