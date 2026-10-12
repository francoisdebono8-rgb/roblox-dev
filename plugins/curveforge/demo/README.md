# Original demo

Three scenarios: overhead utility cable, industrial pipe and repeated two-part fence posts. All objects are original Roblox primitives; no third-party assets.

`CurveForge-Demo.rbxl` currently contains the clean source fixtures (poles, machines, fence source and ordered control points). The finished generated outputs must still be created in Studio using Setup below; they have not been falsely presented as executed output.

To regenerate the demo, open the isolated QA place and run:

```lua
local q = game.ServerStorage.CurveForgeQA; require(q.Demo)(q.Modules)
```

Control parts live in each scenario's `ControlPoints` folder. They are transparent but selectable in Explorer. The generated parent Model retains references to them and its repeat source.
