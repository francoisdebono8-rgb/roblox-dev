# FOUNDATION 01 — Research the real target before rebuilding

## Why this mission exists

Phase 6B proved that importing real open-source systems can improve Ninja Duel, but the human result is still only a small improvement. Legs/movement feel somewhat more alive, yet the game remains far from the intended product. Do not answer this by making another small local polish pass.

This mission is the first step of a foundation reset. Its purpose is to research, decompose and specify the actual target well enough that future implementation cannot satisfy the brief by choosing the easiest approximation.

**This mission is RESEARCH + TARGET SPECIFICATION, not another combat implementation pass. Do not rewrite the game yet.**

The current repository is not the product to protect. The target player experience is.

---

## Product target you must design toward

Ninja Duel is intended to become a highly fluid, tactical 3D ninja arena fighter with roughly 20 genuinely differentiated playable fighters, initially proven through an excellent 1v1 vertical slice.

The long-term fantasy is not a generic cooldown battleground. A player should feel able to exploit ground, air, walls, momentum, spacing, projectiles, feints, preparation, information and character-specific rules.

A representative continuous sequence should eventually be possible without bespoke scripting for that exact sequence:

`sprint -> accelerate -> jump -> preserve horizontal momentum -> air steer -> wall run -> wall jump -> air dash -> throw kunai -> land -> directional evade -> advancing melee -> launcher -> pursuit -> aerial hits -> downslam -> knockdown -> reposition`

The tactical loop is:

`observe -> provoke -> read -> create opening -> execute -> opponent reacts/counters -> punish or disengage`

The game must reward execution, reads, spacing, environment use and information. It must not collapse into pressing whichever ability cooldown is ready.

### Long-term character architecture

Approximately 20 fighters should be possible without 20 isolated hard-coded combat engines. Fighters share a strong universal physical grammar but alter its rules through movement profiles, melee styles, tools, elements, techniques, counters, marks, traps, clones, perception/deception, resources and traits.

Examples of intended differentiation:
- Minato: movement, angles, kunai, marks, pursuit, repositioning, intelligence.
- Itachi: anticipation, shuriken, Fire, Read, deception/genjutsu, punishment.
- Lee: extreme physical pressure/mobility and melee execution.
- Gaara: space control, defensive sand rules, terrain/ranged pressure.
- Neji: precise close range, chakra/body control, defensive rotation.
- Shikamaru: weaker direct confrontation, geometry/setup/traps/read reward.

Do not design these six kits now. Use them as architecture stress tests: a foundation that can only express Minato-like fighters is wrong.

Future product layers may include a scalable ninja-exam/tournament fantasy, 2-player instant duels through larger tournaments/events, progression/cosmetics, and a Create-a-Ninja system assembled from the same capability grammar. None of those should be implemented in this mission, but the foundation must not make them impossible.

---

## Codex operating rules

You are expected to research rather than guess.

1. Search public GitHub repositories, Roblox DevForum/resources/documentation, technical articles and publicly accessible YouTube/tutorial material for each major subsystem below.
2. YouTube/tutorials are valid behavioral/architectural references, but **do not copy code unless reuse rights are clear**. Prefer associated public repositories with explicit licenses.
3. For reusable code, verify the actual license and provenance. No clear reuse rights = reference only.
4. Inspect implementation, not just README marketing claims.
5. Prefer proven Roblox-native implementations over inventing generic infrastructure.
6. Existing Phase 6B donors Bangla Battlegrounds and Place1 are candidates, not sacred. Keep, complement or replace them based on evidence.
7. Do not preserve an old Ninja Duel abstraction merely because migration is inconvenient.
8. Do not recommend paid systems. Development-system candidates must be free/open-source or Roblox-native/free resources with legitimate reuse rights.
9. Do not silently reduce a difficult requirement. Either identify a credible way to achieve it or record the blocker/unknown.
10. Be concise in prose but thorough in research. Spend tokens on evidence and decisions, not repeated project history.

**When an acceptance requirement contains multiple clauses, satisfying the easiest clauses does not satisfy the requirement.**

---

## Research every subsystem below

Research at minimum these areas. For each, find credible candidates/references and determine what the final game actually needs.

### A. Locomotion and momentum
Research:
- acceleration/deceleration instead of binary WalkSpeed feel;
- sprint and braking;
- jump takeoff momentum;
- air steering/control;
- directional ground and air dash;
- momentum inheritance through actions;
- slope/landing behavior where relevant;
- wall run, wall jump/hop, detach and wall-to-air transitions;
- controller response;
- server validation without destroying local responsiveness.

