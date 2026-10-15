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
