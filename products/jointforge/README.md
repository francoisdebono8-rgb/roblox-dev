# JointForge 1.0

Create, inspect and safely assemble joints in Roblox Studio. One DockWidget, three tabs: Create, Batch, Inspect.

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
rojo build products/jointforge/release.project.json -o products/jointforge/dist/JointForge-v1.0.0.rbxm
python3 products/jointforge/tools/verify_release.py --rojo rojo
python3 products/jointforge/tools/build_demo.py
rojo build products/jointforge/tests/plugin.project.json -o /tmp/JointForgeTests.rbxm
rojo build products/jointforge/tests/place.project.json -o /tmp/JointForgeTests.rbxl
```

Install the test plugin locally and open the test place **without Play**. It runs only when Workspace has `JointForgeTestPlace=true`. Expect `[JointForgeTests] 14 passed / 0 failed`. Remove the test plugin after QA. Never include it in the commercial upload. Native Undo tests are not meaningful in a running game.

See [Quick Start](release/QUICK_START.md), [Troubleshooting](release/TROUBLESHOOTING.md), [QA results](tests/RESULTS.md), [demo instructions](demo/README.md) and [release gate](release/CHECKLIST.md).
