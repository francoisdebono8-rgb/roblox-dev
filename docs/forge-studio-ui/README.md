# Forge Studio UI

Planning-only reference for the five existing Forge products.

This folder records the visual/interaction direction agreed while the Forge V2 programme
is still being completed. It exists so the later UI pass can start from a deliberate
design system instead of improvising product by product.

**Hard sequencing rule: finish the functional V2 programme for all five products first.**
Until all five V2s are complete, this folder is research/design only:
- no plugin UI implementation;
- no engine rewrite for visual reasons;
- no Creator Store update caused by this UI work;
- no premature shared UI framework.

Baseline reviewed: `main` at/after SchemaForge commit `fd69f508` (2026-09-27).
PresetForge 2.1.0; SchemaForge 1.1.0; CurveForge/AccessForge/JointForge 1.0.0 at the
time of the first audit.

The existing functional guardrails remain source of truth:
- [Forge functional design system](../v2/forge-design-system.md)
- each product's `v2/AUDIT.md`, release gate and native QA evidence

## Quality bar

The target is not merely "cleaner Roblox UI".

The later Forge Studio pass should bring the **same care, restraint, hierarchy and
desirability** achieved by the approved Forge Studio product covers into the actual
software, translated appropriately for a Studio DockWidget.

That means:
- deliberate composition rather than stacked controls;
- beautiful hierarchy before decoration;
- precise spacing and alignment;
- a recognizable product silhouette at a glance;
- sophisticated but restrained accents;
- surfaces that feel designed, not generated from default controls;
- product-specific workspaces rather than five recolored forms;
- real data and real actions only.

The covers are the **quality reference**, not a literal UI skin. Metallic type, cinematic
lighting and 3D hero imagery belong to marketing. Inside Studio, that same refinement is
expressed through typography, proportion, surfaces, states, motion/feedback and composition.

## What is locked

### Forge Studio brand family

The approved commercial-cover direction is the family reference:

- every product title occupies the same title zone and roughly the same visual mass;
- the product prefix (`Preset`, `Schema`, `Curve`, `Access`, `Joint`) uses the
  same type treatment and placement;
- `Forge` uses one consistent recognizable **F** construction across the family;
- the F is distinctive but restrained: no shield/badge reinvention per product,
  no gaming/esports/kitsch treatment;
- `Forge` carries a refined metallic treatment in the product accent;
- `Studio` is integrated in the same place and scale every time, visibly but quietly;
- only the product accent and the functional illustration change;
- the functional illustration must represent the real product, not a generic metaphor
  and not a fabricated plugin UI.

Approved function cues:
- PresetForge: one source -> reusable recipe -> selected fields applied to many targets;
- SchemaForge: tagged objects -> explicit contract -> findings -> safe missing-only repair;
- CurveForge: ordered control points -> cable/pipe or repeated models along a path;
- AccessForge: industrial stairs / switchback / landing / catwalk / rails;
- JointForge: explicit Part0/Part1 endpoints -> real Roblox joints/constraints.

## What is shared vs what is not

Shared:
- typography, spacing rhythm, surfaces, borders, radii and control density;
- product header/context treatment;
- button hierarchy and status language;
- search/filter affordances;
- cards, list rows, selected states, badges/chips and diff presentation;
- stable primary action area;
- error/warning/success/stale semantics;
- responsive behavior principles and Studio light/dark integration;
- icon language and tooltip behavior;
- Forge Studio brand signature;
- the same overall finish and visual discipline.

Not shared:
- information architecture of the work area;
- number or type of panes;
- domain-specific editors;
- preview content;
- product workflow steps;
- data models and engines;
- write semantics.

A shared visual grammar must **not** become five recolored clones.

## Files

- [VISUAL_DIRECTION.md](VISUAL_DIRECTION.md) — the future art direction and polish bar:
  composition, depth, typography, micro-details and per-product visual personality.
- [SHARED_SYSTEM.md](SHARED_SYSTEM.md) — visual grammar, tokens, common components,
  responsive rules and brand use.
- [PRODUCT_AUDITS.md](PRODUCT_AUDITS.md) — current UI audit of all five products,
  based on the actual checked-in product UI.
- [PRODUCT_STRUCTURES.md](PRODUCT_STRUCTURES.md) — target information architecture
  for each product, wide and narrow.
- [QUALITY_GATES.md](QUALITY_GATES.md) — measurable future acceptance gates; this is
  the Definition of Done, not optional inspiration.
- [WORK_ORDER_TEMPLATE.md](WORK_ORDER_TEMPLATE.md) — exact task template future agents
  must use when implementing a product UI pass.
- [forge-ui-spec.json](forge-ui-spec.json) — machine-readable breakpoints, dimensions,
  accents, required states and product signatures.
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) — future UI-pass engineering
  boundaries and acceptance gates **after all five V2s are complete**.

## Core direction

The target is **professional product software inside Roblox Studio**, not a flashy
landing page and not an internal developer utility.

Every control shown in the real plugin must map to a real function. No dead buttons,
fake metadata, mock-only panels or feature invented for a screenshot.

The common principle is:

> finish the engines first; later, keep the engines and redesign how users see,
> understand and control them at Forge Studio quality.
