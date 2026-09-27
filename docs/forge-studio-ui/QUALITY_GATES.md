# Forge Studio UI quality gates

Status: future UI acceptance contract. **Not active for implementation until all five
functional V2 releases are finished.**

This file converts the art direction into checks that a future implementation must
actually satisfy. A UI task is not complete because "it looks cleaner" or because all
buttons still work.

## Gate 0 — sequencing

Before any Forge Studio visual refactor:
- all five catalogue products have completed their functional V2 scope;
- the user has explicitly opened the UI programme;
- the exact product baseline commit/artifact is recorded.

If not, stop at design/documentation.

## Gate 1 — shell geometry

Every product must be manually/native tested at:

- widths: **240 / 320 / 400 / 560 px**
- heights: **360 / 640 / 900 px** where meaningful
- Studio **Dark** and **Light** themes

Required:
- no horizontal form scrolling;
- no clipped primary action;
- no clipped product title/current-context identity;
- no hidden mode required for the main workflow;
- no overlapping text or controls;
- no control smaller than 28 px interactive target unless it is a noninteractive label;
- body scroll is deliberate and singular per main pane;
- action area remains stable when Preview appears/disappears.

## Gate 2 — spacing and typography

Measure representative screenshots.

Required defaults:
- outer work padding: **12 px**
- micro spacing: **4 px**
- normal gap: **8 px**
- major section gap: **16 px**
- exceptional separation: **24 px**
- common interactive height: **30-34 px**
- card radius: **4-8 px**
- border: **1 px**
- body/control text: **13-14 px**
- metadata/helper: **12-13 px**
- section title: **14-15 px semibold**
- work title: **16-18 px semibold**
- product title: **18-20 px semibold/bold**

Exceptions require a product-specific reason, not random drift.

## Gate 3 — hierarchy

For each primary view, a reviewer should be able to identify in under ~2 seconds:

1. current product;
2. current document/recipe/path/assembly/joint context;
3. current work mode;
4. selected item, if any;
5. current state: draft / preview-ready / stale / blocked / success;
6. primary next action.

Fail if the reviewer must read a paragraph or scan every control to determine these.

## Gate 4 — control hierarchy

Every screen must classify controls into:
- one primary action for the current stage;
- secondary actions;
- tertiary/icon actions;
- destructive actions.

Fail if five or more unrelated full-width buttons have equal visual weight.

Required:
- booleans use checkbox/toggle affordances;
- small exclusive sets use segmented controls;
- long option sets use menus;
- reorder uses compact controls, not large text buttons;
- delete/remove is visually separated from common editing.

## Gate 5 — state completeness

Every relevant component must have deliberate:
- rest;
- hover;
- pressed;
- selected;
- focus;
- disabled.

Every workflow must have deliberate:
- empty/incomplete;
- draft;
- preview-ready;
- stale;
- blocked/error;
- success.

Required:
- stale state disables write;
- stale state removes/invalidates old success wording;
- error copy is human-readable;
- raw Lua stack prefixes are not shown;
- semantic states do not rely on product accent alone.

## Gate 6 — responsive composition

### 560 px
Must use width meaningfully when the product benefits:
- list + detail;
- settings + preview;
- endpoints + plan.

Fail if the design merely stretches inputs.

### 400 px
May retain two-pane composition only if both panes remain legible.

### 320 px
One main column by default. Detail opens as another view/drawer when necessary.

### 240 px
Must remain fully operable:
- filters can collapse;
- metadata can move into detail;
- labels can shorten;
- primary actions stay visible;
- no hidden functionality behind horizontal scroll.

## Gate 7 — product silhouette

A screenshot with the title cropped should still strongly suggest which product it is.

Required signatures:

### PresetForge
- recipe library/identity;
- targets;
- changes/before-after.

### SchemaForge
- contract context;
- findings list;
- selected finding detail;
- Expected/Actual;
- bounded safe repair.

### CurveForge
- ordered path points;
- cable/repeat mode;
- path/output preview.

