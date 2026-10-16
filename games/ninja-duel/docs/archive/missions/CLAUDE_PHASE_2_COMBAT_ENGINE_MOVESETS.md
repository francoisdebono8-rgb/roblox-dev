# Claude Phase 2 — Combat Engine, Movesets, Animation Depth & Vision Gap

## Context

The previous pass successfully pushed the project toward a much more convincing Naruto-like presentation: real jutsu presentation, stronger VFX, fireball/Rasengan-style attacks, Itachi crow effects, and a much stronger overall anime/ninja feel.

This phase must NOT discard that progress.

The purpose now is to make the game **play as well as it looks** and to close the remaining gap between the current build and the intended vision.

This is a deeper pass on:

- combat engine quality;
- movement quality;
- animation quality;
- full-body motion;
- fighter movesets;
- combo structure;
- aerial combat;
- input feel;
- camera;
- bugs;
- character identity;
- overall game quality.

You are also explicitly expected to identify what *you* believe is still missing from the project after playing it, then implement the highest-value improvements instead of waiting for the user to list every weakness.

Do not restart the project and do not erase successful work from the previous pass.

---

# 1. Begin by playing the current version in Roblox Studio

Do not start with assumptions.

Open the latest playable build in Studio and play multiple full fights with both Minato and Itachi.

Test deliberately:

- neutral movement;
- forward movement;
- backward movement;
- strafing;
- sprint;
- dash;
- jump;
- landing;
- wall movement;
- melee strings;
- heavy attacks;
- launchers;
- chase;
- aerial strings;
- slam;
- throws;
- projectiles;
- teleportation;
- jutsu;
- defense;
- substitution/deception;
- camera during all of the above.

Record mentally and in notes every moment that looks or feels wrong.

The guiding question is not only:

> Does it work?

It is:

> Does this feel like a polished anime fighting game interaction?

---

# 2. Combat engine audit — go beneath the presentation layer

The previous work improved visuals significantly. Now inspect whether the underlying combat engine truly supports the experience we want.

Audit and improve where justified:

- attack state machine;
- buffering;
- chaining;
- cancel windows;
- recovery windows;
- hit confirmation;
- hitstun;
- blockstun;
- knockback;
- launch states;
- pursuit/chase;
- aerial states;
- ground recovery;
- invulnerability windows;
- dodge/substitution timing;
- ability interruption;
- movement lock rules;
- facing/orientation rules;
- target lock;
- momentum transfer;
- collision response;
- server/client reconciliation;
- visual vs gameplay hit agreement.

Do not rewrite the engine simply because another architecture would be cleaner.

Change the engine only where the current implementation is visibly limiting gameplay quality, reliability, responsiveness or future character design.

---

# 3. Movement must become a major strength

Movement should be one of the reasons the game is fun even before pressing an attack button.

Focus heavily on leg motion and body locomotion.

## Legs and lower body

At all times the legs should visually support what the character is doing.

Fix cases where:

- feet slide across the floor;
- legs barely move while the root travels;
- the body rotates but the feet do not respond;
- sprint looks like fast walking;
- strafing uses the wrong lower-body silhouette;
- backward movement looks identical to forward movement;
- landing has no real compression;
- jumps begin without a believable push-off;
- wall movement has no convincing leg involvement;
- quick changes of direction cause awkward snaps.

Improve:

- stride length based on speed;
- stride frequency;
- hip rotation;
- knee bend;
- foot placement;
- acceleration pose;
- deceleration pose;
- turn anticipation;
- combat strafe posture;
- retreat posture;
- sprint posture;
- jump launch;
- aerial posture;
- landing absorption.

A character moving quickly must look like they are generating that movement with their body, not being dragged by the HumanoidRootPart.

---

# 4. Upper-body attack animation must become much more convincing

The arms and torso need another quality pass.

Every important melee attack should visibly communicate:

- anticipation;
- path of the strike;
- contact moment;
- follow-through;
- recovery.

Fix attacks where:

- the arm barely moves;
- the fist/foot never visually reaches the opponent;
- the torso does not rotate;
- the shoulder does not drive the strike;
- the strike has no readable contact pose;
- limbs snap between poses;
- attacks look like joint posing instead of actual motion.

