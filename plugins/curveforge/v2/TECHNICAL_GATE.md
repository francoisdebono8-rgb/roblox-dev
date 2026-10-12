# CurveForge 1.1.0 technical gate

Issue #18, 2026-09-27 23:25 UTC (2026-09-28 Paris), native Studio
**0.740.19.7400003**, Edit mode. **PASS: local technical candidate only.**
**DO NOT PUBLISH** in this phase. Canonical **90642263224333** and public 1.0.0
were not changed. No media, listing, outreach or visual redesign performed.

Artifact: `../dist/CurveForge-v1.1.0.rbxm`.
SHA256: `947d71793699215d88548931256cb022b68ff1f62167e1613cc79e17b4f7c71c`.
Five production sources, byte-for-byte reproducible; no tests/demo/network/private
paths in the artifact. Historical 1.0.0 binary is retained unchanged, SHA256
`476ee0fc81f9080130fe8b6914bac8e37a9a1021b71df93f7b87168ee164162b`.

## Actual execution

- **9 V1 regression groups PASS / 0 FAIL**, exact candidate modules in Studio.
- **42 technical groups PASS / 0 FAIL**, including actual native history and actual
  old-binary Cable/Repeat creation followed by candidate migration/regeneration.
- **3 pure-math CLI groups PASS**; not presented as a replacement for Studio.
- Production/QA Luau compilation and exact source/binary/package checks PASS.
- [Sanitized native evidence](../tests/native-v11-technical.txt): timestamps, both
  artifact hashes, each actual result and measured values. No whole Studio log is
  committed. Log identity: `0.740.19.7400003_20260927T232504Z_Studio_8ae68_last.log`.

The separate opt-in QA package imports the final `.rbxm` and historical V1 `.rbxm`,
verifies embedded Sources, and disables their entry scripts only inside the harness.
The commercial artifact is not instrumented. Real Roblox Instances, CFrames, cloning,
metadata and ChangeHistoryService are exercised. Failure injection is used only for
recording refusal/throw/rollback paths. Temporary QA plugin is removed after testing;
the installed public V1 plugin is not replaced by this task.

## Issue #18 matrix

| # | Required check | Result / executed evidence |
|---|---|---|
| 1 | Two-point straight | PASS, endpoints/length/frames and cable |
| 2 | Four-point horizontal S | PASS, frame continuity and cable |
| 3 | Vertical path | PASS, pure vertical and vertical-to-horizontal |
| 4 | Alternating 3D path | PASS, six-control spatial fixture |
| 5 | Near-vertical continuity | PASS, old 0.98-threshold crossing |
| 6 | No abrupt orientation flip | PASS, 800 consecutive frames/fixture and half-turn guide interpolation |
| 7 | Roll off compatibility | PASS, planar reference/source offsets; rotations ignored; intentional 3D frame correction documented |
| 8 | Roll on smooth twist | PASS, endpoints, midpoint, half-turn, parallel-guide fallback, unchanged positions |
| 9 | Adaptive straight | PASS, 2 samples instead of 65 |
| 10 | Adaptive tight bend | PASS, independent dense-reference comparison |
| 11 | Adaptive long gentle curve | PASS, 5400.98-stud reference fixture |
| 12 | Deterministic samples/length | PASS, repeated exact results; eight controls and large-coordinate fixture |
| 13 | Cable straight continuity | PASS, cylinder endpoints/shared-joint tolerances |
| 14 | Cable tight bend continuity | PASS, S and short tight fixtures |
| 15 | Cable steep 3D continuity | PASS, vertical and spatial fixtures |
| 16 | Diameter extremes | PASS, 0.05 and 50; 0.1 segment setting |
| 17 | Repeat Count | PASS, exact counts with Model sources |
| 18 | Repeat Spacing uniformity | PASS, actual 3D clone pivots projected onto independent dense-reference arc |
| 19 | Endpoints on/off | PASS, Count and Spacing; explicit final shorter remainder |
| 20 | Orient on/off | PASS, actual clone pivot rotations |
| 21 | PreserveRotation | PASS, source offset/scale retained |
| 22 | Repeated regeneration drift | PASS, six Edit Existing/load/apply cycles, exact saved offset and matching transforms |
| 23 | Source unchanged | PASS, original part/model transforms/sizes/structure |
| 24 | Internal move with fixed pivot | PASS, PrimaryPart pivot unchanged, stale plan refused |
| 25 | Source resize | PASS, stale plan refused without write |
| 26 | Source structure changes | PASS, add/remove/rename/reparent; attributes also checked |
| 27 | Deleted control/source | PASS, no partial write |
| 28 | Control rotation rules | PASS, ignored with roll off; stale with roll on; reorder/count/settings changes refused |
| 29 | V1 metadata load | PASS, actual historical binary's Cable and Repeat output |
| 30 | V1 -> V2 regeneration | PASS, safe defaults, user siblings, native Undo/Redo of migration |
| 31 | Hard caps | PASS, segment/copy/source/output limits; 512-segment and 5000-instance boundary estimates |
| 32 | Planner estimates | PASS, generated descendant counts, length/sample count and source count |
| 33 | Build Undo/Redo | PASS, real ChangeHistoryService, one-step exact state |
| 34 | Regenerate Undo/Redo | PASS, old/new Output and metadata identities restored/reapplied |
| 35 | Commit-failure rollback | PASS, injected failures plus refusal/throw/reentrant stale-input cleanup |
| 36 | Unrelated objects | PASS, siblings/source/controls preserved; nested source/control rejected |
| 37 | No product runtime exception | PASS, successful native paths monitored; builtin Studio warnings are not hidden |
| 38 | Exact artifact/source equality | PASS, deterministic rebuild and verified imported binary modules |

