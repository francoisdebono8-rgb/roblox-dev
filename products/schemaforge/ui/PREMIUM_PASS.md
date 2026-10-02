# SchemaForge / #23 / approved A-A-A visual pass

2026-10-02. **Visual review candidate, not reference READY.**

The user approved A/A/A: monochrome icons with labels in wide navigation,
compact collection rows with section-level additions, and continuous subtly
layered Light/Dark panels. The binding brief is
[`PREMIUM_VISUAL_PASS.md`](../../../docs/forge-studio-ui/schemaforge/PREMIUM_VISUAL_PASS.md).
Final aesthetic acceptance is still required before one final regression.

## Change and real mapping

| Presentation change | Existing source / action |
|---|---|
| Continuous rail, collection and inspector; 1px separators | Existing Rules/Audit/Repairs/Library navigation and narrow list/detail state |
| 46px rows; selected tint without a surrounding border | Actual attribute/child rules, findings, repair plan and stored contracts |
| Attribute/child counts with 28px `+` targets | Existing AddField/AddChild callbacks and 32-rule limits, unchanged |
| Contract settings row with tag/class/tag-rule summary | Current schema fields, requiredTags and forbiddenTags |
| Numeric constraints in row metadata | Actual min/max values; no inferred defaults |
| Monochrome wide navigation glyphs | Bundled Studio icons for list, search, check and library grid; no external asset dependency |
| Borderless paired Expected/Actual | Existing finding and repair-plan values |
| Ghost secondary action, 58px footer, subdued saved-state Save | Existing commands and enablement rules; no new writes or autosave |

Only `Modules/View.luau` changes production behavior, and only its presentation.
Main, Engine, Schema and Store hashes remain identical to the previous candidate.
Inspecting rows still does not call Preview, Audit or Studio Selection.
No new engine features, shared framework, public asset update or commercial media.

## Baseline and candidate

- Baseline: [`october-review/light-320x600-rules.png`](october-review/light-320x600-rules.png).
- Candidate SHA256: `59750f2a641fc27276adf2c78e278eef3eb86846558422c9d9ef3b982f502cad`.
- Manifest: [`../dist/candidate-1.2.0.json`](../dist/candidate-1.2.0.json).
- Native Rules Light 560x600: [`premium-pass/light-560x600-rules.png`](premium-pass/light-560x600-rules.png).
- Native Rules Light 320x600: [`premium-pass/light-320x600-rules.png`](premium-pass/light-320x600-rules.png).

Captures contain original native pixels, cropped only to the plugin content.
The separate disposable harness imports the final commercial binary and verifies
all five production sources exactly; it does not reconstruct the View.

Compared with the baseline, the large rounded work card is gone, the full-width
Add buttons become header affordances, collection spacing is tighter, and the
secondary footer action no longer has a button outline. Narrow mode retains its
dedicated inspector; wide mode retains context beside it. The existing structural
recomposition is preserved, not replaced by a new workflow.

## Validation for this iteration

| Check | Result |
|---|---|
| Luau compilation | PASS |
| Reproducible binary and five-source correspondence | PASS |
| Native final-binary mount and Rules Light geometry at 560x600 | PASS |
| Native final-binary Rules Light geometry at 320x600 | PASS |
| Actual native Rules captures at 320 and 560 | PASS |
| Controlled end-to-end GUI smoke | NON TESTED; foreground/input reliability prevented completion |
| Full 53-test / 41-row regression on this new binary | NON TESTED; deliberately deferred until visual acceptance |
| Full responsive/theme matrix, Undo/Redo | NON TESTED in this iteration |
| Human visual acceptance / gate 15 | PENDING |

The native log includes real tab activations and unchanged QA fixture values.
These do not establish a controlled editor/add/save/audit/preview walkthrough.
The previous 53/41 PASS belongs to the old binary, not this one.
No full QA campaign was rerun during the visual iteration.

## Local pattern inventory (provisional)

Not approved for extraction until this reference has been accepted visually.

| Pattern | Classification |
|---|---|
| Neutral Light/charcoal Dark tokens, semantic colors separate from accent | REUSABLE FORGE |
| BuilderSans identity 13, title 18, rows 13, metadata/sections 11 | REUSABLE FORGE |
| Insets 12, collection gap 2, inspector gap 6, controls 32, hit targets >=28 | REUSABLE FORGE |
| Continuous panes and 1px separators; no rounded pane containers | REUSABLE FORGE |
| 14px icon + label navigation; narrow underline-only modes | REUSABLE FORGE |
| 46px identity/metadata row, subtle selection and hover, no selected border | REUSABLE FORGE |
| Compact section label/count plus icon-only add with tooltip | REUSABLE FORGE |
| Grouped inspector, paired fields, local errors | REUSABLE FORGE |
| Stable primary/ghost secondary command, nonredundant tooltips | REUSABLE FORGE |
| Breakpoint 560; rail 128, collection 188+, remaining inspector | SCHEMAFORGE-SPECIFIC |
| Contract settings and attribute/child collections | SCHEMAFORGE-SPECIFIC |
| Explicit inspection vs Preview, Expected/Actual and missing-only repair | SCHEMAFORGE-SPECIFIC |

No gratuitous motion or web-only effects. The compact typography/spacing above is
an intentional override from the newer premium brief, not a claim that the old
quality-gate matrix has been re-executed.
