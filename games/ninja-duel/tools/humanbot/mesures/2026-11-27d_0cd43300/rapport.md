# Le robot humain

13 min de jeu : 52 clics et 41 touches, 1 boutons qui ont répondu ; 0 commandes du profil côté serveur, 0 refusées.
Coups de rue pressés par le code du jeu : 9 (9 pendant que le corps pouvait frapper).

## corps bloqué — le corps poussé par les touches ne bouge pas

| quoi | combien de fois | à l'écran | les gestes juste avant |
|---|---|---|---|
| 80,-2160 | 2 | le jeu (W tenu au sol contre une maison : on ne grimpe qu'en l'air) |  |
| 152,-2160 | 3 | le jeu |  |
| -48,-2520 | 1 | le jeu |  |
| -104,-2496 | 4 | le jeu |  |

## à-coup — une image de plus de 0,5 s

| quoi | combien de fois | à l'écran | les gestes juste avant |
|---|---|---|---|
| 1 | 1 | le jeu (au début du duel des ruelles) |  |
| 0.5 | 1 | le jeu |  |

Images longues : 14 de 0.4 s ou plus (la plus longue 1.06 s), une toutes les 38.9 s en moyenne.

## Les murs

En ville : court le long (gauche) 5, monte le mur 4, passe le haut 4, court le long (droite) 2, appel sur le mur 2, saut 2, debout sur le mur 2.
En duel : 11 fois debout sur un mur (de 0.4 à 8.1 s) ; 1 fin(s) sur un coup reçu.
Maisons ouvertes : 24 (énergie 20 à 89.6).
- En ville, debout sur le mur : 2 fois sur 6 courses, seulement en sautant à côté d'un long mur puis en tournant le stick dedans à la fin de la course le long. Garder le stick dedans fait monter et passer le haut en 0,3 s.
- Courir droit dans une maison de 15-18 studs : on monte et on passe sur le toit (la montée fait 36 studs) ; au sol, W contre un mur ne grimpe pas.
- En duel : l'IA se tient sur le mur 8 s au ras du sol (y 3,5) et frappe dans le vide ; elle a frappé 8 s depuis le mur le joueur perché au-dessus, sans qu'aucun coup ne touche dans un sens ou l'autre.
- Le seul coup reçu sur le mur (le joueur tombe sur l'IA) l'a fait quitter le mur aussitôt.
- 24 maisons ouvertes en deux duels : 8 par le corps du joueur projeté, 16 par des coups de l'IA qui touchaient le mur (WorldReaction.impact ouvre une maison à chaque coup assez fort, corps ou coup).


## Ce que les mains ont vu (Claude, pas François)

Place : copie de la place commune (0cd43300, BUILD 021aa681, RUNTIME 2789def3, profil capture) dans `LAB/robots/NinjaDuel-P4-robots.rbxlx`, Studio au second plan, clavier injecté par Studio. TECHNICAL : mesuré ou vérifié dans le serveur / le code. HUMAN_VISUAL_FEEL : lu à l'écran.

### En ville
1. HUMAN_VISUAL_FEEL — **courir le long d'un mur marche tout seul** : en courant à côté d'une maison, la course le long part même au sol (image 36). Le saut pendant la course est un appel du mur vers l'autre côté de la ruelle.
2. TECHNICAL — **monter un mur** : il faut être en l'air (W contre une maison au sol bloque le corps : 10 « corps bloqué »). Sur une maison de 15 à 18 studs, la montée (36 studs en 0,95 s) passe le haut et pose sur le toit (image 37) : on ne s'y tient jamais.
3. TECHNICAL — **se tenir sur le mur** : 2 fois sur 6 essais, seulement en sautant à côté d'un long mur (ExamHallWest, 55 studs) puis en tournant le stick dedans juste à la fin de la course le long. Garder le stick dedans fait monter et passer le haut en 0,3 s ; le lâcher, on tient 6 s puis on tombe (image 38). Rien à l'écran ne dit comment faire (la barre du bas : SHIFT RUN • SPACE TWICE: LEAP • E TALK • B DUELS).
4. HUMAN_VISUAL_FEEL — debout sur le mur, le corps est à l'horizontale, en garde, les pieds sur le mur : l'image est belle de côté (image 38). Les 9 coups pressés là-haut partent (live).

### En duel de rue (THE HARD WORKER, les ruelles)
5. HUMAN_VISUAL_FEEL — **la caméra ne suit pas dans les ruelles** : collée contre une façade, dans la maison qui s'efface, ou bouchée par un mur ; les deux corps hors de l'image (images 40, 41). Sur les toits et quand le joueur est perché, l'image redevient bonne (images 42, 43).
6. TECHNICAL — **l'IA se tient sur le mur au ras du sol** (y ≈ 3,5, 8 s de suite, 7 fois) et frappe dans le vide. Perchée sur le mur sous le joueur posé sur un auvent, elle a frappé 8 s sans qu'aucun coup ne touche, dans un sens comme dans l'autre.
7. TECHNICAL — **le combat ne continue pas là-haut** (0cd43300) : le seul coup reçu par un corps debout sur le mur (le joueur tombe sur l'IA) l'a fait quitter le mur aussitôt. C'est ce que le DEV change dans cette passe.
8. HUMAN_VISUAL_FEEL — **les maisons s'ouvrent** (image 44 : plâtre, planches, une fissure au sol) : 24 trous en deux duels, 8 par le corps du joueur projeté, 16 par des coups de l'IA qui touchaient le mur (WorldReaction.impact ouvre à chaque coup assez fort). Le corps du joueur a aussi été poussé dans une fente de 2 studs entre deux maisons, d'où la caméra ne voyait plus rien.
9. TECHNICAL — l'écran de défaite nomme les maîtres à venir par leur titre (THE LOUDMOUTH, THE PERFECT BROTHER, THE COPYCAT) : le correctif du DEV (`d868666a`) tient (image 45).

### Fluidité pour filmer
10. TECHNICAL — **chaque capture de Studio gèle l'image 0,47 s** : 60 s sans capture, rien au-dessus de 0,3 s ; deux captures, deux images de 0,48 et 0,47 s ; 15 captures pendant la passe, 15 images de 0,39 à 0,55 s. Les « à-coups » de 0,45 s de mes mesures depuis le 27/11 sont donc surtout les miens. Le témoin a maintenant `W.shot()`, et le rapport retire l'image qui suit.
11. TECHNICAL — **micro-profileur, 8,5 s de duel dans les ruelles** : 59 images simulées par seconde, médiane 16,6 ms, 99 % sous 18,6 ms ; **une image de 145 ms, toute dans le son** (updateFmod 134 ms, update3dListenerAttributes 72 ms). Les sons des maisons qui cassent (HouseBreakFX) et des coups (StrikeSoundFX) sont créés à la volée sans préchargement : piste, pas preuve.
12. TECHNICAL — **Studio au second plan ne dessine que 14,8 images par seconde** (le profileur le dit) : un tournage OBS d'une Studio qui n'est pas devant saute forcément.
13. Une seule image d'1,06 s hors capture, au début du duel des ruelles.
