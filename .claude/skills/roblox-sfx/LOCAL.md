# roblox-sfx local settings (Ninja Duel)

No key, no upload: Creator Store sounds by asset id, proven in Studio (IsLoaded + measured TimeLength).
- Studio MCP server: `Roblox_Studio` (the official Studio MCP, reached through the Claude desktop app on François's Mac: tools `mcp__remote-devices__Roblox_Studio__*`). Fallback when it breaks: `robloxstudio-mcp` (third-party, tools `mcp__remote-devices__robloxstudio-mcp__*`), the same official + fallback pair SyphoDev runs. One Studio connection at a time; announce before taking the screen, never while another discussion uses Studio. Value: Roblox_Studio
- Network: the toolbox search endpoints are not reachable from cloud sessions; search through the Studio MCP (`search_asset`, or `http_get` / `execute_luau` in Studio).

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
