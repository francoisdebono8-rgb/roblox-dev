# AccessForge 0.2.5 Installed GUI Evidence

Assessment: **GOOD** for the scoped #33/#35 product finish. Reviewed on 2026-10-03
from actual commercial DockWidget captures, the recorded parent walkthrough and
the session log. This is not a claim of exhaustive GUI coverage.

## Artifact and Session

- Candidate: `AccessForge-ForgeStudio-0.2.5.rbxm`.
- SHA256: `839798041fdc1884df19e8cabccf7e1f698c0087d6f1e3bc8c9ec5bd25b1089d`.
- QA runner SHA256: `1515e3f150eb89f0af29edf8159b5d83397df535fc63ab9db3ee2ef10582198f`.
- All eight production source hashes and both binary hashes were rechecked unchanged.
- Studio 0.741.19.7411056; Edit mode; session `20261003T143618Z`.
- Parent confirms byte-identical full enabled Main installation. The session logs
  the installed file as `user_AccessForge-v1.0.0.rbxm`; that installation filename
  does not identify the candidate's version or replace its SHA verification.
- Source log: `/Users/francoisdebono/Library/Logs/Roblox/0.741.19.7411056_20261003T143618Z_Studio_63785_last.log`.
- No Studio operation, source/binary change or rebuild was performed during this review.

## Verified Log Evidence

The log matches the candidate SHA, contains all 55 individual V11 PASS lines,
all matrix IDs 1 through 44 as PASS, all 10 contextual PASS lines and final PASS.
It then records the commercial dock opening and the following assertions:

```text
14:36:23.425Z [AccessForge025Gate] candidate=839798041fdc1884df19e8cabccf7e1f698c0087d6f1e3bc8c9ec5bd25b1089d
14:36:24.727Z [AccessForgeV11][SUMMARY] 55 PASS / 0 FAIL
14:36:24.988Z [AccessForge025][SUMMARY] 10 PASS / 0 FAIL
14:36:25.495Z [AccessForge025Gate][SUMMARY] PASS
14:38:58.716Z [Forge025GUI] Access commercial dock opened
14:41:27.460Z [Forge025GUI] Access Preview read-only PASS
14:42:54.307Z [Forge025GUI] Access Build UndoRedo 33 parts PASS model=AccessForge_Straight
14:45:59.099Z [Forge025GUI] Access Regenerate 38 parts PASS
```

These are emitted result lines, not only echoed Command Bar input. The read-only
assertion checks the four fixture folders and absence of Generated under Workspace
children. The GUI write assertions count actual generated BaseParts. The parent
reports uninterrupted native Undo/Redo before the 33-part assertion; the suite also
independently checks history and instance identity.

`CreatorError`: **0** in this session log. Four `CreatorWarning` entries at
14:36:22.203Z concern Studio StyleRule `CornerRadius` string-to-UDim conversion,
before AccessForge plugin loading. No AccessForge failure line was found. This is
not an assertion that the entire Studio log has no unrelated warnings/errors.

## Actual Interaction Coverage

| Workflow | Evidence and result |
| --- | --- |
| Full commercial Main | Real installed DockWidget opened; screenshots are not a harness-mounted substitute |
| Straight assignment and Preview | Actual Assign Start/End; 15 steps, 33 parts, rise 12, run 30; 4 context objects, 0 sampled omissions |
| Read-only Preview | Workspace assertion PASS in session log |
| Straight Build/Confirm and Undo/Redo | Actual GUI write; real generated count 33 after uninterrupted native Undo/Redo; PASS |
| Edit Existing and moved End | End moved by (0, 2, -4); preview removed and Regenerate disabled; real Preview refreshed |
| Comparison and regeneration | Actual Existing/Proposed toggles; existing 33 vs proposed 38; Regenerate/Confirm committed 38, logged PASS |
| Switchback refusal and recovery | Initial Width 12 incompatible with 9-stud entrance spacing; actual Width field corrected to 6; valid 20 steps / 71 parts |
| New markers | Actual control exercised, then fixture endpoints reassigned; subsequent Switchback capture valid |
| Catwalk refusal and recovery | Non-level input refused; actual Catwalk fixture assigned; valid rise 0 / run 28 / 17 parts Preview |
| All three Build/Undo/Redo engine paths | PASS in native suite; GUI Build/Confirm was exercised for Straight only |

The invalid Switchback/Catwalk interactions and New markers sequence are reported
by the parent; the subsequent valid states are visible in captures. No screenshot
of an invalid-geometry message is supplied. The stale-state screenshot is separate.

