# Combat Verbs & States

The goal is to make every character feel different while reusing a shared combat language.

## Shared state model

The combat system should think in states rather than isolated moves:

- Neutral
- Approach
- Retreat
- Strafe / angle creation
- Guard
- Dodge
- Counter window
- Light pressure
- Heavy pressure
- Grab / projection
- Launcher
- Airborne attacker
- Airborne victim
- Pursuit
- Wall run
- Wall splat
- Wall bounce
- Knockdown
- Grounded vulnerable
- Recovery
- Substitution escape
- Teleport/reposition
- Projectile setup
- Trap/setup
- Awakening state

A strong move usually does at least one of three things:
1. changes state,
2. changes position,
3. changes available options.

Damage alone is not enough to make a move interesting.

## Four-layer attack model

### Layer 1 — Contact
Punch, kick, elbow, palm, kunai slash, sand strike, snake strike.

### Layer 2 — State change
Stagger, launch, sweep, wall splat, knockdown, bind, guard break, chakra seal.

### Layer 3 — Transition
Dash chase, teleport chase, wall chase, aerial pursuit, side switch, recoil cancel, tool cancel.

### Layer 4 — Character conversion
The same state becomes different gameplay depending on the fighter.

Examples:
- Minato: launcher -> marked teleport aerial continuation.
- Lee: launcher -> physical chase with no teleport.
- Gaara: launcher -> sand continues pressure while Gaara stays grounded.
- Itachi: launcher -> projectile intercepts fall path.
- Neji: stagger -> tenketsu pressure rather than raw damage.

## Character combat verbs

A character should ideally have 5–7 dominant verbs.

### Minato
mark -> angle -> vanish -> appear -> punish -> pursue -> reset

### Itachi
observe -> bait -> redirect -> deceive -> punish -> control

### Neji
enter -> deflect -> touch -> seal -> rotate -> control

### Sasuke
pressure -> launch -> chase -> burn -> trap -> overwhelm

### Naruto
split -> confuse -> swarm -> improvise -> recover -> overwhelm

### Gaara
deny -> absorb -> trap -> displace -> crush -> reset

### Kakashi
read -> adapt -> counter -> vary -> punish -> reposition

### Orochimaru
distort -> extend -> bind -> disappear -> reappear -> corrupt spacing

### Shisui
burst -> duplicate -> misdirect -> cross-up -> vanish -> re-enter

### Rock Lee
close -> pressure -> launch -> chase -> kick -> recover -> repeat

## Movement identity must affect combat

Movement is not a neutral transport layer.

- Minato should solve space with teleport geometry.
- Shisui should solve space with burst movement and afterimages.
- Lee should solve space with physical acceleration.
- Gaara should manipulate space instead of moving much.
- Neji should use compact footwork and circular repositioning.
- Naruto should create positional ambiguity through clones.

## Context should matter

The same input should be allowed to resolve differently based on:
- opponent grounded / airborne,
- wall proximity,
- attacker airborne,
- current speed,
- stick direction,
- previous hit result,
- active mark/trap/projectile,
- chakra state,
- awakening state,
- distance.

This is how the game can stay simple to control while supporting many routes.

## Target feeling

The player should regularly create sequences such as:

neutral -> approach -> light pressure -> launcher -> chase -> aerial route -> wall splat -> wall follow-up -> ground finish

or

projectile setup -> forced dodge -> angle change -> grab -> knockdown -> trap reset

or

counter -> side switch -> stagger -> signature conversion -> awakening finisher

These sequences should remain interruptible and player-driven, not become long cutscenes.