Target sensation: movement is continuous. Jumping while moving must not erase horizontal velocity. Starting an attack must not arbitrarily freeze momentum unless that attack intentionally plants the fighter. Fast movement must be communicated by animation/camera/presentation rather than looking like position snapping.

Explicit failure examples:
- only changing Humanoid.WalkSpeed;
- teleporting for ordinary dashes;
- setting velocity to zero between actions without design reason;
- wall movement that is a canned animation with no meaningful entry/exit momentum;
- movement that feels responsive only on keyboard and not controller.

### B. Physical melee grammar
Research Roblox implementations/references for:
- responsive light chains;
- advancing/root-travel attacks;
- heavy attacks;
- directional attacks;
- launcher/uppercut;
- horizontal finisher;
- pursuit/chase;
- aerial melee;
- juggle trajectory modification;
- downslam;
- knockdown/wakeup;
- guard/block and guard consequences;
- directional dodge/evasive;
- grabs and directional/upward throws;
- wall interactions/wallsplat/rebound where appropriate;
- whiff recovery;
- hitstun/cancel/combo windows;
- attack buffering.

The target is interaction between two moving bodies, not `animation -> hitbox -> damage -> stun -> neutral`.

A launcher must visibly and mechanically create an airborne opponent with trajectory/momentum, a pursuit opportunity, aerial interaction and a possible slam. Merely changing Y, playing an uppercut pose and setting `Stunned=true` is a failure.

### C. Hit detection and authority
Research mature free/open-source Roblox hitbox/collision approaches.
Compare spatial query, swept volume, raycast, server rewind/prediction options if relevant.
Need:
- fast melee at high movement speeds;
- projectiles;
- grabs;
- aerial targets;
- wall proximity;
- reliable server-authoritative outcomes;
- tolerable latency.

Do not build another hitbox framework if a good licensed one fits.

### D. Victim physics and reactions
Research:
- impulse/trajectory systems;
- knockback;
- airborne states;
- knockdown;
- selective ragdoll;
- directional hit reactions;
- wall impact;
- ground impact/bounce if appropriate;
- recovery/wakeup.

Define when animation-driven reaction is better than physics and when physics should take over. Avoid uncontrolled Roblox ragdoll chaos as the universal answer.

### E. Animation architecture
This is critical. Research Roblox R15 combat animation workflows and runtime architecture:
- directional locomotion;
- acceleration/start/stop/pivot;
- jump takeoff/air/landing;
- wall entry/run/exit;
- dash directions;
- attack anticipation/contact/follow-through;
- victim reactions by direction/state;
- launch/aerial/slam/grab/throw/knockdown/wakeup;
- blending, priorities and transitions;
- markers/timing integration;
- ownership/publication constraints;
- retargeting limitations R6 -> R15.

Separate gameplay authority from visual animation markers correctly, while still synchronizing presentation with attack phases.

Find legitimate free animation sources/workflows where useful, but do not assume public asset IDs are commercially reusable or accessible across experiences.

### F. Camera and lock-on
Research third-person arena-fighter cameras and Roblox implementations/references:
- lock-on/orbit;
- target switching if later needed;
- framing both fighters;
- close melee;
- high-speed FOV response;
- vertical launch/pursuit;
- wall proximity/collision;
- camera obstruction;
- impact impulse/shake;
- jutsu presentation without stealing control unnecessarily;
- controller right-stick behavior.

The camera must understand combat state. If a launcher works mechanically but the player loses the opponent, the feature fails experientially.

### G. Abilities / jutsu / status architecture
Research free/open-source Roblox ability frameworks including WCS or better alternatives.
Need to support eventually:
- chakra/resource costs;
- cooldowns;
- instant techniques;
- short prepared/interruptible techniques;
- committed techniques with punishable recovery;
- conditional techniques requiring mark/LOS/contact/projectile/airborne/etc.;
- projectiles;
- elements;
- counters;
- status effects;
- clones/decoys;
- traps/marks;
- charge/channel if useful;
- cancel/fake preparation;
- character-specific extensions without fighter-name spaghetti.

Do **not** let an ability framework own the universal physical melee if that makes melee worse.

