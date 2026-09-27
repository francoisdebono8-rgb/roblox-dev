# Verification - 2026-09-27, issue #12

**NATIVE / GUI / MEDIA GATES PASS. Studio asset submission has not yet completed.**

| Check | Result | Evidence |
| --- | --- | --- |
| All production, test and demo Luau syntax | PASS | Luau compiler, exit 0 |
| Two-point line and distance interpolation | PASS | Actual production Curve module via Luau CLI |
| Four-point and vertical/3D interpolation | PASS | Actual production Curve module via Luau CLI |
| Duplicate, invalid and nonfinite point rejection | PASS | Luau CLI |
| Binary reproducibility and exact embedded source | PASS | `tools/verify_release.py`, 5 production scripts |
| Commercial package excludes tests/demo/network code | PASS | Explicit class/source allowlist and forbidden-content checks |
| GUI New Path, selected points, explicit order and confirmation | PASS | Real clicks in RavenRock, four displayed controls |
| GUI Cable Preview and Build | PASS | Read-only assertions, visible successful output; `docs/forge-catalog-gui-run.txt` |
| GUI Cable Build native Edit Undo/Redo | PASS | Actual menus, removed output/count check, rebuilt and immediate Undo/Redo round trip |
| GUI Edit Existing and moved-point Preview | PASS | Loaded actual output; moving Point02 did not mutate existing cable |
| GUI Cable Regenerate and native Edit Undo/Redo | PASS | Changed order and moved control applied; environment and settings checked |
| GUI Pipe Preview and Build | PASS | Four 3D controls, read-only Preview, actual yellow output |
| GUI Repeat spacing/count Preview, Build, Edit Existing, Regenerate | PASS | 12 then 14 two-part copies; Preview, source and environment assertions |
| GUI Repeat native Edit Undo/Redo | PASS | Immediate actual menu round trip, then 14-copy/source assertions |
| Final installed plugin opens its actual panel | PASS | Native Plugins > CurveForge action and actual subsequent widget clicks |
| Cable geometry, joints, collisions in Roblox engine | PASS | Actual native suite, 01:01:11 UTC |
| Repeat Model count/spacing/rotation/scale in engine | PASS | Actual native suite |
| Preview causes no project mutation | PASS | Engine and widget assertions executed |
| Build and Regenerate native one-step Undo/Redo | PASS | Actual ChangeHistoryService Undo/Redo assertions |
| Regeneration, source preservation and unrelated objects | PASS | Actual native suite |
| Deleted controls and injected transaction rollback | PASS | Actual native suite |
| New Path marker engine operation | PASS | Native suite, including Undo |
| Plugin exceptions during native test window | PASS | No CurveForge exception in scoped Output log |
| Village cable commercial screenshot | PASS | `release/screenshots/01-village-cable.png`, genuine Studio capture |
| Pipe and Repeat Model screenshots | PASS | `02-village-pipe.png`, `03-village-repeat.png`; genuine reviewed captures |
| Studio asset publication | NON TESTED | Gates complete; native submission still pending |

Studio **0.740.19.7400931**, edit mode. First native run: **00:43:28 UTC**, 9 passed / 0 failed. Rerun from the final binary through the isolated catalog runner: **01:01:11 UTC**, again **9 passed / 0 failed**. See [sanitized actual log](../../../docs/forge-catalog-native-run.txt).

The runner imports the final commercial binary. Only its entry Script is disabled inside the QA copy to avoid duplicate toolbars; all module code is unchanged. The installed commercial plugin remains separate. Native suite results do not establish GUI click coverage; the subsequent actual GUI assertions are recorded separately in [forge-catalog-gui-run.txt](../../../docs/forge-catalog-gui-run.txt).

Artifact: `dist/CurveForge-v1.0.0.rbxm`, SHA-256 `476ee0fc81f9080130fe8b6914bac8e37a9a1021b71df93f7b87168ee164162b`.

## Publication handoff

The final working scene is `release/scene/CurveForge-Scenes.rbxl`. It contains the cable, pipe, 14 repeated lamps, controls and original two-part source. All required CurveForge UI workflows and all three captures are complete. Only the clean commercial model in `release/CurveForge-Publication.rbxl` may be submitted, never this media scene.

Native GUI automation intermittently loses window access. Temporary invalid numeric strings caused by keyboard automation were correctly rejected and recovered with valid values; Ctrl+A was not a reliable selection shortcut on this Mac. No product bug was inferred. No failed click is counted as a passed workflow. No screenshot has been fabricated.
