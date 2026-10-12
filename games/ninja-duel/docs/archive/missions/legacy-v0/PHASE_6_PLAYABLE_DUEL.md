# PHASE 6 — PLAYABLE DUEL

## ONE-SHOT MISSION

This is intended to be the last large implementation pass before one final user-feedback iteration. Optimize for **playable quality per token**, not for writing more architecture or documentation.

Do not continue polishing the existing combat just because it exists. The current local Phase 5 work may contain useful systems, but François reports that it still feels unpleasant: stiff/poor attacks, weak visual feedback, insufficient physical interaction, and feature additions did not materially improve the fight.

The target is a complete, controller-playable young Minato vs young Itachi duel with an interactive tutorial.

---

# 0. TOKEN / WORK RULES

Codex must minimize analysis and repeated repo reading.

1. Read this file first.
2. Inspect only the current `games/ninja-duel` implementation and the four external candidates listed below. Do **not** reread every old mission unless a concrete ambiguity requires it.
3. Create a short checklist in `games/ninja-duel/docs/archive/PHASE6_PLAN.md` (maximum ~100 lines), then immediately implement it. Do not stop for plan approval.
4. Prefer adapting proven free/open-source code over implementing generic engines from scratch.
5. Do not produce long design essays, speculative documents, or duplicate status files.
6. Do not repeatedly summarize progress. Work through the checklist autonomously.
7. Commit in a few coherent work packages, not dozens of micro-commits.
8. Ask François only if blocked by an action only he can perform, a license problem, or an irreversible architectural fork not resolved here.
9. Existing combat compatibility is NOT required. Replace weak abstractions rather than wrapping them forever.
10. Preserve useful Phase 5 work (selection, match lifecycle, chakra, networking, AI, etc.) only where it reduces work and does not constrain feel.

Success is judged by the playable duel, not by lines of code or feature count.

---

# 1. FREE RESOURCE POLICY — SEARCH / TEST / ADAPT / CONNECT

Codex's role is primarily **integrator and gameplay engineer**, not author of every engine.

Use only free/open-source resources whose license permits our intended use. Record source URL, exact reused/adapted files/components, license, and required attribution in `games/ninja-duel/THIRD_PARTY.md`.

Primary candidates to inspect, in this order:

### A. Tyrbropro / CombatSystem
https://github.com/Tyrbropro/CombatSystem

Candidate donor for battleground fundamentals: M1 chain, active hit windows, block/perfect block/guard break, directional dash, i-frames, attack lunge, hit reaction/knockback and common combat API.

### B. darrelwic15 / 3D-Fighting-Game-Roblox
https://github.com/darrelwic15/3D-Fighting-Game-Roblox

Candidate donor/reference specifically for 3D fighter interactions: light/heavy combat, launch/airborne state, air combos/juggles, block/break and flashstep-like movement. Reuse only code/assets whose ownership/license is clear. If licensing is absent/ambiguous or a file says it is not the author's, use it as behavioral reference only; do not copy it.

### C. cristophvolt-netizen / -Open-Source-Roblox-Movement-Base
https://github.com/cristophvolt-netizen/-Open-Source-Roblox-Movement-Base

Candidate donor for sprint/dash/momentum/wall-run/wall-jump/camera/audio movement behavior. Verify license before copying.

### D. zAxn1e / axiom-hitbox
https://github.com/zAxn1e/axiom-hitbox

Candidate hitbox package if compatible and licensed. Follow its documented installation/release method rather than blindly copying `/src` if its documentation says so.

Do NOT import four whole frameworks. Select the smallest useful subset. A good existing implementation should be adapted; an incompatible dependency should be rejected quickly.

If none of the candidates can legally/cleanly supply a needed mechanic, implement only that missing mechanic locally using their behavior as reference.

No paid assets or systems.

---

# 2. PRODUCT GATE: BUILD THE FIGHTER BEFORE THE NINJA LAYER

Before spending time on jutsu polish, the universal combat must be fun with techniques disabled.

Required universal combat grammar:

