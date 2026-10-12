# AccessForge 1.0 Native Release Gate

Date: 2026-09-27. Roblox Studio macOS **0.740.19.7400003**, edit mode.

Final commercial binary SHA-256: `53655a01ca0bb2e05886cdc401fa38003430f4f10f7317854a93c646d9dff44c`.

Suite execution: **22 test groups passed / 0 failed**, 11:54:57 UTC, after the dock-size correction. Evidence: Studio log `0.740.19.7400003_20260927T115446Z_Studio_3129c_last.log`, lines prefixed `[AccessForgeTests]`. The QA place imports that exact binary; no mocked Roblox geometry or Undo engine. Injected failing recording services are used only for the explicitly named rollback tests.

| Issue #14 point | Status | Evidence |
|---|---|---|
| 01: 10-step straight | PASS | Native geometry assertions |
| 02: large automatic straight | PASS | Native step/rise calculation |
| 03: non-integer rise | PASS | Equalized rise assertions |
| 04: narrow/wide | PASS | Native width assertions |
| 05: finish/flags/profile | PASS | Parts match material/color/Anchored/CanCollide; square/round |
| 06: read-only Preview | PASS | Workspace count/events/parents unchanged by plan and viewport output |
| 07: intended content only | PASS | Native output and unrelated fixture assertions |
| 08: Build Undo/Redo | PASS | Real ChangeHistoryService undo and redo; GUI menu also observed |
| 09: switchback | PASS | Both flights and middle landing |
| 10: left return | PASS | Native direction and landing checks |
| 11: right return | PASS | Native direction and landing checks |
| 12: landing depth | PASS | Two dimensions compared |
| 13: left guardrail only | PASS | Generated descriptors/parts |
| 14: right guardrail only | PASS | Generated descriptors/parts |
| 15: both guardrails | PASS | Generated descriptors/parts |
| 16: sloped rails | PASS | Endpoint and slope assertions |
| 17: landing continuation | PASS | Outer/inner landing edge coverage |
| 18: level catwalk | PASS | Deck geometry |
| 19: catwalk rails | PASS | Both edge top rails |
| 20: supports | PASS | Bottom at baseline, top under deck |
| 21: support spacing | PASS | Different counts and positions |
| 22: exact Edit Existing settings | PASS | Every stored field compared |
| 23: dimensions/regenerate | PASS | New owned geometry replaces old |
| 24: moved marker/regenerate | PASS | Replanned output; stale plans rejected |
| 25: Regenerate Undo/Redo | PASS | Real native history restores ownership and prior dimensions |
| 26: original markers | PASS | References/parents preserved |
| 27: unrelated environment | PASS | Foreign child remains in its original output folder |
| 28: invalid dimensions | PASS | Zero/negative/text/non-finite values and invalid enums rejected |
| 29: degenerate/invalid input | PASS | Deleted/moved/same-level-invalid markers, corrupt ownership refused |
| 30: conservative cap | PASS | Excessive step/part counts rejected |
| 31: clean package | PASS | Closed instance tree, five production sources, no QA/demo/network paths |
| 32: source/rebuild equality | PASS | Byte-for-byte rebuild; embedded Source equality; manifest |
| 33: successful scoped GUI without exceptions | PASS | Final commercial plugin, real button workflow and all three modes; no AccessForge exception |

Extra PASS: unavailable recording refusal, injected commit failure rollback (Build and Regenerate), panel mount at undersized bounds, New markers native Undo/Redo.

## GUI Walkthrough

Final artifact, 12:16-12:30 UTC, log `0.740.19.7400003_20260927T121442Z_Studio_b17a9_last.log`:

- Real Edit Existing button loaded FactoryStair: width 7, landing 6, 15 steps, 42 parts. Keyboard input changed width to 8; Preview left Workspace at 784 descendants and preserved the old width/geometry/environment. Confirm Regenerate changed width to 8, detached only old owned geometry, and preserved markers and environment transforms.
- Native Edit menu Undo restored width 7; Redo restored width 8. History-event observations at 12:25:12 and 12:25:22 confirm both states without intervening commands. Returned the media stair to width 7.
- Width 0 produced the inline validation message and no valid preview. Correcting to 7 restored the workflow. Rails and Finish tabs were opened and visually checked.
- New markers produced a read-only 10-step/35-part preview; only the marker folder and two markers appeared in Workspace. Real Build/Confirm Build created the assembly. Native menu Undo removed it; Redo restored it (12:26:04/05 event observations, 12:26:16 postcondition). The temporary fixture was removed and the original count restored.
- Real Edit Existing buttons loaded SwitchbackAccess (left return, landing 7, 25 steps/86 parts) and CatwalkSystem (38-stud run, 31 parts). Their genuine scenes and production panel were captured and visually reviewed.
- The cleaned media scene was saved with three valid featured assemblies and zero LuaSourceContainers (12:30:57 assertion). QA runner removed from local Plugins afterwards.

Harness caveat: two earlier Redo assertions failed because executing Command Bar inspection between Undo and Redo invalidated the redo sequence. These are not PASS and are not hidden: they appear as CommandBar errors at 12:18:31 and 12:22:46. The corrected uninterrupted GUI sequences above passed. No production AccessForge script exception occurred. A keyboard automation shortcut also closed Studio; the saved scene was reopened before the final workflow. Neither event required a product-code change.

## Corrections During Validation

- Handle dock sizes below Studio's requested minimum: scroll the complete panel instead of allowing negative content height and hidden commands. Covered by the final native mount test.
