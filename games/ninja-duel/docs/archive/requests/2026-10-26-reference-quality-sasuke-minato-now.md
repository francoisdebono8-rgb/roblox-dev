# OVERRIDE — REFERENCE-QUALITY SASUKE + MINATO NOW

Date: 2026-10-26
Priority: ABOVE roster breadth, new abstractions, progression breadth, extra fighters, and generic polish.

## Why this override exists

A new combat reference supplied by the user makes the acceptance bar concrete. The current Ninja Duel build is still far below the required *production density per character/action*. The problem is not lack of infrastructure. The project already has more than enough infrastructure. The problem is that the visible game still reads too often as a shared battleground/taijutsu engine with powers inserted between universal exchanges.

The user explicitly wants the SAME LEVEL OF DETAIL AND CARE visible in the reference: not copied assets/choreography, but the same production density, character fantasy, responsiveness, visual clarity, variation, and feeling that every power is a complete gameplay event.

STOP spreading effort across 20 fighters. STOP adding broad systems whose benefit is not immediately visible. STOP treating tests, architecture, generic hooks or data coverage as completion.

Until this gate passes, work only on the continuity blocker plus **Sasuke and Minato as the finished-quality vertical slice**.

## What the reference does that Ninja Duel must now match

The benchmark is not "more particles". It is this structure:

1. **Every meaningful technique has a complete body performance.** Anticipation, hand/body preparation, weight transfer, release, follow-through, recovery, and a coherent return to player control. The power is not a VFX placed on a generic cast pose.
2. **Every technique changes gameplay geometry.** Range, altitude, angle, position, threat, timing or information changes. A power is not merely damage + cooldown.
3. **Variants are part of the same ability when logical.** Tap/hold, ground/air/wall, recast, cancel, continuation or alternate release may exist when the fantasy supports it. Do not create twenty unrelated buttons; make the capability deep.
4. **Persistent things remain meaningful in the world.** A clone, seal, marked kunai, wire, hazard or planted object is a gameplay object/threat, not a short-lived decoration.
5. **The opponent has an authored consequence.** Hit, guard, miss, dodge, launch, skid, wall contact, breakable scenery, smoke/dust and recovery must visually agree with the attack.
6. **VFX support the action instead of hiding weak motion.** The silhouette, body trajectory and opponent reaction must already sell the move. VFX, sound, camera and environment amplify it.
7. **Abilities create decisions after activation.** Recast/cancel/route/aim/release decisions when appropriate. The player should frequently decide what to do with a capability already in progress.
8. **Character identity dominates generic combo grammar.** Watching a sequence with UI/names removed must still obviously read as Sasuke or Minato, not as the same fighter with different colors.
9. **Presentation is deliberately exaggerated where needed.** Major ninja powers must feel superhuman. Do not underplay scale, speed, anticipation, reaction or aftermath merely to keep implementation conservative.
10. **Control returns cleanly.** No state seam, pose snap, invisible magnetic correction, dead stop, float or awkward recovery between spectacular pieces.

## Hard rule: techniques are not packets

Do not implement the new quality bar as `press -> lock body -> play animation -> spawn effect -> damage -> recovery`.

A capability may enter a body/world state and then interact with movement, aim, altitude, wall state, objects and later input. The existing BodyState direction is good, but release must inherit the actual body trajectory rather than collapsing back into a generic attack packet wherever possible.

### Minimum technique contract

For every major Sasuke/Minato ability reviewed in this slice, explicitly answer and implement where relevant:

- What does the body do before activation?
- Can the player still move/aim while it exists?
- What changes on ground / sprint / air / wall?
- Can it be held, released, recast or cancelled? If not, why not?
- What happens on HIT?
- What happens on BLOCK?
- What happens on MISS?
- What happens on WORLD CONTACT?
- Does it create a persistent object/state/threat?
- What does the defender see/read and how can they answer it?
- What VFX/SFX/camera treatment supports the physical event?
- What is the exact exit back to player control, inheriting velocity/pose/facing?

A move is not finished because its server logic works. It is finished when every relevant answer is visible and coherent in Studio.

# SASUKE — required finished-quality slice

Sasuke must stop feeling like generic taijutsu + several jutsu slots. For three minutes the player must feel they possess an absurd ninja toolkit.

Required visible depth includes at least:

### Shuriken / kunai / wire
- real throws from the hand while moving;
- useful throws during run/jump/air situations where physically coherent;
- multiple useful trajectories/uses rather than one generic projectile event;
- wire is a real spatial tool: attach/control/route/setup where appropriate;
- wire/projectile setup must be able to create later decisions/interactions instead of disappearing as a combo VFX;
- missed weapons still visually belong to the world long enough to read correctly where useful.

### Katon
At minimum the fire capability must not be one identical cast every time.
- quick practical fire use;
- a committed/held stronger use where appropriate;
- clear body preparation and exhalation/release;
- smoke/heat/ground/world aftermath proportionate to the attack;
- target reaction appropriate to the actual hit;
- aim should be committed/readable, not magnetic tracking through evasions.

### Chidori
This is the canonical proof of the new philosophy.
- form it as a sustained state on the body;
- run with it;
- ground release;
- sprinting release that inherits the run;
- air/downward release;
- wall exit/release;
- bounded player steering, NOT 360-degree homing;
- a genuine miss that carries Sasuke through/away and creates recovery;
- collision with breakable scenery must damage/break the scenery even if no player is hit;
- the arm/body/speed must visibly agree throughout formation, travel, contact/miss and recovery;
- no `BodyState -> generic attack packet` visual seam at release.