## Measured sampling comparison

Reference: 4096 fixed subdivisions per span. Error is maximum positional difference
at equal normalized arc distances over 501 probes, in studs; not a CPU benchmark.

| Fixture | New / V1 samples | New maximum error | V1 maximum error |
|---|---:|---:|---:|
| Straight | 2 / 65 | 0.000001907 | 0.000000060 |
| Long gentle | 203 / 193 | 0.003652939 | 0.006041317 |
| Short tight | 601 / 193 | 0.000153606 | 0.000124567 |
| Alternating 3D | 774 / 321 | 0.001046231 | 0.001152848 |

Actual 3D Repeat: 30 copies, requested spacing 2.5 studs, maximum adjacent reference
arc-step error **0.000010135 stud**. The final endpoint remainder is separately tested
and intentionally retains V1 semantics. More samples do not imply every position
metric improves: the tiny tight fixture and straight float-rounding values are
reported as measured. No universal speed or accuracy superiority claim.

## Corrections and failed intermediate run

The first candidate passed 9 + 38 groups. An added valid eight-control path translated
to (50000,100,50000) exposed excessive adaptive subdivision caused by float32 world
coordinate rounding: intermediate run **40 PASS / 1 FAIL**. Sampling was moved to a
path-local coordinate system, and frame construction now avoids adding a unit vector
to a huge world position. The final complete 9 + 42 run above includes the regression
and passes. The failed intermediate artifact is not the final evidence.

Other technical defects addressed: V1 per-tangent roll-axis switching; incomplete
source freshness checks; unchecked changes while acquiring history; detached output
cleanup when recording throws; translated/nonfinite rotation metadata; duplicate or
gapped metadata references; degenerate cable chords discovered only during output.

## NON TESTED / deferred

- GUI walkthrough, roll-toggle mouse interaction, screenshots, visual/DA quality,
  listing, web configuration and publication: intentionally excluded by #18.
- No long-running CPU benchmark or universal geometric guarantee outside the
  documented fixture/tolerance/domain limits. Exact cusps and tight self-intersections
  are not smoothable by a frame solver.
- No required optional-roll feature was deferred; it is implemented and tested.
- Later UI/commercial release work is separate. Do not overwrite the public asset
  from this technical candidate task.

See [technical behavior](TECHNICAL_BEHAVIOR.md) for all numerical limits, metadata,
source fingerprint coverage and distribution semantics.
