# ANIMATEUR — fin de l'audit feel du 07/11 (12/11/2026)

Référence : `docs/reports/feel-audit-2026-11-07/AUDIT.md`, « Besoins pour l'ANIMATEUR ».
Branche : `work/anim-feel-reactions` (fichiers ANIMATEUR). Le moteur est demandé au DEV dans une PR à part : `work/anim-feel-engine-request` (une seule fonction et deux appels dans `VelmoraMotionEngine.luau`).

Tous les clips sont faits **dans Blender**, sur le rig de contrôle (`nd_ctrl` / `nd_shot`), pose par pose, comme `clips_react2` :
`tools/blender/clips_feel.py` (les poses) et `tools/blender/job_feel_7.py` (les 8 combattants de la beta, export `clips_<F>_feel.json`, planches).
Le job tourne aussi sans écran (`bpy` 5.2.3). 130 clips (16 ou 17 par combattant), répartis dans `AuthoredClips50` à `58`. `regen_clips.sh` les inclut.

## 1. Coups reçus de dos et de côté (M3/m3)

Il manquait l'éjection et la saisie dans ces deux directions ; la réaction sonnée (Hit.Back / Hit.Side) existait déjà.

| Clip | Angle du coup (`hitAngle`, serveur) | Miroir | Ce que fait le corps |
|---|---|---|---|
| `F.Hit.Side` (existant) | 36,9° < \|angle\| < 143,1° (\|sin\| > 0,6) | angle < 0 | plie et part vers sa gauche |
| `F.Hit.Back` (existant) | \|angle\| > 143,1° (cos < −0,4, hors côté) | `hitTwist` < 0 | cambré, tombe en avant |
| `F.Launched.Side` (nouveau) | 36,9°–143,1° | angle < 0 | côtes rentrées, roulé sur la gauche, jambes vers l'attaquant, la tête le cherche |
| `F.Launched.Back` (nouveau) | > 143,1° | `hitTwist` < 0 | cambré puis porté en avant, jambes derrière |
| `F.Knockback.Side` (nouveau) | 36,9°–143,1° | angle < 0 | projeté sur sa gauche, roulé à 38°, bras éloigné en l'air |
| `F.Knockback.Back` (nouveau) | > 143,1° | `hitTwist` < 0 | hanches projetées en avant, vol penché en avant |
| `F.Grabbed` (nouveau, boucle) | < 36,9° | — | saisi au col : sur les pointes, mains sur le poignet, il tire et rue |
| `F.Grabbed.Side` (nouveau, boucle) | 36,9°–143,1° | angle < 0 | tenu par le bras droit : tourné vers la prise, il se penche pour s'en dégager |
| `F.Grabbed.Back` (nouveau, boucle) | > 143,1° | `hitTwist` < 0 | bras autour du cou : sur les talons, mains sur l'avant-bras, la tête se retourne |

Mêmes seuils et même ordre que `Hit.Side` / `Hit.Back` dans le moteur : le DEV choisit la variante au lieu de tourner la victime.
Cas de l'audit : Itachi lancé par Minato (176°) → `Launched.Back` ; Sasuke saisi de dos (179°) → `Grabbed.Back` ; Kakashi sonné (155°) → `Hit.Back`.

**À vérifier avec le DEV, au premier essai :** le signe de l'angle. Avec `hitAngle = atan2(facing × hitFrom, facing · hitFrom)`, un attaquant à droite donne −90°, donc le miroir. Les clips `.Side` suivent la convention de `Hit.Side` : il faut voir en jeu qu'un coup venu de la droite jette bien le corps vers sa gauche. Si ce n'est pas le cas, c'est `Hit.Side` qui est faux aussi : on inverse le test pour les deux.

## 2. Glissades (M1)

**Garde : pas chassés.** `F.Guard.Step.B` / `F` / `L` / `R` sont des cycles où les pieds sont plantés au sol (`nd_shot.cycle`) :
- Le pied du côté où il va part en premier, l'autre suit et rejoint ; les pieds ne se croisent jamais.
- Un pied tient toujours le sol.
- Glisse mesurée dans Blender (`nd_shot.check`) : **0,000** sur les 32 cycles.

