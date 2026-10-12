# SchemaForge #23 / accepted refinement

2026-10-03. Production changes are limited to View. No public asset update,
shared framework, other-product work, commercial media or new engine behavior.

## Visual review

The user rejected the recovered [previous wide Audit](final-review/dark-560-audit.png)
and asked for stronger readability, restrained effects and precise alignment.
The [new wide Audit](refined-review/dark-560-audit.png) and
[compact diagnostic](refined-review/dark-320-detail.png) were then explicitly
accepted: "Oui, passe a la validation finale".

Compared with the approved reference composition: the real contract/list/detail
structure is retained; filters are compact side-by-side menus rather than extra
full-width rows; Expected/Actual use equal-height surfaces; a stronger diagnosis
title and brighter wrapping note establish hierarchy; the bounded safe repair
shows its operation once. Native BuilderSans is retained. Navigation glyphs use
their actual artwork bounds, centered with captions/counts. No decorative glow,
animation, reference artwork or new font dependency is included.

The reference's static search/favorites/extra library entries are not fabricated.
All visible counts, filters, selections and operations come from the real engine.
The canonical Forge brand convergence remains a separate #25 task.

## Corrections

- Normalize bundled navigation-icon margins and center checkbox marks.
- Preserve hover feedback after pointer release while still over a button.
- Synchronize rule/child editor titles and numeric list summaries during typing,
  retaining the same focused TextBox, caret and scroll position.
- Keep comparison bottoms aligned when either value wraps; add a geometry assertion.
- Compact filters, improve diagnostic hierarchy and remove duplicated repair text.

## Exact candidate

SHA256: `542131178c45716fca27d12f7b1ec8678fae3c414e6d33645cf23229f65cb126`.
The reproducible binary contains five production sources / seven instances.
Main, Engine, Schema and Store remain byte-identical. The native QA harness imports
this commercial artifact and verifies source equality; QA is packaged separately.

## Executed focused checks

[Native log](refined-review/native-smoke.txt), Studio 0.741.19.7411056, Dark:

- Name Cost -> CostX -> Cost updates the inspector and list without losing focus.
- Min 0 -> 1 -> 0 updates list metadata live, same TextBox/caret/scroll.
- Actual Audit button: 7 checked / 8 findings. Reason Missing: 3 results.
- Selecting a diagnostic does not re-audit or create a plan.
- Actual Preview: 3 additions / 3 objects; fixture remains missingCosts=3,
  missingTags=1. Actual Apply: missingCosts=0, missingTags=1. Invalid Cost and
  GrowthRate values remain unchanged.
- Actual Edit > Undo restores missingCosts=3; Edit > Redo restores 0. The excluded
  tag stays missing. History invalidates the plan and old success wording.
- Rules/Audit/Preview measured geometry at 320 and 560; Rules and empty Repairs
  additionally exercised through the five-size matrix. No geometry failure.

Full native regression: **53 PASS / 0 FAIL, 41/41 matrix rows PASS**, outer gate
PASS on this exact candidate. [Evidence](refined-review/native-technical.txt).
This was run once after human acceptance, not inherited from an older build.
Final theme/size and extended GUI coverage: **PASS**.

| Final gate group | Result | Evidence |
|---|---|---|
| Source/binary equality, package hygiene, compilation | PASS | Five exact sources / seven instances, unchanged engine modules |
| Human visual acceptance | PASS | Explicit approval of final Dark 320/560 diagnostic screenshots |
| Focused real GUI edit/filter/Preview/Apply/Undo/Redo | PASS | `native-smoke.txt`, fixture readback and actual native menu actions |
| Full technical regression | PASS | 53/0 and 41/41, `native-technical.txt` |
| Required representative screenshot set | PASS | Dark 320/560; Light 560; Light/Dark 240x360 |
| Rules layout in both themes | PASS | Five measured sizes each, plus actual short/narrow/wide captures |
| Complete per-view/theme matrix | PASS | Rules, Audit, populated Repairs, Library; five native sizes in both themes |
| Extended final GUI walkthrough | PASS | Library mutations, long data, empty/blocked/stale states; evidence below |
| #23 ready | YES | All applicable gates PASS; no publication |

