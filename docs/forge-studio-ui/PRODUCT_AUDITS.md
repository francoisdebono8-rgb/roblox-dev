# Forge Studio product UI audits

Planning-only audit of the **actual checked-in product UIs**. This is not an implementation
request and does not change the products.

Sources reviewed include the current UI modules, the V2 product audits, current release
docs and native QA evidence. Visual judgments below distinguish actual current structure
from the future design target.

---

# SchemaForge

## Current product

Current reviewed version: **1.1.0**.

Current shell in `SchemaForge/Modules/View.luau`:
- 128 px header;
- product title + loaded/draft schema context;
- tag/class and scope context;
- `Rules / Audit / Repairs` tabs;
- separate `Library` button;
- one scrolling work body;
- fixed footer with primary action, status and version;
- Studio theme-derived surfaces with mint accent.

The 1.1 engine now genuinely supports the information needed for a premium diagnostic UI:
structured finding categories, Expected/Actual, designer notes, reason/field filters,
finding subsets, selection, conservative missing-only repair, stale-plan blocking and
native Undo/Redo.

## What already works visually/structurally

- context is no longer completely detached from the work;
- primary actions stay in a stable footer;
- narrow-width support is explicitly engineered;
- errors can appear beside invalid drafts;
- findings contain rich information rather than only a raw error string;
- the Library is no longer a fixed column consuming narrow layouts.

## Main visual/UX problem

The interface still reads as a **well-engineered configuration form**.

Most hierarchy is produced from the same primitives:
- 14 px text;
- full-width 32 px buttons;
- stacked TextBoxes;
- menu buttons;
- labels;
- checkboxes.

In Audit, one finding is rendered as a vertical stack:
include toggle -> identity -> path -> reason -> Expected -> Actual -> note -> Select object.
The content is excellent, but its presentation is dense and slow to scan.

Rules has the same issue: choose a field/child from a menu, then edit a long vertical
form. It exposes the engine faithfully but does not yet feel like a purpose-built
contract editor.

## Target experience

SchemaForge should become a **contract review workspace**, not a schema form.

Wide layout:
- compact persistent contract/navigation rail;
- audit list as the primary surface;
- selected finding opens a real detail panel;
- Expected/Actual is a paired visual block;
- designer note has a clear secondary location;
- repairability is a status chip, not buried in text;
- suggested safe repair is a distinct action card;
- Rules uses rule list + selected-rule editor;
- Library is a first-class contract area, not a hidden fourth screen.

Narrow layout:
- single-column list/detail flow;
- findings list -> finding detail -> repair preview;
- filters collapse into one compact control;
- full path moves behind detail/tooltip;
- no compressed fake desktop split view.

## Preserve

Do not redesign the engine while redesigning the UI:
- explicit saved contracts;
- V1 compatibility;
- rule types/ranges/choices/child requirements;
- missing-only repair;
- exact subset semantics;
- stale detection;
- native history.

---

# PresetForge

## Current product

Current reviewed version: **2.1.0**.

PresetForge is already the most componentized UI in the catalogue. `UIFactory.luau`
provides theme-aware surfaces, borders, hover/selected states, search, responsive tabs,
a fixed Preview/Apply footer and an editor overlay.

Current main navigation:
- Library;
- Recipe;
- Targets;
- Changes.

Current capture/editor overlay:
- source;
- recipe name;
- Local/Project storage;
- captured fields;
- tags;
- attributes;
- Save/Cancel.

Current Changes view distinguishes affected/matching/ignored results and provides selection
and framing controls.

## What already works visually/structurally

- real Studio light/dark integration;
- BuilderSans;
- proper selected/hover states;
- responsive 4-tab navigation;
- search is already first-class;
- fixed primary action footer;
- capture editor is separated from browsing;
- Preview and Apply have a clear stage boundary.

This is a useful implementation reference for shared Forge primitives.

## Main visual/UX problem

The product is still organized like four **administrative pages** around one workflow.

The user mentally wants:
> choose recipe -> choose targets -> inspect changes -> apply.

But the UI makes Recipe, Targets and Changes separate peers, so important context is
repeatedly left behind while moving between tabs.

Recipe presentation is mostly labels and buttons. Targets is mostly scope/filter controls.
Changes is mostly result rows. The system is competent but does not visually communicate
the central concept strongly enough:

> a reusable recipe carries chosen fields from one source to a precise target set.

The current visual structure therefore undersells the product's actual differentiation.

