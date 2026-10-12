# Forge Studio — canonical brand reference

Status: **binding brand source for all five Forge products**.

This document exists so no agent has to re-infer the Forge identity by zooming into
raster screenshots.

The five approved commercial covers supplied by the user are the canonical visual family:
- CurveForge
- SchemaForge
- PresetForge
- AccessForge
- JointForge

Their shared F, product-accent families and functional visual cues are locked below.

## 1. Canonical F mark

Use:

`docs/forge/forge-studio-ui/brand/assets/forge-f.svg`

This SVG is the reusable clean silhouette of the **same F construction approved in the
five covers**.

Hard rules:
- do not redraw the F from screenshots;
- do not invent a new F;
- do not change its silhouette per product;
- do not turn it into a shield, badge, monogram or esports mark;
- do not distort width/height;
- recolor the same geometry for each product;
- in-product UI may use the simplified flat mark;
- cover/media may use metallic gradients/highlights on this same geometry.

The raster covers remain the art-direction reference for metallic lighting, but the SVG
is the geometry source of truth.

## 2. Shared cover lockup

The approved family uses the same hierarchy:

1. product prefix in neutral white/silver:
   - Curve
   - Schema
   - Preset
   - Access
   - Joint

2. canonical F joining into `Forge`

3. `Forge` in the product accent / metallic family

4. `Studio` centered beneath Forge, letter-spaced and restrained, with short rules

5. one sentence describing the real product

6. one product-specific functional hero illustration

Do not reconstruct this lockup differently for every product.

## 3. In-product translation

Do **not** literally paste the glossy cover logo into Studio.

Translate it into:
- canonical F silhouette;
- BuilderSans product name;
- quiet `Forge Studio` maker signature;
- product accent;
- neutral surfaces;
- product-specific work motif.

Inside a DockWidget:
- product > maker signature in hierarchy;
- Forge Studio should be visible but subordinate;
- the F should be small and crisp;
- no metallic bevel;
- no glow;
- no large marketing tagline;
- no cover-style cinematic lighting.

## 4. Locked product families

### SchemaForge
Canonical cover family: **premium mint**.

Accent seed:
`#63D6AE`

Recommended tonal ladder:
- highlight: `#8BECCB`
- accent: `#63D6AE`
- strong: `#35B78D`
- deep: `#17694F`

Cover cue:
tagged/project objects -> saved contract -> audit findings -> safe missing-only repair.

In-product identity:
- active contract/rule/finding;
- focus;
- repairable state;
- Expected/Actual;
- safe repair.

Do not use mint for every success/error semantic state.

### PresetForge
Canonical cover family: **warm amber / yellow-orange**.

Accent seed:
`#D1A348`

Recommended tonal ladder:
- highlight: `#F3CD73`
- accent: `#D1A348`
- strong: `#B17E24`
- deep: `#6D4915`

Cover cue:
one source -> reusable recipe -> selected properties/tags/attributes -> many targets.

In-product identity:
- selected recipe;
- captured fields;
- source/recipe lineage;
- Apply-ready change state.

### CurveForge
Canonical cover family: **steel / electric blue**.

Accent seed:
`#4D7DD2`

Recommended tonal ladder:
- highlight: `#7EC8FF`
- accent: `#4D7DD2`
- strong: `#2E69B9`
- deep: `#183F78`

Cover cue:
ordered control points -> custom path -> cable/pipe/repeated models.

In-product identity:
- selected control point;
- active path;
- proposed output;
- preview geometry.

### AccessForge
Canonical cover family: **refined violet / magenta-violet**.

Accent seed:
`#A34BC5`

Recommended tonal ladder:
- highlight: `#E07ADC`
- accent: `#A34BC5`
- strong: `#8137A0`
- deep: `#52235F`

Cover cue:
industrial stairs, switchbacks, landings, catwalks and rails between structural endpoints.

In-product identity:
- assembly mode;
- Start/End relation;
- selected structure;
- preview geometry.

The yellow safety rails in the cover are a **functional material cue**, not the AccessForge
brand accent. Do not replace the violet product identity with safety yellow.

### JointForge
Canonical cover family: **copper / warm orange-metal**.

Accent seed:
`#D77A3E`

Recommended tonal ladder:
- highlight: `#F5B56D`
- accent: `#D77A3E`
- strong: `#B65D25`
- deep: `#713516`

Cover cue:
explicit Part0 + Part1 -> joint/constraint -> create/inspect/batch.

In-product identity:
- endpoint pairing;
- active connection;
- selected joint;
- planned operation.

## 5. Canonical cover copy / real product cues

These are art-direction references, not mandatory in-app slogans.

- CurveForge: "Build cables, pipes and repeated models along custom paths."
- SchemaForge: "Audit saved contracts with clarity."
- PresetForge: "Save and safely reapply reusable edit recipes."
- AccessForge: "Build editable industrial stairs, landings and catwalks."
- JointForge: "Create, inspect and batch-build joints and constraints."

They reinforce the real product function and should prevent future UI/media from drifting
into generic metaphors.

## 6. Brand-vs-semantic color rule

Product accent is identity.
Semantic color is meaning.

Never use product accent as a substitute for:
- destructive red;
- warning amber;
- error red;
- success/valid semantics when those need independent meaning.

Example:
SchemaForge mint can indicate selection/focus/repairability, while an invalid value still
uses warning/error semantics.

## 7. Reuse rule

Every future product UI brief must cite this file and the canonical F asset.

No agent should need to:
- zoom into screenshots;
- trace the F manually;
- choose a new product accent;
- infer which cover belongs to which plugin;
- invent a family lockup.

If the clean F needs rasterization for Roblox, rasterize **this SVG** once and reuse the
same white/monochrome asset with product tinting where technically appropriate.
