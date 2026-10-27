# FUTURE MISSION — ANIMATION MASTERY + COMBAT BREAKTHROUGH

Date: 2026-10-27
Status: FUTURE / do not execute until explicitly activated by the user.

This mission does not replace the current reference-quality mission. It preserves its requirements and adds a harder prerequisite: Claude must actually become highly competent at character animation for Ninja Duel, not merely automate pose values through Blender.

## Core product target

Do not add another abstract layer. Do not restart systems that already work. Do not hide weak body motion with more VFX.

Starting from the current game, make the **body of the characters** cross the quality gap shown by the Itachi benchmark.

The result must still look excellent when:
- major VFX are disabled;
- camera treatment is simple;
- HUD is hidden;
- only silhouettes, trajectories, timing and body mechanics are visible.

The permanent test remains:

> **Je ne veux plus voir les systèmes. Je veux voir un combat.**

---

# 1. FIRST REQUIREMENT — LEARN ANIMATION FOR REAL

This is not optional background reading.

Before continuing large-scale production, Claude must deliberately train until it can produce convincing professional-quality character animation principles on the Ninja Duel rig and explain why they work.

Do **not** interpret “learn Blender” as:
- skim documentation;
- watch one tutorial;
- generate keyframes with Python;
- bake/export successfully;
- produce a mathematically different clip;
- claim mastery because the pipeline works.

The current Blender pipeline is valuable, but much of the animation is still authored like code: numeric joint angles, a few scripted poses, interpolation, then bake/export. Preserve the automation, but stop using Python as the main animator.

**Python = pipeline and repetitive automation.**

**Blender = real animation authoring.**

Claude must become strong at the actual craft:
- posing;
- silhouette;
- timing;
- spacing;
- weight;
- center of gravity;
- support foot and contacts;
- anticipation;
- arcs;
- breakdowns;
- overlap;
- drag and follow-through;
- overshoot;
- settling;
- asymmetry;
- body mechanics;
- weight transfer;
- locomotion mechanics;
- impact mechanics;
- recovery;
- Graph Editor / F-curves;
- readable staging;
- character-specific physical acting.

The goal is not to know the vocabulary. The goal is to **be able to create a new high-quality movement from first principles**.

---

# 2. MANDATORY LEARNING CURRICULUM

Use serious online resources and study them actively before claiming readiness.

Priority sources:
- Blender Studio — Animation Fundamentals;
- Blender Studio — Character Animation / animation workflow material;
- Blender official documentation for Graph Editor, Dope Sheet, interpolation, constraints, IK/FK and animation workflow;
- Roblox Creator Hub for Animation Editor, Curve Editor, R15 rigs, IK, importing animation data and Blender/FBX/glTF workflows;
- high-quality professional character-animation resources when a specific body-mechanics problem remains unclear.

At minimum, Claude must deeply understand and practice the parts relevant to Ninja Duel:
- principles of animation;
- animation workflow and terminology;
- drag and follow-through;
- jump;
- walking/running biped;
- basic body mechanics;
- advanced body mechanics / weight shift;
- posing and breakdowns;
- Graph Editor basics and tools;
- import/export animation workflow;
- constraints and IK where useful.

Do not waste time on unrelated modelling/rendering/acting topics that do not improve Ninja Duel.

But also do **not** skip fundamentals just because they look simple. If a professional animation course uses a basic exercise to teach timing, spacing or weight, learn the principle and then immediately apply it to the Ninja Duel rig.

The learning loop is:

**study -> explain principle -> reproduce it -> apply it to a real Ninja Duel motion -> test in Studio -> critique -> correct.**

No passive “I watched it”.

---

# 3. COMPETENCY GATE — PROVE THE LEARNING BEFORE MASS PRODUCTION

Before scaling the new animation method across the roster, Claude must pass a practical competency gate on the actual Ninja Duel rig.

Create and refine these exercises until they visibly read correctly without VFX:

1. **Weight shift / stance transfer**
   - clear support leg;
   - hips and torso follow the support change;
   - no floating center of gravity.

2. **Ninja acceleration -> sprint -> brake -> direction change**
   - body leans for acceleration;
   - foot contacts match speed;
   - braking changes body mechanics;
   - direction change has planted support, not a rotating root.

3. **Take-off -> airborne arc -> prepared landing -> absorption -> immediate exit**
   - anticipation before push;
   - leg extension causes launch;
   - airborne pose follows momentum;
   - feet search for ground before impact;
   - landing compresses then releases.

