# NEXT MISSION — VALIDATE, POLISH, SCALE THE ROSTER

## Context

The latest combat convergence pass has finally moved Ninja Duel forward in the right areas: combo confirmation, directional routes, re-engage, chakra/tool foundations, stronger fighter identity, Gaara, Rock Lee, larger Chunin stadium, better VFX/animations, and a character production framework.

Do not throw this work away and do not restart architecture from scratch.

The next mission must do two things in parallel:

1. finish and visibly validate what is already implemented but still partial / only technically proven;
2. use the new production framework to expand the playable roster faster, so the engine is stress-tested by more varied movement, jutsu, tools and combat archetypes.

The goal is NOT to produce more documentation. The goal is to make the normal build noticeably more complete, varied and trustworthy when played by a human.

---

# 1. HUMAN-FACING VALIDATION IS NOW MANDATORY

A feature is not complete because:
- a module exists;
- a test passes;
- a value is configured;
- a report says it is implemented;
- an effect can be spawned in isolation.

For every major system touched in the previous mission, verify the actual player-facing result in Studio.

When reporting status, always distinguish exactly between:
- IMPLEMENTED AND PLAYED IN STUDIO;
- IMPLEMENTED BUT ONLY TECHNICALLY TESTED;
- PARTIAL;
- NOT IMPLEMENTED.

Never write that a system is "working" if only its data or tests exist.

For each corrected feature, create evidence through a Studio probe, direct play sequence, screenshot, or measurable runtime result.

---

# 2. COMBO / INPUT MODEL — POLISH UNTIL IT FEELS OBVIOUS

The confirmed-hit combo model and forgiving direction handling are the right direction. Keep them.

Now verify and improve the real feel.

The target remains Storm-like accessibility:
- easy inputs;
- predictable results;
- no frame-perfect ordinary routes;
- no phantom combo state;
- no hidden step advancement;
- skill comes from decisions and defense, not from command difficulty.

Mandatory checks:

- whiff -> next hit must still be Light1 / first confirmed hit;
- buffered hit before contact must not visually or logically skip a combo step;
- fast double tap must be accepted;
- late but reasonable directional input must still select the intended branch;
- walking around / through the target must not accidentally transform forward input into side input;
- route selection must remain stable under camera rotation / lock-on;
- air routes must be equally reliable;
- pursuit / re-engage into attack must not inherit stale combo state;
- jutsu cancel must not corrupt the string counter;
- substitution / dodge / block break must reset or preserve state only when intended.

Do not add complexity. If a route is hard to execute, fix recognition rather than making the player learn a stricter timing.

---

# 3. RE-ENGAGE / CHAKRA DASH — MAKE IT A CORE FEEL FEATURE

The unified E re-engage / pursuit idea is good. Now make it polished and character-specific.

Human-facing goals:

- after knockback, the player instinctively knows they can re-enter;
- re-entry stops at a useful combat distance;
- no overshoot;
- no awkward stop;
- no long recovery that kills momentum;
- no accidental teleport through the opponent;
- attack after arrival should feel continuous.

Character expression:

MINATO
- shortest, cleanest, fastest re-entry;
- precise angle correction;
- FTG/seal logic can enhance it where valid.

ITACHI
- calmer approach;
- deceptive angle / afterimage flavor;
- not as explosively fast as Minato.

NEJI
- controlled center-line close-in;
- compact posture;
- designed to arrive directly into palm pressure.

SASUKE
- aggressive momentum;
- stronger forward commitment;
- natural air / wall conversion.

GAARA
- should not suddenly become a rushdown fighter;
- re-engage should fit his control style, perhaps shorter reposition or sand-assisted correction.

LEE
- explosive physical burst;
- visibly athletic and momentum-heavy.

Test each separately.

---

# 4. CHAKRA SYSTEMIC COMBAT — FINISH THE PLAYER-FACING LAYER

The chakra system is currently one of the most important differentiators from Storm. Do not leave it at "Z+R technically changes projectile metadata".

It must become visible, useful and understandable.

## Tool infusion requirements

Normal tool and infused tool must differ in behavior, not only damage.

At minimum validate and polish:

### Normal kunai/shuriken
- standard speed / arc / impact;
- readable baseline.

### Chakra-reinforced tool
- distinct but restrained aura / trail;
- different contact behavior;
- stronger projectile contest / deflect stability / guard interaction where intended.

