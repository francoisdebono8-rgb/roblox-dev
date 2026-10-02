# SchemaForge UI / issue #23

**REOPENED / VISUAL ACCEPTANCE FAIL. Not ready as the Forge Studio reference.**

Human review on 2026-09-29 rejected the first pass. Gate 15 is NOT PASS.
Current continuation: [OCTOBER_REVIEW.md](OCTOBER_REVIEW.md), 2026-10-02.
Do not reuse this UI as the PresetForge reference.

## Current Candidate

SHA256: `2f8436e1ee9590021e9c4ab86e6ef30363e2a59067108a2af24cd31247c07bda`.
Includes the remote quiet-navigation/hover corrections and the remaining
full-text-tooltip guard. Exact source/package correspondence and compilation
PASS. Studio 0.741.19.7411056 executed **53 PASS / 0 FAIL**, all **41/41** technical
matrix rows PASS on this exact artifact. [Evidence](october-review/native-technical.txt).

**GUI walkthrough, final comparative screenshots and human visual acceptance:
NON TESTED / PENDING.** The user cannot leave Studio available for reliable input
now. A successful native mount/geometry check is not graphical acceptance.
No publication, no other product work, no issue completion claim.

## Historical Second Pass

Second-pass candidate `647741f2...`: **53 native tests PASS / 0 FAIL**, 41/41
technical matrix rows PASS. Exact packaging/source correspondence PASS. The Rules
Light geometry probe passes five sizes; only its 320px native capture is retained.
The full GUI walkthrough, comparable Audit captures, Dark-theme review and human
visual acceptance remain **NON TESTED / PENDING**. No completion claim for #23.
See [SECOND_PASS.md](SECOND_PASS.md). These results do not certify the current UI.

## Historical First Pass (Superseded Visual Acceptance)

Verified 2026-09-28 in native Roblox Studio 0.740.19.7400003, Edit mode.
Canonical public asset **84085408748744 was not created, updated or otherwise changed**.
No commercial media, listing, price, outreach or other product was modified.

## Exact artifact

- Candidate: `../dist/SchemaForge-v1.2.0.rbxm`, 36,885 bytes.
- SHA256: `aaae698940ef22289de4a1d6a54465daf634492c7ebec83e46ec48cc1e3614fc`.
- Five production scripts, seven instances; exact source hashes in `../dist/candidate-1.2.0.json`.
- Reproducible Rojo rebuild and XML roundtrip: PASS; no QA, private paths or network payload.
- Main, Engine, Schema and Store unchanged from the technical baseline.
- No shared Forge UI framework or dependency introduced.

## Structural change

The approved mapping and BEFORE checkpoint are in [WORK_NOTE.md](WORK_NOTE.md).
The former stacked form is now a contract workspace: persistent identity/state,
navigation/project library, collection, selected detail, and stable action footer.
At 560px the collection and inspector are independent panes. At 240/320/400px,
Rules/Audit/Repairs/Library use list-to-detail navigation instead of compressed columns.

Rules separate contract settings, attributes and children. Findings carry concise
identity/category/subset state; Expected/Actual/note and exact safe additions live
in the inspector. Repairs show the actual engine plan. Library distinguishes a
selected entry from the loaded contract and separates destructive actions.

Local View primitives: themed labels/inputs/buttons, checkbox, segmented row, menu,
collection entry, inspector comparison, confirmation, tooltip, pane and footer.
They are local functions, not a reusable cross-product framework.

Certain issues corrected during implementation: render reentrancy could duplicate
navigation; saved contracts needed their refreshed storage token after Save;
old success/error wording needed invalidation; blank duplicate tooltips and an
unsupported arrow glyph were removed. No repair or contract semantics changed.

## Quality gates

