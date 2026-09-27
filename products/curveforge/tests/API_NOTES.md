# API references

Implementation follows the existing Forge-family DockWidget and recorded-transaction patterns. Runtime execution of the final native suite is still required; these documentation checks are not PASS results for the engine tests.

- [ChangeHistoryService](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService): TryBeginRecording, FinishRecording Commit/Cancel, native Undo/Redo in the QA harness.
- [ViewportFrame](https://create.roblox.com/docs/reference/engine/classes/ViewportFrame): preview instances under a WorldModel inside the plugin panel, not Workspace.
- [PVInstance](https://create.roblox.com/docs/reference/engine/classes/PVInstance): Part/Model GetPivot and PivotTo for repeated sources, with no scale changes.

The numeric limits are explicit CurveForge workload/geometry limits, not claims about Roblox engine limits. Metadata is read as typed attributes/references; arbitrary code is never evaluated. All source requires are local ModuleScripts.
