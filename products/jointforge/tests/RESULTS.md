# JointForge 1.0 execution report

Date: 2026-09-26. Real macOS Roblox Studio **0.740.19.7400931**, edit mode.
No simulated engine or mocked Undo is counted as native validation.

| Check | Result | Evidence / boundary |
|---|---|---|
| Nine joint/constraint classes, read-only Preview, creation, poses | PASS | Real instances; native Undo/Redo for every class |
| Mixed static/moving tool batch | PASS | Two WeldConstraints and two Motor6Ds; existing parts preserved |
| Door hinge with reused attachments | PASS | Endpoints, attachment transforms, native Undo/Redo |
| Rope/spring creation and property editing | PASS | Lengths, exposed fields, native Undo/Redo |
| Existing connections, duplicates, indirect cycles | PASS | Rejected before Apply; NoCollision coexistence allowed |
| Stale Preview and invalid input | PASS | Movement, attachment edits, detached endpoints, field changes |
| Inspect external connections and broken endpoints | PASS | Engine tests; four demo connections displayed in actual UI |
| C0/C1 numeric edit and reset | PASS | Engine tests, including native Undo; not a complete GUI field matrix |
| Confirmed removal and attachment preservation | PASS | Native Undo/Redo; children block removal |
| Recording failure / rollback | PASS | Explicit failure injection; property, parent and pose restoration |
| Every exposed property writable | PASS | Actual Studio Instance probes; see API_AUDIT.md |
| Production UI Batch -> Preview -> Apply -> one Edit > Undo | PASS | Real buttons; post-action engine assertions in UI_RUN.txt |
| Three screenshots and demo place | PASS | Actual Studio captures in release/screenshots; no generated UI/compositing |
| Artifact/source equality and reproducible build | PASS | tools/verify_release.py; six scripts only, manifest SHA-256 |
| Luau syntax compilation | PASS | Luau 0.740; not a Roblox-aware static typecheck |
| Complete GUI matrix / physical simulation tuning | NON TESTE | No claim of exhaustive UI or game-play testing |
| Unfamiliar developer under one minute | NON TESTE | Requires an actual unfamiliar human |
| Native Studio versus plugin productivity benchmark | NON TESTE | Only the plugin Batch sequence was exercised; no measured savings claim |

## Engine evidence

`STUDIO_RUN.txt` records the final **14 groups passed / 0 failed** at
12:01:39 UTC. The suite includes assertions and native Undo/Redo within each
group. Test fixtures are separated from operations by a test-only history
waypoint. Unanchored assemblies are compared with CFrame:FuzzyEq(1e-5): the
largest measured translation change was about 0.0000009613 studs, normal engine
floating-point precision, not an intentional repositioning.

During implementation, safety checks were added for invalidated UI previews,
joint children on removal, detached endpoints and edit rollback of connected
part poses. Unary constraints are not incorrectly flagged as missing a second
endpoint. All are covered by the final passing suite.

## Production artifact smoke test

The local plugin was byte-identical to `dist/JointForge-v1.0.0.rbxm`. The QA
plugin was removed before the GUI run. In the original demo, the real Batch
buttons assigned Handle, Body/Battery as Static and Chuck/Trigger as Moving,
previewed four operations and applied once. Command Bar assertions independently
verified two WeldConstraints, two Motor6Ds and unchanged poses/Anchored. One
native **Edit > Undo** removed all four; further assertions checked restoration.
The plugin displayed its actual Undo-completed message. Inspect then listed the
existing model's four joints, including the intentionally missing Weld endpoint.

The successful Batch path used nine semantic actions including Undo, excluding
opening the tab, scrolling and test automation: select/assign root, select/assign
Static, select/assign Moving, Preview, Apply, Undo. Selections were prepared with
Studio Command Bar, not a timed novice interaction. Do not turn this into a
native-versus-plugin speed claim.

No JointForge Luau exception was found in this GUI run. Studio itself emitted
cloud authentication errors and DockWidget relay warnings while opening,
closing and resizing panels; a globally error-free Studio log is **not** claimed.
The widget worked both docked and floating; narrow docking required wrapping and
scrolling. Screenshots use the readable wider floating layout.

## Release decision

Technical package and real Studio smoke evidence are prepared. **Commercial
acceptance remains open**: run the novice trial and native-workflow comparison
in STUDIO_CHECKLIST.md before claiming the issue's full definition of done or
advertising measured time savings. No Creator Store publication, seller/account
change or payment operation was performed.
