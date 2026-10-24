# Mission — Movement Overhaul + video references

Date: 2026-10-24
Project: `games/ninja-duel/`

Goal: move Ninja Duel from “clean Roblox movement” to a true ninja/anime locomotion feel where running, jumping, dodging, wall movement, air movement and attacks read as one continuous physical language.

This is NOT a request to add decorative flips or to create a second locomotion engine. Extend the existing movement/motion architecture, preserve combat authority and preserve the confirmed-hit combo invariant.

## Video references — mandatory

The user supplied two movement reference videos in this ChatGPT session:

- `ScreenRecording_10-23-2026 11-23-01_1(1).mp4` — ~34.3 s — SHA256 `25155cd47e5f5049f713f6f20adee7c69e5c486bb1c39471a88614b6ca84ddca`
- `ScreenRecording_10-23-2026 11-32-44_1(1).mp4` — ~53.0 s — SHA256 `9b376c35fc8a6acdea75990e991e37c21e8a011f58a47bd57dac19fadbaa5667`

A manifest is stored at `docs/references/movement/README.md`.

The MP4 bytes are not currently stored in Git because the available GitHub connector cannot upload local binary files directly. Attach the two videos to Claude when executing this mission. Do not claim they are versioned in the repo unless they are actually added later.

You must watch both videos before changing movement code.

Do not copy the exact game, assets or animations frame-for-frame. Extract the principles responsible for the feel:

**momentum + continuity + anticipation + weight transfer + contextual acrobatics + combat integrated into locomotion.**

Before coding, make a short map:

`observed element -> mechanical principle -> current Ninja Duel state -> adaptation proposed`

Focus especially on:
- run -> jump transitions;
- forward momentum preserved in launched jumps;
- backflips/side flips used by context, not spammed;
- rapid but readable direction changes;
- body orientation that matches trajectory;
- attacks triggered from movement without artificial stop;
- vertical traversal;
- wall movement;
- landing -> immediate re-acceleration;
- light body feel without losing impact weight;
- transitions between locomotion and combat.

## 1. Continuity is the main target

Desired chain:

`sprint -> long jump -> body rotation -> air attack -> landing -> pursuit -> wall-run -> wall-jump -> attack -> landing -> sprint`

The player must not feel separate systems stitched together.

Preserve when possible:
- direction;
- velocity;
- orientation;
- inertia;
- player intent;
- body posture.

Avoid `sprint -> stop -> jump animation -> stop -> attack animation`.

Prefer `sprint impulse -> takeoff from stride -> keep forward motion -> attack uses that motion -> landing absorbs and continues`.

## 2. Acceleration, braking, turning

Do not jump instantly from 0 to full travel speed except explicit special movement such as Shunshin/FTG.

Use a believable arcade/anime illusion:
- subtle forward lean when accelerating;
- hips/feet plant into direction changes;
- counter-lean while braking;
- slightly wider high-speed turns;
- direct low-speed turns;
- no turret-like root rotation.

Strafing must look lateral while attention stays on the opponent. Do not simply rotate a forward run animation 90 degrees.

## 3. Ninja running

Running needs:
- stride cadence that matches actual travel speed;
- real leg push and hip transfer;
- body angle that matches acceleration;
- clean foot contact;
- no visible skating;
- fighter-specific body language.

Examples:
- Minato: light, precise, no wasted motion.
- Itachi: economical and calm.
- Sasuke: aggressive projection, more vertical intent.
- Lee: athletic, stronger leg drive.
- Shisui: short bursts and fast angle breaks.
- Zabuza: heavier inertia because of the cleaver.
- Gaara: much calmer body, sand can support displacement.
- Haku: fine footwork, glide-like transitions.

Shared movement system is fine; shared visible expression is not.

## 4. Jump grammar

Do not use one Roblox-standard jump for every situation.

### Neutral jump
- compact body;
- moderate vertical rise.

### Launched jump
If entered from run/sprint:
- keep clear horizontal velocity;
- travel farther;
- body projects forward;
- takeoff must read as continuation of the previous stride.

### Backward jump / evade
- small hop at low intent;
- real backflip only when speed/evasion context justifies it.

### Side jump / evade
- side hop, side flip or cartwheel-like motion depending on speed/fighter/context.

Acrobatics must serve a purpose: evade, keep momentum, change angle, prepare attack, exit wall, cross obstacle.

## 5. Contextual flips and body rotations

