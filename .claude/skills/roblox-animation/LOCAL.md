# LOCAL.md for roblox-animation (Ninja Duel)

- Path to your R15 rig .blend: NONE needed for Ninja Duel. The fighter is the game's own R15 skeleton of boxes (Server/World.RIG), so the clips use the skill's JOINT-SPACE route (r6_clip.py, "custom rig with no .blend"): `games/ninja-duel/tools/syphodev/rig_dump.luau` writes rig.json, `make_parts.py` the real box parts, `to_authored.py` turns resolved.json into AuthoredClips rows. See `games/ninja-duel/tools/syphodev/README.md`.
  (The community R15 rig of the video, MrXeno's free Gumroad rig, is only needed for the FK route with anim_render.py; François downloads it himself if he wants that route.)
  Value: games/ninja-duel/tools/syphodev (joint-space)
- Path to R6 rig .blend (optional): not used.
  Value:
- Blender executable: cloud `blender` (tools/syphodev/setup_cloud.sh; EEVEE is software there, about 20 s a frame, so use `--no-render` for the numbers and render on the Mac). Mac: Blender 5.2.3 LTS (/Applications/Blender.app), started through the Blender MCP: a preview pass there takes seconds, as in the video.
  Value: blender
- ffmpeg on PATH: yes in cloud sessions (/usr/local/bin/ffmpeg) and in the device sandbox (/usr/bin/ffmpeg).
  Value: ffmpeg
- Studio MCP server name: `Roblox_Studio` (the official Studio MCP, reached through the Claude desktop app on François's Mac: tools `mcp__remote-devices__Roblox_Studio__*`). Fallback when it breaks: `robloxstudio-mcp` (third-party, tools `mcp__remote-devices__robloxstudio-mcp__*`), the same official + fallback pair SyphoDev runs. One Studio connection at a time; announce before taking the screen, never while another discussion uses Studio.
  Value: Roblox_Studio

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
