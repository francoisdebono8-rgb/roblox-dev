# STOP ABSTRACT EXPANSION — VISIBLE RUPTURE REQUIRED NOW

**Status: ACTIVE / IMMEDIATE PRIORITY OVERRIDE**

Start from the real current HEAD of `claude/ninja-duel-2026-10-14` (currently `33962550a8ca7944c556578208a34fc4eaee79eb`; re-check before coding).

Do **not** revert the useful Embodiment work already completed. Keep `ActionContext`, defender recovery, `WorldReaction`, material/integrity logic, perception, AI terrain awareness, tests, and any other genuinely useful foundation.

But stop adding new large abstract systems for now.

The current problem is not lack of architecture. The current problem is that, after several Embodiment commits, the game still looks and feels too similar to the pre-mission build when played normally.

That is unacceptable for a mission whose purpose is to transform the game.

## Immediate rule

> **NO VISIBLE RUPTURE = NO PASS.**

A passing test suite, a new subsystem, more files, more architecture, or more code does not count as success if the player cannot immediately feel and see the difference in a real fight.

Do not proceed to another broad `Embodiment 4/5/...` layer until the systems already built create an obvious product-level change.

---

# 1. THE NEXT DELIVERABLE IS ONE CONVINCING REAL FIGHT

Produce a **60–90 second Sasuke vs Minato free fight** in Studio that looks and plays obviously different from the current build.

This is not a scripted cinematic. It must be a real playable/free-fight demonstration using the actual combat systems.

The purpose of Sasuke vs Minato is not to narrow the product to these two fighters. It is the shortest proof that the universal Embodiment systems actually change moment-to-moment gameplay.

If the new fight still reads as:

`M1 -> M1 -> launcher -> pursuit -> air hits -> reset -> technique -> repeat`

then continue iterating. Do not declare the step complete.

---

# 2. CLEAN THE ARENA BEFORE USING IT AS A SYSTEM TEST

The current arena has become visually worse because training trees/posts/stones were inserted mainly to exercise world-reaction code.

Do not confuse a test fixture with level design.

Required now:

- remove or relocate arbitrary trees/posts/stones that clutter the central fight space;
- restore a large, readable central combat area;
- prevent scenery from frequently blocking the camera;
- keep walls useful for wall-running and combat;
- place destructible geometry deliberately around/peripheral to the fight, where it creates opportunities rather than visual noise;
- improve the obvious placeholder look of the arena where feasible in this pass;
- preserve the reactive-world system, but integrate it into coherent level design.

The arena should support freedom, speed and spectacle. It must not feel like an obstacle course created to test `WorldReaction`.

---

# 3. FIX THE VISIBLE BUGS BEFORE ADDING MORE ABSTRACTION

Use actual Studio playtests and camera footage.

Prioritize visible defects including:

- body intersections / fighters visually merging;
- broken or unclear contact poses;
- ugly snaps or sudden transitions;
- camera obstruction by scenery;
- awkward wall interactions;
- unreadable high-speed exchanges;
- hits whose body motion does not explain the impact;
- odd launch/pursuit spacing;
- visibly mechanical locomotion during combat;
- any new regression introduced by Embodiment systems.

Do not hide these behind effects.

---

# 4. BREAK THE REPETITIVE COMBAT GRAMMAR IN THE ACTUAL FIGHT

The previous audit already showed that a very large share of strikes still resolves through the shared grammar. That is visible in real gameplay.

For the 60–90 s fight, significantly reduce reliance on the old universal sequence.

Normal combat should repeatedly return decisions to both players.

Prefer rhythms such as:

`threat -> response -> movement -> tool/power -> contact -> recovery -> reposition -> new read`

rather than:

`opener -> guaranteed string -> launcher -> pursuit -> air route`.

Keep earned conversions when they come from a real setup, trap, counter, guard break, clean launcher, resource spend or wall setup. But ordinary contact must not repeatedly become a mini-cutscene for the defender.

---

# 5. SASUKE MUST ALREADY FEEL LIKE SASUKE, NOT A BRAWLER WITH SPELL SLOTS