4. **Committed strike**
   - force begins from floor/hips/body, not isolated limb;
   - readable anticipation;
   - fast spacing around impact;
   - overshoot and follow-through;
   - natural recovery.

5. **Directional hit reaction**
   - contact location and direction propagate through the body;
   - head/arms may lag;
   - balance is lost/recovered believably;
   - reaction does not simply swap to a canned pose.

6. **Continuous gameplay transition**
   - run -> jump -> attack -> miss -> landing -> run;
   - no visible animation-state seam.

For each exercise Claude must be able to state:
- where the weight is;
- what initiates the motion;
- what follows later;
- where the fastest spacing occurs;
- where the body absorbs or redirects momentum;
- why the key poses are readable.

If Claude cannot explain and reproduce these principles on a different movement, the competency gate has not passed.

---

# 4. LEARN ONLY TO IMPROVE THE GAME — THEN APPLY IMMEDIATELY

Do not spend days studying Blender in the abstract.

When a gameplay movement is bad, learn the exact animation problem needed to solve it.

Examples:

### Bad jump
Study anticipation, compression, center of gravity, push-off, airborne arc, landing preparation and impact absorption.
Then immediately rebuild the actual Ninja Duel jump.

### Weak strike
Study weight transfer, hips-first motion, anticipation, impact spacing, overshoot and follow-through.
Then immediately rebuild a real combat strike.

### Sliding feet
Study contacts, support foot, root trajectory, cycle speed and IK/contact solutions where appropriate.
Then fix the actual locomotion.

### Artificial hit reaction
Study force direction, impulse propagation, overlap and balance recovery.
Then rebuild that reaction.

Every learning block must end inside **the real game**.

---

# 5. REFERENCE RESEARCH IS MANDATORY — NEVER GUESS A CHARACTER

If there is doubt about how a ninja moves, attacks, stands, lands, uses a weapon or performs a technique, Claude must research it autonomously before authoring the animation.

Do not rely on vague memory.

Search for the most relevant visual references available:
- anime scenes;
- manga panels when useful for pose/intent;
- official game footage;
- high-quality character showcases;
- real martial arts / acrobatics / weapon references when they clarify body mechanics.

Example:
- if authoring Chidori, go watch Sasuke actually forming, carrying, running with and striking with Chidori;
- if authoring Flying Thunder God, study Minato’s preparation, kunai relationship, orientation and arrival behavior;
- if authoring Lee, study how his body, hips, legs and effort differ from Sasuke;
- if authoring Zabuza, study how a massive cleaver changes posture, inertia and recovery;
- if authoring Kimimaro, study how bone weapons grow from and alter the body;
- if authoring Haku, study senbon, mirror exits and light footwork;
- if authoring Gaara, study how calm body acting contrasts with active sand;
- if authoring Neji, study compact palm mechanics and centered posture;
- if authoring Bee, study the multi-sword configurations rather than inventing generic sword swings.

Do not copy exact copyrighted animation frame-for-frame. Extract:
- physical intention;
- posture;
- rhythm;
- weight;
- recognizable body language;
- technique logic;
- relationship to weapon/power/terrain.

Then author an original gameplay animation consistent with Ninja Duel.

---

# 6. THIS RULE APPLIES TO THE ENTIRE ROSTER

Sasuke and Minato are the first proving ground because they are the current finished-quality vertical slice.

They are **not** the limit of this mission philosophy.

The animation mastery and reference workflow becomes a permanent production rule for all 20 target fighters in `docs/characters/ROSTER_20.md`.

For every fighter, before large animation work, Claude must understand from the Combat Bible + outside visual research:
- idle posture;
- center of gravity;
- locomotion rhythm;
- acceleration/braking style;
- jump/air/wall behavior where relevant;
- guard/defensive body language;
- hit reaction character/weight;
- Light/Heavy body mechanics;
- weapon/tool relationship;
- hand-seal/body-preparation behavior where relevant;
- signature technique body logic;
- how the fighter exits a move and returns to control.

HUD hidden, each fighter must become recognizable from body language and combat grammar.

The shared engine may stay shared.
The visible body performance must not collapse into the same animation family with different colors.

---

# 7. KEEP THE EXISTING BLENDER PIPELINE — CHANGE HOW ART IS AUTHORED

