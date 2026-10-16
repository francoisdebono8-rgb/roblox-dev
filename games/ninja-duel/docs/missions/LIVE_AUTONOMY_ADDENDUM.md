# LIVE ADDENDUM — continue current mission autonomously

You are already in the middle of the CORE COMBAT CONVERGENCE 2 mission. Do **not** stop or restart your work because of this note. Treat this as a live priority update and integrate it into what you are already doing.

## Main instruction

Continue working autonomously for as long as useful. Do not stop at the first passing build or the first visible improvement. Keep iterating until the current branch is as advanced, playable, visually convincing and internally consistent as you can reasonably make it in this session.

If one of the points below has already been implemented, do not redo it from scratch. Instead:
- test it in Studio;
- remove bugs / edge cases;
- improve its feel and readability;
- make sure the final report clearly distinguishes what is actually implemented from what is only planned.

Do **not** claim a system exists because the data/config/docs describe it. Only call it implemented if it is actually reachable and observable in the generated game build.

---

## 1. Inputs and combo state are still a top priority

Hands-on feedback still suggests the input/combo model may not yet be fully corrected.

The target remains Storm-like accessibility:
- few buttons;
- combos easy to execute;
- depth comes from route choice, reads, defense, resource use, pursuit and counters;
- not from frame-perfect command execution.

Mandatory behavior:
- the combo starts on the **first confirmed hit**, not on the first button press;
- whiffs must not advance the confirmed combo state;
- buffered inputs must not make the game feel one attack ahead of the player;
- after a broken string, combo state must reset cleanly;
- directional branches must be forgiving and based on buffered player intent, not one exact stick frame;
- `light -> light -> forward+light`, `back+light`, `side+light`, etc. should be reliable in normal play;
- normal strings must not require hidden frame-perfect timing.

Audit the actual runtime state transitions, not only tests:
`combo`, `queuedLight`, `buffered`, `chainOpen`, `chainAt`, `lastAttack`, `airCombo`, pursuit arrival, technique arrival and recovery cancels.

If you already changed this, validate it specifically in Studio and keep improving until the controls feel predictable.

---

## 2. Keep improving the combo work already in progress

The recent direction is good: combos are finally becoming more visual and character-specific. Continue that work.

But do not merely add more route tables. The result must be visible in the body and in the flow of a fight.

For every CORE4 fighter, keep pushing toward:
- simple base string;
- clearly different forward / low / side route;
- useful heavy conversion;
- air continuation;
- spike / slam / drive choice;
- wall conversion when appropriate;
- tool or jutsu conversion;
- intuitive re-engage after separation.

Each route should have:
- a purpose;
- a distinct silhouette;
- a clear next decision;
- reliable execution.

Use Itachi's launcher + shuriken cover and Sasuke's LionKick -> Shadow of the Dancing Leaf -> Lion Combo as the quality benchmark: simple input, immediately visible identity, natural continuation.

---

## 3. Character identity must be felt, not just configured

If a difference only exists as a number, it is not enough for a major identity trait.

### Minato
The player should constantly feel:
- short precise repositioning;
- angles;
- marks;
- kunai geometry;
- FTG re-entry;
- fast but controlled recovery.

His combat should not read as "the shared fighter but faster".

If Wind Cut still feels generic, redesign/refocus it or replace its role. Do not keep a weak move just to preserve the current list.

### Itachi
Make deception actually work in the base playable kit.
- launcher + shuriken cover is a good direction;
- Read must visibly feel like a read;
- Feint / afterimage / Mirage behavior must be reachable and reliable;
- do not hide the core fantasy behind an unselected progression node.

### Neji
His chakra/tenketsu pressure is currently too easy to experience only as bar changes.
Make it visible and physical:
- precise palms;
- local chakra-point feedback;
- different hit reactions;
- readable accumulation of closed points;
- smooth Rotation -> counter flow;
- 64 Palms should feel like the climax of the system.

### Sasuke
Keep the strong identity already emerging:
- kicks;
- vertical pursuit;
- Lion Combo;
- VaultKick;
- wire/fire/lightning possibilities;
- Chidori commitment;
- Curse Mark risk/reward.

Use Sasuke as a benchmark for how much a fighter-specific rule should change the scene.

---

## 4. Re-engage / chakra dash must become natural

Combat still benefits from a faster, cleaner way to return to an opponent after knockback or separation.

Consolidate Rush/Pursuit into an intuitive primary combat action where appropriate.

