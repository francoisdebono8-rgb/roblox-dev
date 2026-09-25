# PresetForge 1.0 final release checklist

Use this short checklist on the exact `.rbxm` selected for Creator Store upload.

## Already validated

- [x] Human Studio workflow: Save Preset -> Preview -> Apply -> Undo.

## Before upload

- [ ] Confirm the upload file is named `PresetForge-v1.0.0.rbxm` and its SHA-256 matches `dist/README.md`.
- [ ] Inspect the package hierarchy: `Main` plus the eleven production modules only; no tests, QA fixtures, local paths, or private data.
- [ ] Install the package in a clean Studio session and confirm the Plugins button opens and closes the widget.
- [ ] Run the Studio test package and confirm `3/3 PresetForge specs passed` with no `[FAIL]` output.
- [ ] Save two presets, restart Studio, and confirm both reload with their values intact.
- [ ] With network access disabled, confirm Save, Preview, Apply, Rename, Delete, Undo, and preset reload still work.
- [ ] Check the widget at its minimum size and at a larger size for clipped or overlapping text and controls.
- [ ] Capture and review the three 16:9 frames in `STORE_LISTING.md`; remove private project and account data.
- [ ] Review the final Creator Store title, descriptions, search terms, V1 limitations, version `1.0.0`, and privacy note.
