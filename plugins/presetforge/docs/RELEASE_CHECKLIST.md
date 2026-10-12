# PresetForge 2.0 release checklist

Use this checklist on the exact `.rbxm` selected for Creator Store upload.

## Automated evidence

- [x] Every production and test `.luau` file compiles with the Luau compiler.
- [x] The isolated Studio harness reports `6/6` deterministic specs passed.
- [x] The short real-project validation was completed without modifying upstream copies.

## Before upload

- [ ] Confirm the upload file is `PresetForge-v2.0.0.rbxm` and its SHA-256 matches `dist/README.md`.
- [ ] Inspect the package: `Main` plus sixteen production modules only; no tests, fixtures, paths, or project data.
- [ ] Install the exact package in a clean Studio session and confirm the toolbar button opens one dockable widget.
- [ ] Complete every item in `tests/STUDIO_CHECKLIST.md`, including native Undo/Redo and restart persistence.
- [ ] Check the widget at 620x520 and at a larger size for clipping, overlap, and usable scrolling.
- [ ] Verify a Project save is explicit and creates only `ServerStorage/PresetForgeProjectRecipes` native data.
- [ ] Verify the complete workflow with network access disabled.
- [ ] Capture the three Store frames with no private data, then review their legibility at listing size.
- [ ] Review the final title, descriptions, boundaries, privacy note, and version `2.0.0`.
