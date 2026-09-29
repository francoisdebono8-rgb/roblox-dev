# Issue 23: reference fidelity, second pass

## Baseline frozen before edits

2026-09-29. Baseline commit acdfba0b6bbd1c0c2a2285cafd762cd984ede3df;
artifact SHA256 aaae698940ef22289de4a1d6a54465daf634492c7ebec83e46ec48cc1e3614fc.
Existing `after/` screenshots are the real native baseline for this pass, not an
accepted visual reference. Its executed 53 native tests and 41 matrix rows remain
historical evidence; repeating that audit before editing adds no useful coverage.
Human visual acceptance failed: flat surfaces, weak diagnostic anchor, generic
rows/controls, oversized header/footer and an insufficiently composed inspector.

Binding sources: issue 23 comments through 2026-09-29, REFERENCE_SPEC.md,
REFERENCE_MOCKUP.html and gates 0-15. The local HTML is read; browser rendering is
blocked by the browser tool's file-URL policy. The user subsequently supplied the
actual rendered reference at 17:50 Paris; its crop is retained as
`second-pass/reference-user-560.png`. Its encoding artifacts are not UI requirements.

Visual thesis: a compact diagnostic inspector, with findings as the anchor and
contract identity, expected/actual and safe-addition decisions in a clear hierarchy.
Content: 68px context header; 124px rail; 186px collection; remaining inspector;
62px anchored command bar. Narrow: tabs, list/detail/back, same command slot.
Interaction: inspection never runs a plan; explicit Preview only; a changed plan
becomes stale, never silently refreshes. Hover/focus are restrained and immediate.

| Reference element | Real source/action | Implementation contract |
|---|---|---|
| Contract context/status | schema, loadedName, dirty, stale, plan | compact identity and state chip |
| Rail/counts/library | fields, children, audit, plan, Store.list | quiet navigation, real counts/entries |
| Finding rows | Engine.audit / filteredIssues | status rail, identity/reason, independent subset |
| Filters | existing reason and exact field filters | compact menus, no invented full-text search |
| Inspection | selected finding/rule/library | local detail only; no audit/preview/Selection |
| Expected/Actual | finding.expected/actual | paired values, semantic actual color |
| Suggested repair | finding.fix.action/value | recorded suggestion, not an engine plan |
| Preview | Engine.preview(audit, subset) | sole plan-creation call, explicit command |
| Select in Studio | Selection:Set | explicit secondary action |
| Rules inspector | existing rule schema | identity/type, paired bounds, repair, note |
| Library actions | existing Store/capture/new | explicit load/write, confirmations unchanged |
| Mockup sample counts/contracts | none | use real fixture results, never fabricate |

The HTML's 8-11px text and pill-shaped noninteractive samples are adapted to
readable BuilderSans metadata and minimum 28px interactive targets. No fake
search or 3D preview. All components stay local; engines and public asset unchanged.

## Implemented Interpretation

| Requested area | Second-pass implementation |
|---|---|
| Silhouette | 68px wide header, 124/186/remaining columns, 62px command bar; 104px header includes narrow tabs. |
| Header | Product is a small identity; contract is the 18px work title; tag/class/scope share one line; compact status. |
| Rail | Transparent inactive rows, real counts, small selected marker; real library entries with no filled button stack. |
| Findings anchor | Independent collection; checked/findings summary, exact reason/field menus; no invented search. |
| Rows | 54px two-line identities, precise selected border/tint, semantic rail, independent inclusion checkbox. |
| Inspector | Finding/category, selected identity/path, explicit Select in Studio. No ViewportFrame. |
| Expected/Actual | Paired adjacent value cells; small captions, strong values, semantic Actual color. |
| Note | Attached 56px default text area with full tooltip; not an empty card. |
| Suggested repair | Recorded `finding.fix` only, bounded additive operation; hidden when stale; no Engine.preview on inspection. |
| Command bar | Fixed right primary slot, left secondary, bounded summary; short labels at 240. |
| Rules | Identity/type, constraints, repair, note; paired min/max and vector bounds; compact transparent checkbox rows. |
| Density | 12px outer, 8px pane inset/gaps, 32px fields; popup menus no longer expand the entire editor vertically. |
| Surfaces | Base, work pane, raised inspector, selected/focus; deliberate Light/Dark palettes. |
| Accent/type | Restrained mint; BuilderSans 11/12/13/14/15/16/18 roles; errors/warnings remain semantic. |
| Narrow | Tabs and one list/detail surface, back navigation, fixed actions; no side rail below 560. |

