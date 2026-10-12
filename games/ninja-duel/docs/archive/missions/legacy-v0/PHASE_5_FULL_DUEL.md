# PHASE 5 — FULL MINATO VS ITACHI DUEL

## Why this phase exists
The V0.2 implementation is now a useful technical base. It has R15 rigs, acceleration/deceleration, sprint, large/variable jump, air control, directional dodge, four-hit moving melee chain, launch/pursuit, lock-on/camera, chakra, interruptible techniques, AI and server validation. Automated/native QA is useful and currently reports passing scenarios.

However, V0.2 itself explicitly acknowledges the remaining gap: animations are procedural placeholders, sound is absent, authored animation markers are absent, visual character identity is primitive, and automated tests cannot prove that the fight actually feels good.

This phase is therefore NOT another feature checklist. It is the autonomous production pass that must turn the existing technical prototype into one coherent, playable Minato-vs-Itachi combat slice.

Read first:
- `games/ninja-duel/docs/archive/BRIEF.md`
- `games/ninja-duel/docs/archive/missions/legacy-v0/COMBAT_FEEL_V02.md`
- `games/ninja-duel/docs/archive/missions/legacy-v0/CHARACTER_REFERENCE.md`
- `games/ninja-duel/docs/archive/missions/legacy-v0/codex-support/IMPLEMENTATION_PLAYBOOK.md`
- the current `games/ninja-duel` implementation and QA

Do not discard working foundations merely to rewrite them.

---

# 1. FIRST TASK: MAKE YOUR OWN EXECUTION PLAN

Before implementing this phase, audit the current game in detail and write an implementation plan inside the repository, for example:

`games/ninja-duel/docs/archive/FULL_DUEL_PLAN.md`

The plan must be concrete and ordered by dependency. It must identify:
- what already works and should be preserved;
- what exists but is placeholder-quality;
- what is missing;
- which systems need refactoring before extension;
- the exact implementation order;
- test/acceptance criteria for each work package;
- any manual Roblox Studio work that genuinely cannot be completed from the repository workflow;
- risks to networking, animation, physics and future PvP.

After creating the plan, FOLLOW IT AUTONOMOUSLY through implementation and verification. Update it as reality changes.

Do not stop after writing the plan. Do not ask François for routine implementation choices. Ask only if a genuinely consequential, difficult-to-reverse decision requires owner arbitration or if an external/manual action is truly unavoidable.

---

# 2. FINAL DELIVERABLE

The deliverable is a **real, coherent, playable young Minato vs young Itachi fight**, not a systems demo.

A player must be able to choose either fighter and play a complete duel against the other with enough movement, melee, defense, elemental ninjutsu, character techniques, audiovisual feedback and arena traversal that the result can honestly be judged as a fighting-game prototype.

The game should evoke the speed, pursuit and spectacle of an arena ninja fighter while retaining our own tactical layer: commitment, chakra, interruption, setup, reads, counters and perception warfare.

The fight must remain interactive. Do not solve spectacle by turning techniques into long non-interactive cutscenes.

Internal prototype references may use Minato/Itachi names and design logic. Keep implementation modular so a commercial public release can later transform names, visuals, lore and assets into original IP-safe equivalents without rebuilding the combat engine.

---

# 3. CHARACTER STATS

Implement explicit data-driven fighter stats rather than hidden arbitrary differences. At minimum support:
- max health / durability;
- max chakra;
- chakra regeneration;
- ground speed;
- acceleration;
- air control;
- jump profile;
- dash profile;
- melee damage/scaling;
- guard strength/cost;
- technique efficiency/cost modifiers where justified;
- recovery/commitment modifiers only where they remain fair/readable.

Expose useful stats in selection UI or a compact character-information surface so the player can understand the broad difference.

Minato should clearly dominate mobility/angle creation. Itachi should clearly dominate anticipation, precision, pressure/control and deceptive openings. Do not make one simply numerically superior in every category.

---

# 4. MAP-WIDE NINJA MOVEMENT

Movement must work throughout a meaningfully larger traversal/combat map, not only on a flat test square.