Keep what already works:
- Blender rig setup;
- automated jobs;
- clip export;
- conversion to runtime data;
- build integration;
- marker timing;
- useful retargeting infrastructure;
- automated filming/boards;
- tests.

But stop treating scripted numeric poses as the artistic source of truth for important animation.

For important motions:
1. establish strong key poses in Blender;
2. create meaningful breakdowns;
3. inspect arcs and contacts;
4. refine timing/spacing in Dope Sheet and Graph Editor;
5. use constraints / IK where they improve contact and mechanics;
6. only then use scripts to automate repetitive export/processing.

The script should preserve the authored animation, not invent most of it.

---

# 8. NEW MANDATORY WORK LOOP FOR EVERY IMPORTANT MOTION

## A — INTENTION
Describe the actual physical action.

Not “Chidori animation”.

Instead:
“Sasuke compresses, forms Chidori, protects the charged arm, commits his body forward, accelerates, can still navigate within bounded steering, and must physically carry the miss/hit momentum into the exit.”

## B — REFERENCE
Study the Itachi benchmark plus character-specific references and real-body references when useful.

Extract principles, not exact frames.

## C — TARGETED LEARNING
If a skill is missing, study it now.

Do not improvise badly because the answer is unknown.

## D — BLENDER AUTHORING
Block strong poses first.
Then breakdowns.
Then timing/spacing.
Then arcs/contacts.
Then Graph Editor curves.
Then overlap/follow-through.

Do not flood the timeline with keyframes before the poses and mechanics work.

## E — SILHOUETTE TEST
Disable distracting effects.
Every major pose should read clearly.

## F — ROBLOX INTEGRATION
Integrate into the existing gameplay systems immediately.

## G — REAL INPUTS
Trigger through actual gameplay controls, not only a scripted playback.

## H — COMPARE
Compare:
- old game;
- new animation;
- target reference.

If an ordinary viewer cannot immediately see the improvement, continue working.

---

# 9. BODY MECHANICS IS THE PRIORITY

For every important action answer:
- Where is the center of gravity?
- Which foot/body part supports the weight?
- Where does the force begin?
- What initiates the action?
- What follows a few frames later?
- What creates the arc?
- What brakes the motion?
- What happens to momentum after hit or miss?
- How does the body regain balance?

Arms and legs must not merely animate around a floating torso.

**The entire body produces the action.**

---

# 10. PLAYER FREEDOM MUST SURVIVE THE ANIMATION UPGRADE

Do not turn Ninja Duel into locked cinematics.

Blender may author:
- starts;
- take-offs;
- landings;
- changes of support;
- locomotion cycles;
- attacks;
- reactions;
- preparations;
- releases;
- signature transitions;
- recoveries.

The game engine still owns:
- real movement;
- player intent;
- direction;
- momentum;
- collision;
- hit detection;
- chakra;
- walls;
- projectiles;
- world interaction;
- hit/miss;
- cancels;
- terrain;
- defender agency.

Animation supports the physical gameplay event. It must not teleport the player to a predetermined ending pose.

---

# 11. SASUKE — FIRST ARTISTIC PROVING GROUND

Do not rebuild his existing systems. Transform their body expression.

### Locomotion
Re-evaluate and upgrade:
- idle;
- run start;
- ninja run;
- acceleration;
- braking;
- direction changes;
- sprint;
- jump;
- lateral/back jumps;
- wall movement;
- wall exit;
- fall;
- landing;
- recovery.

### Taijutsu
Light/Heavy actions must show:
- anticipation;
- real weight transfer;
- readable trajectory;
- impact timing;
- overshoot;
- follow-through;
- natural recovery.

Sasuke must not look like a generic fighter with Uchiha VFX.

### Shuriken / kunai / wire
Throws must work visually while moving and remain physically connected to the hand/body action.

### Katon
Body must tell:
preparation -> seals -> inhale/compression -> projection -> follow-through.

### Chidori — main proof
Study Sasuke references before authoring.

The existing gameplay capability should support, where already intended:
- formation;
- running with it;
- bounded steering;
- jumping;
- wall use;
- plunge;
- hit;
- miss;
- world contact;
- continuation/recovery.

Shoulder, torso, charged arm, legs, speed and trajectory must tell the same action.

---

# 12. MINATO — PROVE THE METHOD CREATES A DIFFERENT PERSON

