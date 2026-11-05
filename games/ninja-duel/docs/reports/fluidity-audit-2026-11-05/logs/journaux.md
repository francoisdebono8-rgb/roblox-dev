# Audit de fluidité du 5 novembre 2026 : journaux bruts

Studio, instance `7ed5fe09`, ND-Test-travail, code `daff77d`. Duels IA contre IA : `devcall("start", joueur, bot)`, puis `autopilot` et `freezeBot false`, pendant 40 à 48 s. Le premier perso est le corps « joueur » (piloté par l'IA), le second est le bot.

Légende :
- `snap` : cassure de vitesse > 650 studs/s² en mouvement libre ;
- `limb` : main ou pied qui saute de plus de 0,9 stud par rapport au torse ;
- `pop` : saut du corps ;
- `slide` : vitesse dessinée loin de la vitesse serveur ;
- `cam.jump` : objectif qui bouge de 2,5 studs de plus que le corps ;
- `where` : transitions d'état (avant → après) les plus fréquentes.

Les durées de `fps` des versions mesurées comptaient aussi le temps hors duel : seuls les dt (p50, p95, p99) font foi. La sonde du dépôt corrige ce calcul.

## A. Sasuke (joueur) contre Naruto (bot) n°1

```
frames 2810 / 50 s, dt p50 16.7 p95 19.5 p99 21.7 max 47 ms, >50 ms 0
human.snap x469 | worst 5062 studs/s² (Neutral -> Neutral) | where: Neutral -> Neutral x387, Guarding -> Guarding x44, Neutral air -> Neutral air x21, Neutral -> Guarding x6
bot.snap x186 | where: Neutral -> Neutral x166
human.limb x137 | worst LeftFoot 2.79 studs in 19 ms (TechniqueChannel) | where: Neutral -> Neutral x99, Startup:WallDive air x4, Stunned x4, Active:Sweep x4
bot.limb x94 | worst RightHand 2.25 studs in 28 ms (Neutral) | where: Neutral -> Neutral x60, Active:DashAttack x8, Stunned x6, Dodging x5
human.pop x16 | worst 2.75 studs in 16 ms (Neutral -> Neutral air) | where: Active:WallDive air x10
human.slide x7 (drawn 2.4 / server 48.0) ; bot.slide x6 ; bot.offscreen x2 ; bot.pop x2 (WallDive air)
```

## B. Gaara (joueur) contre Lee (bot) n°1 (≈117 s de duel, dont l'attente bot figé)

```
frames 7028, dt p50 16.7 p95 19.2 p99 21.5 max 33 ms, >50 ms 0
human.snap x1506 | worst 11104 studs/s² (Pursuit:SandFist -> Neutral) | where: Neutral -> Neutral x1344, Guarding -> Guarding x95, Neutral air -> Neutral air x22, Neutral -> Guarding x8
bot.snap x783 | worst 6589 (Neutral air -> Neutral air) | where: Neutral -> Neutral x710, Neutral air x28, Guarding x23, Stunned -> Neutral x4
human.limb x310 | worst LeftHand 2.84 studs in 18 ms (Neutral) | where: Neutral -> Neutral x200, Rush x11, Active:DashAttack x9, Recovery:DashAttack x6
bot.limb x247 | worst LeftHand 3.01 studs in 16 ms (Recovery) | where: Neutral -> Neutral x146, Stunned x14, Active:DashAttack x13, Recovery x12
bot.slide x28 | worst drawn 62.5 / server 13.3 studs/s (Neutral)
human.slide x18 | worst drawn 4.9 / server 49.5 studs/s (Neutral)
bot.offscreen x14 | worst head at -354,353 (Neutral) | Neutral x9, Recovery x2, Neutral air x1, Guarding x1
cam.jump x14 | worst lens 18.0 studs vs body 0.1 (Neutral r:HitStun air) | where: HitStun x6, HitStun air x4, HitStun -> HitStun air x2, Knockdown x2
bot.pop x1 | 2.57 studs in 19 ms (Neutral air)
```

## C. Neji (joueur) contre Minato (bot)

```
frames 2818 / 50 s, dt p50 16.6 p95 19.0 p99 20.1 max 85 ms, >50 ms 1 (Rush | Neutral)
human.snap x637 | worst 4233 (Neutral r:Launched air -> Neutral air) | where: Neutral -> Neutral x584, Guarding x25, Neutral air x12, TechniqueRecovery -> Neutral x3
bot.snap x426 | worst 5628 (Neutral) | where: Neutral -> Neutral x358, Neutral air x52, Guarding x4, Dodging -> Neutral x3
human.limb x94 | worst LeftFoot 3.02 studs in 18 ms (TechniqueChannel) | where: Neutral x50, Active:DashAttack x12, Stunned x6, Rush x4
bot.limb x67 | worst LeftHand 2.31 studs in 17 ms (Neutral) | where: Neutral x46, Recovery:DashAttack x5, Recovery x3, Active:DashAttack x3
bot.slide x11 (drawn 10.6 / server 54.0) ; human.slide x4 ; bot.offscreen x4 ; human.offscreen x1 (Knockdown)
```

## D. Itachi (joueur) contre Kakashi (bot)

```
frames 2708 / 48 s, dt p50 16.7 p95 18.8 p99 19.9 max 120 ms, >50 ms 1 (Dodging | Neutral)
human.snap x433 | worst 9424 (Pursuit:Throw -> Neutral) | where: Neutral -> Neutral x348, Neutral air x36, Guarding x23, Neutral -> Neutral air x5
bot.snap x153 | worst 5261 (Neutral) | where: Neutral -> Neutral x126, Neutral air x22
human.limb x105 | worst RightHand 2.86 studs in 17 ms (Neutral) | where: Neutral x49, Active:DashAttack x19, Neutral air x8, Recovery:DashAttack x4
bot.limb x39 | worst RightHand 2.33 studs in 15 ms (Startup:WallDive air)
bot.pop x6 | worst 2.40 studs in 19 ms (Active:WallDive air) | all Active:WallDive air
cam.jump x4 | worst lens 11.1 studs vs body 0.0 (Recovery) | all Recovery
human.slide x7 ; bot.slide x6 ; bot.offscreen x6 (head at 1398,302, Neutral air wall) ; human.pop x3
```

## E. Minato (joueur) contre Gaara (bot), DevProfiler actif

```
frames 3208, dt p50 16.7 p95 19.8 p99 25.5 max 121 ms, >50 ms 2
human.snap x709 | worst 9616 (Neutral) | where: Neutral -> Neutral x590, Neutral air x72, Guarding x22
bot.snap x226 | worst 5405 (Neutral) | where: Neutral -> Neutral x204
human.limb x122 | worst RightHand 2.75 studs in 14 ms (Neutral) | where: Neutral x71, Startup:Heavy x17, Active:DashAttack x5, Startup:Light2 x3
bot.limb x60 | worst RightHand 2.41 studs in 17 ms (Neutral r:HitStun air)
human.slide x16 | worst drawn 86.9 / server 18.5 studs/s (Neutral)
bot.slide x5 (drawn 80.4 / server 38.2) ; human.pop x6 ; bot.offscreen x5 ; human.offscreen x1 ; human.freeze x1 (server 32.6 studs/s, drawn 0)
```

DevProfiler (41 s, ms par appel) :

```
client.frame        p50 16.69  p95 19.08  max 82.95
client.presentation.update  moyenne 1.08  p95 4.43  max 22.98
client.presentation.smoothStep  moyenne 0.38  p95 0.94  max 7.22
client.presentation.impacts  moyenne 0.14  p95 1.75  max 11.92
client.fx           moyenne 0.69  p95 3.94  max 10.08
client.camera       moyenne 0.17  p95 0.33  max 8.27
client.hud          moyenne 0.37  p95 1.21  max 5.27
client.snapshot.gap p50 35.8  p95 67.1 ms   ; snapshot.age p50 40.3  p95 76.5 ms
client.bot.presentationGap  p50 0.12  p95 1.85  max 10.35 studs (bot dessiné derrière le serveur)
client.human.presentationGap p50 0  p95 0.11  max 6.24 studs
visual-position-jump : 6 sur 7 aux téléportations de Minato (warp déclaré) ; 1 sans warp : joueur 7,7 studs en 25 ms, Neutral (cause non identifiée)
server.combat       moyenne 0.33  p95 0.84  max 5.99
server.matches      moyenne 0.51  p95 1.39  max 8.46
server.snapshot     moyenne 0.16  p95 0.49 ; 5,3 Ko estimés par paquet
server.snapshot.gap p50 38.2  p95 51.4 ms
server.root.sampleDelta p50 1.36  p95 5.84  max 44.1 studs
server.destroy      22.3 ms (fin de duel)
```

## F. Sasuke contre Naruto n°2 : serveur contre affichage

Mac ralenti pendant ce duel (dt p95 66 ms, 160 images > 50 ms) : les images lentes ne sont pas retenues ici.

```
serveur (sonde serveur, 2398 battements) : cassures du trajet réel, tous états : joueur 102, bot 98
client (sonde diagnostic, 1993 images), tous états :
  joueur : corps dessiné 750 cassures | 1112 paquets au sol, saut du tracé à l'arrivée p50 0.15 p90 0.44 max 6.05 studs, > 0.18 dans 508 (46 %)
           erreur vitesse constante p50 0.08 p90 0.33 | écart de vitesse p50 0.3 p90 6.0 | âge p50 32 ms
  bot    : corps dessiné 436 cassures | 1064 paquets, saut p50 0.10 p90 0.41 max 4.99, > 0.18 dans 400 (38 %)
           erreur p50 0.06 p90 0.28 | écart de vitesse p90 4.6 | âge p50 32 ms
paquets : écart serveur p50 33.5 p95 49.9 ms
sonde corps : human.snap x267, bot.snap x95, cam.jump x8 (18.0 studs, HitStun air)
```

## G. Gaara contre Lee n°2 : articulations et orientation

```
2809 images
human.facing x174 | 71° in 18 ms (Rush -> Rush) || 68° in 20 ms (Guarding -> Rush) || 57° in 18 ms (Neutral)
bot.facing x44 | 42° in 15 ms (Startup:GreatWhirlwind) || 34° (Rush) || 34° (Rush)
bot.joint RightHip x45 | 170° in 18 ms (Startup:DashAttack) || 111° in 16 ms (Startup:KneeStrike)
bot.joint RightKnee x103 | 141° in 18 ms (Startup:DashAttack) || 49° (TechniqueChannel)
bot.joint LeftKnee x80 | 130° in 16 ms (Startup:KneeStrike)
bot.joint RightAnkle x70 | 117° in 16 ms (Startup:KneeStrike) || 98° in 18 ms (Neutral) || 97° in 18 ms (Neutral r:HitStun)
bot.joint LeftHip x61 | 89° in 16 ms (Startup:KneeStrike)
human.joint LeftHip x37 | 80° in 16 ms (Startup:Light2)
human.joint LeftKnee x60 | 61° in 16 ms (Startup:Light2) || 59° (TechniqueChannel)
human.joint RightKnee x37 | 61° in 18 ms (Neutral r:Knockback)
human.joint RightAnkle x48 | 60° in 17 ms (Startup:DashAttack)
human.joint Root x23 | 61° in 17 ms (Neutral) || 55° in 18 ms (Neutral) || 54° (Startup:DashAttack)
bot.joint Root x13 | 63° in 18 ms (Recovery:DashAttack) || 61° (Neutral) || 61° (Neutral)
au plafond (37–44° par image) : human RightShoulder x38, RightWrist x16, Neck x7, Waist x7 (Neutral) ; bot LeftShoulder x38 (DeflectKick), LeftElbow x29 (GreatWhirlwind)
handWorld (frappes, attendu) : bot RightHand 3.90 studs (Active:DashAttack) ; human RightHand 2.79 (Recovery)
cam.jump : aucun dans ce duel
```

## H. Sasuke contre Naruto n°3 : caméra et orientation

```
human.facing x158 | 159° in 19 ms (Neutral -> Neutral r:HitStun) || 109° in 16 ms (Neutral air -> Startup:WallDive air) || 68° (Startup:WallDive air)
bot.facing x36 | 46° in 19 ms (Startup) || 41° (Rush) || 35° (Rush)
cam.jump x6 | 18.0 studs ; distance objectif-corps 11.7 -> 9.5 ; la ligne vers l'ancien objectif ne touche rien (HitStun air)
            || 16.7 studs ; 3.8 -> 18.3 ; ne touche rien (HitStun)
            || 16.5 studs ; 6.3 -> 14.7 ; ne touche rien (HitStun air)
human.snap x391 | worst 6480 (Pursuit:AirSpike -> Neutral) ; bot.snap x185
paquets : saut du tracé p90 0.24 max 6.71 (joueur) / 4.68 (bot) studs ; > 0.18 dans 16 % (dilué par l'attente bot figé après le duel)
dt p50 16.7 p95 18.2 p99 18.9 max 47 ms, 0 image > 50 ms
```
