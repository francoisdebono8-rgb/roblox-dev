# CurveForge 0.2.5 Installed GUI Review

Decision: **GOOD for the executed workflow and reviewed final captures.** No remaining
blocker was found in this evidence. The earlier short-layout blocker is resolved on the
exact final artifact. This is not certification of every size/theme/GUI branch or a claim
that all QUALITY_GATES matrix cells were executed.

## Provenance

- Candidate SHA256: `510b7dc3af0dfed72bdc97f7ebe83ce2bdacfc960ffac38dd9ab9735e78cdc7d`.
- Roblox Studio 0.741.19.7411056, Edit mode, 2026-10-03.
- Coordinator operated the actual installed commercial Main/GUI and confirmed installed
  byte equality. The repository artifact hash was independently verified by this reviewer.
- All ten unretouched final images in `review` and the final Studio log were independently
  inspected. No Studio interaction, source change, image editing or rebuild occurred in
  this documentation review.
- `native-final-run.txt` establishes 63 native checks PASS / 0 failures: 9 baseline,
  42 technical, 5 context and 7 View callback checks. Callback mounts of the separate QA
  import do not prove the installed commercial GUI; the evidence below is separate.
- `review-before-compact-fix` and `native-dark-run.txt` belong to the earlier candidate.
  They are historical evidence only, not final-hash PASS evidence.

## Every Final Capture Reviewed

Pixel dimensions include native frame/tab chrome; they are not measured DockWidget client
heights. Logical width labels identify the coordinator's capture settings.

| Capture | Image pixels | Independent assessment |
| --- | --- | --- |
| [Dark Cable 560](review/dark-560-cable.png) | 1124x1328 | GOOD: four ordered points, real poles/crossarms, 40.5 studs, 51 segments, four context parts; selected point and Regenerate clear. |
| [Dark Repeat 560](review/dark-560-repeat.png) | 1124x1328 | GOOD: path rail and contextual result use the width; Repeat is first-class, source CustomBeacon identified, 41.4 studs / 14 copies and two context parts. |
| [Dark stale 560](review/dark-560-stale.png) | 1124x1328 | PASS for shown state: geometry and old estimate cleared, stale message, disabled comparison/Regenerate, dominant Preview recovery. |
| [Dark Existing 560](review/dark-560-existing.png) | 1124x1328 | GOOD: actual old geometry is selected; metrics explicitly say Proposed: 48.7 studs / 14 copies, avoiding an old-result count claim. |
| [Dark Proposed 560](review/dark-560-proposed.png) | 1124x1328 | GOOD: moved-path result visibly differs; platform placement and framing match Existing for a useful comparison. |
| [Dark Repeat 320](review/dark-320-repeat.png) | 644x1328 | GOOD: usable narrow result, source CustomBeacon, 48.7 studs, 14 copies, two context parts and stable action. |
| [Dark 400](review/dark-400.png) | 804x1328 | GOOD: deliberate single-pane Preview; result, metadata and commands fit. |
| [Dark short Built 240](review/dark-240-short-built.png) | 484x768 | GOOD as a compact survival layout: meaningful output/platforms visible, comparison controls fit, full Built: 48.7 studs / 14 copies confirmation, Preview and disabled Regenerate remain reachable. |
| [Light Repeat 560](review/light-560-repeat.png) | 1124x1328 | GOOD: path rail, selected mode, source, four markers and 48.7 studs / 14 copies remain readable; coherent Light plugin content. |
| [Light Repeat 320](review/light-320-repeat.png) | 644x1328 | GOOD: substantial dedicated Preview, source/context and primary command fit without product-text collisions. |

No product-content layout collision or clipped primary command is apparent in these
captures. Projected point markers can overlap: point 2 partly covers selected point 1,
especially in the compact view. This is geometry projection, not overlapping UI sections;
the selected blue marker and Path list remain available, but compact point inspection is
less comfortable than at normal size. The smallest view is not presented as the preferred
working size or proof that every dense path is easy to inspect.

Light native titles/tabs still show inherited palette contrast outside the plugin content.
The coordinator attributes this to live Studio theme inheritance; this review did not
isolate native Qt behavior. The internal Forge surfaces, text, selected states and controls
are legible in both final themes. No final Light Cable capture is claimed.

## Compact Fix Review

