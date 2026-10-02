# Forge Studio shared UI system

Status: design reference only. No product implementation is authorized by this file.

This document extends the functional rules in
[`docs/v2/forge-design-system.md`](../v2/forge-design-system.md) with the stronger
Forge Studio visual direction established after the first V2 implementations.

## 1. Product feel

The UI should feel like a compact professional creation tool:

- quiet dark/light Studio-compatible surfaces;
- clear hierarchy before decoration;
- deliberate whitespace;
- few strong actions rather than many equal buttons;
- readable data cards instead of raw stacked labels;
- domain objects and results are the visual focus;
- technical depth remains available without dominating first glance.

Avoid:
- terminal/admin-panel density;
- long walls of labels;
- all controls looking equally important;
- raw `[x]`, `Up`, `Down`, `Remove` text controls when a clear native-style
  affordance can communicate the same action;
- giant permanent tutorial copy;
- ornamental gradients, glass or neon that reduce Studio readability.

## 2. Brand and product accents

Candidate UI accent seeds, aligned to the approved Forge Studio cover family:

| Product | Accent seed | Meaning in product |
|---|---|---|
| PresetForge | amber `#D1A348` | recipe / captured field / pending apply |
| SchemaForge | mint `#63D6AE` | contract / valid context / safe repair |
| CurveForge | blue `#4D7DD2` | path / control point / proposed output |
| AccessForge | violet `#A34BC5` | structure mode / selected assembly |
| JointForge | copper `#D77A3E` | endpoint / connection / joint focus |

These are identity seeds, not certified contrast values. Final fills/text must be tested
against both Studio themes. Error, warning, success and destructive states remain semantic
colors and must never be replaced by the product accent.

### Cover lockup

Commercial media uses one locked family lockup:
- same title bounding box and baseline;
- same prefix font, weight and relative size;
- one canonical Forge F;
- `Forge` in restrained product-colored metal;
- `Studio` in the same position/scale on all products;
- no independent logo redesign for a new product image.

The in-plugin UI should use a restrained text/logo signature, not reproduce the glossy
metal effect literally.

## 3. Typography

Preferred Roblox UI font: `BuilderSans` family.

Suggested scale:
- product/title: 18-20 px semibold/bold;
- work-view title: 16-18 px semibold;
- section/card title: 14-15 px semibold;
- body/control: 13-14 px;
- metadata/path/helper: 12-13 px;
- compact badge/chip: 11-12 px.

Rules:
- no all-caps body copy;
- no code font except values where monospace genuinely improves parsing;
- paths are secondary metadata, never the primary identity;
- long text truncates gracefully with full value available by tooltip/detail;
- one line of actionable empty-state help before a wall of documentation.

## 4. Geometry and spacing

Use the common rhythm:
- 4 px micro gap;
- 8 px control/card internal gap;
- 12 px default outer padding;
- 16 px major section separation;
- 24 px exceptional section separation.

Controls:
- common control height: 30-34 px;
- compact icon target: minimum 28 px;
- card radius: 6 px target, 4-8 accepted;
- border: 1 px, low contrast;
- selected state: border + subtle tinted surface, not only a text-color change.

The product should not feel like every item sits in a box. Cards are reserved for
meaningful groups: current contract, endpoint pair, selected finding, preview summary,
selected assembly, recipe, etc.

## 5. Shared shell grammar

Every plugin should expose these concepts consistently, but the physical layout may differ.

### Product context
At a glance show:
- product name;
- current document/output/recipe/assembly when one exists;
- dirty/stale state when relevant;
- critical scope/context when the write depends on it.

### Navigation
Use the smallest structure that matches the product:
- tabs for a few peer work modes;
- compact side rail for persistent major areas on wide layouts;
- drawer/view switch on narrow layouts.

Do not force a side rail into products that are naturally linear.

### Work body
One scroll owner per logical pane. Avoid nested scrolling unless the inner list is a
real independent collection. Keep selected item context visible during editing where possible.

### Stable action area
Preview/Apply/Build/Regenerate belongs in a stable region. The action area must not jump
because a preview appears or disappears. Exact target/change counts are shown at the action.

## 6. Shared components

These are design concepts first. Do not extract a code library until at least two real
products need and validate the same implementation.

### ProductHeader
Product identity + current context + compact status.

### SectionNav
Tabs/rail/drawer with:
- clear selected state;
- optional count badge;
- no clipped labels at 240 px.

### EntityRow
For a recipe, finding, joint, control point or generated assembly:
- primary identity;
- one concise metadata line;
- optional status chip;
- selected/hover state;
- optional trailing locate/action icon.