### Sharingan
It must change the player's actual combat information/perception, not merely hidden parry numbers. The exact effect must remain competitive/readable, but the user must visibly/meaningfully experience that Sasuke is reading combat differently.

### Sasuke's taijutsu
Keep it, but make it one tool among many. Short, decisive exchanges. Do not make the optimal loop return to `Light1 -> Light2 -> launcher -> pursuit -> air string` every time power states end.

# MINATO — required finished-quality slice

Minato must feel like a player who is building and exploiting spatial geometry, not a fast generic fighter with teleport buttons.

### Marked kunai / anchors
- kunai are physical throws with readable release/flight/contact;
- planted/landed marked kunai persist as meaningful spatial anchors;
- throw while moving/jumping where coherent;
- different practical throw intentions/angles rather than one animation packet;
- teleport to a planted kunai;
- teleport to a marked kunai still in flight if the existing system supports it;
- previously placed kunai must create later routes, escapes, attacks and feints;
- the player should be able to look at the battlefield and understand the geometry they have created.

### Flying Thunder God
- no generic `teleport + auto-hit` grammar;
- teleport changes position; the player then owns the next decision unless a specifically authored action was chosen;
- ground/air/wall/kunai contexts must flow naturally;
- arrival must preserve/transform momentum coherently;
- whiffs and wrong reads remain possible;
- feints and spatial outplays are more important than guaranteed follow-ups.

### Rasengan
Treat it as a held dangerous capability where possible, not only a one-shot cinematic packet. Body, movement, hit/miss/world consequence and release must be authored with the same density expected of Chidori.

### Minato's physical style
Economical, geometric, minimal wasted motion, rapid angle changes. His taijutsu should bridge spatial decisions rather than become another universal three-hit combo engine.

# Visual continuity remains mandatory

Do NOT use this override to ignore the current continuity blocker. This quality target is impossible while the engine still exposes state seams.

The following must be fixed as part of the same vertical slice, not postponed:

- takeoff anticipation and real leg impulse;
- jump -> attack continuity;
- launcher -> pursuit continuity;
- pursuit -> air strike continuity;
- attack -> reaction physical inheritance;
- air -> landing anticipation/contact/compression/release;
- pose hand-offs with no visible missing frames;
- bounded facing with no direct one-frame CFrame snap except actual teleport powers;
- no magnetic attacker/victim tethering in air;
- no artificial body hover to preserve an air string;
- no camera/world occlusion regression;
- no visible foot skating at important contacts/landings;
- no VFX arriving before/after the body event it is meant to sell.

Architectural requirement: during any frame there must be a clear owner of root motion. Handoffs must inherit position, velocity, facing/angular intent, support/air state and relevant pose/momentum. Do not continue solving this with isolated animation patches if the root controller is the cause.

# Production-quality workflow — mandatory

For Sasuke and Minato, work **action by action in Studio**, not file-by-file.

For each capability:
1. play it at 1x with real controls;
2. inspect 0.5x/frame-by-frame when a seam is suspected;
3. test hit, miss and defensive answer;
4. test relevant movement contexts (run/air/wall/etc.);
5. test world contact when relevant;
6. inspect body silhouette before VFX;
7. add/adjust VFX/SFX/camera only after the body/event reads correctly;
8. retest the transition into the next free player action;
9. do not mark it done merely because automated tests pass.

Use `izzyfrm/roblox-ai` as a visual reference library when useful for animation/VFX/presentation, but references are supporting material, not a substitute for Studio iteration or this benchmark.

# Two mandatory deliverables before touching roster breadth again

## A. Character showcase proof
Produce a controlled real-time Studio showcase for **Sasuke** and one for **Minato**, roughly 45–60 seconds each, that deliberately demonstrates the production density above. It may use a passive/controlled opponent so every action is clearly visible, like a professional character showcase.

The showcase must make a viewer understand, without reading code, that these are exceptional ninja with deep capabilities.

## B. Free-fight proof
Then produce a **60–90 second Sasuke vs Minato real fight** using the same actual gameplay systems, not a scripted cinematic. It must naturally show different ranges, tools, mobility, powers, misses, defense, environment/world interaction and player-authored routes.

A good showcase with a bad free fight is FAIL. A good free fight with cheap/unfinished individual techniques is also FAIL.

# Acceptance gate

Do NOT return to the other roster until all are true:

- The user can watch the new footage without reading commits and immediately see a generational jump.
- Individual abilities have the same *density of authored detail* as the supplied reference: body + gameplay geometry + opponent consequence + presentation + clean continuation.
- Sasuke can spend a fight making meaningful decisions with shuriken/wire/fire/Sharingan/Chidori and movement instead of waiting to return to generic strings.
- Minato can spend a fight creating/exploiting kunai/FTG spatial geometry instead of repeating generic strings with teleport decoration.
- Chidori is visibly usable as a controlled state in multiple coherent directions/contexts and can genuinely miss/hit the world.
- At least several powers support meaningful hold/recast/cancel/context variations where the fantasy calls for them; not every power requires every variant.
- The environment visibly acknowledges major impacts without becoming cluttered or obstructing the camera.
- No obvious state seams remain in the showcased paths.
- The free fight does not repeatedly collapse into universal `3 hits -> launcher -> chase -> air` grammar.
- Removing UI and most VFX would still leave clearly different Sasuke and Minato body/gameplay behavior.

## Final instruction

Do not optimize for the smallest patch. Do not optimize for generic architecture elegance. Do not optimize for touching every fighter.

**Optimize for the player saying: `I am Sasuke` / `I am Minato`, and for the viewer saying: `this is finally at the level of the reference`.**

If the result still looks like the current game with extra effects, it is not done. Keep iterating in Studio until the visible difference is unmistakable.