### Wind infusion
- visibly sharper / faster / cutting identity;
- trajectory or lane-control property that matters;
- Minato wind tool should visibly differ from his normal kunai.

### Fire infusion
- visible ignition behavior;
- burn must not repeatedly restun or falsely inflate combo counter;
- burning zone / target feedback must be readable but not noisy.

### Lightning + metal / wire
- implement a first real useful conductive interaction;
- this is especially important for Sasuke;
- do not reduce it to bonus damage.

### Planted tools
- when a tool remains in the world, the player must understand why it matters;
- marks, anchors, wire endpoints, traps or return points should be visually readable.

### Projectile interaction
- test collisions / interceptions;
- deflect / clash rules should be coherent;
- effects should explain which projectile won and why.

### Wire
- wire must be a real combat object / state, not only a scripted jutsu animation;
- support at least one useful Sasuke route such as:
  shuriken -> wire bind / line -> fire or lightning conversion.

Keep controls simple. Do not add many new buttons.

---

# 5. CORE4 IDENTITY — FINISH WHAT IS STILL ONLY TECHNICALLY PROVEN

## Minato

Must clearly show:
- angle changes;
- seals;
- body mark;
- floor mark / planted kunai;
- FTG re-entry;
- combo -> relocation -> combo continuity;
- Rasengan conversion.

Wind Cut was reworked; now decide by actual play if it deserves to remain. If it still feels generic or weak, redesign again rather than defending existing code.

Yellow Flash awakening must visibly change his combat flow, not merely stats.

## Itachi

Must clearly show:
- calm economical strikes;
- launcher + shuriken cover;
- real Mirage deception;
- correct fake-body / real-body readability;
- Read success visibly communicating prediction;
- CounterPalm flow;
- projectile geometry / ricochet usefulness;
- fire pressure as control rather than generic damage.

Base Itachi must already feel deceptive without requiring a future progression build.

## Neji

This remains a major visual priority.

Must clearly show:
- Gentle Fist palms visually distinct from generic punches;
- precise local chakra-point impacts;
- tenketsu accumulation that the attacker AND defender can understand;
- chakra regen / jutsu restriction consequences that feel connected to those hits;
- Rotation -> counter continuity;
- Vacuum Palm wall pressure;
- 64 Palms as a natural culmination of his chakra-network game.

If tenketsu still only feels like hidden numbers / bar changes, this part is not complete.

## Sasuke

Keep him as the current identity benchmark.

Polish:
- kick-heavy strings;
- LionKick;
- Shadow of Dancing Leaf;
- Lion Combo;
- VaultKick;
- air pursuit;
- wire integration;
- Phoenix Flower hidden-tool identity;
- Chidori conversion / risk;
- Curse Mark changing route pressure and not just multipliers.

---

# 6. GAARA — TURN TECHNICAL COMPLETENESS INTO GOOD GAMEPLAY

Gaara is now playable and visually much more complete, but he still needs human-feel validation.

Check:
- shield clarity;
- shield strength / regeneration;
- how easy it is to understand when it has charges;
- sand lashes readability;
- Sand Pillar startup and punishability;
- Sand Coffin readability and escape logic;
- Desert Wave usefulness;
- sand flicker feel;
- projectile visuals in motion;
- matchup fairness against fast melee fighters.

Important:
AI results suggest Gaara may dominate some opponents because the shield absorbs too much basic pressure.

Do not balance purely from AI win rate, but use it as a warning.

Gaara should feel:
slow, protected, controlling, oppressive at the correct range,
but punishable when bypassed.

---

# 7. ROCK LEE — FINISH THE FIRST STRESS-TEST CHARACTER

Rock Lee is the first real proof that the production framework can create a new fighter faster.

Fix known issues first:
- Primary Lotus dive must not pass through the opponent;
- Gate speed / acceleration must be measured and tuned;
- route transitions must remain physically coherent;
- ensure he is not just "Sasuke without jutsu".

Then deepen only what is needed to make him clearly Rock Lee:
- physical acceleration;
- taijutsu pressure;
- strong kicks;
- Lotus;
- Gate transformation;
- weight-removal style speed change if appropriate for this version;
- no elemental-jutsu dependency.

Do not spend forever polishing one fighter. Use Lee to improve reusable melee / launch / air / pursuit components.

---

# 8. CHARACTER PRODUCTION FRAMEWORK — MAKE NEW FIGHTERS CHEAPER

This is now strategic.

Do not hand-author every future character from zero.

