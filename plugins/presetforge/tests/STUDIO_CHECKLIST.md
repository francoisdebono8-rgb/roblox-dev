# PresetForge 2.1 Studio acceptance checklist

Run this human pass on the final `PresetForge-v2.1.0.rbxm`. Keep Explorer, Properties, and Output visible. Build and run the separate final-binary gate using [FINAL_GATE.md](FINAL_GATE.md); expected native success is `41/41 checks passed`, including the six original specs. Record PASS / FAIL / NOT TESTED independently for the human checks.

## Core workflow

- [ ] The toolbar opens one dockable widget; widths 240 / 320 / 400 / 560 and heights 360 / 640 / 900 have no horizontal clipping. All four tabs, capture fields, Preview/Apply, and Save/Cancel remain reachable.
- [ ] Header and action footer remain fixed while content scrolls. Focus, selection, and unsaved draft fields survive the expected re-renders.
- [ ] Save a recipe from one supported source with two checked properties, one unchecked property, Tags, and Attributes. Confirm Save changes no target or place data.
- [ ] Edit the recipe to change its field set, then Recapture from one compatible source. Confirm the chosen fields and new values are shown correctly.
- [ ] Recapture from a source lacking one chosen field and confirm the operation is refused with that field named.
- [ ] Rename and confirmed Delete work; a first Delete click alone removes nothing.
- [ ] Search a populated Local/Project library with mixed case and literal punctuation such as `[`, `%`, and `.*`.
- [ ] Duplicate a recipe, edit the variant's fields/tags/attributes, and reopen both recipes. The original remains exact.
- [ ] Change selection with an open capture draft. The draft remains, but Save refuses to capture the wrong source.
- [ ] Project storage copy explicitly says saving writes to the place; Local storage copy identifies Studio settings.

## Scope, Preview, and selection

- [ ] In Selection mode use mixed compatible/incompatible objects. Confirm all five counts and each full-path result are correct.
- [ ] In Descendants mode select a model, choose a supported class, then exercise name and tag filters. Confirm nothing outside the visible filter result is affected.
- [ ] Confirm property, tag, and attribute before/after rows are correct and Preview is read-only.
- [ ] Changed objects appear first with stable ordering, including duplicate object names. Matching/ignored groups start collapsed and expand correctly.
- [ ] Long paths and exact before/after values wrap without truncation.
- [ ] Use Select affected, matching, ignored, and one result; confirm Studio Selection matches each command.
- [ ] Frame affected moves the camera to the correct spatial bounds without changing objects. Nonspatial selections produce a useful message.
- [ ] Change a selected recipe property after Preview. Apply must refresh/invalidate the Preview instead of writing.

## Apply and persistence

- [ ] Apply to multiple compatible objects. Confirm only checked fields change and unrelated properties, tags, and attributes remain exact.
- [ ] Undo once restores the complete Apply on every target; Redo once restores it.
- [ ] Create one Local and one Project recipe. Confirm Project data appears only after the explicit Project save and contains no Script or ModuleScript.
- [ ] Restart Studio and confirm Local and Project recipes, edited fields, rename, and deletion state persist.
- [ ] Load an existing V1 preset and confirm it behaves as a seven-field BasePart recipe.
- [ ] Complete the workflow offline and confirm Output contains no PresetForge error or warning.

## Publication

- [ ] Capture the three scenarios in `docs/STORE_LISTING.md` with no private project or account data.
