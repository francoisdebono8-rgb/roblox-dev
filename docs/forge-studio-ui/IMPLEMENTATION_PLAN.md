# Forge Studio UI implementation plan

Planning-only. This file defines the future UI refactor after the functional V2 releases
are complete. It does not authorize product publication or immediate code changes.

## Objective

Bring all five commercial plugins to one Forge Studio quality bar while preserving
their distinct workflows and proven engines.

The target is not "more decoration". The target is:
- faster visual parsing;
- less admin-form density;
- stronger product identity;
- clearer relationships between objects, preview and write actions;
- premium consistency across the catalogue;
- zero regression in safety semantics.

## Preconditions

Do not start a product UI pass until:
1. its functional V2 scope is complete enough to avoid redesigning moving requirements;
2. current release/QA blockers are known;
3. the existing product engine and persistence format are treated as stable unless a
   separately justified bug requires change;
4. the target UI structure in this folder has been reviewed.

## Proposed sequence

### 1. SchemaForge — reference implementation

Why first:
- 1.1 already exposes rich structured data;
- the product benefits strongly from list/detail design;
- its engine safety is now substantially stronger than its presentation;
- it can establish shared visual primitives without requiring spatial preview work first.

Goal:
produce the first complete Forge Studio-grade DockWidget and validate the visual grammar
at 240/320/400/560 widths and light/dark themes.

Do not use SchemaForge to force a generic product framework.

### 2. PresetForge — prove reuse

Why second:
- 2.1 already has a componentized UIFactory and theme handling;
- Library/list/detail/Preview concepts overlap enough with SchemaForge to prove which
  visual primitives are genuinely reusable;
- it has a different mental model, so it is a good guard against five cloned layouts.

After this product, shared components may be extracted **only where both implementations
actually use the same behavior**.

### 3. JointForge — information architecture pass

Why:
- current UX has the highest technical-density problem;
- Create, Batch and Inspect require deliberately different structures;
- endpoint cards and master/detail inspection can demonstrate that the system supports
  complex tools without becoming an admin panel.

### 4. AccessForge — spatial builder pass

Why:
- needs the shared shell plus product-specific endpoint/assembly presentation;
- requires careful contextual preview work;
- current narrow-dock behavior needs structural rather than cosmetic correction.

### 5. CurveForge — spatial path editor pass

Why last:
- the most important improvement is contextual path/output preview;
- it benefits from lessons learned in AccessForge;
- safe world-preview implementation may require the most product-specific Studio work.

This order is a proposal, not a release dependency.

## Per-product implementation phases

### Phase A — freeze behavior

Before touching View/UI:
- record current supported workflows;
- record current write boundaries;
- record persistence/metadata format;
- run baseline engine/native tests;
- capture current UI state for comparison.

### Phase B — build static structure around real data

Implement:
- shell;
- navigation;
- list/detail hierarchy;
- cards/rows/chips;
- stable action area;
- responsive reflow.

Do not add fake controls to make a mockup look complete.

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

Where the mockup suggests a useful action that the engine does not support, either:
- omit it; or
- create a separately reviewed functional issue.

Do not silently expand the engine during a visual task.

### Phase D — interaction polish

Validate:
- focus/caret;
- scroll;
- hover/selected states;
- tooltips;
- keyboard navigation where practical;
- long names;
- duplicate names;
- empty states;
- stale states;
- error recovery;
- short-height behavior.

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
- Does a 560 px dock use the extra space intelligently rather than just stretching fields?
- Does the product still look like itself, not a recolored sibling?
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

This separation lets the cover stay cinematic while the product remains a clear,
Studio-native professional tool.
