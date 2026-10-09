# Codex Support Playbook — Ninja Duel V0.2

## Purpose
This folder is the implementation support layer for `COMBAT_FEEL_V02.md` and `CHARACTER_REFERENCE.md`.

Use it when a design requirement is clear but you need a concrete engineering pattern. These are reference contracts/pseudocode, not mandatory copy-paste code. Adapt them to the repository's actual architecture after inspection.

The goal is to solve the recurring hard needs once: movement, lock-on, action/state arbitration, animation ownership, melee motion, substitution/cancel windows, technique execution, hit feel, AI/controller parity, cleanup and future PvP seams.

## Non-negotiable engineering principles
1. Server owns authoritative combat outcomes: damage, chakra, cooldown legality, match state.
2. Local player movement/camera/animation presentation must remain responsive. Do not make every visual response wait for a server round trip.
3. Separate **intent**, **simulation/validation**, and **presentation**.
4. AI and human controllers should submit the same high-level combat intents where practical.
5. Fighter-specific mechanics extend common contracts; never build a giant `if fighterName ==` tree.
6. Temporary actions/effects own cleanup tokens so rematch/death cannot leak anchors, illusion clones, forces, tracks or connections.
7. Animation and locomotion state have explicit ownership/priorities. No random scripts fighting over `Humanoid.WalkSpeed`, `AutoRotate`, camera or animation tracks.
8. Tunables live in configuration, not scattered magic numbers.

---

# Suggested runtime layers

```text
Client
  InputController
  CombatController          -- turns inputs into intents
  MovementController        -- local responsive locomotion presentation
  LockOnController
  CameraController
  AnimationController
  FXController
  HUDController

Shared
  CombatTypes
  FighterRegistry
  FighterDefinitions
  TechniqueDefinitions
  StateRules
  Tunables

Server
  MatchService
  CombatService             -- validates intents/state
  DamageService
  ResourceService
  TechniqueService
  MovementValidationService -- validates extraordinary moves
  FighterRuntimeService
  AIController
```

Names may change to fit the repo. Preserve responsibilities.

---

# 1. Unified action intent

Human input and AI should converge on an intent structure similar to:

```lua
export type CombatIntent = {
    sequence: number,
    action: string, -- LightAttack, GuardStart, GuardEnd, Dodge, JumpBurst, Technique, Substitute, Cancel
    direction: Vector3?,
    targetId: string?,
    techniqueId: string?,
    clientTime: number,
    metadata: {[string]: any}?,
}
```

Server validates intent against current authoritative runtime state. Client sequence IDs allow acknowledgement/rejection and debugging.

Do not trust client-provided hit targets/damage. For exceptional movement, client requests the move; server checks state/resource/cooldown and constrains destination/travel.

---

# 2. Action/state arbitration

Use explicit action phases rather than dozens of independent booleans.

```lua
export type ActionPhase =
    "Neutral" | "Startup" | "Active" | "Recovery" |
    "Guard" | "Dodge" | "Hitstun" | "Channel" |
    "Airborne" | "Defeated"

export type RuntimeState = {
    phase: ActionPhase,
    actionId: string?,
    startedAt: number,
    endsAt: number?,
    canTurn: boolean,
    canMove: boolean,
    canCancel: boolean,
    interruptLevel: number,
}
```

Each action definition should expose phase timings and allowed transitions.

```lua
ActionDefinition = {
    Startup = 0.12,
    Active = 0.09,
    Recovery = 0.20,
    Movement = {...},
    CancelWindows = {...},
    InterruptibleDuring = {"Startup", "Recovery"},
}
```

Centralize transition rules:

```lua
function StateRules.canTransition(current, requested, context)
    -- defeated rejects everything
    -- hitstun only permits explicit escape/substitution windows
    -- recovery permits only declared cancels
    -- channel can be interrupted by qualifying hits
end
```

This is essential for future roster complexity.

---

# 3. Movement motor — target feel

Do not create ninja movement by only setting `WalkSpeed = 40` and `JumpPower = 100`.

Maintain a desired planar velocity and approach it with tuned acceleration/deceleration. Use frame-rate-independent integration.

Concept:

```lua
local desired = moveDirection * targetSpeed
local rate = desired.Magnitude > current.Magnitude and accel or decel
current = approachVector(current, desired, rate * dt)
```

Separate tunables:

