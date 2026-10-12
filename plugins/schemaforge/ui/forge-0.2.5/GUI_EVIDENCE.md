# SchemaForge installed GUI review / Forge Studio 0.2.5

**Classification: GOOD.** The actual installed product's recorded hero workflow
passes; this is not an exhaustive GUI certification. Parent performed the native
actions. This review independently inspected all nine retained screenshots,
compared accepted references and read the product's CreatorOutput markers.

Studio **0.741.19.7411056**, local **Edit mode**, 2026-10-03. Commercial artifact
SHA256 `1e86dd4e581bdffbae2a55635b95ab41bfa4d41359826935c74ef59bbf9575fe`
was rechecked unchanged. Main was the real installed plugin. The separate QA
bridge prepared/inspected the actual fixture and made the explicit stale mutation;
it did not replace the visible product View or certify GUI clicks by itself.

## Actual workflow and corroborating markers

Source log: [20261003T141548Z CreatorOutput](/Users/francoisdebono/Library/Logs/Roblox/0.741.19.7411056_20261003T141548Z_Studio_c7ea9_last.log).
All timestamps below are UTC. Counter order is
**checked / valid / objects with issues / findings / safely repairable**.

| Actual action or observation | Evidence | Result |
| --- | --- | --- |
| Fixture imports exact artifact | 14:15:51.493 `[SchemaForge025][ARTIFACT]`, matching SHA256, mode=fixture | Correct binary reference |
| Real Load Greenhouse Contract -> Audit -> Run | Parent-operated GUI; Dark/Light Audit captures | 8 / 3 / 5 / 7 / 3 |
| Baseline snapshot | 14:28:57.969 `[SchemaForge025][FIXTURE]` | 8 / 3 / 5 / 7 / 3 |
| Actual Preview 3 on 2 objects; project unchanged | dark-preview.png; 14:29:22.134 `[SchemaForge025][FIXTURE]` | 8 / 3 / 5 / 7 / 3 |
| Actual Apply 3, then uninterrupted native Undo/Redo | Parent's native interaction record; 14:29:57.015 snapshot after that sequence | 8 / 5 / 3 / 4 / 0 |
| Actual re-audit after repair/history | dark-after-repair.png | Four nonfixable diagnostics, zero safe repairs |
| Subsequent native Undo | 14:31:48.745 `[SchemaForge025][FIXTURE]` | 8 / 3 / 5 / 7 / 3 restored |
| Actual Select in Studio on Cost / PlantPot03 | 14:34:00.922 `[Forge025GUI] Schema SelectInStudio PASS` | Selection assertion succeeds; scope then restored via QA bridge |
| Actual Preview 3; deferred QA stale mutation Cost=99 | 14:34:39.088 CreatorOutput command; dark-stale.png | Real GUI Stale and disabled Apply |

The log's snapshot markers confirm actual instance state, not button activation.
The uninterrupted first Undo/Redo pair has one snapshot afterward; no fabricated
intermediate Undo snapshot is claimed. The later Undo independently records the
restored baseline. The parent reports the native interaction sequence and the
screenshots show the resulting installed UI states.

Retained marker values, transcribed without inventing GUI events:

```text
2026-10-03T14:29:22.134Z [SchemaForge025][FIXTURE] {"valid":3,"checked":8,"objectsWithIssues":5,"findings":7,"safelyRepairableFindings":3}
2026-10-03T14:29:57.015Z [SchemaForge025][FIXTURE] {"valid":5,"checked":8,"objectsWithIssues":3,"findings":4,"safelyRepairableFindings":0}
2026-10-03T14:31:48.745Z [SchemaForge025][FIXTURE] {"valid":3,"checked":8,"objectsWithIssues":5,"findings":7,"safelyRepairableFindings":3}
2026-10-03T14:34:00.922Z [Forge025GUI] Schema SelectInStudio PASS
2026-10-03T14:34:39.088Z > task.defer(function() game.ServerStorage.SchemaForge025QA:Invoke("stale") end)
```

