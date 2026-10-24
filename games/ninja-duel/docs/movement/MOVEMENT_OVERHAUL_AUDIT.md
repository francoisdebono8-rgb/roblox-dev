# Movement overhaul — pre-code audit (24/10/2026)

Mission: [2026-10-24-movement-overhaul-reference](../archive/requests/2026-10-24-movement-overhaul-reference.md). Base `a0935c8`.

**Status: audit only, no movement code changed.** The brief makes watching the two reference videos a precondition for any movement change. They are not in the repo (see [manifest](../references/movement/README.md)), not attached to the Claude session, and not in the Mac folders this session can read (Documents, Desktop). Access to Downloads was refused. The "observed element" column below is therefore **empty until the videos are supplied**; only the current-state column is filled, from the code.

## Where movement lives today

| System | File | What it does now |
|---|---|---|
| Ground run / sprint / stamina, takeoff momentum, air steering | `Server/Place1Movement.luau` (donor, MIT) | Acceleration 170 / deceleration 290 / turn 360 (`Config.Movement`). Sprint 45. `preserveTakeoffMomentum` keeps horizontal speed on a jump; a sprint "bunny-hop" speed of 62. Air control with acceleration 76. |
| Mantle, wall hop | `Server/Place1Parkour.luau` (donor, MIT) | Ledge mantle (0.7–5.7 studs) on a Bezier arc. Wall hop: away 58, up 64, **max 2 per airtime**, cooldown 0.15 s. |
| Wall cling / wall run | `Server/Motor.luau` `tryWall` / `stepWall` / `detach` | One wall state: the root is placed against the wall and slides along it at RiseSpeed 23 / SideSpeed 30 for at most 1.65 s, then detaches. Rebound: up 61, away 29. A single mode: no horizontal-vs-vertical distinction, no speed-dependent height. |
| Dodge / evade | `Server/BanglaEvade.luau` | Always 14 studs × DashScale in 0.32 s, eased. **Sets velocity to zero every frame and at the end**: momentum is lost on entry and on exit. Same expression in every direction: no backflip or side-flip context. |
| Chakra dash / pursuit (E) | `Server/Combat.luau` + `Brawler` | Pursuit 74 studs/s, window 0.85 s, range 46; its arrival converts into a strike, heavy or grab. |
| Landing | `Combat.luau` ~l.1422 (`MovementLandedAt`, `MovementHardLanding`) | Hard landing gives an impact accent. One landing shape; no "small / fast-launched / heavy / combat" split. |
| Body (client) | `Client/VelmoraMotionEngine.luau` + Wave*Motion | Gait per fighter (`GAIT`: stride, cadence, lean, bob). IK feet with a step reach. Codex's `2bb05de` added strafe counter-motion and foot continuity. **No flip / side-flip / cartwheel / wall-run body clip**; the only flips are attack clips (Lion Kick). |
| Camera | `Client/Camera.luau` | Follow rig with a step limit, Studio-only film/capture modes. No speed FOV or travel framing. |

## First gaps the code already shows (to confirm against the videos)

1. **Dodge kills momentum** (`AssemblyLinearVelocity = Vector3.zero`), entering and leaving. That breaks "dodge -> attack" and "sprint -> dodge -> sprint".
2. **Dodge has one body**: no back hop / backflip / side step / side flip chosen by speed and direction.
3. **Wall movement is one mode** (cling-slide). No horizontal run with a gradual speed loss, no vertical run whose height comes from entry speed, wall-jump capped at 2 and not tangential.
4. **Landing is binary** (hard or not): nothing yet for "fast landing keeps travel" vs "heavy landing absorbs".
5. **Sprint attacks**: `DashAttack` exists per fighter, but whether a sprint+Light keeps travel or stops first still has to be measured natively.
6. **Camera**: nothing yet for speed/travel framing (low priority in the brief).

## Map to fill once the videos are watched

`observed element -> mechanical principle -> current Ninja Duel state -> adaptation proposed`

Videos watched 24/10 (contact sheets at 2–3 fps, then 6–15 fps on the key moments). User's note: the flips are not only evasions; they illustrate how the whole movement reads as ninja, especially in video 1.

