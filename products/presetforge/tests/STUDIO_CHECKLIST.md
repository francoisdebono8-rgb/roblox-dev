# PresetForge 2.0 Studio acceptance checklist

Run this short human pass on the final `PresetForge-v2.0.0.rbxm`. Keep Explorer, Properties, and Output visible. Automated coverage is separate and must report `6/6 PresetForge specs passed`.

## Core workflow

- [ ] The toolbar opens one dockable widget; the 620x520 minimum and a larger size have no overlap or clipped controls.
- [ ] Save a recipe from one supported source with two checked properties, one unchecked property, Tags, and Attributes. Confirm Save changes no target or place data.
- [ ] Edit the recipe to change its field set, then Recapture from one compatible source. Confirm the chosen fields and new values are shown correctly.
- [ ] Recapture from a source lacking one chosen field and confirm the operation is refused with that field named.
- [ ] Rename and confirmed Delete work; a first Delete click alone removes nothing.

## Scope, Preview, and selection

- [ ] In Selection mode use mixed compatible/incompatible objects. Confirm all five counts and each full-path result are correct.
- [ ] In Descendants mode select a model, choose a supported class, then exercise name and tag filters. Confirm nothing outside the visible filter result is affected.
- [ ] Confirm property, tag, and attribute before/after rows are correct and Preview is read-only.
- [ ] Use Select affected, matching, ignored, and one result; confirm Studio Selection matches each command.
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
