# Verification - 2026-09-27

**NOT READY FOR CREATOR STORE: native Studio release gate remains unexecuted.**

| Check | Result | Evidence |
| --- | --- | --- |
| All production, test and demo Luau syntax | PASS | Luau compiler, exit 0 |
| Two-point line and distance interpolation | PASS | Actual production Curve module via Luau CLI |
| Four-point and vertical/3D interpolation | PASS | Actual production Curve module via Luau CLI |
| Duplicate, invalid and nonfinite point rejection | PASS | Luau CLI |
| Binary reproducibility and exact embedded source | PASS | `tools/verify_release.py`, 5 production scripts |
| Commercial package excludes tests/demo/network code | PASS | Explicit class/source allowlist and forbidden-content checks |
| Final plugin UI workflow in Studio | NON TESTED | Earlier build loaded according to Studio log; full interaction not executed |
| Cable geometry, joints, collisions in Roblox engine | NON TESTED | Prepared in Studio Suite; not counted as passed |
| Repeat Model count/spacing/rotation/scale in engine | NON TESTED | Prepared in Suite |
| Preview causes no project mutation | NON TESTED | Engine and widget assertions prepared in Suite |
| Build and Regenerate native one-step Undo/Redo | NON TESTED | Native ChangeHistoryService tests prepared; not executed |
| Regeneration, source preservation and unrelated objects | NON TESTED | Prepared in Suite |
| Deleted controls and injected transaction rollback | NON TESTED | Prepared in Suite |
| Three finished demo scenes and actual Studio screenshots | NON TESTED | Original fixtures and Studio generator prepared; captures absent |

Studio 0.740.19.7400931 opened the isolated QA place and logged loading the initial CurveForge package. The automation then repeatedly returned `timeoutReached` / `noWindowsAvailable`. The old JointForge publication window's Save dialog could be read but not operated reliably. No Studio Suite PASS lines were observed. No results are inferred from compilation or the mere presence of a window.

## Resume native gate

1. Bring Studio to the foreground; save/close the old JointForge publication window.
2. Open `tests/CurveForge-QA.rbxlx` in **edit mode**, not Play.
3. Run `local q = game.ServerStorage.CurveForgeQA; require(q.Suite)(q.Modules)` in the Command Bar. Expect nine actual PASS groups and zero failures.
4. Run `local q = game.ServerStorage.CurveForgeQA; require(q.Demo)(q.Modules)` to create all three finished demo outputs using the production engine.
5. Exercise the installed final plugin: New Path, order confirmation, Preview, Build, Edit, Regenerate, Undo/Redo. Capture the three scenes described in `release/screenshots/README.md`.

Do not mark the native rows PASS or list this as a finished commercial release until those steps execute successfully.
