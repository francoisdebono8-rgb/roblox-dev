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
5. **Directional hit reaction**
   - Runtime: the clip is chosen by zone, side and strength, and mirrored for a blow from the other side. Its amplitude scales with the strength.
   - Batch 2 clips (`clips_react.py`) are kept. They were re-evaluated as functional but still generated from parameters, so a pose-first re-authoring is pending (ANIM-005).
6. **Continuous transition** (run → jump → attack → miss → landing → run)
   - Runtime: inertialized transitions (pose and velocity carried, critically damped offset).
   - A strike thrown at a run keeps the run's legs.
   - Planted feet of authored strikes, casts and landings stay locked on the real floor while the server moves the body.
   - Start and stop are authored one-shots.
   - Headless tests: no snap leaving a run for a strike (the strike's worst frame stays within the run's own), and planted feet held to 0.03 stud while the server carries the body 3 studs. Both tests fail when their mechanism is removed (mutation).

## Status

- TECHNICAL PASS: 31 suites; release build. See the commit for its hash.
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