Requirements:
- natural controller input, not an awkward D-pad primary action;
- target-aware when locked;
- usable after suitable knockbacks / launchers / conversions;
- cancelable into sensible combat options;
- resource cost and punishability;
- different expression by fighter.

Minato should feel surgical, Sasuke explosive, Neji compact, Itachi deceptive.

---

## 5. Chakra infusion / ninja-tool freedom must not be forgotten

This is still one of the main systems that should differentiate Ninja Duel from Storm.

Do not postpone it indefinitely.

The target is not "chakra = mana for jutsu".
The target is:

`tool/body action + chakra + element/mastery + context = modified behavior`

Do not add a large number of buttons. Prefer a contextual chakra modifier combined with existing actions.

At minimum, start implementing a robust systemic slice of:
- normal tool vs chakra-reinforced tool;
- visibly different trajectory / contact / stability, not only extra damage;
- projectile interception / deflection where practical;
- planted projectiles remaining useful where appropriate;
- wire as a real gameplay object;
- lightning + metal/wire interaction;
- wind + kunai behavior;
- fire + relevant tool/zone interaction.

If the full system cannot be completed in one pass, implement a coherent working vertical slice that is actually playable and extendable. Do not fake completion in documentation.

---

## 6. Arena: correct the concept, not just add props

Current feedback: adding random rocks/pillars is not enough and can move away from the intended fantasy.

The target is a **larger gameplay-adapted version of the real Chunin Exam arena**, with believable proportions and scale.

Prioritize:
- overall diameter;
- wall height;
- arena scale relative to fighters;
- recognizable Chunin Exam architecture;
- proper long-distance fighting lanes;
- enough empty space for pursuit, projectiles and re-entry;
- useful walls / elevation / routes.

Only keep rocks/pillars/obstacles when they have a clear gameplay reason such as:
- cover;
- wall splat;
- jump / traversal;
- line-of-sight change;
- vertical route.

Do not clutter the arena simply to make it look more complex.

---

## 7. Begin scaling the roster more efficiently

Do not abandon the CORE4 polish, but do not design the production process as if every future fighter must be handcrafted from zero.

We need a faster **character production framework**.

Build reusable fighter components / archetype layers for things such as:
- stance and locomotion family;
- combo grammar;
- launcher family;
- side route family;
- air route family;
- pursuit / re-engage family;
- tool package;
- elemental package;
- defensive mechanic;
- awakening hook;
- reaction / animation building blocks.

Then spend bespoke effort only on the 30–40% that creates identity.

Goal after the CORE4 pass:
start bringing additional fighters to a **playable stress-test level** faster, so the larger variety exposes engine weaknesses earlier.

High-value next playable candidates already designed:
- Naruto;
- Gaara;
- Rock Lee;
- Kakashi;
- Haku;
- Temari.

Do not make all of them polished before testing.
A good strategy is:
- CORE4 = higher quality bar;
- additional 4–6 = playable mechanical stress-test roster;
- then use the discovered issues to harden the shared framework.

More playable archetypes will help expose:
- animation repetition;
- movement assumptions;
- projectile bugs;
- wall/air bugs;
- tool-system limitations;
- character-state leaks;
- networking assumptions.

If you have enough time after the current core tasks are genuinely working, start laying this reusable framework and bring at least one or two additional designed fighters closer to actual playability rather than producing more design-only documents.

---

## 8. Work autonomously and keep iterating

Do not stop simply because one checklist is technically satisfied.

Use the remaining session to make the game as advanced as reasonably possible.

Recommended autonomous loop:
1. inspect current behavior;
2. implement the highest-impact visible improvement;
3. rebuild;
4. test in Studio;
5. compare intended vs actual behavior;
6. fix what is visibly wrong;
7. run automated regression tests;
8. continue to the next highest-impact issue.

Prioritize actual player-facing progress over documentation volume.

Do not wait for another user message if you can safely continue the current mission.

---

## 9. Truthfulness / final report requirement

The final report must separate:
- IMPLEMENTED AND PLAYABLE;
- IMPLEMENTED BUT NEEDS MORE FEEL POLISH;
- PARTIAL / FOUNDATION ONLY;
- NOT IMPLEMENTED.

For each major claim, point to the actual runtime behavior / file / test that supports it.

Do not say things like:
- "Mirage works" if only config/data exists;
- "chakra infusion exists" if it is only described;
- "fighter is playable" if only a design sheet exists;
- "arena validated" if it was not actually inspected in Studio.

Keep existing good work. Improve it rather than replacing it unnecessarily.

The desired result when the user returns is not a bigger checklist. It is a game that has visibly moved forward by a large amount.
