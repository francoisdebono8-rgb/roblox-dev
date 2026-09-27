# AccessForge 1.0

Industrial straight/switchback stairs, landings, guardrails and catwalks with editable regeneration. Roblox Studio edit-mode plugin. Generated output is ordinary Parts with transparent attributes and ObjectValues, not executable scripts.

- Commercial plugin: `dist/AccessForge-v1.0.0.rbxm`.
- Start here: `release/QUICK_START.md`.
- Boundaries: `release/LIMITATIONS.md`.
- Native test evidence: `tests/RESULTS.md`.
- Store copy and publication state: `release/STORE_LISTING.md`, `release/PUBLICATION_STATUS.md`.
- Licensed demo: `release/scene/AccessForge-Media.rbxl` (not the upload artifact).

## Build and verify

Use Rojo 7.7.0 and the official Luau compiler. From the repository root:

```sh
rojo build products/accessforge/release.project.json -o products/accessforge/dist/AccessForge-v1.0.0.rbxm
python3 products/accessforge/tools/verify_release.py --rojo rojo
rojo build products/accessforge/tests/place.project.json -o products/accessforge/tests/AccessForge-QA.rbxl
rojo build products/accessforge/tests/runner.project.json -o /tmp/AccessForgeTests.rbxm
```

Install the commercial artifact and the separate test runner in Studio's **Plugins Folder**, restart Studio and open the QA place in edit mode. Read `[AccessForgeTests]` in Output. The suite imports the exact commercial binary, uses native ChangeHistoryService Undo/Redo and modifies only disposable fixtures. Remove the test runner afterwards. It is not a customer dependency.

Run the GUI sequence in `tests/RESULTS.md`; a compiled script alone is not a Studio PASS. Do not publish the QA or media place as the plugin.