```lua
Movement = {
    CombatRunSpeed = 28,
    SprintSpeed = 38,
    GroundAcceleration = 120,
    GroundDeceleration = 150,
    AirAcceleration = 55,
    AirMaxSpeed = 31,
    JumpVerticalVelocity = 62,
    JumpForwardBoost = 8,
    DashSpeed = 62,
    DashDuration = 0.16,
    DashRecovery = 0.12,
}
```

These numbers are starting points only. Tune in Studio by feel.

For jumps, prefer deliberate velocity/impulse control over default Roblox jump alone. Preserve horizontal momentum. Avoid infinite bunny hopping with landing/jump gating if needed.

## Lock-on movement basis
When locked:

```lua
local toTarget = flat(targetPos - playerPos).Unit
local right = Vector3.yAxis:Cross(toTarget).Unit
local desired = toTarget * inputY + right * inputX
```

Character facing can smoothly orient toward target while locomotion strafes around them. During committed attacks, attack definition can temporarily own facing.

## Dash
Dash should snapshot or continuously derive intended direction according to action design. It should have:
- startup cue (tiny);
- fast travel;
- optional narrow invulnerability window, shorter than total dash;
- recovery;
- cooldown/resource;
- collision handling;
- no uncontrolled fling physics.

Do not use unconstrained BodyVelocity-style hacks that launch characters through walls. Prefer modern constraints/controlled root velocity/validated displacement appropriate to current repo implementation.

---

# 4. Melee root motion profile

Every melee attack may define a motion curve independent of damage.

```lua
MovementProfile = {
    ForwardDistance = 5.5,
    StartNormalized = 0.10,
    EndNormalized = 0.62,
    Curve = "EaseOut",
    FaceTarget = true,
    MaxAssistAngle = 28,
    MaxAssistDistance = 7,
}
```

During the action, move the attacker through the intended distance while collision-validating. Do not snap directly to target.

Hit detection happens only in declared active windows. Prefer spatial query/hitbox modules rather than `Touched` for fast combat.

```lua
HitWindow = {
    Start = 0.18,
    Finish = 0.28,
    Shape = "Box",
    Size = Vector3.new(5, 5, 6),
    Offset = CFrame.new(0, 0, -3),
}
```

A four-hit combo should have four distinct movement profiles and reactions, not reuse the same punch four times.

Finisher reaction can contain launch velocity that intentionally leaves a pursuit opportunity.

---

# 5. Pursuit

After specific launchers, mark a short pursuit window.

```lua
PursuitWindow = {
    Duration = 0.65,
    MaxDistance = 22,
    ChakraCost = 8,
}
```

If player triggers pursuit during the window, execute a validated high-speed close-in toward a safe point near the airborne opponent. It is not a free hit; both fighters regain interaction after arrival according to tuned timings.

This is one of the highest-value systems for Storm-like flow.

---

# 6. Universal substitution / escape prototype

Implement this as a limited defensive resource rather than an unlimited combo breaker.

Suggested initial model:
- `2` substitution charges per round, or one charge regenerating very slowly;
- valid only during declared hitstun/attack windows;
- narrow timing window after receiving a qualifying hit;
- consumes charge even if it only repositions and does no damage;
- defender relocates a modest distance to an angle behind/side of attacker if safe;
- attacker receives no giant stun; combat instantly returns to a read/reaction situation;
- clear smoke/afterimage placeholder VFX;
- server validates charge/state/destination.

Pseudo contract:

```lua
Substitution = {
    Charges = 2,
    ValidHitstunAgeMin = 0.05,
    ValidHitstunAgeMax = 0.32,
    RepositionDistance = 7,
    Invulnerability = 0.10,
    Recovery = 0.12,
}
```

Do not make substitution a guaranteed backstab. Its reward is **escape + angle**, then the player must act.

This resource can later become fighter-specific or chakra-linked after playtesting.

---

# 7. Cancel system

Actions should declare exactly what they can cancel into and when.

Example:

```lua
CancelWindows = {
    {
        From = 0.22,
        To = 0.38,
        Into = {"Dodge", "Technique:Quickstep"},
        Cost = {Chakra = 6},
    }
}
```

Important distinction:
- **hit cancel**: available after confirming contact;
- **whiff cancel**: rarer/more expensive;
- **technique feint cancel**: specific channels may be intentionally cancelled to bait an interrupt, usually losing partial chakra.

Do not permit universal cancel-anything-at-any-time; commitment is central to the game.

---

# 8. Technique definition contract

Future techniques should be data-driven enough to support different execution grammars.