Support real backflips, side flips, front rotations, partial rotations, twists and wall flips, but choose them from:
- direction;
- speed;
- height;
- ground distance;
- wall proximity;
- combat input;
- fighter movement profile.

Do not trigger flips just to make movement look busy.

## 6. Movement must feed attacks

This is critical.

### Sprint + Light
Do not always stop the character first. Depending on fighter it can become:
- launched punch;
- shoulder entry;
- gliding kick;
- running slash;
- palm entry.

### Jump + Forward + Light
Use current forward momentum. Examples:
- projected punch;
- dive kick;
- descending blade;
- palm strike;
- full-body impact.

The feeling should be: **“I was already moving, so the attack uses that movement.”**

### Sprint + Heavy
Can use more entry inertia but should pay with more recovery/commitment.

### Dodge + Light
Allow immediate flow into a riposte where appropriate.

Do not let directional attack routes violate the combo rule: before first confirmed hit, holding a direction must never replace the basic Light with a launcher/finisher route.

## 7. Momentum model

Preserve partial momentum between:
- run -> jump;
- jump -> air attack;
- air attack -> landing;
- dash -> attack;
- dodge -> attack;
- wall-run -> wall-jump;
- wall-jump -> attack;
- pursuit -> air combo;
- knockback recovery -> movement.

Do not preserve 100% everywhere, but do not reset velocity to arbitrary fixed values at every state change.

Consider:
- incoming velocity;
- input direction;
- next action;
- state-specific control caps;
- fighter profile.

## 8. Landings

Need multiple landing behaviors:

### Small landing
- almost instant;
- can flow directly into movement.

### Fast landing after launched jump
- one or two absorption steps;
- retain forward travel.

### Heavy landing
- knees/hips absorb;
- short lockout only if fall/attack weight justifies it.

### Combat landing
- recovery depends on air attack;
- preserve facing/attention toward opponent.

Avoid `touch ground -> idle reset -> run`.

## 9. Wall-run

Wall movement must be part of locomotion, not a separate mode.

### Horizontal wall-run
If speed and entry angle are valid:
- plant a foot;
- lean body toward wall;
- travel parallel;
- lose speed gradually;
- allow attack or wall-jump.

### Vertical wall-run
If entering wall with jump/forward velocity:
- real vertical foot plants;
- height depends on entry momentum/resource;
- allow attack, wall-jump or fall.

Avoid snapping onto wall, floating, or playing a normal run clip vertically.

## 10. Wall-jump and wall attacks

Wall-jump should:
- push away from the wall;
- preserve part of tangential velocity;
- use real body rotation;
- allow player steering of the exit.

Support a simple contextual grammar:
- wall-run + Light;
- wall-jump + Light;
- short wall contact + attack;
- descending attack from wall.

No button bloat. Context chooses the variation.

## 11. Air control

Allow correction, not unrestricted flying.

Player can:
- adjust trajectory;
- aim an attack;
- change angle moderately.

Player should not instantly rotate 180 degrees in mid-air unless a specific fighter mechanic explicitly allows it.

## 12. Dodge and dash

Directional dodges need different body language.

Forward dodge:
- short burst;
- lower center of gravity;
- off-line slip.

Backward dodge:
- retreat hop or backflip based on speed/context.

Side dodge:
- side-step or side-flip based on context.

Dash should not be one shared red VFX.

Shared gameplay abstraction is fine, but expression should vary:
- Minato: clean precise burst, subtle afterimage.
- Shisui: partial disappearance / false continuity / angle break.
- Lee: physical burst.
- Sasuke: aggressive acceleration.
- Itachi: short sober displacement.
- Gaara: controlled glide/sand support.
- Haku: ice footing/fine angle changes.
- Zabuza: heavier travel.

## 13. Camera

Camera supports the movement; it must not fake it.

Use sparingly:
- slight dynamic FOV at high speed;
- framing bias in travel direction;
- clean vertical framing during wall movement;
- brief landing accent;
- stable horizon during flips.

No constant shake.

## 14. Root-motion illusion / body coherence

Even if root-driven, visible body motion must match actual travel.

Avoid:
- root moving faster than feet;
- foot sliding;
- instant root rotation;
- rigid torso while trajectory changes;
- attack animation independent of velocity.

Use current Motor6D/motion architecture, impulse timing, orientation, stride matching, lean and anticipation to create the illusion of authored root motion.

