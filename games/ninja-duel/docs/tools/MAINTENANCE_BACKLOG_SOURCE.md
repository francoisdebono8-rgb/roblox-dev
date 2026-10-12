# Codex maintenance tasks — support work only

Use Codex for repo/build/maintenance work that should make future gameplay iteration faster. Do not give Codex ownership of visual/game-feel direction unless explicitly asked.

## Priority tasks

1. **Repository cleanup**
   - audit `games/ninja-duel` for obsolete files, duplicated docs, stale build artifacts and dead experimental code;
   - do not delete anything still referenced by build/runtime/tests;
   - produce a compact `PROJECT_STRUCTURE.md` explaining where gameplay, presentation, characters, arena, tests and builds live.

2. **Folder organization**
   - make character-specific data easy to find and extend;
   - separate generic combat systems from fighter-specific moves/FX/presentation where safe;
   - keep current runtime behavior identical while moving files;
   - update all imports/references and tests after moves.

3. **One-command build/test**
   - create or improve a single command/script that runs automated tests, rebuilds `../../dist/NinjaDuel.rbxlx` and reports success/failure clearly;
   - fail loudly if the artifact is stale relative to sources.

4. **Build provenance**
   - generate a small manifest containing version, commit SHA, build timestamp, test result and artifact hash;
   - make it obvious which source commit produced the `.rbxlx` being tested.

5. **Regression test coverage**
   Add headless tests for:
   - combo state cleanup;
   - substitution during juggle/pin/grab;
   - wall splat/bounce/tech state exits;
   - teleport/seal lifecycle;
   - aerial recovery and landing;
   - KO -> result -> rematch -> character switch;
   - all three characters loading valid move graphs.

6. **Performance instrumentation**
   - add lightweight diagnostics for snapshot cadence, interpolation buffer, visual position error, dropped/late updates and camera correction magnitude;
   - Studio/debug only; zero or negligible live overhead.

7. **Public-build helper docs**
   - document the shortest Mac/PC workflow for opening the latest GitHub `.rbxlx`;
   - if Roblox publishing automation is not safely available, document exact Studio publish steps instead of inventing automation.

## Constraints
- Preserve gameplay behavior while doing maintenance.
- Small commits with clear names.
- No broad rewrites.
- Never replace working Claude gameplay/presentation work with generic abstractions just for cleanliness.
- Run tests after every structural change.
