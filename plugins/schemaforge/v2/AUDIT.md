# SchemaForge V2 programme audit

2026-09-27; issue #15, design only. Canonical `84085408748744`, current 1.0.0.
Public price observed 7.99 USD, not the local roadmap's 4.99 recommendation.

## Real Studio path

Isolated `release/SchemaForge-Media.rbxl` copy, adapted official Roblox Plant greenhouse.
MIT provenance: [scene README](../release/scene/README.md).
Project schemas > Greenhouse pots; Audit > Workspace; Audit tagged objects; Select
affected objects; Preview missing defaults; Apply 2 missing defaults. Actual UI: 8 checked,
3 valid, 6 findings, 5 affected objects selected; two missing Cost values to 25. Native
assertion checked the eight tagged pots and the two named repaired values.
Full rule editing, persistence/reload and Undo/Redo were not reexecuted.
[Execution record](../../../docs/forge/v2/studio-audit-evidence.md).

## Most important friction

**P1: the rule editor and finding context compete with a very large persistent header.**
On the initial narrow dock, project library, secondary actions and tabs were clipped.
After widening, the library/title/capture/save/status area still takes most of the upper
panel. A three-attribute schema already pushes rule values below the fold. Audit then
does not keep the loaded schema name prominently visible, weakening scope confidence.

Other findings:
- Capture reference and New schema have equal prominence, but the empty form does not
  make the shortest first-use route obvious.
- Audit and missing-only repair are clear once loaded. Selection of five affected
  objects works; preserve this strength.
- Six findings show mostly object/field/reason; Expected/Actual/note context would
  reduce trips back to Rules or native Properties.
- Source inspection: `SchemaForge/Modules/View.luau` rebuilds the form on render without
  the CanvasPosition preservation used by CurveForge. Scroll/focus loss during rule
  editing is a risk to reproduce in implementation, **not a GUI-verified bug here**.

## Demand, substitutes and reviews

[Attribute descriptions](https://devforum.roblox.com/t/custom-descriptions-for-attributes-in-the-properties-panel/4664872)
(June 2026) supports designer context. [Attribute UX constraints](https://devforum.roblox.com/t/a-number-of-studio-specific-attribute-features-to-improve-ux/1334456)
supports ranges/choices, but those already exist in V1. Native QueryDescendants can
express missing-attribute and child predicates; a project script may be enough.
[Attribute QA](https://create.roblox.com/store/asset/87556490782458) costs 4.99 and
already audits missing/wrong types/outliers with reference or inferred schema.
[AttributeSheet](https://create.roblox.com/store/asset/77824934141606), September 2026,
offers a batch comparison table/Preview/Undo with Get Plugin. Both have zero visible
reviews, as does SchemaForge. No evidence yet that our higher actual price converts.
No strong matching new Building Support case was found; do not invent outreach.

## Proposed scope, in order

| Change | Evidence / value | Frequency / confidence |
|---|---|---|
| Compact responsive header; loaded schema/tag/scope always visible; reference-first empty state | Real greenhouse path and clipped initial form | Every setup/audit; high |
| Findings with expected/actual values and relevant designer note; filter by reason/field and select affected subset | Six mixed findings; description/handoff request | Frequent on repeated gameplay objects; high |
| Stable rule editor with preserved draft/focus/scroll and contextual rule validation | Long existing form; source risk, not yet reproduced | Frequent schema maintenance; medium |

The commercial promise stays saved explicit project contracts, child requirements and
conservative missing-only repair. It is not another spreadsheet, inferred correctness
engine or runtime type system. No new attribute type is justified by this bounded audit.

## Reject / defer

Automatic majority-schema inference as a correctness guarantee, destructive type conversion,
automatic hierarchy repair, arbitrary Lua predicates, runtime enforcement, CI/cloud service,
Explorer UI injection and generic batch attributes. Native capabilities and competitors
already cover much of simple editing; keep the contract/review distinction.

## Acceptance target for a later release

Load the greenhouse contract, identify its target/scope immediately, see expected/actual
for each issue and select a subset. Preview only the two permitted missing defaults;
existing invalid values/children remain untouched. Editing a long rule retains focus
and scroll. Verify saved contract compatibility and actual native Undo/Redo on final binary.