| Gate | Result | Evidence / review |
|---|---|---|
| 0 Sequencing | PASS | #23 explicitly opens UI after all five technical V2s; baseline frozen before edits. |
| 1 Shell geometry | PASS | Four views, both themes, five native size probes; representative native visual review below. |
| 2 Spacing/type | PASS | Native screenshots: 12px outer inset, 8px normal gap, 4px compact gap, 32px controls, 6px radius, 1px input/divider borders; BuilderSans 12/13/14/16/18 hierarchy. |
| 3 Hierarchy | PASS | Product, contract, tag/scope, mode, selected row, document state and footer next action separately identifiable. |
| 4 Controls | PASS | One primary footer slot; segmented scope; boolean checkboxes; type/reason/field menus; separated confirmed removal. |
| 5 States | PASS | Native clicks/focus/typing, selected/disabled controls, empty/draft/dirty/ready/stale/blocked/applied and confirmations exercised. |
| 6 Responsive | PASS | Wide collection/detail vs narrow view navigation; no horizontal form scroll; fixed actions through Preview/Apply. |
| 7 Product signature | PASS | Contract, findings, paired Expected/Actual and bounded safe-addition inspector remain characteristic without title. |
| 8 Preview | PASS | Exact 3-change subset and 4-change full plans; counts, scope and write action; stale plan visibly disables Apply. |
| 9 Lists | PASS | Identity + concise metadata + selected marker/subset affordance; full paths and explanations in detail. 32-rule scroll tested. |
| 10 Restraint | PASS | Studio-compatible base, mint selection, separate error colors; no decorative cards/chrome/glow/media. |
| 11 Truth | PASS | Actual Store entries, Engine findings/plans and Selection; no fabricated metrics or mock actions. |
| 12 Screenshots | PASS | Exact-final native screenshots below, cropped only; no redrawing or recoloring. |
| 13 Regression | PASS | 53 native tests / 0 failures, 41 matrix rows, outer gate; additional real GUI Apply and Edit-menu Undo/Redo. |
| 14 Schema review | PASS | Tag/scope visible; category/Expected/Actual/note; wrong-type diagnostics explicitly have no automatic repair. |

Gate 2 exceptions: 54px two-line list rows deliberately exceed the single-control
height; header 82/118px and footer 88px have stable responsive tracks. Check marks
are 16px inside 32px interactive targets. No target is reduced to the glyph size.
Paired inspector values are one meaningful comparison group, not nested cards.

## Native regression and interaction

[Exact-final regression](after/native-technical.txt): **53 PASS / 0 FAIL**, all
**41/41** technical matrix rows PASS, outer gate PASS. Eight additional datatypes,
legacy schema loading/migration, scalar semantics, vectors, tags/children, persistence,
scope/freshness, transaction refusal/races, rollback and user-content preservation
remain covered. The moved tag editor has a separate added native test; coverage was
not removed to accommodate the layout. Compilation and source/package verification PASS.

[Dark session](after/native-dark.txt): actual Library select/Load; min-value edit
and Save; field filtering; duplicate-named targets distinguished; Select object;
subset excludes one finding; Preview shows 3 additions on 2 objects with fixture
unchanged. Fixture change makes it stale; disabled Apply does nothing. Fresh Audit/
Preview then actual Apply at 240x360 adds three attributes and one tag. Native
**Edit > Undo** restores missingCosts=3/missingTags=1; **Edit > Redo** restores 0/0.
Wrong-type Cost="unknown" and invalid GrowthRate=-2 remain unchanged. Old Applied
wording is invalidated by history. Fresh audit shows diagnostic-only findings.

[Light session](after/native-light.txt): actual loaded/selected library states;
contradictory tags show adjacent errors and disable Save, with the same focused
TextBox/caret/scroll; discard Cancel preserves edits, Confirm reloads saved data;
child editor and removal Cancel; 32-rule contract loaded, scrolled to rule 32,
name suffix accessible via End, selection retained and Add disabled at capacity.
Delete Cancel then Confirm removes only the disposable saved contract. Empty/New,
Capture reference, Save and reload are real clicks. Auditing an incomplete contract
shows Blocked with a readable tag error, not a Lua module prefix. Long object paths
wrap in detail. Reason=Wrong type gives 1/1 finding, Preview 0 disabled and
Select affected selects exactly Workspace.Greenhouse.PlantPot4.

Logs also record real native layout measurements. Initial fixture creation and
long-name fixture creation are QA setup, not claimed product-button actions.
The harness imports the commercial artifact and disables Main only on its QA copy;
View mounts those exact imported sources in a native DockWidget. QA is separate.