### AccessForge
- Start/End context;
- Straight/Switchback/Catwalk;
- industrial assembly preview;
- dimensions/rails relationship.

### JointForge
- Part0/Part1 or connection relationship;
- Create/Batch/Inspect distinction;
- joint type/connection state;
- plan/inspection detail.

Fail if the product could be recolored and relabeled as another Forge tool without
structural change.

## Gate 8 — preview prominence

Preview/review is a commercial core of all five products.

Required:
- Preview has a dedicated visual surface or clearly dominant review state;
- exact counts are visible;
- scope/target is visible;
- proposed change is distinguishable from current state;
- write action is adjacent to the review state;
- stale Preview is visibly invalidated.

Product expectations:
- Preset: before/after changed fields;
- Schema: exact safe missing-default repairs;
- Curve: proposed path/output, existing vs proposed when editing;
- Access: proposed assembly and fit/context;
- Joint: exact planned create/edit/remove operations.

## Gate 9 — list quality

Any repeated item list must use a designed row.

Default row budget:
- one primary identity line;
- one concise metadata line;
- one status chip/marker;
- max two immediate row actions.

Extra detail belongs in a detail panel/view.

Fail if every row dumps path + reason + expected + actual + note + buttons at once.

## Gate 10 — visual restraint

Fail for:
- faux-metal controls inside the functional UI;
- heavy glow;
- gaming/esports chrome;
- excessive gradients;
- every section inside a card;
- oversized pills;
- heavy shadows;
- decorative UI that competes with data.

Pass target:
- one quiet base;
- one dominant work surface;
- a few meaningful raised groups;
- restrained product accent;
- semantic colors kept separate.

## Gate 11 — truth

Every visible control and value must be real.

Fail immediately for:
- mock-only button;
- fabricated count;
- fabricated PASS/success;
- decorative "live" state not backed by engine state;
- preview graphic unrelated to actual plan;
- hidden behavior change introduced only to make the UI screenshot look better.

## Gate 12 — real screenshot test

For the final artifact, capture at minimum:
- 320x640 representative workflow;
- 560x640 representative workflow;
- one narrow/short case;
- one Light-theme case;
- one Dark-theme case.

The UI passes the visual gate only if these screenshots can be used for internal/product
review **without redrawing the interface**.

Cropping Studio chrome is allowed. Recreating the plugin UI in an image editor is not.

## Gate 13 — functional non-regression

The UI pass must rerun the product's native functional acceptance:
- Preview read-only where promised;
- stale writes blocked;
- exact Apply/Build/Regenerate scope;
- native Undo/Redo;
- persistence/reload where applicable;
- source/user-content preservation;
- artifact/source correspondence.

A prettier UI with weaker safety fails.

## Gate 14 — product-specific review

### PresetForge
- current recipe always identifiable;
- Local vs Project obvious;
- affected changes dominate matching/ignored;
- target scope visible at Preview;
- before/after readable without opening Properties.

### SchemaForge
- schema/tag/scope visible;
- finding category scannable;
- selected finding has Expected/Actual/note;
- repairability explicit;
- wrong-type/invalid/child findings never imply auto-repair.

### CurveForge
- selected control point obvious;
- point order obvious;
- Edit Selected is first-class;
- Cable/Repeat visually distinct;
- preview is usable against real context where safe.

### AccessForge
- all three modes reachable without horizontal scroll;
- Start/End visually paired;
- Edit Existing first-class;
- stale Preview state impossible to confuse with ready state;
- preview explains fit/assembly, not only isolated geometry.

### JointForge
- Part0/Part1 distinguishable even with duplicate names;
- Create/Batch/Inspect have different task-appropriate composition;
- conflicts/broken endpoints visible at item level;
- destructive removal separated from inspect/edit;
- preview clearly identifies exact operation.

## Definition of done

A future Forge Studio UI issue may close only when:
- every applicable gate above is marked PASS;
- any exception has a written product-specific justification;
- real final-artifact screenshots are attached/linked;
- native QA passes;
- no UI shown in media differs functionally from the shipped artifact.