Use full-body coordination.

Punches should involve shoulder/torso/hips.

Kicks should involve hips, support leg, torso balance and recovery.

Kunai/shuriken throws should have believable draw, aim, release and recovery.

Jutsu startups should have convincing body language and hand/arm motion.

---

# 5. Hybrid animation approach — do what looks best

Do not treat the existing procedural Motor6D layer as sacred.

It is useful, but it is not necessarily sufficient for every animation.

Use the strongest combination of:

- Roblox Animation tracks;
- authored keyframed animation;
- Motor6D additive adjustments;
- procedural aiming;
- procedural recoil;
- procedural foot/torso correction;
- VFX-driven motion accents.

Choose per situation.

The quality bar is the final visual result, not ideological consistency of implementation.

---

# 6. Expand the movesets — Minato and Itachi need deeper combat identities

The current movesets should now be treated as the beginning of the final characters, not feature demos.

Each fighter should have a coherent combat plan and enough options to create different exchanges.

Avoid two characters who merely share the same combo tree with different special effects.

## Minato identity

Minato should reward:

- speed;
- angle changes;
- marked positions;
- kunai placement;
- instant repositioning;
- whiff punishment;
- hit-and-run pressure;
- rapid conversion from movement into offense.

Potential areas to deepen if they improve the game:

- multiple meaningful ways to use marked kunai;
- teleport follow-ups;
- teleport feints;
- teleport behind / side angle logic;
- kunai throw as combo starter or extender;
- Rasengan conversion;
- fast punish move;
- evasive reposition;
- airborne teleport route;
- counter or reactive teleport option;
- movement-specific attacks.

Do not add complexity purely for quantity. Every move should serve his identity.

## Itachi identity

Itachi should reward:

- prediction;
- spacing;
- shuriken control;
- deception;
- fire pressure;
- punishing predictable approaches;
- forcing hesitation;
- controlling the pace.

Potential areas to deepen if they improve the game:

- shuriken strings and angle control;
- shuriken into melee conversion;
- fireball pressure and zoning;
- crow substitution/deception routes;
- mirage bait;
- counter-style punish;
- defensive reposition;
- delayed pressure;
- traps or false openings;
- aerial denial.

Again, prioritize coherent identity over move count.

---

# 7. Combo design — inspired by Ninja Storm flow, but with more player agency

The combo system should feel fast and cinematic without becoming automatic.

Improve:

- ground strings;
- branching options;
- heavy finisher routes;
- launcher routes;
- chase timing;
- air routes;
- knockdown routes;
- jutsu conversion;
- projectile conversion;
- defensive escape opportunities.

A strong flow example is:

`approach → melee string → branch → launcher → chase → aerial continuation → finisher or reset`

But the player should still make decisions.

Avoid a single optimal canned string that plays itself.

Consider meaningful branches such as:

- safe ender;
- launcher;
- damage ender;
- positioning ender;
- jutsu cancel;
- kunai/shuriken route;
- teleport/deception route.

Combat should allow stylish expression while preserving counterplay.

---

# 8. Input feel and responsiveness

Test the controls like a player, not like a developer.

Inspect:

- input latency;
- early input buffering;
- repeated presses;
- simultaneous inputs;
- jump buffering;
- attack buffering;
- dash into attack;
- attack into movement;
- landing input;
- teleport follow-up;
- guard release;
- substitution response.

The player should rarely feel:

> I pressed it, but the game ignored me.

At the same time, inputs should not cause accidental queued actions seconds later.

Tune buffer durations and cancel windows based on actual play feel.

---

# 9. Air combat must become reliable and satisfying

Aerial combat is one of the most important remaining quality gates.

Aggressively test and fix:

- jump attack;
- launcher;
- chase;
- air attack 1;
- air attack 2;
- aerial heavy/finisher if present;
- air projectile;
- air teleport;
- slam;
- landing transition;
- interrupted aerial strings;
- wall proximity;
- camera during vertical movement.

Eliminate:

- hovering;
- falling out of combo for no reason;
- attacker and defender separating too far;
- sudden teleports caused by correction;
- wrong facing in the air;
- missed attacks despite visual contact;
- slam stopping above ground;
- camera losing one fighter;
- landing in a broken state.

