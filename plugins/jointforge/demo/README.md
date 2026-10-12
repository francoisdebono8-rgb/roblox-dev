# JointForge demo

Open `JointForge-Demo.rbxlx` locally in Studio edit mode. Everything is original Roblox primitives; no third-party assets, scripts or runtime behavior. Rebuild with `python3 plugins/jointforge/tools/build_demo.py`.

- `01_BatchTool`: cordless-tool model, no joints. Handle is the root, Body/Battery are Static, Chuck/Trigger are Moving. DisplayBase is not part of the assembly.
- `02_ExistingGraph`: same model with two WeldConstraints, a Chuck Motor6D and an intentionally missing endpoint on a Weld. Existing objects must survive conflict Preview.
- `03_DoorHinge`: Frame and Door with aligned vertical hinge attachments. Create a HingeConstraint by choosing those existing attachments.
- `04_RopeSpring`: beam with two loads and existing rope/spring. Inspect and adjust key properties.

The clean place is an editing fixture, not a game. Anchored roots and loads prevent accidental simulation of unfinished assemblies. Intentionally unanchor appropriate objects in a copy when testing motion.

## Three screenshots

1. **Batch tool setup:** frame `01_BatchTool`; assign Handle, Static Body/Battery and Moving Chuck/Trigger. Show the Batch list and Preview, with no conflicts.
2. **Inspect existing graph:** select `02_ExistingGraph`, Inspect current selection. Show the connections and broken endpoint. Endpoint selection highlights the actual part through Studio Selection.
3. **Preview / Apply / Undo:** create the tool batch, verify four new joints, invoke Studio Undo once and show the restored unjoined assembly with the plugin's actual Undo status. A still image cannot prove an entire temporal sequence; the Studio test log records that separately.

Capture only the scene and JointForge panel. Exclude the macOS/Studio title and account chrome. Do not replace UI text, fabricate a graph or composite different states. Screenshot status is recorded in `tests/RESULTS.md`.
