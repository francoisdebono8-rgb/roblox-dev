# Ninja Duel — Velmora first playable fight

Version `0.12.0-final-playable` — see `FINAL_45MIN_REPORT.md` (smooth motion and camera, taijutsu routes, battle wear, arena) and `PUBLIC_BUILD.md`. Before: `FINAL_TODAY_REPORT.md` (Neji Hyuga as third fighter, smooth bodies and planted feet, rhythm, more taijutsu). Before: `PHASE4_REPORT.md` (combo scaling, recharging substitution, wall combat loop, clashes, multi-seal Flying Thunder God, context Rasengan, Itachi's Sharingan and Phoenix Flower). Previous: `PHASE3_REPORT.md`, `VISION_GAP.md`, `CLAUDE_PASS_REPORT.md`.

Open `dist/NinjaDuel.rbxlx` in Roblox Studio and **Test**. Select Minato or Itachi, then **Duel** or **Interactive Tutorial**. Velmora's position-history hit validation, parry/guard stamina, perfect dodge, additive R15 attack motion and hit feedback now run inside the principal combat runtime. Ninja Duel retains its proven R15 fighters, Minato/Itachi kits, launch/pursuit/aerial route, grab/throw, wall movement, camera, AI, substitution and full controller mapping. No donor installer or parallel combat/input controller runs.

The build manifest records automated and native status separately (`automatedQA`, `nativeQA`, `visualAcceptance`, `controllerFeel`). Controller feel and native Studio behaviour remain human gates; open the exact normal artifact above for the final pass. Pass history and open items: `STABILITY_PASS.md` (0.6.0 bugs), `FLUIDITY_PASS.md` (0.6.1 feel), `ANIMATION_PASS.md` (0.7.0 body animation, reactions, impact).

| Controller | Action |
|---|---|
| Left stick / click LS | Move / toggle sprint |
| Right stick / click RS | Camera / lock |
| X / Square | Light; third light finishes horizontally; throw while grabbing |
| Y / Triangle | Heavy; launcher after two confirmed lights; air slam; upward throw |
| A / Cross | Jump / contextual chase / mantle / wall rebound |
| B / Circle | Directional evade / substitution after a fresh hit |
| LB / L1; LT / L2; RT / R2 | Guard; grab; kunai/shuriken |
| RB + A / X / Y / B | Techniques 1 / 2 / 3 / 4 |
| D-pad up; View / touchpad | Technique 5; skip tutorial |
| D-pad / left stick + A | Menu selection and activation |

### Keyboard (grouped around WASD)

| Key | Action |
|---|---|
| **WASD** | Move |
| **LMB** | Light chain (third light finishes; throws while grabbing) |
| **RMB** | Heavy — launcher after two confirmed lights, air slam, upward throw |
| **SPACE** | Jump / wall rebound / contextual chase |
| **Q** | Dodge (becomes substitution right after being hit) |
| **F** | Guard (hold) |
| **V** | Grab |
| **R** | Kunai / shuriken |
| **E** | Chase during the launch window |
| **X** | Substitution (accessible, but never next to the movement keys) |
| **G / C** | Feint / wall detach |
| **CTRL / SHIFT** | Sprint / lock-on |
| **1–5** | Jutsu |
| Mouse move / wheel | Free-look when unlocked; camera distance |
| **ESC** | Skip tutorial |

Every key is declared once in `src/Shared/Controls.luau`, which also feeds the on-screen help and the tutorial copy. A key can never drive two actions; `tests/Regression.spec.luau` enforces that.

Ground-to-air route: **light → light → heavy launcher → chase → air light → air light → heavy slam**. A third grounded light chooses Bangla's finisher instead. Whiffs retain recovery; substitution spends charge/chakra; knockdown has a protected wakeup.

## Build and tests

From the repository root (or `games/ninja-duel`):

```
python3 games/ninja-duel/build.py          # normal place  -> dist/NinjaDuel.rbxlx
python3 games/ninja-duel/build.py --qa     # QA place      -> dist/NinjaDuel-QA.rbxlx
games/ninja-duel/tests/run.sh              # every headless suite
```

`build.py` runs all headless suites against the exact sources it embeds and refuses to write an artifact if one fails; the result is recorded in `dist/NinjaDuel.json` under `automatedQA`.

| Suite | Covers |
|---|---|
| `tests/Rules.spec.luau` | pure policy: states, costs, cooldowns, token bucket |
| `tests/Combat.spec.luau` | combat, donour migrations, controller callbacks, choreography |
| `tests/Sequences.spec.luau` | the 14-step acceptance route for both fighters, camera, AI, joints |
| `tests/Regression.spec.luau` | the bugs fixed in this pass, plus a randomised soak |
| `tests/Feedback.spec.luau` | contact feed and impact hierarchy |
| `tests/Animation.spec.luau` | stances, directional locomotion, hit reactions, knockdown/KO, weapons, and a full-fight no-snap contract |

The headless suites share `tests/Harness.luau`, a stubbed Roblox environment. They prove timing and state, not Studio physics, rendering or controller feel.

The native suite lives in `dist/NinjaDuel-QA.rbxlx`: open it in Studio, press **Test**, and read `[NinjaDuelQA] START 0.7.0-animation` followed by one `PASS`/`FAIL` line per case and the totals. `nativeQA` stays `PENDING` in the manifest until that run is recorded on the exact artifact.

## Normal-place acceptance route

1. Open the rebuilt **normal** place and Test.
2. Select Minato against Itachi.
3. Move, orbit, sprint and stop for 20 seconds.
4. Jump, steer in air, approach a ledge and traverse/rebound from a wall.
5. Lock Itachi and circle him.
6. Land the three-light chain; check that contacts and misses are clear.
7. Use two lights then heavy to launch intentionally.
8. Press chase during the launch window.
9. Land two air strikes then heavy slam; check landing and wakeup.
10. Block an incoming strike, then evade in a chosen direction.
11. Spend substitution immediately after being hit.
12. Use Minato's kunai, marked anchor, teleport, entry and Wind.
13. Rematch, return to selection and play Itachi.
14. Test shuriken, Fire, timed Read and deception.
15. Replay the complete interactive tutorial, including its reset/skip paths.

Record native errors and the first unpleasant control or unconvincing exchange. Source/import notices and exact components: `THIRD_PARTY.md`. Pre-migration snapshot: Git commit `d61c09b`; mission head: `2bac931`.