An aerial route should feel intentional from launch to landing.

---

# 10. Bugs — perform a dedicated destruction pass

Try to break the game on purpose.

Test spam and awkward sequences:

- jump while attacking;
- attack while landing;
- teleport during hitstun;
- jutsu immediately after dash;
- projectile during wall movement;
- block during recovery;
- repeated substitution;
- grab near walls;
- slam near arena edges;
- teleport to invalid/obstructed locations;
- hit during character state transition;
- KO during aerial sequence;
- rematch after unusual state;
- repeated fast inputs.

Fix reproducible issues.

Do not hide bugs with VFX or forced resets unless that is genuinely the correct design solution.

---

# 11. Camera — support the improved movement and combos

Revisit the camera after the movement/combat improvements.

The camera should:

- frame both fighters reliably;
- preserve orientation during dashes;
- make teleportation readable;
- track launch/chase smoothly;
- support aerial strings;
- handle walls and elevation;
- avoid geometry clipping where practical;
- avoid sudden unnecessary FOV jumps;
- accent major moments without becoming cinematic every two seconds.

Investigate whether the camera should adapt slightly based on distance, vertical separation and move state.

The camera should make good combat look better, not make fast combat harder to understand.

---

# 12. Character feel — Minato and Itachi must feel different even with VFX disabled

Perform a test with effects mentally ignored or reduced.

Ask:

> If the particles were removed, would Minato and Itachi still feel different to control?

They should.

Difference should exist in:

- acceleration;
- preferred range;
- attack rhythm;
- recovery;
- movement options;
- projectile role;
- combo structure;
- risk/reward;
- defensive tools;
- positioning goals.

VFX must reinforce gameplay identity, not substitute for it.

---

# 13. Jutsu integration — abilities must belong to the combat system

The new jutsu are visually much stronger. Now ensure they are mechanically integrated.

For every major technique ask:

- What situation is this move good in?
- Can it start a combo?
- Can it extend a combo?
- Is it a finisher?
- Is it zoning?
- Is it punishable?
- Can it be interrupted?
- What is the opponent's answer?
- Does it create meaningful positioning?

Avoid abilities that are beautiful but disconnected from the melee game.

Examples:

- Rasengan should have a clear role beyond "big damage effect".
- Fireball should create pressure/space and have meaningful range/recovery.
- Crow/mirage tools should create deception decisions, not only visual spectacle.
- Kunai/shuriken should influence spacing and routes.

---

# 14. Arena interaction and traversal

Evaluate whether the current arena actually supports the movement/combat fantasy.

Improve where useful:

- wall running;
- wall rebound;
- vertical chase;
- obstacle navigation;
- line of sight;
- teleport anchors;
- projectile paths;
- open areas vs constrained areas;
- arena edge handling.

The arena should create situations, not merely host the fight.

Do not overcomplicate it into platforming.

---

# 15. Game feel pass

After systems are stable, do a dedicated feel pass.

Tune:

- movement acceleration;
- stopping;
- dash speed/distance;
- jump force;
- attack speed;
- hitstop;
- hit reaction duration;
- knockback;
- camera impulse;
- sound timing;
- VFX timing;
- projectile speed;
- teleport timing;
- jutsu startup/recovery;
- combo rhythm.

Do not tune values in isolation. Play full fights after changes.

The goal is a fast, responsive anime duel that remains readable.

---

# 16. VISION GAP AUDIT — mandatory

After you have understood and played the current build, perform your own expert audit.

Create a short document:

`games/ninja-duel/VISION_GAP.md`

Answer:

1. What currently prevents this from feeling like a genuinely strong Naruto-like combat game?
2. What looks impressive but is mechanically shallow?
3. What works mechanically but still looks weak?
4. Which bugs most damage the experience?
5. Which systems are currently overbuilt relative to their player value?
6. Which systems are underdeveloped?
7. What is missing from Minato's fantasy?
8. What is missing from Itachi's fantasy?
9. What is missing from movement?
10. What is missing from combat flow?
11. What is missing from camera/game feel?
12. What would you add or change if your goal were to make a 30-second gameplay clip genuinely compelling?

