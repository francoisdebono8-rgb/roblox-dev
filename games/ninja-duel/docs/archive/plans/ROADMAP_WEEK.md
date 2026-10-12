# Ninja Duel — one-week finishing plan

State at the start of the week (`0.13.0-arena-combo`): four playable prodigies (Minato, Itachi, Neji, Sasuke),
Gaara server-complete, a large stadium, a shared directional combo grammar, zone-based hit reactions, shared
ninja tools with per-fighter mastery, rounds, awakenings, substitutions, wall/air play, AI for every matchup,
131 headless tests and a 16-matchup Studio sweep. What is left to call it a finished game, in order of value.

## Day 1 — done (this pass)
Arena scale and long-range play; directional combo grammar (launch / low / side / air drive / spike / switch,
hop-out); reactions by zone and kind; shared tools (Itachi's Shuriken Geometry, ricochets, air fan); Sasuke;
Chidori, Wire Trap → Dragon Flame, Lion Combo; balance sim; floor-ray bug in effects.

## Day 2 — fifth fighter: Gaara's client layer
Server and tests exist (`Sand`, hidden). Needed: costume (red hair, 愛 mark, dark rings, gourd), stance (arms
crossed, still), sand effects (shield block, pillar, coffin wave and burial, desert wave, sand flicker, bullet),
clips (short arm commands; the sand does the work), AI ranges, balance (the AI sim had him at 96 % before the
lash nerf — re-run `../../../tests/Balance.sim.luau` and target 40–60 %), then add `"Sand"` to `playable`.

## Day 3 — two players
The duel is player vs AI. Matches already runs two actors through one combat core, so PvP is an input
change: a lobby pad (two players stand on it), the second player's input drives the second actor instead
of `AI:update`, both cameras use the same rig from their own side. Add client-side prediction for the local
player's own movement (input currently lags by the ping) and server reconciliation on `warpSerial`.

## Day 4 — sound and presentation
- Audio pass: hit sounds by kind (punch / kick / palm / sweep / slam), whooshes by weight, jutsu cues (fire,
  lightning chirp, wire), crowd reacting to big moments (the cheer hook exists), round / K.O. stingers.
- Victory poses and one line per fighter on the result screen; move list on the pause / select screen (the
  `Routes` line is the seed).
- Tutorial: teach the grammar (toward / away / side after two hits, air routes, hop-out, Shuriken Geometry).

## Day 5 — controls on every device
Mobile touch layout (stick, light, heavy, jump, dodge, tool, jutsu wheel), controller check on Mac and PC,
key rebinding screen, camera sensitivity. Verify the HUD at phone width.

## Day 6 — performance and robustness
Part budget of the stadium (spectators are ~1,300 parts: instance them per tier or bake), effect pooling,
`Debris` audit, memory over ten rematches, 30-player server with several lanes (lane spacing is 520 studs),
reconnect mid-match, the anti-cheat rate limits under two-player input.

## Day 7 — balance and release
`Balance.sim` matrix with 8 seeds per pair, then playtests; tune damage scaling and recoveries, not identities.
Bug bash with `sweep.lua`; rebuild `../../../dist` and the QA artifact; publish from your Studio session
(`../../tools/PUBLIC_BUILD.md`; publishing is your action on your account).

## After the week — the rest of the ten
Rock Lee first (pure taijutsu stress test for the grammar), then Naruto (clone routes), Kakashi (adaptation),
Shisui (afterimage choice), Orochimaru (unnatural reach). Each follows `../../characters/FIGHTER_TEMPLATE.md`: data, move
graph, clips, costume, effects, AI, tests, sweep.