### H. Tactical information / genjutsu
Research design/technical references for implementing deception without long hard stuns.
Potential vocabulary:
- afterimages;
- false target/movement cues;
- misleading indicators;
- short visual/audio misinformation;
- clone/decoy ambiguity;
- conditional perception windows;
- counterable Read mechanics.

Goal: cause one wrong decision that the attacker must manually punish, not `press genjutsu -> enemy cannot play for 5 seconds`.

### I. AI
Research architecture suitable for an AI that uses the same action grammar/intents as a human:
- spacing;
- pursuit;
- guard/dodge;
- combo choice;
- interrupting preparation;
- using projectiles to force reactions;
- character-specific tactical goals;
- difficulty based on decision quality/reaction limits rather than stat cheating.

Do not build AI now. Define the seams required by the foundation.

### J. Networking / prediction / security
Research appropriate Roblox patterns for a fast PvP fighter:
- local responsiveness;
- server authority;
- movement validation;
- combat validation;
- rate limiting;
- client prediction/correction where warranted;
- latency-sensitive hit confirmation;
- exploit resistance;
- future human-vs-human support.

Avoid both extremes: trusting the client for outcomes, or making every movement wait for server round-trip.

### K. Presentation / impact
Research reusable/free solutions and techniques for:
- camera shake/impulse;
- hitstop/hit pause where appropriate;
- trails;
- impact VFX;
- speed lines/afterimages selectively;
- sound layering and spatial audio;
- landing/wall impact feedback;
- readable telegraphs;
- UI that does not cover the fight.

Presentation should communicate physics and decisions. It must not hide weak mechanics under particles.

---

## Required behavioral target map

Create a precise observable target for at least these player scenarios. Each scenario must state expected movement, animation, camera, attacker/victim behavior, possible branches and failure cases.

1. stand -> run -> sprint -> hard stop -> reverse direction;
2. sprint -> jump -> air steer -> land while preserving believable momentum;
3. sprint -> jump -> wall run -> wall jump -> air dash -> landing;
4. neutral -> directional dodge -> immediate repositioning decision;
5. light -> light -> horizontal finisher;
6. light -> light -> launcher -> pursuit -> air light -> air light -> downslam;
7. launcher without pursuit: defender trajectory and recovery;
8. aerial defender changes direction after another hit;
9. heavy knockback into nearby wall;
10. grab -> forward throw and grab -> upward throw;
11. guard a normal chain, then punish a whiff/recovery;
12. substitution/evasive after being opened, with limited resource/counterplay;
13. projectile forces dodge/guard and attacker closes distance;
14. short jutsu preparation is interrupted by melee;
15. player deliberately cancels/fakes preparation to bait a response;
16. Minato-like mark/kunai movement changes angle rather than becoming teleport spam;
17. Itachi-like Read/deception creates misinformation that still requires a manual punish;
18. camera behavior throughout a ground-to-air-to-ground exchange;
19. same core sequence on controller without keyboard-only actions;
20. high latency conceptual behavior: what is predicted locally and what the server decides.

Do not use vague words such as "fluid" or "responsive" without translating them into observable behavior.

---

## Required research output

Create these files under `games/ninja-duel/docs/missions/foundation/`:

### 1. `GAMEPLAY_BIBLE_DRAFT.md`
A durable specification of the intended game, not merely Phase 6B. Include:
- core promise;
- movement fantasy;
- physical combat grammar;
- tactical loop;
- defense;
- chakra/substitution;
- jutsu categories and interruption;
- projectiles/tools/elements;
- genjutsu/information warfare;
- environment/verticality/walls;
- camera;
- animation quality bar;
- controller-first requirements;
- character differentiation architecture;
- AI principles;
- future 20-fighter scalability;
- future Create-a-Ninja compatibility;
- scalable duel/tournament/exam product vision that works from 2 players upward and never requires 20 concurrent players to make the game playable;
- future progression/monetization boundaries, including avoiding pay-to-win;
- visual/audio quality principles;
- networking/security principles;
- explicit anti-patterns.

Clearly label **FINAL VISION**, **VERTICAL SLICE**, and **CURRENT FOUNDATION GATE** so future Codex work does not prematurely build the whole product.

### 2. `TECHNICAL_REFERENCE_MAP.md`
For every subsystem A-K, include a compact table with:
- candidate/reference;
- URL;
- date/recentness where relevant;
- license/reuse status;
- actual capabilities verified;
- limitations;
- Roblox/R15/controller/server-authority fit;
- whether to IMPORT, ADAPT, KEEP CURRENT, REFERENCE ONLY, or REJECT;
- exact reason.

