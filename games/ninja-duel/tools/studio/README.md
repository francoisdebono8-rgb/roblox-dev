> Référence technique/recherche, non normative. État, priorités et règles : [sources actives](../../docs/active/EXECUTION_RULES.md). Les commandes, exemples et anciens constats ci-dessous se vérifient sur le HEAD courant.

# Native Studio QA through the Roblox Studio MCP server

Tooling for observing and measuring Ninja Duel in a real Studio playtest, driven by an agent (Claude/Codex) without a human at the keyboard. Windows paths; added 2026-10-16. It is test tooling only: nothing here is built into a place.

## 1. Enable Studio as an MCP server (once)

User action in Studio: **Assistant** (sparkles icon, right end of the top bar) → **⋯** → **Manage MCP Servers** → **Enable Studio as MCP server**.

The toggle is stored as the built-in plugin setting `Assistant-ExternalMCPEnabled` in `%LOCALAPPDATA%\Roblox\<userId>\InstalledPlugins\0\settings.json`. With the user's consent, it can be set there while Studio is closed (back the file up first). Studio then connects to the WebSocket host opened by `StudioMCP.exe` (`127.0.0.1:13469`) and publishes its tools (`execute_luau`, `start_stop_play`, `get_studio_state`, `screen_capture`, `user_keyboard_input`, `user_mouse_input`, `get_console_output`, …).

## 2. Bridge

```sh
python tools/studio/mcp_bridge.py          # keep running (background)
python tools/studio/mcp.py tools           # list Studio tools
python tools/studio/open_place.py dist/NinjaDuel-Debug.rbxlx   # restart Studio on a place, Play, foreground
python tools/studio/mcp.py luau Server tools/studio/probes/ai_fight.luau
python tools/studio/mcp.py luau Client tools/studio/probes/snaps.luau 60
python tools/studio/mcp.py shot fight1     # viewport capture → %TEMP%/ninja-duel-shots
```

Keep **one** bridge alive: spawning `StudioMCP.exe` per call makes Studio drop and renegotiate its connection, so calls fail with “No Roblox Studio instances are connected”. Copy the place to a short path before opening it (Windows MAX_PATH). Long `execute_luau` calls must yield (`task.wait`).

## 3. Probes (debug build: they use `ServerStorage.NinjaDuelDev` and the inspector broadcast)

| Probe | Datamodel | Measures |
|---|---|---|
| `measure_movement.luau` | Server | standing/running/sprint jump apex, air time, horizontal speed before/after landing; run/sprint top speed and 90 % rise time |
| `smoothness_probe.luau` | Server | Codex's client probe (head/root acceleration spikes) while walking, sprinting and in an AI-vs-AI fight |
| `ai_fight.luau` | Server | (re)starts a duel, waits for the intro, places both fighters, AI drives both sides |
| `scenario.luau` | Server | scripted scenario started in the background (`rush`, `atk`, `jump`; edit `SCEN`) |
| `snaps.luau` | Client | per-frame discontinuities of camera, roots, torsos and feet (error vs. own recent velocity > 0.8 stud) and root yaw turns > 25°/frame, annotated with the inspector state |
| `flash_exposure.luau` | Client | dynamic light power and large-neon exposure per frame during a fight |
| `fps.luau` | Client | client render rate |
| `poses.luau` | Server | pose loops for visual comparison (`MODE`: idle, strafe, run, sprint, circle, circlerun, zigzag, retreat, jump, runjump, jab, combo, heavy, air, guard, tool); `circle`/`circlerun` lap the arena without any re-placement, so probes stay clean |
| `exchange.luau` | Server | one clean scripted exchange after `DELAY` (`SCEN`: string, launch, heavy, guarded), bot frozen but reacting |
| `film_record.luau` | Client | records every rendered frame of both fighters' parts (poses, no VFX) for `DUR` s into `shared.NdFilm`, with the inspector's combat state |
| `film_show.luau` | Client | chronophotograph: `COUNT` instants between `FROM` and `TO` posed as frozen copies side by side (`COLS` per row), seen from the side; `film_clear.luau` restores |
| `film_distances.luau` / `film_labels.luau` | Client | per-frame root / torso / head / nearest-part distances between the fighters; state changes over the recording |
| `staged_moment.luau` | Server | `MODE="setup"` starts `A` vs `B` (bot frozen, tool-driven); otherwise `WHO` performs `MODE` (Attack, Heavy, Technique1…, Tool, Dodge) at `GAP` studs |
| `fx_freeze.luau` | Client | freeze-frame of an effect: waits for an object named `TARGET` under the effects folder, then after `DELAY` copies every visible effect and fighter part into a static `FrozenFX` folder and holds a side camera on it, so a 0.1 s effect can be captured; `TARGET="off"` restores |
| `double_tap.luau` / `seqrec.luau` | Client | real packets through the `Action` remote (anti-cheat included): two Attack presses `GAP` s apart; or record the light/route names the snapshots show for `DUR` s while `user_keyboard_input` / `user_mouse_input` (Studio MCP) play real keys and clicks |
| `projrec.luau` | Client | records the projectiles (kind and chakra infusion) and the human's states from the snapshots while real keys are played (Z + R chord, R, E) |
| `intentrec.luau` | Server | samples the human's route intent every frame (stick class, remembered push, combo count, gap, chain open) through the Debug-only `dev:Invoke("intent")` |
| `reengage.luau` | Server | chakra dash from 22 studs and launcher + chase for the four CORE4: state changes and distance to the target |
| `../input_matrix.py` (driver, not a probe) | — | real-input control matrix: stages each scenario on the server, records the human's moves from the client snapshots and plays real keys/clicks (`user_keyboard_input` / `user_mouse_input`): whiff then hit, early buffer, plain / toward / away strings, air route, dash into attack, jutsu cancel, blocked string |
| `side_camera.luau` | Client | analysis camera bound after the game camera (`VIEW` side/front/off, optional fixed `AXIS`): profile views of gait, jumps and strikes; Studio-only tool, never shipped |

`snaps.luau` also reports `…FootRel` (foot position in its own root frame, threshold 0.5 stud): the animation's own discontinuities, without the body's translation. `hot_push.py` writes sources into the Edit datamodel and restarts Play, so an animation change is checked in seconds without rebuilding or reopening the place (the shipped build still comes from `build.py`). `contact_sheet.py` tiles captures (`CROP=x0,y0,x1,y1`) for side-by-side comparison.

Rules: run client probes with Studio in the **foreground** (`open_place.py` does it; otherwise the client renders at ~15–20 fps and every metric is noise). A placement (`place`) inside a probe window is a deliberate teleport, not a defect. AI fights are random: compare averages of several runs, or scripted scenarios, never single fights.

## 4. Baselines recorded (2026-10-16, Minato vs Itachi, 56–60 fps)

| Metric | `3b50d8e` (before this session) | `f895158` |
|---|---|---|
| standing jump apex / air time | 19.6 studs / 0.53 s | 16.4 / 0.94 s |
| running jump speed before → after landing | 36 → 14 | 36 → 19 |
| sprint jump speed before → after landing | 69 → 20 | 69 → 50 |
| camera frames with a jump, AI fight | 1.8–4.5 % | 0.3–0.5 % |
| root jumps during 5 scripted rushes (frames > 0.6 stud off) | 1.1 %, up to 3–4 studs (pre-fix build `c3dcfb1`) | 0.4 % |

These are technical measurements on the exact debug artifact. They do not replace human acceptance of the feel.
