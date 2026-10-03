# Forge Studio — Fast Track for Remaining Products

Status: binding acceleration workflow for PresetForge, CurveForge, AccessForge and JointForge.

SchemaForge has already established the Forge Studio visual grammar. The remaining products
must **reuse that proven grammar immediately** instead of rediscovering the design system.

## Goal

Ship each remaining UI in one main implementation pass, then at most one short visual correction.

Do not repeat the SchemaForge process of multiple design phases, large pre-code questionnaires,
or repeated QA matrices.

## What is already decided — do not ask again

Shared Forge Studio language:
- canonical F: `docs/forge-studio-ui/brand/assets/forge-f.svg`
- maker signature: restrained `Forge Studio`
- BuilderSans hierarchy
- continuous low-chrome surfaces
- thin separators
- compact list rows
- quiet navigation
- subtle selected/hover/focus/pressed states
- one dominant primary command
- ghost/text-level secondary commands
- tooltip only for hidden/truncated/icon-only information
- wide = meaningful split workspace
- narrow = one work surface / list-to-detail when needed
- no glow / faux metal / gaming chrome
- no generic card-everything dashboard

Locked accents:
- PresetForge #D1A348
- CurveForge #4D7DD2
- AccessForge #A34BC5
- JointForge #D77A3E

Canonical product specs:
`docs/forge-studio-ui/brand/products/*.md`

## Copy/adapt proven UI primitives

For speed, it is acceptable to copy/adapt the proven local visual primitives from
SchemaForge's View into each product locally:
- theme token logic
- typography roles
- hover/pressed/focus behavior
- quiet navigation row
- compact entity row
- section header + add action
- command/footer hierarchy
- tooltip policy
- responsive breakpoint approach
- canonical F/maker signature treatment

Do **not** copy SchemaForge's information architecture.

Do not create a shared framework yet. Local duplication is acceptable for these four passes.
After PresetForge becomes the second validated consumer, shared extraction may be considered,
but it must not block the remaining products.

## Per-product workflow

### 1. Read only what matters
Before code:
- product technical V2 doc
- product section in PRODUCT_STRUCTURES.md
- its brand product spec
- this FAST_TRACK document
- SchemaForge final View as visual implementation reference

Do not reread the entire historical UI documentation unless a real ambiguity appears.

### 2. Implement immediately
Build the intended product-specific architecture in one pass.

Do not stop for design questions unless a choice would materially change:
- product work silhouette
- primary workflow
- brand identity
- preview/work-object prominence

If such a question exists:
- ask maximum 1–3 questions in one batch;
- recommend defaults;
- continue implementing reversible details.

### 3. First review
Produce:
- Dark 560 screenshot of the main signature workflow
- Dark 320 screenshot of the same product in narrow mode

That is enough for the first visual review.

### 4. One correction pass maximum
If the real screenshots reveal clear issues:
- make one focused visual correction pass;
- do not start another "phase";
- do not rewrite specs.

### 5. Final verification once
After visual acceptance:
- compile/build
- one final technical regression run
- basic Light sanity check
- stop before publication

No repeated full test matrix during visual iteration.

## Product-specific target silhouettes

### PresetForge
Visual idea: **source -> recipe -> targets -> changes**

Wide:
- left recipe library
- selected recipe/work context
- target scope
- changes-first preview as the visual anchor
- before/after values
- matching/ignored secondary

Narrow:
- Library -> Recipe -> Targets/Changes
- stable Preview/Apply command area

Do not copy SchemaForge's findings inspector.

### CurveForge
Visual idea: **ordered control points shaping an output**

Wide:
- compact point rail/list
- selected point/context
- Cable / Repeat settings
- preview is the largest/strongest work surface
- Edit Existing is first-class, not buried

Narrow:
- point list -> settings -> dedicated preview
- no generic text Up/Down/Remove rows

Preview is the reason to buy this product. Do not make settings dominate it.

### AccessForge
Visual idea: **fit an industrial assembly between Start and End**

Wide:
- clear Start / End relationship
- Straight / Switchback / Catwalk mode
- compact grouped settings
- assembly preview as hero
- geometry/dimension metrics next to preview

Narrow:
- endpoints -> mode/settings -> preview
- absolutely no horizontal form scrolling

Violet is brand accent. Yellow rail color is a material/safety cue, not the brand.

### JointForge
Visual idea: **two endpoints intentionally connected**

Wide Create:
- Part0 and Part1 as paired endpoint cards/regions
- joint type visibly between/near them
- exact plan preview
- conflicts adjacent to the relationship

Batch:
- root + parts list with Static/Moving roles
- conflicts per row

Inspect:
- joint list + selected joint inspector
- endpoint relationship remains visible
- removal/destructive action clearly separated

Do not force Create/Batch/Inspect into one generic stacked form.

## Branding rule

Every product gets:
- canonical F geometry
- product name
- quiet Forge Studio signature
- locked product accent

Branding must be integrated in the same hierarchy as SchemaForge, but product workflow remains
the visual hero.

Do not retrace covers or redesign the F.

## Questions — accelerated mode

Questions are now exception-based, not mandatory.

Good question:
"Should CurveForge's preview stay persistently visible while editing points at 560, or become
a separate focus mode?"

Bad questions:
- radius 4 or 6?
- icon or no icon for obvious actions?
- which amber?
- where should Forge Studio go?
These are already decided by the system.

## Definition of Done per product

A product is ready when:
- it clearly belongs to Forge Studio
- it is recognizable beyond its accent
- its real work object is visually dominant
- it does not look like a generic Roblox form
- 560 and 320 real screenshots are accepted
- one final technical regression passes
- no publication has been performed

Target: **one main pass + one correction maximum per plugin.**
