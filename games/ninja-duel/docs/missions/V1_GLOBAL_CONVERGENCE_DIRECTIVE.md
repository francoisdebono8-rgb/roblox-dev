# NINJA DUEL — V1 GLOBAL CONVERGENCE DIRECTIVE

## Read this as a product-level directive, not a small feature ticket

You are already in the middle of active development. Do **not** stop the current useful work, do not reset the branch, and do not throw away working improvements.

This document changes the way the remaining work should be approached.

From now on, do not think in terms of isolated mini-missions that end as soon as one subsystem becomes technically present.

Think in terms of the **complete playable V1 experience**.

The repository now contains enough history, combat experiments, fighter sheets, move graphs, animation systems, progression foundations, online foundations, Studio probes, reports, generated builds and prior decisions to understand the intended game.

Use all of it.

Your job is now to converge the project toward a **large, coherent, late-V1 playable build** where the major systems are no longer prototypes existing next to each other, but parts of the same finished-feeling game.

The goal is not perfection in the sense of final launch polish.

The goal is to reach the point where, after this convergence, what remains is predominantly:
- tuning;
- balance;
- art polish;
- VFX polish;
- additional roster content;
- optimization;
- final UX polish;
- production hardening.

It should no longer feel like a collection of promising prototypes.

---

# 1. NON-NEGOTIABLE PRODUCT VISION

Ninja Duel is a fast, readable, accessible ninja fighting game with:

- Storm-like simplicity of execution;
- much greater movement freedom;
- contextual combo routing;
- meaningful defense;
- chakra as a systemic combat resource;
- tools that remain tactically relevant;
- elemental/tool interactions;
- walls, verticality and arena geometry that matter;
- strong fighter identity visible in motion, not only in data;
- awakenings that change behavior, not only multipliers;
- enough roster diversity that the combat engine is stress-tested by different archetypes;
- multiplayer-ready rules and server authority underneath the presentation.

Do not copy Storm one-to-one.

Storm is only the accessibility/readability reference.

The differentiators are:
- freedom;
- chakra systems;
- tools;
- environment;
- fighter-specific mechanics;
- more systemic interactions.

---

# 2. GLOBAL STANDARD: DO NOT CALL A SYSTEM "DONE" BECAUSE IT EXISTS

A recurring failure mode in earlier passes has been:

"the process/system exists in code"

while the actual player-facing result is weak, invisible, awkward, unreliable, ugly, or not truly usable.

That is no longer acceptable.

For every feature, ask all of the following:

1. Does it work technically?
2. Can a player trigger it reliably with normal inputs?
3. Is the result visible and understandable?
4. Does it look coherent with the rest of the game?
5. Does it improve the combat decision space?
6. Does it have an actual gameplay consequence?
7. Does it create bugs or awkward transitions around it?
8. Does it still work when another fighter/system interacts with it?
9. Is it still good when viewed in motion rather than as a frozen screenshot?
10. Would a player notice the feature without reading the source code?

If the answer to several of these is no, the feature is not finished.

---

# 3. WORK AUTONOMOUSLY TOWARD THE END STATE

Do not stop after a small subtask just because one checklist item passes.

When one block reaches an acceptable state:
- inspect the next most important weakness;
- fix it;
- rebuild;
- run tests;
- launch Studio;
- capture or inspect the result;
- compare it with the intended experience;
- continue.

Continue this convergence loop for as long as there is meaningful high-value work that can be completed safely in the current environment.

Stop only when:
- the major V1 experience is genuinely coherent;
- remaining work is mainly polish/tuning/content expansion;
- or an external dependency truly blocks further useful progress.

Do not invent completion because a session has been long.

Do not stop merely because one report was written.

Reports describe the build. They do not replace the build.

---

# 4. GLOBAL VISUAL REVIEW — LOOK AT THE WHOLE GAME, NOT ONLY THE FEATURE YOU JUST TOUCHED

You now have Studio tooling and screenshot/probe infrastructure.

Use it aggressively.

Do not only inspect the exact object you just changed.

Regularly inspect the entire fight scene:
- fighter silhouettes;
- stance;
- arena scale;
- camera framing;
- spacing;
- hit VFX;
- projectile scale;
- wall scale;
- floor readability;
- environmental clutter;
- HUD;
- tool trails;
- chakra effects;
- awakenings;
- victim reactions;
- pose transitions;
- grounded vs airborne movement;
- visual noise;
- ugly geometry;
- obvious Roblox-placeholder appearance.

If something clearly looks bad in a screenshot, fix it even if the corresponding test passes.

