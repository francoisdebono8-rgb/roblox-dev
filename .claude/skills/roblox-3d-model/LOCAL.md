# LOCAL.md for roblox-3d-model (Ninja Duel)

`LOCAL.md` holds paths and tool locations only. No key or token value here, ever.

## Tools

- BLENDER (env var): cloud = `blender` on PATH after `bash tools/syphodev/setup_cloud.sh` (Blender 5.2.3 bpy, CPU: fine for decimate/UV/bake, slow for EEVEE renders). Mac = Blender 5.2.3 LTS, through the Blender MCP.
  Value: blender
- KILN_HOME (env var): not set up yet (hard-surface route). Node 22 is in the cloud sessions.
  Value:
- Work folder: cloud `games/ninja-duel/work/models` (not committed); keepers go to the Mac `~/Documents/NinjaDuel/BLENDER/models/` through the device folder.
  Value: games/ninja-duel/work/models
- Studio MCP server name: `Roblox_Studio` (the official Studio MCP, reached through the Claude desktop app on François's Mac: tools `mcp__remote-devices__Roblox_Studio__*`). Fallback when it breaks: `robloxstudio-mcp` (third-party, tools `mcp__remote-devices__robloxstudio-mcp__*`), the same official + fallback pair SyphoDev runs. One Studio connection at a time; announce before taking the screen, never while another discussion uses Studio.
  Value: Roblox_Studio

## Credentials (env var NAMES only)

- HF_TOKEN: not set. NOTE the network: cloud sessions and the device sandbox cannot reach huggingface.co or api.cloudflare.com (allow-list). Only processes on the Mac itself (Blender started by the Blender MCP) can, so the Hi3DGen / Flux steps run there once François has made the free accounts and set the variables on the Mac (`launchctl setenv HF_TOKEN ...` then restart the Claude app; he types it, never in a chat). Set: no
- CF_ACCOUNT_ID, CF_API_TOKEN: same as above. Set: no
- Kaggle: NOT USED. Leave it unset.
- ROBLOX_API_KEY: not used; uploads go through the Studio MCP's `open_cloud_invoke` (see create-roblox-game LOCAL.md). Set: no
- ROBLOX_USER_ID or ROBLOX_GROUP_ID: read from Studio (`open_cloud_invoke` GET) when an upload is approved. Set: no
- POLLINATIONS_TOKEN: Set: no

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
