# PresetForge / Creator Store copy

Prepared 2026-10-03 for #38. Not uploaded. Status: **READY EXCEPT MEDIA**.

## Title
PresetForge - Preview Exact Bulk Changes

## One-line promise
See exactly which objects and fields will change before applying a saved recipe.

## Short description
Choose recipe fields, filter targets, inspect Before/After, then Apply the affected subset. Keep unrelated settings unchanged.

## Full description
Bulk edits should not be a guessing game.

PresetForge saves selected properties, tags and attributes as reusable recipes. Choose Selection or filtered Descendants, then Preview. Changes shows the affected objects, exact Before/After values and the number that will change. Matching objects stay separate; ignored objects are explained. Apply N commits the reviewed changes with Studio Undo.

Capture individual fields, edit or duplicate a recipe, and keep it locally or with the project. Supported families include parts, lights, sounds, particles, decals, textures, GUI objects, prompts and configuration metadata, with a controlled property list for each.

For simple copies, native Properties or free copy/paste tools suffice. PresetForge focuses on exact targets and reviewed differences.

Supported classes/fields only. Preview is read-only; changed scenes need a fresh plan. No network calls or telemetry. Local recipes use Studio settings; Project recipes stay in the place.

## Search terms
bulk edit, property presets, before after, recipe, tags, attributes, filtered descendants, batch properties, safe apply, Roblox Studio

## Privacy and limits
- No HTTP requests, analytics, remote library or external account. Local recipes use Plugin GetSetting/SetSetting; Project recipes live under ServerStorage and are visible to place collaborators. Saving a Project recipe changes the place; Preview does not.
- Controlled families: BasePart, PointLight, SpotLight, SurfaceLight, Sound, ParticleEmitter, Decal, Texture, common GuiObject fields, ProximityPrompt and Configuration metadata. One family per recipe; not arbitrary classes, references or scripts. Exact fields are defined in `PresetForge/Modules/Schema.luau`.
- Selected tags are added and selected attribute values are set; unrelated tags/attributes remain. This is not a tag removal tool or a recipe-stack engine.
- Caps: 256 selection roots, 20,000 scanned descendants, 5,000 compatible targets, 2,000 affected targets, 20,000 writes. At most 500 result rows rendered, 256 recipes, 64 tags and 64 attributes per recipe.
- Local storage is not a cloud backup or restart-persistence guarantee from the current GUI session. Stale checks/Undo do not guarantee simultaneous Team Create transactions. Narrow oversized scopes.

## Version and asset
Internal **2.2.0** / **Forge Studio 0.2.5**, canonical plugin **73596873703054**. [Exact artifact](LAUNCH_CHECKLIST.md), not the older 2.0 or 2.1 release file.

## Market and launch price
Recommendation: **4.99 USD**, an unvalidated one-time launch hypothesis. No price was set.

| Substitute | Evidence inspected 2026-10-03 | Why pay, or not |
| --- | --- | --- |
| [Copy&PasteProperties](https://create.roblox.com/store/asset/132373628730536/CopyPasteProperties) | Live page: free acquisition, updated Jun 19, 2025; selectable-property presets and keyboard shortcuts | Do not sell field selection or presets as exclusive. Prefer it for quick transfers without a detailed target review. |
| [Preset Manager](https://devforum.roblox.com/t/preset-manager-plugin-bulk-apply-properties-attributes-tags-and-collisions/1187701) | Author documents bulk properties, attributes, tags, collision groups and a library; current checkout price not reverified | Substantial functional overlap. Do not claim this concept is new or the alternative abandoned. |
| [Native Properties](https://create.roblox.com/docs/studio/properties) | Native editing has no extra plugin purchase | Best for a small, known selection; no need for an extra tool on every edit. |

The paid proposition is the explicit affected subset plus per-object Before/After and one reviewed Apply action, not more presets. Launch at the paid floor because free overlap is strong; a higher price lacks evidence. Listings were inspected, not installed or benchmarked. No claim that competitors lack unadvertised capabilities.

## Forbidden claims
No unique/only presets, support for all properties, perfect concurrent editing, unlimited targets, automatic backup, measured percentage savings, invented sales/reviews or free plugin ownership through the Playground.
