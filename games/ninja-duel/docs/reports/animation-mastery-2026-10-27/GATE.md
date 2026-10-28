> Rapport de travail, non normatif. Travail et critères : ANIM-001…006 ([MASTER_BACKLOG](../../active/MASTER_BACKLOG.md)). Méthode : [ANIMATION_CRAFT](../../research/ANIMATION_CRAFT.md).

# Animation mastery — competency gate (27/10/2026)

Rig: the control rig `tools/blender/nd_ctrl.py` (world IK feet, knee poles, centre of gravity, FK chest and arms, exact retarget to the Motor6D joints). Authoring: `nd_shot.py` (pose-to-pose keys with explicit spacing, overlap, mirrored cycles with computed planted feet). Clips: `clips_lion2.py` (Sasuke), `clips_flash2.py` (Minato). The `.blend` files with the actions on the control rig are in `Documents/NinjaDuelBlender/NinjaDuel_Sasuke_v2.blend` and `NinjaDuel_Minato_v2.blend`, and can be edited by hand in the Graph Editor.

Automatic checks on every clip (`nd_shot.check`): a foot that slides while on the floor, the centre of mass off the base of support on a slow frame, extremity speeds (spacing), and paths (arcs). After fixing the IK of straight legs, the cycles (run, sprint) show **0 skating**. The residual counts on walks and strikes are mostly heel lifts and pivots on the ball of the foot, which the measure (the centre of the foot) does not tell apart from a slide. That measure needs refining before it can serve as a gate.

## The six exercises

For each: where the weight is, what initiates, what follows late, the fastest spacing, where momentum is absorbed or redirected, why the key poses read.

1. **Weight shift** (`Lion.Idle`, `Flashstep.Idle`)
   - Weight: front foot 55% → back foot → front.
   - Initiation: the hips (`cog`) carry the centre of mass over the support foot.
   - Follows late: the chest +3 frames, the head and shoulders +5 (they counter, so the gaze stays fixed).
   - Spacing: slow in / slow out at both ends (a breath, not an action).
   - Absorbed: the rear knee loads, and the hip on the support side rises (contrapposto).
   - Read: two poses whose supports differ visibly. Minato does the same on the balls of his feet, in 1 s instead of 2.4.
2. **Acceleration → sprint → braking → change of direction** (`Start`, `Run.F/B/L/R`, `Sprint`, `Brake`)
   - Weight: in front of the feet at the start (a controlled fall forward); over the stance foot in the cycle; behind the planted heel when braking.
   - Initiation: the rear foot drives (heel up, the leg extending) and the hips go ahead.
   - Follows late: the chest straightens over the steps, the arms 1 frame behind the legs.
   - Spacing: fastest at toe-off (`launch`), arrival at the contact (`impact`).
   - Absorbed: on braking, the front leg catches the momentum (hips drop, chest back), and the second step plants and the weight rocks back onto it.
   - Direction changes: the side runs turn the hips and legs into the travel while the chest stays on the opponent. At runtime, the lean into acceleration and the bank into the turn come from the real velocity.
   - Read: the run's contact / down / passing / toe-off / peak poses with a flight phase. The ninja sprint with the arms swept back.
3. **Take-off → arc → landing → absorption → exit** (`Jump.Air`, `Jump.Leap`, `Land`)
   - Weight: in the legs at take-off (extended, ankles pointed). In the air, the centre of mass follows the server's parabola and the body only changes shape (extended → gathered → open).
   - Feet search for the floor before impact.
   - Landing: the front foot first, the knees take it (deepest at frame 5), and the chest folds over the knees to keep the centre of mass over the feet.
   - Exit: possible from frame 10; Minato lands quieter and is ready at frame 6.
