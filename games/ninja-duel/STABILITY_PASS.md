# Stability pass — `0.6.0-stability`

Goal kept from the brief: **same livelier combat, far fewer bugs, more natural PC
controls, more satisfying hits.** No new arena, character, economy or combat
engine. No movement was removed to make the build easier to hold together.

Artifacts rebuilt on this pass:

| Artifact | SHA-256 |
|---|---|
| `dist/NinjaDuel.rbxlx` | see `dist/NinjaDuel.json` |
| `dist/NinjaDuel-QA.rbxlx` | see `dist/NinjaDuel-QA.json` |

## 1. Bugs found by replaying the acceptance route, and fixed

Each one was reproduced headlessly first, then fixed, then locked by a test.

1. **Strikes grazed past a target in front of them.** Hit range/cone validation
   sampled Velmora's position history only every third frame, so a fast-closing
   attack was checked against a pose up to 33 ms stale. Contact could be rejected
   at 8 studs while the hitbox visually overlapped. The history is now recorded
   every frame.
2. **A swing only tested its contact volume once.** `p.hit` latched `false` on the
   first active frame, so a target that entered the volume one frame later took
   no damage from a visibly connected hit. The active window now re-tests every
   frame until it connects.
3. **Pursuit never reached a rising victim.** The chase only moved towards the
   target horizontally, so after a launcher the attacker ended up on the floor
   underneath a victim 20 studs above it. Pursuit now flies to a 3D rendezvous
   point and settles into the air-combo envelope.
4. **The slam left the attacker hovering in mid-air.** The old descent stopped
   correcting as soon as the target dropped below the attacker, and its hover
   window outlived the attack. The slam now owns a bounded plunge sized from the
   drop at commit time and clears its own hover/airborne state on landing.
5. **A buffered light press advanced the combo counter twice.** The follow-up was
   resolved both when the press arrived and again when it chained, so "two
   lights then heavy" never reached the launcher branch. The step is now resolved
   exactly once, when the press is accepted.
6. **Early chain presses were dropped.** Buffering was only armed on an
   already-open chain, which made combos feel sticky. A press during a confirmed
   swing is now buffered and fires as soon as the chain opens.
7. **`airHold` could be left set on the ground.** It is now initialised and
   cleared, so a stale hover window cannot freeze a grounded actor.
8. **Analysis pass on the rest of the brief** (startup→active→recovery→neutral,
   forced facing, wall conversion, guard during impact, substitution during a
   reaction, grab/throw, camera mode and framing, reset/rematch) found no further
   stuck states; those paths are now covered by tests instead of hope.

## 2. PC controls

The keyboard layout is now declared once in `src/Shared/Controls.luau`, which
also feeds the HUD help and the tutorial copy, so the three cannot drift apart.

| Key | Action |
|---|---|
| LMB / RMB | Light / heavy — both immediately under the mouse hand |
| SPACE | Dash (and substitution right after a hit) |
| V | Jump / chase / wall rebound |
| F | Guard |
| Q, E, R | Grab, chase, tool — all in the WASD cluster |
| X, G, C | Substitution, feint, wall detach |
| CTRL / SHIFT | Sprint / lock |
| 1–5 | Jutsu |

The controller layout is untouched. `tests/Regression.spec.luau` fails if one
physical key ever drives two actions, and `tests/Combat.spec.luau` drives the
real `ContextActionService` callbacks for both input families.

## 3. Combat feedback

Contacts are now reported by the server with their real position, style and a
serial, and carried in the existing snapshot. The client plays the reaction on
the frame the hit happened — never on the frame the button was pressed.

Hierarchy (deliberately not the same effect everywhere):

```
whiff < kunai/shuriken/dodge < light < air/block/landing < launcher
      < finisher/parry < jutsu < slam
```

Each style combines only what it warrants: a short impact VFX with a light flash,
hitstop and a small camera impulse/FOV kick scaled to the style, plus the two
audio assets this project has already verified (light and heavy melee). The
whiff cue is a quiet air-slash with a nearly invisible shake, so misses now read
as misses instead of silence, and blocks, parries, dodges, substitutions and
landings are all distinguishable from plain damage.

**Audio note:** only the already-imported `8595980577` and `9117969717` melee
assets are used; no unverified asset IDs were invented. `src/Client/VelmoraHitFeedback.luau`
keeps a one-line `AUDIO` table for adding licenced cues (whiff, slam, parry,
block, substitution, landing) as soon as they are chosen, and
`THIRD_PARTY.md` remains the place to record them.

## Verification actually run

```
games/ninja-duel/tests/run.sh
  Rules        PASS  NinjaDuel pure policy: 7 PASS
  Combat       PASS  NinjaDuel headless combat/migration: 17 PASS
  Sequences    PASS  NinjaDuel sequence replay: 15 PASS
  Regression   PASS  NinjaDuel regressions: 9 PASS
  Feedback     PASS  NinjaDuel feedback policy: 5 PASS
```

53 automated checks. `Sequences` replays the 14-step manual route for **both**
fighters (move, dash, ground combo, launcher, pursuit, two air hits, slam, guard,
dodge, substitution, tool, jutsu, wall fight, death) and asserts no actor, AI or
camera is left broken. `Regression` adds a randomised 3 500-frame soak that fails
on any stuck state or orphan swing.

## Still PENDING (needs Roblox Studio, which this environment cannot launch)

- `nativeQA` — open `dist/NinjaDuel-QA.rbxlx`, press **Test**, read
  `[NinjaDuelQA] START 0.6.0-stability`. The QA place now also asserts the contact
  feed, the slam landing and the PC mapping.
- `visualAcceptance` — the new impact VFX and camera impulses need eyes.
- `controllerFeel` — gamepad feel is unchanged but still a human gate.
- Audio beyond the two verified melee assets.
