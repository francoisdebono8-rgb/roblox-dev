# Fluidity pass — `0.6.1-fluidity`

Human feedback on `0.6.0-stability`: every fix was good, but the combat read as
*move → micro-pause → correction → micro-pause → new animation*. This pass keeps
all of those fixes and removes the stutter. **No new feature was added.**

The 0.6.0 guarantees all still hold and are still tested: per-frame hit history,
active window re-testing, 3D pursuit that reaches a rising victim, a slam that
reaches the floor, a single-resolved combo counter, early input buffering,
`airHold` cleanup, stuck-state checks, the randomised soak and a clean
reset/rematch.

## 1. Hitstop is now a weight, not a pause

Before, every light hit froze **both** bodies for up to 55 ms, and the freeze also
pushed the swing clock forward, so animation and hitbox disagreed.

| Event | Before | Now |
|---|---|---|
| Clean light / small air hit | 45–55 ms, both bodies | **0** — contact keeps moving |
| Normal block | 40–55 ms | 10 ms, defender only |
| Light3 / finisher | 55 ms, both | 30 ms |
| Launcher | 55 ms, both | 40 ms |
| Parry | — | 50 ms |
| Slam / big jutsu | 55 ms | 65 ms |

Only the defender is stopped, and only for a genuinely heavy contact does the
attacker join for half that time. The swing clock no longer advances during
hitstop, so the animation never drifts behind the hitbox. Weight is declared once
in `Combat.Hitstop`; per-move `hitstop` values were removed from `Attacks.luau` so
a light jab can never be given a heavy stop again.

## 2 & 3. Continuous client presentation

The frame path used to be `Motion.clear()` (snap every Motor6D to identity) then
write the new pose, every frame, for both fighters. That is exactly the
snap → pose → snap the brief calls out, and it was the main source of visual
stutter.

- Motor6D transforms now **damp towards their target** (`Transform:Lerp`, rate per
  layer: 34/s attack, 26/s recoil, 24/s defense, 22/s guard, 16/s locomotion,
  14/s air). A hard reset exists (`Motion.reset`) and runs **only** on character
  switch, rematch, death or destruction.
- The pose no longer snaps to Neutral when an attack ends; damping carries the
  body back into locomotion.
- **Snapshot interpolation**: the client keeps a short buffer of snapshots and
  renders ~85 ms behind the newest one, lerping position between the two samples
  that bracket the render time. Motion is therefore continuous at frame rate
  instead of stepping at 10 Hz. The network rate is unchanged.
- The render is **corrected gently** (18/s damping) and only hard-snaps beyond
  14 studs — i.e. a real substitution, flashstep or respawn.
- Attacks animate from a **local clock** started the first time the attack is
  seen, so a late or jittery packet can no longer make the body jump backwards or
  replay its wind-up.
- Locomotion and air poses read the rig's **live `AssemblyLinearVelocity`**
  instead of the speed value that rode in with the last snapshot.

## 4. Pursuit and slam: fixes kept, corrections removed

`Motor.flight` teleported the root along a swept line, which is what produced
`advance → correction → advance`. Both moves now use continuous kinetic motion:

- New `Motor.move(a, c, aim, dt)` accelerates a **real velocity** towards the
  target with bounded acceleration (pursuit 1400, slam drift 220), integrates it,
  and only stops short on a genuine collision. Vertical is integrated with the
  same velocity and clamped at the floor.
- New `Motor.descend` gives the slam a constant plunge velocity (118) with
  bounded deceleration instead of per-frame position nudges.
- Pursuit **brakes on approach** (`speed = 40 + d²·2.4` under 7 studs) so it
  settles into the air-combo envelope instead of overshooting and snapping back.
- A gravity fallback pulls back a body that has stalled in the air with no
  physics owner. This is what used to leave a fighter hovering after a slam.

Position, not velocity, is still authoritative for hits, damage and states.

## 5. Camera noise

`Camera:impulse` now uses a per-style table and the health-delta fallback only
fires on a big scratch (≥12 damage or heavy), instead of adding a shake and FOV
kick to every single point of damage.

| Event | Shake | FOV |
|---|---|---|
| whiff / kunai / shuriken | 0 | 0 |
| light | 0.02 | 0.35 |
| dodge | 0.012 | 0.25 |
| launcher | 0.10 | 1.3 |
| finisher | 0.14 | 1.7 |
| parry | 0.15 | 1.8 |
| big jutsu | 0.17 | 2.0 |
| slam | 0.26 | 3.0 |

## 6. PC controls

Exactly the requested layout, still declared once in `Shared/Controls.luau` and
mirrored by HUD help, tutorial copy and tests:

`WASD` move · `LMB` light · `RMB` heavy · `SPACE` jump / wall rebound ·
`Q` dodge · `F` guard · `V` grab · `R` tool · `E` pursuit · `X` substitution ·
`G` feint · `C` wall detach · `CTRL` sprint · `SHIFT` lock · `1–5` jutsu.

The contextual chase stays on the jump key (SPACE on keyboard, A on a pad).
Gamepad is byte-for-byte the same mapping as before.

## Verification

```
games/ninja-duel/tests/run.sh
  Rules        PASS  NinjaDuel pure policy: 7 PASS
  Combat       PASS  NinjaDuel headless combat/migration: 17 PASS
  Sequences    PASS  NinjaDuel sequence replay: 15 PASS
  Regression   PASS  NinjaDuel regressions: 12 PASS
  Feedback     PASS  NinjaDuel feedback policy: 5 PASS
```

56 automated checks. Three new regressions protect the feel directly:

1. **hitstop weight** — a clean light hit must freeze neither body; the full
   hierarchy (light < finisher < launcher ≤ parry < slam) is asserted, so a light
   jab can never be given a heavy stop again;
2. **damped Motor6D** — one frame moves a joint part of the way, repeats stay
   continuous, a long run converges on the authored pose, and only the hard reset
   zeroes the skeleton;
3. **kinetic chase and slam** — neither the pursuit nor the slam may move the root
   more than a few studs in a single 10 ms tick, which is the automated definition
   of "no teleporting corrections".

## Still PENDING (needs Roblox Studio, which this environment cannot launch)

- `nativeQA` — open `dist/NinjaDuel-QA.rbxlx`, press **Test**, read
  `[NinjaDuelQA] START 0.6.1-fluidity`.
- `visualAcceptance` — the damped skeleton, snapshot interpolation and the calmer
  camera need eyes on the human acceptance route: one continuous minute of
  `move → attack → impact → continue`.
- `controllerFeel` — unchanged mapping, still a human gate.
