# AccessForge 1.1.0 technical gate

Native status: **PASS**, executed by the main coordinator in Roblox Studio
0.740.19.7400003 on 2026-09-28 at 11:37:01 UTC. Exact-candidate suite: **55 PASS /
0 FAIL**, all **44 matrix rows PASS**, outer gate PASS. Sanitized evidence:
[native-v11-technical.txt](native-v11-technical.txt) and
[technical-1.1.0-results.json](technical-1.1.0-results.json).

Tested candidate SHA256:
`484faabbfa9f8b02717a537aeee46c87e26861b83f8a66adadade112a5d89959`.
The product agent collected and verified the log, without launching Studio or
installing global plugins. Existing V1 Suite/RESULTS remain historical evidence.

The candidate is `dist/AccessForge-v1.1.0.rbxm`. Its current SHA is in
`dist/candidate-1.1.0.json`. The public V1 binary must retain SHA256
`53655a01ca0bb2e05886cdc401fa38003430f4f10f7317854a93c646d9dff44c`.

## Build and run

From this worktree root:

```sh
python3 products/accessforge/tools/verify_candidate.py --rojo /private/tmp/jointforge-tools/rojo/rojo --build
python3 products/accessforge/tests/build_technical_gate.py --rojo /private/tmp/jointforge-tools/rojo/rojo --output-dir /private/tmp/AccessForge21QA
```

The first command reproducibly builds and verifies the production binary and
exactly five production sources. The second imports that exact binary and the
untouched V1 binary, verifies every Source, disables only their Main scripts in
the QA copies, and packages a separate opt-in runner. No loose source substitute
or injected production payload is used. A second binary import verifies the QA
package, both disabled Main scripts and the single enabled Runner.

The coordinator runs `AccessForgeTechnicalGate.rbxm` only in the generated empty
local `AccessForge21QA.rbxl`, Edit mode, PlaceId 0, with Workspace attribute
`AccessForgeTechnicalGate=true`. The runner refuses populated fixtures. It records
the exact candidate and V1 SHA, per-case assertions, all matrix rows and a final
summary. Native history tests call SetWaypoint after fixture setup and before
recording, then assert the same old/new Instances across Undo and Redo.

Failure injection lives exclusively in the QA suite: fake history objects and
temporary function environments exercise native setters on real Instances. The
candidate Sources remain unchanged. No test hook ships in the product.

After a successful native run:

```sh
python3 products/accessforge/tests/collect_technical_evidence.py /absolute/path/to/versioned_Studio_last.log
```

The collector accepts only the most recent run matching the current candidate
and V1 SHA, final gate PASS, zero failed cases and all 44 matrix rows PASS. It
writes sanitized `native-v11-technical.txt` and `technical-1.1.0-results.json`.
Rebuilding a changed candidate invalidates earlier native evidence.

## Matrix

| # | Gate | Native status |
|---|---|---|
| 1 | V1 Straight load | PASS |
| 2 | V1 Switchback load | PASS |
| 3 | V1 Catwalk load | PASS |
| 4 | V1 automatic migration | PASS |
| 5 | Straight exact endpoint fit | PASS |
| 6 | Straight shallow rise | PASS |
| 7 | Straight long run | PASS |
| 8 | Switchback odd steps | PASS |
| 9 | Switchback even steps | PASS |
| 10 | Switchback Left across quadrants | PASS |
| 11 | Switchback Right across quadrants | PASS |
| 12 | Catwalk exact level | PASS |
| 13 | Catwalk tolerance boundary | PASS |
| 14 | Non-level Catwalk refuses | PASS |
| 15 | Top landing | PASS |
| 16 | No landing | PASS |
| 17 | Left/right rails | PASS |
| 18 | Midrail on/off | PASS |
| 19 | Round/square rails | PASS |
| 20 | Supports on/off | PASS |
| 21 | Floor validation | PASS |
| 22 | 256 steps accepted, 257 refused | PASS |
| 23 | 1000 Parts accepted, 1001 refused | PASS |
| 24 | Invalid/degenerate preflight | PASS |
| 25 | Deterministic immutable one-use planner | PASS |
| 26 | Marker movement stales | PASS |
| 27 | Marker reparent/delete/ancestor change stales | PASS |
| 28 | Settings/mode mutation stales | PASS |
| 29 | Owned Part edits stale | PASS |
| 30 | Metadata/output/registry corruption refuses | PASS |
| 31 | Unrelated Workspace change stays fresh | PASS |
| 32 | All user siblings preserved | PASS |
| 33 | Owned-Part user child refuses | PASS |
| 34 | Recording refusal writes nothing | PASS |
| 35 | Recording-open mutation caught | PASS |
| 36 | Mid-regenerate failure rollback | PASS |
| 37 | Commit failure rollback | PASS |
| 38 | Build native Undo/Redo | PASS |
| 39 | Regenerate native Undo/Redo with same identities | PASS |
| 40 | New Markers Undo/Redo and cleanup | PASS |
| 41 | Large coordinates/near axes | PASS |
| 42 | Successful native paths without runtime exception | PASS |
| 43 | Exact artifact/source correspondence | PASS |
| 44 | No network/telemetry/runtime payload | PASS |

Offline verification: Luau compilation and exact-source reproducible packaging
PASS. Rows 43/44 also passed in the imported-binary native gate. Optional orientation and
environment obstruction diagnostics are explicitly deferred in the technical
design document.

## Harness audit

The initial 11:32:49 UTC run on candidate
`0cffbb9a23c4260210a44f19e53b1a56b135224e68234a9c6cbf5b7af6668600`
reported 45 PASS / 5 FAIL. All five failures were in the QA helper: `plan()`
returns both a plan and mutable input settings; nested `apply(plan())` mistakenly
treated the second return as an optional engine. Production failures were not
observed. The helper now accepts only the plan; legacy calls use their explicit
engine. The failure tests also expanded to six distinct parent-write positions.
The version label then changed from 1.0 to 1.1, producing the final candidate
above, which was fully rerun. The earlier run is not final-candidate evidence.