The earlier [failed short capture](review-before-compact-fix/dark-240-short.png) reduced
geometry to roughly 4px while keeping Regenerate available. It remains failure evidence,
not an accepted exception. The final short Built image now shows output and both platforms.

Read-only source review confirms that root heights below 440 use header 64, mode row 64,
navigation 102, work top 136, reserved height 206 and footer offset 62. The redundant output
heading is hidden; comparison remains 30px high with preview top 36. At root 240x338 this
leaves a 96px-high viewport, rather than the earlier 4px. Normal 640-high layout geometry
retains its previous branch, and final 320/400/560 captures show no visible regression.

The compact Built fix preserves the `Built: ` prefix when metrics move into the footer;
the final capture displays the full confirmation and disabled Regenerate. The seventh
native View test verifies preview >=96px high / >=200px wide at 240x338 and 240x360,
preview/footer bounds, comparison targets >=28px, Built text and disabled repeat write.
The installed Regenerate action and its short success capture are separate physical GUI
evidence. No compact-only code mistake was found in the reviewed change. Unshown compact
error/fallback/tooltip states are not certified by this success-state review.

## Before / After

Both historical images were inspected: [320 baseline](../review/dark-320.png) and
[560 baseline](../review/dark-560.png). Those show an isolated cable with no environmental
anchors, Repeat hidden behind Settings, and no visible Existing/Proposed comparison.
The final images retain the accepted F/BuilderSans/quiet-surface grammar while making
Cable/Repeat permanent, moving Edit Existing earlier in the rail, tying numbered controls
to actual geometry, identifying the custom Repeat source, and showing existing versus
proposed output against real copied poles/platforms. This is a substantive workflow and
preview improvement, not merely a recolor. Different fixtures and included native chrome
mean the comparison is compositional; it is not a pixel-identical A/B measurement.

## Installed Workflow And Log

Main log: `/Users/francoisdebono/Library/Logs/Roblox/0.741.19.7411056_20261003T151954Z_Studio_66ec5_last.log`.
The following assertions were read directly. They support the coordinator's reported
real Cable/Repeat Edit Existing, Preview, comparison and short-dock Regenerate clicks plus uninterrupted native
Undo/Redo. Control movement and assertions used the Studio command bar; this is not
evidence of physically dragging the point with the Move tool.

| UTC time / log line | Evidence and scope |
| --- | --- |
| 15:23:13.853 / 1567; completion 15:23:13.864 / 1569 | Snapshots source BasePart CFrame/Size/Color and output CFrames; moves Repeat Point02 by `(0,4,5)`. Final stale capture shows invalidation. |
| 15:24:25.975 / 1594 | PASS: after real Preview, all 42 output BaseParts match baseline CFrames, 14 copies remain, source CFrame/Size/Color unchanged. |
| 15:26:03.272 / 1635 | PASS after real Regenerate and reported uninterrupted native Undo/Redo: 14 copies, 42 parts, all 42 positions changed; original source identity and geometry preserved. |
| 15:26:42.820 / 1645 | PASS: separate native Undo restored all 42 exact baseline CFrames. |

Repeat length changes from 41.4 to 48.7 studs with 14 copies. Existing/Proposed captures
use the same visible framing. No `FLog::CreatorError` matched the final log at review;
this is not a claim of a warning-free Studio session. Native context tests additionally
cover unchanged history head, detached-copy sanitation and read-only snapshot behavior.

## Scoped Gate Decision

PASS: final exact-candidate native regression; installed Cable/Repeat Edit Existing and
scoped Repeat stale/Preview/regeneration/history/source workflow; shown 320/400/560 layouts;
short Built geometry/confirmation/footer; basic final Light/Dark plugin-content sanity;
stale/ready/success shown states; truthful contextual comparison; independent ten-image
and before/after review. The former short-layout failure under Gates 6/8 is resolved for
the demonstrated state, supporting GOOD for this scoped review.

NOT TESTED: 900-high physical capture, tall 240 Preview, exhaustive advanced/error/new-Build
installed GUI, every control/state across every size/theme, full hover/focus/scroll and
long/duplicate-name physical walkthrough. Native engine/callback coverage does not replace
these unexecuted GUI checks. GOOD here does not mark that full matrix PASS or authorize
publication. No source edits, Studio interaction or commit were made by this reviewer.
