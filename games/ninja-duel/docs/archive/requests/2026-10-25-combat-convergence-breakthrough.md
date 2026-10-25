# NEXT MISSION — COMBAT CONVERGENCE BREAKTHROUGH

**Status: ACTIVE / NEXT EXECUTION TARGET**

This mission starts from the current head of `claude/ninja-duel-2026-10-14` after Movement Overhaul passes 1–4 (`a3eb920` + report commit).

The movement work is useful and must be preserved. It is **not** the final target.

The next delivery must create an **obvious visual rupture** in normal-speed gameplay. If a player familiar with the current build watches 15–20 seconds before/after and has to be told what changed, this mission is NOT complete.

The qualitative reference remains the user-provided Naruto-style combat video analyzed on 24–25 October. Do not copy individual moves. Extract and reproduce the principles that make the whole fight feel continuous, integrated, physical and polished.

> **The player must stop seeing the systems and start seeing the fight.**

---

## 0. NON-NEGOTIABLE OUTCOME

This is NOT "movement overhaul pass 5".

Do not spend the session adding isolated features and declaring success because tests pass.

The next build must make a fight look dramatically more authored and coherent in these areas at the same time:

- two-body choreography;
- attack/defender relationship;
- feet / support / body weight;
- continuous transitions;
- hit reactions;
- whiff and recovery;
- weapon/object integration;
- VFX timing and attachment;
- high-speed readability;
- visible bug removal;
- per-fighter physical identity.

The goal is not more content. The goal is that **existing content suddenly looks like it belongs to one combat system instead of many Roblox systems joined together**.

### Hard acceptance statement

At normal speed, a 20-second no-jutsu combat sequence must already look like a ninja anime fight.

No jutsu is allowed to hide weak body mechanics.

---

# 1. DEVELOPMENT UNIT = A FIGHT, NEVER A FEATURE

From this point forward, implement and validate through complete combat sequences.

Do not validate:

- "dodge works";
- "M1 works";
- "kunai works";
- "wall-run works";
- "launcher works";
- "reaction works".

Validate things such as:

`approach -> footwork -> jab -> defender slips -> attacker pivots -> body hit -> defender folds -> attacker changes side -> block -> riposte -> separation`

`run -> kunai draw -> throw while moving -> defender avoids -> attacker closes -> taijutsu -> knockback -> recovery -> chase`

`launcher -> pursuit -> air exchange -> defender spike/recovery -> landing -> immediate grounded continuation`

`pressure -> wall -> wall interaction -> counter -> exit -> return to neutral combat movement`

Every changed system must answer:

> **What became visibly better inside an actual fight?**

If the answer is only a file/function/state/test name, the work is not finished.

---

# 2. PRESERVE THE MOVEMENT GAINS — THEN BUILD ON THEM

Passes 1–4 already improved:

- momentum after dodge;
- running strikes;
- jump + attack continuity;
- air steering;
- wall run / wall jump;
- wall exits;
- contextual acrobatics;
- per-fighter sprint expression;
- some per-fighter inertia;
- Studio-driven route testing.

Do NOT regress these.

But do not confuse a continuous movement route with a convincing fight.

The current report itself still admits important weaknesses:

- no dedicated foot-sliding audit;
- end of air combo can hold the body ~0.4 s before falling;
- HUMAN_VISUAL/FEEL still pending;
- some fighters only validated headless;
- movement route testing still focuses heavily on one active fighter rather than full two-body exchange quality.

These weaknesses are now first-class targets.

---

# 3. THE BIGGEST MISSING SYSTEM: TWO-BODY CHOREOGRAPHY

The reference does not look good because one fighter has nice animations.

It looks good because BOTH fighters appear to belong to the same exchange.

A strike should create the next spatial and visual situation.

The defender is not a target dummy that switches to `HitStun`, `Knockback` or `Knockdown`.

The defender must respond with a body result that corresponds to:

- hit direction;
- hit height / zone;
- strike weight;
- current momentum;
- current support leg / stance;
- airborne vs grounded state;
- wall proximity;
- current facing;
- attacker's continuation.

## Required reaction grammar

Audit and improve at least:

- head snap;
- torso fold;
- shoulder twist;
- side recoil;
- backward stagger;
- forward stumble;
- leg displacement;
- loss of footing;
- spin / turn from side impact;
- short skid;
- heavy knockback;
- launcher;
- juggle;
- spike;
- knockdown;
- roll / tumble where appropriate;
- wall splat;
- wall bounce;
- recovery step;
- ninja landing / regain footing.

The defender reaction must help create a believable next option for the attacker.

### Important