Do not stop at writing the audit.

After identifying the gaps, implement the highest-value items that fit this phase.

You have permission to propose and implement ideas that were not explicitly requested when they clearly improve the shared vision.

Use judgment.

---

# 17. Ideas are welcome — but must serve the vision

You should actively suggest and, when reasonable, implement improvements such as:

- better movement tech;
- more expressive combo branches;
- defensive mechanics;
- character-specific movement;
- better target lock;
- improved clash/impact feedback;
- better wall interaction;
- stronger telegraphing;
- better recovery systems;
- better AI behavior for testing;
- visual readability improvements;
- arena interactions;
- smarter camera behavior;
- improved character-specific transitions.

But do not add random features just to increase scope.

Every addition should answer:

> Does this make the duel more fun, more Naruto-like, more expressive, more readable, or more polished?

If not, skip it.

---

# 18. Performance and robustness

The visual upgrade should not destroy performance.

Audit:

- excessive particle counts;
- unnecessary per-frame allocations;
- too many cloned instances;
- effect cleanup;
- projectile cleanup;
- connection cleanup;
- memory leaks;
- duplicated effects;
- server cost;
- network spam;
- expensive raycasts or loops.

Preserve responsiveness while keeping the game practical for normal Roblox hardware.

---

# 19. Test both fighters as if preparing for an external playtest

Before finishing, run multiple full fights.

Test:

## Minato

- neutral movement;
- dash and direction changes;
- kunai routes;
- mark/teleport routes;
- ground combos;
- launcher/chase;
- air combo;
- Rasengan integration;
- teleport follow-up;
- defense;
- wall movement;
- recovery.

## Itachi

- neutral movement;
- shuriken control;
- ground combos;
- launcher/air route;
- fireball integration;
- crow/mirage behavior;
- spacing tools;
- defensive tools;
- wall/vertical interaction;
- recovery.

Also test AI enough to ensure it can demonstrate and stress the systems.

---

# 20. Delivery requirement — the user must be able to test on their Mac

This is non-negotiable.

At the end of the phase, the user must be able to test the exact final version on their Mac in Roblox Studio with minimal effort.

Therefore:

- commit all source changes;
- push them to GitHub;
- rebuild the playable place;
- update `games/ninja-duel/dist/NinjaDuel.rbxlx`;
- update `games/ninja-duel/dist/NinjaDuel-QA.rbxlx` if relevant;
- verify the built `.rbxlx` opens successfully in Roblox Studio;
- make sure the build corresponds to the final committed source;
- do not leave required assets only on your local machine;
- do not leave unpublished local changes that the user's Mac cannot retrieve.

The user should be able to:

1. pull/download the latest project;
2. open `games/ninja-duel/dist/NinjaDuel.rbxlx`;
3. press Play;
4. test the version you just finished.

If any asset requires Roblox ownership/permissions/publication to work on another machine/account, document and resolve it where possible before delivery.

---

# 21. Final deliverables

At the end provide:

1. final branch name;
2. final commit hash;
3. exact `.rbxlx` to open on the user's Mac;
4. confirmation that it was opened/tested in Roblox Studio;
5. concise list of major engine changes;
6. concise list of animation/movement changes;
7. Minato moveset changes;
8. Itachi moveset changes;
9. bugs fixed;
10. camera changes;
11. your own top ideas/improvements implemented from the Vision Gap audit;
12. remaining known issues;
13. the 5 highest-value next improvements after this phase.

---

# Final quality bar

The previous phase proved that the game can look much more impressive.

This phase must prove that the **combat underneath is worthy of those visuals**.

At the end:

- movement should feel alive;
- legs should visibly drive locomotion;
- arms/body should visibly drive attacks;
- combos should flow;
- aerial combat should be reliable;
- Minato and Itachi should have deeper identities;
- jutsu should integrate into combat;
- camera should support fast action;
- bugs should be significantly reduced;
- the game should offer more player expression;
- the whole duel should feel closer to a real anime fighting game than to a Roblox combat prototype.

Do not stop when it is merely functional.

Stop when the game is clearly better to **play**, not only better to look at.