Then apply the same professional method to Minato.

He must not look like a faster Sasuke.

Focus on:
- economy of movement;
- exact foot placement;
- low unnecessary motion;
- fast angle changes;
- kunai throws during locomotion;
- body already prepared for the next choice after FTG;
- coherent arrival orientation/momentum;
- Rasengan with real body mechanics.

FTG must never read as:
pose -> disappear -> unrelated pose.

It should read as:
intent/setup -> disappearance -> arrival with coherent body state -> next decision.

---

# 13. REACTIONS AND DEFENCE

The current Blender reactions/guard/dodges are useful functional work. Do not throw them away automatically.

But re-evaluate them artistically because many were generated from scripted pose parameters.

Keep what already reads well.
Re-author what does not.

Reaction quality should account for:
- contact location;
- direction;
- strength;
- previous velocity;
- current support;
- ground/air state;
- nearby world contact;
- fighter body/weapon identity when relevant.

---

# 14. NO-MAKEUP TEST

Before adding more large VFX:
- disable major effects;
- reduce camera tricks;
- use readable lighting;
- record the body.

If the action is not already good:

**DO NOT ADD VFX TO SAVE IT.**

Fix the animation/body mechanics first.

---

# 15. CONTINUITY TEST

Inspect especially:
- run -> jump;
- run -> attack;
- jump -> attack;
- wall -> attack;
- attack -> movement;
- knockback -> landing;
- launcher -> pursuit;
- pursuit -> air attack;
- miss -> recovery;
- teleport/FTG -> next action.

No transition should feel like the engine replaced the current body with a new animation.

The next action must inherit believable pose, velocity, facing, support and momentum.

---

# 16. GRAPH EDITOR IS PART OF THE CRAFT

Do not only pose and accept default interpolation.

For important actions inspect curves deliberately:
- acceleration;
- deceleration;
- impact spacing;
- overshoot;
- settling;
- held contacts;
- follow-through.

Curves must serve physical intention, not just look smooth mathematically.

---

# 17. DEFINITION OF DONE FOR AN ANIMATION

An animation is not done because:
- it exports;
- tests pass;
- Blender produces no error;
- it has more frames;
- it has more keyframes;
- it is numerically different;
- a comparison script says it changed.

It is done when:

**a human immediately sees that the body movement is significantly better, believable, character-specific and pleasurable to watch.**

---

# 18. FIRST VISIBLE DELIVERY

Produce real-input gameplay sequences, not cinematics.

### Sasuke sequence
Naturally include:
run -> angle change -> jump/wall -> tool -> taijutsu -> Chidori -> hit or miss -> landing/recovery.

### Minato sequence
Naturally include:
run -> kunai -> reposition -> FTG -> taijutsu or evade -> Rasengan -> exit.

Record with major VFX both ON and OFF.

---

# 19. FINAL VERTICAL-SLICE COMBAT

Play a real Sasuke vs Minato round for roughly 60–90 seconds using normal gameplay inputs.

The fight should naturally show:
- verticality;
- misses;
- defence;
- tools;
- jutsu;
- changes of rhythm;
- terrain;
- recoveries;
- player decisions;
- different body identities.

Do not script a showcase choreography to hide gameplay weaknesses.

---

# 20. ACCEPTANCE BAR

Compare directly with:

`games/ninja-duel/reference/itachi-quality-benchmark.mp4`

The question is not:
“Do we have as many particles?”

The question is:

**Are the characters now as intentionally animated, physically coherent, character-specific and enjoyable to watch move?**

The user should see the result and think:

> I no longer see states changing. I see Sasuke fighting Minato.

Then the learned method must scale across the complete roster through the Combat Bibles and character-specific research.

---

# 21. PERMANENT PRODUCTION RULE AFTER THIS MISSION

Do not finish this as a one-off Sasuke/Minato polish pass.

The real deliverable is a repeatable production method:

**character research -> animation learning when needed -> strong authored poses -> body mechanics -> Blender refinement -> export automation -> Studio gameplay -> visual critique -> correction.**

For every future fighter or technique:
- consult its Combat Bible;
- research how the character actually moves/uses the technique when uncertain;
- learn any missing animation principle before improvising;
- author the body properly;
- test without VFX;
- integrate into real gameplay;
- iterate until the visible result passes.

The project already has systems. The next quality leap comes from learning to animate them like a real action game.