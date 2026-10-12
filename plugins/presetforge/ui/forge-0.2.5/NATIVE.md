# PresetForge 0.2.5 native execution record

**GOOD.** Parent executed the 94/94 native suite and the separate full installed Main
hero workflow on unchanged SHA `a9726d442d8376a658cdb042da2212cced695ab2b7e6a96c4b8a08e71d881a63`
in Studio 0.741.19.7411056, local Edit mode, 2026-10-03. The suite ended at
13:17:39.329Z; the final clean GUI Undo/Redo assertion passed at 14:14:50.346Z.
See [GUI_EVIDENCE.md](GUI_EVIDENCE.md) for scoped log excerpts and independent comparison
of seven real screenshots, and [native-dark-run.txt](native-dark-run.txt) for the suite.

The first GUI Redo assertion failed at 14:13:43.949Z after a Command Bar read between
Undo and Redo disrupted history. That invalid QA procedure is disclosed, not counted
as PASS and not attributed to a product error. The successful rerun had no intervening
Command Bar execution, including reads; its assertion ran only after Apply -> Undo -> Redo.

Physical editor/selective-capture, duplicate/edit/search, GUI stale mutation and restart
persistence were not separately executed in the GUI session. Relevant controller/native
cases passed in the 94-check suite; in-session storage checks are not restart evidence.

The checklist below is retained for traceability, not a claim every physical GUI step
was executed or a request for more tests. No rebuild, Studio action or publication is
requested. Historical reproduction commands start at the repository root.

## Rebuild and integrity

```sh
python3 plugins/presetforge/ui/forge-0.2.5/build_candidate.py
shasum -a 256 plugins/presetforge/ui/forge-0.2.5/PresetForge-ForgeStudio-0.2.5.rbxm
```

The builder compiles 38 Luau files, checks unchanged engines/Main against `92e4463`,
independently rebuilds the candidate, imports all 20 exact Sources, checks commercial
hierarchy, then disables only Main in duplicated QA imports. It imports retained
2.0.0/2.1.0 binaries for migration regression. The final QA binary is decoded again.
All inputs, candidate, QA and fixture hashes are recorded in `candidate.json`.
Any later production edit invalidates all native evidence and requires a rerun.

## Automated native suite (parent's exclusive Studio slot)

1. Open `qa/PresetForge025Gate.rbxl` in local Studio **Edit** mode (`PlaceId == 0`).
2. Stage/load only `qa/PresetForge025Gate.rbxm` as the separate QA plugin. The place
   already has `Workspace.PresetForge025Gate = true`; this must be present at startup.
3. The runner refuses nonempty Workspace/QA services, live/simulated places and a
   concurrent PresetForge gate. Other QA plugins must be disabled for this run.
4. Preserve output beginning `[PresetForge025Gate]`. Expected: **94 checks**, all
   PASS, zero FAIL, then `[SUMMARY] PASS`. Confirm the opening commercial SHA matches
   candidate.json. Also inspect model attributes `Complete`, `Success`, `Passed`, `Total`.
5. Remove/disable the QA plugin before the installed GUI session. Never distribute it.

Coverage: 74 existing technical/native checks (including all M01-M35 and the retained
baseline/workflow/storage regressions), 12 layout cases (240/320/400/560 x 360/640/900),
and H01-H08 (selective capture, category limits, real eight metrics, exactly 30 targets
and 60 setters, native Undo/Preview/Redo, watcher and synchronous stale refusal,
metadata-only Apply preservation, version/branding and long UTF-8 paths).

UI geometry/controller tests deliberately use an isolated native host and direct
handlers. **They do not prove the installed commercial GUI or count as screenshots.**
The native suite uses isolated settings, restores real QA keys, and never writes the
commercial settings key. It does modify the disposable QA place's history.

## Actual installed Main / GUI (separate gate)