Strengthen the production framework so a new fighter can reuse:
- locomotion families;
- stance families;
- strike archetypes;
- launcher archetypes;
- aerial families;
- wall routes;
- projectile families;
- tool behaviors;
- jutsu casting patterns;
- awakening hooks;
- VFX helpers;
- hit reactions;
- AI archetypes;
- test templates.

But reuse must NOT erase identity.

Target philosophy:
- ~60–70% robust reusable foundation;
- ~30–40% identity-specific work.

The identity-specific part is where time should go:
- signature movement;
- signature route;
- signature jutsu;
- signature defensive mechanic;
- signature visual feedback;
- awakening behavior.

A new character should no longer require rewriting core combat code.

---

# 9. EXPAND TO 8–10 PLAYABLE FIGHTERS AS A STRESS TEST

Do not jump directly to 20 polished characters.

The near-term target is 8–10 genuinely playable fighters.

Current six:
- Minato
- Itachi
- Neji
- Sasuke
- Gaara
- Rock Lee

Next candidates should be selected for maximum system diversity, not only popularity.

Recommended priority pool:
- Naruto
- Kakashi
- Haku
- Temari
- then Shikamaru / Kisame depending framework needs.

Choose 2–4 next characters based on which systems need stress-testing.

Examples:

NARUTO
- clone pressure;
- unpredictable rush;
- projectile / clone interaction;
- Rasengan-like close conversion without copying Minato's identity.

KAKASHI
- adaptive / balanced archetype;
- lightning;
- tools;
- defensive reads;
- useful for testing flexible framework composition.

HAKU
- high-speed movement;
- needles;
- ice / mirror concepts;
- unusual mobility and projectile geometry.

TEMARI
- long-range wind control;
- large fan attacks;
- arena lane control;
- excellent for testing projectile / space systems.

SHIKAMARU
- traps / state control;
- tests non-rushdown combat.

KISAME
- heavy weapon / water / reach;
- tests larger attack volumes and resource pressure.

Do NOT make them mere reskins.

For each new fighter require, before moving on:
- selectable;
- stable locomotion;
- basic ground string;
- at least 3 meaningful routes;
- air route;
- re-engage behavior;
- tool behavior;
- at least 2–3 usable techniques;
- one signature mechanic;
- one awakening or temporary power-state if appropriate;
- AI can use core kit;
- automated tests;
- one native Studio play sequence.

They do not need final polish before the next fighter begins.

The purpose is breadth enough to expose framework bugs quickly.

---

# 10. USE THE LARGER ROSTER TO FIND ENGINE BUGS

As roster expands, actively look for systemic failures:

- combo counter corruption;
- shared attack animation looking wrong on a different archetype;
- projectile collision bugs;
- re-engage overshoots;
- wall splat failures;
- air hold bugs;
- chakra infusion incompatibilities;
- incorrect hitboxes on tall / unusual moves;
- stale target tracking;
- jutsu cast locking movement;
- tool / jutsu cancel exploits;
- camera framing failures;
- awakenings cancelling speed or movement modifiers;
- AI unable to understand new archetypes;
- UI scaling / roster menu problems.

When a new fighter exposes a shared engine bug, fix the shared engine instead of patching only that character whenever possible.

---

# 11. ARENA — BUILD THE CHUNIN EXAM STADIUM, NOT A RANDOM OBSTACLE FIELD

The arena should now be corrected toward the actual visual and spatial language of the Chunin Exams stadium.

The previous approach of adding rocks / pillars / random obstacles is not sufficient if the overall space does not read correctly.

Priority order:

1. overall scale;
2. field diameter;
3. wall height;
4. stadium / stands silhouette;
5. participant / spectator architecture;
6. entry geometry;
7. usable vertical surfaces;
8. only then secondary obstacles if gameplay needs them.

The arena should feel like:
"a larger, gameplay-ready interpretation of the real Chunin Exam arena"

not:
"a generic circular combat field with rocks."

Use reference proportions from the source material as inspiration, but adapt dimensions for Ninja Duel's movement speed, projectiles and pursuit.

Current radius 145 can be retuned if needed.

Test actual combat distances:
- long range;
- mid range;
- close range;
- chase from one side to the other;
- wall route;
- cornice route;
- projectile pressure.

The stadium's size must create freedom without creating dead travel time.

---

# 12. MAKE THE ARENA MATTER TO COMBAT

The current AI mostly fights in the center. That means the arena systems are not yet integrated enough.

