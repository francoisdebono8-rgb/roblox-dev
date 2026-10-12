# Studio Features opportunity mine

Source hub: https://devforum.roblox.com/c/feature-requests/studio-features/24

Started: 2026-09-27.

Goal: turn real Roblox Studio feature-request pain into Forge product candidates. A request is not enough by itself. Every candidate must pass:
1. plugin API feasibility;
2. native-Studio current-state check;
3. Creator Store competitor audit;
4. evidence that the pain is broader than one post;
5. a clear paid workflow advantage.

Do not copy competitor code, assets, UI, branding or implementation.

---

## Current lead — SchemaForge / ConfigForge (name TBD)

### Problem cluster

Several independent feature requests point at the same deeper problem: large projects use tags + attributes as an informal configuration/schema system, but Studio does not give teams a good way to document, validate and audit that configuration.

Sources:

1. **Custom descriptions for attributes in the properties panel** — June 2, 2026  
   https://devforum.roblox.com/t/custom-descriptions-for-attributes-in-the-properties-panel/4664872  
   Team problem: programmers create attributes for artists/designers, but Studio gives no project-specific descriptions/documentation.

2. **Highlight instances with tags or attributes in the explorer** — September 25, 2025  
   https://devforum.roblox.com/t/highlight-instances-with-tags-or-attributes-in-the-explorer/3957685  
   Large-world problem: configured instances are widespread and developers need to see which objects carry tags/attributes and detect missed configuration.

3. **Instance icons should be customizable based on tags or attributes** — June 23, 2026  
   https://devforum.roblox.com/t/instance-icons-should-be-customizable-based-on-tags-or-attributes/4694640  
   Semantic problem: tag-driven objects function like custom classes but are hard to distinguish in Studio.

4. **Parity between the Query language and Explorer (& more syntax)** — September 25, 2026  
   https://devforum.roblox.com/t/parity-between-the-query-language-and-explorer-more-syntax/4893794  
   Concrete QA problem: author tried to find invalid rail models (missing children / wrong sizes), ended up combining QueryDescendants, temporary tags, Explorer search and Vector3 checks.

5. **Are there any faster ways to add attributes?** — September 20, 2024  
   https://devforum.roblox.com/t/are-there-any-faster-ways-to-do-add-attributes/3165640  
   Support-thread evidence that developers with heterogeneous towers/enemies struggle to configure many instances manually.

### Existing alternatives checked

- Roblox native Tag Editor: manages/visualizes tags, not a project-specific configuration schema validator.
  https://devforum.roblox.com/t/tag-editor-plugin-for-studio/2055202
- Attribute Manager (2021): search/rename/edit attributes; older and not positioned around schemas, required fields, documentation or validation.
  https://devforum.roblox.com/t/attribute-manager-plugin-for-all-your-attribute-needs/1562593
- Attribute Tools (Creator Store, 2022): bulk-add attributes; not a schema/audit workflow.
  https://create.roblox.com/store/asset/9516206594/Attribute-Tools
- Attribute Clipboard: copy/paste attributes.
  https://create.roblox.com/store/asset/73182638914598/Attribute-Clipboard
- Virgo (2026, $4.99): rename/recolor/add attributes; public listing does not establish a schema-validation workflow.
  https://create.roblox.com/store/asset/89487356614253/Virgo
- PresetForge: our own product already applies recipes/attributes/tags. A new product must not merely duplicate PresetForge.

### Product hypothesis

**SchemaForge — Project Configuration Validator**

Define a project schema such as:

- Tag: `Door`
- required attributes:
  - `Locked: boolean`
  - `OpenSpeed: number 0..10`
  - `AccessLevel: number 0..5`
- required/optional children:
  - `HingeAttachment`
  - `Prompt`
- project-facing descriptions for designers.

Then SchemaForge:
- documents each field for non-programmers;
- scans selected scope / project;
- lists valid / missing / wrong-type / out-of-range instances;
- highlights/selects invalid objects;
- optionally adds safe missing defaults after Preview;
- supports saved project schemas;
- never executes project code;
- Undo for fixes.

**Paid boundary hypothesis:** not “edit attributes faster,” but “make tag/attribute-driven level design auditable and understandable for a team.”

### Status

**PROMISING / NOT APPROVED YET.**

Before Product 5 development:
- exact Creator Store audit for schema/config validators;
- verify plugin APIs can provide a clean validation/highlight workflow;
- inspect 2–3 real open-source projects using tag+attribute component patterns;
- make sure this is sufficiently distinct from PresetForge.

---

## Medium lead — TemplateForge / StarterForge

### Evidence

**Allow developers to save places as studio templates**  
https://devforum.roblox.com/t/allow-developers-to-save-places-as-studio-templates/241595

- 100+ likes in the thread.
- Thousands of views.
- Continued activity / workaround discussion in 2025.
- Use cases: default lighting, baseplates, script libraries, standard folder structures, green-screen/render places.

Related workaround:
https://devforum.roblox.com/t/how-to-make-custom-place-templates/3888845

### Problem

Roblox still does not provide the exact native custom-template workflow requested.

### Risk

