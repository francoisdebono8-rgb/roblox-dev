# Human acceptance gate

Use a copy of `demo/JointForge-Demo.rbxlx`. Do not save over the clean fixture.

1. Ask a developer unfamiliar with JointForge to connect the door's Frame and Door using the prepared HingePivot attachments. Record completion time without external documentation. Target: under one minute. Not validated by an automated test.
2. Batch `01_BatchTool`: root Handle; Static Body/Battery; Moving Chuck/Trigger. Preview four joints, Apply once, Undo once, Redo once. Check poses, Anchored and names remain unchanged.
3. Inspect `02_ExistingGraph`. Locate the Motor6D, select both endpoints, observe the intentionally broken Weld. Attempt an overlapping batch and verify it is blocked, preserving every existing joint.
4. Inspect `04_RopeSpring`, change rope Length or spring FreeLength via Preview/Apply; Undo. For physical testing in a copy, unanchor only the intended loads. Check behavior and tune stiffness/collisions yourself.
5. In Inspect, preview checked removal, verify Apply without confirmation fails, then confirm and apply. Undo once restores the joint; attachments remain throughout.
6. Test narrow docking, long names, C0/C1 numeric editing, a stale preview and plugin close/reopen. Verify no JointForge Output errors.

## Manual comparison protocol

Count an endpoint selection, a command invocation, a property assignment and an explicit confirmation as separate semantic actions. Do not count individual keystrokes. Use the same initial fixture and desired result on both paths. Record native Studio's best available contextual tools, not an artificially slow workflow.

| Scenario | Without JointForge | With JointForge | Preview detects conflicts | One Undo restores |
|---|---|---|---|---|
| Tool: 2 static + 2 moving pieces | NOT MEASURED | Executed 9 semantic actions: root select/assign, static select/assign, moving select/assign, Preview, Apply, Undo; tab/scroll/automation overhead excluded | Automated PASS | Engine + real Edit > Undo PASS |
| Door / prepared hinge pivots | NOT MEASURED | Planned 8 actions: select type, select/assign each attachment, Preview, Apply, Undo | Automated duplicate/path checks PASS | Automated PASS |
| Rope / spring adjustment | NOT MEASURED | Record separately for each constraint and property | Automated stale-preview PASS | Automated PASS |
| Existing model preservation | NOT MEASURED | Record inspection, conflict discovery and explicit resolution separately | Automated PASS | Creation/removal/edit tested |

Planned counts are a reproducible procedure, **not measured savings**. The executed Batch path used Command Bar to prepare selections and is not a novice timing trial. Record both native and plugin counts and time with a human before using numerical productivity claims in the listing. A single native hinge can already be fast; the commercial hypothesis is the mixed static/moving batch, not replacing every native constraint tool.