## 15. Transition audit — highest priority

Explicitly test:
- idle -> run;
- run -> sprint;
- sprint -> jump;
- sprint -> Light;
- sprint -> Heavy;
- jump -> attack;
- attack -> air continuation;
- air attack -> landing;
- landing -> sprint;
- dash -> attack;
- dodge -> attack;
- jump -> wall;
- wall -> wall-run;
- wall-run -> wall-jump;
- wall-jump -> attack;
- wall -> ground;
- pursuit -> air combo;
- knockdown/get-up -> movement.

None should create an avoidable pause, snap, sudden orientation reset or visible pose reset.

## 16. Compact contextual movement grammar

Prefer one compact decision layer driven by:

`state + input + velocity + direction + surface + combat context + fighter profile`

Examples:
- `Airborne + ForwardVelocityHigh + Light -> forward aerial attack`
- `Grounded + Sprinting + Light -> running Light`
- `WallRun + Jump -> wall jump`
- `Grounded + Back + Dodge + HighSpeed -> backflip`
- `Airborne + NearWall + TowardWall -> wall contact`

Do not build dozens of isolated state machines if the current architecture can express this cleanly.

## 17. Fighter-specific weighting

Do not make everyone equally acrobatic.

- Lee: highest physical acrobatics and momentum expression.
- Shisui: fastest angle breaks, micro-disappearances, false continuation.
- Minato: precision, clean transitions, low wasted motion.
- Sasuke: verticality, kicks, aggressive movement.
- Itachi: minimal movement, efficient evasion.
- Haku: glide, fine footwork, mirror/ice-friendly movement.
- Zabuza: heavy inertia, less airborne freedom.
- Gaara: calm body, sand contributes to travel.
- Nagato: minimal acrobatics, controlled force-driven displacement.
- Bee: mobile but affected by multi-blade body configuration.

## 18. Do not overload

Do not solve this with:
- flip on every jump;
- particles on every dash;
- unreadable speed;
- disappearing constantly;
- permanent camera shake;
- unpunishable movement;
- long animations that remove control.

Quality comes from **timing + transition + posture + momentum + context**.

## 19. Studio acceptance

Automated tests are necessary but not sufficient.

The mission is only visually successful if Studio shows:
1. credible ninja run;
2. sprint -> jump with no break;
3. launched jump clearly preserving forward momentum;
4. contextual backflip on backward evade;
5. contextual side acrobatics;
6. jump + attack that uses movement;
7. sprint attack without artificial stop;
8. landing -> run flow;
9. credible horizontal wall-run;
10. credible vertical wall-run;
11. wall-jump preserving tangential momentum;
12. wall-jump -> attack;
13. pursuit -> air combo with no micro-pause;
14. camera supporting rather than hiding body problems;
15. no obvious foot sliding;
16. no brutal root pivot;
17. no visible pose reset between actions.

## 20. Continuous Studio route

Validate one uninterrupted route with the same fighter:

`sprint -> direction change -> long jump -> air Light -> landing sprint -> side dodge -> running Heavy -> jump toward wall -> vertical wall-run -> wall-jump -> air attack -> landing -> horizontal wall-run -> exit flip -> pursuit target -> air combo -> ground recovery`

Watch the whole sequence. Do not validate only one mechanic at a time.

## 21. Technical constraints

Preserve:
- current combat stability;
- server authority for combat;
- confirmed-hit combo invariant;
- existing good systems;
- performance;
- simple keyboard/controller controls.

Audit before changing:
- movement controller;
- motion engine;
- dash/dodge;
- jump;
- pursuit;
- wall interactions;
- camera;
- fighter-specific movement data.

Do not create a second locomotion engine if the existing one can be extended.

## 22. Priority order

1. locomotion continuity;
2. momentum;
3. jump/landing;
4. dodge/dash;
5. wall-run/wall-jump;
6. contextual moving attacks;
7. transition polish;
8. camera;
9. fighter-specific expression;
10. VFX polish.

Do not start with VFX.

## 23. Deliverable

Report at the end:
- exact systems modified;
- before/after for each major movement problem;
- Studio sequence used for validation;
- fighters actually replayed;
- remaining flaws;
- commits carrying the work.

Do not claim success only because automated tests pass.

The final target is a feeling of an extremely mobile ninja where **body + movement + combat form one continuous piece of motion**, visibly much closer to the supplied reference videos than to standard Roblox locomotion.