Examples:
- Gaara sand should not look like crude blocks, ugly blobs or placeholder geometry.
- Chakra effects should not look like generic neon pasted onto an object.
- Fire should read as fire, not orange particles with no volume.
- Lightning should look sharp, conductive and fast.
- Wind should be readable through motion, pressure and directional shape rather than a random glowing projectile.
- Impact effects must support the strike rather than cover the entire character.

If the current implementation is technically correct but visually poor, continue iterating.

---

# 5. COMBAT FEEL MUST BECOME THE PRIMARY QUALITY BAR

The combat must be tested as continuous play, not isolated move tests.

The target loop is:

distance
→ movement
→ read
→ tool / projectile
→ defensive answer
→ angle change
→ approach
→ clash
→ confirmed hit
→ combo route
→ defender resource decision
→ pursuit / wall / air conversion
→ disengage or finisher
→ neutral resumes.

A 60–90 second fight should naturally express this loop.

The game should not repeatedly collapse into:
- two fighters glued together;
- random light spam;
- repeated generic knockback;
- running back to center;
- isolated jutsu buttons.

---

# 6. COMBOS — ACCESSIBLE, FLUID, CHARACTER-SPECIFIC

This remains one of the highest priorities.

The correct execution philosophy is:

**easy to perform, difficult to land against a knowledgeable defender.**

Do not introduce unnecessary dexterity barriers.

The combo model must satisfy:
- first confirmed hit begins the chain;
- whiffs never advance the chain;
- buffered presses do not invisibly consume combo steps;
- directional intention is forgiving;
- standard routes work under normal human timing;
- transitions between attacks are smooth;
- no confusing off-by-one combo state;
- no route disappearing because the player released a direction a few frames early;
- no hidden requirement to mash at one exact moment.

Then push the actual fighter differentiation.

The same four-button sequence should not produce four visually similar fights.

Each fighter must bend the shared grammar.

Every important combo route should have:
- a clear silhouette;
- a clear purpose;
- a clean animation transition;
- an understandable reaction;
- a meaningful next decision.

---

# 7. FIGHTER IDENTITY — THE PLAYER MUST FEEL IT WITHOUT READING STATS

## Minato

He must visibly fight through:
- speed of decision;
- angle changes;
- marks;
- kunai placement;
- precise re-entry;
- teleport conversions;
- short economical movement;
- Rasengan as a natural conversion/commitment.

He must not simply be "the shared fighter but faster".

His marks should become part of the visible battlefield.

A viewer should see:
strike → mark → reposition → reappear → continue.

Yellow Flash must change route freedom/flow, not merely increase values.

## Itachi

He must visibly fight through:
- calm timing;
- compact body mechanics;
- shuriken woven into strings;
- deception;
- delayed coverage;
- read/counter behavior;
- afterimages that have gameplay meaning;
- fire used to control space.

Mirage/Echo must not be a fake system that only exists under one build configuration.

Base Itachi needs a meaningful deception identity.

Sharingan Focus must change how his reads, counters and deception flow.

## Neji

He must visibly fight through:
- precise palms;
- close-range efficiency;
- tenketsu accumulation;
- chakra denial;
- Rotation counterplay;
- Byakugan awareness.

The opponent must visually understand that their chakra network is being attacked.

Do not rely only on a shrinking resource bar.

Use precise local feedback and victim posture changes.

## Sasuke

He remains the quality benchmark for a fighter whose rules visibly change the scene.

Push:
- kicks;
- verticality;
- pursuit;
- Lion Combo;
- wire;
- shuriken;
- fire;
- lightning;
- Chidori commitment;
- wall conversions;
- Curse Mark risk/reward.

Do not flatten him into the shared combat tree as more characters are added.

## Gaara

Gaara is especially important for global quality because he stresses a completely different archetype.

His sand must look and behave like one coherent combat medium.

Fix anything that looks cheap, blocky, disconnected, or like a placeholder.

The player should see one living sand system supporting:
- shield;
- lashes;
- pillar;
- coffin;
- projectiles;
- displacement;
- defensive body flicker;
- arena control.

Sand must flow from the environment/body context in a visually consistent way.

Do not settle for "the move works" if the sand looks bad.

## Rock Lee

Rock Lee should stress-test:
- pure taijutsu;
- very high tempo;
- chase;
- launch;
- air conversion;
- body animation;
- gates;
- stamina/risk.

Fix Lotus collision/body traversal issues.

His speed should still be readable and grounded in believable body mechanics.

---

# 8. EXPAND THE ROSTER THROUGH THE FRAMEWORK, NOT BY COPYING WHOLE FIGHTERS