Required baseline:
- responsive walk/combat strafe;
- fast ninja run/sprint;
- acceleration/deceleration with no sticky feeling;
- large ninja jump;
- preserved horizontal momentum;
- air control;
- ground directional dash;
- lateral lock-on dash/evasion;
- aerial dash/evasion;
- satisfying landing and rapid recovery;
- chase/pursuit after launches;
- reliable lock-on while moving vertically and rapidly;
- movement remains controllable during the flow into/out of attacks.

## Wall traversal is required
Implement a robust first version of **wall running / chakra wall walking**.

The player must be able to approach a suitable wall and continue moving along/up it in a readable, controllable manner rather than simply colliding and stopping.

Wall traversal should support, as appropriate after playtesting:
- wall detection with normals/raycasting;
- transition from ground/air to wall state;
- upward and/or lateral wall movement;
- wall jump/rebound;
- detach intentionally;
- gravity/orientation handling;
- animation/presentation hooks;
- camera that remains usable;
- geometry validation;
- clean exit to air/ground state;
- no climbing arbitrary ceilings or getting stuck in corners;
- future server/PvP validation seam.

It should feel like ninja traversal, not Roblox ladder climbing.

Do not add trees/water traversal until wall traversal and normal movement are actually good.

---

# 5. ARENA / MAP

Replace or extend the test arena into a compact combat playground designed for the movement system.

It needs:
- enough horizontal space for sprint/pursuit;
- meaningful vertical surfaces for wall movement;
- at least a few elevation changes/platforms/structures;
- readable collision;
- no clutter that destroys lock-on/camera;
- boundaries that do not constantly interrupt combat;
- spawn/reset reliability.

Every piece of geometry should exist to test or improve combat/traversal. Do not spend time making a huge decorative village.

---

# 6. UNIVERSAL FIGHTING MOVESET

Both fighters need a common ninja fighting foundation before character-specific jutsu.

Required:
- combat stance/idle;
- light melee chain using both punches AND kicks;
- at least four authored/distinct combat beats;
- attacks move through space rather than stationary punching;
- finisher/launcher;
- aerial attack or reliable air-to-ground/air follow-up;
- pursuit after launcher;
- guard;
- directional dodge;
- hit reactions;
- whiff recovery;
- interruption;
- knockback/launch;
- substitution/escape resource;
- sensible combo reset;
- no long unavoidable stun-lock chain;
- cancel system with intentional windows rather than universal cancel spam.

A melee exchange must look like two fighters interacting, not two Roblox mannequins alternately playing poses.

## Substitution
Implement the limited substitution/escape concept from the support playbook unless playtesting proves a better equivalent.

It should:
- be resource/charge limited;
- have a timing condition;
- escape/reposition rather than automatically damage;
- return both players quickly to an interactive read;
- have clear feedback;
- be server validated.

---

# 7. ELEMENTAL NINJUTSU FOUNDATION

Create an extensible elemental technique framework supporting at least these elemental families in architecture and test coverage:
- Fire;
- Lightning;
- Wind;
- Water;
- Earth.

This does NOT mean Minato and Itachi each receive every element.

The framework must support genuinely different technique behavior, not the same projectile recolored five times. Examples of elemental primitives the engine should be capable of expressing:
- Fire: committed cone/projectile/area pressure, lingering danger where appropriate;
- Lightning: fast precise burst/contact enhancement, higher execution/commitment where appropriate;
- Wind: displacement, cutting projectile, range/trajectory manipulation;
- Water: moving projectile/wave/control volume and future environmental interactions;
- Earth: defensive/terrain/ground-control primitive.

For this phase, implement only the techniques needed to prove the framework and enrich Minato/Itachi. At least Fire must be combat-ready for Itachi, and at least one additional elemental primitive should be fully usable in the test environment to prove the system is not Fire-specific.

Every combat-ready elemental technique needs:
- chakra cost;
- startup;
- animation/presentation hook;
- telegraph;
- hit/area logic;
- server validation;
- interruption where appropriate;
- active phase;
- recovery;
- cooldown/anti-spam;
- counterplay;
- VFX/readability appropriate to element.

Do not build five weak elemental buttons merely to satisfy a count.

---

# 8. MINATO — COMPLETE PROTOTYPE IDENTITY

Use `CHARACTER_REFERENCE.md` as the source pool. Select a coherent kit rather than implementing every idea.