Add / improve reasons to use space:
- wall splat;
- wall recovery;
- wall dive;
- wall run;
- elevated escape;
- pursuit to a wall;
- ranged lane pressure;
- obstacle cover if retained;
- character-specific wall conversions.

AI should occasionally:
- disengage toward useful space;
- pressure toward a wall;
- pursue a launched opponent;
- use vertical surfaces;
- avoid obvious ranged lanes.

Do not script theatrical arena usage. Make the systems naturally produce it.

---

# 13. ANIMATIONS / IMPACT — CONTINUE POLISH, DO NOT FREEZE THEM AS "DONE"

The animation work is improved, but still not final.

Keep auditing:
- combo transitions;
- foot planting;
- torso / pelvis weight transfer;
- strike acceleration;
- recoil / follow-through;
- air transitions;
- pursuit arrival;
- landing;
- wall contact;
- victim reactions;
- jutsu startup / recovery.

New fighters are useful here because they will reveal which motion families are too generic.

If every fighter still shares too much body language, improve the reusable motion system rather than writing hundreds of unrelated clips.

---

# 14. CONTROLLER VALIDATION

Keyboard input has received real Studio validation.

Controller still needs a real pass.

Mandatory:
- actual gamepad input;
- light / heavy;
- jump;
- dodge;
- guard;
- tool;
- chakra modifier + tool;
- re-engage;
- jutsu selection / activation;
- awakening;
- lock-on.

Core actions must be comfortable.

Do not leave any major combat action on an awkward D-pad combination if a better mapping exists.

---

# 15. ONLINE / PROGRESSION ARE NOT THE PRIMARY FOCUS YET

Preserve all existing work.

Do not delete or regress:
- online protocol;
- queue / private duel foundation;
- progression data;
- profiles;
- skill trees.

But do NOT spend the bulk of this mission expanding them.

Before investing heavily in those systems, core combat should have:
- 8–10 varied playable fighters;
- reliable inputs;
- readable chakra interactions;
- good arena flow;
- convincing animations;
- stable tools / projectiles.

A two-client online test may be done if easy and useful for regression detection, but it is secondary to combat completion.

---

# 16. AUTONOMY RULE

Continue working autonomously while meaningful high-value work remains.

Do not stop after implementing one small subsection just because a commit exists.

Use the mission as a prioritized backlog.

When one part is blocked:
- move to another high-value part;
- return later;
- keep the game advancing.

Prefer several hours of meaningful implementation / testing over early reporting.

However:
- do not create speculative systems just to stay busy;
- do not inflate code volume;
- do not create fake completeness through docs;
- do not add roster entries that are data-only and call them playable.

Every substantial change should improve the actual normal build.

---

# 17. FINAL ACCEPTANCE TARGET

At the end of this mission, opening:

`games/ninja-duel/dist/NinjaDuel.rbxlx`

should show a noticeably more complete game.

Expected visible result:

- combo inputs feel simple and reliable;
- confirmed-hit model feels natural;
- re-engage is intuitive and smooth;
- chakra-infused tools are visible and tactically different;
- wire / elemental interactions begin to create real freedom;
- Minato, Itachi, Neji and Sasuke feel more distinct than before;
- Gaara feels truly playable rather than technically integrated;
- Rock Lee feels stable and unique;
- at least 2 more fighters are preferably playable if the framework allows it without sacrificing core stability;
- arena looks much closer to a real large Chunin Exam stadium;
- walls / verticality / space enter actual fights more often;
- attack / reaction animation continues improving;
- no major regression in tests or builds.

Do not optimize for the number of checkboxes.

Optimize for:
"When the user comes back and plays for 15 minutes, how many meaningful improvements can they immediately see and feel?"

---

# 18. END-OF-MISSION REPORT FORMAT

At the end, report only concrete truth.

Use four sections:

## PLAYED AND VERIFIED IN STUDIO
For each item:
- exact input / scenario;
- exact fighter;
- exact visible result;
- bug found and corrected if applicable.

## IMPLEMENTED BUT NOT HUMAN-VALIDATED
Be explicit.

## PARTIAL / STILL WEAK
Do not hide weaknesses.

## NOT IMPLEMENTED
List what remains.

Also include:
- exact playable roster;
- exact controls after changes;
- exact chakra infusion interactions that work;
- exact arena changes;
- exact known bugs;
- automated test counts;
- build status for Normal / Debug / QA.

Suggested final commit title:

`feat(ninja-duel): validate combat systems and scale playable roster`
