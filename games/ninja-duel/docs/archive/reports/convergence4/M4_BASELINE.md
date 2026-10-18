# M4 — baseline de la grille (sans retuning)

Source : HEAD courant + instrumentation M4 (push mesuré depuis le 3e contact jusqu'à la fin de la réaction ; casts distincts par événements `Cast:<Id>`). Headless, lune 0.10.5, seeds fixes. Ce ne sont pas des objectifs d'équilibrage.

```
fighter      str  dmg3  push react whiff       heavy conv      ko/tech
   conv Flashstep: E=ok A1=Air1 A2=Air2 A3=Air1
Flashstep   0.51  34.7  22.4  0.48  0.46  0.30/ 14.0    3    16s  2/1 W
   conv Mirage: E=ok A1=Air1 A2=Air2 A3=Air1
Mirage      0.56  38.2  25.8  0.48  0.47  0.30/ 15.4    3    20s  4/2 W
   conv GentleFist: E=ok A1=Air1 A2=Air2 A3=Air1
GentleFist  0.55  33.0  23.2  0.48  0.47  0.31/ 13.3    3    17s  2/1 W
   conv Lion: E=Committed A1=Air1 A2=Air2 A3=Air1
Lion        0.56  36.5  24.1  0.48  0.48  0.30/ 14.7    3    16s  2/2 W
   conv Sand: E=ok A1=Air1 A2=Air2 A3=Air1
Sand        0.82  18.9  24.1  0.48  0.70  0.27/  9.0    3    23s  3/3 W
   conv Leaf: E=Committed A1=Air1 A2=Air2 A3=Air1
Leaf        0.52  27.9  24.9  0.48  0.46  0.27/ 14.0    3    17s  1/1 W
   conv Legion: E=ok A1=Air1 A2=Air2 A3=Air1
Legion      0.56  34.7  23.2  0.48  0.48  0.30/ 14.0    3    19s  3/2 L
   conv Gale: E=ok A1=Air1 A2=Air2 A3=Air1
Gale        0.59  22.6  30.1  0.48  0.50  0.32/ 14.0    3    19s  3/1 W
   conv Lavender: E=ok A1=Air1 A2=Air2 A3=Air1
Lavender    0.55  31.9  21.5  0.48  0.46  0.30/ 12.9    3    31s  4/2 W
   conv Copycat: E=ok A1=Air1 A2=Air2 A3=Air1
Copycat     0.55  35.4  23.2  0.48  0.47  0.30/ 14.3    3    23s  4/2 W
   conv Mirror: E=ok A1=Air1 A2=Air2 A3=Air1
Mirror      0.53  31.2  20.6  0.48  0.45  0.29/ 12.6    3    15s  2/2 L
   conv Mist: E=ok A1=Air1 A2=Air2 A3=Air1
Mist        0.59  39.8  27.5  0.48  0.52  0.33/ 15.7    3    16s  1/1 W
   conv Bone: E=ok A1=Air1 A2=Air2 A3=Air1
Bone        0.55  34.7  22.4  0.48  0.47  0.30/ 14.0    3    27s  3/2 L
   conv Flicker: E=ok A1=Air1 A2=Air2 A3=Air1
Flicker     0.53  33.3  21.5  0.48  0.45  0.29/ 13.4    3    16s  3/3 W
   conv Serpent: E=ok A1=Air1 A2=Air2 A3=Air1
Serpent     0.55  34.0  21.5  0.48  0.48  0.30/ 13.7    3    21s  3/2 L
   conv Medic: E=ok A1=Air1 A2=Air2 A3=Air1
Medic       0.55  31.9  20.6  0.48  0.47  0.30/ 12.9    3    22s  2/1 L
   conv Clay: E=ok A1=Air1 A2=Air2 A3=Air1
Clay        0.56  31.2  24.9  0.48  0.48  0.30/ 12.6    3    19s  2/1 W
   conv Puppet: E=ok A1=Air1 A2=Air2 A3=Air1
Puppet      0.76  20.3  23.2  0.48  0.65  0.30/ 12.9    3    24s  5/2 W
   conv Rinnegan: E=ok A1=Air1 A2=Air2 A3=Air1
Rinnegan    0.56  31.2  24.1  0.48  0.48  0.31/ 12.6    3    15s  1/1 W
   conv Ink: E=ok A1=Air1 A2=Air2 A3=Air1
Ink         0.56  37.7  26.7  0.48  0.48  0.32/ 14.8    3    33s  4/3 W
```

Natif (Studio Mac, Debug, DevGateCheck S15, 18/10 02:16) : Lion L3 push 24.2 / react 0.49 s, heavy push 25.3 / 0.93 s ; Mist L3 27.7 / 0.48, heavy 25.4 / 0.95 ; Puppet L3 23.1 / 0.49, heavy 25.4 / 0.93 ; Ink L3 26.9 / 0.48, heavy 18.9 / 0.90 — cohérent avec la grille headless. S16/S17 natifs : non obtenus (écran du Mac éteint pendant l'exécution).

Constats (à traiter en M6, pas ici) : la réaction du 3e léger dure 0,48 s pour les vingt (même Knockback) ; Sasuke et Lee refusent E après leur launcher (Committed : leur route a sa propre poursuite) ; Sand/Puppet : chaîne plus lente (0,76–0,82 s) par conception.

Complément natif (18/10 02:29, Debug M5, DevGateCheck) : S16 PASS — Flicker, Bone, Clay : launcher, E accepté, Air1/Air2/Air1 acceptés, 3 coups aériens, retour au sol ; S17 PASS — Killer Bee en duel IA 60 s : 3 techniques distinctes comptées par événements (Lariat ×2, InkMist ×1, OctoHold ×1), duel encore en cours à 60 s.
