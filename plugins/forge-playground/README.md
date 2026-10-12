# Forge Playground V1

Playable demonstrations of the five existing Forge products, implementing
[issue #29](https://github.com/francoisdebono8-rgb/roblox-dev/issues/29).
This replaces the earlier simplified prototype. Real production planners and
validators now drive all five stations; no plugin UI is impersonated.

Local/GitHub test build only. No Roblox experience or Creator Store asset was
published or updated. This project does not install or grant ownership of a
Studio plugin. Embedded modules are current repository candidates, not a claim
that every Store listing already contains these versions.

## Try It

1. Open [Forge-Playground-v0.1.0.rbxl](dist/Forge-Playground-v0.1.0.rbxl) in Studio.
2. Start **Play/Test**, not server-only Run. No plugin installation is required.
3. Choose a station, inspect its actual Preview/audit, then build or repair.
4. **Reset** restores that station's original fixtures. **Explore** enables the
   normal character camera; **Demo view** returns to the focused scene.

The scene is created at runtime; an almost empty edit-mode place is expected.
Each player receives a separate workshop, up to six concurrent workshops. State
is temporary and removed on leave. There is no HTTP, telemetry, saving, purchase
flow, external asset download or runtime dependency installation in this code.

## Five Workflows

| Station | Try | Real engine behavior |
| --- | --- | --- |
| AccessForge | Select START, select Straight/Switchback/Catwalk, Preview, Build; try Invalid | Production geometry planning, validation, part counts and generated geometry. |
| CurveForge | Select one of four points; change its side offset; Cable/Repeat; Preview and Build | Production adaptive path, placement frames, freshness checks and output generation. |
| JointForge | Scan, select a diagnostic, choose Handle or invalid Door endpoint, repair selected, rescan | Production graph diagnostics and explicit planner operations; duplicate removal and pivot/axis repair, no Fix All. |
| SchemaForge | Audit 24 tagged crates; inspect Expected/Actual; safe repair selected | Production audit and repair planning. Only missing defaults/tags are repaired; wrong values and missing children remain diagnostic. |
| PresetForge | Choose Color or Color + Brightness, Preview, inspect findings, Apply recipe | Production capture, descendant filters, exact-field diffs, affected/matching/ignored sets and stale-plan protection on 36 PointLights. |

Preset's baseline Color preview scans 72 descendants (36 housings + 36 lights):
24 compatible, 18 affected, 6 matching, 48 ignored, 18 property writes. After Apply,
it reports 0 affected / 24 matching. Brightness stays unchanged for Color-only.
**Change one target** deliberately invalidates a preview; Apply must reject it
until a new Preview. Filters are fixed: PointLight, Accent name, PGAccent tag,
descendant scope. The row inspector explains individual changes and exclusions.

This is not Studio Undo. Runtime mutations use fixture-scoped adapters, and Reset
reconstructs the demo fixtures. No Studio edit-mode guard has been disabled.

## Build And Test

Python 3 and Rojo 7.7 are build-time tools only. From the repository root:

```sh
python3 plugins/forge-playground/tools/build.py --rojo /path/to/rojo --compiler /path/to/luau-compile
python3 plugins/forge-playground/tools/build.py --rojo /path/to/rojo --compiler /path/to/luau-compile --qa
```

The compiler flag is optional. The normal build goes to `dist`; `--qa` writes a
separate place and import bundle in the system temporary `ForgePlaygroundQA`
directory. Open that QA place and start Play. The expected complete result is
`[Playground29] COMPLETE 27 passed / 0 failed`. The normal artifact excludes the
test runner. Do not publish the QA artifact.

The builder checks every script against a Rojo XML build of the same project and
records source/artifact SHA-256 values in [manifest.json](dist/manifest.json).
It reads current working-tree modules through direct Rojo paths; rebuilding
after a product changes requires rerunning parity QA.

See [architecture](PLAYGROUND_ARCHITECTURE.md), [status](STATUS.md) and
[native validation evidence](tests/RESULTS.md).

## Scope Of This V1

The room and fixtures are deliberately simple. This is a functional test build,
not final commercial art direction or a completed Store relaunch. Future work:
an attractive integrated world, guided challenges, full real-device/controller
acceptance and multiplayer soak testing, then separately authorized publication.
No plugin asset IDs or listings need to change.