- responsive locomotion and target-relative strafe
- sprint
- large jump with useful air control
- ground directional dash
- side/back dodge
- air dodge
- lock-on
- light attacks with distinct punches AND kicks
- heavy attack
- advancing attacks rather than stationary punching
- combo branching
- intentional launcher/uppercut
- real airborne victim state
- pursuit/chase after launch
- aerial combo
- downward finisher / ground slam
- knockback
- knockdown + wakeup/recovery
- guard
- guard reaction / guard break rules
- limited substitution/evasive
- grab
- directional throw
- whiff recovery
- hitstun with no excessive unavoidable stunlocks
- sensible cancel windows
- wall interaction when a launched victim reaches suitable geometry; wall splat/bounce only if stable

Minimum interaction chains that MUST work:

### Ground conversion
`light -> light -> light -> launcher -> chase -> air light -> air light -> downslam -> knockdown -> wakeup`

### Horizontal conversion
`dash attack -> light chain -> horizontal finisher -> reset/pursuit`

### Throw
`grab -> directional throw`, with an upward/launching option if cleanly supported.

### Defense
Defender can guard/dodge and has a limited substitution/evasive resource so receiving the first hit is not always a cutscene.

These are systems, not scripted sequences.

---

# 3. COMBAT V2 DATA MODEL

Do not force everything into one mutually-exclusive state enum if that creates stiffness.

The implementation must be able to represent independently where appropriate:

### Locomotion
Grounded / Running / Jumping / Falling / Dashing / AirDashing / Chasing / WallRunning

### Attacker/action
Neutral / Startup / Active / Recovery / Guard / Grab / Throw / Technique / Defeated

### Victim/reaction
Free / GuardStun / HitStun / Launched / Juggled / Knockback / GroundBounce if used / WallSplat if used / Knockdown / Wakeup / Grabbed

Exact code names may differ. Requirement is behavioral: an airborne fighter can still be in a combat action; movement and reaction must not be artificially serialized by a single coarse state.

An attack definition should be able to describe at minimum:
- startup / active / recovery
- attacker movement/root travel
- hitbox
- damage
- hitstun
- victim impulse/trajectory
- launcher/knockback/knockdown reaction
- facing/target assist limits
- cancel/branch options
- block behavior
- hit/whiff behavior
- animation hook
- VFX/SFX/camera hooks

Momentum should matter. Avoid visually teleporting actors between combat beats unless it is an explicit character ability.

---

# 4. MOVEMENT / NINJA TRAVERSAL

The player must enjoy moving even before attacking.

Required:
- responsive acceleration/deceleration
- fast sprint
- large ninja jump
- preserve sensible horizontal momentum
- air steering
- ground dash
- lock-relative side/back dash
- air dodge/dash
- fast readable landing/recovery
- movement can flow into attacks
- attack movement does not feel like the character freezes then teleports

### Wall movement is required
Use/adapt a proven free implementation if legal and suitable.

Must support:
- detect suitable wall
- enter wall run/walk from ground or air naturally
- upward/lateral travel
- wall jump/rebound
- intentional detach
- clean gravity/orientation transitions
- corners/failure do not trap the player
- camera remains usable
- server/PvP validation seam

Do not spend time on water walking, trees, ledge systems or open-world parkour in this phase.

---

# 5. CONTROLLER-FIRST INPUT

A normal Xbox/PlayStation-style controller must be able to complete the tutorial and full duel with **zero keyboard/mouse use**.

Use Roblox input abstractions/context actions rather than hardcoding keyboard-only logic.

Recommended semantic actions (exact physical mapping can be adjusted to avoid conflicts):

- Left stick: movement
- Right stick: camera
- Right stick click: lock/unlock target
- South face button (A/Cross): jump; context can support chase after launcher if readable
- West face button (X/Square): light attack
- North face button (Y/Triangle): heavy / contextual launcher/downslam branch
- East face button (B/Circle): dodge/evasive; substitution through contextual/timed use or modifier if needed
- LB/L1: guard
- RB/R1: technique modifier / ninja actions
- LT/L2 and RT/R2: techniques or chakra actions
- D-pad: additional techniques only if needed

