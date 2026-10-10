# Ninja Duel — Phase 6B migration candidate

Open `dist/NinjaDuel.rbxlx` in Roblox Studio and **Test**. Select Minato or Itachi, then **Duel** or **Interactive Tutorial**. The normal game now runs imported/adapted Bangla M1 contact/damage/feedback and directional evade, plus Place1 sprint/stamina, takeoff momentum, air steering, mantle and wall hops. R15, both character kits, the AI, substitution, guided tutorial and rematch lifecycle remain connected to the same server authority. No donor installer or parallel input controller runs.

**Pending acceptance:** compilation/build and automated policy/integration checks pass. Native Studio physics, donor animation access/retargeting, rendered choreography and controller hardware have not been validated. The public Punch asset download returned HTTP 403; Studio window control timed out. See `ANIMATION_TODO.md` for the exact owner publication step and remaining clip gaps. This is not a completed visual/feel gate.

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

Keyboard: WASD, CTRL sprint, SPACE jump, LMB light, T heavy/launcher/slam, V grab, F guard, Q evade, X substitution, R tool, E chase, SHIFT lock, 1–5 techniques, C wall detach, G feint, ESC skip tutorial. RMB + mouse orbits the third-person camera.

Ground-to-air route: **light → light → heavy launcher → chase → air light → air light → heavy slam**. A third grounded light chooses Bangla's finisher instead. Whiffs retain recovery; substitution spends charge/chakra; knockdown has a protected wakeup.

From the repo root: `python3 games/ninja-duel/build.py`, repeat with `--qa`; `luau games/ninja-duel/tests/Rules.spec.luau`; `lune run games/ninja-duel/tests/Combat.spec.luau`. Current evidence: 7 policy and 15 integration scenarios PASS with a geometry adapter. The native suite is in `dist/NinjaDuel-QA.rbxlx` and prints `[NinjaDuelQA] START 0.4.1-phase6b` then its totals. Reopen after rebuilding. An explicit native gate fails if donor R15 tracks cannot load/play.

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
