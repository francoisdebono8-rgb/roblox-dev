You are taking ownership of the next major quality pass of Ninja Duel.

Repository:
`francoisdebono8-rgb/roblox-dev`

Work from the latest relevant Ninja Duel branch/current implementation. First inspect the repo, recent commits, current movement/combat/VFX/camera/animation architecture, existing audits and tests before changing anything.

PRIMARY VISUAL REFERENCE:
`ScreenRecording_10-23-2026 11-23-01_1(2).mp4`

Treat this video as a QUALITY REFERENCE, not as a request to copy individual moves.

The previous mistake was interpreting it too literally:
- add flips,
- add running attacks,
- preserve dodge momentum,
- add some transitions.

Those are useful, but they are not the real target.

# 1. THE REAL TARGET

The reference feels several levels above because the player almost never sees the game engine changing state.

The player sees:

`ninja action -> continuation -> reaction -> continuation`

rather than:

`run -> stop -> attack -> recovery -> idle -> dodge -> stop -> next move`

Our goal is:

> I should no longer see separate Roblox systems. I should see a continuous Naruto-style fight.

The combat must feel alive even with NO jutsu.

A 20-second sequence containing only:
- running,
- combat footwork,
- jumping,
- dodging,
- blocking,
- punches/kicks,
- kunai,
- getting hit,
- recovering,

must already look like an anime ninja fight.

Jutsu should enhance that foundation, not hide a weak foundation.

---

# 2. DEVELOPMENT RULE FROM NOW ON: BUILD THROUGH FIGHTS

Do NOT develop or validate systems in isolation.

The unit of development is now a COMBAT SEQUENCE.

Do not say:
- "dodge works",
- "kunai works",
- "wall-run works",
- "launcher works".

Validate:

`pressure -> side dodge -> angle change -> counterattack -> victim reaction -> chase`

or:

`run -> jump -> attack -> impact -> recovery -> continue running`

or:

`taijutsu exchange -> knockback -> wall interaction -> recovery -> re-engage`

Every system you touch must be evaluated in the context of a fight.

Automated/unit tests remain mandatory, but passing tests does NOT mean the work is visually accepted.

---

# 3. FIRST TASK: FULL AUDIT BEFORE IMPLEMENTATION

Before coding, perform a full audit of:

- current movement
- combat
- motion engine
- attacks
- hit reactions
- body-to-body spacing
- lock-on
- root motion / server movement
- jump / landing
- dodge
- wall systems
- weapons
- projectiles
- held objects
- VFX
- chakra effects
- camera
- hitstop
- sound timing
- character identity
- transitions between all of the above

Read the existing movement/video audit, but do not blindly follow it.

Use the VIDEO itself as the qualitative target if available.

Look for the implicit things, not only obvious features.

Ask continuously:

> Why does the reference look fluid even when very little is happening?

> Why does it rarely look like Roblox?

> Which tiny discontinuities in Ninja Duel expose the underlying game systems?

Document the findings briefly, then execute the entire plan without waiting for another review.

Do not stop after the audit.

---

# 4. CORE PRINCIPLE: CONTINUITY

The biggest goal is continuous physical and visual state.

Every action should inherit meaningful information from the action before it:

- velocity
- facing
- angular direction
- body pose
- center of gravity
- planted foot / supporting leg
- airborne state
- movement intent
- target relationship
- weapon state

And every action must leave behind a meaningful EXIT STATE for the next action.

Avoid unnecessary resets.

Bad:

`running pose -> neutral -> punch animation -> neutral -> run`

Target:

`running stride -> attacking step -> strike follow-through -> recovery step -> running stride`

The player should almost never visibly return to a generic neutral pose between connected actions.

---

# 5. BODY MECHANICS MUST EXPLAIN MOVEMENT

For every visible translation, ask:

> What physically pushed the fighter there?

If the root moves but:
- no foot pushes,
- no jump impulse occurs,
- no dash is expressed,
- no hit force occurs,
- no body lean supports it,

the movement will look like Roblox sliding.

Improve the relationship between:

- feet
- knees
- hips
- pelvis
- torso
- shoulders
- head
- arms

and the actual root trajectory.

Important:
Do NOT simply increase animation smoothing.

