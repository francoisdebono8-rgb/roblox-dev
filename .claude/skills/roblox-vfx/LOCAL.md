# roblox-vfx local settings (Ninja Duel)

- ROBLOX_VFX_LIB: `~/Roblox-VFX-Library` in a cloud session (rebuilt per session) and the Mac `~/Documents/NinjaDuel/LAB/vfx-library` to keep harvested recipes between sessions (copied through the device folder). Value: ~/Roblox-VFX-Library
- Studio bridge: `Roblox_Studio` (the official Studio MCP, reached through the Claude desktop app on François's Mac: tools `mcp__remote-devices__Roblox_Studio__*`). Fallback when it breaks: `robloxstudio-mcp` (third-party, tools `mcp__remote-devices__robloxstudio-mcp__*`), the same official + fallback pair SyphoDev runs. One Studio connection at a time; announce before taking the screen, never while another discussion uses Studio. Value: Roblox_Studio
- Sink port: 48752 (recipe_server.py; only when it runs on the Mac next to Studio. From a cloud session, harvested recipes come back through `execute_luau` output instead). Value: 48752
- Studio window: maximised and in the foreground for screenshots, AFTER announcing it to François.
- Blender: `blender` (cloud, tools/syphodev/setup_cloud.sh) or Blender 5.2.3 on the Mac. Value: blender
- Lune folder: any folder whose `rokit.toml`/`aftman.toml` lists Lune; in the cloud `~/tools/lune-0.10.5/lune` (setup_cloud.sh). Value: ~/tools
- VFX research folder: `games/ninja-duel/work/vfx-research` (not committed). Value: games/ninja-duel/work/vfx-research
- Open Cloud key: not used (uploads through the Studio MCP's `open_cloud_invoke`). Value:
- Texture library and meshes: build once per cloud session with the First run commands. Value: built 2026-11-19 (cloud session), rebuild in a new session
- Ninja Duel's FX belong to the ANIMATEUR (RUNBOOK 3 quater): `src/Client/*FX*`, `tools/blender/fx_*.py`.

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
