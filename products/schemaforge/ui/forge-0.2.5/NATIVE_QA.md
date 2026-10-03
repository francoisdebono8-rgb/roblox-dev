# Native QA / executed evidence and reproduction

No Studio process, installed plugin or theme was touched by this agent.
Use the manifest hash for every native run and screenshot. Current Main stays
enabled in the commercial binary. Never install the QA binary as the product.

## Executed final candidate

Studio 0.741.19.7411056, Edit mode, exact SHA256
`1e86dd4e581bdffbae2a55635b95ab41bfa4d41359826935c74ef59bbf9575fe`.
Native module QA: **63 PASS / 0 FAIL, 41/41 matrix rows PASS, outer SUMMARY PASS**
([log](native-dark-run.txt)). The parent's separate full installed GUI session is
now reviewed as **GOOD**; [GUI_EVIDENCE.md](GUI_EVIDENCE.md) links the real captures
and exact `20261003T141548Z` CreatorOutput markers.

Executed GUI scope: Load -> Audit 8/3/5/7/3; read-only Preview three additions on
two objects; Apply 3; uninterrupted native Undo/Redo then snapshot 8/5/3/4/0;
actual re-audit with four diagnostic-only findings; another native Undo restoring
8/3/5/7/3; actual Select in Studio verified on PlantPot03; scope restored through
the fixture bridge; fresh Preview followed by deferred Cost=99 mutation showing
Stale and disabled Apply. Dark/Light 560/320, Dark 400 and 240-short are captured.

Advanced first-use/capture/filter/subset GUI cases below are reproduction guidance,
not exhaustive executed GUI claims. The full native regression covers the related
module behaviors separately. No 560x900 GUI capture or full theme/size matrix is
claimed. The short body's density and native Qt title contrast are documented.

## Offline rebuild

Reference command only. No rebuild was performed for this final signoff. The build
script regenerates candidate.json with pending native statuses; preserve executed
evidence and revalidate the exact hash before using it for a future authorized build.

From the repository root:

```sh
python3 products/schemaforge/ui/forge-0.2.5/build.py --rojo /private/tmp/jointforge-tools/rojo/rojo --compiler /private/tmp/jointforge-tools/luau/luau-compile --luau /private/tmp/schemaforge025-tools/runtime/luau
```

Only this directory receives generated outputs. No historical dist file is written.
Pure summary tests use official Luau 0.693; downloaded archive SHA256
18401b4d08331c95b74ceaf19a69894b88d0132b4d5e646a747b595c6bb94508.

## Automatic regression

Separate plugin: `SchemaForge025QA.rbxm`.
Separate opted-in local place: `SchemaForge025Technical.rbxl`.
Workspace attribute: `SchemaForge025Mode="technical"`; local PlaceId 0, Edit mode,
initially empty Workspace/ServerStorage/ReplicatedStorage/ServerScriptService.
Runner refuses another run in the same session (`SchemaForge025Running`).

It imports the exact new commercial artifact plus frozen 1.1.0. Main is disabled
only in both duplicated QA imports; sources are verified unchanged through roundtrip.
No QA fixture/source enters the commercial binary.

Expected: **53 V12 cases + 6 summary cases + 4 hero cases = 63**, and **41 V12 matrix
rows**. Prefixes: `[SchemaForgeV12]`, `[SchemaForge025Summary]`,
`[SchemaForge025Hero]`, outer `[SchemaForge025]`. Require all summaries and the
outer PASS for the same artifact hash, with no imported-source async exception.
The suite includes native history, stale refusal, rollback, persistence and typed
compatibility. The package assertion now requires six explicitly named scripts
(AuditSummary is the sixth); no regression case was removed.

## Installed commercial workflow reproduction

This checklist includes optional extensions not all repeated in the final GUI run.
Consult GUI_EVIDENCE.md for the precise executed scope, rather than treating every
instruction below as a PASS.

Parent stages `SchemaForge-ForgeStudio-0.2.5.rbxm` as the real local plugin.
Open fresh `SchemaForge025Fixture.rbxl` with the separate QA plugin available.
`SchemaForge025Mode="fixture"` creates actual tagged Parts and saves the real
Greenhouse Contract via Store. It selects the fixture folder but never mounts a
replacement View or patches production functions. Outer output is FIXTURE READY,
not GUI PASS.

Open the real SchemaForge toolbar button. Load Greenhouse Contract from Library;
this must land on Audit. Run Audit against Selection (fixture folder):

| State | Checked | Valid | With issues | Findings | Safely repairable |
| --- | --- | --- | --- | --- | --- |
| Before | 8 | 3 | 5 | 7 | 3 |
| After all three additions | 8 | 5 | 3 | 4 | 0 |

1. Capture actual installed GUI at **560x640 Dark** and **320x640 Dark**. Verify
   list/detail vs narrow detail navigation, all five real counters, tag/class/scope,
   Expected/Actual and designer note. Compare accepted baseline lockup and Audit.
2. Select Cost on PlantPot03, inspect its note and select the actual object in
   Studio. Wrong Cost on PlantPot05, GrowthRate on PlantPot06 and child/Retired
   findings on PlantPot07 must remain diagnostic-only.
3. Filter Wrong type: only one finding; total summary still 8/3/5/7/3; no safe
   preview. Clear filters, exclude one safe finding and verify exact subset Preview.
4. Restore fixture folder selection, fresh Audit, preview all **three additions on
   two objects**: Cost=25 on PlantPot03/04 and Interactable tag on PlantPot04.
   Confirm Preview leaves the project unchanged.
5. For stale proof, while Preview is ready use the QA bridge outside a Command Bar
   recording: `task.defer(function() game.ServerStorage.SchemaForge025QA:Invoke("stale") end)`.
   It changes PlantPot03.Cost to 99. Wait for stale; Apply must be disabled. Audit
   summary is historical until rerun. Rerun must preserve 99 and propose only two
   remaining additions. Use a fresh fixture place for the full three-addition path.
6. Real Apply, then **native Edit > Undo / Redo**. Snapshot shows before/after
   totals above. Wrong Cost="unknown", GrowthRate=-2, Retired tag and missing child
   remain unchanged. Re-audit after history; old success must be invalidated.
7. Light sanity plus 240x360, 400x640 and 560x900 where physically possible. Check
   long names, empty scope, zero matches, all-valid, blocked draft, capture-review,
   theme switching, subset/selection staleness, stable footer and scroll reachability.
   First-use Capture opens contract settings; safe defaults remain opt-in.

QA bridge commands `snapshot`, `scope`, `reference`, `stale` are fixture-only.
`snapshot` audits actual instances and prints `[SchemaForge025][FIXTURE]` JSON;
it does not certify visible UI values. Full GUI proof must use the installed Main.

The real final captures, CreatorOutput markers and unchanged hash are recorded in
GUI_EVIDENCE.md and candidate.json. Offline build success alone is not GUI evidence.
No Creator Store operation is authorized or performed.
