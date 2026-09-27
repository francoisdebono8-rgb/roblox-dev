# SchemaForge 1.1.0 release gate

Issue #17. Canonical asset `84085408748744`; never create another asset.
2026-09-27, Studio 0.740.19.7400003, Edit mode. **NOT READY for submission:**
implementation and final native regression suites pass, but the complete final-binary
GUI/media acceptance remains open. No 1.1.0 submission was attempted.

Final artifact: `../dist/SchemaForge-v1.1.0.rbxm`, SHA256
`92c6924b897eeaefc9940f14ebf8a6e6d7dd24926778d83cb78cca0df377f653`.
The local installed plugin and publication place contain these exact production sources.

## Scope

Compact themed contract header and fixed primary actions; reference-first empty state;
separate project library; expected/actual/note findings; reason/field filters and exact
finding subsets; stable draft text and scroll restoration; contextual validation.
Existing schema format/types and missing-only repair semantics are preserved.
Audit snapshots reject changed schemas, roots, tagged attributes/tags and required child
paths. Selection and saved-contract changes also invalidate the panel's repair preview.
No conversion, child repair, network service or new product.

## Executed evidence

- [Final native run](../tests/native-v11-final-dark.txt): **23 baseline + 35 extended
  engine + 33 layout/focus checks PASS, 0 FAIL**, exact final artifact. The layout
  count includes 24 measured ScreenGui cases, one native chrome calibration and eight
  actual DockWidgets. Native window content widths were 240/320/400/560; heights
  360 and 639 (requested 640, within the declared one-pixel tolerance).
- [Restart](../tests/native-v11-restart.txt): fresh Studio process, original disk-saved
  greenhouse contract loaded by final modules; 8 targets / 6 findings, no writes.
  This is not a new GUI-edited contract save/reopen test.
- [Real greenhouse GUI](../tests/GREENHOUSE_V11.md): capture/load, filters/subset,
  read-only/stale Preview, exact two-default Apply and actual Edit Undo/Redo executed
  on the **pre-focus-fix** artifact `9a3fb232...`. Three real screenshots were captured.
- [Light](../tests/native-v11-light.txt) and [dark](../tests/native-v11-dark.txt)
  pre-focus-fix runs each passed 23 + 35 + 24 checks. Only Dark was rerun on the final
  artifact. These files record their own hash; they are not relabelled as final.
- Binary/source equality, production-only hierarchy and Luau compilation: PASS.
  Five production scripts, no QA/demo/network requests, dependencies or private paths.

## Issue #17 acceptance

Final-native PASS means the specific assertion really ran in Studio, not that a GUI
click was simulated. GUI below refers only to the pre-focus-fix commercial artifact.
NON TESTED never implies an observed product failure.

| # | Acceptance | Final native | Real GUI before focus fix |
|---|---|---|---|
| 1 | Existing greenhouse contract load | PASS, fresh process | PASS |
| 2 | Loaded name/tag/scope immediately visible | NON TESTED, loaded-GUI path | PASS |
| 3 | Exact 240/320/400/560 widths | PASS, actual DockWidgets | NON TESTED, only 247/299/356 observed |
| 4 | Short-height core actions | PASS for Rules; other views NON TESTED | NON TESTED at short height |
| 5 | Empty/reference-first | PASS, rendered Capture control | PASS, actual capture |
| 6 | Existing schema compatibility/reload | PASS | PASS |
| 7 | Long rules, focus/caret/selection/scroll | PASS, native focused rerenders | NON TESTED, complete rule-switch path |
| 8 | Contextual invalid-draft validation | PASS, rendered errors/correction | NON TESTED |
| 9 | Mixed findings | PASS, greenhouse and engine fixtures | PASS |
| 10 | Expected/Actual/note | PASS, structured finding data | PASS, visible |
| 11 | Reason filter | PASS, engine | PASS |
| 12 | Field/rule filter | PASS, engine | PASS |
| 13 | Exact affected subset | PASS, engine/Selection | PASS |
| 14 | Read-only Preview | PASS | PASS, full greenhouse snapshot |
| 15 | Stale Preview blocks Apply | PASS, engine | PASS, disabled Apply click |
| 16 | Two permitted greenhouse defaults | NON TESTED, final greenhouse Preview | PASS |
| 17 | Apply only permitted defaults | PASS, native fixtures | PASS, greenhouse |
| 18 | Existing invalid values preserved | PASS | PASS |
| 19 | Unrelated state preserved | PASS | PASS, full greenhouse snapshot |
| 20 | Native Undo | PASS, real history transaction | PASS, Edit menu |
| 21 | Native Redo | PASS, real history transaction | PASS, Edit menu |
| 22 | Saved contract after restart | PASS, existing disk-saved contract | NON TESTED, fresh GUI save/reopen |
| 23 | Long/duplicate identities distinguishable | PASS, engine identities/long forms | NON TESTED, complete duplicate-name UI |
| 24 | No product exception in successful path | PASS, monitored native suites | PASS, product path; helper failure below |
| 25 | Exact artifact/source correspondence | PASS | Pre-fix hash recorded separately |

## Corrections and failed attempts

Actual DockWidget input had `IsFocused() == true` while the global input service did
not identify it. View now snapshots focus using TextBox:IsFocused(), restores only
the same logical rule/input, and ignores superseded deferred restores. The eight
native focus/caret/selection/scroll regression cases pass on the final binary.
The earlier real-typing helper's global-focus assertion was a harness failure, not
proof of lost typing focus; the helper now uses the same correct native query.

An initial final-binary dock test failed eight size assertions because macOS window
chrome reduced the requested client area by 2 x 24 pixels. The harness now measures
that overhead first; all eight requested content widths pass without relaxing their
existing tolerance. No production sizing was changed to make the tests pass.
An earlier QA attempt to set Studio.Theme from Lua crashed Studio; it was removed.
Theme settings are read-only in every checked-in QA runner.

## Remaining release blockers

1. Final installed binary: finish real long-rule switching/caret/draft validation,
   duplicate-name inspection and short-height Audit/Repairs/Library interaction.
2. Revalidate the greenhouse GUI path and Light theme after the isolated focus fix;
   recapture the three screenshots using that exact final artifact. Current PNGs
   are genuine 1.1.0 pre-fix captures, not final-artifact evidence.
3. Only after these pass, perform one existing-asset update of **84085408748744**
   and retain the success proof. No new-asset flow is authorized.

After the user's three-minute foreground window, Safari was again visible and Studio
exposed no accessible window; CUA also timed out. Background native suites and the
restart check still ran successfully. No graphical action or submission is inferred
from those background results. QA plugins were removed from the local Plugins folder.

API references checked: [Studio theme](https://create.roblox.com/docs/reference/engine/classes/Studio),
[native history](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService).
No competitor-superiority claim, new outreach target or public forum post is introduced.
