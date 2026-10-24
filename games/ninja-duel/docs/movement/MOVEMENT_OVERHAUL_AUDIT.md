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

| Observed (video, timecode) | Principle | Current state | Proposed adaptation |
|---|---|---|---|
| _pending videos_ | | | |

Planned order (brief §22) once the map exists: continuity -> momentum -> jump/landing -> dodge/dash -> wall-run/wall-jump -> moving attacks -> polish -> camera -> per-fighter expression -> VFX. Everything stays inside the existing systems above (no second locomotion engine), with server combat authority and the confirmed-hit invariant preserved.