Requirements:
- controller glyphs/prompts in tutorial/HUD
- no cursor-dependent combat UI
- menus navigable with controller
- rematch/character select navigable with controller
- simultaneous controller and keyboard support is fine, but controller is acceptance target
- haptic feedback may be added for meaningful hits if simple and supported, but is optional

Do not map five separate jutsu in a way that makes controller play awkward. A modifier + face buttons is acceptable.

---

# 6. UNIVERSAL NINJA LAYER

Once the combat gate works, integrate:

- Health
- Chakra
- Chakra regeneration/tuning
- Guard resource/cost if useful
- Substitution charges/resource
- basic projectile/tool contract for kunai/shuriken
- interruptible/prepared techniques
- range/LOS/facing requirements where relevant
- startup/channel/recovery
- cancel/feint only where intentional
- server-authoritative outcomes

Elemental architecture should remain extensible to Fire / Lightning / Wind / Water / Earth, but Phase 6 must NOT build five mediocre elements just to tick boxes.

Only implement the elements needed for this duel plus one reusable proof if cheap. Fire must be combat-ready for Itachi.

---

# 7. YOUNG MINATO — COMPLETE PLAYABLE KIT

The player fantasy is mobility, angles, kunai precision and tactical entry. Do not make him a cooldown caster.

### Stats
Data-driven and visibly distinct from Itachi:
- higher ground speed / acceleration
- stronger air control/mobility
- moderate durability/damage
- efficient movement-related chakra costs

### Universal combat flavor
Minato's basic attacks should travel more and reposition more than Itachi's. His combo animations/poses must visibly include distinct punches/kicks and athletic footwork.

### Required character tools
1. **Kunai Check**
   - quick, modest damage
   - usable to force reaction/set spacing
   - useful in air if stable
   - not spammable without cadence/cost constraints

2. **Quickstep**
   - character-specific fast angle change/reposition beyond universal dodge
   - useful for combo routing or whiff punishment
   - no permanent invulnerability

3. **Burst Entry**
   - committed fast entry/punish
   - real startup/travel/whiff recovery
   - integrates into combat rather than standalone damage button

4. **Marked Anchor / spatial signature**
   - keep only if it is fun and stable
   - visible/counterable anchor
   - relocation costs chakra
   - arrival does not guarantee free damage
   - useful for angle/chase/escape

No Rasengan/Kurama/adult-Hokage kit in this young prototype.

---

# 8. YOUNG ITACHI — COMPLETE PLAYABLE KIT

The player fantasy is precision, prediction, projectile pressure, Fire and deception.

### Stats
- slightly lower raw traversal than Minato
- precise melee/control
- efficient chakra
- stronger ranged/conditioning tools
- Read/deception reward correct prediction rather than autoplay

### Required character tools
1. **Shuriken pressure**
   - constrains movement / creates approach decisions
   - not simply ranged DPS spam

2. **Fire technique**
   - visible startup
   - committed area/range pressure
   - interruptible/punishable where appropriate
   - meaningful hit/guard interaction
   - real VFX/impact hook

3. **Read**
   - timed window/stance
   - rewards correctly reading a committed action
   - no passive permanent auto-dodge

4. **Genjutsu / deception**
   - victim retains control
   - use short false afterimage/decoy/target misinformation/false cue or similarly interactive deception
   - server retains authoritative true state
   - clear end/cleanup
   - counterplay through interruption, spacing/LOS, recognition, or timing
   - purpose is to induce one bad decision, not stun for several seconds

Itachi should feel composed and predictive, not like slower Minato with red particles.

---

# 9. ANIMATION / PRESENTATION IS PART OF GAMEPLAY

The current procedural-looking attack presentation is explicitly rejected by the user.

Do not claim success if the fight still looks like stiff R15 figures taking turns playing poses.

Use only original/free/legal assets. Reuse compatible free animations only when license/ownership is clear. Otherwise create the best legal in-project solution and expose clean animation IDs/hooks for later authored replacement.