The reference is fluid because movement is CONTINUOUS, not because everything is soft.

It uses:
- sharp acceleration,
- fast pose changes,
- compression,
- extension,
- suspension,
- impact,
- follow-through.

Controlled snaps are allowed when they make motion feel stronger.

---

# 6. COMBAT MUST CHANGE THE GEOMETRY OF THE FIGHT

Taijutsu should not feel like two characters standing on fixed spots playing animations.

During exchanges:

- fighters gain/lose ground
- they circle
- they change sides
- one enters the other's space
- the other yields or redirects
- attacks can slightly overshoot
- missed attacks affect positioning
- defense changes the next angle
- knockback changes the next opportunity

Combat should create new spatial situations continuously.

Avoid magnetic "snap to opponent" behavior.

Avoid fighters merging into one another.

Avoid attacks always ending perfectly in front of the opponent.

Small controlled imperfections are desirable.

---

# 7. TWO-BODY CHOREOGRAPHY

Stop thinking only about the attacker.

A hit is an interaction between TWO bodies.

The defender reaction must help create the next readable combat state.

Develop a richer hit-reaction grammar.

Examples:

- head snap
- torso fold
- shoulder twist
- leg displacement
- light stagger
- side stagger
- backwards stagger
- loss of footing
- stumble
- spin
- airborne juggle
- hard knockback
- low knockdown
- roll
- skid
- wall splat
- wall bounce
- recovery step
- ninja recovery / landing

Direction and hit zone should matter.

The victim should not simply switch between a few generic:
`HitStun / Knockback / Knockdown` presentations.

Receiving an attack should be almost as authored as performing one.

---

# 8. TRANSITIONS ARE FIRST-CLASS CONTENT

Do not only author attacks.

Author the spaces BETWEEN attacks.

Important contexts include:

- idle/guard -> walk
- walk -> sprint
- sprint -> stop
- sprint -> pivot
- sprint -> attack
- sprint -> heavy
- run -> jump
- jump -> air movement
- jump -> attack
- attack -> run
- attack -> whiff
- attack -> next attack
- attack -> block
- block -> riposte
- dodge -> attack
- dodge -> run
- hit -> recovery
- knockback -> landing
- knockback -> roll
- landing -> run
- landing -> attack
- wall-run -> jump
- wall-run -> attack
- wall exit -> landing
- weapon draw -> throw
- throw -> movement continuation
- jutsu -> taijutsu continuation
- taijutsu -> jutsu continuation

Do not necessarily create unique animations for every pair.

Build systemic transition rules where possible.

But visually, these transitions must stop looking like state changes.

---

# 9. OBJECT / WEAPON INTEGRATION — ZERO VISIBLE BUG STANDARD

The reference feels polished because objects appear physically integrated into the action.

Make this an invariant across the game.

For every weapon/object:

`acquire/appear -> held state -> anticipation -> action -> release/contact -> world state -> cleanup`

Check:

- correct hand
- correct grip
- correct orientation
- no clipping through wrist/body
- no duplicate held + projectile object
- no one-frame disappearance
- no one-frame floating weapon
- no teleporting projectile spawn
- release occurs on the correct animation frame
- projectile begins at the correct world position
- projectile direction matches hand/arm motion
- body velocity is inherited when appropriate
- object remains visually stable during fast movement
- object cleanup never pops visibly

Audit:
- Minato kunai
- normal kunai
- shuriken
- swords if present
- fans
- chakra constructs
- Rasengan
- Chidori
- substitution objects
- clones
- seals
- any other temporary combat object

The current project already has some strong infrastructure for synchronized projectile presentation.

Preserve and generalize it.

---

# 10. VFX MUST BE ATTACHED TO EVENTS, NOT LAYERED OVER THEM

Do not solve weak combat by adding more effects.

VFX must CONFIRM physical events.

Order:

`body action -> physical/contact event -> visual accent`

not:

`approximate action -> giant VFX hides it`

Audit every important effect for:

- origin
- orientation
- timing
- duration
- scale
- cleanup
- relationship to the body
- relationship to the victim
- camera readability

Use short, precise impact flashes where possible.

Keep characters readable.

---

# 11. SPEED MUST REMAIN READABLE