| Observed (video, timecode) | Principle | Current state | Proposed adaptation |
|---|---|---|---|
| V1 0:00.6–0:01.6, 0:04–0:06: low crouched base, the body leans hard into each short burst, arms trail behind, then plants low | Weight goes first; the centre stays low between bursts | Gait is upright-ish; burst exists on the server (BurstWindow) but the body barely leans | Later pass: deeper lean on burst and on the start of a sprint (gait), not in this first commit |
| V1 0:07.9–0:08.3: mid-run front flip, body upside down, comes out straight into a strike on the opponent | A rotation carries travel into the attack: the flip is the approach | No travel rotation exists; jumps only lean | **Front flip on a chained launched jump** (second sprint jump soon after a landing), only for acrobatic fighters |
| V1 0:22.4–0:23.2: after the exchange, a high back flip out of contact, full 360°, then a crouched landing, arms spread | Leaving contact is a readable arc; the landing absorbs low with arms out for balance | Backward jump = sit back with the guard up; landing = generic crouch | **Back flip on a backward jump with momentum**; **ninja landing** (deep crouch, arms out) after a trick |
| V1 0:26.1–0:26.6: burst, then a sideways cartwheel (body horizontal) and a low recovery | Changing angle is done with the whole body | Side dodge = a lean and a slide | **Side flip / cartwheel on a side jump with momentum**, and **cartwheel / back handspring on side / back dodges** for the most acrobatic fighters |
| V2 0:00–0:00.7: running straight up a building, body perpendicular to the wall, then a flip over the top edge onto the roof | The wall exit is a rotation that turns vertical travel back into horizontal travel | Wall cling exits with a plain rebound | **Wall flip on leaving a wall** (rebound or top) |
| V2 0:01–0:09: rooftop to rooftop: takeoff from the running stride, long arcs with arms back and legs tucked, a burst in the air, landing straight back into the run | Momentum is kept from run to jump to landing; most long jumps are NOT flips | Server already keeps takeoff momentum and the running landing keeps the stride; air pose already sweeps the arms back on a running jump | Keep: plain long jumps stay leaps. Flips are reserved to the contexts above so they stay meaningful |
| V2 0:17–0:29: running up a slope with chakra feet, fighting on the move | Locomotion and combat share the same stride | Dodge zeroes velocity, so a dodge breaks the run | **Dodge keeps its momentum** on exit (server), so dodge → run / dodge → attack flows |

Who flips (brief §17): an `acro` level per fighter in the motion engine's data (like GAIT). Lee, Sasuke, Minato, Naruto, Shisui highest; Itachi, Nagato, Sasori, Zabuza, Gaara low (Gaara never). Below a fighter's threshold the same context keeps the existing lean, so not everyone is equally acrobatic.

Planned order (brief §22) once the map exists: continuity -> momentum -> jump/landing -> dodge/dash -> wall-run/wall-jump -> moving attacks -> polish -> camera -> per-fighter expression -> VFX. Everything stays inside the existing systems above (no second locomotion engine), with server combat authority and the confirmed-hit invariant preserved.

## Pass 1 — delivered (24/10)

- **Client body** (`Client/VelmoraMotionEngine.luau`, acrobatics block): per-fighter `ACRO` level (data, like GAIT) and per-trick thresholds `TRICK_AT`. A tracker (`trickStep`, every presented frame) notices takeoffs from the ground or from a wall and landings, and picks: back flip (backward jump with momentum), side flip (side jump with momentum), front flip (sprint jump chained off a landing within 0.45 s, never twice in a row), wall flip (leaving a wall). Duration from the real airtime (0.36–0.62 s). The body tucks at the top (side flip: arms open) and turns 360° around a pivot near the belly; any strike, technique, hit, dodge or chase cancels it at once. After a flip: the ninja landing (deep crouch on spread feet, arms out). Dodges: cartwheel (side) or back handspring (back) from level 0.75; forward stays a low slip. Presentation only.
- **Server momentum** (`Server/BanglaEvade.luau` `Evade.finish`, `Place1Movement`, `Combat`): a dodge that ends free hands its speed back (at least a running pace along the dodge, at most the sprint, never more than it came in with plus a run), so dodge → run / dodge → attack no longer stops dead. Without input the carry fades in a few frames.
- **Tests**: `tests/Movement.spec.luau` (9 cases, including a control: without the server change the run drops to ~10 studs/s at the dodge exit).
- **Not yet done** (next passes, brief order): sprint-start lean and lower ninja run; air attacks that use the takeoff momentum; landing variants by fall weight; wall-run horizontal vs vertical and tangential wall-jump; per-fighter dash expression; camera. Studio check of pass 1 pending.
