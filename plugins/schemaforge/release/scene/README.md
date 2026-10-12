# Plant greenhouse media provenance

- Author: Roblox Corporation.
- Project: Roblox/resources, official Plant experience.
- Revision: `ee51421b99234a436aa22d417a31316541b1575d`.
- URL: https://github.com/Roblox/resources/tree/ee51421b99234a436aa22d417a31316541b1575d/experiences/plant
- License: MIT, reproduced in [LICENSE-Roblox.md](LICENSE-Roblox.md).
- Retained source models: Farm, MediumPot, Cabbage in `source`. No executable scripts inside these models.

Local adaptation: greenhouse, eight tagged cabbage pots, two benches, path/ground, documented configuration errors and one saved schema. Glass is hidden for a cutaway camera view. No external game was published; no source runtime scripts run. The saved media place has no test runner or setup code. The setup module and build project are separate reproduction helpers, never included in the commercial model.

To rebuild: build `build.project.json` into a fresh temporary place and install the separate `tests/runner.project.json` plugin. Open that place once: Setup constructs the scene and removes its own source/assets/modules. Save a local copy and remove the QA plugin. Camera and cutaway changes made during the captured Studio session are retained in `../SchemaForge-Media.rbxl`.