The reference demonstrates an important rule:

You do not need to literally display every frame of extremely fast movement.

At very high speed, readability can come from:

- afterimages
- controlled streaks
- displacement silhouettes
- anticipation
- departure pose
- arrival pose
- trajectory cue
- brief residual image

Do not merely increase WalkSpeed.

The player should perceive:
- where the ninja came from,
- where they are going,
- why they ended there.

Investigate perception-based mechanics too.

For example, Sharingan / Byakugan / sensory abilities should potentially change how high-speed opponents are READ visually, rather than just giving statistical buffs.

Do not implement unnecessary new dojutsu systems unless appropriate to the current scope, but architect with this concept in mind.

---

# 12. CAMERA: DO NOT OVERCOMPENSATE

The reference camera is relatively restrained.

Do NOT try to solve the visual gap with:
- more shake,
- excessive FOV,
- constant zooms,
- cinematic interruption.

The current camera already has substantial combat framing logic.

Only change it where real combat testing proves it is breaking readability or continuity.

The BODY and interaction quality are the priority.

---

# 13. MOVEMENT MUST BE COMBAT MOVEMENT

Locomotion is not a separate minigame.

Walking, running, sprinting, jumping and wall movement must be designed knowing that an attack may begin at almost any moment.

Combat movement should include:

- low ninja posture where appropriate
- acceleration
- deceleration
- pivot
- directional changes
- short approach bursts
- retreat
- lateral movement
- combat circling
- long running jumps
- ordinary jumps
- contextual acrobatics
- landing that preserves momentum when appropriate
- landing that absorbs force when appropriate

Flips are NOT the objective.

They are one expression of movement.

Do not overuse them.

---

# 14. CHARACTER IDENTITY

Do not make fighters identical bodies with different speed values and jutsu.

Movement/combat language must differ.

Examples:

MINATO:
- economical
- extremely efficient direction changes
- little wasted movement
- kunai naturally integrated
- speed represented clearly
- teleportation feels like an extension of positioning

ITACHI:
- restrained
- precise
- minimal unnecessary acrobatics
- composed guard
- small efficient evasions
- deceptive positioning

SASUKE:
- more aggressive body rotation
- more acrobatic kicks
- offensive angle changes

LEE:
- highly physical
- explosive legs
- taijutsu-driven movement
- strongest visible body mechanics

GAARA:
- low acrobatics
- movement should not imitate Lee/Minato
- defense/sand identity changes his spatial behavior

Do not needlessly rewrite the whole roster now.

Use representative fighters to prove the system, then generalize.

---

# 15. COMBAT REFERENCE SCENARIOS

Create/use a small set of repeatable combat scenarios.

These are our visual acceptance tests.

## Scenario A — Pure taijutsu
NO jutsu.

20 seconds containing:
- approach
- footwork
- M1 exchange
- block
- dodge
- counter
- launcher or knockback
- recovery
- re-engagement

If this does not already look good, the pass is not finished.

## Scenario B — Minato vs Itachi
Test:
- speed
- kunai
- high-speed approach
- reading/countering
- angle changes
- teleport positioning
- weapon synchronization
- restrained vs explosive character identity

## Scenario C — Air/launcher flow
Test:
- launcher
- pursuit
- air attack
- defender reaction
- landing
- transition back into grounded combat

## Scenario D — Environment
Test:
- fight approaching wall
- wall interaction
- wall-run/wall-jump if context requires
- attack/recovery from wall
- return to normal combat

## Scenario E — Whiffs and imperfections
Intentionally miss attacks.

Verify:
- attacker follows through
- momentum remains believable
- no instant magnetic correction
- recovery pose makes sense
- next action begins naturally

---

# 16. VISUAL QA — FRAME-BY-FRAME

This is mandatory.

Use Roblox Studio real playtests if Studio is available.

Record or inspect combat sequences.

Slow them down / inspect frames when necessary.

Look specifically for:

