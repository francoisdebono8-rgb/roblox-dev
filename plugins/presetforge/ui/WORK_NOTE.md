# PresetForge Product Enablement + UI review

Current continuation for issues #31/#35: see
[`forge-0.2.5/STATUS.md`](forge-0.2.5/STATUS.md) and its exact-source candidate manifest.
The checkpoint and evidence below remain historical; no native PASS transfers to 0.2.5.

2026-10-03. Implements the new sequential brief, building on uncommitted #24 work.
FIRST REVIEW PENDING. Not a final release gate. No publication or asset update.

## Product check

- Hero: many objects -> precise targets -> exact before/after -> Apply N.
- Already available: selective capture, all eight metrics, scopes/filters, immutable
  plans, stale checks, write journal/rollback and native history. No engine changes.
- Enablement: expose selective metadata, show real metrics and color swatches,
  open Changes when choosing a recipe; retain Library/Recipe and fixed actions.
- Rejected: new classes/properties, AI, cloud, scripting and a shared UI framework.
- What a new user should understand in 10 seconds: I can see exactly which lights
  will change, and from what to what, before applying only those fields in one operation.

## Candidate and fixture

- `PresetForge-v2.2.0-ui24.rbxm`: current source-only candidate, SHA-256
  `89d469227090d94f446f627f143749b7c3ebd5f80fb5ee727f823549fcb30131`.
- `PresetForge-LightingWorkshop.rbxl`: script-free original primitive scene;
  no third-party assets. Two real saved Project recipes and a reference source.
  The older `demo/PresetForge-Demo.rbxl` user modification is untouched.
- Select `Workspace.Workshop`, choose `Warm worklights`, Descendants / PointLight,
  Preview: 197 instances scanned, 40 compatible, 30 affected, 10 matching,
  157 ignored; 60 property writes, 0 tag writes, 0 attribute writes.
  Brightness 2 -> 5, Color #FFFFFF -> #FFCC8C. Range, tags and attributes stay out
  of this recipe's write scope. `Service metadata` demonstrates a separate subset.
- Next native sequence: Apply 30, Undo, Preview again; change a target Brightness
  before Apply and verify stale refusal. This sequence is prepared, NOT executed
  on the current UI candidate.

## Executed checks and outstanding gates

| Check | Result |
| --- | --- |
| Current Luau compilation | PASS |
| Current binary rebuild byte equality and all imported Sources equal local files | PASS |
| Commercial candidate contains only Main + product Modules, no QA/demo | PASS |
| Real selective metadata controls save only checked names | PASS on captured predecessor below |
| Metadata disabled on a source exceeding category limits | PASS on captured predecessor below |
| Real scene Preview, all eight metrics, no target writes | PASS on captured predecessor below |
| Dark 560 and 320 native rendering | Drafts captured; narrow long-path overflow observed |
| Last bounded-path fix: native recheck and final captures | NON TESTED |
| Human visual acceptance | PENDING |
| Full final native regression, Apply/Undo/Redo, stale, preservation, Light | NON TESTED; after visual acceptance |

`review/draft-dark-560.png` and `draft-dark-320.png` are real native pixel crops,
not redrawn screenshots. They show SHA-256
`da434b56d6116f67630f0811c31081db3e0ccdc34f9307a333f2cdca6a98c638`, before the
last path-bound correction. They are NOT evidence for the newer candidate above.
The older `review/dark-320.png` is the superseded Arena #24 baseline.

The first harness run exposed a deferred SelectionChanged event clearing a
programmatically immediate Preview. Waiting for the native event in the harness
fixed the test sequence; no engine workaround was added. The repeated run passed.
The last path fix clamps against the actual workspace width and preserves the full
path in its tooltip. Its harness now asserts path TextBounds before declaring a capture ready.

Studio interactions stopped at the user's request because another operation was
opening Forge-Playground-QA. Resume only the final candidate's first review; do not
mark the predecessor's results as final. Local QA imports the exact built candidate,
disables only its duplicated Main, uses real modules/services and isolated Local
settings. These checks are controller/native rendering tests, not physical GUI clicks.

### Full installed plugin reprise

The user correctly rejected treating the harness as validation of the installed
product. The full current candidate (`89d469...30131`) is now installed locally;
byte comparison with the candidate passed. The existing installation filename was
retained to preserve its plugin settings identity. The previous 2.1.0 binary was
backed up outside the plugins directory; the separate UI review wrapper was removed.

Studio loaded the real enabled Main. Its native dock title is `PresetForge 2.2.0`;
an existing Local recipe loaded through the real plugin settings. The script-free
LightingWorkshop place, including its two Project recipes, opened successfully.
No alternate UI/controller was instantiated in this reprise. Visibility and scene
selection were automated; the real recipe/Preview/Apply walkthrough is not yet passed.

The Mac then entered the lock screen. After the user unlocked it, the actual
installed panel and LightingWorkshop selection were observed again. The user
then requested an immediate stop and push of the current work. Final 560/320
captures, the long-path check and visual acceptance remain pending. Do not reuse
draft captures or the earlier harness to close this gate. No publication occurred.

## SchemaForge check only

Read-only inspection of `Engine.audit` confirms `matched`, `valid`, and findings
containing `instance` and `fix` already exist. Checked = matched; objects with
issues = matched - valid; unique instances with a non-nil fix give objects with
at least one additive repair. Fully repairable objects must additionally have no
unfixable findings. No new engine or display adapter is needed to obtain this summary.
Existing unrelated SchemaForge work is untouched.

## Reproduce

Build the product with its existing `release.project.json` into the UI candidate.
Run `build_demo.py --rojo <rojo>` for the clean scene, then
`build_gate.py --rojo <rojo> --output <temporary-directory>` for isolated QA.
The QA plugin is separate and must never be shipped. No Creator Store action.
