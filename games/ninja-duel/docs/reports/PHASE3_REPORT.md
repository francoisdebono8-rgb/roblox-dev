# Phase 3 — Youth Tournament Core: report (`0.9.0-phase3-youth-tournament`)

Branch `claude/minato-itachi-final`, continuing from `8d7023d` without discarding the previous work.
Audit: `VISION_GAP.md`.

## Test it (Mac or Windows)

Pull the branch, open `games/ninja-duel/dist/NinjaDuel.rbxlx` in Roblox Studio, press **Play**. Pick your
prodigy on the roster screen, choose the AI opponent, **Enter the stage**. The file is self-contained:
scripts, arena, costumes and VFX are all in it; it only uses built-in Roblox textures/sounds and three
public sound ids already used before.

## Controls

Keyboard: WASD move · LMB light · RMB heavy · SPACE jump / chase · Q dodge · F guard · V grab ·
R kunai / shuriken · E chase · X substitution · G feint · C wall detach · CTRL sprint · SHIFT lock · 1–5
techniques. Gamepad unchanged (RB + face buttons for techniques).

**New this phase — directional branches inside a clean string** (hold the direction, press LMB):

| | Side + LMB | Back + LMB | After a Read |
|---|---|---|---|
| Minato | AngleStep: cuts while circling the guard (string continues) | kunai disengage (hop back) | — |
| Itachi | Sweep: knockdown, ends the string | two-shuriken disengage | CounterPalm on the next LMB |

Minato can also cancel a clean string into **Rasengan** (3) with a short wind-up. Itachi can cancel a
**blocked** light into shuriken (R). Techniques: Minato 1 Marked Kunai, 2 Flying Thunder God, 3 Rasengan,
4 Quickstep, 5 Wind Cut · Itachi 1 Read, 2 Shuriken Barrage, 3 Genjutsu: Mirage, 4 Great Fireball.

## What changed

- **Young prodigies, not adult final forms.** Minato (13): navy zip-up, open light half-vest (no haori, no
  kanji), holster and pouch, younger spiky hair. Itachi (13): village-era Uchiha shirt with the clan crest,
  grey arm guards, normal Konoha headband (no Akatsuki cloak, no slash). Bigger rounded heads, faces no
  longer shadowed by hair. Rasengan reduced to an "unfinished prototype" (20 damage, string finisher).
- **Arena: the Konoha Chunin Exam finals stadium.** Earth field with worn grass, bushes at the foot of a
  46-stud circular panelled wall (every panel is a wall-run surface, like Sasuke's run), field trees and
  boulders for line of sight, spectators along the rim behind a brick parapet, white pavilions with golden
  roofs, the two-storey Kage box with the 火 plaque, the participants' balcony and the gate. Bright exam-day
  lighting. The arena limit is now round.
- **Move graphs and cancel rules** (`../../src/Shared/MoveGraphs.luau`): character branches are data;
  strings continue only on a clean hit; on block only Itachi keeps a tool cancel; whiffs keep full
  recovery; Read opens a counter; Rasengan can spend a clean string.
- **Tournament presentation:** roster screen "Prodigy Tournament / 天才忍者大会" with 20 slots (2 playable,
  18 locked "Prodigy" slots for the future roster), match intro (camera orbit, full names with age and
  title, "VS", "始め! BEGIN"), tournament HUD (name plates with health/chakra, round banner, technique
  cards with cooldown), victory/defeat framing. During the intro Minato twirls a kunai and Itachi's
  Sharingan flares.
- **Crowd:** spectators rise and cheer on launchers, finishers, slams, teleports, parries and fire blasts.
- **Camera:** props between the lens and the fight fade instead of collapsing the camera onto the player;
  wider framing at long range; intro orbit.
- **Fixes:** gamepad focus warning on screen changes; Studio-only tooling (DevHooks, diagnostics, capture
  aid) never active in a live server.

## Verification

- Headless suites: **73/73 PASS** (new `Branches.spec.luau`, 9 cases: AngleStep, both disengages, Sweep,
  block rules, Read counter, Rasengan cancel, Flying Thunder God onto a kunai in flight, fireball at range).
- Roblox Studio playtests: costumes, stadium, intro and HUD inspected; Minato's marked kunai → teleport →
  arrival strike and Itachi's Great Fireball captured frame by frame; 45 s AI-vs-AI soak with no stuck
  state, no server error, max airborne time 0.8 s.

## Known issues

- On this Windows machine (150 % display scaling) the Studio window shows only part of the play viewport;
  this is a Studio display issue and does not affect the Mac.
- Clips for Grab/Throw, Air1/Air2 and turning on the spot are still weak (see `VISION_GAP.md` §5).
- No audio pass yet beyond the existing hit sounds and built-in Roblox sounds.
- The stadium is block-built (no textured roof tiles or wall panels); spectators are simple figures.
- `nativeQA`, `visualAcceptance`, `controllerFeel` remain `PENDING` in the manifest (human gates).
