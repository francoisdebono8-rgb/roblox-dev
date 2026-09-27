# Forge Studio target product structures

This file defines **information architecture**, not final pixel mockups.

The five plugins should share a visual language without sharing one forced screen layout.
Each structure below is built around the product's real workflow and current engine.

## Shared structural rules

Every product gets:
- compact product/context header;
- clear work-mode navigation;
- one dominant work surface;
- selected-item detail where the product benefits from inspection;
- stable Preview/Apply/Build/Regenerate action area;
- visible stale/blocked/success state;
- responsive one-column fallback.

What changes per product is the **work model**.

| Product | Primary mental model | Wide structure | Narrow structure |
|---|---|---|---|
| PresetForge | Recipe -> Targets -> Changes | Library + workspace | Library / Recipe / Preview views |
| SchemaForge | Contract -> Findings -> Repair | Nav/list + detail | Findings -> detail -> repair |
| CurveForge | Path -> Output | point rail + settings/preview | points -> settings -> preview |
| AccessForge | Endpoints -> Assembly | settings + contextual assembly preview | sections + dedicated preview |
| JointForge | Connection graph | endpoint/list + detail/plan | workflow list -> detail/preview |

---

# SchemaForge

## Wide target

```
┌──────────────────────────────────────────────────────────────┐
│ SchemaForge     Greenhouse Contract ●     #PlantPot Workspace│
├───────────────┬──────────────────────────────┬───────────────┤
│ CONTRACT      │ AUDIT                        │ FINDING       │
│ Rules         │ 8 checked / 6 findings       │ PlantPot #4   │
│ Audit      6  │ [Missing] [Invalid] [Child]  │ Cost          │
│ Repairs    2  │ [Search / filters]            │               │
│               │                               │ Expected      │
│ LIBRARY       │ ● Cost · Missing · FIXABLE    │ number >= 0   │
│ Greenhouse    │   PlantPot #4                 │ Actual        │
│ EnemyConfig   │ ○ GrowthRate · Invalid        │ Missing       │
│ DoorContract  │   PlantPot #6                 │               │
│               │                               │ Designer note │
│               │                               │ ...           │
│               │                               │ Safe repair   │
│               │                               │ Cost -> 25    │
├───────────────┴──────────────────────────────┴───────────────┤
│ 2 safe repairs selected                    [Preview changes] │
└──────────────────────────────────────────────────────────────┘
```

### Rules target
Replace field-picker + long generic form with:
- rules list;
- Attribute / Child grouping;
- selected rule editor;
- rule type/status summary in each list row;
- contextual validation attached to the exact field.

### Audit target
- changes/actionable findings first;
- category chip;
- field;
- object identity;
- compact reason;
- selected finding detail;
- Expected/Actual as paired values.

### Repairs target
Repairs can be a dedicated review view **or** a selected-finding repair panel depending
on available width. It must never imply repair of wrong types/invalid values/children.

## Narrow target
`Contract header -> Audit list -> Finding detail -> Repair preview`.
Library and Rules are separate views. No three squeezed columns.

---

# PresetForge

## Wide target

```
┌──────────────────────────────────────────────────────────────┐
│ PresetForge    Point Light Warm ● Project              Help  │
├─────────────────┬────────────────────────────────────────────┤
│ RECIPES         │ RECIPE / TARGETS                           │
│ [Search...]     │ Point Light Warm          Project          │
│ ● Warm Lights   │ Brightness · Color · Attributes           │
│   Blue Lights   │                                            │
│   Neon Sign     │ Target: Descendants                        │
│   UI Button     │ [Class] [Name] [Tag]                       │
│                 │ 21 matched                                 │
│ + New recipe    │                                            │
│                 │ PREVIEW                                    │
│                 │ 4 changes · 17 matching                    │
│                 │ ● Lamp_04 Brightness 2 -> 4                │
│                 │ ● Lamp_11 Brightness 1 -> 4                │
│                 │ [17 matching collapsed]                    │
├─────────────────┴────────────────────────────────────────────┤
│ 4 changes / 4 objects                [Preview] [Apply 4]     │
└──────────────────────────────────────────────────────────────┘
```

### Library
- searchable;
- Local/Project badge on rows;
- selected recipe summary;
- duplicate/edit in a compact overflow/action group.

### Recipe
The recipe should visually explain captured content:
- property group;
- tags;
- attributes;
- source identity;
- storage scope.

### Targets
Targets and Preview belong in the same broader workspace; avoid making target selection
feel like an unrelated admin page.

### Changes
Affected first. Matching/ignored collapsed by default.
Before/after values are the main review unit.

## Narrow target
`Library -> Recipe -> Targets/Preview -> Changes`, while the current recipe remains
visible in the compact header and Preview/Apply remains stable.

---

# CurveForge

## Wide target

```
┌──────────────────────────────────────────────────────────────┐
│ CurveForge     Cable_02 ● Editing existing       [New Path]  │
├────────────────┬─────────────────────────────────────────────┤
│ PATH           │ CABLE                                      │
│ 1  Pole_A   ◉  │ Diameter          0.35                     │
│ 2  Mid_01      │ Segment length    1.5                      │
│ 3  Mid_02      │ Material          SmoothPlastic            │
│ 4  Pole_B      │ Color             ■                         │
│                │ Anchored  ✓  Collide ○  Shadow ✓           │
│ + point        │                                             │
│                │ CONTEXTUAL PREVIEW                          │
│ [Cable|Repeat] │ existing ─── / proposed ━━━                 │
│                │ 83.2 studs · 56 segments                    │
├────────────────┴─────────────────────────────────────────────┤
│ Preview current path                        [Regenerate 56]   │
└──────────────────────────────────────────────────────────────┘
```