Do not create dozens of purely cosmetic animations if a smaller systemic reaction grammar can produce the result.

But the final screen result matters more than architectural elegance.

---

# 4. COMBAT MUST CHANGE THE GEOMETRY OF THE FIGHT

Two fighters should not remain perfectly in front of each other after every exchange.

During combat they should naturally:

- gain and lose ground;
- rotate around each other;
- pass to a flank;
- overshoot slightly on committed attacks;
- recover from misses;
- yield space under pressure;
- re-enter range;
- switch sides;
- use walls and airspace without magnetic corrections.

## Kill these visible failure modes

- attacker snaps to victim;
- victim snaps to attack line;
- roots overlap;
- both characters merge during strings;
- every attack ends at exactly the same contact distance;
- whiff is instantly corrected toward target;
- locked facing forces ugly 90° pivots;
- recovery teleports the body back to a canonical combat line.

Use soft spacing / collision / angle logic where appropriate, but do not make movement feel magnetized.

Controlled imperfections are desirable.

---

# 5. FEET AND BODY WEIGHT — REQUIRED AUDIT

The previous report explicitly says there was no dedicated foot sliding audit. Fix that now.

The user reference feels physical because the body usually appears to have a support and a reason to move.

For every translation ask:

> **What physically pushed the character there?**

If the root moves, the body must visually explain it through one of:

- planted foot push;
- step;
- jump impulse;
- dash / burst;
- wall push;
- received hit force;
- aerial momentum.

Audit at slow speed and normal speed:

- sprint acceleration;
- deceleration;
- pivot;
- strafe;
- backpedal;
- M1 step-in;
- running strike;
- heavy;
- launcher;
- dodge;
- block impact;
- hit reaction;
- landing;
- wall entry / exit;
- whiff recovery.

## Required fixes

- reduce visible foot skating;
- prevent planted feet from drifting through the floor;
- make pelvis travel match support changes;
- preserve convincing knee/hip compression on landings;
- make sharp direction changes visibly load and push;
- ensure attack travel is supported by body mechanics rather than invisible root drive.

Do not solve this by simply slowing everything down.

---

# 6. CONTINUITY CONTRACT BETWEEN ACTIONS

Every action must consume an entry state and leave an exit state.

Relevant inherited information includes:

- velocity;
- facing;
- angular direction;
- body lean;
- pelvis orientation;
- current stride phase;
- support leg where practical;
- airborne state;
- target relationship;
- weapon state;
- previous hit / block / dodge result;
- movement intent.

Avoid visual resets.

### Bad

`run -> generic neutral -> punch -> generic recovery -> run`

### Target

`running stride -> attacking step -> contact/follow-through -> recovery step -> continued run`

The player should rarely catch a one-frame generic idle/guard flash between connected actions.

Audit transitions including:

- run -> attack;
- attack -> attack;
- attack -> whiff;
- attack -> run;
- dodge -> attack;
- dodge -> run;
- block -> counter;
- hit -> recovery;
- knockback -> roll/landing;
- launcher -> pursuit;
- air attack -> fall;
- air combo -> landing;
- landing -> run;
- landing -> attack;
- wall -> attack;
- wall -> jump;
- wall -> ground;
- weapon throw -> movement continuation;
- taijutsu -> jutsu;
- jutsu -> taijutsu.

The current ~0.4 s aerial hold at the end of some air routes must be reviewed visually. Keep it only if it reads as intentional combat suspension. Remove/rework it if it reads as hover/freeze.

---

# 7. WHIFFS MUST LOOK GOOD

Intentionally missing is a mandatory test.

A missed attack should not expose the engine.

Test:

- light whiff;
- heavy whiff;
- running strike whiff;
- aerial whiff;
- wall attack whiff;
- weapon throw miss.

The body should:

- continue committed momentum;
- follow through;
- recover from where the move actually ended;
- possibly lose positioning advantage;
- never magnetically turn back onto the victim during the committed portion.

A beautiful hit with an ugly miss is not a finished combat system.

---

# 8. WEAPONS / OBJECTS — ZERO VISIBLE BUG PASS

The reference creates a strong feeling that objects belong to the body and world.

The current project already has useful weapon infrastructure. Now audit it as a visual invariant across combat.

For every object lifecycle:

`appear/acquire -> held -> anticipation -> action -> release/contact -> world state -> cleanup`

Check:

- correct hand;
- stable grip;
- correct wrist orientation;
- no clipping through forearm/torso/head;
- no held + projectile duplication;
- no one-frame disappearance;
- no floating object;
- projectile begins exactly from the release position;
- projectile orientation follows the throw;
- release frame matches body animation;
- inherited body velocity when appropriate;
- world object remains stable at high speed;
- cleanup never pops visibly.

