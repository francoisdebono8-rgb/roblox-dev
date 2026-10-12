# JointForge 0.2.5 - installed GUI review

Classification: **GOOD**, based on independent inspection of all seven final
screenshots, the #28 baseline and actual CreatorOutput results. Exact artifact:
`e74b3f4d94de155faa634a0986dcea30efee105a1c009b8db7c9a324e36a2216`.
Studio 0.741.19.7411056; parent operated the full installed Main. This review made
no Studio, source, binary, image, git or publication changes.

## Observed workflow

- Actual Scan: 12 joints / 12 issues / 11 affected. BrokenConnection detail shows
  Part0 Endpoint #4 and Part1 Missing. The selected connection and issue reason
  are immediately distinguishable in both the list and the detail.
- Parent selected BrokenC, used the actual Assign selected part to 1 control and
  Preview repair. The screenshot shows the explicit candidate endpoint, a ready
  Preview and Apply 1; the output probe still reports Part1 nil.
- Actual Apply 1 set Part1 to BrokenC. The replaced/corrected
  [after-repair image](review/dark-after-repair.png) visibly shows 11 issues /
  10 affected, Part1 BrokenC #6, 0 issues on this joint and Applied 12 -> 11.
- Actual Undo restored Part1 nil; actual Locate selected BrokenConnection.
  GUI Redo was not verified. Native real Undo/Redo remains PASS separately.

## Screenshot comparison

The [baseline](../review/dark-560.png) opens on Create with paired Handle/Blade
and one creation plan. The [new 560 view](review/dark-560.png) makes assembly
counts, a filtered issue collection and selected connection detail the main work.
This changes navigation, information hierarchy and list/detail relationship while
preserving the canonical F, BuilderSans, copper selection and restrained surfaces.
At [320](review/dark-320.png), the list yields to a readable detail view with
Issues/Rescan navigation and stable Preview/Apply. The real value is demonstrable
without repainting: one missing endpoint becomes BrokenC and the count decreases.

All images were viewed directly. No visible horizontal form scroll or overlapping
controls in the captured states. Light keeps readable text, warnings and selection.
At 240x360 the footer sentence truncates, but header counts, selected identity,
endpoints and action region remain visible; lower controls require vertical scroll.
The interface is GOOD, not VERY GOOD: path-heavy assignment text and below-fold
plan/detail content are still relatively verbose. This is visual judgement of the
captured states, not an exhaustive interaction or all-quality-gates certification.

| Image in review/ | Content size, logical px | PNG pixels including native frame |
| --- | --- | --- |
| dark-560.png | 560x642 | 1124x1332 |
| dark-320.png | 320x642 | 644x1332 |
| dark-after-repair.png | 320x642 | 644x1332 |
| light-560.png | 560x640 | 1124x1328 |
| light-320.png | 320x640 | 644x1328 |
| light-400.png | 400x640 | 804x1328 |
| light-240-short.png | 240x360 | 484x768 |

Dark outer height is 666 logical px; do not label these as 640-high content.
Current screenshot hashes are recorded in candidate.json.

## Actual output and automation incident

Logs are under `/Users/francoisdebono/Library/Logs/Roblox/`:

| Session log | Actual CreatorOutput evidence (not echoed commands) |
| --- | --- |
| 0.741.19.7411056_20261003T133443Z_Studio_d72fd_last.log | L1508 before=nil; L1542 previewPart1=nil; L1543 size=320,642; L1566 appliedPart1=BrokenC PASS; L1592 undoPart1=nil |
| 0.741.19.7411056_20261003T134350Z_Studio_5a7f5_last.log | L2783 theme=Light; L2865 Locate PASS; L2866 size=240,360 theme=Light; L3016 real Apply PASS; L3042 real Undo PASS |

The initial session crashed at 13:42:36.407 UTC (L1593):
`HardAssert (UIContext::requireUIContext not on UI thread)`. Immediately preceding
it, L1590 echoes the coordinator's direct Command Bar `settings().Studio.Theme=t`
assignment; the Undo readback had already printed nil. Record this as a QA
automation-triggered Studio crash, not a product defect. It was not concealed or
counted as a successful theme test. Parent recovered the QA fixture and used
native Studio Settings for theme switching in the second session; Light captures
and subsequent actual Locate/Apply/Undo succeeded without a source/binary change.

Preserved native proof: [native-dark-run.txt](native-dark-run.txt), 48 scenarios
(38 V11 + 10 issue), zero failures, all 56 matrix rows, real native Undo/Redo.
GUI Redo, actual GUI Create/Batch/stale/cancel/removal walkthroughs, uncaptured
theme/size/state combinations and installed stress responsiveness remain unverified.
