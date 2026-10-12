# Forge Studio visual direction

Status: **future UI art direction only**. No plugin implementation before all five
functional V2s are finished.

This document defines the level of visual finesse expected from the later Forge Studio
UI pass.

The reference is the quality achieved by the approved Forge Studio covers:
recognizable, premium, restrained, product-specific and composed with intent.

The plugin UI should not copy the covers literally. It should feel as if the same art
director designed both the marketing and the software.

---

## 1. The desired first impression

On opening any Forge plugin, the user should feel:

> "This is a focused professional tool made for one job."

Not:
- a debug panel;
- a raw collection of Roblox UI controls;
- a settings menu;
- a web dashboard pasted into Studio;
- a neon gaming overlay;
- five products using the same template with different colors.

The interface should be beautiful because **its hierarchy is obvious**, not because it
contains more decoration.

---

## 2. Quiet premium, not flashy premium

The Forge Studio covers use metal, cinematic lighting and a strong central object.
Inside Studio, translate that into quieter equivalents:

| Cover quality | In-product equivalent |
|---|---|
| metallic title | crisp typography + carefully weighted accent |
| cinematic depth | layered surface hierarchy |
| central hero object | dominant work object/list/preview |
| controlled lighting | subtle selected/hover contrast |
| premium spacing | deliberate negative space |
| one accent color | restrained product identity |
| clean silhouette | unmistakable information architecture |

No glossy chrome buttons. No bevelled fake metal. No glow around every control.

Premium in the DockWidget means **precision**.

---

## 3. Surface hierarchy

Use a maximum of roughly four meaningful depth levels:

1. **Studio canvas/background**
   - quiet;
   - lowest contrast;
   - no decorative noise.

2. **Primary work surface**
   - the main list/editor/preview;
   - visually continuous;
   - should occupy most of the useful area.

3. **Raised functional card**
   - current object;
   - selected finding;
   - endpoint pair;
   - preview summary;
   - only when grouping matters.

4. **Interactive selected/focused state**
   - subtle product tint;
   - precise border;
   - small elevation/contrast change;
   - never a giant glowing rectangle.

A screen with fifteen identical outlined cards is not refined.

---

## 4. Typography as the main visual system

Use BuilderSans consistently.

The hierarchy should feel editorial:

- product identity: confident, compact;
- current document/assembly: secondary but always readable;
- work-view title: clear;
- item title: stronger than metadata;
- labels: quiet;
- paths and technical identifiers: smallest/secondary;
- values that matter: visually stronger than their labels.

Avoid the current pattern where almost every line is the same size/weight.

Long paths should look like metadata.
`Expected`, `Actual`, `Part0`, `Part1`, `Source`, `Target` should behave like
structural labels, not paragraph text.

---

## 5. Product accent discipline

The accent identifies the product, but should occupy a small percentage of the interface.

### PresetForge — warm amber
Use for:
- selected recipe;
- captured-field markers;
- Apply-ready state;
- subtle recipe lineage.

Mood: precise, crafted, reusable.

### SchemaForge — mint
Use for:
- active contract;
- selected rule/finding;
- repairable safe state;
- validation marks.

Mood: clean, analytical, trustworthy.

### CurveForge — electric/steel blue
Use for:
- active path;
- selected control point;
- proposed curve/output;
- mode selection.

Mood: spatial, fluid, technical.

### AccessForge — refined violet
Use for:
- active industrial assembly;
- current mode;
- selected endpoint;
- preview geometry emphasis.

Mood: architectural, controlled, structural.

### JointForge — copper/orange
Use for:
- endpoint pairing;
- active connection;
- selected joint;
- planned operation.

Mood: mechanical, tactile, precise.

Semantic warning/error/success colors remain separate.

---

## 6. Product-specific visual signatures

Each plugin needs a recognizable **work silhouette**.

### PresetForge
Signature:
- vertical recipe library;
- selected recipe summary;
- clean before/after change rows.

A screenshot should look like PresetForge even if the title is cropped.

Visual motif:
**source -> recipe -> many targets**, expressed through composition rather than arrows everywhere.

### SchemaForge
Signature:
- compact contract context;
- findings master list;
- selected diagnostic detail;
- paired Expected / Actual;
- clearly bounded safe repair.

Visual motif:
**contract -> finding -> decision**.

### CurveForge
Signature:
- numbered control-point rail;
- blue path/proposed output;
- spacious preview;
- compact mode settings.

Visual motif:
**ordered points shaping an output**.

### AccessForge
Signature:
- Start/End pairing;
- industrial mode selector;
- assembly preview with stairs/catwalk silhouette;
- dimension summary near geometry.

Visual motif:
**fit an editable industrial structure between endpoints**.

### JointForge
Signature:
- paired Part0/Part1 cards or connection list/detail;
- visible joint type in the relationship;
- mechanical status chips;
- exact preview operation.

Visual motif:
**two objects connected intentionally**.

---

## 7. Rows should feel designed