Include YouTube/tutorial references where they materially teach a mechanic, even when code cannot be reused. If a video has an associated repository/resource, trace it.

### 3. `FOUNDATION_ARCHITECTURE.md`
Propose the best concrete stack after research. It must answer:
- which current Phase 6B pieces survive;
- which should be replaced;
- which external modules/repos should be imported;
- which systems must remain custom because they are game-specific;
- how movement, action state, animation, hit detection, victim reaction, camera, abilities and server authority communicate;
- how one semantic input layer supports keyboard + controller;
- how AI submits the same semantic intents;
- how character data/extensions avoid giant fighter-name conditionals;
- how the architecture can support ~20 fighters and later Create-a-Ninja.

Prefer one owner per concern. Explicitly prevent competing movement/combat/input loops.

### 4. `HUMAN_ACCEPTANCE_MATRIX.md`
Turn subjective quality into repeatable controller tests.
For each of the 20 behavioral scenarios above, provide:
- setup;
- exact input sequence;
- expected visible result;
- expected physical result;
- camera expectation;
- PASS;
- FAIL examples.

Automated tests may support these gates but may never substitute for them.

### 5. `FOUNDATION_02_PLAN.md`
Write the next implementation mission as a proposed plan only. Do **not** execute it.
It should build the smallest two-fighter graybox/playground that can prove the foundation before character content. No need to preserve weak existing architecture. It should identify donor imports and exact replacement boundaries.

The playground must eventually be enjoyable for roughly 10 minutes with no character jutsu, using movement + physical combat alone.

---

## Research quality bar

Do not stop after finding the first plausible repository.

For each major concern, compare enough candidates to make a reasoned decision. Usually 2-4 serious candidates is appropriate where the ecosystem provides them. Do not pad the list with obviously irrelevant repos.

For GitHub candidates inspect source/tree/release/activity/license enough to determine whether it is real and usable. For videos/tutorials record the exact mechanic learned and, where practical, timestamp/section or title details useful to future implementation.

Pay special attention to recent Roblox resources for:
- battleground combat;
- uppercut/downslam/aerial combo;
- movement momentum/wallrun;
- R15 combat animation;
- hitboxes;
- camera/lock-on;
- ability frameworks;
- client/server combat architecture.

Do not claim a resource is reusable merely because it is public.

---

## Hard anti-laziness rules

The following are explicit failures:

- describing our existing Phase 6B implementation as the target simply because it already exists;
- recommending local reimplementation without first checking mature reusable alternatives;
- treating `WalkSpeed` changes as a movement foundation;
- treating damage + stun as a combat foundation;
- calling a static pose plus Y displacement a launcher;
- calling particles an improvement to combat feel;
- saying "add better animations later" without specifying the required animation pipeline and coverage;
- ignoring controller because keyboard works;
- ignoring R15 compatibility;
- ignoring animation ownership/publication restrictions;
- accepting client-authoritative competitive outcomes for convenience;
- making all actions server-round-trip before local presentation;
- building 20 fighters now;
- building tournament/progression/shop now;
- implementing Foundation 02 before human approval of this research.

If research shows an assumption in this mission is wrong, say so and provide evidence. Do not conform to a bad assumption merely to satisfy the brief.

---

## Definition of done

This mission is done only when:

1. all five required documents exist;
2. all A-K systems were researched;
3. reusable candidates have verified license/provenance status;
4. YouTube/tutorial research is included where useful, not ignored;
5. Bangla/Place1 are critically reassessed rather than automatically retained;
6. the 20 observable scenarios are specified;
7. the proposed architecture has one clear owner per major concern;
8. the future ~20-fighter design and Create-a-Ninja compatibility are accounted for without implementing them;
9. the product can scale from excellent 2-player duels to larger exam/tournament events without requiring 20 concurrent players;
10. `FOUNDATION_02_PLAN.md` is ready for François/ChatGPT review but has NOT been executed;
11. changes are committed.

Final Codex response must be short:
- commit SHA;
- five created files;
- recommended foundation stack in <=10 lines;
- top 5 donor/reference discoveries;
- biggest 5 gaps in current Phase 6B;
- explicit statement: `FOUNDATION 02 NOT EXECUTED`.

Do not ask routine questions. Research autonomously. Ask only if a decision would materially change the product and cannot reasonably be resolved from this specification.