The finished Minato prototype must express:
- exceptional natural movement;
- kunai use integrated into neutral;
- rapid angle creation;
- tactical entry/disengagement;
- movement skill converting into offensive opportunity;
- at least one character-specific mobility/feint mechanic beyond universal dash;
- a coherent signature mechanic.

Strong candidate kit:
- universal melee + Minato-specific timing/travel;
- quick kunai check / moving projectile;
- Quickstep;
- Burst Entry;
- experimental marked-anchor relocation if it genuinely improves the fight;
- Counterstep/angle escape only if it adds meaningful skill rather than duplicate dodge.

Age restraint remains: do not lazily make him an adult Rasengan/Kurama character. The prototype should sell young-prodigy Minato through speed, kunai, intelligence and positioning.

If the marked-anchor mechanic remains, make it tactical and counterable, not infinite teleport spam.

---

# 9. ITACHI — COMPLETE PROTOTYPE IDENTITY

The finished Itachi prototype must feel dangerous because he anticipates and manipulates decisions, not because the game auto-plays defense for him.

Required identity:
- precise melee;
- shuriken/projectile pressure;
- combat-ready Fire technique;
- timed Read/perception mechanic;
- interactive genjutsu/illusion mechanic;
- deliberate punish loop.

Genjutsu must preserve victim control. Prefer a short deception that can cause one wrong decision:
- false afterimage;
- misleading target information;
- false movement/attack cue;
- brief decoy/position uncertainty.

Server simulation keeps the real authoritative state. Client presentation may deceive information. Give the victim counterplay and clear eventual resolution.

Do not implement permanent auto-dodge, a multi-second hard stun or an unavoidable cutscene punish.

---

# 10. TECHNIQUE EXECUTION / INTERRUPTIBILITY

Techniques must feel performed during a fight.

Preserve and expand:
- startup;
- channel/preparation;
- interruption;
- cancel/feint where declared;
- partial resource loss/refund rules;
- LOS/range/facing/target conditions;
- recovery;
- visible telegraph;
- counterplay.

The architecture must remain capable of future hand-sign/input sequences, marks, stance requirements, counters and environmental anchors.

For this phase, prioritize combat flow over building a giant hand-sign minigame.

---

# 11. ANIMATION IS NOW PART OF DEFINITION OF DONE

V0.2 correctly identified procedural Motor6D poses as placeholders. Phase 5 cannot claim final completion while the whole fight still looks like placeholder Roblox posing.

Target coverage:
- distinct Minato and Itachi combat idle;
- run/sprint;
- strafe left/right;
- backward locomotion;
- jump takeoff;
- rise/fall;
- landing;
- ground dash;
- air dash;
- wall-run/wall-walk;
- wall jump/detach;
- guard;
- substitution;
- hit reactions;
- four melee strikes using punches/kicks;
- launcher;
- pursuit/follow-up;
- each equipped technique startup/release/recovery;
- defeat.

Use the best legitimate workflow available. Never rip copyrighted animations/assets.

If final authored Roblox animation clips genuinely require François to perform a manual Studio/account publication step that Codex cannot execute, Codex must:
1. complete every code-side integration seam first;
2. provide the exact smallest manual action required;
3. provide temporary procedural/original placeholders good enough to continue testing;
4. mark the deliverable as blocked on authored animation rather than falsely calling placeholder poses final.

---

# 12. CAMERA + IMPACT + AUDIOVISUAL FEEL

The fight must have fighting-game feedback.

Implement/tune:
- stable two-fighter lock-on framing;
- vertical camera handling for jumps/walls;
- restrained speed FOV;
- short hit camera impulses;
- stronger finisher/technique feedback;
- synchronized trails/impact VFX;
- elemental VFX language;
- readable channel/interruption feedback;
- sound hooks and legitimate/original sounds where available;
- landing/dash/guard/hit/launch/technique audio feedback;
- local hit-stop/equivalent only if it does not break authoritative simulation.

Spectacle must improve readability, not cover the screen in particles.

---

# 13. AI MUST USE THE REAL GAME

The opponent must use the same combat language:
- traverse map;
- approach/sprint;
- strafe/circle;
- jump;
- use wall movement occasionally if reliable;
- melee;
- guard;
- dodge;
- substitute;
- pursue;
- use character techniques;
- interrupt channels;
- respect chakra/cooldowns;
- imperfect reaction time;
- no omniscience.

