# PresetForge 2.0

PresetForge is a Safe Bulk Editor for Roblox Studio.

**Promise:** Bulk-edit exactly what you want, exactly where you want. Preview every change. Undo safely.

## What 2.0 does

- Saves property-by-property recipes from one configured source instance.
- Supports a controlled schema for `BasePart`, the three Studio light classes, `Sound`, `ParticleEmitter`, `Decal`, `Texture`, common `GuiObject` properties, `ProximityPrompt`, and `Configuration` tags/attributes.
- Targets either the current Selection or filtered descendants of selected containers.
- Requires a supported class filter in Descendants mode, with optional name and tag filters.
- Shows scanned, compatible, affected, matching, and ignored counts plus a per-object before/after diff.
- Selects affected, matching, ignored, or individual results back in Studio.
- Edits a recipe's included fields and recaptures values while preserving its field set.
- Keeps a local library and an explicitly created, Roblox-native project library.
- Reads V1 local presets and writes them as V2 when they are next changed.

Save and Preview are read-only. Apply validates every stored property against the central schema, changes only affected compatible targets, and uses one Change History recording. Existing unrelated properties, tags, and attributes remain untouched.

There are no external runtime dependencies, network calls, analytics, telemetry, cloud services, AI features, or arbitrary code execution.

## Install PresetForge 2.0

The final package is [`dist/PresetForge-v2.0.0.rbxm`](dist/PresetForge-v2.0.0.rbxm).

1. Open a blank place and show **View > Explorer**.
2. Right-click `Workspace` and choose **Insert from File...**.
3. Select `PresetForge-v2.0.0.rbxm`.
4. Right-click the inserted `PresetForge` model and choose **Save as Local Plugin**.
5. Delete the temporary model without saving the blank place.
6. Open PresetForge from the Studio **Plugins** toolbar. Restart Studio if the button does not appear immediately.

The package hash and exact hierarchy are recorded in [`dist/README.md`](dist/README.md).

## Package structure

The release contains `Main` and sixteen production modules only:

```text
PresetForge
|- Main (Script)
`- Modules (Folder)
   |- ApplyService
   |- AttributeCodec
   |- CaptureService
   |- Constants
   |- Controller
   |- PresetSerializer
   |- PresetStore
   |- PresetValidator
   |- PreviewService
   |- ProjectStore
   |- RecipeRepository
   |- Schema
   |- StringCodec
   |- TargetResolver
   |- UIFactory
   `- ValueCodec
```

It contains no tests, fixtures, project recipes, local paths, or private data.

## Build from source

With Rojo 7 installed:

```sh
rojo build release.project.json -o dist/PresetForge-v2.0.0.rbxm
```

The product itself does not require Rojo at runtime. The source can also be assembled manually by reproducing the hierarchy above and using the corresponding `.luau` source for each script.

## Deterministic Studio tests

Six framework-free specs cover schema and type validation, exact-field capture, read-only and stale Preview behavior, Selection and Descendants scopes, filters and result sets, Apply/rollback recording, V1 migration, edit/recapture persistence, and local/project library safety.

Build the place harness, open it in Studio, and start Play:

```sh
rojo build tests/default.project.json -o /tmp/PresetForgeStudioTests-v2.rbxl
```

Expected Output: `6/6 PresetForge specs passed` with no `[FAIL]` line. A plugin-mode harness is also available in `tests/plugin.project.json` for isolated automated release runs.

Complete the short human pass in [`tests/STUDIO_CHECKLIST.md`](tests/STUDIO_CHECKLIST.md). The repository does not claim those visual and native Undo/Redo checks have passed until a person performs them on the final package.

## Product documents

- [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md): customer workflow and supported fields.
- [`docs/STORE_LISTING.md`](docs/STORE_LISTING.md): publication copy and three screenshot scenarios.
- [`docs/REAL_PROJECT_VALIDATION.md`](docs/REAL_PROJECT_VALIDATION.md): short read-only validation against the issue corpus.
- [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md): final pre-upload checks.
- [`tests/STUDIO_CHECKLIST.md`](tests/STUDIO_CHECKLIST.md): short Studio acceptance pass.
