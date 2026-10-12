# CurveForge 1.1.0 technical candidate

Issue #18: stable 3D frames, optional control roll, bounded adaptive sampling and
safe repeat/regeneration inputs. Built on the existing V1 engine, not a UI rewrite.
Public version remains **1.0.0**, asset **90642263224333**, unchanged. This candidate
is **not published**; no new media, listing or promotional work belongs to this phase.

For local candidate testing only, use `dist/CurveForge-v1.1.0.rbxm` in Studio's local
Plugins Folder instead of the V1 copy, then reopen Studio. The automated engine gate
below does not replace the installed commercial V1 plugin. No external runtime
dependencies, network requests, analytics or account setup.

See `release/QUICK_START.md` and `release/TROUBLESHOOTING.md`.

## Build and verify

Build-only tools: Rojo 7.7.0, Python 3 standard library, Luau compiler. None is embedded in the plugin.

```sh
rojo build plugins/curveforge/release.project.json -o plugins/curveforge/dist/CurveForge-v1.1.0.rbxm
python3 plugins/curveforge/tools/verify_release.py --rojo rojo
python3 plugins/curveforge/tests/build_technical_gate.py --rojo rojo
```

Install the separate `CurveForgeTechnicalGate.rbxm` emitted in the temporary QA
directory and open its `CurveForge18QA.rbxl` in Studio **Edit mode**, not Play.
The opt-in runner imports the exact candidate and historical V1 binaries, disables
their entry scripts only in this isolated QA copy, and exercises actual native APIs
and history. Remove the QA plugin afterward. Never publish the QA package/place.
See [technical gate](v2/TECHNICAL_GATE.md) for the actual results and 38-point matrix.

## Boundaries

2-8 control BaseParts; open paths; 512 cable segments, 500 copies, 5000 repeated
instances, 1000 source instances. Adaptive sampling is capped at 8192 points and
depth 18. Source models must be Archivable, contain parts and no scripts or external
joint/object references. Tight bends may self-intersect; this is not rope physics.
See [technical behavior](v2/TECHNICAL_BEHAVIOR.md) for tolerance, frame, roll,
fingerprint and endpoint semantics. Existing commercial release docs/media describe
V1 and are deliberately unchanged.

Metadata remains a plain `CurveForgeData` folder with typed attributes and ObjectValue
references. V1 loads with roll disabled; successful Regenerate writes metadata V2.
Keep the original controls/source in the same place. No metadata code is executed.
Preview output stays in the DockWidget ViewportFrame, never Workspace. Regenerate
replaces only `Output` and `CurveForgeData`; user-added siblings remain intact.
