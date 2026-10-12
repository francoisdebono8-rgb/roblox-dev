# Studio audit execution record

2026-09-27, Studio `0.740.19.7400003`, macOS, edit mode, light Studio theme.
This is a first-use heuristic audit by an agent, **not an independent novice user study**
and not a new exhaustive release gate. Product actions were clicked in the real UI.
Command Bar was used to select known scene instances and assert results, not to invoke
plugin internals as a substitute for GUI actions.

Commercial local plugins were already installed; SHA-256 matched each repository dist:

| Product | Version | Installed = dist SHA-256 |
|---|---|---|
| PresetForge | 2.0.0 | `31401503260a2d6a95b17d41553601ebcba0c590b490ef5fced3a08b622618ec` |
| JointForge | 1.0.0 | `24f43cf04c7d4e8cf92310b3c725f827e36b1ea22d9806e20325a4af4d2633bd` |
| CurveForge | 1.0.0 | `476ee0fc81f9080130fe8b6914bac8e37a9a1021b71df93f7b87168ee164162b` |
| AccessForge | 1.0.0 | `53655a01ca0bb2e05886cdc401fa38003430f4f10f7317854a93c646d9dff44c` |
| SchemaForge | 1.0.0 | `d6b29c5b9f76db7d96e4ac828e4eb2f56152c66c8e6e98c67ac598d383b99a2f` |

Only disposable local copies of the five saved media scenes were changed. No scene
original, plugin source, binary, release metadata or public asset was changed. Existing
user-local presets were retained. No QA plugin was added to the installed set.

## Executed scope

| Product | Real project and GUI sequence | Result actually observed |
|---|---|---|
| PresetForge | MIT Nexus-Battles DodgeballArena: source light selected; Save Recipe, Project, Brightness only; 21 PointLights selected; Preview; Apply | PASS for this path: 21 compatible, 4 changes, 17 already matching; all 21 Brightness values equal 4 after Apply. |
| JointForge | MIT Nexus-Battles TheDepths: explicitly assign two existing Arch parts; Preview; Apply | PASS: same endpoint was blocked during setup, distinct pair previewed with anchored warning; selected result was a WeldConstraint with the exact expected Part0/Part1. |
| CurveForge | MIT Nexus-Battles RavenRock: select saved cable; Edit Selected; blue swatch; auto Preview; Regenerate | PASS: loaded four points; output recolored; 125 output parts verified blue. Source/environment preservation was not exhaustively rechecked in this pass. |
| AccessForge | MIT hacker-tycoon utility facility: select FactoryStair; Edit Existing; width 7 to 8; Preview; Regenerate; Confirm Regenerate | PASS: 15-step / rise 12 / run 30 / 42-part preview; saved output metadata Width=8 after the actual GUI write. |
| SchemaForge | MIT Roblox Plant greenhouse: Project schemas > Greenhouse pots; Audit > Workspace; Audit; Select affected; Preview missing defaults; Apply | PASS: 8 checked, 3 valid, 6 findings; 5 selected objects; two Cost defaults shown as missing to 25, then verified on Cabbage_03 and Cabbage_06. |

These scene adaptations already contained controls/configuration fixtures from previous
release work. They are realistic environments, not claims of discovering these exact
defects in unmodified upstream games. No third-party runtime scripts were launched.

## Sanitized assertion transcript

Native CreatorOutput success lines after assertions, timestamps UTC. Command echoes
and failed setup attempts are not counted as successful assertions.

```text
2026-09-27 14:49:41 Preset GUI Apply verified: 21 PointLights, Brightness 4
2026-09-27 15:00:50 Joint GUI Apply verified WeldConstraint endpoints
2026-09-27 15:06:50 Curve GUI regenerate blue verified 125
2026-09-27 15:17:08 Access GUI regenerate Width=8 verified
2026-09-27 15:25:37 Schema GUI 2 missing defaults verified; selected 5
```

UI screenshots were actually inspected during each path. Raw window captures remain
temporary and are not committed: they contain local title paths/account chrome and are
not commercial media. This transcript is a minimal transcription, not an attached raw log.

## Limits and negative observations

- All five initially inherited a roughly 190-logical-pixel-wide dock beneath Explorer
  and Properties. PresetForge, AccessForge and SchemaForge clipped essential controls;
  the other forms were severely constrained. Enlarging the dock recovered the workflows.
- Only one display scale and Studio light theme were exercised. Dark theme, Windows,
  full keyboard-only flow, Team Create and large-project performance: NOT TESTED here.
- Native Undo/Redo: NOT REEXECUTED in this audit. Existing historical QA remains separate.
- Complete class/property matrices, persistence across restart and final artifact rebuild:
  NOT REEXECUTED, because no product changes were made.
- Selection fixture scripts aided navigation. No claim that a real novice found objects
  unaided, nor a claim of measured time savings.
- Multiple Studio processes and stale native automation handles required recovery.
  Treat that as automation/environment friction, not a demonstrated plugin defect.
- AccessForge numeric entry initially produced 87 instead of 8 during keyboard automation;
  it was corrected before Apply. This is not counted as a plugin parsing bug.

Per-product findings and proposed scopes are linked from
[implementation-order.md](implementation-order.md). Tests in this table certify only
the listed path, not "all V1 QA PASS" or "V2 release ready".