Minimum presentation coverage:
- distinct combat idle
- sprint
- strafe left/right/back
- jump takeoff / airborne / landing
- ground dash / air dash
- wall run / wall jump
- guard + guard impact
- hit reactions for light/heavy/launch/knockdown
- distinct light-chain strikes containing punches and kicks
- heavy
- launcher
- aerial strikes
- downslam
- grab/throw
- substitution
- Minato technique actions
- Itachi technique actions
- defeat/wakeup

Animation timing, root travel, hitbox active frames and victim reaction must agree. Foot sliding and snap-to-idle should be minimized.

If Roblox account publication is the only thing preventing final authored AnimationTracks, do not stop the whole mission. Complete the engine/integration and provide the smallest exact manual action required. But procedural placeholders alone cannot be described as final-quality animation.

---

# 10. CAMERA / HIT FEEL / VISUAL CLEANUP

Required:
- stable lock-on framing for two fighters
- survives large jumps, chase and wall movement
- target-relative movement readable
- restrained speed FOV
- small hit camera impulse
- stronger launcher/slam/technique impact
- local-only hit-stop or equivalent if safe
- trails/impact VFX synchronized to hit timing
- dust/landing/dash feedback
- readable Fire/projectile/illusion VFX
- sound hooks and legal/free sounds where practical

### HUD
The current debug-heavy presentation must not dominate the screen.

Player-facing HUD should primarily show:
- health
- chakra
- substitution resource
- compact technique readiness/icons/prompts
- lock target where useful

Move verbose `WHIFF / RECOVERING / state machine` information to developer/debug mode. The player should watch the fighters, not debug text.

---

# 11. ARENA

Build/refine one compact training arena designed for this combat, not a gray feature-test floor.

Need:
- enough horizontal room for sprint/chase
- useful walls for traversal and combat
- vertical surfaces/elevation
- readable collision
- no constant camera obstruction
- simple coherent ninja-training visual identity using legal/original Roblox primitives/assets
- decent lighting/materials
- reliable reset

Do not spend time building a village/open world.

---

# 12. AI

One fighter must be playable against the other as a functioning opponent.

AI uses the same combat actions/interfaces as the player where practical.

It should:
- approach/retreat
- strafe
- sprint/dash
- jump when useful
- melee and branch combos
- launcher + occasional chase/air follow-up
- guard
- dodge
- substitution when eligible
- use character techniques
- interrupt obvious committed techniques
- manage chakra/cooldowns
- occasionally use wall traversal only if reliable
- stop cleanly after defeat

No omniscience. Reaction latency/noise required.

Minato AI should favor mobility/angles; Itachi AI should favor spacing/read/conditioning.

---

# 13. INTERACTIVE CONTROLLER TUTORIAL

Required, playable with controller from start to finish.

Do NOT make a wall of text.

Tutorial is a sequence of short objectives. Detect successful action before advancing.

Suggested sequence:
1. Move with left stick.
2. Sprint.
3. Jump and land.
4. Lock target.
5. Directional dash.
6. Wall-run/wall-jump.
7. Land a light combo.
8. Use heavy/launcher.
9. Chase launched target.
10. Land aerial hits.
11. Downslam.
12. Guard an attack.
13. Dodge an attack.
14. Use substitution/evasive.
15. Grab and throw.
16. Use chakra/character technique.
17. Interrupt a telegraphed technique.
18. Short free practice / defeat training opponent.

Requirements:
- controller glyph/prompt for current action
- one objective at a time
- quick reset if failed
- skip tutorial option
- tutorial replayable from menu
- no keyboard required
- tutorial uses the real combat engine, not fake scripted controls

---

# 14. MENU / MATCH LOOP

Controller navigable:

`Main / Tutorial -> Character Select -> Minato or Itachi -> opponent -> Duel -> Result -> Rematch or Character Select`

Both Minato-vs-Itachi directions required. Mirror matches optional unless nearly free.

Character select should show concise gameplay identity and meaningful stats, not paragraphs.

---