After restart, CUA could capture the floating window but its clicks returned
`noWindowsAvailable`; System Events coordinate clicks had no effect. The user
explicitly authorized a macOS mouse helper restricted to the QA Studio process
and bounded window coordinates. This recovered actual click/scroll access.
Failed attempts are not PASS. Dark was restored through native Studio Settings;
both temporary QA plugins were removed after collecting evidence.

Final screenshots: [Dark Rules 320](refined-review/dark-320-rules.png),
[Dark Rules 560](refined-review/dark-560-rules.png),
[Light Rules 560](refined-review/light-560-rules.png),
[Light short](refined-review/light-240-rules.png),
[Dark short](refined-review/dark-240-rules.png), plus accepted Audit/detail above.
The first Light raw capture clipped the footer because the native window chrome
reduced the client height; it was rejected and recaptured at the correct height.

## Final extended native walkthrough

[Extended log](refined-review/native-extended.txt), same final binary throughout:

- Library: select entry, Load contract, edit Min, Save, restore Min, Save.
- Preview in Light: one exact missing Cost addition; fixture stays missingCosts=1.
  Mutating the disposable target makes the plan Stale. Clicking disabled Apply
  does not change missingCosts=1; no old success wording remains.
- Delete saved contract opens an explicit red confirmation. Cancel retains it;
  reopening and Confirm removes it and shows an empty draft/library.
- A real 32-rule contract was saved by the separate QA harness and loaded via UI.
  Mouse-wheel scrolling reaches rule 32; opening its editor, changing its type
  through the native menu to Vector3 and returning retains the list position.
  The vector constraints appear and Save edits becomes available. Save succeeds.
- New opens an empty draft. Actual Run audit shows Blocked with the readable
  target-tag requirement, without a raw Lua prefix. Capture with ReferencePot
  selected produces its three actual attributes, then Save succeeds.
- Duplicate names were present in the initial fixture and distinguished by
  numbered identities. Long contract/rule names were reviewed at 400px, with
  truncation in identity labels and editable values in the inspector.
- Inspection stays separate from explicit Preview and Studio Selection. The
  engine-call trace changes only when Audit/Preview is requested, not while
  navigating the rule/library inspectors.

Additional actual captures: [Light Audit](refined-review/light-560-audit.png),
[Light Preview](refined-review/light-560-preview.png),
[Dark Preview](refined-review/dark-560-preview.png),
[Stale](refined-review/light-560-stale.png),
[Confirmation](refined-review/light-560-confirmation.png),
[Long list after editor return](refined-review/light-400-long-scroll.png),
[Vector editor](refined-review/light-400-vector-editor.png),
[Blocked](refined-review/light-400-blocked.png),
[Dark Library](refined-review/dark-400-library.png).

## Final quality gates

| Gate | Result | Exact-final evidence |
|---|---|---|
| 0 Sequencing | PASS | #23 opens the UI phase; original baseline/mapping retained in WORK_NOTE.md |
| 1 Geometry | PASS | Four views, Dark/Light, 240x360 / 320x640 / 400x640 / 560x640 / 560x900 native probes |
| 2 Spacing/type | PASS | BuilderSans hierarchy; 12px outer inset, compact rhythm, centered icons and equal comparison bottoms |
| 3 Hierarchy | PASS | Real contract/tag/class/scope, selected item, state and stable primary footer |
| 4 Controls | PASS | Scope segments, menus, checkboxes; one primary action; separated confirmed delete |
| 5 States | PASS | Focus/caret, hover/press, selected/disabled, draft/dirty/ready/stale/blocked/applied, empty and confirmation |
| 6 Responsive | PASS | Wide rail/list/detail; narrow list-to-detail; 400px scroll/return plus actual short 240px captures |
| 7 Signature | PASS | Contract, finding diagnosis, Expected/Actual and bounded additive repair |
| 8 Preview | PASS | Actual 3-subset/4-full/1-addition plans; read-only readback; stale write disabled |
| 9 Lists | PASS | Identity/metadata rows, duplicate identities, 32-rule mouse scroll and preserved position |
| 10 Restraint | PASS | Quiet continuous panes, restrained selected/repair surfaces, no decorative chrome |
| 11 Truth | PASS | Real final Engine/Store data and explicit actions; no fabricated reference controls |
| 12 Screenshots | PASS | Real final 320/560, 240x360, Light/Dark, additional 400px; crop only |
| 13 Regression | PASS | 53/0, 41/41, outer gate; actual GUI Apply and native Undo/Redo; reproducible binary |
| 14 Schema review | PASS | Categories, Expected/Actual/note and exact repairability; invalid values remain unchanged |
| 15 Human acceptance | PASS | User explicitly accepted the actual final Dark wide/compact diagnostic captures |