Prioritize actual current combat objects:

- Minato marked kunai;
- normal kunai;
- shuriken;
- swords / cleaver;
- fan;
- Rasengan;
- Chidori;
- substitution object/log;
- seals;
- clones / temporary body objects;
- any currently visible combat prop.

Do not just inspect code. Test in Studio during real movement and combat.

---

# 9. VFX MUST BE PHYSICALLY SOURCED

VFX should confirm a physical event, not hide weak animation.

Order:

`body -> contact/force -> VFX accent`

not:

`approximate move -> huge flash -> player cannot see the bug`

Audit:

- source attachment;
- frame timing;
- direction;
- duration;
- scale;
- relationship to limb / weapon;
- relationship to victim;
- cleanup;
- visibility at normal speed.

Prefer short precise effects for ordinary hits.

Reserve large effects for genuinely large events.

Do not increase camera shake/FOV just to create fake impact. The current camera is already sufficiently advanced; change it only when combat testing proves a framing problem.

---

# 10. HIGH-SPEED READABILITY

The reference shows an important principle: extremely fast motion does not need every frame to be readable literally.

Use perceptual tools where useful:

- afterimages;
- departure pose;
- arrival pose;
- controlled streaks;
- trajectory hints;
- brief silhouettes;
- strong anticipation;
- clean end position.

The viewer must understand:

- where the fighter came from;
- where they went;
- why they are now there;
- what action occurred during the displacement.

Do not turn speed into invisible teleport spam.

For sensory characters / dojutsu, keep in mind that powers can improve **information/readability**, not only stats. Do not build a whole new system unless useful to the current pass, but preserve this philosophy.

---

# 11. PER-FIGHTER PHYSICAL IDENTITY INSIDE REAL COMBAT

Movement Pass 4 began to differentiate sprint. Continue into fighting behavior.

Do not merely change speed multipliers.

### Minato

- economical;
- precise;
- little wasted motion;
- kunai integrated naturally;
- explosive displacement with clean arrivals;
- teleportation extends positioning rather than interrupting combat.

### Itachi

- restrained;
- composed;
- smaller efficient evasions;
- low unnecessary acrobatics;
- deceptive angle control;
- precise counters.

### Sasuke

- aggressive rotation;
- acrobatic but purposeful kicks;
- strong offensive angle changes.

### Lee

- leg-driven;
- obvious physical push/compression;
- explosive support changes;
- taijutsu should be the clearest stress-test of body mechanics.

### Zabuza

- heavier commitment;
- more inertia;
- weapon mass visibly affects recovery and angle change.

### Gaara

- low acrobatics;
- defense/spatial control should make his body language fundamentally different.

Use representative fighters to prove the architecture; do not waste the pass polishing the entire roster equally before the core result is visible.

---

# 12. REQUIRED VISUAL ACCEPTANCE FIGHTS

These are not optional unit tests. They are visual gameplay tests.

## Fight A — PURE TAIJUTSU, NO JUTSU

20 seconds minimum.

Must contain:

- approach;
- combat footwork;
- direction changes;
- 2–3 strike exchange;
- block;
- dodge;
- counter;
- whiff;
- knockback or launcher;
- recovery;
- re-engagement.

This is the primary quality gate.

If this sequence does not look significantly better than the current build, continue working.

## Fight B — MINATO VS ITACHI

Test:

- high-speed approach;
- restrained defense;
- kunai while moving;
- angle changes;
- counter;
- teleport position change;
- immediate continuation;
- object synchronization;
- different movement identities.

## Fight C — ATTACK / DEFENDER REACTION TEST

Repeat controlled attacks from:

- front;
- side;
- behind;
- low;
- heavy;
- launcher;
- air;
- wall proximity.

Verify the defender result is visibly different and physically coherent.

## Fight D — AIR / WALL CONTINUITY

- launcher;
- pursuit;
- air string;
- fall;
- landing;
- immediate grounded movement;
- wall approach;
- wall use;
- attack / exit;
- return to fight.

No visible hover or state reset.

## Fight E — WEAPON INTEGRATION

Perform weapon actions while:

- stationary;
- running;
- jumping;
- after dodge;
- immediately before/after melee.

Inspect release frame and object continuity.

---

# 13. FRAME-BY-FRAME VISUAL QA

Studio is available and has already been used. Therefore this mission requires real visual QA.

Record / inspect relevant sequences.

Check both normal speed and slow/frame-by-frame for:

