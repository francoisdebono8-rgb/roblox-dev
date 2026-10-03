# AccessForge / Forge Studio 0.2.5

Issue #33 under #35. **GOOD: NATIVE REGRESSION AND SCOPED INSTALLED-GUI REVIEW PASS.**
No publication. Source and candidate remain frozen.
Internal product version remains **1.1.0**; catalogue label appears in the existing
Forge Studio header. Canonical asset `127360597946823` is unchanged.

## Scope and Mapping

Visual thesis: preserve the accepted F/BuilderSans shell and make the real assembly
between Start and End the main work object. Content: endpoints, assembly mode,
contextual preview, real metrics, Build/Regenerate. Interaction: instant comparison
with fixed framing, existing quiet hover states, explicit stale invalidation.

Baseline: commit `bff0d9d`, `../AccessForge-v1.1.0-ui27.rbxm`; internal baseline
screenshots `../review/dark-320.png` and `../review/dark-560.png`.

| Surface | Real source/action |
| --- | --- |
| Paired Start/End and viewport labels | Assigned BasePart positions, `plan.a/b` |
| Assembly | Exact detached `Engine.output(plan)` |
| Existing/Proposed | Registered existing owned Parts vs exact new output; same camera bounds |
| Nearby platforms | Read-only bounded queries; exact supported primitive geometry; counted omissions |
| Steps, parts, rise, run, riser, both tread depths | Immutable `plan.metrics` |
| Landing, rail segment/post, support counts | Immutable `plan.metrics` |
| Stale / Build disabled | Engine freshness plus captured context freshness |

Engine, Geometry, Settings and canonical ForgeMark are byte-identical to baseline.
No generator, dependency, shared framework or project preview object was added.
The assembly pane scrolls at short heights; the command area stays fixed.

Safe context fallback: at most 32 primitive copies, two 48-result spatial queries,
18 studs per axis around each endpoint, 64-stud maximum context dimension.
Only exact Part (Block/Ball/Cylinder), WedgePart and CornerWedgePart geometry without
child meshes is shown. Meshes, unions, trusses, other classes, non-Archivable,
oversized and invisible objects are omitted, never substituted with bounding boxes.
Original Archivable is never changed. No project recursive cloning, children,
scripts, meshes or textures are copied; appearance is simplified.
The UI gives shown and omitted counts plus omission reasons. Counts cover unique
sampled objects only; query caps/failures are explicit and unsampled objects,
other non-queryable objects and terrain are not counted. This is a partial context
illustration, not a collision/clearance test.
Comparison switches complete states instead of overlapping two opaque assemblies.

## Evidence

Exact artifact and per-source hashes: [candidate.json](candidate.json).
Build, source verification and native instructions: [NATIVE.md](NATIVE.md).
Native evidence: [native-dark-run.txt](native-dark-run.txt), executed by the parent
on 2026-10-03 at 13:09 UTC in Studio **0.741.19.7411056**, Edit mode, Dark theme.
The log matches candidate SHA256
`839798041fdc1884df19e8cabccf7e1f698c0087d6f1e3bc8c9ec5bd25b1089d`:
55 V11 cases PASS / 0 FAIL, all 44 matrix rows PASS, 10 contextual cases PASS /
0 FAIL, final gate SUMMARY PASS. Candidate and QA runner were not rebuilt.

The parent reran the same complete native gate in session `20261003T143618Z`,
then exercised the actual enabled commercial Main. All 65 cases and 44 matrix rows
passed again. [GUI_EVIDENCE.md](GUI_EVIDENCE.md) records the reviewed native captures,
baseline comparison, verified log assertions and exact coverage limits.

| Gate | Status |
| --- | --- |
| Luau compile; two identical builds; source equality | PASS |
| Engine/brand and three historical binaries unchanged | PASS |
| QA isolated; commercial Main enabled; QA copies disabled | PASS |
| Full 55-case V2 / 44-row matrix + 10 contextual cases | PASS |
| Byte-identical full Main installation and startup | PASS, parent installation report and session log |
| Session CreatorError check | PASS: 0 entries; four pre-load StyleRule warnings documented |
| Actual GUI: assign endpoints, Straight Preview/Build/Confirm | PASS: 15 steps / 33 parts; read-only Preview assertion |
| Actual GUI: moved End, stale blocking, Existing/Proposed, Regenerate | PASS: Existing 33 / Proposed 38; committed 38 parts |
| Actual GUI: Switchback and Catwalk | PASS for invalid-to-valid Preview; GUI Build NOT RUN for these modes |
| Native suite: Edit Existing, moved End, regeneration, user content | PASS |
| Native Undo/Redo; actual Straight GUI build Undo/Redo | PASS |
| 320/560 Dark + Light captures and theme sanity | PASS |
| 400x640 Light and 240x360 Light layout sanity | PASS for captured states; short body scroll documented |
| Before/after screenshot review | PASS; scoped assessment GOOD |
| Exhaustive GUI Rails/Finish, ownership and all-width interaction matrix | NOT RUN; native safety coverage is separate |
| 560x900 capture | NOT RUN: exceeds usable Mac screen |

GOOD is justified by the visible endpoint-to-platform workflow, explicit comparison
and omissions, stable actions, real metrics, successful installed Straight write
workflow and full native regression. It is not a claim that every control/state was
clicked at every size. At 560 the Catwalk sidebar row needs vertical scrolling or
Settings; at 240x360 preview/metrics require body scrolling. The stale state has
generic "Start and End required" secondary copy despite assigned markers, while its
footer correctly requests Preview and Regenerate is disabled. These usability
limits keep the assessment at GOOD rather than VERY GOOD. No 900-high evidence,
exhaustive interaction PASS, publication or Git operation is implied by this review.