The five-size probes measure actual native GUI instances, not browser mockups.
560x900 is geometry-only because the physical desktop cannot show that full client
height; it is not claimed as a full-height screenshot. Visible 240/320/400/560
captures and manual review supplement the probes. They do not imply that every
possible data combination was exhaustively clicked at every size.

Typography exceptions: 11px compact filter/nav-count/category metadata and 12px
inspector labels preserve density in the 560px three-pane layout. Targets remain
at least 28px; 46px two-line rows and the fixed 58px footer have separate roles.
Long identity labels deliberately truncate and expose their value through the
existing tooltip/editor rather than expanding the whole shell.

## Local pattern inventory

| Pattern | Classification | Contract |
|---|---|---|
| Neutral theme tokens, separate semantic colors | REUSABLE FORGE | Light/Dark backgrounds, readable muted text, mint not used for errors |
| BuilderSans hierarchy | REUSABLE FORGE | 11-12 metadata, 13-14 rows, 15 values, 18 work title; native font only |
| Continuous panes and thin separators | REUSABLE FORGE | 12px outer inset, compact 4px inspector rhythm, no floating page cards |
| Navigation row and count | REUSABLE FORGE | 32px target, centered 14px artwork, restrained selected fill |
| List identity/metadata | REUSABLE FORGE | 46px two-line row, no redundant hover label, compact section add action |
| Inline property / paired values | REUSABLE FORGE | 30px controls, full-row checkbox hit area, stable focused input |
| Footer / command hierarchy | REUSABLE FORGE | Fixed 58px, quiet secondary and one primary, precise hover/press/focus |
| Tooltip policy | REUSABLE FORGE | Only hidden/truncated content or icon-only/unfamiliar affordance |
| Narrow list-to-detail navigation | REUSABLE FORGE | No squeezed columns below 560px; product-specific pane allocation |
| Findings comparison and safe-addition block | SCHEMAFORGE-SPECIFIC | Real Expected/Actual, explicit Preview, no inspection side effects |
| Contract/rule/child editors | SCHEMAFORGE-SPECIFIC | Existing schema model, validation and storage safety unchanged |

Reusable means a candidate for a second consumer, not an extracted framework.

## Evidence limitations

Screenshots are real Retina window captures, cropped only, never redrawn/resized.
`final-review` is the rejected prior binary; `refined-review` is this candidate.
Changing Studio.Theme from Command Bar caused a native Studio UI-thread assertion
and restart. This is recorded as a QA environment failure, not a product PASS or
a SchemaForge exception. The restarted Light session mounted the same binary;
theme restoration through native settings succeeded without a crash.
Two direct Command Bar calls to the QA long-fixture writer were rejected because
the Command Bar already owned an Undo recording. Deferring the QA fixture setup
outside that recording succeeded; production safety was not bypassed or edited.
An incidental click applied the four-change disposable preview while navigating
to Settings; it is not counted as the deliberate Apply/Undo test. That test is
the separate three-change sequence in native-smoke.txt. These environment/setup
events mean this report does not claim an entirely error-free Studio session.
