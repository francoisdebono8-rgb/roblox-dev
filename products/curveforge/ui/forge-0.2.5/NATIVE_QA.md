# CurveForge 0.2.5 Native Handoff

Executed evidence is recorded in `STATUS.md`, `candidate.json` and `GUI_EVIDENCE.md`.
The procedures below remain a rerun checklist; an unchecked step is not a claimed PASS.
Any new Studio run remains parent-coordinated.

## Executed Status

Exact candidate `510b7dc3af0dfed72bdc97f7ebe83ce2bdacfc960ffac38dd9ab9735e78cdc7d`:
63 native checks PASS (9 baseline, 42 technical, 5 context, 7 callback mounts), recorded
in `native-final-run.txt`, Studio 0.741.19.7411056 Edit mode on 2026-10-03.
The coordinator separately exercised the installed commercial Main: Cable and Repeat
Edit Existing, moved Repeat Point02 through the command bar, observed stale/disabled
Regenerate, refreshed and compared Existing/Proposed, regenerated 14 copies, and used
native Undo/Redo. Saved assertions confirm read-only Preview, source preservation,
42 changed output positions after regeneration and exact baseline restoration on Undo.

All ten final captures and both historical baselines were independently inspected.
Classification is GOOD for the executed installed workflow and captured 240-short,
320/400/560 layouts; basic Light/Dark content sanity passes. The short viewport blocker
is resolved, with visible built geometry, Built confirmation and disabled Regenerate.
The seventh View check mounts CoreGui at 240x338 and 240x360, asserting preview >=96px
high / >=200px wide, preview/footer bounds, comparison controls >=28px high, Built text
and disabled repeat write. This is callback-mount evidence; the installed short Built
capture and coordinator's real Regenerate are separate evidence. Nearby projected
markers can overlap at the compact scale; the Path list remains the selection alternative.
No 900-high physical capture or exhaustive advanced/error/new-Build installed GUI run is
claimed. See `GUI_EVIDENCE.md` for per-image review, exact log times and remaining gates.
Pre-fix captures in `review-before-compact-fix/` and the 62-check `native-dark-run.txt`
are historical only. They do not count toward this final candidate's acceptance.
This evidence update did not rebuild or change the product sources/artifact.

## Offline Build

From the repository root:

```sh
python3 products/curveforge/ui/forge-0.2.5/build.py --rojo /private/tmp/jointforge-tools/rojo/rojo --compiler /private/tmp/jointforge-tools/luau/luau-compile
```

`candidate.json` records commercial artifact/source hashes and QA artifact hashes.
The build checks deterministic bytes, exact embedded sources, production-only packaging,
unchanged historical binaries and unchanged Engine/Curve/Settings/ForgeMark against #26.
No source test, fixture or runner enters the commercial package.

## Native Regression

1. Open the disposable local `CurveForge-0.2.5-QA.rbxl` in Edit mode, not Play.
2. Parent installs only the separate `CurveForge-0.2.5-QA-runner.rbxm` for this run.
3. It auto-runs only with Workspace attribute `CurveForge025QA=true`, an empty Workspace,
   and `ServerStorage.CurveForge025QA`. Embedded Candidate and Legacy Main are disabled
   in the duplicated QA import only. The commercial binary's Main stays enabled.
4. Capture Output lines beginning `[CurveForge025]`, `[CurveForgeTests]`, `[CurveForgeV11]`.
   Expected: 9 baseline + 42 technical + 5 context + 7 View callback checks = 63.
   No summary PASS occurs unless every suite returns success and async errors are absent.
5. Inspect `ServerStorage.CurveForge025QA` attributes `Complete` and `Success`.
   On failure retain the output and report the failure, not PASS. Reopen the clean QA place
   to rerun; the runner deliberately does not run twice in a completed place.

`CurveForge-0.2.5-QA-import.rbxm` is also available separately for import into
ServerStorage of an equivalent disposable empty place. It contains the exact candidate
and historical 1.0.0 modules plus tests. `Runner.plugin.luau` contains no commercial UI.

Context assertions cover no transient Workspace additions/removals, unchanged original
geometry/metadata, absence of cloned scripts/ObjectValues/tags, true Existing snapshots,
no extra Undo/Redo step, bounded/failing context queries, invisible controls with markers,
Cable and Repeat point movement/regeneration with native Undo/Redo. V11 retains the full
frame/roll/arc-length/limits/migration/stale/transaction/source regression.

## Installed Main And GUI

The parent must stage the commercial artifact separately and verify its installed hash.
The tests mount native View for callback smoke only; that is not proof of installed GUI.
After a successful runner, `Workspace.CurveForge025Demo` contains two real engine-built
fixtures. Select `Cable.UtilityCable`, then use actual installed CurveForge Edit Existing.

- Cable: four controls, two utility poles/crossarms, real cable. Review Proposed/Existing.
- Repeat: select `Repeat.CustomBeaconPath`, Edit Existing. Four controls repeat the
  three-part `Repeat.CustomBeacon` source 14 times. Verify its source identity in Output.
- Move Point02 by `(0,4,5)` with the Studio Move tool. Observe stale, disabled Regenerate,
  refresh Preview, compare Existing/Proposed, then Regenerate. Source remains unchanged.
- Native Undo restores old output; Redo restores new output. Move/Undo are distinct steps.
- Edit a generated segment directly, refresh, and confirm Existing shows its actual position.
- Compare, navigate and resize repeatedly; no Workspace preview objects/history steps.
- Test long/duplicate names, missing/deleted source/control, invalid numeric/RGB values,
  order confirmation/reorder/removal, roll, Count/Spacing, empty, error, stale and success.
- Open, close, reopen the actual plugin; confirm one usable toolbar/dock and no errors.

## Captures And Acceptance

Capture only real installed GUI, unretouched. Suggested internal filenames:
`review/dark-560-cable.png`, `review/dark-320-repeat.png`,
`review/dark-560-existing.png`, `review/dark-560-proposed.png`,
`review/light-560-repeat.png`, `review/light-320-repeat.png`,
`review/dark-240-short-built.png`, `review/dark-400.png`.
Record logical widths 240/320/400/560 and heights 360/640/900 where meaningful.
Compare the 320/560 baseline captures to the final artifact. Ensure numbered controls,
selected mode, result, exact counts, context/source and primary action are legible.
Check clipped labels, action reachability, hover/focus/disabled states and scroll retention.

Update STATUS/candidate gates only with executed evidence on the exact final hash.
The final short-layout evidence resolves the previously recorded blocker. This does not
turn unexecuted GUI branches or size/theme combinations into PASS. Any later source or
binary change needs new exact-artifact verification and applicable native/GUI evidence;
these records do not certify a future build. No publication is authorized.