## Target experience

PresetForge should become a **recipe workspace**.

Wide layout:
- compact searchable recipe library on the left;
- selected recipe header/card with Local/Project badge and captured-field summary;
- main workspace shows target scope and pending changes together;
- Changes becomes the dominant review surface after Preview;
- affected rows show field-level before/after without making matching rows compete;
- matching/ignored groups remain collapsed by default;
- fixed action area shows exact affected count before Apply.

Capture/Edit:
- focused editor surface;
- source identity at top;
- captured properties/tags/attributes grouped clearly;
- storage choice visibly explains Local vs Project;
- no generic wall of checkboxes when grouping can clarify the recipe.

Narrow layout:
- Library -> Recipe -> Target/Preview as sequential views;
- current recipe identity remains in the compact header;
- Preview/Apply stays reachable.

## Preserve

- current capture/property support;
- per-field selection;
- filters;
- Local/Project semantics;
- recipe migration;
- search/duplicate;
- exact preview/write scope;
- native Undo/Redo;
- current responsive correctness.

---

# CurveForge

## Current product

Current reviewed version: **1.0.0**.

Current UI is essentially one long scrolling workflow:
- title;
- PATH;
- New Path / Use selected points;
- one row per control point with text actions `Up / Down / Remove`;
- Confirm displayed order;
- OUTPUT MODE;
- SETTINGS;
- isolated DockWidget ViewportFrame;
- Preview / Build or Regenerate;
- EDIT EXISTING at the bottom.

Cable mode includes diameter, segment length, swatches/RGB, material and physical toggles.
Repeat mode includes source, spacing/count and orientation options.

## What already works visually/structurally

- the workflow is explicit;
- control points are visible and selectable;
- mode-specific settings are bounded;
- Preview exists before Apply;
- edit/regenerate reuses the existing product engine;
- the current View already preserves scroll during renders.

## Main visual/UX problem

The product's strongest concept — **editing a path in space** — is represented as a long
form.

Control points are rows of text buttons rather than a purposeful ordered path editor.
`Edit Selected CurveForge Model`, one of the highest-value recurring actions, is below
the whole new-path workflow.

The isolated preview is also disconnected from the world context that matters:
pole alignment, clearance, source distribution and environmental fit.

The current UI therefore feels like parameter entry for a geometry script rather than
a visual path-building tool.

## Target experience

CurveForge should become a **path editor with contextual output controls**.

Wide layout:
- top-level `New Path` and `Edit Selected` entry actions;
- ordered control-point rail/list with numbered markers;
- locate/select/reorder controls using compact icons;
- main settings panel changes with Cable/Repeat mode;
- contextual preview is visually dominant;
- existing output vs proposed output is explicit;
- length / segment or copy count is a concise preview summary;
- Preview/Build/Regenerate remains stable.

The mini ViewportFrame can remain as fallback, but it should not be the only meaningful
visual feedback if a safe contextual world-preview implementation is validated.

Narrow layout:
- point list and settings become sequential sections;
- selected point remains obvious;
- preview becomes a dedicated view/drawer instead of a tiny squeezed panel.

## Preserve

- 2-8 bounded control points;
- current Cable and Repeat engines;
- source preservation;
- re-edit/regenerate metadata;
- read-only preview semantics;
- native Undo/Redo;
- no roads/terrain/automatic routing scope creep.

---

# AccessForge

## Current product

Current reviewed version: **1.0.0**.

Current structure:
- horizontally/vertically scrollable shell with a forced internal minimum around 350x620;
- header with `Straight / Switchback / Catwalk`;
- `Layout / Rails / Finish` sections;
- Layout contains Start/End assignment, New markers, Edit Existing and dimensions;
- fixed lower result area with metrics, an isolated ViewportFrame and Preview/Build;
- Rails and Finish are parameter forms.

## What already works visually/structurally

- product modes are real and explicit;
- settings are already separated into sensible domains;
- Start/End are explicit concepts;
- a geometry summary exists;
- a preview surface and stable lower action zone exist;
- Edit Existing is supported.

## Main visual/UX problem

The UI currently solves narrow docks by making the **plugin internally wider than the dock**,
which protects controls but produces the wrong product feel.

The result still reads as an engineering parameter sheet:
mode buttons -> tab buttons -> rows of numeric fields -> preview.

The most important user question is not "what number did I type?" but:
> does this stair/catwalk fit the actual platform between these endpoints?

The current isolated preview cannot answer that well.

