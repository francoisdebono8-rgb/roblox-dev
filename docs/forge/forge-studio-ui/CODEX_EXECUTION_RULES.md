# Codex execution rules — Forge Studio UI

Status: **inactive until all five functional V2 releases are complete and the user explicitly starts the UI programme.**

This file exists because the Forge Studio UI pass must not collapse into a cosmetic reskin of the existing plugins.

## Non-negotiable interpretation

When the later Forge Studio UI programme begins, **do not interpret the task as**:
- "make the current UI prettier";
- "add rounded corners";
- "add gradients";
- "add a sidebar";
- "change fonts/colors";
- "recolor the existing stacked form";
- "wrap the current controls in cards".

The intended task is:

> keep the product engine and safety semantics, but **recompose the View around the real workflow** so the interface feels like a purpose-built commercial product.

A result that is recognizably the same stacked form with new styling is a **FAIL**.

## The current SchemaForge screen is an explicit anti-reference

The current 1.1 UI is functionally useful but visually represents the problem we are trying to solve:
- large vertical stack;
- many equal-weight full-width buttons;
- repeated grey rectangular inputs;
- weak distinction between navigation, context, data and action;
- rich findings rendered as text blocks instead of a list/detail workflow;
- screen composition driven by control order rather than user task.

The future implementation must not preserve that composition merely because it is already working.

Equivalent anti-patterns in the other products must also be redesigned structurally.

## Mockups are targets, not moodboards

Before any product UI code is changed:
1. the assistant/user will provide approved reference mockups for that product;
2. each visible area/control in the mockup must be mapped to a real existing function/data source;
3. anything not backed by the real product must be removed from the implementation;
4. the implemented UI should match the mockup's **information hierarchy, composition and interaction model** as closely as Roblox Studio allows.

Do not treat mockups as optional visual inspiration.

Allowed deviations:
- required by Roblox Studio limitations;
- required by responsive behavior;
- required to preserve truthful functionality;
- explicitly approved.

Every material deviation must be documented.

## Required before/after review

For each product:
- capture the current baseline UI at comparable widths;
- implement the new structure;
- capture the new UI at the same widths;
- compare side by side.

The pass fails if the main visual differences are only:
- color;
- radius;
- border;
- typography;
- iconography;
- spacing.

At least one of these must materially change where appropriate:
- information architecture;
- list/detail relationship;
- grouping;
- navigation;
- location of primary action;
- preview prominence;
- responsive composition.

## Structural expectations by product

### SchemaForge
Must stop behaving like one long form.

Expected structural change:
- contract context;
- audit findings as a scannable collection;
- selected finding as a separate detail state/pane;
- Expected/Actual as a paired component;
- repair preview/action clearly separated;
- rules rendered as a rules collection + selected-rule editor where width allows;
- narrow mode uses list -> detail navigation, not compressed columns.

### PresetForge
Must present:
- recipe library;
- current recipe identity;
- target scope;
- Preview changes;
- before/after values;
as one coherent workflow rather than four administrative pages with equal weight.

### CurveForge
Must present the path as the main object:
- ordered points;
- selected point;
- cable/repeat mode;
- contextual preview/output.
Do not leave control points as generic rows with large text Up/Down/Remove actions.

### AccessForge
Must present:
- Start/End relationship;
- selected structure mode;
- assembly parameters;
- assembly preview and fit.
Do not solve narrow layouts with horizontal scrolling or an oversized virtual panel.

### JointForge
Must present connections, not raw paths:
- paired Part0/Part1 relationship in Create;
- root + assigned parts in Batch;
- joints list + selected detail in Inspect.
Do not preserve the generic stacked workflow and simply restyle it.

## Visual bar

The approved Forge Studio product covers define the **care level**, not literal UI decoration.

Translate that care into:
- strong composition;
- controlled negative space;
- clear visual anchor;
- subtle depth;
- exact alignment;
- restrained accent use;
- product-specific silhouette;
- clean state transitions;
- meaningful preview prominence.

Do not translate it into:
- metallic buttons;
- glow everywhere;
- fake 3D chrome;
- gaming UI;
- decorative cards with no information purpose.

## Roblox Studio realism

The result must still feel native and credible in Studio:
- Studio light/dark theme compatible;
- real Roblox controls and data;
- real DockWidget sizing;
- no fabricated visual affordance that cannot work;
- no web-only blur/glass dependence.

Target fidelity is to the mockup's **composition and polish**, not every rendering effect.

## Mandatory checkpoints

### 1. Baseline review
Before code, record:
- current screenshot(s);
- current structure;
- specific visual problems;
- real data/actions available.

### 2. Mockup mapping
Create a table:
| Mockup element | Real source/action | Implemented? |
Every visible element must have a real mapping.

### 3. Structural implementation
Build the new hierarchy before decorative polish.

### 4. Visual refinement
Only after structure works:
- typography;
- spacing;
- surface hierarchy;
- accent;
- icons;
- selected/hover/focus/disabled states.

### 5. Native comparison
Capture actual final UI at:
- 240;
- 320;
- 400;
- 560 px widths.

Compare against:
- baseline;
- approved mockup.

### 6. Functional regression
Run all product safety/native tests.

## Hard rejection conditions

Reject the implementation if:
- current stacked-form composition is substantially preserved without justification;
- the UI only looks different because of colors/radii;
- a mockup area has no real product counterpart but was implemented anyway;
- a real core function disappeared to match the mockup;
- the new UI cannot operate at 240 px;
- wide layouts merely stretch narrow controls;
- Preview remains visually secondary to configuration boilerplate;
- selected item/state is not obvious at a glance;
- the real final screenshot still looks like an internal developer tool;
- store media would require recreating the UI to make it look commercial.


## Visual acceptance is not self-certification

The agent may prove geometry, responsiveness, interaction and native regression, but it must **not declare the visual reference accepted solely from automated gates**.

For the reference product:
- final screenshots must be reviewed against the approved mockup/reference by the user/assistant;
- “all gates pass” is invalid if the human visual review says the result is materially below the reference;
- when that happens, keep/reopen the issue and iterate instead of moving to the next product;
- do not propagate the current implementation as a shared pattern until the reference product is explicitly accepted visually.

A structurally different UI can still fail the programme if its visual execution remains generic. In particular, a plain sidebar + text list + default-looking fields is not enough merely because it is no longer one long form.

## Completion language

Do not report:
- "UI polished";
- "premium redesign complete";
- "matches Forge Studio";
without evidence.

Final report must include:
- baseline screenshots;
- final screenshots;
- mockup comparison;
- quality-gate table;
- list of structural changes;
- list of deliberate deviations;
- native regression results;
- final artifact hash.

If the result does not visibly cross the bar from "developer utility" to "commercial Forge Studio tool", continue iterating.
