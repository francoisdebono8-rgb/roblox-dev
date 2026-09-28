# JointForge

Create, inspect and safely assemble joints in Roblox Studio. One DockWidget, three tabs: Create, Batch, Inspect.

Public release: **1.0.0**. Unpublished technical candidate: **1.1.0**, issue #22.
The public binary and canonical asset 103958912217728 remain unchanged.
See the [technical contract](v2/TECHNICAL_1.1.0.md) and [exact-candidate matrix](tests/TECHNICAL_MATRIX_1.1.0.md)
for graph plans, explicit endpoint repair, native field validation, limits and QA scope.

## Install

Insert `dist/JointForge-v1.0.0.rbxm` into a temporary place, right-click the JointForge model in Explorer and choose **Save as Local Plugin**. Open **Plugins > JointForge**. Do not publish the temporary place. Remove the inserted model afterwards; it is not game runtime code.

The commercial package contains one plugin Script and five ModuleScripts. No HTTP, telemetry, backend, runtime dependencies, settings storage or external assets. Tests, demo and build tools are separate.

## Scope

- Create WeldConstraint, Weld, Motor6D, HingeConstraint, BallSocketConstraint, RopeConstraint, RodConstraint, SpringConstraint and NoCollisionConstraint.
- Assign endpoint parts explicitly; reuse direct-child attachments or create new ones on Apply.
- Batch: choose a root, assign selected BaseParts Static (WeldConstraint) or Moving (Motor6D), Preview, Apply once.
- Inspect a selected model, parts or joints, including externally parented connections. Select endpoints or the joint in Explorer. Unsupported classes are inspect-only for properties.
- Edit exposed key properties and numeric C0/C1 offsets, including explicit identity reset. Preview field changes before Apply.
- Preview confirmed joint removal, preserving attachments. Joints with children cannot be removed until those children are handled explicitly.
- Each Apply uses one native ChangeHistoryService recording. Preview is read-only and rejected if relevant state or inputs changed.

Creation preserves world poses within engine floating-point precision. Offset editing deliberately changes a joint's pose. Existing connection paths conservatively block another physical connection, including disabled joints; inspect and resolve them explicitly. A NoCollisionConstraint may coexist with a physical joint.

There are no custom draggers, animation controls, IK/FK, simulation tuning, automatic unanchoring, renaming or reparenting of unrelated objects. Anchors, collisions and attachment placement remain the developer's responsibility. Workspace edit mode only.

## Build and verify

Build-only tools: Rojo 7.7.0, Python 3 standard library; Luau 0.740 for syntax compilation. None ships in the plugin.

```sh
python3 products/jointforge/tools/verify_candidate.py --build --rojo rojo
python3 products/jointforge/tests/build_technical_gate.py --rojo rojo --output-dir /tmp/JointForge22QA
```

The coordinator installs the separate technical QA plugin in an isolated Studio session
and opens the generated empty local place **without Play**. It runs only when Workspace
has `JointForgeTechnicalGate=true`. The gate embeds the exact candidate and public V1
binaries with only their QA-copy Main scripts disabled. All 56 matrix rows must pass.
Never rebuild current sources into the historical 1.0.0 binary or include QA code in the
commercial artifact. Native Undo tests are not meaningful in a running game.

The older source-based `Suite.luau` remains for reference and has been adapted to the
immutable-plan API; this technical release claims its exact-binary `V11.spec.luau`
gate, not a new execution of the old source-based runner.

See [Quick Start](release/QUICK_START.md), [Troubleshooting](release/TROUBLESHOOTING.md), [QA results](tests/RESULTS.md), [demo instructions](demo/README.md) and [release gate](release/CHECKLIST.md).