Minato AI should seek angles/mobility. Itachi AI should condition/read/control more deliberately.

Do not create AI-only cheats to make the demo look functional.

---

# 14. REQUIRED PLAYABLE SCENARIO

A normal match should be capable of naturally producing sequences such as:

Minato sprints across the arena -> transitions onto a wall -> wall-runs upward/laterally -> leaps off -> throws a kunai while airborne -> Itachi evades -> Minato lands into a fast angle entry -> moving punch/kick chain -> launcher -> Itachi uses a limited substitution -> lock-on/camera reacquires cleanly -> Itachi creates space and begins Fire technique -> Minato attempts interruption -> Itachi uses a successful Read/deception opportunity -> both disengage/reposition -> neutral resumes.

This is an example of the **level of interaction**, not a scripted sequence. The systems must allow it to emerge during real play.

---

# 15. TESTING GATES

Automated tests remain necessary but are not sufficient.

## Technical gates
Test at minimum:
- both character selections;
- Minato vs Itachi and Itachi vs Minato;
- movement across full arena;
- wall enter/traverse/detach/landing;
- wall corner/failure cleanup;
- jump/air dash;
- four-hit chain;
- launcher/pursuit;
- substitution valid/invalid/no-charge;
- guard/dodge;
- each equipped technique;
- interruption;
- insufficient chakra;
- cooldown rejection;
- elemental hit/area behavior;
- genjutsu cleanup;
- anchor cleanup if used;
- death during techniques/traversal;
- rematch repeatedly;
- return selection;
- AI stops after defeat;
- no stale wall/illusion/anchor/action state after reset;
- exploit attempts cannot bypass damage/range/chakra/cooldown/movement validation.

## Human-feel gates
Codex must also leave a concise manual QA route for François.

The following must be judged manually:
1. Is moving around the map enjoyable without attacking?
2. Does wall traversal connect naturally to normal movement?
3. Do melee hits feel like they have weight?
4. Does the camera survive fast vertical/side movement?
5. Does Minato genuinely feel more mobile?
6. Does Itachi genuinely make the player think/read?
7. Can a player defend/react during exchanges?
8. Do elemental techniques feel like combat actions rather than cooldown buttons?
9. Can a full match be played without the controls fighting the player?
10. After one match, is there an immediate desire to try another?

Do not claim these subjective gates PASS without human playtest evidence.

---

# 16. AUTONOMY RULE

Once the execution plan is written, continue through the plan autonomously.

You may create multiple commits/work packages. Keep them understandable. Run tests after each major system.

Do NOT repeatedly stop for review after movement, then wall running, then elements, then melee, etc.

Stop and ask François only for:
- an irreversible major architecture choice;
- a manual Roblox Studio/account action only he can perform;
- a licensing/asset choice requiring owner approval;
- a design fork where both options materially change the game vision and existing docs do not answer it;
- a blocker that cannot reasonably be solved autonomously.

Otherwise decide, implement, test, tune, document, continue.

---

# 17. FINAL REPORT

At completion, report clearly:
- plan executed;
- commits/work packages;
- what is actually playable;
- Minato complete moveset;
- Itachi complete moveset;
- universal moveset;
- stats differences;
- elemental framework and implemented elemental techniques;
- wall traversal behavior;
- animation status;
- camera/VFX/audio status;
- AI status;
- automated test results;
- exact manual playtest steps;
- known defects/technical debt;
- anything that still requires François manually.

Separate claims into:
1. **Proven by automated/native test**
2. **Implemented but requires human feel validation**
3. **Blocked/manual Studio work**
4. **Future work, explicitly outside this phase**

Do not call the phase complete merely because every checkbox has code behind it.

# FINAL DEFINITION OF DONE

The output is not “V0.3 architecture.”

The output is:

**I can open the Roblox place, choose young Minato or young Itachi, move fluidly around and vertically through a ninja combat arena including walls, fight with punches/kicks/defense/substitution/chakra/elemental and character techniques, experience distinct Minato and Itachi identities, complete a full fight against a functioning opponent, rematch, and honestly judge whether this feels like the foundation of the real game.**
