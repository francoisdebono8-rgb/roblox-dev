# Forge Studio UI work-order template

Use this template **only after all five functional V2 releases are finished and the user
explicitly starts the Forge Studio UI programme**.

Copy it into the product UI issue and replace bracketed values.

---

## Product

[PRODUCT] — Forge Studio UI pass.

Baseline commit/artifact:
- commit: [SHA]
- package version: [VERSION]
- canonical asset: [ASSET]
- exact final functional V2 gate: [PATH/LINK]

## Source of truth

Read before implementation:
1. `docs/forge-studio-ui/README.md`
2. `docs/forge-studio-ui/VISUAL_DIRECTION.md`
3. `docs/forge-studio-ui/SHARED_SYSTEM.md`
4. `docs/forge-studio-ui/PRODUCT_AUDITS.md`
5. `docs/forge-studio-ui/PRODUCT_STRUCTURES.md`
6. `docs/forge-studio-ui/QUALITY_GATES.md`
7. the product's current V2 audit/release gate.

Do not reinterpret the task as a generic theme refresh.

## Required outcome

Recompose [PRODUCT]'s actual workflow using the product-specific target structure while
preserving the existing functional engine and write semantics.

The result must:
- look intentionally designed at 240/320/400/560 px;
- use the Forge Studio shared visual grammar;
- keep [PRODUCT]'s unique work silhouette;
- expose real engine data only;
- keep Preview/write safety intact;
- be visually good enough for a real Studio screenshot without recreated UI.

## No-scope list

Do not:
- add a feature only because a mockup looks better with it;
- change canonical asset;
- replace native Undo/Redo;
- weaken stale-write protection;
- introduce a generic Forge workflow framework;
- copy another product's information architecture;
- fabricate a preview;
- implement cover-style metallic/glow controls inside the tool.

## Implementation checkpoints

### Checkpoint 1 — before code
Record:
- current major views;
- current primary action per view;
- exact engine calls the UI invokes;
- current persistence/write boundaries;
- current responsive behavior;
- current screenshots at 320 and 560.

### Checkpoint 2 — structure
Implement the product structure from `PRODUCT_STRUCTURES.md`.

Stop and review before visual polish if the information architecture materially differs
from the documented target.

### Checkpoint 3 — visual system
Apply:
- shared spacing;
- shared typography scale;
- product accent;
- button hierarchy;
- list row/detail patterns;
- stable action area;
- all component states.

### Checkpoint 4 — native interaction
Test:
- real clicks;
- focus/caret;
- scroll preservation;
- selected state;
- long names;
- duplicate names;
- empty;
- stale;
- blocked/error;
- success.

### Checkpoint 5 — responsive
Native test:
- 240x360;
- 320x640;
- 400x640;
- 560x640;
- 560x900 where useful;
- Light;
- Dark.

### Checkpoint 6 — functional regression
Run the full product final gate and native Undo/Redo.

## Required evidence table

| Gate | PASS / FAIL / NON TESTED | Evidence |
|---|---|---|
| 240 width usable | | |
| 320 width usable | | |
| 400 width usable | | |
| 560 width uses extra space | | |
| Light theme | | |
| Dark theme | | |
| Product context obvious | | |
| Selected item obvious | | |
| Preview state obvious | | |
| Stale state blocks write | | |
| Primary action stable | | |
| Long names | | |
| Duplicate names | | |
| Empty state | | |
| Blocked/error state | | |
| Success state | | |
| Native Undo | | |
| Native Redo | | |
| Artifact/source equality | | |
| Real screenshot needs no UI recreation | | |

## Close criteria

Do not close the issue until:
- `QUALITY_GATES.md` passes for every applicable gate;
- product-specific non-regression passes;
- final screenshots come from the exact final artifact;
- any deviation from the documented structure is explained;
- reused shared components and intentionally product-specific components are listed.
