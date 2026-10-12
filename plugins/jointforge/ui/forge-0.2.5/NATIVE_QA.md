# JointForge 0.2.5 native handoff

Owner: parent coordinator. No Studio slot has been used by this implementation
agent. Run locally in Edit mode, never Play/Run or a published place.

## Rebuild

From repository root:

```sh
python3 plugins/jointforge/ui/forge-0.2.5/build.py
```

Optional `--rojo /path/to/rojo --compiler /path/to/luau-compile`. This command
only builds/compiles/verifies; it does not install plugins or open Studio.
It verifies two identical builds, the imported 9 Sources, the production-only
11-item model, the unchanged engine/brand baseline and unchanged historical dist.

## Automatic native runner

All paths below are relative to this directory.

1. Parent installs only the separate `JointForge025QA.rbxm` for the QA session.
2. Parent opens `JointForge025QA.rbxl` (empty, local, Edit mode). Its Workspace
   attribute `JointForge025Gate=true` opts in. The runner checks emptiness,
   IsStudio, not IsRunning, and PlaceId=0 before creating test fixtures.
3. The runner automatically executes the existing V11 56-row technical matrix,
   including its 9 supported classes, transaction/rollback/cap tests and native
   Undo/Redo. Its obsolete V1 callback smoke is replaced via an explicit test
   option with current Inspect/Create/Batch/attachment native control callbacks.
   No engine assertion is skipped. Payload count is now 9 production Sources.
4. It also runs 10 targeted issue scenarios: all nine diagnostic codes and real
   counts; read-only Scan/Preview; explicit repair 12 -> 11 and native Undo/Redo;
   duplicate repair clearing both rows; stale refusal before recording;
   NoCollision policy; Create/Batch native writes; scope/duplicate identities/
   inspect-only refusal; overflow/cancellation/changed-scan refusal; a measured
   128-connection scan under 2,000 unrelated folders with yielded heartbeats.
5. Save the native log. Required prefixes: `[JointForgeV11][MATRIX]` (all 56 PASS),
   `[JointForgeV11][SUMMARY]`, `[JointForge025][ISSUES] 10 PASS / 0 FAIL`,
   `[JointForge025][RESPONSIVENESS]` (measured numbers, no preset performance PASS),
   and `[JointForge025][SUMMARY] PASS`. The QA model attributes Complete/Success
   are written by actual execution. Treat missing output or any FAIL as failed.

The QA Candidate and Legacy are imports of the exact binaries. Only Main.Disabled
is changed in those copies. Sources are verified byte-for-byte against the
commercial artifact. The commercial Main remains enabled. Fixture, runner,
tests and legacy import never enter the commercial binary.

## Installed commercial GUI, separately

Parent installs `JointForge-ForgeStudio-0.2.5.rbxm` as the actual full plugin and
opens `JointForge025-Demo.rbxl`. This demo has no auto-run attribute/scripts.
`JointForge-Issues.rbxmx` is the same real fixture embedded in the QA model.

1. Open the plugin using its actual toolbar. Inspect opens first. Select
   JointForgeIssueAssembly and Scan selection. Expected engine results are
   12 joints, 12 diagnostic occurrences, 11 affected joints, nine grouped codes.
   Warnings and inspect-only observations count as issues; this is explicit in
   the detail codes, not a promise that every row is automatically repairable.
2. Inspect BrokenConnection; Locate selects that exact joint. Part0 is Endpoint,
   Part1 is Missing. Two fixture parts named Endpoint exercise duplicate path
   identity; the session # IDs and Locate actions distinguish them.
3. Select BrokenC in Explorer, explicitly assign it to endpoint 1, Preview repair.
   Verify one exact reassignment, no write before Apply, stable Apply action.
   Apply. The original assembly scope must remain selected in the scan context
   even though Locate/Assign changed Studio Selection. Expected rescan: 11 issues.
4. Native Undo then Rescan restores 12; Redo then Rescan restores 11. A scan's
   old result is invalidated on Undo/Redo. Changing a relevant endpoint after
   Preview must remove Apply and show stale status. Selection changes invalidate
   the exact plan too. Test Cancel scan and a scan over 128 connections: no
   partial clean result may appear.
5. Inspect DuplicateOne: reassign Part1 to DuplicateC and Preview/Apply. Both
   duplicate diagnostics disappear, reducing the current total by 2.
6. Inspect the Hinge, invalid-ancestry Rope, anchored warning and unsupported
   Rigid. Confirm codes/endpoints are real, with no guessed endpoints, auto
   unanchoring or Fix All. Rigid remains inspect-only.
7. Exercise Create with CreateA/CreateB; Batch with BatchA as root, BatchB Static,
   BatchC Moving. Review exact plans, Apply, native Undo/Redo. Check separate
   removal selection, Preview, mandatory confirmation and same-instance Undo.
8. Capture 320x640 and 560x640 in Dark and Light, plus 240x360 / 400x640 / tall
   sanity where meaningful. Check scroll, input focus, tooltips, selected state,
   no horizontal scroll, long/duplicate names, empty/blocked/stale/success states,
   code grouping and stable primary actions. Compare to #28 baseline screenshots.

The callback smoke is not actual installed-GUI evidence. Keep installed-GUI,
screenshots/theme review and human visual judgement separate in the gate record.

## Bounds and pending timing review

The existing Planner does not accept a reusable index. The adapter allows at most
128 selected scope objects and 128 inspected connections. Every supported valid
joint receives an unchanged Planner Preview with its own edge excluded; only its
real direct-duplicate/indirect-path codes are added to Graph diagnostics.
Existing Graph caps still apply: 20,000 visited descendants, 8,000 nodes/edges,
4,000 nodes per component, depth 128. At most 132 bounded graph builds run for a
complete 128-connection scan. This remains O(joints * scene), with an explicit
ceiling, progress and cancellation between rows; no speed claim is made.

The runner measures actual native elapsed/longest-step times. Parent must review
interactive responsiveness/cancellation on the installed GUI; reduce scope if a
full scene is slow. A changed relevant fingerprint, changed scan membership,
overflow, cancellation or unexpected Planner error prevents a completed result.