- foot slide;
- floor penetration;
- root/body mismatch;
- abrupt root turns;
- torso facing errors;
- one-frame idle flashes;
- animation reset;
- limb clipping;
- two fighters merging;
- incorrect spacing;
- weapon grip bug;
- duplicated weapon;
- projectile spawning away from hand;
- VFX detached from source;
- late/early effect;
- bad landing;
- hover/freeze;
- sudden velocity loss;
- camera correction exposing teleport;
- presentation interpolation fighting server motion.

### Perceptual rule

Mathematical perfection is not required.

But if a bug is obvious at normal gameplay speed, it must be treated as a real defect.

---

# 14. AUTOMATED TESTS ARE A FLOOR, NOT ACCEPTANCE

Preserve all existing test suites and server authority.

Add regression coverage for any systemic fix.

But do not write a report that implies completion because:

- 29 suites pass;
- movement probes have good numbers;
- a state transitions correctly;
- a route executes end-to-end.

Those are necessary, not sufficient.

The user is explicitly asking for a **huge visible difference**.

This mission is judged on the screen.

---

# 15. IMPLEMENTATION GUIDANCE

Prefer improving current architecture over creating a second locomotion/combat stack.

Do not pile dozens of special-case flags onto the current system if the real problem is missing shared state continuity.

If useful, formalize a combat presentation contract such as:

- entry body state;
- trajectory intent;
- contact result;
- defender response;
- follow-through;
- exit body state.

But choose architecture based on the actual code.

The goal is not to create a beautiful abstraction. The goal is to make the fight visibly better without breaking server authority.

Preserve:

- confirmed-hit invariants;
- authoritative damage;
- networking assumptions;
- anti-exploit constraints;
- validated movement improvements.

---

# 16. EXECUTION ORDER

Do not stop after the first visible win.

Suggested order:

1. record/observe current pure-taijutsu baseline;
2. identify the 5–10 worst visible discontinuities;
3. fix two-body spacing and exchange geometry;
4. improve defender reaction grammar;
5. audit feet / root / weight;
6. remove state-reset flashes and bad transition boundaries;
7. fix whiffs and recoveries;
8. audit weapon/object lifecycle;
9. synchronize VFX to body/contact;
10. revisit air hold / landing continuity;
11. tune representative fighter identities;
12. replay all acceptance fights;
13. frame-by-frame cleanup;
14. run automated suites;
15. produce final report with honest remaining weaknesses.

---

# 17. HARD DEFINITION OF DONE

The mission is complete only if all of these are defensible:

### A — Visible rupture
A normal-speed before/after comparison shows an immediately obvious improvement without needing explanation.

### B — No-jutsu quality
20 seconds of pure movement/defense/taijutsu already looks like a ninja fight.

### C — Two-body coherence
Attacker and defender look like participants in the same exchange, not an attacker plus a target dummy.

### D — Physical translation
Major root movement is visually explained by feet, jump, dash, wall force, attack commitment or received force.

### E — Reactions
Different attacks produce visibly appropriate body reactions and useful next combat states.

### F — Continuity
Connected actions rarely expose generic neutral/idle resets.

### G — Whiff quality
Missed attacks remain believable and do not magnetically correct.

### H — Object integration
Weapons/projectiles/props show no obvious attach/release/spawn/cleanup bugs in tested fights.

### I — VFX integration
Effects originate from the correct physical event and do not hide broken motion.

### J — Air / ground / wall
Transitions across these spaces do not visibly freeze or reset the fighter.

### K — Identity
Minato/Itachi/Lee/Zabuza (or equivalent representatives) do not feel like the same body with different speed numbers.

### L — Robustness
Existing automated suites pass and server combat authority is preserved.

### M — Studio proof
The final report lists the actual full fights played in Studio, not only headless tests.

---

# 18. FINAL DELIVERABLE

Commit the implementation in clear, simple commits.

Produce a concise report containing:

1. baseline visible problems found;
2. changes made;
3. which full fights were played;
4. what visibly improved in each fight;
5. frame-by-frame defects fixed;
6. test results;
7. remaining visible weaknesses;
8. exact final commit IDs.

Do not sell incremental work as a breakthrough.

If the visual delta is not large enough, continue iterating in Studio before declaring the mission complete.

---

# FINAL QUALITY BAR

Do not ask:

> "Did I add enough systems?"

Ask:

> **"If I hide the UI and show 20 seconds of this fight next to the previous build and next to the reference, did Ninja Duel visibly move a large step toward the reference?"**

If the answer is not an immediate **yes**, keep working.

> **The next commit series must be a combat convergence breakthrough, not another incremental movement pass.**
