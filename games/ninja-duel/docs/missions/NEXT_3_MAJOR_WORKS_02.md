# Ninja Duel — Next 3 Major Visible Works

## Baseline
Work from the current playable baseline after commit `93dec769d8e958ce1830c2419f7d6ff81bc22ecf`.

The game is now more fun than before. Do **not** restart or replace the core movement/combat/runtime architecture. Every change must improve the current build directly.

The previous pass was too timid visually: it mostly changed timings, multipliers and small camera behaviors. This mission must create changes François can clearly see and feel in the first minutes.

No new general research. No new engine. No Foundation rewrite. No parallel prototype. No large refactor for cleanliness. Code -> build -> useful test -> correction -> commit.

---

# WORK 1 — REAL CHARACTER MOVESETS, NOT SHARED ATTACKS WITH DIFFERENT NUMBERS

## Problem
Minato and Itachi still feel too similar because they mainly share the same combat actions and differ through profile multipliers. That is not enough.

## Goal
Give Minato and Itachi **visibly different combat choreography, routes and body movement** while preserving the same universal combat grammar.

Universal concepts may remain shared: light attacks, finisher, launcher, pursuit, aerial route, slam, grab, guard, dodge, substitution.

But each fighter must execute them differently enough that, with UI and names hidden, François can tell who is fighting.

## Minato — expected visual/game feel
Minato should feel fast, precise, mobile and angle-based.

Create/replace concrete attacks so that his basic combat includes several genuinely distinct motions, not only timing multipliers:
- Light 1: quick advancing strike with a short body step.
- Light 2: fast follow-up that shifts him slightly around the opponent.
- Light 3 / finisher: strong lateral or forward conversion with clear displacement.
- Launcher: very fast and compact upward attack.
- Pursuit: aggressive catch-up that visibly closes the gap.
- Air 1 / Air 2: fast aerial strikes that alter relative positioning.
- Slam: sharp, controlled downward finish rather than a generic heavy attack.
- Dash attack: clearly different entry attack.
- At least one short-range kunai integration inside normal combat flow where appropriate.

Desired examples:
- `M1 -> M1 -> angle shift -> finisher`
- `M1 -> M1 -> launcher -> pursuit -> Air1 -> reposition -> Air2 -> slam`
- `kunai pressure -> movement entry -> melee`

Do not make every attack teleport. Minato should feel agile through body movement, angle changes and selective teleport/mark mechanics, not constant visual noise.

## Itachi — expected visual/game feel
Itachi should feel calmer, more deliberate, precise and control-oriented.

Create/replace concrete attacks so that he has his own choreography:
- Light 1: compact precise strike.
- Light 2: different rhythm from Minato, potentially preparing ranged pressure.
- Light 3 / finisher: creates space or a deliberate advantageous position.
- Heavy: slower and more committal than Minato's equivalent.
- Launcher: visibly different motion and trajectory from Minato's.
- Air 1 / Air 2: controlled aerial hits rather than Minato-style chasing strikes.
- Slam: heavier / more deliberate finish.
- Dash attack: controlled intercept rather than pure speed entry.
- Integrate short-range shuriken naturally into at least one route.
- Clone/deception should be able to interrupt the expected rhythm of an exchange without becoming a long stun.

Desired examples:
- `M1 -> short shuriken -> M1 -> finisher`
- `pressure -> feint/deception -> punish`
- `controlled launcher -> short air conversion -> spacing finish`

## Implementation requirement
Do not solve this only by editing values in `AttackProfile`.

It is acceptable to share infrastructure, but the active move definitions, body motion, animation/motion poses, attack travel and combo routes must actually differ.

At minimum, the following must be visibly different per fighter:
- several ground attacks;
- launcher;
- dash entry;
- aerial sequence;
- slam/finisher;
- at least one tool-integrated route.

## Human gate
Within 20–30 seconds of switching from Minato to Itachi, the difference should be obvious without reading stats.

---

# WORK 2 — COMBAT ARENA + VERTICALITY THAT ACTUALLY CHANGES FIGHTS

## Problem
Movement/wall systems exist, but the environment still does not contribute enough to the fight.

## Goal
Turn the current gray arena into a **small combat playground designed around the existing ninja movement**, not a decorative map.

Do not build a final art map. Build a strong gameplay arena.

