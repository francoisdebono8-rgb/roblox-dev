# PresetForge 2.1 quick guide

PresetForge bulk-edits a controlled set of Roblox properties through auditable recipes.

## Source to Apply

1. **Source:** Select exactly one supported, correctly configured instance.
2. **Fields:** Choose **Save Recipe**, select only the properties Apply may change, and independently choose Tags or Attributes if needed. The current source value appears beside every property.
3. **Library:** Choose **Local** for this Studio installation or **Project** for a recipe stored transparently in the place.
4. **Scope:** Select target objects for **Selection**, or select containers for **Descendants**.
5. **Filter:** In Descendants mode choose an allowed class/type. Optionally narrow by name text and tag.
6. **Preview:** Changes appear first. Matching and ignored details remain collapsed until requested. Select a result or the affected group to locate it in Explorer; Frame affected fits available 3D bounds in the scene camera.
7. **Apply:** Apply only after reviewing the current Preview. If a target or selected value changed, PresetForge refreshes the Preview and requires another review.
8. **Undo:** One Studio Undo restores the complete Apply; Redo reapplies it.

Capture and Preview do not modify source/target objects. Saving Local recipes writes Studio settings. Saving Project recipes changes the place's library under ServerStorage. Frame only changes the editing camera; Select only changes Studio selection.

## Supported fields

- **BasePart:** `Anchored`, `CanCollide`, `CanTouch`, `CanQuery`, `Transparency`, `CastShadow`, `Massless`.
- **PointLight:** `Enabled`, `Brightness`, `Color`, `Shadows`, `Range`.
- **SpotLight / SurfaceLight:** the light fields above plus `Angle` and `Face`.
- **Sound:** `SoundId`, `Volume`, `PlaybackSpeed`, `Looped`, `RollOffMinDistance`, `RollOffMaxDistance`, `RollOffMode`.
- **ParticleEmitter:** `Enabled`, `Texture`, `Rate`, `Lifetime`, `Speed`, `Color`, `Transparency`, `Size`, `LightEmission`, `LightInfluence`, `ZOffset`, `Rotation`, `RotSpeed`, `Orientation`.
- **Decal:** `ColorMap`, `Color3`, `Transparency`, `Face`.
- **Texture:** Decal fields plus `StudsPerTileU`, `StudsPerTileV`, `OffsetStudsU`, `OffsetStudsV`.
- **GuiObject:** `Visible`, `Active`, background and border fields, `Position`, `Size`, `AnchorPoint`, `Rotation`, `ZIndex`, `LayoutOrder`, `AutomaticSize`.
- **ProximityPrompt:** `Enabled`, text fields, hold/distance/line-of-sight fields, input keys, click behavior, and `Exclusivity`.
- **Configuration:** tags and attributes only.

Persisted property names and values are revalidated against this list before Preview and Apply. Unknown or wrong-typed data is rejected.

## Scope and preservation

Selection processes only the selected instances. Descendants processes descendants of selected containers, never the containers themselves, and requires an allowed class filter.

Recipe tags are added when missing; other tags are preserved. Recipe attributes are added or updated; unrelated attributes are preserved. Unselected properties are never written.

## Edit and recapture

The Library view searches names without changing the chosen recipe. Duplicate creates an independent recipe in the same Local/Project library under a new unique name. Select a compatible configured source and Edit the variant to change its field set and values; the original remains unchanged.

**Edit** reads values from one selected source of the recipe's current class and lets you change the included field set. **Recapture** refreshes values while preserving the existing field set. A recapture to another supported class is accepted only when every selected property is valid there; otherwise it is refused with the invalid field name.

## Local and Project libraries

Local recipes use Studio plugin settings. Existing V1 presets load as BasePart recipes with their original seven-property selection and are persisted as V2 after their next edit.

Project recipes are created only when **Project** is explicitly selected. They live under `ServerStorage/PresetForgeProjectRecipes` as `Configuration`, `Folder`, and `StringValue` instances, so teams can inspect and version them. Loading a project library never executes scripts, and malformed, executable, unknown-property, duplicate, or cross-library conflicting records are rejected.

PresetForge has no cloud sync, recipe stacks, favorites, arbitrary property editing, or destructive descendant cleanup. Its property whitelist and storage format are unchanged from 2.0.
