# Mission FEEL — journaux bruts AVANT

Copies des sorties Studio (instance `558350fe`, ND-Test-travail Debug, code `02b3381`).

## Prise 1 (OBS lancé à 19:05:50 heure de Paris)

Temps vidéo = t0 + t client − 18:05:50 UTC, avec t0 client = 1793901933,45. Le temps serveur `DevFlight` vaut environ le temps client + 33,7 s.

### Serveur : chaque appui et son verdict (`DevFlight.inputs`, 57 entrées)

```
42.61 GuardOff GATE st=Neutral re=Juggled air=true age=473
100.59 Dodge ok st=Dodging
101.12 PadJump ok:Airborne air=true
101.42 JumpOff ok air=true
102.84 PadJump ok:Airborne air=true
103.04 JumpOff ok air=true
103.29 Attack ok st=Startup air=true
138.87 Dodge ok st=Dodging
139.32 PadJump ok:Airborne air=true
139.60 JumpOff ok air=true
141.10 PadJump ok:Airborne air=true
141.30 JumpOff ok air=true
141.55 Attack ok st=Startup air=true
179.08 Attack refused:Reacting re=HitStun
179.42 Attack refused:Reacting re=HitStun
179.77 Attack ok:Buffered st=Recovery
180.33 Heavy ok:Buffered st=Recovery
181.12 Dodge refused:Committed st=Active
182.23 Attack ok st=Startup
182.55 Attack ok:Buffered st=Recovery
182.87 Attack ok:Buffered st=Active
183.18 Attack ok:Buffered st=Recovery
183.90 Technique2 ok st=TechniqueChannel
184.00 SealRelease dropped
185.22 Guard refused:Committed st=TechniqueActive
186.13 GuardOff dropped
186.13 Attack ok st=Startup
186.45 Attack ok:Buffered st=Recovery
186.78 Heavy refused:Reacting re=HitStun
187.69 Dodge ok st=Dodging
188.29 Attack refused:Reacting re=HitStun
188.61 Attack ok st=Startup
188.92 Attack ok st=Startup
189.24 Attack refused:Committed st=Recovery
189.55 Attack ok:Buffered st=Recovery
190.57 Dodge ok st=Dodging
191.08 Attack ok st=Startup
191.40 Attack ok:Buffered st=Recovery
191.73 Heavy ok:Buffered st=Active
207.00 Attack ok st=Startup
207.43 Attack ok st=Startup
207.88 Heavy ok st=Startup            <- S3a : 2 coups puis L2+△ (Heavy chakra)
211.68 PadJump ok:Airborne air=true
211.80 JumpOff ok air=true
238.25 Technique1 ok                  <- S3b : kunai marqué (Minato)
238.35 SealRelease dropped
239.25 Technique3 ok st=TechniqueChannel  <- FTG
239.36 SealRelease dropped
239.56 Attack ok st=Startup
239.92 Attack ok st=Startup
240.28 Attack ok st=Startup
242.40 Technique1 ok
242.51 SealRelease dropped
243.43 Technique3 refused:Cooldown
243.53 SealRelease dropped
243.71 Attack ok st=Startup
255.82 GuardOff GATE age=301
```

### Serveur : gels (stick tenu, corps vivant, vitesse nulle ≥ 0,3 s)

```
t=99.91  lasted=1.00 Neutral y=3   ws=45   (juste après un déplacement par l'outil dev)
t=138.21 lasted=0.95 Neutral y=2.99 ws=45  (juste après un déplacement par l'outil dev)
t=178.68 lasted=0.68 Neutral y=2.99 ws=18.5
t=182.01 lasted=0.51 Neutral y=2.99 ws=18.5
```

`worstDt` serveur : 0,999 s.

### Client : caméra

12 000 images, 27,7 i/s en moyenne (Studio passait en arrière-plan). L'adversaire est hors cadre sur 252 images et au bord sur 29 ; le joueur est hors cadre sur 116 images.

Séquences de plus de 0,25 s avec l'adversaire hors cadre (temps client) : 142,8–143,4 ; 145,8–146,4 ; **174,7–176,5 (lancer chakra de Neji, ≈1,8 s)** ; 196,5–197,6.

### Client : S3b, Minato (temps client)

```
204.63 cue=Marked Kunai
204.95 bot Stunned, cue=SEAL ON TARGET • 2 TO FOLLOW
205.63 TechniqueChannel FTG
205.98 Startup / Light1 / FlashStrike
206.02 bot HitStun, hp 126 -> 121 ; Light2 -> 115 ; Light4 -> 113
208.80 second kunai -> sceau
209.83 cue=COOLDOWN
210.10 AngleStep touche -> 106
caméra : 566 images, adversaire hors cadre 0
```

### Sans rendu (`tools/feel/novice.luau`, Lune)

- Neji, 2 coups puis L2+△ : Launcher chargé au chakra, impulsion Vacuum ×1,5 ×1,2. Hauteur 66 studs (Heavy normal : 20,6), 2,44 s en l'air.
- Novice contre IA facile ou normale : ≈30 % des appuis refusés, surtout Committed. Il gagne en 12–14 s (sans rendu seulement).

## Prise 2 (OBS profil ND-FEEL, lancé à 19:22:52)

### S1, corps en mouvement (Neji ; bot figé à (0,3,125) ; départ (0,3,60) ; R3 pour verrouiller)

Entrées client, en secondes depuis le repère :

```
0.45+ButtonR3 0.56-ButtonR3 1.77+W 1.77+LeftControl 2.28+D 2.59+ButtonB 3.04-ButtonB 3.45-D
3.86+ButtonA 4.14-ButtonA 5.09+ButtonA 5.33-ButtonA 5.66+ButtonX 5.77-ButtonX 6.45-W 6.45+S 7.88-S 7.88-LeftControl
```

Images client de plus de 50 ms : **2.98 s : 379 ms** (juste après l'appui d'esquive), 3.05 : 73, 3.15 : 50, 3.24 : 117, 4.86 : 92, 5.67 : 89, 5.74 : 54.

Verdicts serveur : Dodge **GATE, âge 402 ms** ; 2 sauts ok ; Attack **GATE, âge 403 ms**. Gel de 0,39 s en l'air contre le mur, bloqueurs « Boundary, Boundary ».

États :

```
0.02  Neutral au sol, (0,3,60)
3.94  Neutral en l'air, (6,4.9,105)
5.30  au sol (9,2.9,121) ; 5.46 en l'air (7,5.6,129) ; 6.09 au sol (-3,2.8,137)
7.26  WALL RUN • SPACE REBOUND / C DETACH, wall=true, (-11,3.4,143)
8.29  au sol (-11,3,142)
```

Caméra, joueur / adversaire / distance de la caméra au joueur (2 = bien dans le cadre, 0 = hors cadre), toutes les 0,5 s :

```
0.0 2/2/15 ... 6.5 2/2/13 | 7.0 0/2/9  7.5 0/2/9  8.0 0/2/10 ... 9.5 0/2/9
```

Joueur hors cadre de 7,00 à 11,99 s : 100 % des images.

### Banc saturé (non comptés comme défauts du jeu)

- Ensuite, appuis réels au clavier et via le plugin : âges de 1006, 2417, 3197, 4666 et 6088 ms.
- OBS, profil ND-FEEL : 89,3 % d'images ignorées (retard d'encodage).
