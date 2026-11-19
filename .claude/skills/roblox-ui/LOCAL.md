# roblox-ui local settings (Ninja Duel)

- Icons project folder: `games/ninja-duel/work/ui` (cloud, not committed). Ninja Duel's screens belong to the DESIGN discussion (DA v3, Mix-* mockups): it uses this skill's spec -> PNG mockup -> Luau builder and checker for ITS screens. Value: games/ninja-duel/work/ui
- CF_ACCOUNT_ID / CF_API_TOKEN: not set (Cloudflare is not reachable from cloud sessions; see roblox-3d-model LOCAL.md). No kanji icons for techniques; no emoji icons (SyphoDev's rule).
- ROBLOX_API_KEY: not used (uploads through the Studio MCP's `open_cloud_invoke`).
- Studio MCP server: `Roblox_Studio` (the official Studio MCP, reached through the Claude desktop app on François's Mac: tools `mcp__remote-devices__Roblox_Studio__*`). Fallback when it breaks: `robloxstudio-mcp` (third-party, tools `mcp__remote-devices__robloxstudio-mcp__*`), the same official + fallback pair SyphoDev runs. One Studio connection at a time; announce before taking the screen, never while another discussion uses Studio. Value: Roblox_Studio

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