### Path rail
- numbered points;
- selected point;
- locate/select;
- compact reorder;
- remove;
- point name gets more space than controls.

### Mode workspace
Cable and Repeat get separate, purpose-built settings groups rather than a single generic
parameter stack.

### Preview
Context is the hero. Existing/proposed distinction must be visible.
Fallback isolated ViewportFrame remains acceptable where contextual world preview is not
safe/available.

## Narrow target
Point list -> selected mode settings -> Preview view. Selected point/path identity persists.

---

# AccessForge

## Wide target

```
┌──────────────────────────────────────────────────────────────┐
│ AccessForge      FactoryStair ● Edit existing                │
├───────────────────┬──────────────────────────────────────────┤
│ STRAIGHT          │ CONTEXTUAL ASSEMBLY                      │
│ SWITCHBACK        │                                          │
│ CATWALK           │      ┌──────── platform                  │
│                   │     ╱                                   │
│ ENDPOINTS         │    ╱ stairs + rails                      │
│ Start  [Frame]    │   ╱                                      │
│ End    [Frame]    │                                          │
│ [Swap]            │ 15 steps · rise 12 · run 30 · 42 parts  │
│                   │                                          │
│ Layout Rails Finish│                                         │
│ Width       8     │                                          │
│ Tread       2     │                                          │
│ Riser       .8    │                                          │
├───────────────────┴──────────────────────────────────────────┤
│ Preview fits current markers              [Regenerate 42]    │
└──────────────────────────────────────────────────────────────┘
```

### Endpoint card
Start and End must be understood together:
- identity;
- locate/frame;
- current distance/rise where useful;
- swap/reassign.

### Settings
Layout / Rails / Finish remains a good domain split, but becomes visually cleaner cards
rather than a raw parameter list.

### Preview
The assembly and its relationship to the platform/environment is more important than
an isolated beauty render. Metrics belong next to that preview.

## Narrow target
Mode -> endpoints -> section settings -> Preview. No forced 350 px internal surface and
no horizontal form scroll.

---

# JointForge

JointForge needs three genuinely different work surfaces rather than one generic form.

## Create

```
┌──────────────────────────────────────────────────────────────┐
│ JointForge                  Create | Batch | Inspect         │
├────────────────────────┬─────────────────────────────────────┤
│ PART 0                 │             PART 1                  │
│ Handle                 │             Blade                   │
│ BasePart               │             BasePart                │
│ [Locate] [Reassign]    │   Motor6D   [Locate] [Reassign]     │
│ Attachment: GripA      │      ⇄      Attachment: GripB       │
├────────────────────────┴─────────────────────────────────────┤
│ PREVIEW: 1 Motor6D · no conflict · world pose preserved      │
│                                           [Preview] [Apply 1] │
└──────────────────────────────────────────────────────────────┘
```

Endpoint cards are the visual model. Long paths are detail metadata, not the headline.

## Batch

```
┌──────────────────────────────────────────────────────────────┐
│ ROOT: Handle                                             ... │
├──────────────────────────────────────────────────────────────┤
│ Part                       Mode       Planned connection      │
│ Blade                      Moving     Motor6D                 │
│ Guard                      Static     WeldConstraint          │
│ Bolt                       Static     WeldConstraint          │
│ ...                                                          │
├──────────────────────────────────────────────────────────────┤
│ 3 operations · 0 conflicts                 [Preview] [Apply]  │
└──────────────────────────────────────────────────────────────┘
```

Rows use status chips for Static/Moving and per-row conflict state.

## Inspect

```
┌──────────────────────┬───────────────────────────────────────┐
│ JOINTS               │ MOTOR6D · Grip                        │
│ [All][Broken]        │ Part0  Handle                         │
│ ○ WeldConstraint     │ Part1  Blade                          │
│ ● Motor6D            │ [Locate 0] [Locate 1] [Locate joint] │
│ ! Hinge · Broken     │                                       │
│                      │ PROPERTIES                            │
│                      │ C0 ...                                │
│                      │ C1 ...                                │
│                      │ ...                                   │
├──────────────────────┴───────────────────────────────────────┤
│ Selected edit has 2 changes                  [Preview edits]  │
└──────────────────────────────────────────────────────────────┘
```

Removal is a distinct destructive selection/review flow; it should not visually compete
with ordinary inspection/editing.

## Narrow target
Create stacks endpoint cards; Batch becomes rows/cards; Inspect becomes joints list ->
selected joint detail.

---

# Common vs product-specific matrix

| Element | Shared grammar | Product-specific content |
|---|---|---|
| Product header | Yes | context fields |
| Navigation styling | Yes | nav model/count |
| Primary button | Yes | Preview/Apply/Build/Regenerate |
| Search field | Yes | Recipe/findings/joints where needed |
| Filter chip/menu | Yes | product categories |
| List row | Yes | recipe/finding/point/joint semantics |
| Detail card | Yes | domain data |
| Expected/before-after block | Yes | Schema/Preview-specific labels |
| Status chip | Yes | Missing, Static, Broken, etc. |
| Contextual preview shell | Yes | curve/access geometry implementation |
| Endpoint pair | No | JointForge/AccessForge-specific |
| Rule editor | No | SchemaForge-specific |
| Recipe capture editor | No | PresetForge-specific |
| Path-point editor | No | CurveForge-specific |
| Stair/catwalk settings | No | AccessForge-specific |
| Joint field editor | No | JointForge-specific |

The shared layer should provide visual primitives; product modules own domain semantics.
