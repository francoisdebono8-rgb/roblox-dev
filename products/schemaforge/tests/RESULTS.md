# SchemaForge 1.0.0 release gate

Historical 1.0.0 evidence only. Current production sources have since changed for
issue #17; see [the 1.1.0 gate](../v2/RELEASE_GATE.md). The manifest now describes 1.1.0.

2026-09-27, macOS, Studio 0.740.19.7400003, Edit mode.

Exact commercial SHA-256: `d6b29c5b9f76db7d96e4ac828e4eb2f56152c66c8e6e98c67ac598d383b99a2f`.
At that historical run, installed binary, tested modules and publication input matched.

| Gate | Result | Actual evidence |
| --- | --- | --- |
| Final binary modules in Studio | PASS | 23 test groups, 0 failures; [native-run.txt](native-run.txt) |
| Real plugin entry and GUI | PASS | Installed binary toolbar/DockWidget; capture, name, save, load, edit numeric bounds/integer/default/notes, required child path and delete confirmation clicked |
| Selection and Workspace | PASS | One reference: 1 checked / 1 valid. Workspace: 8 checked / 3 valid / 6 findings; 5 unique affected objects selected |
| Read-only capture/audit/preview | PASS | Native snapshots; GUI missing attributes still absent before Apply |
| GUI Apply scope | PASS | Exactly two missing Cost attributes set to 25. Every existing scene attribute, name, parent and BasePart CFrame compared unchanged |
| Native Undo/Redo | PASS | Native tests for Apply/save/edit/delete; GUI Edit > Undo produced nil/nil and Redo 25/25 for the two repaired attributes |
| Invalid/stale data and rollback | PASS | Native invalid schema/default/bounds/type, stale value/tag/parent/scope, name collision, duplicate child and malformed storage checks; two recording failure tests use injected history faults |
| Project persistence | PASS | Typed JSON save/load/edit/delete in engine and real GUI library. Place saved to disk with one canonical demo schema. Fresh Studio reopen of that media file is not separately claimed |
| Package/source cleanliness | PASS | Reproducible byte equality, five exact source texts, production-only tree; no QA/demo/network requests/dependencies |
| Commercial media | PASS | Three real Studio captures, pixel crop only; official Plant scene with recorded MIT license |
| Studio publication | PASS | Successfully submitted once; canonical asset 84085408748744 |

[GUI assertion evidence](gui-run.txt). No SchemaForge production exception was observed. Studio itself logged ExplorerPlugin selection-sync errors and startup/internal warnings; this is not a claim of globally empty Studio logs.

Earlier harness runs failed because fixture changes were not isolated from Undo history. The harness now records a fixture baseline and waits after native Undo/Redo; the fresh final run passed all 23 groups. No product behavior was weakened to make those tests pass.

Not claimed: exhaustive load/performance testing, Team Create concurrent sessions, all future Studio versions, runtime/server enforcement. Small-dock mount/dispose is tested; long rule forms scroll, and rerender may return the form to its top.

## Reproduce

For 1.1.0, run `python3 tests/build_final_gate.py --rojo /path/to/rojo` from the product directory. It packages an opt-in QA plugin containing the exact final binary and a separate empty QA place. Install the QA plugin, open the generated empty place in Edit mode, and inspect `[SchemaForgeFinalGate]` Output. Remove the QA plugin afterward. Never publish a QA/media place as the commercial plugin.

`--restart-check` instead packages the read-only existing greenhouse contract check
and copies the licensed saved media place. Open that copy in a fresh Studio process;
inspect `[SchemaForgeRestart]`. It does not simulate a Library click or claim that a
new GUI edit was saved/reopened. `tools/collect_v11_evidence.py` verifies the current
artifact hash before extracting product-only evidence (also accepts `--restart-check`).
