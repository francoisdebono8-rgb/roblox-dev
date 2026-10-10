# 45-minute final playable pass — report (`0.12.0-final-playable`)

Branch `claude/minato-itachi-final`. Playable build: `games/ninja-duel/dist/NinjaDuel.rbxlx` (open in Studio → Play).
Commit: see `git log` (the commit that adds this report; SHA also given in the chat delivery).

## Stutter / motion / camera
- Bodies are drawn on an interpolated track of the replicated root — **position and facing** — just before each
  frame (the server root only updated every other frame, and the old client correction fought replication).
- Only real teleports snap: the server now flags every relocation (`warpSerial`: Flying Thunder God,
  substitution, setups); dashes, chases and knockbacks are smoothed instead of hopping.
- Legs and lean follow the drawn body's velocity; planted feet move at body speed (no skating); pivot steps.
- Camera keeps up with high-speed movement (faster follow, speed cap raised from 210 to 520 studs/s).
- Studio probe (walking, frames with a visual jump): ~38 % before these passes → ~3–6 % now.

## Movement readability
Strafing leans into the step with shoulders on the opponent; retreating sits back behind a raised guard; bigger
hip/shoulder/step mechanics on every ground strike (previous pass), distinct dash/chase/wall/air/landing poses.

## Taijutsu / combo routes
- **Knock-away → chase → re-entry:** any strike that sends the body flying opens a chase window (E).
- Heavy after one clean strike differs per fighter (Minato rising knee pop-up, Itachi palm push, Neji twin palms);
  sprint + strike = flying kick, sprint + heavy = sliding sweep.
- Context route: Neji's third palm becomes the twin-palm thrust once three chakra points are closed.
- Existing: wall splat → pin / bounce → chase, launcher → air string → slam / Rasengan plunge, grabs and throws,
  Read / Sharingan counters, Rotation counter.

## Battle wear and arena
- Battle wear at 75 / 50 / 25 % health: dirt, scuffs, small grazes, then dusty darker cloth (no gore).
- Arena: the gate is now a pair of banded wooden doors instead of a black slab; twelve tournament banners
  (火 / 忍 / 試) dress the wall; decor never blocks the camera or collision.

## Tests
- Headless suites 99 / 99 PASS.
- Studio: full journey for all 9 matchups (intro → AI combat with air/wall/jutsu/substitution → K.O. →
  result → rematch → selection → next matchup): 0 stuck states, 0 server or client errors; smoothness probes;
  captures of the banners, battle wear and strings.

## Known issues
- No client-side prediction yet: online, your inputs lag by the ping; the smoothing adds ~45 ms on screen.
- Animation is procedural keys on a block rig; no audio pass.
- Not published to a Roblox Experience (see `PUBLIC_BUILD.md`: Studio menu action on the owner's account).