Parent stages the full enabled commercial candidate under the existing filename
`/Users/francoisdebono/Documents/Roblox/Plugins/PresetForge-v2.0.0.rbxm` after backing
up the previous installation outside Plugins. Hash the installed file against the
candidate. Do not instantiate another UIFactory or Controller, constrain a fake host,
replace settings with a mock, or load the old `ui/Harness.plugin.luau` for this gate.

Open the **current** `PresetForge-LightingWorkshop.rbxl` in this directory. Use a
disposable copy; no saving over the user-modified `demo/PresetForge-Demo.rbxl`.

1. Open the real toolbar/dock. Title stays `PresetForge 2.2.0`; footer reads
   `Forge Studio 0.2.5`. Verify existing Local recipes load with real plugin settings.
2. Select `Workspace.Workshop`. Choose Project recipe `Warm worklights`, Descendants,
   class `PointLight`, empty name/tag filters. Click **Preview**.
3. Expect 30 will change, 10 matching, 197 scanned, 40 compatible, 157 ignored;
   60 property writes, 0 tag writes, 0 attribute writes; **Apply 30**.
   Before/After: Brightness 2 -> 5, Color #FFFFFF -> #FFCC8C. Preview changes nothing.
   Actual installed Studio session: **218 scanned / 178 ignored**, due to 21 additional
   `Snap` instances verified by read-only native class counts. All light/write metrics
   remain identical; the offline 197/157 expectation is preserved in the fixture record.
4. Capture genuine dock pixels at Dark 560x640 and 320x640. Check path truncation and
   full tooltip. Include 240x360, 400x640, 560x900, then Dark/Light sanity at both
   320/560. Record actual inner dimensions, theme and candidate SHA with each image.
   Compare against predecessor drafts and approved product structure. No redrawing.
5. Click **Apply 30**. Inspect all 40 lights: Brightness=5, Color=#FFCC8C, Range=12,
   Shadows=false, Enabled=true, original FixtureId/Keep=false/LightingProfile=Existing,
   original Worklight/KeepTag tags and no FixtureReady tag. The other objects are untouched.
6. Use actual **Edit > Undo**, verify first 30 return to Brightness=2/white and last
   ten stay warm. Click Preview again: the same 30/60 metrics. Use **Edit > Redo**,
   verify all 40 warm and a new Preview has 0 affected/40 matching. Avoid **all Command
   Bar execution, including reads**, between Undo/Redo; it can disrupt Studio history.
   In the accepted GUI rerun, Apply -> Undo -> Redo was uninterrupted, then asserted.
7. Preview, then change `Workshop.Lighting.Bay 01.Fixture 01.Diffuser.Worklight 01`
   Brightness to 3 in native Properties. Verify stale status and disabled Apply.
   No other light changes. Restore Brightness=2; refresh Preview to recover 30.
8. Select `ServerStorage.ReferenceFixture.Source`; capture a temporary recipe via the
   real editor, checking only tag `FixtureReady` and attribute `LightingProfile`.
   No properties, FixtureId, Keep or other tags checked. Inspect saved recipe; apply
   to Workshop. Expect 40 tag and 40 attribute writes, zero property writes. Verify
   all other fields/tags/attributes remain unchanged. Native Undo restores metadata.
9. Check Local/Project distinction, duplicate/edit preserving original, search,
   source changes refusing capture, long/duplicate names, empty/error/success states,
   focus/caret, scroll and Select/Frame. Remove temporary recipes through real UI.
   Verify Local and Project persistence after a controlled restart/reopen if supported
   by the parent slot. Do not silently infer restart persistence from in-session tests.

Recorded actual captures: Dark 320/560, Light 320/560, Light 240-short/400 and after-Apply.
At 240x360 the fixed action remains visible while metrics/diffs require body scrolling.
These are internal QA captures, not new Store media. Physical GUI steps beyond the
documented hero sequence remain NON TESTED. Previous 74/74 and predecessor captures
remain historical evidence only; the parent owns the final #35 catalogue decision.