### DetailCard
Selected-object details. Prefer label/value pairs and grouped semantics over raw paragraphs.

### StatusChip
Examples: `Missing`, `Invalid`, `Repairable`, `Broken`, `Static`, `Moving`,
`Preview stale`. Color + text/icon; color alone is insufficient.

### DiffBlock
Before/after or expected/actual:
- two visually paired values;
- missing is explicit, never blank;
- long values wrap/expand without destroying layout.

### SearchFilterBar
Search field plus compact filters. On narrow widths filters collapse to a single menu/drawer.

### EmptyState
One sentence + one primary action. Optional secondary link/button only when it represents
a genuinely different route.

### StickyActionBar
Exact primary action and count; safe disabled/stale state; concise status.

## 7. Interaction hierarchy

Button tiers:
1. **Primary** — one action for the current stage: Preview, Apply N, Build, Regenerate.
2. **Secondary** — Edit, Locate, Select, Duplicate, Capture, assign endpoint.
3. **Tertiary/icon** — reorder, overflow, clear filter, reveal path.
4. **Destructive** — Delete/Remove separated visually and spatially.

No screen should present five visually identical full-width buttons unless the task
really has five equivalent choices.

Booleans use checkbox/toggle affordances.
Small mutually exclusive sets use segmented controls.
Long sets use menus/searchable menus.
Reorder uses drag or compact up/down icon affordances with accessible labels.

## 8. State language

The same state contract applies across products:

- **Incomplete**: state what is missing and the next action.
- **Draft**: inputs valid enough to Preview.
- **Preview ready**: exact count + scope + warnings.
- **Stale**: visible chip/banner; write disabled; clear refresh action.
- **Blocked**: explain why and how to recover.
- **Success**: exact committed result; mention native Undo only after a real write.
- **Failure**: no stale success copy; raw Lua stack prefixes are stripped.

A preview is never described as a guarantee of correctness or engineering safety.

## 9. Responsive behavior

Validation widths: 240 / 320 / 400 / 560 px.
Validation heights: 360 / 640 / 900 px.

### 560+
Two-pane layouts are allowed where they genuinely improve the task:
- list + detail;
- settings + contextual preview;
- endpoints + plan.

### 400
Prefer compact two-pane only if both remain legible. Otherwise collapse to a primary
pane with an explicit detail/preview drawer.

### 320
One main column. Navigation can wrap/collapse. Detail opens as a view rather than a
squeezed second column.

### 240
Survival mode without feature loss:
- no clipped primary action;
- no horizontal form scrolling;
- short labels;
- filters collapse;
- paths/details move behind detail disclosure;
- work remains possible, not merely visible.

Short heights keep navigation and write action reachable while the work body scrolls.

## 10. Theme and visual effects

Respect Studio light/dark surfaces and text colors.

Forge Studio identity comes from:
- layout;
- typography;
- spacing;
- accent discipline;
- selected states;
- icons;
- strong product-specific work surfaces.

Not from forcing a dark island in light Studio, heavy glow, faux-metal controls or
decorative 3D chrome inside the DockWidget.

Subtle accent gradients may be evaluated later for headers/selected surfaces, but only
if they remain readable and consistent with Studio.

## 11. Icon language

Use a small stable set:
- locate/frame;
- select;
- refresh/re-audit;
- add;
- duplicate;
- edit;
- delete/remove;
- reorder;
- warning/error/success;
- preview;
- apply/build.

Icons require tooltip/accessibility text. Do not invent a different symbol vocabulary
per plugin.

## 12. Shared implementation boundary

A future UI pass should first change presentation and interaction composition around
existing engines.

Do not casually move product logic into shared UI modules.
Do not create a speculative Forge framework before two implementations prove the same
component is useful.
Do not weaken existing stale-plan, transaction, persistence or Undo/Redo safeguards to
make a prettier flow easier to implement.


## Hover and tooltip rule

Forge Studio must not use a generic hover "magnifier" that repeats the hovered control's
label in a floating/below-control tooltip.

Hover should normally communicate only through subtle visual state:
- restrained surface lift/tint;
- border/focus treatment where appropriate;
- cursor/pressed feedback.

A tooltip is justified only when it reveals information that is genuinely unavailable
in the visible control, for example:
- a truncated full object/path value;
- an icon-only action label;
- a keyboard shortcut;
- a concise explanation of an unfamiliar technical symbol.

Do not tooltip ordinary visible text such as a button label, tab name, finding title,
field name or other already-readable copy. Repeating the same text on hover is a FAIL
for the Forge Studio visual system.
