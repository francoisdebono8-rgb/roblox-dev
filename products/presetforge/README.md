# PresetForge V1

PresetForge is a compact Roblox Studio plugin for saving a BasePart setup and applying it safely to a selection.

**Promise:** Save a setup once. Apply it to a whole selection safely.

## V1 behavior

- Captures exactly one selected `BasePart`.
- Lets the user explicitly choose Properties, Tags, Attributes, or any combination.
- Captures only `Anchored`, `CanCollide`, `CanTouch`, `CanQuery`, `Transparency`, `CastShadow`, and `Massless` as properties.
- Adds preset tags without removing existing tags.
- Adds or updates preset attributes without removing other attributes.
- Ignores non-BasePart targets and reports them in Preview.
- Makes Save and Preview read-only operations.
- Applies the complete selection in one supported Change History recording for one-step Undo.
- Stores presets locally with `Plugin:GetSetting` and `Plugin:SetSetting`.

There are no external dependencies, network calls, analytics, telemetry, or unnecessary permissions.

## Install PresetForge 1.0

The versioned release package is [`dist/PresetForge-v1.0.0.rbxm`](dist/PresetForge-v1.0.0.rbxm). Installation requires only Roblox Studio:

1. Open a blank place and show **View > Explorer**.
2. In Explorer, right-click `Workspace` and choose **Insert from File...**.
3. Select `PresetForge-v1.0.0.rbxm`.
4. Right-click the inserted `PresetForge` model and choose **Save as Local Plugin**.
5. Delete the temporary model from `Workspace` without saving the blank place.
6. Open PresetForge from the Studio **Plugins** toolbar. Restart Studio if the button does not appear immediately.

The package has no external runtime dependency. Its SHA-256 and package contents are documented in [`dist/README.md`](dist/README.md).

## Package structure

The release package contains only the product entry point and eleven production modules:

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
   |- StringCodec
   `- UIFactory
```

It does not contain tests, QA fixtures, build scripts, local paths, or project data.

## Assemble from source

The repository intentionally does not require a build tool. Maintainers can reproduce the model manually in Roblox Studio:

1. Open a blank Studio place and show **View > Explorer** and **View > Properties**.
2. Insert a `Model` named `PresetForge` into the place temporarily.
3. Inside it, insert a `Folder` named `Modules`.
4. For every file in `PresetForge/Modules`, create a `ModuleScript` with the same base name and paste the source. For example, `ApplyService.luau` becomes `ApplyService`.
5. Inside the `PresetForge` model, create a regular `Script` named `Main` and paste `PresetForge/Main.plugin.luau` into it.
6. Right-click the `PresetForge` model and choose **Save as Local Plugin**. Confirm the local installation.
7. Remove the temporary model from the place. Open PresetForge from the Studio **Plugins** toolbar.

## Automated Studio tests

The specs run inside Studio without a third-party test framework.

1. In `ServerScriptService`, create a `Folder` named `PresetForgeTestPackage`.
2. Under it, reproduce the `PresetForge/Modules` folder from the plugin source. Do not add or run `Main` in this test package.
3. Add a sibling `Folder` named `tests`.
4. Copy each `tests/*.spec.luau` file into a same-named `ModuleScript` under `tests`.
5. Copy `tests/TestRunner.server.luau` into a regular `Script` named `TestRunner` under `tests`.
6. Start Play and verify that Output reports `3/3 PresetForge specs passed` with no failure.

The expected test hierarchy is:

```text
ServerScriptService
`- PresetForgeTestPackage
   |- PresetForge
   |  `- Modules
   `- tests
      |- TestRunner (Script)
      |- ApplyService.spec (ModuleScript)
      |- CapturePreview.spec (ModuleScript)
      `- PresetStore.spec (ModuleScript)
```

Complete the real plugin checks in [`tests/STUDIO_CHECKLIST.md`](tests/STUDIO_CHECKLIST.md), especially one-step Undo and persistence after restarting Studio.

## Source map

- `Main.plugin.luau`: plugin toolbar, DockWidget, and service wiring.
- `Controller.luau`: UI state and end-to-end workflow.
- `CaptureService.luau`: exact capture boundary.
- `PreviewService.luau`: read-only change calculation.
- `ApplyService.luau`: transactional application and rollback.
- `PresetStore.luau` and codecs: verified local persistence.
- `UIFactory.luau`: dependency-free Studio interface.

## Product documents

- [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md): short customer guide.
- [`docs/STORE_LISTING.md`](docs/STORE_LISTING.md): publication copy and screenshot plan.
- [`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md): final pre-upload checks.
- [`tests/STUDIO_CHECKLIST.md`](tests/STUDIO_CHECKLIST.md): release acceptance pass.