```lua
TechniqueDefinition = {
    Id = "MirageCast",
    ChakraCost = 28,
    Cooldown = 8,

    Requirements = {
        Grounded = true,
        TargetRequired = true,
        MaxRange = 26,
        LineOfSight = true,
        FacingAngle = 35,
    },

    Execution = {
        Kind = "Channel", -- future: InputSequence, Counter, Anchor, Stance
        Startup = 0.18,
        Channel = 0.62,
        Recovery = 0.35,
        Interruptible = true,
        CancelAllowed = true,
        CancelChakraRefund = 0.25,
    },

    Presentation = {
        Animation = "...",
        Telegraph = "MirageFocus",
        ReleaseFX = "MirageEnter",
    },
}
```

Pipeline:

```text
request
 -> validate requirements
 -> reserve/spend resource
 -> startup
 -> channel/execution
 -> interrupt/cancel OR complete
 -> resolve effect server-side
 -> recovery
 -> cooldown
```

Keep this generic enough for future hand signs, anchors, counters and stance requirements.

---

# 9. Minato-reference implementation seam

Do not encode `if Minato` in CombatService.

Character definition could expose:

```lua
FighterDefinition = {
    Id = "MinatoPrototype",
    MovementProfile = "MobilityProdigy",
    BasicCombo = "MinatoBasic01",
    Techniques = {
        "KunaiCheck",
        "Quickstep",
        "BurstEntry",
        "MarkedAnchorExperimental",
    },
    AIProfile = "MobileFlanker",
}
```

Anchor component interface:

```lua
AnchorService:Create(owner, worldCFrame, lifetime)
AnchorService:GetActive(owner)
AnchorService:Consume(owner, anchorId)
AnchorService:ClearOwner(owner)
```

Relocation validation:
- anchor belongs to actor;
- alive/current match;
- sufficient chakra;
- legal combat phase;
- destination not inside solid geometry/out of arena;
- max active anchors respected.

Arrival does not itself deal damage.

---

# 10. Itachi-reference implementation seam

Perception/read is a timed state, not passive auto-dodge.

```lua
ReadWindow = {
    Startup = 0.10,
    Active = 0.32,
    Recovery = 0.30,
    Cooldown = 3.5,
    EligibleThreatTags = {"CommittedMelee", "BurstEntry"},
}
```

When eligible threat enters the active read condition, grant a **short opportunity token** rather than auto-winning:

```lua
runtime.tokens.ReadSuccess = now + 0.45
```

Specific evasive/counter action can consume it.

## Illusion presentation
Server decides whether MirageCast succeeds. Client victim receives an effect payload and locally renders deception.

```lua
IllusionPayload = {
    effectId = guid,
    duration = 1.15,
    kind = "FalseAfterimage",
    sourceActorId = ...,
    seed = ...,
}
```

Never let illusion client logic alter authoritative real positions/damage. It manipulates **presentation/information**, while server simulation remains real.

Every illusion effect must register cleanup on timeout, death, match end and respawn.

---

# 11. Animation controller

One controller should own combat tracks for the local actor. Establish priority and track groups.

Conceptual layers:

```text
Base locomotion: idle/run/strafe/jump/fall/land
Action: attack/guard/dodge/technique/hitstun
Additive/upper-body (future): hand signs while limited locomotion
```

Rules:
- action animations override locomotion where needed;
- never restart a looping run animation every frame;
- use markers for meaningful events (`HitStart`, `HitEnd`, `Release`, `FootPlant`) but server must not blindly trust client markers for damage;
- blend out/in intentionally;
- locomotion speed can scale animation playback within reasonable range;
- landing chooses soft/hard variant based on vertical speed if available;
- avoid default Animate script fighting custom tracks; explicitly decide whether to replace/override it.

Create a debug overlay/command showing current movement state, action state and active animation track. This will save enormous iteration time.

---

# 12. Camera recipe

Lock-on camera target can be based on midpoint plus player-biased framing:

```lua
mid = (playerPos + targetPos) * 0.5
separation = (playerPos - targetPos).Magnitude
cameraDistance = clamp(base + separation * factor, minDistance, maxDistance)
```

Smooth with spring/damped interpolation, not raw `CFrame:Lerp` with frame-dependent constants.

Camera effects API:

```lua
CameraFX:Impulse(magnitude, duration)
CameraFX:SetSpeedFov(alpha)
CameraFX:TechniquePulse(kind)
```

Use tiny impulses for normal hits, larger but brief impulses for finishers. Avoid continuous shake.

Camera collision/raycast should prevent sustained clipping through arena geometry.

---