A good list row has:
- one clear primary identity;
- one metadata line at most in the default state;
- one status;
- selected state;
- one or two obvious actions maximum.

Details belong in the detail surface.

Do not make every row contain:
identity + path + status + explanation + Expected + Actual + note + three buttons.

That is data dumping, not interface design.

---

## 8. Inputs should feel intentional

Current Roblox-style forms often look "nerdy" because every parameter becomes:
label -> TextBox -> label -> TextBox -> toggle -> button.

Instead:
- related values share a field group;
- units are visually attached;
- boolean controls are compact;
- enum choices use segmented controls only when small;
- colors show actual swatch + value;
- destructive actions move away from frequent fields;
- advanced/rare options can sit in a secondary section.

Whitespace is part of the control.

---

## 9. Selected states and micro-interaction

The later UI should have a subtle interaction polish pass.

Required states:
- rest;
- hover;
- pressed;
- selected;
- focused;
- disabled;
- stale;
- warning;
- error;
- success.

Transitions should be quick and restrained if implemented:
- no bouncy web animation;
- no large fades delaying work;
- no decorative motion unrelated to state.

A selected item should look selected before the user reads a label.

---

## 10. Dividers, borders and radii

Use fewer dividers than the current "everything is boxed" instinct.

Preferred:
- spacing to separate normal groups;
- low-contrast 1 px border for meaningful cards;
- stronger border/accent only for selected/focus;
- 4-8 px radii;
- straight, crisp layout geometry.

Avoid:
- oversized pills;
- excessive rounded cards;
- gradients around every panel;
- heavy shadows;
- double borders.

Forge Studio should feel **engineered and refined**, not soft/mobile.

---

## 11. Empty states

An empty state is a designed moment, not leftover blank space.

It should include:
- one small product-specific visual cue where useful;
- one sentence;
- one primary action;
- maybe one restrained secondary action.

Examples:
- Schema: "Select one configured object to capture a contract." / Capture reference
- Preset: "Select one source to create a reusable recipe." / Save Recipe
- Curve: "Create a path or edit a selected CurveForge model." / New Path / Edit Selected
- Access: "Set two endpoints or edit an existing assembly." / New markers / Edit Existing
- Joint: "Assign Part0 and Part1 to preview a connection." / Use selection

No tutorial wall.

---

## 12. Preview must look like the reason to buy the plugin

Preview is a central commercial feature in all five products.

It should never feel like an afterthought.

- Schema: preview = exact safe repairs.
- Preset: preview = exact changed fields/objects.
- Curve: preview = proposed geometry/path in context.
- Access: preview = proposed industrial assembly in context.
- Joint: preview = exact planned joint/constraint operations.

The preview surface gets more visual weight than configuration boilerplate.

---

## 13. Stale and blocked states can be beautiful

Safety states should not destroy the composition.

Instead of generic red paragraphs:
- compact banner/chip near the affected action;
- clear disabled primary action;
- one recovery action;
- precise reason.

Example:
`Preview stale · selection changed`  [Refresh Preview]

The interface should remain calm when something is wrong.

---

## 14. Narrow width is not a degraded screenshot

At 240 px the product should still look intentionally designed.

That means changing composition:
- list -> detail instead of two columns;
- filters collapse;
- metadata hides behind detail;
- actions shorten;
- title/context compress;
- preview can become a separate view.

Do not simply shrink every component until it technically fits.

---

## 15. 560 px should feel better than 320 px

Wide docks should use space for meaningful context:
- list + detail;
- selected object + preview;
- rule list + rule editor;
- endpoints + plan.

Do not just stretch TextBoxes to 540 px.

Responsive design should improve the workflow as space increases.

---

## 16. Visual review standard

Before a future UI release, review screenshots at 240 / 320 / 400 / 560 px and ask:

### Composition
- Is there a clear visual anchor?
- Is the screen balanced?
- Is empty space intentional?
- Does one primary action dominate appropriately?

### Hierarchy
- Can I understand the screen in two seconds?
- Can I tell what is selected?
- Can I identify the current object/document/scope?

### Craft
- Are baselines aligned?
- Are paddings consistent?
- Are icons optically balanced with text?
- Are border weights consistent?
- Are disabled states still readable?
- Do long labels degrade gracefully?

### Brand
- Does it feel like Forge Studio?
- Does it still feel specifically like this product?
- Is the accent restrained?
- Is there any generic/default UI that breaks the illusion?

### Truth
- Is every visible control real?
- Is every visible value real?
- Is Preview showing actual engine output/state?
- Would we be comfortable using this exact screen in store media?

If the last answer is no because "we would need to beautify it in Photoshop", the UI pass is not finished.

---

## 17. Final principle

The Forge Studio UI should not chase beauty as a separate layer.

The beauty should come from:

**real product structure + strong hierarchy + precise spacing + restrained materials +
product-specific visual identity + excellent state design.**

That is the same reason the final covers became stronger when we stopped adding random
elements and made each image represent the product's real function.