The project now has enough infrastructure to stop treating every fighter as a fully manual bespoke project.

Use the production framework.

Create reusable families for:
- stance;
- locomotion;
- light-string archetype;
- launcher family;
- sweep family;
- side route;
- aerial pursuit;
- slam;
- projectile behavior;
- tool behavior;
- awakening presentation;
- defensive identity;
- elemental layer;
- wall route;
- re-engage style.

Then reserve bespoke work for what makes the fighter memorable.

The goal is not to produce 20 shallow clones.

The goal is to make future fighters much faster while preserving unique hooks.

The next meaningful V1 roster should move toward roughly 8–10 actually playable and diverse characters.

Prioritize characters that stress different parts of the engine.

Good candidates from existing sheets include:
- Naruto — clones / rush / unpredictable approach;
- Kakashi — adaptive toolkit / lightning / tactical flexibility;
- Haku — mobility / ice / projectile geometry;
- Temari — extreme range / wind control;
- Shikamaru — trap/control logic;
- Kisame — heavy weapon / water / resource pressure.

Do not add all of them merely to increase a number.

Add the ones that reveal engine weaknesses and widen the playable experience.

A new fighter counts as playable only if:
- selectable;
- basic movement works;
- attacks animate coherently;
- combo routes function;
- at least one clear identity system exists;
- jutsu/tool behavior works;
- no major missing presentation layer makes the fighter feel like a debug dummy.

---

# 9. SYSTEMIC CHAKRA MUST BECOME A CORE DIFFERENTIATOR

The current chakra foundation must be pushed until it is a real combat language.

Chakra is not only a cost meter for jutsu.

It should meaningfully modify:
- tools;
- movement;
- re-engage;
- body attacks where appropriate;
- elemental interactions;
- defensive choices;
- setup/utility.

Maintain simple input design.

A chakra modifier combined with existing actions is preferable to adding many buttons.

The player should be able to understand:
- normal tool;
- chakra-reinforced tool;
- elemental tool where fighter mastery allows it;
- conductive interaction;
- burning interaction;
- wind interaction;
- planted-object interaction.

Behavior must change.

Do not implement infusion as "same projectile + more damage".

Examples of acceptable systemic differences:
- projectile stability;
- deflection behavior;
- guard interaction;
- velocity/trajectory;
- persistence;
- conductive links;
- fire spread/ignition;
- cutting pressure;
- anchor/seal usage;
- collision/interception.

Also visually validate:
- trails;
- contact feedback;
- infused object appearance;
- readability at combat speed.

---

# 10. NINJA TOOLS SHOULD BECOME PART OF COMBAT, NOT SIDE BUTTONS

Tools must participate in the same combat grammar as body attacks and jutsu.

Push:
- kunai;
- shuriken;
- wire;
- planted tools;
- interceptions;
- deflections;
- wall ricochets where appropriate;
- setup into jutsu;
- air tool use;
- retreat tool use;
- pressure/re-engage interactions.

If appropriate and feasible for V1, add first-pass versions of:
- explosive tags;
- smoke tools.

Only if they add clear tactical value.

Do not add clutter for completeness.

---

# 11. ARENA — BUILD THE LARGE CHŪNIN EXAM FIGHTING SPACE, NOT A RANDOM OBSTACLE COURSE

The arena must support the game fantasy and the combat system.

The current direction must converge toward a recognizable, enlarged Chūnin-exam-style arena.

Priorities:
- correct overall scale;
- large fighting floor;
- high surrounding walls;
- stadium/stands architecture;
- participant/viewing ledges;
- believable proportions;
- vertical routes;
- wall run surfaces;
- wall splat surfaces;
- meaningful sightlines;
- room for ranged combat and re-engage;
- enough structure that fights can move through space.

Do not scatter rocks/pillars merely to "make the map less empty".

Every obstacle should have a purpose.

Examples:
- line-of-sight break;
- wall conversion;
- jump route;
- projectile angle;
- escape route;
- temporary cover.

The arena should look intentional in wide screenshots.

The camera must frame the larger space well.

The AI should gradually learn to use more than the center floor.

---

# 12. ANIMATION QUALITY — JUDGE MOVEMENT IN SEQUENCES

Do not only inspect individual poses.

A move can have good key poses and still look bad because transitions are wrong.

Review:
- neutral → attack;
- attack → attack;
- attack → branch;
- branch → pursuit;
- pursuit → air hit;
- air hit → spike;
- spike → landing;
- wall run → attack;
- wall splat → recovery;
- jutsu → movement;
- tool throw while running;
- awakening → combat;
- hit → reaction → recovery.