In the proof fight, make his existing systems visibly interact.

He should naturally be able to combine several of these during normal play:

- free shuriken / kunai use;
- wire as actual spatial setup;
- fire controlling or changing space;
- Sharingan changing how the player reads the fight;
- Chidori as a **controllable charged physical state**, not only a canned forward attack;
- Chidori usable from coherent situations such as ground sprint, jump/descent, wall exit or angle change;
- limited steering, real momentum, real miss, real recovery;
- Chidori/world collision: if Sasuke misses the opponent and hits valid scenery, the scenery receives the attack;
- lightning interacting with valid conductive objects through shared rules;
- tools/powers remaining relevant outside preset combo routes.

Do not create free 360-degree homing. Freedom must still obey body commitment, inertia and counterplay.

The player should feel: **I have Sasuke's capabilities; I decide how to use them.**

---

# 6. MINATO MUST PLAY THROUGH SPACE HE ACTUALLY CREATED

In the same proof fight:

- marked kunai/anchors must be physically meaningful world facts;
- placement must matter later;
- throwing, planting, recovering and teleporting should combine with movement instead of only firing isolated techniques;
- FTG arrival must not automatically grant a hit;
- arrivals should remain readable and preserve believable orientation/momentum where appropriate;
- Minato should be able to use his network for offense, escape, angle creation, bait and repositioning;
- after some time, the player should visibly understand that Minato has reshaped the battlefield through his anchor network.

Again, this is a proof of the universal persistence/space architecture, not a bespoke Minato minigame.

---

# 7. MAKE THE REACTIVE WORLD VISIBLE IN NATURAL PLAY

`WorldReaction` is useful, but the player should not need to read a commit to know it exists.

During the proof fight, world interaction should happen naturally when appropriate:

- a body smashed into breakable geometry can damage/break it;
- Chidori or another valid high-energy collision can crack/break suitable material;
- tools embed/ricochet according to material;
- ground/wall impacts leave readable traces;
- fire/lightning/slash/blunt impacts produce different consequences where supported;
- the arena accumulates a bounded visual memory of the fight.

Do not force the AI to walk into a tree just to show the feature. The environment must be part of real combat decisions.

After 60–90 seconds, the arena should not look exactly as it did at the start.

---

# 8. DO NOT ADD ANOTHER MAJOR SYSTEM UNTIL THIS PASSES

For this pass, implementation work should primarily be:

- integration;
- tuning;
- replacing old repetitive routes;
- making already-built systems actually trigger in natural play;
- fixing visible bugs;
- improving the arena and camera readability;
- making Sasuke/Minato capabilities genuinely usable;
- iterating through Studio footage.

A new helper module is fine if required to make the visible result work. A new broad architecture layer is not the goal.

Do not optimize for commit size or subsystem count.

Optimize for what the player sees, feels and can decide.

---

# 9. STUDIO LOOP IS THE ACCEPTANCE PROCESS

Repeat this loop until the result is clearly different:

1. play a real fight at normal speed;
2. capture/watch it;
3. identify the most obvious remaining old-game behavior or visual bug;
4. fix it;
5. replay;
6. compare against the pre-Embodiment footage;
7. continue until the difference is undeniable.

Use slow motion only for debugging. Acceptance is judged at normal play speed.

Automated tests still need to pass, but they are not the product acceptance criterion.

---

# FINAL ACCEPTANCE QUESTION

The owner must be able to watch the new fight **without reading the commit notes** and immediately think:

> **"Là, le jeu a changé."**

The fight should communicate:

- greater freedom;
- less repetition;
- more defender agency;
- character-authored powers but player-authored sequences;
- visible supernatural capability;
- meaningful use of movement, tools, chakra and space;
- a reactive battlefield;
- cleaner presentation with fewer obvious bugs.

If the owner instead sees essentially the same battleground-style fight plus a few new effects, wall hits, trees or hidden systems, the pass FAILS.

Do not move on to the next major Embodiment layer until this visible rupture exists.
