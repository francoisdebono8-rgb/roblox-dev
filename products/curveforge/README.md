# CurveForge 1.0

Issue #11: editable Catmull-Rom paths, cable/pipe segments and repeated Parts/Models.

Install `dist/CurveForge-v1.0.0.rbxm` using Studio's local Plugins Folder and reopen Studio. Open **CurveForge** from the Plugins toolbar. No external runtime dependencies, network requests, analytics or account setup.

See `release/QUICK_START.md` and `release/TROUBLESHOOTING.md`.

## Build and verify

Build-only tools: Rojo 7.7.0, Python 3 standard library, Luau compiler. None is embedded in the plugin.

```sh
rojo build products/curveforge/release.project.json -o products/curveforge/dist/CurveForge-v1.0.0.rbxm
python3 products/curveforge/tools/verify_release.py --rojo rojo
rojo build products/curveforge/tests/place.project.json -o /tmp/CurveForge-QA.rbxlx
```

Open the QA place in Studio **edit mode**, not Play. In the Command Bar:

```lua
local q = game.ServerStorage.CurveForgeQA; require(q.Suite)(q.Modules)
```

Expected: 9 groups, zero failures. Native Undo/Redo is exercised directly. Alternatively build `tests/plugin.project.json` as a temporary local test plugin; it only runs in the dedicated QA place. Remove that test plugin after use. Never publish it.

## Boundaries

2-8 control BaseParts; open paths; 512 cable segments, 500 copies, 5000 repeated instances. Sampling uses 64 subdivisions per control span with arc-length redistribution. Source models must be Archivable, contain parts and no scripts or external joint/object references. Tight bends may self-intersect. This is a building tool, not rope physics. See the release limitations and actual test results.

Metadata is a plain `CurveForgeData` folder with typed attributes and ObjectValue references to original controls/source. Keep those originals in the same place. No metadata code is executed. Preview output lives in the DockWidget's ViewportFrame, never Workspace. Regenerate replaces only `Output` and `CurveForgeData` under the selected recognized model.
