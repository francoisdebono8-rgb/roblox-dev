# Mission FEEL — journaux bruts APRÈS (5 novembre 2026, 21:00–21:45, heure de Paris)

Instance Studio `7ed5fe09`, ND-Test-travail (Debug). Code `42939bd`, puis `8be877c` pour `Camera.luau`, corrigé à chaud entre deux parties.

Légende :
- `meOff` / `foeOff` : images où le joueur / l'adversaire est hors cadre ;
- `Edge` : au bord (5 % de marge) ;
- `hitches` : images de plus de 50 ms.

## S1, corps en mouvement (même script que la prise 2 AVANT ; première version APRÈS)

```
0.03 Neutral au sol (0,3,60)
2.63 Rush (la ruée chakra : sprint + ○ vers l'adversaire) (7,3,88)
3.05 Recovery (-1,3,121) ; 3.53 en l'air (1,4.9,127) ; 4.40 au sol ; 4.73 en l'air
5.31 Startup/WallDive (0,10.9,120) ; 5.43 Active ; 5.60 Recovery ; 5.95 Neutral (-2,3,134)
caméra : 1019 images, foeOff 0, meOff 0, hitches 5.93 s : 56 ms
entrées : 0.40+R3 1.72+W+LeftControl 2.23+D 2.55+○ 3.47+× 4.68+× 5.26+□ 6.07-W+S 7.48-S
```

## S1b, acculé au mur (joueur (0,3,140), adversaire (0,3,110), bot figé)

```
première version APRÈS, verrouillée          : 181 images  meOff 0   meEdge 0   foeOff 0   (caméra en x 9,8 : a pivoté)
première version APRÈS, libre manette        : 241 images  meOff 241                       (pas encore de pivot en libre)
libre manette, pivot sans cadrage de la paire : 240 images  meOff 0   foeOff 209
libre manette, version finale                 : 237 images  meOff 42  meEdge 10  foeOff 0   hitches 2.06 s : 83 ms
verrouillé, version finale                    : 240 images  meOff 0   meEdge 4   foeOff 0
```

## S3a, Heavy chakra de Neji (2 □ puis L2+△, écart de 5 studs, bot figé)

```
écart de 12 studs        : Light1 dans le vide puis DashAttack puis Heavy (Knockdown) : pas de lancer
2 coups lents (0,43 s)   : Light1, Light2, Heavy (Knockdown) : la chaîne s'est refermée, pas de lancer
2 coups rapides (0,28 s) : Light1 1.30 Launcher « VACUUM PALM » ; bot Launched ; y 12.8 / 28 / 37.7 / 66.9
  première version APRÈS, libre manette : foeOff 67 (1.71–2.85 s), foeEdge 13
  verrouillé                            : foeOff 0, foeEdge 0, meOff 0 (bot à y 67,5)
  version finale, libre manette         : foeOff 0, foeEdge 0, meOff 0 (bot à y 67,5)
```

## Saut (Neji, même code avant et après)

```
appui × 80 ms  : sommet 8,13 studs au-dessus du sol, 0,62 s en l'air
appui × 400 ms : sommet 13,04 studs, 0,81 s en l'air
```

## S3b, Minato (kunai, FTG, □□□, kunai, FTG en recharge, □)

```
0.80 Marked Kunai ; 1.18 SEAL ON TARGET • 2 TO FOLLOW (bot Stunned)
1.84 FTG PREPARING ; 1.88 TechniqueActive, téléporté de z=12 à z=-15
2.25 Light1 touche ; 2.74 Light2 touche ; 3.20 Light4 touche
5.10 Marked Kunai ; 5.26 sceau ; 6.13 refus du FTG : repère COOLDOWN, ligne discrète COOLDOWN (affichée « RECHARGING »)
6.53 Light1 touche
caméra : 492 images, foeOff 0, meOff 0, aucun à-coup
```

## S2, novice Neji contre IA facile (25 appuis en 20 s)

```
Attack:ok Attack:ok/Buffered Attack:ok/Buffered Heavy:ok/Buffered Dodge:ok Attack:ok Attack:ok Heavy:ok/Buffered
Dodge:ok Dodge:refused/Cooldown Attack:ok Attack:ok/Buffered Attack:ok/Buffered Attack:ok/Buffered PadJump:refused/Committed
Attack:refused/Reacting Technique2:ok Attack:ok Attack:ok/Buffered Heavy:ok/Buffered Dodge:refused/Committed
Attack:refused/Reacting Attack:ok Attack:ok/Buffered Heavy:refused/Reacting
=> 9 joués tout de suite, 10 mis en attente puis joués, 6 refusés, 0 GATE
lignes discrètes : COOLDOWN 6.3–6.8 s ; BUSY 9.7–10.3, 13.6–14.1, 15.0–15.6, 16.2–16.7 s
caméra : 1099 images, foeOff 0, meOff 15, meEdge 4, aucun à-coup
```

## Appuis en retard : latence simulée de 350 ± 80 ms (outil dev `lag`), 6 appuis □ ○ □ △ ○ □

```
logique AVANT (rétablie le temps de la mesure) : Attack:GATE/âge 342  Dodge:GATE/âge 390  Attack:GATE/âge 409
                                                 Heavy:GATE/âge 450   Dodge:GATE/âge 387   Attack:GATE/âge 354
logique APRÈS                                  : Attack:ok Dodge:ok Attack:ok Heavy:ok Dodge:refused/Committed Attack:ok
```

## OBS

- Profil ND-FEEL (1470×956, H.264 matériel) avec un seul Studio ouvert : 51 images ignorées sur 4256 (1,2 %), 11 manquées sur 5402 (0,2 %).
- Mais l'image est noire (aperçu noir, 2,1 Mo pour 70 s) : `FEEL/_junk/`.
- OBS a été remis sur le profil « Sans nom ».
