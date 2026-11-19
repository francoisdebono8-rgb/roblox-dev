# LOCAL.md for create-roblox-game (Ninja Duel)

`LOCAL.md` holds paths and tool locations only. No key or token value here, ever.

## Folders

- Games folder: the repository's `games/` folder (`ROBLOX_GAMES_HOME=<repo>/games`). Ninja Duel is an EXISTING game: its design contract is `games/ninja-duel/docs/active/` (VISION, CURRENT_STATE, MASTER_BACKLOG), not a new `design/game.json`.
- Skills folder: the repository's `.claude/skills` (`ROBLOX_SKILLS_DIR=<repo>/.claude/skills`).

## Tools (preflight.py checks these live)

- Blender: cloud sessions run `bash tools/syphodev/setup_cloud.sh` (Blender 5.2.3 as `bpy` + a `blender` command). On the Mac: Blender 5.2.3 LTS in /Applications, driven through the Blender MCP (`execute_blender_code_for_cli`).
- Rojo 7.6.1, Wally 0.3.2, Selene 0.29.0, StyLua 2.3.1, Lune 0.8.9 (+ Lune 0.11.1 for Ninja Duel's own tests): installed per cloud session by `tools/syphodev/setup_cloud.sh`. Ninja Duel's own gates are `build.py`, `tests/run.sh`, `tests/test_build_isolation.py`, `tools/check_project_docs.py`, `../../tools/check_architecture.py`.

## Roblox Studio MCP

- `Roblox_Studio` (the official Studio MCP, reached through the Claude desktop app on François's Mac: tools `mcp__remote-devices__Roblox_Studio__*`). Fallback when it breaks: `robloxstudio-mcp` (third-party, tools `mcp__remote-devices__robloxstudio-mcp__*`), the same official + fallback pair SyphoDev runs. One Studio connection at a time; announce before taking the screen, never while another discussion uses Studio.

## Accounts and keys (names only, never values)

- Open Cloud: NO key needed. The official Studio MCP's `open_cloud_invoke` uploads with Studio's own sign-in, limited to the scopes François grants in Studio > Assistant > MCP Permissions, from folders he approves there. (`ROBLOX_API_KEY` stays unset.)
- Kaggle: NOT USED (2026-10-19). Its terms ban this use; see roblox-3d-model.
- Place ids: never changed (Ninja Duel rule). The places are built by `games/ninja-duel/build.py`.

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
