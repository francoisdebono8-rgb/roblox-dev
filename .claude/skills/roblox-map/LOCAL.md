# roblox-map local settings (Ninja Duel)

- Python: python3 with numpy, scipy, Pillow (cloud: `bash tools/syphodev/setup_cloud.sh`). Value: python3
- Studio MCP server: `Roblox_Studio` (the official Studio MCP, reached through the Claude desktop app on François's Mac: tools `mcp__remote-devices__Roblox_Studio__*`). Fallback when it breaks: `robloxstudio-mcp` (third-party, tools `mcp__remote-devices__robloxstudio-mcp__*`), the same official + fallback pair SyphoDev runs. One Studio connection at a time; announce before taking the screen, never while another discussion uses Studio. Value: Roblox_Studio
- Map work folder: `games/ninja-duel/work/map` (not committed). The village itself is `src/Shared/HubMap.luau` + `src/Server/Hub.luau`; the movement profile comes from the game's real numbers (`Hub.WALK, Hub.RUN, Hub.JUMP, Hub.LEAP`, `Shared/Config`), each labelled with its source. Value: games/ninja-duel/work/map
- Asset ids file (optional): not yet. Value:
- serve_map port (optional): 8787 (only when Studio and the server run on the same machine). Value: 8787
- ROBLOX_API_KEY: not used (uploads through the Studio MCP's `open_cloud_invoke`).

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
