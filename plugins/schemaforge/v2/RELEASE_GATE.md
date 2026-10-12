# SchemaForge 1.1.0 release gate

Issue #17. **READY / PASS, Studio-side update confirmed.** Canonical asset
**84085408748744** was updated once on 2026-09-27 at 22:57 UTC (2026-09-28 Paris).
Studio returned **Successfully submitted!** with that same ID. No new asset.
Proof: [Studio success](../release/studio-update-1.1.0.png).

Final commercial artifact: `../dist/SchemaForge-v1.1.0.rbxm`, SHA256
`4c6768ba0c484164a576287b3cb623b8fd23c5ae90054b415e640c483a1906e9`.
The locally installed copy and clean publication place contain the exact production
sources. Only documentation/evidence changed after submission.

## Scope

Compact themed contract context and fixed primary actions; reference-first empty state;
separate project library; Expected/Actual/note findings; reason/field filters and exact
subsets; stable draft text/focus/scroll; contextual validation. Existing schema types,
format and missing-only repairs are preserved. Relevant project/schema/selection
changes invalidate Preview. No conversion, hierarchy repair, network or new product.

## Final-artifact evidence

- [Light native](../tests/native-v11-final-light.txt) and
  [Dark native](../tests/native-v11-final-dark.txt): each **91 PASS / 0 FAIL**,
  comprising 23 baseline, 35 engine and 33 layout/focus checks in actual Studio.
  Layout includes 24 measured ScreenGui cases, one native chrome calibration and
  eight actual DockWidgets at 240/320/400/560 widths and short/normal heights.
- [Fresh-process restart](../tests/native-v11-restart.txt): original disk-saved
  greenhouse contract, 8 targets / 6 findings, no writes. Not a newly edited GUI
  contract file-save/reopen claim.
- [GUI evidence](../tests/FINAL_GUI_V11.md): final-binary reference/load, live theme
  switch, short Library/Audit/Repairs, filtering/selection, read-only/stale Preview,
  exact two-default Apply, actual Edit-menu Undo/Redo and all three media.
- Reproducible artifact/source equality and compilation: PASS. Five production
  scripts; no QA/demo, external dependencies, HTTP, telemetry or private paths.

## Issue #17 acceptance

PASS identifies executed evidence, not a claim that every possible combination was
clicked. Native suites use the exact commercial modules in an isolated QA host.
Historical GUI evidence is explicitly separated in the linked report.

| # | Acceptance | Result and coverage |
|---|---|---|
| 1 | Existing greenhouse contract load | PASS, final GUI and fresh process |
| 2 | Loaded name/tag/scope visible | PASS, final GUI |
| 3 | 240/320/400/560 dock widths | PASS, final actual native DockWidgets, both themes |
| 4 | Short-height core actions | PASS, final native Rules and actual 400x360 Library/Audit/Repairs |
| 5 | Empty/reference-first | PASS, final native and actual reference capture |
| 6 | Existing schema compatibility/reload | PASS, final native and GUI |
| 7 | Long rules, focus/caret/selection/scroll | PASS, final native focused rerenders; real typing/switching on preceding theme-only-fix binary |
| 8 | Contextual invalid draft/correction | PASS, final native; actual keyboard correction on preceding binary |
| 9 | Mixed findings | PASS, final engine and real greenhouse |
| 10 | Expected/Actual/note | PASS, final GUI and screenshot |
| 11 | Reason filter | PASS, final native and GUI |
| 12 | Field/rule filter | PASS, final native and GUI |
| 13 | Exact affected subset | PASS, final native and actual Selection |
| 14 | Read-only Preview | PASS, final full greenhouse snapshot |
| 15 | Stale Preview blocks Apply | PASS, final native and disabled-button click |
| 16 | Two permitted greenhouse defaults | PASS, final Preview: Cost=25 on Cabbage_03/06 |
| 17 | Apply only those defaults | PASS, final real Apply and exact snapshot |
| 18 | Existing invalid values preserved | PASS, final native and GUI snapshot |
| 19 | Unrelated state preserved | PASS, final attributes/properties/tags/children snapshot |
| 20 | Native Undo | PASS, final native suites and real Edit menu |
| 21 | Native Redo | PASS, final native suites and real Edit menu |
| 22 | Saved contract after restart | PASS, final fresh process loading original disk-saved contract |
| 23 | Long/duplicate identities | PASS, final native identity/long-form checks; actual distinct selections on preceding binary |
| 24 | No product exception in successful path | PASS, monitored final suites and clean GUI history run |
| 25 | Exact artifact/source correspondence | PASS, reproducible bytes and per-source hashes |

**NON TESTED:** newly GUI-edited contract followed by file-save/Studio restart;
physical long-rule switching/duplicate-name click sequence not repeated after the
isolated theme-registration fix (final native regressions and affected theme GUI were
repeated). Creator Hub website configuration and public distribution are user-owned.
These are coverage boundaries, not observed unresolved product failures.

## Corrections and reruns

- Focus: DockWidget TextBox:IsFocused() is authoritative when the global input
  service omits the focused box; restore only the same logical input and ignore
  superseded deferred restores. Final native focused rerenders pass in both themes.
- Theme: weak-key style registration lost still-live native Instance wrappers;
  retain them until Destroying, then release. Persistent header/footer/input label
  colors now pass the actual Light-to-Dark switch after a long-lived session.
- Harness: native window chrome is measured without changing production sizes or
  loosening tolerances. One Dark host was limited to 638px instead of requested
  640px and failed four size assertions; a correctly sized fresh host passed all
  91 checks. This interrupted run is not counted as PASS.
- Earlier UI automation misrouting/delayed history callbacks produced helper failures;
  a fresh scene, serial menu operations and preinstalled observers verified real
  Undo/Redo. An older attempt to set Studio.Theme from Lua crashed Studio; checked-in
  runners only read theme settings, which were changed through native Settings.

## Final release state

Three genuine final-artifact screenshots: [media plan](../release/MEDIA_PLAN.md).
One existing-asset update: [publication record](../release/PUBLICATION.md).
No outstanding Studio release blocker. QA plugins removed from local Plugins.
No CurveForge or other product changes; no forum posts or Creator Hub web actions.