Selection-only row handlers preserve workflow messages as well as the plan; no
automatic audit, preview or Studio Selection call. The only `Engine.preview` call
site is the explicit footer command. Filter/subset/schema/scope changes invalidate
an existing Preview instead of silently discarding/regenerating it. A stale plan
retains its original scope label. Engines and persistence format remain unchanged.

Deliberate deviations from the HTML: no fabricated sample contracts/counts or
full-text search; exact field/reason filters and two-way scope control represent
the actual engine. The 28px subset control takes space that the mockup used for a
tiny FIXABLE badge; semantic rail and inspector repairability remain. Text is
readable at Studio scale rather than copying the mockup's 8-10px samples. Work
panes are continuous rather than floating cards. These choices still need native
Audit comparison and human acceptance, not merely source review.

## Exact Candidate and Executed Evidence

Artifact: `../dist/SchemaForge-v1.2.0.rbxm`.
SHA256: `647741f255518a26e39e4b0a79d564ce2bd8bd0ed50531a25d5302917e12e300`.
Main/Engine/Schema/Store hashes are unchanged from the baseline. No shared framework,
dependencies, commercial media or public-asset action.

| Check | Result | Evidence |
|---|---|---|
| Compile and exact artifact/source equality | PASS | Luau compile; reproducible Rojo binary and XML source comparison; five production scripts. |
| Full native functional regression | PASS | `second-pass/native-technical.txt`: 53 PASS / 0 FAIL, 41/41 matrix rows, outer PASS, Studio 0.740.19.7400003 at 16:04 UTC. |
| Typed/tag editor validation after regrouping | PASS | Same native assertions retained, recursively locating grouped controls; no coverage removed. |
| Rules Light geometry | PASS (geometry only) | `second-pass/native-light-rules.txt`: 240x360, 320x640, 400x640, 560x640, 560x900. |
| Rules 320 native rendering | CAPTURED, NOT ACCEPTED | `second-pass/light-320-rules.png`, 640x1280 Retina pixels; crop only. |
| Finding/rule/library inspection counters | NON TESTED | Instrumentation added outside commercial candidate; no successful product clicks in this session. |
| Audit/Preview/Apply GUI, caret/scroll, all states | NON TESTED | Old first-pass clicks are not substituted for this new candidate. |
| Full final Dark/Light screenshot matrix | NON TESTED | Dark attempt interrupted by native Studio crash; no Dark PASS. |
| Reference side-by-side Audit comparison | PENDING | User's rendered reference received; matching real Audit screenshots still required. |
| Gate 15: human visual acceptance | PENDING | No human acceptance of this candidate. Issue remains open. |

## Concrete Blockers and Resume

Native AX menu/Command Bar actions worked, but coordinate clicks on the plugin
repeatedly returned `noWindowsAvailable`, including after clean launches and a
right-docked QA attempt. A full-display observation showed Safari in a separate
fullscreen space. The user was asked to leave Studio visible; no confirmation
arrived during this pass. No failed click is counted as an executed GUI test.

Changing Theme through Command Bar while also requesting the geometry matrix
terminated Studio (process exit 133). No native crash root cause is established;
this is not attributed to product code and no Dark result is claimed. On resume,
switch theme using Studio Settings with the UI accessible, separately from tests.
The persisted theme preference was restored to Default for the next launch;
temporary QA plugins were removed. The post-crash Home window was left alone
after Studio refused a normal Quit request. Explorer/Properties were closed only
for the docked QA layout and should be reopened for the next native session.

Next: build/install the disposable UI gate; leave Studio foreground; inspect the
real Audit/Rules/Library/Repairs at 560/320 and narrow sizes in both themes; verify
inspection counters and stale semantics through real clicks; capture comparable
Audit evidence and review against the supplied reference. Iterate as required.
Gate 0 and native gate 13 have evidence; do not promote other gates from the
superseded first-pass table. Do not close #23 or move to PresetForge.