# 13. Hit feel event

One authoritative confirmed hit can fan out into presentation:

```lua
HitPresentation = {
    hitId = ...,
    attacker = ...,
    victim = ...,
    worldPosition = ...,
    severity = "Light" | "Heavy" | "Finisher",
    reaction = "StaggerLeft",
}
```

Client presentation may trigger:
- impact VFX;
- sound hook;
- victim reaction animation;
- attacker confirmation effect;
- tiny camera impulse;
- optional local hit-stop illusion.

If using hit-stop, do not freeze the entire server/world. Prefer local animation/time presentation tricks or very short controlled pauses that cannot desync authoritative combat.

---

# 14. AI utility interface

AI evaluates high-level actions, then submits the same intents as human controllers.

```lua
scoreApproach(context)
scoreRetreat(context)
scoreLightAttack(context)
scoreGuard(context)
scoreDodge(context)
scoreTechnique(context, techniqueId)
scorePursuit(context)
scoreSubstitute(context)
```

Apply reaction delay and noise:

```lua
score *= randomRange(0.8, 1.2)
nextDecisionAt = now + reactionDelay
```

Profiles alter weights rather than branching entire AI code:

```lua
MobileFlanker = {movement=1.4, angle=1.5, projectile=0.9, read=0.7}
PredictiveController = {movement=0.9, angle=1.0, projectile=1.2, read=1.5}
```

AI must only know information a plausible player/controller could know. No reading future inputs.

---

# 15. Cleanup scope

Create a match/fighter lifetime scope (Maid/Janitor-style pattern, custom if no dependency exists).

```lua
local scope = CleanupScope.new()
scope:Add(connection)
scope:Add(instance)
scope:Add(function() ... end)
```

Nested scopes:

```text
MatchScope
  FighterScope A
    ActionScope
    AnchorScope
    IllusionScope
  FighterScope B
```

Destroy MatchScope -> everything dies. This prevents rematch bugs.

---

# 16. Debug tooling Codex should add

Development speed matters. Add a developer-only debug panel or commands to:
- refill chakra;
- reset duel;
- toggle AI idle/active;
- show hitboxes;
- show current combat phase;
- show velocity/speed;
- show lock-on target;
- show active cooldowns;
- show substitution charges;
- optionally slow local test simulation/presentation for timing inspection;
- spawn/select either prototype quickly.

Do not ship debug UI to normal players.

---

# 17. Tuning workflow

Do not tune everything simultaneously.

Pass A — empty arena:
`run -> turn -> jump -> air control -> land -> dash` until enjoyable.

Pass B — stationary dummy:
`approach -> M1 chain -> launch -> pursuit -> reset` until enjoyable.

Pass C — defensive dummy:
`attack -> guard/dodge -> whiff -> punish -> substitution` until readable.

Pass D — techniques:
`create opening -> channel -> interrupt/cancel -> release`.

Pass E — AI.

Pass F — camera/VFX/audio polish and global retuning.

For every pass, record tunables changed and why. Avoid hiding feel changes inside unrelated code refactors.

---

# 18. Performance/network future checklist

Before considering V0.2 architecture stable:
- no per-frame server remote spam for normal movement;
- combat remotes rate-limited;
- server validates extraordinary movement and hits;
- spatial queries bounded/filter configured;
- temporary VFX primarily client-side;
- no unbounded task.spawn loops surviving match reset;
- no one RemoteEvent per technique if a typed/common protocol suffices;
- fighter definitions can be replicated/read without exposing authority logic;
- AI controller can later be replaced by a network player controller;
- match service does not assume Player 2 is always NPC.

---

# 19. What NOT to spend time on now
- 24 fighters;
- progression;
- quests;
- inventory;
- cosmetics store;
- ranked matchmaking;
- elaborate lobby;
- giant maps;
- final VFX;
- final UI brand;
- final monetization.

The test is movement + combat.

---

# 20. Escalation questions for François
Ask before committing only if one of these becomes a real blocker/major fork:
- R6 vs R15/custom rig choice materially changes animation future;
- custom physics motor vs Humanoid approach creates PvP/network tradeoff;
- legitimate animation production requires external/manual Studio work;
- Itachi's perception/genjutsu cannot be made convincing enough and Shisui would be a better V0 opponent;
- substitution fundamentally changes desired combo philosophy;
- marked-anchor teleport becomes the defining Minato mechanic despite age/lore ambiguity;
- a system requires irreversible repo/framework migration.

Otherwise implement and tune autonomously.