# API audit

Checked against Roblox's public reference and Studio 0.740.19.7400931 on 2026-09-26. The engine test `every exposed property is writable in this Studio engine` reads and writes the complete exposed schema on detached instances. Read-only measurement properties are not exposed for editing.

| Surface | Decision / verification |
|---|---|
| [WeldConstraint](https://create.roblox.com/docs/reference/engine/classes/WeldConstraint), [Weld](https://create.roblox.com/docs/reference/engine/classes/Weld), [Motor6D](https://create.roblox.com/docs/reference/engine/classes/Motor6D) | Explicit Part0/Part1. Weld/Motor6D use C0 = Part0.CFrame:ToObjectSpace(Part1.CFrame), C1 identity. No writes to Transform, Active, ParentName or ChildName. |
| [HingeConstraint](https://create.roblox.com/docs/reference/engine/classes/HingeConstraint) | Attachment references, writable limits and motor/servo fields. No CurrentAngle or deprecated SoftlockServo property. Aligned X axes for new pivots. |
| [BallSocketConstraint](https://create.roblox.com/docs/reference/engine/classes/BallSocketConstraint) | Writable limits, twist limits and friction. No assumption that hinge fields exist here. |
| [RopeConstraint](https://create.roblox.com/docs/reference/engine/classes/RopeConstraint), [RodConstraint](https://create.roblox.com/docs/reference/engine/classes/RodConstraint), [SpringConstraint](https://create.roblox.com/docs/reference/engine/classes/SpringConstraint) | Distinct schemas. Initial length/free length from attachment world distance. No CurrentLength writes. |
| [NoCollisionConstraint](https://create.roblox.com/docs/reference/engine/classes/NoCollisionConstraint) | Part0/Part1, not attachment endpoints. May coexist with physical connections. |
| [ChangeHistoryService](https://create.roblox.com/docs/reference/engine/classes/ChangeHistoryService) | TryBeginRecording/FinishRecording per Apply; explicit rollback journal on error. Native Undo/Redo executed in edit-mode tests. Legacy SetWaypoint only isolates test fixture setup, never used in production. |
| [Plugin](https://create.roblox.com/docs/reference/engine/classes/Plugin), [Selection](https://create.roblox.com/docs/reference/engine/classes/Selection) | Documented toolbar, CreateDockWidgetPluginGuiAsync, Unloading, Selection:Get/Set and SelectionChanged. No fabricated dragger API. |

Numeric validation rejects NaN/infinity submitted as edits and checks engine clamping on a detached instance with relative float tolerance. Cross-field lower/upper order is checked. No invented maximum torque/stiffness/length caps. Engine defaults, including an infinite default where allowed, remain untouched unless explicitly edited.

Motor6D remains supported for tool assemblies; this is not a migration tool for newer avatar joint systems. Unsupported constraint classes remain inspect-only for property editing. Unary forces are not falsely marked broken merely for lacking a second attachment.

No plugin settings API, filesystem API, HTTP service, remote require, external asset IDs or persistent account data are used in production.
