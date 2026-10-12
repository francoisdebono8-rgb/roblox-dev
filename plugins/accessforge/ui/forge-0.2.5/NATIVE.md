# AccessForge 0.2.5 Native Handoff

## Recorded Execution

The exact frozen candidate passed the native suite in both the 13:09 UTC run
([native-dark-run.txt](native-dark-run.txt)) and Studio session `20261003T143618Z`:
55 V11 cases, 44 matrix rows and 10 contextual cases PASS, zero failed cases,
final SUMMARY PASS. Studio 0.741.19.7411056, local Edit mode.

The latter session also exercised the real installed commercial Main. Straight
Preview was read-only, Build/Confirm produced 33 parts, native Undo/Redo restored
33, moved End caused visible stale blocking, Existing/Proposed showed 33/38 parts,
and Regenerate/Confirm produced 38. Switchback and Catwalk invalid-to-valid GUI
Preview passed; their Build paths passed in the native suite, not through GUI clicks.
Reviewed captures cover Dark 320/560, Light 320/560, Light 400x640 and 240x360.
See [GUI_EVIDENCE.md](GUI_EVIDENCE.md) for the actual walkthrough, logs, visual review
and exclusions. The numbered checklist below remains a broader reference, not a
claim that every step was executed. No 560x900 capture exists: it exceeds the usable
Mac screen. No exhaustive Rails/Finish or ownership GUI walkthrough is claimed.

Candidate SHA256:
`839798041fdc1884df19e8cabccf7e1f698c0087d6f1e3bc8c9ec5bd25b1089d`.
Source, candidate and QA package are frozen; do not rebuild for this evidence update.

## Reproduction Reference

Historical build command from repository root (writes this candidate directory only):

```sh
python3 plugins/accessforge/ui/forge-0.2.5/build.py --rojo /private/tmp/jointforge-tools/rojo/rojo --luau-compile /private/tmp/jointforge-tools/luau/luau-compile
```

- Commercial: `AccessForge-ForgeStudio-0.2.5.rbxm` (normal enabled Main).
- Separate runner: `AccessForge025Gate.rbxm`.
- Empty opt-in place: `AccessForge025QA.rbxl`.
- Exact hashes: `candidate.json`; rebuilding after source changes invalidates old native evidence.
- Intended execution: local Studio **Edit mode**, PlaceId 0, empty Workspace/services.
- Runner starts only when Workspace `AccessForge025Gate == true` (already in QA place).
- Candidate/legacy Main scripts are disabled only in duplicated QA imports; their Sources are identical to the binaries.

The parent grants/stages the Studio slot. Open the empty QA place with the separate
QA runner installed for this run. Never run the gate in a user project. It refuses
nonempty Workspace/services and does not clean an existing place to make it fit.

Expected output: `[AccessForge025Gate] candidate=<exact sha>` and legacy SHA,
55 `[AccessForgeV11][PASS]` cases, 44 `[AccessForgeV11][MATRIX] n PASS` rows,
10 `[AccessForge025][PASS]` contextual cases, both suite summaries with zero failures,
then `[AccessForge025Gate][SUMMARY] PASS`. Any missing line or exception leaves the
gate incomplete. The sole V11 harness adaptation is its production-source count:
read the verified package count instead of hard-coding the historical five scripts.
No old assertions or safety cases were removed.

Context cases include exact supported primitive shapes; MeshPart, UnionOperation,
TrussPart and child-mesh omission; non-Archivable preservation; oversized/invisible
omission counts; and capped-query disclosure. No unsupported geometry is boxed.

After success the runner creates `Workspace.AccessForge025Fixture` with real
Straight, Switchback, Catwalk and Invalid endpoints/platforms for installed-plugin
testing. Preview geometry has not been inserted by the fixture; use the actual
commercial plugin to Preview and Build. The runner does not drive its GUI.

## Installed GUI Walkthrough

1. Parent installs the exact commercial candidate, confirms its hash and one active
   AccessForge version, and opens the actual toolbar/DockWidget.
2. For each fixture folder, select `Start`, Assign Start; select `End`, Assign End;
   choose the matching mode. Preview. Inspect both endpoint labels and platforms,
   actual counts, and the predicted fit. Build via confirmation, native Undo/Redo.
3. Select Invalid Start/End with Straight: Preview must refuse; Build stays disabled
   and old preview/counts are cleared. Also try non-level Catwalk.
4. Select a built Straight model; Edit Existing. Add `UserKeep` as a sibling under
   the assembly, Generated, and Generated.Stairs. Move End up 2 and back 4 studs.
   Observe stale state. Change Width to 8; Preview; toggle Existing/Proposed.
   The comparison must keep camera bounds and reveal old vs new fit. Regenerate;
   confirm user siblings survive and Undo/Redo preserves their identities.
5. Put a Folder inside an owned generated Part. Regeneration must refuse with an
   actionable message. Restore that child outside the owned Part before continuing.
6. Move a displayed platform after Preview. Preview must become stale with Build
   disabled. A fresh Preview must reflect the new platform. No preview objects may
   appear in Workspace and Preview must not add native history entries.
7. Exercise Layout/Rails/Finish (supports, landing, both rail profiles, color/material),
   duplicate/long endpoint names, confirm/cancel-by-changing-input, empty/blocked/
   success states, narrow scroll and keyboard field focus.
8. Assign an unsupported shape or non-Archivable object as an endpoint, or put it
   near one. The Start/End position remains marked; unsupported context must be
   absent, with an omission count/reason. Check oversized objects and query limits.
   Counts describe sampled objects, not the entire environment. Original Archivable
   must remain unchanged; no bounding box may stand in for unsupported geometry.

Capture actual production DockWidget: 560x640 and 320x640 Dark; both widths Light
sanity; 240x360 and 400x640. A 560x900 capture is unexecuted on this screen. Use Straight, Switchback,
Catwalk and moved-End regeneration comparison. At 240, short button copy may be
needed only if the physical gate demonstrates clipping. Record actual pixel
dimensions, Studio version/theme, candidate SHA and GUI source in evidence.
Compare with the historical 320/560 screenshots and accepted shell. Do not count
the native suite's separate View mount as production GUI proof.

Update status only from actual execution. The scoped #33/#35 native, installed
hero-workflow and screenshot review is GOOD with the documented coverage limits;
the coordinator owns issue closure and catalogue acceptance. No publication is authorized.
