# PresetForge V1 Studio release checklist

Run this checklist with the locally assembled plugin from `products/presetforge/README.md`. Start with a blank place and keep Output visible.

## Installation and persistence

- [ ] The plugin installs without a third-party tool or dependency.
- [ ] The Plugins toolbar button opens and closes a dockable PresetForge widget.
- [ ] Run the automated test package and confirm `3/3 PresetForge specs passed`.
- [ ] Save two presets, close Studio completely, reopen Studio and the place, then confirm both presets remain with their values intact.
- [ ] Disable network access and confirm all preset workflows still work.

## Save and management

- [ ] With no selection, Save reports that exactly one BasePart is required and creates nothing.
- [ ] With two selected BaseParts, Save reports that exactly one BasePart is required and creates nothing.
- [ ] With one non-BasePart selected, Save reports that a BasePart is required and creates nothing.
- [ ] With no capture category selected, Save refuses to create a preset.
- [ ] Save a valid preset and confirm the place itself is unchanged.
- [ ] Confirm Name, Parent, CFrame, Position, Size, Material, and Color were not captured.
- [ ] Create two presets, then try to rename one to the other's name with different letter casing; confirm the rename is refused.
- [ ] Rename a preset to a unique valid name and confirm it persists.
- [ ] Choose Delete once and confirm nothing is deleted; choose Confirm and confirm the preset is removed and stays removed after restart.

## Preview

- [ ] With no targets selected, Preview reports zero compatible targets and Apply stays disabled.
- [ ] Select two Parts and one Model; Preview reports 3 selected, 2 compatible, and 1 ignored.
- [ ] Configure the source and targets so each whitelist property differs; confirm Preview lists Anchored, CanCollide, CanTouch, CanQuery, Transparency, CastShadow, and Massless with correct target counts.
- [ ] Confirm Preview lists preset tags only where they need to be added.
- [ ] Confirm Preview distinguishes attributes to add from attributes to update.
- [ ] Snapshot target properties, tags, and attributes, run Preview repeatedly, and confirm nothing changes.
- [ ] Change the selection after Preview and confirm Apply becomes disabled until Preview runs again.
- [ ] Change a target value after Preview, choose Apply, and confirm PresetForge refreshes the Preview and asks for review before applying.

## Apply and Undo

- [ ] With no compatible target, Apply cannot be activated.
- [ ] Apply to several selected BaseParts and confirm every compatible target receives all seven captured property values.
- [ ] Confirm selected non-BaseParts are unchanged.
- [ ] Confirm target Material, Color, Size, CFrame, Name, and Parent are unchanged.
- [ ] Give a target an existing unrelated tag, Apply, and confirm that tag remains while the preset tag is added.
- [ ] Give a target an unrelated attribute, Apply, and confirm it remains unchanged.
- [ ] Give a target an attribute with the same key as the preset, Apply, and confirm the preset value replaces it with the correct Roblox type.
- [ ] Confirm the success message reports compatible targets and actual property, tag, and attribute writes.
- [ ] Use Studio Undo once and confirm every property, added tag, and added/updated attribute returns to its exact previous state on all targets.
- [ ] Use Studio Redo once and confirm the complete Apply returns.
- [ ] Confirm Output contains no PresetForge error or warning during the successful workflow.

## Creator Store capture pass

- [ ] Dock the widget at its minimum supported size and confirm no controls or text overlap.
- [ ] Resize the widget wider and taller and confirm the preset list and detail view remain readable.
- [ ] Capture the three frames specified in `docs/STORE_LISTING.md` with no private project data visible.
- [ ] Review the Creator Store text, version `1.0.0`, privacy note, and screenshots before publication.
