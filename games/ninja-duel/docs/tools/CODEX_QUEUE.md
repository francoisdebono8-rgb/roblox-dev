# Codex queue — tasks Claude hands to Codex (DEC-030)

> Owner: Claude writes the tasks. Codex takes the **first task whose status is TODO** and sets it to `IN_PROGRESS (codex, date)`. It works on its own branch, created from the current HEAD of the Ninja Duel branch, and opens no PR into the protected branches. When it is done, it sets the status to `DONE (branch, commit)`. Claude reviews and integrates.
>
> Rules for every task:
> - Read `CLAUDE_START_HERE.md` and the docs it lists that the task needs. Follow `docs/active/EXECUTION_RULES.md`.
> - Never modify files Claude is working on. The current list is in the task under "Do not touch".
> - Never push to Claude's branch.
> - Run `python3 tools/check_project_docs.py` and the relevant test suites before reporting.
> - Base the work on references (the user's reference videos in `reference/`, the Naruto source material, fighting-game and Roblox combat-game practice) and say in the report which reference each choice comes from.
> - **Quality bar:** the user wants a beta that feels finished. Test-level placeholders are not acceptable.

## C-001 — Itachi: shot file for Blender (Partie 3 preparation) — DONE (Claude, 28/10: `tools/blender/itachi_p3.py`)

- **Goal:** write `tools/blender/itachi_p3.py`. It holds Itachi's complete authored move set, posed for the Blender control rig, ready for Claude to render and refine. It must not be wired into the game.
- **Read first:**
  - `docs/characters/ITACHI.md`, the bible;
  - `tools/blender/kunai_lion.py` and `tools/blender/sasuke_p1.py`, examples of the vocabulary;
  - `tools/blender/nd_ctrl.py`, `pose_bones()`, for the spec format;
  - `tools/blender/nd_shot.py`, `Shot`.
- **Vocabulary:**
  - yaw + turns right, pitch + leans forward, roll + leans right;
  - feet are WORLD positions: x right, z back, y lift;
  - arms take raise, out, twist, elbow and wrist;
  - spacing values are ease, pass, impact and launch.
- **Content, one function per clip, on Itachi's own stance (`Mirage`):**
  - Idle, Walk.F/B/L/R, Run.F/B/L/R, Sprint, Start, Brake, Jump.Air, Jump.Leap, Land;
  - Light1–3, Heavy, Launcher, Air1, Air2 and its routes (see `src/Shared/MoveGraphs.luau` for Mirage);
  - Throw.Shuriken with the **left** hand;
  - each technique: Read, NeedleFan, MirageCast, FireBloom, PhoenixFlower, as Channel/Release/Recover;
  - Guard, Dash.F, Intro and Awaken.
- **Timing:** markers (contact, recover, release) at the server's frame data. Read them from `src/Shared/Attacks.luau` together with Itachi's `AttackProfile` and Techniques in `src/Shared/Fighters.luau`.
- **Style:**
  - economical, precise and low. He invites the opponent's answer, then punishes with a smaller gesture;
  - the reference for fluidity is the user's TikTok video (see `docs/active/DECISIONS.md`, DEC-029); for the techniques, the Shonen Unleashed Itachi showcase;
  - amplify the poses ("ninja" amplification: hips turn 60–90°, chest past the hips, arms last, held overshoots).
- **Done when:** the file imports in Blender (no syntax errors), each clip has a docstring explaining its key poses (what carries the weight, what leads, where it is fastest) and the reference it comes from, and an `author(arm)` returns every action.
- **Do not touch:** `src/Client/*`, `tools/blender/kunai_lion.py`, `tools/blender/sasuke_p1.py`, `tools/blender/nd_ctrl.py`.

## C-002 — Online: two real clients in Studio (Partie 11 preparation) — TODO

- **Goal:** prove or fix the online 1v1 with two clients: the server and two players in Studio, Test > Clients and Servers.
- **Steps:**
  1. Write a reproducible checklist and a Studio helper script under `tools/studio/` that does the following:
     - two players queue (or use a private code);
     - they pick, fight for 60 s, then one forfeits or rematches;
     - one disconnects in the middle of the duel.
  2. Measure the snapshot bandwidth at the current `Config.SnapshotInterval` (0.033 s since DEC-030).
  3. Fix the desyncs or errors you find on the server or online side (`src/Server/Online.luau`, `Matches.luau`), with tests in `tests/Online.spec.luau`.
- **Done when:** the checklist is green in Studio with two clients, and there are 0 errors in Output.
- **Do not touch:** `src/Client/Presentation.luau`, `src/Client/Main.client.luau`, `src/Client/VelmoraMotionEngine.luau`. Claude is changing the local player's responsiveness there.

## C-003 — Hit impact pass (Partie 1 support) — TODO

- **Goal:** contacts must "snap" like the reference Roblox combat games. Work only in `src/Client/VelmoraHitFeedback.luau`, plus new textures if needed, for each contact kind: light, heavy, slash (kunai), kick, launch, guard, parry. The items:
  - hit-stop length;
  - small camera shake and FOV punch (through the existing camera impulse API, without changing `Camera.luau`'s interface);
  - impact spark or flash shape;
  - slash streak for kunai contacts.
- **References:** the user's TikTok video, which shows sparks, small blood flecks, a white slash arc and a short freeze. Note frame counts, and say which reference each value comes from.
- **Done when:**
  - `tests/Feedback.spec.luau` is extended and passes;
  - a short report lists the before and after values;
  - nothing in combat authority changes.
- **Do not touch:** `src/Client/Presentation.luau`, `src/Client/Main.client.luau`, `src/Client/VelmoraMotionEngine.luau`, `src/Client/MotionSmear.luau`.
