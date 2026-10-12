# SchemaForge visual reference specification

Status: binding visual reference for issue #23. This is **not production code**.

Render/open [REFERENCE_MOCKUP.html](REFERENCE_MOCKUP.html) to understand the intended
composition. The HTML deliberately uses only simple surfaces, borders, typography and
spacing that can be translated to Roblox Studio UI.

The implementation is not required to copy CSS. It **is** required to reproduce the
same information hierarchy, density, pane relationships and interaction model as closely
as Studio allows.

## Why this exists

The first #23 pass proved that prose like "rail + list + detail" is not enough. A clean
admin panel can satisfy that wording while still missing the approved mockup.

This file removes that ambiguity.

## Desktop composition at ~560 px

Target:
- header: ~68 px;
- main content: ~510 px;
- footer command bar: ~62 px;
- outer padding: 12 px;
- gaps: 8 px;
- columns approximately:
  - navigation/library: 124 px;
  - findings/rules collection: 186 px;
  - selected detail: remaining ~200 px.

Do not blindly copy these values if native chrome changes the client area by a few pixels.
Keep the proportions and hierarchy.

### Header

One object, not three unrelated labels:
- SchemaForge = small product identity;
- current contract = strongest line;
- tag / class / scope = one quiet metadata line;
- Saved / Draft / Stale = compact status chip.

Do not spend header space on decorative branding.

### Navigation/library rail

Tool rail, not button stack:
- mostly transparent inactive rows;
- active row = subtle tint + narrow accent marker;
- small count at far right;
- project library below, compact rows;
- selected library contract visibly distinct without a giant mint rectangle.

### Findings collection

This is the visual anchor:
- compact title/count;
- filters directly under title;
- search directly under filters;
- rows ~50–56 px;
- primary = field/rule;
- secondary = object + reason;
- optional tiny FIXABLE badge;
- no full paths/explanations in the row.

Selected row gets:
- precise border;
- restrained surface tint;
- status rail;
- no giant fill.

### Selected finding detail

The right pane must feel like a dedicated inspector:
- category/repairability kicker;
- field/rule as work title;
- object/path as metadata;
- Expected and Actual as visually paired values;
- designer note attached to the finding;
- suggested repair only when actually repairable;
- Select in Studio as secondary action.

No 3D object preview is required by default.

### Bottom command bar

Stable app command bar:
- secondary re-run audit action;
- exact selected safe-repair summary;
- one dominant Preview/Apply action at far right;
- does not jump as selection/details change.

## Selection vs inspection vs Preview — hard rule

These are three different concepts.

### 1. Selecting a finding/rule/library row

Selection MUST:
- update the selected row state;
- update the detail inspector;
- preserve scroll where expected.

Selection MUST NOT automatically:
- call `Engine.preview`;
- re-run the audit;
- change the Studio Selection;
- build a ViewportFrame/3D preview;
- open a modal;
- replace the entire screen on wide mode;
- generate repair output;
- auto-apply or auto-select a suggested repair.

The detail inspector is **inspection**, not Preview.

### 2. "Select in Studio"

This is an explicit secondary action.
Only this action changes Roblox Studio Selection for the selected finding/object.

Do not change Studio Selection merely because the user clicks a finding row.

### 3. Preview changes

Preview is an explicit command.
Only the explicit Preview action should call the real preview/plan path.

After Preview:
- show exact planned changes;
- show exact count/scope;
- enable Apply only if still fresh;
- if relevant selection/project/schema state changes, mark Preview stale;
- do not auto-regenerate Preview.

This separation is mandatory because automatic preview/selection coupling makes the
tool feel unstable and difficult to reason about.

## 3D thumbnails / object preview policy

SchemaForge is an audit/contract tool, not a model viewer.

Default finding detail should **not** reserve large space for a 3D object thumbnail.

A small icon/class indicator is enough.

Only add a ViewportFrame later if:
- it solves a demonstrated identification problem;
- it does not destabilize layout;
- it is optional/non-dominant;
- it is real and cheap enough for many findings;
- human review explicitly approves it.

Issue #23 should not add one merely because the original generated mockup showed a plant.

## Rules composition

The visual reference for Rules uses the same shell:
- left rail remains;
- center = compact rule collection;
- right = selected rule inspector.

Rule row:
- rule name;
- type;
- compact summary (required/default/bounds/tag/child);
- selected state.

Rule inspector groups:
1. Identity
2. Type
3. Constraints
4. Repair/default semantics
5. Designer note

Do not copy the old vertical form into the right pane unchanged.
Pair related numeric inputs; keep booleans compact; make advanced constraints quieter.

## Narrow 320

No side rail and no 3-column squeeze.

Default Audit:
- compact header;
- top mode tabs;
- findings list full width;
- stable bottom action bar.

Click finding:
- dedicated detail state;
- back to Findings;
- Expected/Actual;
- note;
- repair;
- secondary Select in Studio;
- explicit Preview action.

## Narrow 240

One view at a time:
- minimal metadata;
- no side rail;
- filters collapse;
- detail and repair are dedicated states;
- primary action remains reachable.

## Visual non-negotiables

- BuilderSans in production.
- Mint ~5–10% of screen area.
- 3–4 depth levels maximum.
- No heavy glow.
- No faux metal.
- No giant pills.
- No card around every group.
- No large dead canvas.
- No default-looking full-width button for every action.
- No equal typography weight for product/context/pane/item/path.

## Human visual acceptance

Automated geometry tests cannot approve this reference.

Before issue #23 is complete:
1. capture actual final screenshots at 320 and 560;
2. compare them to REFERENCE_MOCKUP.html and the approved generated mockup direction;
3. human review must confirm the composition is materially close;
4. if it still reads as an internal Roblox utility/admin panel, continue iterating.