## Capture Inventory

All images are actual unredrawn commercial UI. PNGs include Qt window chrome and
use Retina scale 2. Parent-reported outer logical dimensions are client width + 2
and client height + 24; measured PNG dimensions agree exactly. Baselines are already
cropped to client bounds, so comparison excludes the new window title bar.

| Capture | Client logical size | PNG pixels | Observed state |
| --- | --- | --- | --- |
| [dark-560](review/dark-560.png) | 560x640 | 1124x1328 | Straight endpoints beside contextual preview and real metrics |
| [dark-320](review/dark-320.png) | 320x640 | 644x1328 | Dedicated Straight Preview, visible labels/metrics/action |
| [dark-edit-existing](review/dark-edit-existing.png) | 560x640 | 1124x1328 | Existing selected, 33 parts, moved current endpoint |
| [dark-edit-proposed](review/dark-edit-proposed.png) | 560x640 | 1124x1328 | Proposed selected, 18 steps / 38 parts, same comparison framing |
| [dark-stale](review/dark-stale.png) | 560x640 | 1124x1328 | Geometry cleared; Preview primary; Regenerate visibly disabled |
| [dark-switchback](review/dark-switchback.png) | 560x640 | 1124x1328 | Valid 20 steps / 71 parts, both tread depths and landing/rail counts |
| [dark-catwalk](review/dark-catwalk.png) | 560x640 | 1124x1328 | Valid 0 steps / 17 parts, rise 0, run 28 |
| [light-560](review/light-560.png) | 560x640 | 1124x1328 | Catwalk; neutral Light surface, readable geometry and labels |
| [light-320](review/light-320.png) | 320x640 | 644x1328 | Catwalk narrow Preview and complete metrics |
| [light-400](review/light-400.png) | 400x640 | 804x1328 | Single-column Preview; full metrics and stable footer |
| [light-240-short](review/light-240-short.png) | 240x360 | 484x768 | Header/navigation/footer fit; body scroll exposes remaining preview/metrics |

No 560x900 capture exists: 900 client pixels exceed the usable Mac screen.
Dark 240/400 and a complete theme-by-size-by-state matrix were not captured.

## Baseline Comparison and Judgment

Reviewed directly against [baseline 560](../review/dark-560.png) and
[baseline 320](../review/dark-320.png), baseline commit `bff0d9d`.
The fixtures differ (baseline Straight run 24 / 31 parts; current run 30 / 33),
so those numeric differences are not presented as a performance improvement.

The accepted F, BuilderSans, violet accent, restrained surfaces and fixed command
bar remain recognizable. The meaningful change is in the work object: the baseline
shows isolated stairs, while current captures show Start and End against actual
supported platform geometry. Counts and scope sit directly below the preview;
regeneration has selected Existing/Proposed views. At 560 the endpoints remain
beside the result; at 320/400 the result gets its own legible view. Both themes are
readable without horizontal scrolling or overlapping controls in the supplied states.

The hero workflow is now evident and demonstrated through a real build/regeneration,
with credible technical results and explicit context omissions. This supports GOOD.
It does not justify VERY GOOD or an unconditional all-controls/all-gates PASS:

- At 560 the Catwalk sidebar row lies below the visible body. It is reachable by
  vertical scrolling and via Settings, as exercised by the parent; mode identity
  remains visible in the header. This reduces at-a-glance discoverability.
- At 240x360 the viewport and metrics deliberately extend below the scrolling body.
  Navigation and Build remain visible; this capture is short-layout sanity, not a
  complete narrow interaction walkthrough.
- The stale screenshot retains generic "Start and End required" secondary copy
  despite assigned markers. Its footer correctly identifies changed markers,
  removes old preview geometry and makes the write action unavailable.
- Full Rails/Finish, ownership-protection and long/duplicate-name GUI cases were
  not exhaustively exercised. Relevant engine safety passes in the native suite;
  those results are not relabeled as GUI coverage.

## Gate Interpretation

PASS: exact artifact/native regression, sampled real-data truth, actual Straight
Preview/Build/Regenerate/history, comparison/stale states, Dark/Light 320/560 sanity,
400 Light and 240-short Light layout sanity, and baseline-relative visual review.
NOT RUN: GUI Build for Switchback/Catwalk, exhaustive control/state interaction
matrix and 900-high capture. The #33/#35 scoped assessment is GOOD with these
explicit boundaries; the coordinator owns issue closure and catalogue acceptance.
No source change, publication or Git write is part of this evidence update.