A normal plugin cannot simply add arbitrary entries to Studio's native start-page template UI. A product would likely need to be reframed as a **project starter / template injector** inside an already-open place.

### Status

**MEDIUM.** Strong demand, but feasibility/UX may make the result feel like a workaround rather than a premium product.

---

## Medium lead — ImportForge

### Evidence

**Ability to bulk retarget file locations on import** — May 12, 2026  
https://devforum.roblox.com/t/ability-to-bulk-retarget-file-locations-on-import/4632609

**Studio Asset Upload UX** — January 26, 2026  
https://devforum.roblox.com/t/studio-asset-upload-ux/4298732

Problems include:
- texture paths breaking across collaborator machines;
- fixing mappings one by one;
- friction choosing creators/experiences;
- bulk image naming.

### Opportunity hypothesis

Batch import preflight / remapping / naming assistant.

### Risk

Plugin filesystem and import-pipeline APIs may not expose enough control. Roblox staff also indicated they have discussed improving the native workflow.

### Status

**MEDIUM / FEASIBILITY FIRST.**

---

## Small lead — PaletteForge

### Evidence

**Better custom color/gradient palette saving/history**  
https://devforum.roblox.com/t/better-custom-colorgradient-palette-savinghistory/3115644

Pain:
- weak custom-color history;
- easy accidental overwrite;
- no easy gradient library;
- developers copy/paste gradients from folders.

### Opportunity hypothesis

Cross-place Color3 / ColorSequence / NumberSequence swatch library with favorites, recent history and one-click application.

### Risk

Small visible demand and easy to copy; likely better as a low-priced micro-plugin or a PresetForge V2 module rather than a major standalone product.

### Status

**SMALL / HOLD.**

---

## Rejected for now — SelectForge / Magic Wand

Demand is real:

**"Magic Wand" Selection Tool for Studio**  
https://devforum.roblox.com/t/magic-wand-selection-tool-for-studio/1489595

But the market is already crowded:
- Selection Wand (2026) — similar-items magic wand + rectangle/circle selection + filters:
  https://devforum.roblox.com/t/selection-wand-magic-wand-for-selection/4433450
- Quick Select — paid $4.99, updated June 2026:
  https://create.roblox.com/store/asset/15507630959
- Pick — expressive instance search:
  https://create.roblox.com/store/asset/2724083983/Pick-Pro-quick-instance-selection
- Crowbar — free selection/placement suite:
  https://create.roblox.com/store/asset/6009603869/Crowbar

**Status: REJECT as a standalone V1 unless a new unmet workflow appears.**

---

## Rejected for now — true Orthographic/ViewForge

**Create an orthographic view** has thousands of views:
https://devforum.roblox.com/t/create-an-orthographic-view/1300021

However Roblox still lacks true orthographic projection. Existing workarounds use tiny FOV / distant camera and have rendering/culling limitations.

**Status: REJECT.** A plugin workaround would not honestly deliver the requested native feature.

---

## Rejected / native progress — TestForge

**Unit Testing Workflows are Impossible**
https://devforum.roblox.com/t/unit-testing-workflows-are-impossible/1938709

Demand was strong, but Roblox introduced headless/Open Cloud engine execution and the community now has multiple 2025–2026 test-runner/CLI projects.

**Status: REJECT for our fast paid-plugin catalog.**

---

## Existing-product V2 evidence — PresetForge

Do not create a separate product for these.

### Copy Properties From Object
https://devforum.roblox.com/t/copy-properties-from-object/224274

Large, long-lived demand for copying selected properties across instances/places. PresetForge already overlaps strongly.

### Preset Manager
https://devforum.roblox.com/t/preset-manager-for-organizing-and-bulk-applying-properties-attributes-tags-and-collisiongroups-to-instances/1164752

Direct evidence for reusable property/attribute/tag presets. Activity continued in 2026.

### Sequence bulk editing
https://devforum.roblox.com/t/let-us-edit-multiple-sequence-properties-at-a-time/425043

The original pain was real, but Roblox shipped multi-sequence editing in 2024. Treat this as a reminder to re-check native Studio before implementing old feature requests.

---

## Native-resolved / do not productize

### Paste into multiple objects
https://devforum.roblox.com/t/paste-something-into-multiple-objects/18100

Later replies note Studio supports Ctrl+Shift+V for multi-paste. Closed in 2025.

### Multiple sequence editing
Roblox staff enabled multi-selection sequence editing in 2024.

---

## API/native blockers — useful as demand research, not products

- Colored folders / native Explorer icons.
- Native plugin toolbar grouping.
- Script-editor fold registration.
- True orthographic camera.
- Full Studio layout preset control.

These may have lots of interest but should not become Forge products unless Roblox exposes the necessary plugin APIs.

---

## Mining rule going forward

Before brainstorming a new plugin, mine Studio Features first.

For every interesting thread record:
- URL;
- date / activity;
- visible likes/replies/views where available;
- exact user pain;
- whether a plugin can solve it today;
- current native Studio behavior;
- Creator Store competitors;
- whether the request is already solved;
- possible Forge product or existing-product V2 mapping.

Prioritize **clusters** of multiple independent requests over one-off ideas.