Start/End also lack strong visual endpoint identity and locate/reverse affordances.
The preview metrics are useful but visually disconnected from the geometry they describe.

## Target experience

AccessForge should become an **industrial assembly builder**.

Wide layout:
- mode selector for Straight / Switchback / Catwalk;
- prominent endpoint assignment card showing Start and End together;
- locate each endpoint + reversible swap action;
- compact `Layout / Rails / Finish` section navigation;
- settings grouped into meaningful cards;
- large contextual assembly preview;
- geometry metrics attached to preview, not floating as raw text;
- existing assembly name/replace target visible when regenerating;
- fixed Preview / Build or Regenerate action.

The stair/catwalk silhouette and dimension relationships should make the product visually
recognizable even before reading every field.

Narrow layout:
- no horizontal scrolling;
- mode selector collapses/wraps safely;
- endpoints become stacked cards;
- preview becomes a dedicated section;
- primary action remains fixed/reachable.

## Preserve

- Straight / Switchback / Catwalk engines;
- rails/supports/material/finish settings;
- marker semantics;
- explicit regeneration;
- user-added-object protection;
- native Undo/Redo;
- no engineering/code-compliance claim.

---

# JointForge

## Current product

Current reviewed version: **1.0.0**.

Current top-level tabs:
- Create;
- Batch;
- Inspect.

Create:
- choose joint/constraint type;
- assign Part0 and Part1;
- optionally use/create attachments;
- Preview;
- Apply.

Batch:
- choose root;
- assign selected parts as Static or Moving;
- Preview assembly;
- Apply.

Inspect:
- scan current selection;
- render each found joint as stacked text;
- Inspect/Edit or mark Remove;
- selected joint edit form is appended later in the same scroll;
- Preview checked removals;
- shared preview text appended to the workflow.

## What already works visually/structurally

- three real workflows are separated;
- Preview precedes every write;
- endpoints are explicit;
- supported type scope is bounded;
- Inspect can locate endpoints/joint;
- Batch has a clear root + Static/Moving model;
- conflict and removal safeguards are real.

## Main visual/UX problem

JointForge is the strongest example of the current **technical-tool aesthetic**.

The UI exposes a lot of raw implementation detail:
- long object paths;
- generic stacked labels;
- generic `SELECT > TYPE > PREVIEW > APPLY` copy even where Inspect does not follow it;
- textual endpoint identity;
- property forms appended beneath lists;
- preview operations as text paragraphs.

Repeated hierarchies can display indistinguishable endpoint paths. The user needs a
spatial/relational understanding of two endpoints, not more path text.

## Target experience

JointForge should become a **connection inspector / assembly tool** with different
work surfaces per mode.

### Create
- strong Part0 / Part1 paired endpoint cards;
- each endpoint has identity, class, locate/select and assignment state;
- center connection/type selector visually links the pair;
- attachment state appears inside the endpoint card;
- conflict/anchored warnings sit next to the affected endpoint/connection;
- preview summarizes the exact connection before Apply.

### Batch
- Root card at top;
- assigned parts as a compact list/table with `Static` / `Moving` status chips;
- fast reassignment/removal;
- preview groups planned WeldConstraint vs Motor6D operations;
- conflicts are visible per row, not buried in a message.

### Inspect
- master list of joints/constraints;
- broken/conflict filters;
- selected joint opens a dedicated detail/field panel;
- endpoint pair remains visible while editing;
- removal selection is explicit and visually separated from normal inspection.

Narrow layout uses list -> detail navigation rather than squeezing two columns.

## Preserve

- nine supported joint/constraint types;
- explicit endpoints;
- attachment policy;
- conflict policy;
- world-pose preservation where currently promised;
- inspect-only unsupported classes;
- preview-before-write;
- removal confirmation;
- native Undo/Redo;
- no auto-rigging, auto-unanchoring or silent endpoint repair.

---

# Cross-product conclusion

The current catalogue has reached the point where **the engines are more mature than
their presentation**.

The goal of the future Forge Studio UI pass is not to add visual noise. It is to make
the existing product concepts visible:

- PresetForge = recipe -> targets -> exact changes;
- SchemaForge = contract -> findings -> safe repair;
- CurveForge = path -> output -> contextual preview;
- AccessForge = endpoints -> industrial assembly -> fit/regenerate;
- JointForge = endpoints/assembly graph -> inspect -> precise write.

That distinction should remain obvious even if all five share the same visual grammar.
