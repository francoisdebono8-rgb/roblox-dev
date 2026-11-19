# LOCAL.md for roblox-code (Ninja Duel)

Rojo 7.6.1, Wally 0.3.2, Selene 0.29.0, StyLua 2.3.1 and Lune 0.8.9 come from `bash tools/syphodev/setup_cloud.sh`. In a scaffold, put `~/tools/lune-0.8.9` first on PATH (the scaffold pins it) and write Selene's Roblox std with `python3 tools/syphodev/selene_roblox_std.py <project>` (Selene cannot download it through the proxy).

Ninja Duel itself is not a Knit project: its four gates are `python3 build.py` (with "", --debug, --qa, --capture), `LUNE=~/tools/lune-0.10.5/lune bash tests/run.sh` (exactly Lune 0.10.5), `python3 tests/test_build_isolation.py` and the docs/architecture checks. The skill's rules apply as written: code lives in files, tunables in Config, pure rules tested headless, one remotes file, traps written down.

## My preferences

- Ninja Duel (repo `games/ninja-duel`). Read `docs/tools/METHODE_SYPHODEV.md` first: it maps this skill onto the game, the four discussions and their files.
- Each discussion adds its OWN files to the game (RUNBOOK 3 quinquies): animation, FX and Blender belong to ANIMATEUR, screens to DESIGN, engine/systems to DEV.
- No Roblox LIVE publication, no PlaceID/UniverseID change, no asset upload without François's explicit OK in the conversation.
- Look up the real Naruto reference before modelling a prop or decor; no kanji icons for techniques.
- Every fix the user asks for and that works is written down in this skill's traps/references with its reason (SyphoDev: "ask it to remember the fix").
