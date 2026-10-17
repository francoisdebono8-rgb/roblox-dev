# Research Backlog

Research should be done by topic, not by endlessly searching generic Naruto prodigy lists.

For every useful source, capture:
1. source / title,
2. mechanic or design principle observed,
3. why it works,
4. how to reinterpret it for Ninja Duel,
5. implementation risk / complexity,
6. which characters could benefit.

## Movement & locomotion

Research topics:
- best lock-on movement systems in 3D arena fighters;
- games where characters run freely while preserving target awareness;
- strafing vs turning thresholds;
- body orientation during lateral sprint;
- root motion vs procedural locomotion;
- foot planting at high speed;
- animation warping / motion matching concepts usable in Roblox;
- camera behavior during high-speed pursuit.

Questions:
- When should torso/head track the target while hips follow travel direction?
- When should a strafe become a true run?
- How do games hide direction changes without visual snaps?

## Taijutsu / close combat

Research topics:
- readable anime melee choreography;
- Tekken/Virtua Fighter body mechanics for impact inspiration, not input complexity;
- arena fighters with strong freeform melee;
- martial arts references for kicks, sweeps, throws, counters;
- 360/spinning kicks and believable setup/recovery;
- hit reactions that communicate weight without freezing play too long.

Questions:
- Which movements look spectacular but remain readable at Roblox scale?
- How much recovery sells weight without making combat sluggish?

## Combo architecture

Research topics:
- directional combo systems;
- context-sensitive combo branching;
- launcher/pursuit systems;
- air-combo escape mechanics;
- wall combo systems;
- cancels that increase freedom without destroying readability;
- ways to prevent one optimal route.

Look especially at how simple control schemes generate depth through state/context.

## Projectiles & ninja tools

Research topics:
- projectile deflection and ricochet systems;
- weapon collision with weapon/projectile;
- delayed projectiles;
- wire/tether mechanics;
- projectile trajectory manipulation;
- projectile + elemental interactions;
- tool inventory systems that remain fast in combat.

Goal: tools should become a shared combat language with different mastery levels.

## Arena & environment

Research topics:
- fighting games with meaningful large arenas;
- wall running integrated into combat;
- environmental rebounds;
- cover that does not turn combat into a shooter;
- vertical pursuit;
- terrain tags and breakable geometry;
- camera framing in large spaces.

## Character identity / large rosters

Research topics:
- how fighting games differentiate 30–50 characters sharing the same controls;
- archetype matrices;
- common-system vs character-specific ratios;
- stance systems;
- resource-specific fighters;
- clone/puppet/summon archetypes;
- teleport vs burst-mobility differentiation.

## Awakenings / transformations

Research topics:
- transformations that change rules rather than only stats;
- install supers;
- temporary stance changes;
- risk/reward transformations;
- comeback mechanics that avoid feeling unfair.

## Naruto lore research per candidate

For each candidate, investigate specifically their capabilities around roughly 10–14 years old, then separate:
- canon known at that age,
- plausible extrapolation,
- intentional gameplay liberty.

Topics:
- Minato early combat feats and academy records;
- Itachi childhood shurikenjutsu / genjutsu / Sharingan progression;
- Shisui early Body Flicker and genjutsu reputation;
- Kakashi youth arsenal around Chunin/Jonin progression;
- Orochimaru youth skill set;
- Gaara childhood sand defense;
- Neji Chunin-era Gentle Fist;
- Sasuke pre/post Chunin Exams;
- Naruto Chunin-era clone creativity and one-tail transition;
- Lee Gates and taijutsu progression;
- Haku, Kimimaro, Killer Bee, Temari, Tenten, Shikamaru, Shino, Kiba, Choji, Hinata and others for possible roster slots.

## Fan fights / AI animation inspiration

Search fan-made fights, hypothetical tournaments, animation projects and AI-generated fight concepts only as choreography inspiration.

Extract:
- clever transitions,
- matchup ideas,
- environmental use,
- surprising counters,
- signature sequences.

Do not import fan claims as canon automatically.

## Research output format

Create one note per topic in this folder when research is deep enough.

Suggested template:

```md
# Topic

## Sources reviewed
...

## Useful principles
...

## Ninja Duel adaptations
...

## Characters affected
...

## Prototype ideas
...

## Risks / things not to copy
...
```

The aim is to continuously turn outside inspiration into implementation-ready design knowledge.