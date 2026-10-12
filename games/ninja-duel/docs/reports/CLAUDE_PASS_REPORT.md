# Claude final combat pass — report (`0.8.0-claude-final-pass`)

Branch: `claude/minato-itachi-final`. This pass was **stopped early at the user's request**, so it is a
partial delivery of `../archive/missions/CLAUDE_FINAL_PASS.md`. What landed and what did not is listed below.

## Open this

`games/ninja-duel/dist/NinjaDuel.rbxlx` → Roblox Studio → **Test**. The QA place is `../../dist/NinjaDuel-QA.rbxlx`.

## Controls

Unchanged from the README (keyboard: WASD, LMB light, RMB heavy, SPACE jump/chase, Q dodge, F guard, V grab,
R kunai/shuriken, E chase, X substitution, G feint, C wall detach, CTRL sprint, SHIFT lock, 1–5 jutsu; the
controller map is unchanged too). The technique slots are now:

| Slot | Minato | Itachi |
|---|---|---|
| 1 | Marked Kunai (thrown while running) | Read |
| 2 | Flying Thunder God (teleport to the seal, even mid-flight) | Shuriken Barrage (5 blades) |
| 3 | Rasengan | Genjutsu: Mirage |
| 4 | Quickstep | Great Fireball |
| 5 | Wind Cut | — |

## What changed

**Combat / gameplay (server)**
- New projectile pipeline: every projectile has an id, a real launch point (hand or mouth) and an exact
  straight flight that the client reproduces on the shared server clock. Contacts report the projectile id,
  the surface normal and the owner, so the client finishes the exact object it was drawing.
- Kunai and shuriken throws keep the thrower in Neutral: the legs keep running and the blade leaves on the
  release frame. Itachi throws a precise pair; Shuriken Barrage fans five.
- Marked Kunai is a mobile throw. **Flying Thunder God reaches the seal mid-flight**, lands behind an opponent
  the seal is on, faces them, and opens a 0.55 s window in which an attack cancels the technique recovery
  (attack → dash strike / light, heavy → launcher, airborne → air string or slam). This is the
  `throw marked kunai → keep moving → teleport → attack from the new angle` loop. The AI uses it too.
- Fire is now **Great Fireball**: hand signs, then a growing travelling blast (62 studs) with knockback, splash
  and burning ground. A guarded blast is absorbed whole.
- Burst Strike presents as **Rasengan** (bigger spinning knockback).
- Server effect parts are logical markers only (the translucent neon blocks are gone from view).
- Snapshots carry projectiles, hazards, throw / cast / teleport timing and only unsent contacts; a contact,
  throw or teleport triggers an immediate packet (regular cadence 15 Hz).

**Presentation (client)**
- `VelmoraMotionEngine.luau` rebuilt into a full-body animation system: owned pose state (not diluted by the
  Animator), two-bone leg IK with planted feet, anatomically correct elbows/knees (the previous choreography
  bent elbows backwards), angular-speed-limited damping (no snaps), a real gait with stride/foot lift and the
  ninja run, authored multi-key clips for every attack of both fighters, throw overlays on the upper body,
  hand signs, Katon breath, Rasengan, Flying Thunder God arrival, wall run, chase pose, directional
  reactions, grounded knockdown/wake-up and KO poses that lie on the floor instead of floating.
- `Effects.luau` (new): real 3D kunai, Minato's three-pronged marked kunai with its seal tag, four-point
  shuriken, fireball (particles, light, growth), wind blade; planted seals; blades that stick where they land;
  explosion, scorch and burning ground; yellow-flash teleport (afterimage, streak, arrival burst); log
  substitution for Minato, crow scatter for Itachi; Minato speed trail; Itachi's Sharingan glow.
- Weapons in hand: reverse-grip kunai for Minato's cuts, forward grip / marked kunai during throws, shuriken
  in Itachi's left hand; each disappears on its release frame.
- Costumes (`World.dress`): rounded heads, eyes, brows, headbands (Itachi's slashed); Minato's spiky blond
  hair, jonin vest, open white haori with 四代目火影 and the flame hem; Itachi's long hair and ponytail,
  Akatsuki cloak with high collar and red clouds.
- Camera rewritten: it orbits (speed-limited) when the fighters swap sides instead of staying on the wrong
  side after a teleport or cross-up — a real bug in the previous camera.
- Fix: the HUD threw on an undefined `ui` every render, so technique slots, hints and the result title never
  updated.

**Tooling**
- `../../build.py` finds `luau`/`lune` on Windows and reads sources as UTF-8.
- `DevHooks.luau` (Studio only, inert in a live server): start duels, drive either fighter, freeze the AI,
  AI-vs-AI autopilot, state dumps and a client diagnostics channel, for playtesting from tooling.

## Verification actually run

- Headless suites: 64/64 PASS on the exact sources built into `../../dist` (`../../build.py`).
- Roblox Studio: the build was opened and played repeatedly. Seen working in Studio: duel start, costumes,
  Sharingan glow, the new stance with planted IK feet, the camera staying behind the player, burning ground
  after a fireball.

## Known issues / not done (honest)

- **Stopped before the arena / lighting pass**: the courtyard is still the flat grey box with dark walls.
- Attack, throw and jutsu clips, projectiles (kunai, shuriken, fireball flight), teleport flash, wall run and
  KO poses were written and are covered headlessly, but were **not yet reviewed frame by frame in Studio**;
  expect tuning (angles, timing, VFX scale).
- One Studio capture showed the fighters low in the frame; the camera needs a framing check in play.
- The enemy health bar was not visible in Studio captures; not investigated.
- The Bangla donor animations fail to load in Studio (asset permission 403). They are now visually overridden
  by the client engine, so this only produces warnings.
- `nativeQA`, `visualAcceptance`, `controllerFeel` stay `PENDING` in the manifest.

## What still separates this from a publishable alpha

Arena and lighting/atmosphere; a full Studio tuning loop on animations, VFX and camera; real sound design
(only three melee sounds plus built-in Roblox sounds are used); HUD/menus; PvP networking (the game is
player vs AI); mobile controls; a native QA run on the exact artifact; performance checks on low-end devices.