## Responsive/theme evidence

| View | Dark | Light |
|---|---|---|
| Rules | 240x360 / 320x640 / 400x640 / 560x640 / 560x900 PASS | Same five PASS, including 32 rules |
| Audit/detail | Same five PASS | Same five PASS, including long object identity |
| Repairs | Same five PASS | Same five PASS |
| Library | Same five PASS | Same five PASS |

These are measured native geometry checks, not a claim of 40 separate screenshots.
Actual visual/click review covers 240x360, 320x640, 400x640 and 560x640 in both themes.
560x900 is a geometry-only extension: this Mac cannot display a full 900px client
without clipping native chrome. It uses the same wide composition and was checked
for layout/targets/footer, not falsely claimed as a full-height captured walkthrough.

Representative exact-final captures (Retina pixels, 2 pixels per UI px):

- [Dark 320 rules](after/dark-320-rules.png), [Dark 560 rules](after/dark-560-rules.png).
- [Dark 560 findings/detail](after/dark-560-audit.png), [Dark 560 exact plan](after/dark-560-preview.png).
- [Dark 240 stale](after/dark-240-stale.png), [Dark 560 library](after/dark-560-library.png).
- [Light 560 rules](after/light-560-rules.png), [Light 560 invalid tags/focus](after/light-560-blocked.png).
- [Light 320 long rule](after/light-320-rules-long.png), [Light 320 empty](after/light-320-empty.png).
- [Light 400 long diagnostic](after/light-400-audit-long.png), [Light 240 plan](after/light-240-preview.png).
- [Light 560 exact plan](after/light-560-preview.png), [Light 560 diagnostic-only](after/light-560-diagnostic.png).

Compare [before 560 Dark](before/dark-560-rules.png) with after 560 Rules/Audit:
the old full-width stacked controls become a persistent collection and inspector.
Compare [before 320 Dark](before/dark-320-rules.png) with after 320 Rules: schema
settings no longer precede every editor; the selected item opens a dedicated view.
Before Light evidence is also retained. No screenshot is a simulated interface.

## Limitations and excluded evidence

- Tool `noWindowsAvailable`/ineffective drags required a clean QA Studio restart;
  failed input attempts are not counted as tests. Final successful sessions are linked.
- One mislabeled 320 crop of a 560 view was rejected and is not included.
- Intermediate pre-final runs/screenshots do not establish final acceptance.
- Early Command Bar Undo experiments were invalid because the command itself adds
  history. Only the final actual Edit-menu Undo/Redo is counted as GUI acceptance.
- Studio's built-in ExplorerPlugin emitted unknown-instance selection errors for the
  transient QA fixture; Selection:Get verified the correct object. Native text-bound
  reentrancy warnings also occurred. No SchemaForge source exception or geometry
  failure was found in the final sessions. This is not an "Output entirely empty" claim.
- No publication gate was attempted: #23 explicitly forbids it.

## Reproduce

1. Run `python3 products/schemaforge/tools/verify_candidate.py --rojo /path/to/rojo --build`.
2. Build the native functional gate using `products/schemaforge/tests/build_technical_gate.py`;
   run it in its opted-in empty local place. Keep its output separate from historical #20 results.
3. Run `python3 products/schemaforge/ui/build_gate.py --rojo /path/to/rojo` and install
   its generated QA plugin only for the disposable opted-in place.
4. Give the floating window 560x640 client space (664px total height on this Mac).
   Use the QA bridge `game.ServerStorage.SchemaForgeUIQA:Invoke("matrix")` for native
   measurements and `Invoke("resize", width, height)` for review. Run setup through
   `task.defer` outside Command Bar recordings. Use real native controls for workflows.
5. Capture the real window; `crop_capture.py` only crops pixels. Inspect each image
   before accepting its label. `collect_log.py` retains product-prefixed evidence only.
6. Remove the temporary QA plugins and restore the original Studio theme preference.

Original theme preference Default (Light) restored. Temporary QA plugins removed
after completion. Historical public binaries/media and unrelated local changes preserved.
