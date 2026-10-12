# JointForge - Forge Studio 0.2.5

GOOD - reviewed actual installed Inspect/repair workflow and Dark/Light captures.
Native regression PASS: 48 scenarios (38 V11 + 10 issues), all 56 matrix rows.
Parent executed native and installed-GUI QA on 2026-10-03 in Studio
0.741.19.7411056. GUI Redo and other unexecuted interactions remain NON TESTED;
this is not a blanket PASS for every UI quality gate. No publication/commit/push.

Internal productVersion remains 1.1.0. Catalogue release is Forge Studio 0.2.5,
shown in the existing native widget title. Canonical asset 103958912217728 is
unchanged. Historical binaries, hashes and previous UI evidence are preserved.

Candidate: `JointForge-ForgeStudio-0.2.5.rbxm`; exact hash and source hashes are
recorded in `candidate.json`. Build/runner instructions: `NATIVE_QA.md`.

## Implemented

Inspect/Issues opens first. Real Graph diagnostics plus existing Planner conflict
codes drive joint count, issue count, affected count, issue groups and row states.
Wide list/detail and narrow list-to-detail preserve visible Part0/Part1 identities.
Locate uses actual Selection; endpoint reassignment is explicit; Preview/Apply
uses the unchanged engine. Apply rescans the stored assembly scope and reports
the actual before/after issue count. Create/Batch remain secondary workflows.
Removal stays separate and confirmed. Canonical F, BuilderSans, local Studio
primitives, engine and native transaction sources match baseline bff0d9d.

Scans are capped at 128 connections/scope objects, yield progress per connection,
can be cancelled, and reject partial or changed results. No auto-repair, automatic
unanchoring, guessed endpoints, new joint classes or core graph rewrite.

## Evidence and limits

| Gate | Status |
| --- | --- |
| 12 Luau production/QA sources compile | PASS |
| Reproducible artifact; 9 imported production Sources equal disk | PASS |
| Commercial Main enabled; QA Main disabled only in imported copy | PASS |
| Unchanged engine, canonical F and StudioUI baseline hashes | PASS |
| Historical dist bytes unchanged | PASS |
| Real 12-joint fixture references package correctly | PASS |
| Native V11 regression: 38 PASS / 0 FAIL; all 56 matrix rows | PASS |
| 10 targeted issue scenarios | PASS |
| Actual fixture totals: 12 issues / 11 affected; explicit repair 12 -> 11 | PASS |
| Installed full Main loads | PASS, actual installed plugin |
| Actual GUI Scan/Inspect/Assign/Preview/Apply/Rescan | PASS, reviewed captures + output assertions |
| Actual GUI Locate | PASS, exact BrokenConnection selection verified |
| Actual GUI Undo | PASS, Part1 restored to nil |
| Actual GUI Redo | NON TESTED; native Undo/Redo remains PASS |
| Native yielded scan, cancellation/overflow and measurements | PASS, QA runner only |
| Create/Batch native non-regression, stale, real Undo/Redo | PASS |
| Actual GUI Create/Batch, stale, cancellation, removal walkthroughs | NON TESTED; native/callback evidence only |
| Captured Inspect geometry: 240/320/400/560; Dark/Light sanity | PASS for recorded sizes/states |
| Independent visual/product review against #28 baseline | GOOD; evidence and limits in GUI_EVIDENCE.md |

Evidence: [native-dark-run.txt](native-dark-run.txt), executed 2026-10-03
13:28:53-13:28:59 UTC against unchanged artifact SHA256
`e74b3f4d94de155faa634a0986dcea30efee105a1c009b8db7c9a324e36a2216`.
The 128-connection scan with 2,000 unrelated folders recorded 128 heartbeats,
2,129.901 ms elapsed and an 11.073 ms longest step. These are measurements from
this fixture/run, not a general performance guarantee. Native callbacks and
yielded cancellation passed; installed-GUI stress/cancellation remain untested.
Separate [GUI evidence](GUI_EVIDENCE.md) records actual Scan -> explicit repair ->
Rescan, real Locate and Undo. It does not convert harness callbacks into GUI proof.

The actual before state shows 12 scanned / 12 issues / 11 affected, BrokenConnection
with Part0 Endpoint #4 and Part1 Missing. Preview left Part1 nil. Actual Apply 1
set Part1 to BrokenC; the corrected after-repair screenshot shows 11 issues /
10 affected, Part1 BrokenC #6, and the 12 -> 11 success message. Actual Undo was
verified separately; GUI Redo was not. Dark captures use 560/320x642 content
(666 outer height), not 640; Light captures use 560/320/400x640 and 240x360.

QA automation failure, retained in the record: session 20261003T133443Z crashed
at 13:42:36.407 UTC immediately after the coordinator directly assigned
settings().Studio.Theme from Command Bar, with a UI-thread HardAssert. This was
an automation-triggered Studio failure, not a JointForge action/engine failure.
The QA fixture was recovered in session 20261003T134350Z; native Studio Settings
theme switching worked and Light/Locate/Apply/Undo checks continued successfully.
No source, binary or Studio changes were made during this documentation review.

Raw-log review: `0.741.19.7411056_20261003T132850Z_Studio_59878_last.log`,
line 1443, reports once at 13:28:54.199 UTC that SerializationService's Parent
is locked (current parent JointForge025QA.rbxl, new parent NULL). There is no
attributed JointForge stack at that warning and no SerializationService reference
in the production or QA Sources. All native assertions subsequently passed.
The cause is not established; this is a recorded QA-session warning, not evidence
of a deterministic JointForge engine defect. No engine change or rebuild made.

## Contract mapping and baseline

Visual thesis: existing restrained copper Forge connection workspace, with issues
as the work object. Content: scan context/counts, filtered connection rows, selected
endpoint relationship, explicit plan and stable action. Interaction: selected/hover
states, narrow list/detail navigation, cancellable progress; no decorative motion.

Baseline: UI #28 commit bff0d9d and `../review/dark-320.png`,
`../review/dark-560.png`. Historical UI report: `../STATUS.md`.
The #34/#35 brief replaces the old Create-first hierarchy; no new branding or
commercial mock UI is introduced. No sequential approval prerequisite is applied.

| Reference area | Real source/action |
| --- | --- |
| Issues summary/groups/rows | Graph.inspect + disposable Planner reassign Preview |
| Connection identity and Part0/Part1 | Graph.endpoints and session Graph.id |
| Locate | Studio Selection:Set on that exact joint/endpoint |
| Explicit assignment | One selected BasePart or direct Attachment, validated by Planner |
| Exact repair plan | Planner.preview, unchanged immutable plan and stale checks |
| Repair + Rescan | Transaction.apply then Inspection.scan over stored scope |
| Create/Batch | Existing endpoint cards, entries, Planner create/batch requests |
| Separate removal | Existing bounded Planner remove + explicit confirmation |

Deliberate limit: full conflict analysis is bounded to 128 connections because the
unchanged Planner builds its own graph per Preview. Counts are diagnostic occurrences
(including warnings and inspect-only), not a count of automatically repairable joints.
Native regression and the demonstrated installed hero workflow are PASS. The
reviewed composition is GOOD: real issue collection/detail at 560, sequential
detail at 320, visible endpoint identity and a stable action area. Long path text
and below-fold detail/plan content remain less concise than ideal; 240x360 truncates
the footer sentence while retaining counts, identity and the action region.
Unexecuted GUI checks and exhaustive size/state combinations are not marked PASS.
