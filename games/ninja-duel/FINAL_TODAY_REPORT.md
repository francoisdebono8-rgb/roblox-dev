# Final today — report (`0.11.0-final-today`)

Branch `claude/minato-itachi-final`. Code + playable build: commit **`24b8a0b`** (this report is the commit after it).
Open `games/ninja-duel/dist/NinjaDuel.rbxlx` in Roblox Studio (Mac or Windows) and press **Play** — nothing to build.

## Major changes

- **Smoothness.** Bodies no longer jump: each fighter is drawn on an interpolated track of its replicated
  position (the server root only moved every other frame), and the camera frames the same track. Feet no
  longer skate (cadence matched to speed and leg reach), turning on the spot takes pivot steps. Measured in
  Studio while walking: frames with a visual jump went from ~38 % to ~3 %.
- **Rhythm.** Deliberate walking pace with explosive sprint starts; heavier hitstop on finishers, launchers,
  parries and slams; the camera eases back after big blows and rises smoothly along walls; a K.O. beat before
  the result; the AI alternates pressing and probing and breathes after a combo.
- **Taijutsu.** Bigger, faster body mechanics on ground strikes (hips, shoulders, steps). New routes: heavy
  after one clean strike (Minato rising knee → pop-up, Itachi palm → push, Neji twin palms → wall carry), and
  out of a full sprint a flying kick (strike) or a sliding sweep (heavy) for every fighter.
- **Third fighter: Neji Hyuga (13)** — see controls below. Cream Hyuga top, Byakugan eyes, Gentle Fist stance,
  palm clips, trigram circle, Rotation dome, AI and roster/HUD integration.
- **Bug sweep.** All 9 matchups (Minato / Itachi / Neji, both sides, mirrors) run through intro, AI play, K.O.,
  result, rematch and back to selection in Studio: no stuck state, no server or client error.

## Neji controls

| Input | Action |
|---|---|
| LMB ×3 | Gentle Fist palms — each palm drains chakra (even through a guard), a clean one closes a chakra point (slower chakra recovery, up to 4) |
| LMB then RMB | Twin-palm thrust (pushes into walls) · LMB LMB RMB = launcher |
| Side / back + LMB in a string | Low sweep / kunai disengage |
| **1 Rotation** | Spinning dome: repels a strike, deflects blades and fire; then LMB = palm-thrust counter |
| **2 Vacuum Palm** | Air-pressure palm at range; also ends a clean string |
| **3 Sixty-Four Palms** | Point blank: locks, drains, then seals the opponent's techniques for 3.5 s (a substitution escapes it) |
| R · CTRL+LMB · CTRL+RMB | Kunai · flying kick · sliding sweep |
| Passive — Byakugan | Guard covers every side except a blind spot straight behind; Itachi's genjutsu decoy does not work on him |

Other fighters keep their controls (`PHASE4_REPORT.md`); Itachi has Phoenix Flower on 5.

## Tests run

- Headless suites **99 / 99 PASS** (`tests/run.sh`; new `Neji.spec.luau` 8 cases, `Phase4.spec.luau` 18 cases).
- Roblox Studio: full-flow sweep over the 9 matchups (0 errors), smoothness probe (walking and AI fights),
  frame captures of Neji's string / Rotation / Vacuum Palm into the wall / Sixty-Four Palms, Minato's knee
  route and flying kick, the K.O. beat.

## Remaining blockers

1. Movement is server-authoritative without client prediction: on a real network your own inputs lag by the
   ping, and the smoothing adds ~45 ms of visual delay. Client-side prediction is the next feel step.
2. Animation is still procedural keyframes on a block rig, and there is no real audio pass yet.
3. Neji is a prototype: his air string and throws borrow Itachi's clips.
4. Balance and fight length are tuned from AI-vs-AI data; human playtests are needed.
5. On this Windows machine (150 % scaling) Studio shows only part of the viewport; the Mac is unaffected.
