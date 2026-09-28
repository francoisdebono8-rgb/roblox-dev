# SchemaForge UI / issue 23

## Checkpoint 1 (before View edits, 2026-09-28)

Issue 23 explicitly opens this programme after the five functional V2 gates.
Baseline source commit: a756a6b4b716e411cec5e20e9c48667ccef7db31.
Baseline artifact: SchemaForge-v1.2.0.rbxm, SHA256
`1ffab441b8ee88db2372e113776d2fb7cfdb5b890e8576cbae36ff378229fbec`.
Fresh native Studio 0.740.19.7400003 execution: **52 PASS / 0 FAIL**,
41 matrix rows PASS, outer gate PASS. See `before/native-technical.txt`.

Actual native DockWidget baseline captures: `before/{dark,light}-{320,560}-rules.png`.
Client viewports are 320x640 and 560x640; image files retain Retina pixels and
22px native window title bar. All four images use the same three-attribute,
one-child Greenhouse contract fixture. The harness imports the candidate binary
without changing any Source; only its Main.Disabled is set on the QA copy.
Schema.new is temporarily seeded for the initial draft, not a claimed GUI load.
Dark/Light are actual Studio themes, not a recolored screenshot. Original Studio
theme preference is Default; restore it after final QA.

### Current structure and problems

128px fixed header; one scroll body; 100px footer. Rules stacks contract settings,
tag constraints, field picker and the entire selected editor. Audit stacks filters,
selection actions and six expanded findings per page. Repairs repeats unstructured
multiline changes. Library is a separate button containing capture/new/load/delete.
At 560px the extra width only stretches fields. Findings dump identity/path/reason/
Expected/Actual/note/actions; rules cannot be scanned as a collection.

### Binding target

The approved SchemaForge structure in PRODUCT_STRUCTURES.md is the mockup.
Visual thesis: a quiet mint-accented contract review workspace, with the collection
and selected diagnostic doing most of the work. No hero, imagery or decorative
cards are appropriate for this native diagnostic tool.
Content plan: compact persistent contract identity; named navigation and real project
library; concise rule/finding rows; selected editor/diagnostic; bounded repair review.
Interaction thesis: wide master/detail, narrow list-to-detail navigation, stable
write/review action slot, persistent independent pane scroll and draft caret.

| Target/mockup element | Existing source / action | Implement |
|---|---|---|
| Contract header | schema.name/tag/className, loadedName, scope, dirty/stale | yes |
| Findings count/list | Engine.audit(schema, roots) | yes |
| Reason/field filters | Engine.filteredIssues(audit, reason, field) | yes |
| Selected finding | actual finding table and engine identity | yes |
| Expected / Actual | finding.expected / finding.actual | yes |
| Designer note | finding.description / saved rule.description | yes |
| Repairability | finding.fix, only missing defaults/required tags | yes |
| Suggested repair | Engine.preview(audit, {finding}).changes | only actual change |
| Preview changes | Engine.preview(audit, exact current subset) | yes |
| Apply | Engine.apply(plan, ChangeHistoryService) | same safeguards |
| Rules collection/editor | schema.fields / schema.children; Schema.validate | yes |
| Capture | Schema.capture(single allowed Selection reference) | yes |
| Library | Store.list/load/save/delete, expected saved token | yes |
| Select affected | actual unique finding instances via Selection:Set | yes |
| Unsupported metrics/history/severity/runtime | no engine source | omit |

Only Store.save/delete and Engine.apply mutate project data. Capture/audit/preview,
filtering and editing the draft are read-only with respect to project configuration.
Saved-entry token checks, isFresh polling, scope selection guard, exact subset and
native history must remain. No Engine/Schema/Store contract change is authorized.

## Planned structural changes

560px: compact navigation/library rail, collection and independent selected detail.
Below 560px: four named modes and a list/detail back navigation; never three squeezed
columns. Rules contract settings become one selectable collection item, not a form
prefix on every field. Attribute and child collections have distinct headings.
Audit rows contain field, object identity, category and a subset checkbox. Expected/
Actual and notes only appear in the inspector. Repairs is an exact-plan review.
Footer retains one fixed primary slot through Audit -> Preview -> Apply, plus a
secondary action and a concise status. Destructive actions require confirmation.

All primitives remain local to SchemaForge. No shared Forge UI framework is planned.
Screenshots are internal QA only. Public asset 84085408748744 must remain untouched.

## Execution status

Checkpoints 1-5 complete. The structural implementation, final native regression,
responsive/theme matrix and gates 0-14 are recorded in [RELEASE_STATUS.md](RELEASE_STATUS.md).
The public asset remains unchanged; this issue delivers an unpublished UI candidate.
