# PresetForge quick guide

## Save a preset

1. Select one configured `BasePart`.
2. Open PresetForge from the Plugins toolbar.
3. Choose **Save Preset**.
4. Enter a unique name and explicitly enable the categories to capture.
5. Choose **Save**.

Properties are limited to Anchored, collision/query/touch behavior, Transparency, CastShadow, and Massless. Save never changes the place.

## Preview and apply

1. Select the target instances.
2. Select a preset in the PresetForge library.
3. Choose **Preview** and review compatible, ignored, and pending change counts.
4. Choose **Apply**.

Only selected BaseParts are changed. Preset tags are added; existing tags stay. Preset attributes are added or updated; all other attributes stay. Apply is unavailable until a valid Preview contains at least one change.

Use Studio **Undo** once to restore the complete application.

## Manage presets

Use **Rename** to give the selected preset a new unique name. Use **Delete**, then **Confirm**, to remove it. Presets are stored locally for the current Studio installation and do not require a network connection.
