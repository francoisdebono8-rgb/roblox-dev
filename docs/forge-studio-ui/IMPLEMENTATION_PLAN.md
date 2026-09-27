# Forge Studio UI implementation plan

Planning-only. This file defines the future UI refactor **after the complete five-product
functional V2 programme is finished**.

It does not authorize product publication or immediate code changes.

## Hard gate before any UI implementation

Do **not** start implementing the new Forge Studio UI on any product while another
catalogue product still has unfinished functional V2 work.

The order is:

1. finish PresetForge V2;
2. finish SchemaForge V2;
3. finish CurveForge V2;
4. finish AccessForge V2;
5. finish JointForge V2;
6. only then open the separate Forge Studio UI programme.

The exact V2 numbering/release state may move while work continues; the principle is what
is fixed: **functional scope first across the entire catalogue, UI redesign second**.

Why:
- we want to design against settled real functionality;
- we do not want to redo layouts because a later V2 changes a workflow;
- we want one coherent catalogue-wide art direction, not incremental visual drift;
- UI work must not consume the engineering attention needed to finish the V2s.

## Objective after the gate

Bring all five commercial plugins to one Forge Studio quality bar while preserving
their distinct workflows and proven engines.

The target is not "more decoration". The target is:
- faster visual parsing;
- less admin-form density;
- stronger product identity;
- clearer relationships between objects, preview and write actions;
- premium consistency across the catalogue;
- the same level of visual care as the approved Forge Studio covers, translated to
  a real Studio-native tool;
- zero regression in safety semantics.

## Design preparation allowed before the gate

Before all V2s are finished, design work may continue only as documentation/research:
- audit the real current UI;
- refine information architecture;
- define visual language;
- collect constraints from real workflows;
- note future component candidates;
- compare wide/narrow behavior;
- document product-specific art direction.

Do not:
- modify View/UI code;
- introduce new shared UI dependencies;
- change engines for presentation;
- publish visual refactors;
- declare a product's later UI "done".

## Future implementation sequence

Once all five V2s are complete, SchemaForge is the proposed **reference implementation**
because its engine already exposes rich structured diagnostic data. PresetForge should
follow to prove which visual primitives are actually reusable. The remaining three can
then follow based on the settled V2 state.

This is a sequencing proposal for the later UI programme, not permission to begin early.

## Per-product implementation phases

### Phase A — freeze behavior

Before touching View/UI:
- record current supported workflows;
- record current write boundaries;
- record persistence/metadata format;
- run baseline engine/native tests;
- capture current UI state for comparison.

### Phase B — compose the product, not a form

Implement the product-specific structure defined in `PRODUCT_STRUCTURES.md`:
- shell;
- navigation;
- list/detail or spatial hierarchy;
- cards/rows/chips where they clarify meaning;
- stable action area;
- responsive reflow.

The goal is visual composition with real data, not a prettier pile of controls.

### Phase C — wire existing actions

Connect each control to existing product behavior:
- selection;
- capture;
- filters;
- preview;
- apply/build/regenerate;
- library/persistence;
- locate/frame;
- Undo/Redo state reaction.

Where a visual concept implies a function the engine does not support:
- omit it; or
- create a separately reviewed functional issue.

Do not silently expand the engine during a visual task.

### Phase D — refinement pass

This phase is mandatory. "Everything works" is not the finish line.

Review:
- spacing rhythm;
- optical alignment;
- text hierarchy;
- icon weight and consistency;
- hover/press/selected/disabled states;
- active vs inactive surface contrast;
- field grouping;
- empty states;
- microcopy;
- long-name treatment;
- tooltip behavior;
- scrolling;
- focus/caret;
- visual stability when content changes;
- quality at 240/320/400/560 px;
- light and dark themes.

The UI should be good enough that a **real unmodified Studio screenshot** looks like
commercial product software.

### Phase E — native QA and commercial capture

Run the product's real workflow on the final artifact:
- light/dark;
- 240/320/400/560 widths;
- 360/640/900 heights where relevant;
- new item + edit existing;
- Preview read-only;
- stale write blocked;
- final Apply/Build/Regenerate;
- native Undo/Redo;
- source preservation;
- artifact/source equality.

Only after the exact final UI passes should new Creator Store screenshots be made.

## Engineering boundary

### Prefer view adapters over engine rewrites

If the new UI needs display-oriented structures, build a presentation adapter around
existing engine results rather than changing the transactional engine simply to fit a
component.

Examples:
- group Schema findings for display without changing finding truth;
- map Preset preview results into visible rows without changing preview semantics;
- derive Joint endpoint display identity without changing connection planning;
- derive Access/Curve preview metrics without changing geometry.

### Shared component extraction rule

A shared module is justified only when:
1. two products require materially the same behavior;
2. both implementations have passed native UI QA;
3. product-specific semantics remain outside the shared module.

Good candidates after proof:
- theme/token resolver;
- button hierarchy;
- card/border/padding helpers;
- status chip;
- list row;
- diff block;
- stable action footer;
- responsive breakpoint helper;
- tooltip/long-value reveal.

Bad candidates:
- one universal "ForgeWorkflow";
- one generic schema for all product state;
- one mega View module parameterized by dozens of flags;
- generic geometry preview abstraction before both spatial products prove the same need.

## Visual acceptance gate

A UI pass is not complete merely because controls are reachable.

Review the real plugin against these questions:
- Can a new user identify the current object/document/scope immediately?
- Is the primary task visible before technical detail?
- Can the user scan a list without reading every line?
- Does selection have a strong but restrained visual state?
- Are status, errors and stale state visually distinct?
- Is the write action obvious and exact?
- Does the interface still look intentional at 240 px?
- Does a 560 px dock use extra space intelligently rather than just stretching fields?
- Does the product still look like itself, not a recolored sibling?
- Are there any obviously default/raw controls breaking the composition?
- Does every surface, divider and spacing choice look intentional?
- Can a real screenshot be used in store media without recreating or beautifying the UI?

## Product-specific non-regression gates

### SchemaForge
- V1 schema compatibility;
- explicit contracts;
- Expected/Actual truth;
- missing-only repair;
- stale-plan protection;
- subset integrity.

### PresetForge
- Local/Project distinction;
- capture fields unchanged;
- filter scope unchanged;
- exact before/after Preview;
- recipe search/duplicate;
- Apply exact scope.

### CurveForge
- 2-8 controls;
- Cable/Repeat support;
- source preservation;
- edit/regenerate;
- preview does not persist output;
- no world-preview residue if contextual preview is implemented.

### AccessForge
- Straight/Switchback/Catwalk;
- exact marker semantics;
- re-edit/regenerate;
- user-added-object protection;
- no false engineering safety implication.

### JointForge
- supported class list;
- endpoint explicitness;
- conflict policy;
- attachment policy;
- world-pose promise where applicable;
- destructive removal confirmation;
- no silent repair.

## Documentation outputs per UI pass

Each implemented product should leave:
- before/after structure note;
- screenshots at representative widths;
- light/dark evidence;
- interaction acceptance table;
- exact final artifact hash;
- list of reused shared components;
- list of intentionally product-specific components;
- any deferred mockup idea that was not safely implemented.

## Store-media handoff

The Forge Studio brand covers and the in-product UI are separate layers.

Cover:
- same locked title/Forge/Studio structure;
- product-colored metal;
- one real functional illustration.

Store screenshots:
- real final Studio UI;
- crop/layout adaptation allowed;
- no fabricated UI;
- no fake selection/result;
- no feature that the binary does not contain.

The cover can remain cinematic while the software expresses the same refinement through
composition, typography, material restraint and interaction quality.