4. **Committed strike** (`Light1`, `Heavy`, Minato's `Heavy` and `Rasengan`)
   - Weight: front foot, carried forward by the step.
   - Initiation: the rear foot pushes and the lead foot steps; the hips turn before the arm.
   - Follows late: the arm extends last, the head +2 frames.
   - Spacing: the fist or heel arrives at full speed on the frame the step lands (`impact`). The key before eases out, so the motion accelerates all the way.
   - Absorbed: overshoot of 2 frames (the shoulder rolls through), a retraction faster than the extension, and the rear foot drags up to rebuild the stance.
   - Read: one straight line from the rear heel to the fist (Rasengan, Chidori thrust).
5. **Directional hit reaction** (`clips_react2.py`, 28/10)
   - Contact: the struck part moves first, in 3 frames (`impact`): the head for a face blow, the hips and chest for a body blow, the ribs for a side blow, the spine for a blow from behind, the knee for a low one.
   - Follows late: the chest 4 frames after the head, the arms fly out last (`drag`).
   - Direction: the body goes with the blow. Each side is authored (`.L`), not mirrored, so the lead foot never swaps.
   - Support: the planted foot holds the real floor while the server slides the body ~0.9 stud; the other foot steps to catch the weight, then a step rebuilds the stance.
   - Recovery: the head comes back to the opponent first. Minato gives less and is back sooner (tempo 0.82) than Sasuke (1.0).
   - Same method for guard and guard impact, knockback and its landing skid, launch, knockdown, down, get-up (each side), forward dash, cartwheel, handspring and chase.
6. **Continuous transition** (run → jump → attack → miss → landing → run)
   - Runtime: inertialized transitions (pose and velocity carried, critically damped offset).
   - A strike thrown at a run keeps the run's legs.
   - Planted feet of authored strikes, casts and landings stay locked on the real floor while the server moves the body.
   - Start and stop are authored one-shots.
   - Headless tests: no snap leaving a run for a strike (the strike's worst frame stays within the run's own), and planted feet held to 0.03 stud while the server carries the body 3 studs. Both tests fail when their mechanism is removed (mutation).

## Status

- TECHNICAL PASS: 31 suites; release build. See the commit for its hash. Animation suite 24 cases, two added on 28/10 (strike markers inside their clip; a planted foot held under a hit), both checked by mutation.
- NATIVE_STUDIO: PASS on the checks listed below (build `8e664a8`, Debug, BUILD 079033dc…).
- HUMAN_VISUAL/FEEL: PENDING. The verdict belongs to the user.

## NATIVE_STUDIO (27/10, `Documents/Roblox/ND-Anim1.rbxlx`)

Real keys and mouse through Studio input, the bot frozen unless stated, and the client state read every frame:

- **Run → strike (Sasuke):** W held, then a click. The jab comes out on the run's legs with the stride kept; no pose replaced at once (chronophotograph).
- **Back jump → landing → backpedal:** seen, feet on the floor at the landing.
- **Chidori (Sasuke):** key 4 → `TechniqueChannel/Chidori` 0.68 s → neutral with the Chidori in hand → run (W) → click → `Startup/Active ChidoriThrust` → recovery. The thrust comes out of the run.
- **Flying Thunder God → Rasengan (Minato):** at a run, key 2 (FTG channel 0.1 s, recovery) then key 3 → `TechniqueChannel/BurstStrike` → `Active/DashAttack` → recovery → neutral in under a second.
- **AI duel, Minato (autopilot) vs Sasuke, 25 s:** dodges, stuns, Phoenix Flower channel/active/recovery; no error.
- **Console:** only the build line and the usual Studio messages in every run.

Not yet done in Studio: wall → strike, launcher → pursuit, a thrown body landing, Katon held at length, the 60–90 s round played by a human, VFX off then on (ANIM-005).

## Pass 2 (28/10): ANIM-005 and the five open points

**Bug found and fixed.** The export divided the clip markers by 60 a second time: every contact sat at ~0.002 s. The runtime maps the server's startup onto the clip's contact, so the stance was held through the whole startup and the blow played *after* the server's hit. This is very likely a large part of "strikes thought alone, not like a player who moves". Markers are now in seconds, the export refuses one outside its clip, and a test checks every strike. The contact now lands on the server's frame. A wind-up longer than the startup plays at most 1.25× its speed, its slow start skipped (the transition carries the body in).

Other runtime fixes:
- each blow is its own inertialized transition (a juggle hit no longer restarts the launch clip from the stance);
- an authored fall plays before the lying pose (the body went to the floor in one frame);
- a foot leaving the floor accelerates from rest (critically damped spring);
- a leg handed from a drawn pose to the feet solver starts from where it was;
- the air pose follows the vertical speed at a bounded rate.

Clips: Minato Light3 flip fixed (frames re-spaced). His Launcher kick chambers, extends, re-chambers, and comes down in front. The sprint and run passing positions moved away from the hip, which removed the knee flip on every sprint stride (104° → 46° per sample, Minato 81° → 45°).

### NATIVE_STUDIO (28/10, `Documents/Roblox/ND-Anim5.rbxlx`)

Joint motion per 1/60 s on both bodies, every frame, with the state of each fighter.

| Round (real keys, AI live) | Length | Frames > 40°/frame | > 60°/frame |
|---|---|---|---|
| ND-Anim3, Sasuke vs Minato, before the fixes | 90 s | 179 | 51 |
| ND-Anim4, Minato vs Sasuke, VFX **off** | 87 s | 160 | 30 |
| ND-Anim5, Sasuke vs Minato | 75 s | 94 | 23 |

- States covered across the rounds: light chains, heavies, launcher → pursuit → air strings, dash attacks, sweeps, guards, dodges, grabs, wire trap/bound, Katon, Phoenix Flower, Chidori (formed → run → thrust), FTG, Rasengan, marked kunai, hit-stun, knockback, juggle, knockdown, wake-up, defeat.
- **Wall → strike:** run and jump into the arena wall, click: `wall` → `WallDive` → the opponent is knocked down and gets up, with no snap above 75°.
- **Launcher → pursuit:** `Launcher` → `Pursuit` → `Air1` → `AirDrive` → the body is thrown (Knockback), lands and skids.
- **Thrown body landing:** `Knockback` (air) → `Knockback.Land`, inertialized over 0.08 s.
- **VFX off** (every effect part, particle, beam, trail, light and billboard hidden each frame): Katon is read as the hand brought to the mouth, Chidori as the arm carried while running. The bodies remain the only information, and the counts above did not rise.
- **Remaining snaps (> 60°):**
  - FTG arrivals (a teleport);
  - Minato Light3's spin on its first frames;
  - the start of a run (knee 65° at the hand-over from the start one-shot to the cycle);
  - a few shoulder pops at the return to locomotion.

## Status after pass 2

- ANIM-005: the reactions and defence have been re-authored, and the 60–90 s rounds have been played with real keys, with VFX both on and off. The human verdict remains open.
- HUMAN_VISUAL/FEEL: PENDING.

## Pass 3 — Sasuke's kunai string, animated in Blender (28/10, after the user's 12:08 feedback)

- New clips, authored pose by pose on the control rig and checked on renders from the game camera and a side camera (`tools/blender/kunai_lion.py`, `~/Documents/NinjaDuelBlender/NinjaDuel_Sasuke_v3.blend`, sheets `out/sheet_k*_*.png`):
  - `Lion.Light1`: a draw-slash. The hand goes to the thigh holster, then the blade rises across the body as the lead foot steps a full stud. It overshoots above the head and holds there.
  - `Lion.Light2`: a backhand return. The kunai is wound to the left shoulder, the rear foot steps through, then a flat left-to-right sweep. Ends right-lead.
  - `Lion.Light3`: a full spinning slash on the front foot. The arm is straight, so the blade draws a flat circle.
  - `Lion.Heavy`: a front salto (load, take-off, tuck, a full turn, open, land) into a downward axe slash.
- In game, a kunai is welded to Sasuke's right hand from the start of each of these four strikes to the end of its recovery. The weld is the same as in Blender.
- Engine:
  - the authored cap is 2200°/s for limbs and 3600°/s for the Root;
  - the Root may translate at 90 studs/s;
  - a foot planted by an authored clip is solved exactly.
- Headless: release PASS (Animation 24 PASS).
- Studio file for the user: `Documents/Roblox/ND-Kunai1.rbxlx` (Debug build).
- HUMAN_VISUAL/FEEL: PENDING. The user plays the string himself.