Continue improving biomechanics:
- support foot;
- planted feet;
- hip drive;
- pelvis rotation;
- torso counter-rotation;
- knee/ankle shape;
- elbow/wrist shape;
- believable recovery.

Avoid mannequin movement, pose snapping, sliding, crossed feet and root-only displacement.

Use reference logic from strong anime fighting games even when authoring original animations.

The goal is not to copy exact copyrighted animation sequences.

The goal is to match the quality principles:
- readable silhouette;
- clear anticipation;
- acceleration;
- impact;
- follow-through;
- recovery;
- continuity.

---

# 13. HIT REACTIONS MUST SELL THE COMBAT

Every improvement to attacker animation is wasted if the victim barely reacts.

Continue differentiating:
- head hits;
- body hits;
- palm strikes;
- knees;
- sweeps;
- launchers;
- spikes;
- wall impacts;
- heavy tools;
- chakra point hits;
- sand captures;
- lightning impact;
- fire pressure.

Reactions should communicate what happened physically.

Do not hide poor reactions behind excessive particles or camera shake.

---

# 14. JUTSU — QUALITY OVER QUANTITY

Audit each playable fighter's jutsu set as part of normal combat.

Every jutsu must be one or more of:
- signature;
- utility;
- setup;
- pressure;
- defensive answer;
- risky finisher.

Remove or redesign moves that feel generic or redundant.

Transitions into and out of jutsu must be combat-quality.

Hand signs, anticipation, cast posture and recovery need visual continuity.

The jutsu should not feel like the game briefly exits the fighting system to play a separate ability animation.

---

# 15. AWAKENINGS MUST CHANGE THE FIGHTER

Do not settle for stat multipliers.

An awakening should visibly change:
- route options;
- cancel rules;
- re-engage behavior;
- resource dynamics;
- defensive capability;
- attack presentation;
- risk/reward.

Examples:
- Minato: teleport/seal flow;
- Itachi: read/deception control;
- Neji: full-field perception/chakra oppression;
- Sasuke: Curse Mark aggression/risk;
- Lee: Gates speed/pressure/body cost;
- Gaara: stronger living-sand control.

The player should feel the mode switch immediately.

---

# 16. CAMERA / PRESENTATION / HUD

The game should increasingly look like one product.

Audit:
- camera distance;
- FOV;
- wall framing;
- air combo framing;
- large-arena framing;
- pursuit framing;
- camera shake restraint;
- hitstop restraint;
- combat UI density;
- combo text;
- chakra readability;
- awakening readability;
- tutorial hints.

Do not drown the player in prompts.

The combat should teach itself through consistency.

Use UI only where the world/animation cannot communicate enough.

---

# 17. MULTIPLAYER FOUNDATION MUST REMAIN COMPATIBLE

Do not ignore multiplayer architecture while improving the single-player feel.

Every major combat change must remain compatible with:
- server authority;
- two-player state;
- online protocol;
- prediction/reconciliation assumptions.

Do not expand online scope unnecessarily before the core is good.

But do not introduce major systems that would later require rewriting the whole combat model for multiplayer.

When the combat reaches a sufficiently coherent state, perform a real two-client Studio test if the environment supports it.

Document whether latency-sensitive systems need additional work.

---

# 18. AI SHOULD BECOME A REAL STRESS-TEST PLAYER

Use AI not just as an opponent but as an automated systems tester.

Make AI exercise:
- ranged pressure;
- defense;
- pursuit;
- re-engage;
- walls;
- verticality;
- tools;
- chakra decisions;
- fighter-specific mechanics;
- awakenings;
- disengagement.

Run diverse matchup soaks.

Use failures to find systemic bugs.

If every AI fight happens in the center using the same two options, the stress test is too weak.

---

# 19. BUILD AND TEST DISCIPLINE

Keep the strong build discipline already introduced.

Every meaningful source change should preserve:
- normal build;
- Debug build;
- QA build;
- automated test integrity.

Do not weaken tests merely to make them pass.

Add regression coverage for every real bug found.

But remember:

TECHNICAL PASS ≠ PLAYER-FACING PASS.

For every large visual/system pass, also use Studio.

---

# 20. SCREENSHOT / VIDEO-LOGIC REVIEW LOOP

Even without a human continuously watching, you can make much better visual judgments than a purely headless workflow.

Use staged screenshots and probes at representative combat moments.

Capture:
- neutral;
- approach;
- first hit;
- mid-string;
- launcher;
- air conversion;
- tool impact;
- chakra infusion;
- awakening;
- wall interaction;
- jutsu cast;
- victim reaction;
- wide arena shot.

