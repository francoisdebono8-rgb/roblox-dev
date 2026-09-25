# PresetForge 1.0 quick guide

PresetForge saves a trusted `BasePart` setup as a local preset, previews every pending change, and applies that setup safely across a Studio selection.

## The one-minute workflow

1. **Save Preset:** Select one configured `BasePart`, choose **Save Preset**, name it, and enable Properties, Tags, Attributes, or any combination.
2. **Preview:** Select the target instances, choose the preset, then choose **Preview**. Review the selected, compatible, ignored, and pending change counts.
3. **Apply:** Choose **Apply** only after the Preview looks right. Non-`BasePart` selections are ignored.
4. **Undo:** Use Studio **Undo** once to restore the complete Apply. Studio **Redo** reapplies it.

Save and Preview are read-only. Apply stays disabled until a reviewed Preview contains at least one compatible target and one pending change.

## Properties supported in V1

- `Anchored`
- `CanCollide`
- `CanTouch`
- `CanQuery`
- `Transparency`
- `CastShadow`
- `Massless`

PresetForge does not capture names, parents, transforms, position, size, material, or color.

## Tags and attributes

- Preset tags are added when missing. Existing unrelated tags are never removed.
- Preset attributes are added or updated. Existing unrelated attributes are never removed.
- A selected Model or other non-`BasePart` instance is reported as ignored; its descendants are not processed.

## Preset library

Use **Rename** to assign a unique name. Use **Delete**, then **Confirm**, to remove a preset.

Presets are stored locally by Roblox Studio on this installation. PresetForge has no cloud sync, import/export, network requests, analytics, or telemetry.
