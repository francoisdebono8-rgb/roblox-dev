# Animation, reactions & impact presentation — `0.7.0-animation`

Built on `0.6.1-fluidity` and preserving it. This project did not add a mechanic,
an arena or a jutsu: it changed **what the bodies actually do**. The engine is the
same damped procedural motion layer — no new animation engine.

## The constraint that shaped every decision

The imported movement clips are `Movement`-priority Animator tracks, and Roblox
applies `Motor6D.Transform` **after** the Animator. So this layer is purely
additive: it cannot freeze or fight the rig, and disabling the Animator (and with
it every imported clip) would have been a one-way risk. Everything below is
written as an additive transform, so the worst case is a wrong-looking pose, never
a dead character.

## 1 — Locomotion is authored now

`Motion.locomotion` used to be a small waist bounce. It is now a full locomotion
vocabulary:

- **Authored idle stances.** Minato is coiled forward with his weight on the lead
  foot and a reverse-grip kunai hand, alive with a fast breath cycle. Itachi is
  upright and square, hands deliberate and close, with almost no idle motion.
- **Directional movement.** Forward drive leans into travel; **retreating** is its
  own shape (chest up, weight back, lead leg extending) rather than a slowed-down
  run; **strafing** tilts the torso into travel and opens the lead shoulder. The
  torso leads every turn so the head never snaps independently.
- **Stride driven by real speed.** The cycle phase advances with the rig's live
  velocity, so a stopped fighter stops striding and speed changes are visible.
- **Air and landing.** Separate takeoff, rising, apex, falling and
  landing-compression silhouettes. A hard landing absorbs visibly; a soft one
  barely interrupts the flow.

## 2 — Combos read as sequences

The three-hit string used to be `pose → reset → pose → reset`. The attack pose now
ramps out of **whatever the body is already doing**, so a chained attack continues
from the previous follow-through instead of snapping to neutral first. Feet
reposition, the torso carries its rotation, and arms do not reset between beats.
Minato's route stays angle-driven and lateral; Itachi's stays economical with a
stable base and deliberate finishing shapes. Grab/Throw/ThrowUp gained their own
authored frames for both fighters.

## 3 — Hit reactions answer the hit

The server now measures the contact direction and weight and sends them:
`hitFrom`, `hitAngle` (signed, relative to the victim's facing), `hitStrength` and
`reactionElapsed`. The client picks a reaction from that vocabulary:

| Hit | Body answer |
|---|---|
| Light frontal | small torso recoil, head/shoulder reaction, feet planted |
| Light from behind | the body folds **forward** |
| Side hit | the body rotates with the incoming direction |
| Heavy body hit | stronger bend, longer recovery |
| Launcher | contact compression → fold → feet leave → launched pose → air |
| Air hit (Juggled) | body rotates around the incoming direction, limbs trail |
| Knockback | carried by force, chest open, arms trailing, legs lifted |
| Wall impact | compression, splat pose, then recovery |
| Slam | air reaction → forced descent → ground collision → impact pose |

## 4 — Knockdown, ground and get-up

A new grounded pose family means a knocked-down fighter no longer slides along the
floor standing up. The body lies flat on the side it was knocked towards, then
runs a short three-phase get-up (push up, gather, stand) that never becomes
cinematic. This exposed a **real bug**: `airborne` was never cleared when a
knockdown body reached the floor, so the grounded pose could never play. Fixed in
`Brawler.step`, and `groundPose` is now cleared on full recovery.

## 5 — KO is a real defeat

`Motion.ko` settles the body from the blow that ended it — light collapse,
finisher collapse, launcher fall or slam stay-down. There is no rigid freeze, no
standing corpse and no floating defeated fighter; the result screen can appear
while the body settles. `koStyle` and `koAirborne` are preserved in the snapshot.

## 6 — Defence is readable

Dodge is direction-specific (backstep, forward slip and side roll are three
different shapes). Guard is a stable, intentional two-forearm stance that absorbs
into a small stance recoil. Parry keeps its decisive window. Substitution keeps
its gameplay and gains a clean departure/appearance.

## 7 — Weapons belong to the hands

Minato's kunai sits reverse-gripped in the right hand and is held through the
wind-up, the strike and the first part of the follow-through, then put away —
driven by the move's own `startup + active + recovery*0.45`, not a fixed timeout.
Itachi draws from the left hand on his throwing moves. A body move never leaves a
weapon hanging in the hand.

## 8 — Transitions

`Motion.present` is the single presentation contract, in strict priority order:
KO → ground → air reaction → defence → guard → landing → attack → locomotion.
Every **family change** is ramped over 130 ms from the body's current pose, and
within a family the per-layer damping drives it. This is what removes the
idle↔attack and ground↔air snaps. The engine also moved onto a **simulated clock
advanced once per frame by the render loop**, so the animation is identical on a
30 Hz and a 120 Hz client and is deterministic in tests.

## 9 & 10 — Impact support and camera

Added restrained wall dust (flat puff away from the surface) and reported the wall
impact, without new screen shake. Existing low-hitstop hierarchy untouched. The
camera now biases its focus towards the victim for launcher, air, slam, pursuit
and wall framing so a rising or falling body stays in frame, with a little more
height on the slam descent.

## Verification actually run

```
games/ninja-duel/tests/run.sh
  Rules        PASS  NinjaDuel pure policy: 7 PASS
  Combat       PASS  NinjaDuel headless combat/migration: 17 PASS
  Sequences    PASS  NinjaDuel sequence replay: 15 PASS
  Regression   PASS  NinjaDuel regressions: 12 PASS
  Feedback     PASS  NinjaDuel feedback policy: 5 PASS
  Animation    PASS  NinjaDuel animation presentation: 8 PASS
```

64 automated checks. The new `Animation.spec.luau` is the interesting one:

1. every pose stays inside human joint limits (18 states × 2 fighters + 4 KO
   styles);
2. idle stances differ per fighter and actually pose the body;
3. forward / backward / strafe / idle are four visibly different shapes;
4. hit reactions answer direction and weight, and a launched body is not a
   neutral airborne body;
5. **no snap across a whole fight** — a real fight is played through the real
   state machine and the largest single-frame joint change is measured with a
   rotation metric that is stable in this host runtime. Threshold: 32°/frame;
6. knockdown/wakeup/reset leave no broken animation state;
7. a KO settles by the blow that ended it, and never leaves the body upright;
8. weapons appear only for their own moves and are released after the swing.

Two measurement traps were found and fixed while writing these: Lune mirrors one
CFrame basis axis (so trace- and Euler-based angle metrics are wrong), and a
double-advanced presentation clock was making the animation frame-rate dependent.

### Regressions the tests caught during the work

- `airborne` never cleared on a knockdown landing;
- `groundPose` was not dropped after full recovery;
- the landing branch was ordered after the attack branch, so its family was wrong;
- the presentation clock advanced from inside the pose functions.

## Still PENDING — needs Roblox Studio

- `nativeQA` — open `../../dist/NinjaDuel-QA.rbxlx`, press **Test**, read
  `[NinjaDuelQA] START 0.7.0-animation`.
- `visualAcceptance` — **this is the one that matters most for this project.**
  Automated checks prove the poses are distinct, anatomically bounded, coherent
  per hit direction and snap-free. They cannot prove it *looks* good. Run the
  human acceptance test in the README: play a full fight without looking at the
  HUD.
- `controllerFeel` — unchanged mapping, still a human gate.