| | Valeur |
|---|---|
| Vitesse des pas, telle qu'animée | **6 studs/s** : 2,2 studs par cycle de 0,367 s (deux pas) |
| Le moteur accélère la cadence | × vitesse / 6, plafond 1,8 |
| Pieds exacts | jusqu'à **10,8 studs/s** |
| Au-delà de 12 studs/s | `F.Guard.Skid` : arc-bouté, penché dans la poussée, talon avant qui creuse. Le recul de 33 studs/s ne se fait pas en pas : c'est une glissade assumée, plus une pose figée. |
| Vitesse de garde du jeu (`Config.GuardSpeed`) | 8 studs/s, soit une cadence × 1,33 |

**Fin des coups (Light1–4, DashAttack, jusqu'à 14 studs/s) : pas de nouveau clip dans ce lot.**
- Le moteur mélange déjà les jambes de course dans les coups au-dessus de 7 studs/s (`wMove`).
- La sonde client `tools/studio/probes/feel_client.luau` dira si ce mélange suffit. Elle compte les glissades vues à l'écran : corps qui avance, aucun pied qui tient le sol.
- Si des glissades restent sur ces coups, le lot suivant fait des fins de coup marchées (`Light*.Walk`).

## 3. Coup qui pivote

`F.Pivot.R90`, `R180`, `L90`, `L180`, 0,25 à 0,3 s.
- La racine (HumanoidRootPart) tourne à la vitesse du moteur, 1800°/s, soit 3 images à 60 fps pour 90°.
- Le corps est en retard sur la racine : la tête retrouve l'adversaire d'abord, puis le buste, les hanches en dernier (petit dépassement, puis il se stabilise).
- Le pied avant pivote sur la plante, le pied arrière fait le tour en arc. Glisse : 0,07 au plus.
- Le coup part ensuite de la garde, déjà tourné.

## 4. Arrivée des jutsu de déplacement

**Poses d'arrivée.**
- `Flashstep.LightningStrike.Arrive` (Minato) : bas, large, le kunai porté derrière, la main libre près du sol.
- `Copycat.LightningCut.Arrive` (Kakashi) : en fente, le bras de la coupe tendu derrière lui, l'avant-bras gauche en garde.
- Les deux se relèvent dans la garde en 0,4 s, avec un pas.
- **En attente de l'état demandé au DEV** : le moteur doit jouer `F.<Tech>.Arrive` à `teleportAt`.

**Trace entre le départ et l'arrivée : `src/Client/DashTrailFX.luau`.**
- Une ligne qui court du départ à l'arrivée en 0,06 s, puis s'efface.
- Une brûlure au sol.
- 3 ou 4 images rémanentes de la pose d'arrivée, alignées sur le trajet.
- Minato : ligne jaune, droite.
- Kakashi : vraie foudre blanc-bleu qui se ramifie deux fois en s'éteignant, étincelles à l'arrivée.
- La couche n'intercepte pas l'impact : les nuages de FamilyFX marquent toujours le départ et l'arrivée.

## 5. Foudre (Lightning Beams, MIT)

- `src/Client/LightningBoltFX.luau` adapte `SamyBlue/Lightning-Beams` (commit `406c3b9`), en gardant ses maths : courbe de Bézier, bruit de Perlin en couches, épaisseur variable, impulsion qui court, dissipation.
- Adapté à la bible VFX :
  - dessiné avec des Beams (un trait blanc au centre, la couleur dans le halo), jamais de pièces en Neon ;
  - rien n'est créé avant le premier éclair ;
  - 24 éclairs au plus ;
  - chaque éclair passe dans un `pcall`.
- Licence : `vendor/lightningbeams/` (original et LICENSE), `THIRD_PARTY.md`, `vendor/manifest.json`, et `build.py` qui embarque le texte de la licence dans la place.
- `src/Client/LightningFX.luau` (Chidori de Sasuke, Raikiri de Kakashi) :
  - **tenu en main** : 3 à 5 arcs sortent de la paume et changent toutes les 0,06 à 0,1 s, avec un arc vers le sol de temps en temps ;
  - **en course** : un arc traîné au sol derrière lui ;
  - **à l'impact** : 4 éclairs traversent le corps dans le sens du coup.
- `Effects.luau` : deux lignes d'installation, et la sphère du Chidori passe du Neon au ForceField.

## 6. Plugin Blender officiel de Roblox (MIT)

`Roblox/roblox-blender-plugin` envoie maillages et collections vers Roblox (Open Cloud), sous forme de packages, sans passer par Studio.
- **Ce qu'il change :** les formes VFX faites dans Blender (anneaux, cônes, éclats) pourront partir directement de Blender.
- **Ce qu'il ne change pas :** nos clips d'animation sont des données Luau, pas des assets.
- **Étape du propriétaire :**
  1. Dans Blender 5.2 : Préférences > Add-ons > Install from Disk, avec le zip de la page *Releases*.
  2. Panneau `Roblox` (touche N) > Install Dependencies, puis redémarrer Blender.
  3. **Log in**, avec ton compte Roblox (OAuth dans le navigateur).
- Je ne peux pas faire la connexion à ta place.

## 7. Preuve (LAB) : pas encore faite

Les places sont prêtes sur le Mac :
- `LAB/repro/ND-DEV-feel-AVANT.rbxlx` (référence 2f76fca) ;
- `LAB/repro/ND-DEV-feel-APRES.rbxlx` (cette branche, avec la demande moteur appliquée, profil debug).

À faire, Studio au premier plan, qualité 10 :
1. Jouer Naruto–Kakashi en IA pendant 60 s dans chaque place.
2. Lancer `tools/studio/probes/feel_audit.luau` côté serveur et `feel_client.luau` côté client.
3. Comparer retournements et glissades par minute, avant et après.
4. Filmer 60 s APRÈS avec OBS.

Bloqué le 12/11 : le contrôle de l'ordinateur a été arrêté, et la seule fenêtre Studio ouverte est ND-DEV, qui n'est pas la mienne.

**Les retournements restent au DEV.** Les clips ne suppriment pas le demi-tour d'une image, qui vient du serveur. Pistes :
- le `lookAt` de la saisie appelé à chaque image (Brawler ~1645) ;
- `GRAB_TURN` 900°/s (Families ~855).

## 8. Demandes au DEV (PR `work/anim-feel-engine-request`)

1. **Variante selon le côté du coup** : une fonction `directional()` dans `authoredReaction`, pour Launched, Knockback (en l'air) et Grabbed. Avec elle, ne plus tourner la victime vers le coup.
2. **Garde en mouvement** : `guardStep()` dans la branche `Guarding`. Pas selon la direction locale, cadence = vitesse / `meta.speed` (plafond 1,8), au-dessus de 12 studs/s → `Guard.Skid`. Le choc sur la garde (`guardImpact`) garde son clip.
3. **Pivot (pas dans la PR, c'est le code des coups)** : quand un coup part à plus de 90° de la direction de l'adversaire, jouer `F.Pivot.<R|L><90|180>` (le plus proche) pendant que la racine tourne, puis le coup depuis son début.
4. **Arrivées (pas dans la PR)** : jouer `F.<Tech>.Arrive` à `teleportAt` à la place de la pose procédurale « Teleport », pour LightningStrike et LightningCut.

## 9. Tests manette (courts, pour toi)

1. Garde (L2) en reculant puis en allant de côté : les pieds font des petits pas, ne se croisent pas, et rien ne patine.
2. Prends un coup de dos (laisse l'IA te contourner) : le corps part en avant, il ne fait plus de demi-tour.
3. Fais-toi saisir de dos, puis de côté : la prise se voit (bras au cou, bras tenu).
4. Minato, LightningStrike : une ligne jaune relie le départ et l'arrivée, avec des silhouettes sur le trajet.
5. Kakashi, LightningCut et Raikiri : de la foudre se ramifie le long du trajet ; tenu en main, des arcs sortent de la paume ; à l'impact, ça traverse le corps.
6. Sasuke, Chidori tenu en courant : un arc traîne au sol derrière la main.

Les tests 1 à 3 demandent la PR moteur ; les tests 4 à 6 marchent avec cette seule branche.

## 10. Tests automatiques

- Suite Lune : **tout passe**, sauf `CameraFeel`, qui échoue déjà sur la référence 2f76fca (l'arbre sous la boîte invisible n'est pas estompé) et n'est pas lié à ce travail.
- Nouveau : `tests/Lightning.spec.luau`, 8 tests :
  - les éclairs sont faits de Beams, sans Neon ;
  - fin de vie et budget respectés ;
  - un éclair cassé n'arrête pas l'image ;
  - lecture du Chidori et du Raikiri ;
  - les couches n'interceptent aucun impact ;
  - tracé droit ou brisé.
- Avec la demande moteur appliquée : Animation, CombatFeel, Embodiment, Fluidity, Locomotion, Sequences, Kakashi et Control passent.