# 15. QUALITY GATES — DO NOT HIDE BAD COMBAT WITH JUTSU

Codex must implement in this order and verify each before spending heavily on the next:

### Gate A — Graybox Fighter
Techniques disabled. Movement + melee + launcher + chase + air combo + slam + grab/throw + defense/substitution must form a coherent fight.

### Gate B — Ninja Movement & Presentation
Wall movement, camera, hit feel, animation integration, reactions, HUD cleanup and arena make Gate A readable and satisfying.

### Gate C — Minato / Itachi
Only now finish character-specific techniques, chakra, Fire, Read/genjutsu, identity-specific tuning and AI.

### Gate D — Controller Tutorial / Complete Loop
Controller-only tutorial and menu-to-rematch loop.

If Gate A is structurally weak, fix/replace it rather than compensating with particles or more abilities.

---

# 16. TECHNICAL / QA ACCEPTANCE

Automate what is reasonably automatable, but do not confuse passing tests with fun.

Verify at minimum:
- controller actions bind and no combat action requires keyboard
- menu/tutorial/rematch navigable via controller
- both fighters selectable/playable
- ground combo branches
- launcher transitions victim to airborne state
- chase only when eligible
- aerial combo works
- downslam/knockdown/wakeup
- grab/throw valid + invalid cases
- guard/dodge/substitution valid + invalid cases
- substitution resource consumption
- wall enter/traverse/jump/detach and cleanup
- death during air/wall/grab/technique
- reset/rematch clears all temporary states
- Minato techniques and cleanup
- Itachi techniques/genjutsu cleanup
- Fire hit/guard/interruption behavior
- chakra/cooldown rejection
- AI stops after defeat
- repeated rematches
- remote/exploit attempts cannot bypass server legality
- no stale wall/anchor/illusion/grab/action state

### Human feel checklist — mark `NEEDS HUMAN TEST`, never fabricate PASS
- Is moving fun for 30 seconds with no attacks?
- Does first contact feel responsive?
- Can player intentionally choose horizontal finisher vs launcher?
- Is launcher -> chase -> air combo -> slam satisfying?
- Does defender still make decisions?
- Does grab/throw feel physical rather than teleporty?
- Does camera survive vertical combat?
- Is wall movement useful rather than gimmicky?
- Does Minato feel fundamentally more mobile?
- Does Itachi make opponent think/read?
- Are jutsu part of combat rather than five cooldown buttons?
- Can a new player learn it with controller tutorial?
- Does player want an immediate rematch?

---

# 17. DEFINITION OF DONE

This phase is NOT done because modules exist or tests compile.

The deliverable must let François:

1. open the playable place;
2. use a controller;
3. optionally complete a real interactive tutorial;
4. choose young Minato or young Itachi;
5. enter the arena;
6. move quickly on ground, in air and on walls;
7. lock and fight with punches, kicks, combo branches, launcher, pursuit, air combo, downslam, guard, dodge, substitution, grab and throw;
8. use chakra and character-specific techniques;
9. experience Fire/deception/kunai/mobility interactions rather than standalone cooldown buttons;
10. fight a functioning opponent through victory/defeat;
11. rematch without restarting Studio.

The expected feel is a **Roblox 3D arena fighter with battleground-style physical combat + Storm-like pursuit/mobility + ninja tactical techniques**, not an RPG ability bar and not a tech demo.

We accept that this will not have AAA/Storm production values. We do NOT accept combat that is technically feature-complete but unpleasant to control.

---

# 18. FINAL OUTPUT — KEEP IT SHORT

At completion, do not write a huge report. Update:
- `games/ninja-duel/docs/archive/PHASE6_PLAN.md` with checked status
- `games/ninja-duel/THIRD_PARTY.md`
- existing README only where controls/run instructions changed

Then report only:
1. commit(s)
2. free resources actually reused/adapted and licenses
3. what is playable
4. automated/native tests run
5. exact 5-minute controller playtest François should perform
6. anything requiring a manual Roblox/Studio action
7. known blockers only

Do not propose Phase 7. The next step is one user playtest/feedback iteration.