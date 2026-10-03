# PresetForge 0.2.5 / installed GUI evidence

**Assessment: GOOD.** Independent review of seven direct native screenshots and scoped
log results; no Studio interaction, image editing, code change or rebuild for this review.
Commercial SHA: `a9726d442d8376a658cdb042da2212cced695ab2b7e6a96c4b8a08e71d881a63`.
Coordinator executed the full installed Main in Studio 0.741.19.7411056, local Edit mode.

## Actual results

Source log: `0.741.19.7411056_20261003T140234Z_Studio_e3ab2_last.log` in
`/Users/francoisdebono/Library/Logs/Roblox/`. Only actual
`[FLog::CreatorOutput] [Forge025GUI]` output is counted below, not echoed `> ... print(...)`
commands containing a proposed PASS string.

| UTC on 2026-10-03 | Observed evidence |
| --- | --- |
| 14:08:37.845 | `preview lights=40 cold=30 warm=10`; Preview left the light baseline unchanged |
| 14:08:37.845 | Classes: Folder 2, PointLight 40, Model 5, Part 150, Snap 21 = 218 descendants |
| 14:09:45.543 | `Apply all40 warm; noncaptured properties tags attributes preserved PASS` |
| 14:10:28.057 | `native Undo30 baseline10 preserved PASS` |
| 14:13:43.949 | First Redo assertion failed in CommandBar; invalid interrupted-history QA sequence, not PASS |
| 14:14:50.346 | `native UndoRedo uninterrupted all40 warm PASS` after clean Apply -> Undo -> Redo |

Real clicks selected Project **Warm worklights**, Descendants / PointLight, then Preview
and Apply 30. Screens show 30 affected, 10 matching, 40 compatible and 60 property writes.
Studio's 21 additional Snap instances explain **218 scanned / 178 ignored**, versus the
offline fixture's 197/157. Affected/compatible/matching/write scope is unchanged.

The successful Apply assertion checks every light's Brightness=5, Color=#FFCC8C, Range=12,
Shadows=false, Enabled=true, Keep=false, LightingProfile=Existing, Worklight+KeepTag and
absence of FixtureReady. The screenshot records 30 targets / 60 properties / zero metadata
writes and disables Apply 0. Full graph preservation and instrumented setter counts are
separate native-suite evidence (H04/H06), not inferred solely from this GUI assertion.

The coordinator identified the first Redo failure as a Command Bar read between Undo and
Redo disrupting history. The failed assertion is retained above. The final successful
sequence had no intervening Command Bar execution; assertions ran only afterward. No
product error is attributed to the invalid first QA procedure.

## Independent visual comparison

Compared `../review/dark-320.png` (older Arena baseline) and
`../review/draft-dark-320.png` / `../review/draft-dark-560.png` (predecessor `da434b...`) with:

| Final capture | Assessment |
| --- | --- |
| [Dark 560](review/dark-560.png) | Selected Project recipe and real Local entries remain visible beside scope/changes; 30 will change and exact values dominate |
| [Dark 320](review/dark-320.png) | One column retains context, contained path, paired values, color swatches and fixed Apply 30 |
| [Light 560](review/light-560.png) / [320](review/light-320.png) | Same hierarchy, readable text, restrained selection tint and strong primary action |
| [Light 240 short](review/light-240-short.png) | Tabs wrap intentionally, identity and Apply stay visible; metrics/diffs require body scrolling |
| [Light 400](review/light-400.png) | Single column remains legible; no unnecessary compressed library pane |
| [After Apply](review/dark-after-apply.png) | Truthful zero-change state, 40 matching, success result and disabled Apply 0 |

Against the older Arena baseline, the headline impact, distinct write counters and actual
color before/after make the bulk-edit value faster to read. Against the immediate lighting
drafts, this is a controlled finalization of the same composition, not a new redesign:
paths remain contained, row actions have room, the catalogue footer is present, and the
full installed plugin exposes real persisted Local/Project context. No obvious text/control
collision or clipped primary action appears in the inspected captures. The next result row
is partially visible at the deliberate scroll boundary; that is not overlapping content.

The images are Retina captures including native window chrome: 1124x1328 for 560x640,
644x1328 for 320x640, 804x1328 for 400x640 and 484x768 for 240x360. Snapshot hashes are in
candidate.json. This supports **GOOD**, without claiming another structural redesign or
an interaction state that a screenshot cannot show.

Physical capture/editor, selective-metadata, duplicate/edit/search, GUI stale mutation and
restart persistence are **NON TESTED in this GUI session**. Applicable controller/native
regressions passed in the separate 94/94 run; in-session settings tests do not prove restart
persistence. No new native tests or publication are requested by this evidence record.
