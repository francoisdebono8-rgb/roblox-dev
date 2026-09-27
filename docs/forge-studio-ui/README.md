# Forge Studio UI

Planning-only reference for the five existing Forge products.

This folder records the visual/interaction direction agreed after the Forge V2 work:
keep the proven product engines and safety semantics, but replace the current
"developer panel / admin form" feel with a coherent commercial Forge Studio UI.

**This folder does not authorize implementation, publication, asset duplication or a
functional rewrite.** Product code remains unchanged until a separate UI pass is
explicitly started.

Baseline reviewed: `main` at/after SchemaForge commit `fd69f508` (2026-09-27).
PresetForge 2.1.0; SchemaForge 1.1.0; CurveForge/AccessForge/JointForge 1.0.0 at the
time of this audit.

The existing functional guardrails remain source of truth:
- [Forge functional design system](../v2/forge-design-system.md)
- each product's `v2/AUDIT.md`, release gate and native QA evidence

## What is locked

### Forge Studio brand family

The approved commercial-cover direction is now the visual family reference:

- every product title occupies the same title zone and roughly the same visual mass;
- the product prefix (`Preset`, `Schema`, `Curve`, `Access`, `Joint`) uses the
  same type treatment and placement;
- `Forge` uses one consistent recognizable **F** construction across the family;
- the F must be distinctive but restrained: no shield/badge reinvention per product,
  no gaming/esports/kitsch treatment;
- `Forge` carries a refined metallic treatment in the product accent;
- `Studio` is integrated in the same place and scale every time, visibly but quietly;
- only the product accent and the functional illustration change;
- the visual illustration must represent the real product function, not a generic
  metaphor and not a fabricated plugin UI.

Approved function cues:
- PresetForge: one source -> reusable recipe -> selected fields applied to many targets;
- SchemaForge: tagged objects -> explicit contract -> findings -> safe missing-only repair;
- CurveForge: ordered control points -> cable/pipe or repeated models along a path;
- AccessForge: industrial stairs / switchback / landing / catwalk / rails;
- JointForge: explicit Part0/Part1 endpoints -> real Roblox joints/constraints.

The metallic cover lockup is a **brand/media device**. The in-plugin UI should inherit
its precision, spacing and product accent, not literally render glossy marketing text
inside every DockWidget.

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
- Forge Studio brand signature.

Not shared:
- the information architecture of the work area;
- the number or type of panes;
- domain-specific editors;
- preview content;
- product workflow steps;
- data models and engines;
- write semantics.

A shared visual grammar must **not** become five recolored clones.

## Files

- [SHARED_SYSTEM.md](SHARED_SYSTEM.md) — visual grammar, tokens, common components,
  responsive rules and brand use.
- [PRODUCT_AUDITS.md](PRODUCT_AUDITS.md) — current UI audit of all five products,
  based on the actual checked-in product UI.
- [PRODUCT_STRUCTURES.md](PRODUCT_STRUCTURES.md) — target information architecture
  for each product, wide and narrow.
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) — future UI-pass sequence,
  engineering boundaries and acceptance gates.

## Core direction

The target is **professional product software inside Roblox Studio**, not a flashy
landing page and not an internal developer utility.

The visual bar is the polished mockup direction explored for Forge Studio, but every
control shown in the real plugin must map to a real function. No dead buttons, no fake
metadata, no mock-only panels and no feature invented for a screenshot.

The common principle is:

> keep the engine; redesign the way the user sees, understands and controls it.