## Retained captures

These are actual plugin captures, not reconstructed UI. Native title chrome remains
visible. Individual PNG SHA256 values are recorded in candidate.json.

| Capture | Independent inspection |
| --- | --- |
| [Dark 560](review/dark-560.png) | Five totals, selected finding, Expected/Actual/note, bounded repair and stable Preview action visible together |
| [Dark 320](review/dark-320.png) | Readable totals and single-column findings; no squeezed inspector columns |
| [Light 560](review/light-560.png) | Correct light surfaces, readable semantic values and same selected diagnostic/repair hierarchy |
| [Light 320](review/light-320.png) | Narrow list, scope, totals and primary action remain readable |
| [Repair preview](review/dark-preview.png) | Exactly three additions on two objects; Cost=25, missing current value, Apply 3 |
| [After repair](review/dark-after-repair.png) | 8/5/3/4/0; wrong-type Cost remains "unknown" (string); manual review and disabled repair preview |
| [Stale](review/dark-stale.png) | Warning icon/status, recovery wording and visibly disabled Apply 3; old plan remains reviewable as stale |
| [Dark 400](review/dark-400.png) | Usable single-column work surface; collapsed Filters shown, footer unobstructed |
| [Dark 240 short](review/dark-240-short.png) | Totals and navigation readable; very compact scroll body; Audit and Preview 3 footer usable |

## Before/after judgment

Compared against the accepted [320 lockup](../brand-review/lockup-dark-320.png)
and [560 lockup](../brand-review/lockup-dark-560.png), plus the
[earlier Audit composition](../brand-review/dark-560-audit.png). The earlier Audit
capture predates the accepted F relocation; branding is compared to the lockup
references, not that superseded header. Fixtures differ, so historical and current
numeric totals are not represented as a same-fixture before/after improvement.

The canonical F, BuilderSans, restrained mint selection and quiet surfaces are
preserved. Previously, checked/findings appeared as a small line within the list.
The final dedicated band makes all five real outcomes immediately legible while
preserving the list/diagnostic relationship and exact Expected/Actual/note. At 560
the detailed missing-cost explanation and safe addition remain visible together.
At 320 the summary reorganizes above a usable single-column findings list. Preview
makes the scope of repair concrete, and the post-repair screenshot visibly retains
the four problems that cannot safely be changed. The product benefit is clear
without having to interpret an attribute editor or a wall of rule controls.

This supports **GOOD** for #30/#35's reviewed commercial finish. The minimum-size
experience is functional but cramped, and the preview's three-item fixture leaves
substantial unused vertical space. These are reasons to avoid a stronger rating,
not grounds for inventing more features or modifying the accepted artifact.

## Coverage boundaries

- Advanced first-use/capture/filter/subset GUI combinations were not exhaustively
  run. The [63-case native regression](native-dark-run.txt), all 41 matrix rows and
  outer PASS cover module regressions separately; they are not a substitute for
  claims about every real click, text focus or narrow detail transition.
- The retained 240x360 view has only a small scrolling work area. Its contract
  name truncates, while the wider screenshots show the full identity. The footer
  stays usable. This is a minimum-size sanity pass, not comfortable dense editing.
- No final 560x900 capture, complete width/height/theme cross-product or full Light
  functional suite is claimed. Light sanity is evidenced at 560 and 320.
- Black title text on dark Qt window chrome after theme switching is visible;
  it is outside the correctly themed plugin content. The in-plugin product mark,
  context, controls and diagnostics retain correct contrast. No theme or source
  workaround was applied during this documentation review.
- The raw log contains Studio layout reentrancy warnings during resizing. This is
  not a claim that every Studio log line was warning-free.

Only STATUS.md, candidate.json, NATIVE_QA.md and this evidence record were changed
for this signoff. No Studio interaction, source/binary edits, rebuild, historical
file changes, git operation or publication. Parent owns the catalogue freeze.
