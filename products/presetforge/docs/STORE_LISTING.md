# Creator Store listing

## Product name

PresetForge - Safe Bulk Part Presets

## Tagline

**Save once. Preview changes. Apply safely.**

## Short description

Save a trusted BasePart setup, preview bulk changes, and apply properties, tags, and attributes with one-step Studio Undo.

## Full description

PresetForge turns a configured `BasePart` into a reusable local preset so repeated Studio setup stays fast, visible, and controlled.

Choose exactly what the preset captures: seven focused behavior properties, tags, attributes, or any combination. Select your targets and run Preview to see compatible parts, ignored instances, and every pending write before the place changes. Apply only after the result looks right.

Save and Preview are read-only. Apply changes only the selected compatible `BasePart` instances and records the complete operation for one-step Studio Undo. Existing unrelated tags and attributes remain intact.

### V1 features

- Local persistent preset library
- Explicit Properties, Tags, and Attributes capture
- Read-only change Preview before Apply
- Bulk Apply across selected BaseParts
- Mixed selections with non-BaseParts reported as ignored
- Existing unrelated tags and attributes preserved
- One-step Undo for each complete Apply
- Rename and confirmed deletion
- No network, analytics, telemetry, or external dependencies

### Properties supported in V1

`Anchored`, `CanCollide`, `CanTouch`, `CanQuery`, `Transparency`, `CastShadow`, and `Massless`.

### V1 limitations

- Presets target `BasePart` instances only. Models and other instance types are ignored; descendants are not processed.
- Names, parents, transforms, position, size, material, and color are not captured.
- Preset tags are added but do not remove other tags.
- Preset attributes are added or updated but do not remove unrelated attributes.
- Presets are local to the current Roblox Studio installation. V1 has no sharing, cloud sync, import, or export.

## Creator Store metadata

- Category: Studio Plugins / Productivity
- Version: 1.0.0
- Support note: Uses Roblox Studio local plugin settings and Change History APIs.
- Privacy note: PresetForge makes no network requests and collects no data.
- Search terms: BasePart presets, bulk properties, batch edit, tags, attributes, part setup, Studio productivity, Roblox Studio plugin

## Three screenshots

Use a neutral gray Studio theme, the PresetForge teal accent, a readable 100% UI scale, and a 16:9 crop. Hide unrelated plugins, account details, private project names, and personal data.

1. **Save setup once:** Show one clearly configured Part selected in a neutral blank place. Keep Explorer and Properties visible, and open the Save Preset dialog with a short name plus Properties, Tags, and Attributes selected. Caption: `Save the setup you trust.`
2. **Preview bulk changes:** Show two target Parts and one Model selected. The widget must visibly report `3 selected`, `2 compatible`, `1 ignored`, plus property, tag, and attribute changes. Caption: `Review every bulk change first.`
3. **Apply safely + Undo:** Show the updated Parts and the green success feedback with write counts and the one-Undo statement. Keep one unrelated tag or attribute visible in Properties to demonstrate preservation. Caption: `Apply safely. Undo in one step.`

## Thumbnail concept

Use a tight 1:1 crop with the name `PresetForge` in large high-contrast type, a single teal accent, and three simple Part silhouettes moving from one configured source to a small group. Add the short line `Safe bulk presets` only if it remains readable at thumbnail size. Do not show ratings, download counts, price claims, badges, or other invented marketing figures.