Look for:
- clipping;
- oversized effects;
- ugly primitives;
- missing effects;
- visual discontinuity;
- bad proportions;
- floating bodies;
- feet sliding;
- environment scale mismatch;
- effects that obscure the action;
- character identity that disappears at combat speed.

Fix obvious problems immediately.

Do not postpone all visual judgment to the human user.

---

# 21. PRIORITIZATION RULE

At any moment, work on the highest-value remaining problem in this order:

1. Broken / unreliable controls or combo state.
2. Major combat bugs.
3. Bad animation / transition issues that visibly damage feel.
4. Fighter identity that is mechanically present but visually weak.
5. Chakra/tools that exist but lack meaningful interaction.
6. Re-engage / wall / air flow gaps.
7. Arena scale/function issues.
8. Major ugly/placeholder VFX.
9. Roster expansion through reusable framework.
10. AI stress coverage.
11. Multiplayer validation.
12. Progression/UX only where necessary for a coherent V1.

Do not spend an hour polishing a menu while a core strike animation is broken.

Do not add three new fighters while the production framework produces obviously bad generic animation.

Do not endlessly polish CORE4 while the engine has never been stress-tested by different archetypes.

Balance these priorities intelligently.

---

# 22. DEFINITION OF A LARGE V1 CANDIDATE

Do not declare this directive complete until the build is close to the following state:

## Combat
- controls reliable;
- confirmed-hit combo model reliable;
- forgiving intent recognition;
- smooth attack transitions;
- clear defense;
- good pursuit/re-engage;
- useful air routes;
- useful wall routes;
- satisfying hit reactions;
- no major repeated snap/slide/overshoot bugs.

## Fighter identity
- six current fighters visibly distinct;
- additional fighters added through the new framework where productive;
- no major fighter whose identity is mainly stat multipliers;
- awakenings visibly change play.

## Chakra/tools
- chakra modifier works naturally;
- infusion visibly changes behavior;
- tools participate in combat routes;
- elemental/tool interactions have real use;
- projectiles can meaningfully interact where appropriate.

## Arena
- large, recognizable Chūnin-exam-inspired stadium;
- correct combat scale;
- useful walls/verticality;
- not cluttered with arbitrary props;
- camera supports the scale.

## Visual quality
- no obviously placeholder-looking major combat effect;
- Gaara sand looks coherent and intentional;
- core jutsu visually readable;
- hit VFX support rather than hide combat;
- character animation remains readable at speed.

## Roster
- production framework proven on multiple distinct archetypes;
- approximately 8–10 playable fighters if achievable without lowering quality;
- otherwise fewer but with the framework genuinely ready to scale.

## AI
- diverse matchups complete without errors;
- AI exercises more than center-stage melee spam.

## Multiplayer
- architecture remains intact;
- real two-client validation performed when feasible;
- known latency issues documented honestly.

## Build quality
- tests pass;
- normal/debug/QA builds updated;
- known limitations separated from completed work.

---

# 23. FINAL REPORTING RULE — BE STRICTLY HONEST

At the end of this convergence, report using four categories only:

### VERIFIED PLAYABLE
Actually exercised in Studio/gameplay with evidence.

### IMPLEMENTED BUT NEEDS HUMAN FEEL JUDGMENT
Works technically and has been inspected, but user feel remains unknown.

### PARTIAL / FOUNDATION
Architecture or first implementation exists but the player-facing feature is incomplete.

### NOT IMPLEMENTED
No euphemisms.

Do not call:
- a design sheet playable;
- a unit-tested VFX beautiful;
- a headless mechanic visually validated;
- a server protocol multiplayer-tested;
- a configurable process a finished gameplay feature.

Also include:
- exact build tested;
- exact branch head;
- automated test counts;
- Studio scenarios performed;
- remaining visual defects;
- remaining gameplay defects;
- recommended human test order.

---

# FINAL DIRECTIVE

Do not optimize for "finishing the ticket".

Optimize for making the game itself substantially closer to its final V1 form.

Keep what works.
Improve what is weak.
Remove or redesign what is generic.
Use the repository's existing foundations instead of reinventing them.
Use Studio constantly.
Use screenshots critically.
Use automated tests aggressively.
Use additional fighters to stress-test the combat language.
Make chakra/tools/environment the reason this game is more free than Storm.
Make the fighter identities visible in motion.
Make the arena support the fantasy.
Make the transitions smooth enough that the game stops looking like a prototype.

Do not stop at "technically implemented".

Continue until the build is a coherent late-V1 candidate and the remaining work is genuinely mostly polish, tuning and content expansion.