- foot sliding
- feet penetrating floor
- root/body mismatch
- sudden rotation
- chest facing wrong direction
- body snapping back after attack
- idle pose flashing for one frame
- limbs clipping through torso
- limbs clipping opponent
- opponent bodies merging
- weapon grip errors
- weapon duplication
- projectile appearing away from hand
- effect origin mismatch
- effect one frame early/late
- incorrect landing pose
- abrupt camera recenter
- VFX lingering after action
- velocity suddenly disappearing
- weird pose during network/snapshot interpolation
- animation visibly fighting server movement

Treat any obvious occurrence during normal-speed gameplay as a bug.

Perfect mathematical animation is not required.

PERCEPTUAL cleanliness is required.

---

# 17. DO NOT BREAK GAMEPLAY AUTHORITY

Preserve:

- server authority
- confirmed-hit logic
- deterministic gameplay where currently required
- damage rules
- networking invariants
- anti-exploit assumptions
- existing validated combat functionality

Presentation can predict/interpolate where appropriate.

Do not let visual polish create false hit confirmation.

---

# 18. PERFORMANCE / ROBUSTNESS

Do not create a system that only looks good in ideal local Studio conditions.

Test where possible:

- normal FPS
- lower FPS
- snapshot interpolation
- rapid input
- repeated attacks
- repeated dodges
- several projectiles
- rapid direction changes

Avoid excessive per-frame allocations and unbounded VFX objects.

---

# 19. IMPLEMENTATION STRATEGY

You are allowed to refactor existing systems where necessary.

Prefer improving the current architecture over creating parallel movement/combat engines.

Do NOT pile another animation system on top of VelmoraMotionEngine unless there is an exceptionally strong reason.

Do NOT simply add dozens of special-case booleans to hide deeper architecture problems.

If the current structure makes continuity impossible, fix the structure.

A likely direction is to introduce a shared representation of:

- entry state
- action body intent
- trajectory intent
- contact state
- exit state

so locomotion/combat/presentation can hand state to each other cleanly.

But inspect the code and choose the correct implementation yourself.

---

# 20. EXECUTION ORDER

Work autonomously through the complete pass.

Suggested order:

1. Audit current fight end-to-end
2. Define visual/physical invariants
3. Fix state continuity
4. Fix body/root relationship
5. Improve two-body spacing/choreography
6. Improve hit reactions
7. Improve combat transitions
8. Audit weapons/objects
9. Audit VFX synchronization
10. Improve high-speed readability
11. Character expression
12. Environment/wall combat integration
13. Studio combat QA
14. Automated regression tests
15. Final tuning
16. Final acceptance fights

Do not stop after one or two items because they produced a visible improvement.

Finish the whole coherent pass.

---

# 21. ACCEPTANCE CRITERIA

This mission is NOT complete because:
- tests pass,
- code compiles,
- more animations exist,
- more movement states exist.

It is complete when the following statements are defensible:

### A.
20 seconds of combat without jutsu already looks like a ninja fight.

### B.
At normal speed, obvious transitions between locomotion/combat/defense are difficult to perceive.

### C.
Attacks visibly inherit momentum/posture from their entry state and leave a believable recovery state.

### D.
The defender's reaction corresponds to the attack rather than looking generic.

### E.
Two characters rarely overlap unnaturally or snap magnetically into position.

### F.
Weapons and combat objects have no visible attach/release/spawn bugs in tested sequences.

### G.
High-speed movement remains readable.

### H.
Missing an attack still produces believable body motion.

### I.
The same movement system does not make Minato, Itachi and Lee feel identical.

### J.
No large VFX/camera tricks are being used to hide poor body mechanics.

### K.
Automated tests and existing combat invariants still pass.

### L.
Real Studio combat has been played, observed and tuned — if Studio is available.

---

# 22. FINAL DELIVERABLE

At the end, provide:

1. The implemented code.
2. Passing relevant tests.
3. A short audit of what changed.
4. The combat scenarios actually tested.
5. Remaining visible weaknesses, if any.
6. Clear commit(s) with simple names.

Most importantly, explain each major change in terms of:

> "What became better during an actual fight?"

Not:
> "What new system/file/function was added?"

---

# FINAL PRINCIPLE

Keep this sentence as the quality bar for the entire pass:

> **The player must stop seeing the systems and start seeing the fight.**

And for every new implementation decision ask:

> **Does this make an actual 10–20 second combat sequence closer to the reference video?**

If not, it is probably not the priority.