## Required layout
Create one compact arena containing:
- clear central fighting floor;
- 2–3 usable vertical levels;
- at least two wall-run / wall-jump surfaces;
- one narrow elevated route/platform;
- one wider elevated combat platform;
- at least one wall/corner specifically suitable for wall-splat / wall conversion;
- open space for ranged pressure;
- enough cover/geometry to create line-of-sight decisions without making camera navigation miserable.

## Required gameplay interactions
The environment must meaningfully support:
- wall run;
- wall jump;
- launcher into vertical pursuit;
- aerial combat above/between platforms;
- slam from height;
- wall-splat / wall conversion;
- escape/reposition routes;
- projectile pressure around geometry.

A player should occasionally choose a route or position because of the arena, not fight as if standing in an empty box.

## Camera requirement
The current combat camera must survive this arena:
- both fighters remain readable at different heights;
- camera collision prevents clipping into walls;
- no violent rotation when fighters cross above/below each other;
- pursuit and aerial chains remain readable near geometry;
- wall fights do not collapse into a close-up of the player's back.

Do not rebuild Camera from scratch. Extend the current camera only where this arena exposes concrete problems.

## Human gate
François should be able to spend several minutes intentionally using walls/platforms during a duel and feel that verticality creates new attack/escape opportunities rather than visual clutter.

---

# WORK 3 — COMBAT PRESENTATION: VFX, SOUND, IMPACT, READABILITY

## Problem
The underlying fight is becoming more fun, but it still looks too much like Roblox characters executing logic. We need a major presentation jump without changing the combat engine.

## Goal
Make existing actions look and sound substantially more convincing.

Do not hide weak mechanics under giant particles. Effects must support readable combat.

## Hit hierarchy
Create a clear presentation hierarchy:

### Light hit
- small contact flash / sparks;
- short impact sound;
- tiny camera impulse if appropriate;
- very brief hitstop;
- visible victim reaction.

### Heavy / finisher
- stronger contact effect;
- stronger body reaction;
- more pronounced but short hitstop;
- short camera kick / FOV response;
- stronger sound layer.

### Launcher
- clear upward force cue;
- dust or contact effect at origin if appropriate;
- camera starts following vertical action smoothly;
- victim trajectory immediately readable.

### Pursuit / aerial hit
- readable speed trail only when useful;
- clear air-contact feedback;
- avoid filling the screen with particles.

### Slam
- visible downward acceleration;
- impact at ground contact, not before;
- ground dust/ring/debris-like effect using simple safe primitives;
- low-frequency impact sound;
- short camera impulse and fast recovery.

### Wall impact
- obvious but compact wall contact effect;
- sound distinct from normal ground hit;
- readable wall-splat state.

## Fighter-specific presentation
Minato and Itachi should also have subtle presentation signatures:

Minato:
- fast, clean yellow/blue-ish speed/mark cues consistent with current original visual language;
- kunai/mark actions should read instantly;
- short trails, not huge persistent glows.

Itachi:
- darker/red controlled cues for Read/deception/fire/shuriken interactions;
- clone/deception should be visually understandable after the fact, even if initially deceptive;
- fire must have readable startup, danger area and ending.

Keep all art original/generic enough for the project; no need for final production assets yet.

## Audio/readability
Use or generate only legally usable/project-safe audio references. If good audio assets are unavailable, prioritize the structure/hooks and current allowed assets rather than blocking the whole mission.

Important actions should sound different:
- light contact;
- heavy contact;
- block/parry;
- dodge/substitution;
- launcher;
- slam;
- wall impact;
- kunai/shuriken;
- fire/teleport/deception cues.

## Human gate
François should immediately notice that the same fight now looks substantially more alive and understandable, without making the screen noisy.

---

# DO NOT SPEND THIS PASS ON
- rebuilding movement;
- replacing the current combat runtime;
- another donor migration;
- generic research;
- progression/economy/shop;
- final map art;
- large menu/UI redesign;
- exhaustive keyboard remapping;
- long documentation;
- automated tests unrelated to changed systems.

Keyboard controls can be cleaned later. Only fix an input if it directly blocks testing these three works.

---

# EXECUTION ORDER
1. Real Minato/Itachi movesets and choreography.
2. Combat arena / verticality and camera fixes exposed by it.
3. VFX + sound + impact/readability pass.

Do not stop after changing data values. The mission is successful only when the changes are clearly visible in the actual `dist/NinjaDuel.rbxlx` build.

Preserve everything that is currently fun. Improve; do not restart.

Build the main artifact, do only necessary regression checks, correct obvious failures, and commit the result.