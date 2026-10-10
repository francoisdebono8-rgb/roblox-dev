# Adding a prodigy — fighter template

How a new fighter goes from `ROSTER_MOVESETS_10_PRODIGIES.md` to a playable prototype. The six layers of the
blueprint (taijutsu, movement, tools, techniques, signature mechanic, awakening) each have one home in the code.
Sasuke (`Lion`) was built this way in one pass; Gaara (`Sand`) is server-complete and waiting for his client layer.

| Layer | Where | What to write |
|---|---|---|
| Identity & stats | `src/Shared/Fighters.luau` | `Name`, `FullName`, `Age`, `Title`, `Color`, `Description`, `Routes` (one line shown on select), health/chakra/speed scales, `PreferredRange` (AI spacing) |
| Taijutsu timing | `Fighters.<id>.AttackProfile` | per-move multipliers: `startup`, `recovery`, `travel`, `range`, `depth`/`offset`/`width` (hitbox), `damage` (scale), `impulseY/Z` |
| Combo grammar | `src/Shared/MoveGraphs.luau` | `routes = {up, down, side, airUp, airDown, airSide}` → attack names; `heavyAfterOne`; `disengage` (tool kind); `onRoute[name]` payoff kind; `stringCancels` (jutsu allowed out of a clean string); `blockCancels`; `readCounter` |
| New strikes | `src/Shared/Attacks.luau` | `move(startup, active, recovery, damage, travel, reaction, impulse, stun)` + motion entry + `ZONE` / `KIND` (drives the victim's reaction) + hitbox fields; `orbit` for side-switching routes; `chain=true` if the string continues |
| Route payoffs | `Brawler.routePayoff` | one `kind` branch (examples: `bodySeal`, `floorSeal`, `coverBlades`, `tenketsu`, `shadowLeaf`) |
| Ninja tools | `Fighters.<id>.ToolMastery` | `Kind` (kunai/shuriken), `Count`, `Speed`, `Damage`, `Recover`; mastery flags (`Geometry`, `Ricochet`, `AirSpread`) |
| Techniques | `Fighters.<id>.Techniques` + `src/Server/Techniques.luau` | up to five specs (`Cost`, `Channel`, `Active`, `Recovery`, `Cooldown`, `Range`, …); an `execute(c, a, pending)` per `Id` (reuse an existing Id to reuse its implementation) |
| Signature / passive | Combat / Brawler hook | keep it data-driven when possible (`Sharingan`, `Byakugan`, `GentleFist`, `SandShield`, `SandFlicker` are examples) |
| Awakening | `Fighters.<id>.Awakening` | `Name`, `Speed`, `Damage`, `Regen`, `Cooldown`, optional `CostScale`, `Windows`, `NoBlindSpot`, `HealthDrain`, `ShieldRegen` |
| Body: stance & gait | `src/Client/VelmoraMotionEngine.luau` | `STANCE.<id>`, `GAIT.<id>` (stride, cadence, arm swing, lean, bob, guard), `SPRINGY` |
| Body: clips | same file | `CLIPS.<id>.<Attack>` keys on the 0–3 timeline (0 start, 1 contact, 2 end of active, 3 back in stance); a metatable fallback to an existing fighter covers what is not authored yet; mark spins `keep` (exact angles, keys < 180° apart) |
| Technique poses | `castSpec` | channel and release pose per technique `Id` |
| Costume | `src/Server/World.luau` | `dress<Name>(model, def)` with `wear`, `spike`, `hairCap`, `headband`, `face`, `crest`; hidden parts toggled by effects (Byakugan veins, curse marks) |
| Effects | `src/Client/Effects.luau` | colour tone, signature visuals in `FX:fighter`, impact styles in `FX:impact`, projectile builders in `BUILD` |
| Camera | `src/Client/Camera.luau` | `IMPULSE[style]` for any new impact style |
| UI | `src/Client/UI.luau` | add the id to `playable` |
| AI | `src/Server/AI.luau` | one `use=` rule per technique id; anything special in the string block |
| Tests | `tests/<Name>.spec.luau` | one test per signature move + an AI duel against every fighter; register in `tests/run.sh` and `build.py` |

Checklist before shipping a prototype:
1. `bash tests/run.sh` green; `lune run tests/Balance.sim.luau` gives every fighter between ~35 and ~65 % wins.
2. Studio: `replay.sh <id> <opponent>`, film the string, each route, each technique (side film camera).
3. Studio sweep (`sweep.lua`) with the new id in `ids`: 0 errors, 0 stuck states.
