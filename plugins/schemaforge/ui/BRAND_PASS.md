# SchemaForge #25 / brand convergence iteration

Baseline: accepted #23 at `1c644998a1d7a62fcec97ff8bae9eba6be6ab054`.
Artifact SHA256: `542131178c45716fca27d12f7b1ec8678fae3c414e6d33645cf23229f65cb126`.
Status: visually accepted on 2026-10-03 ("c est acceptable").
Final technical regression PASS; final graphical gate incomplete. NOT published.

## Decisions before code

User answered: "1 la bonne impression, A , A".
- Personality: a good first impression; interpret provisionally as clear, composed
  and trustworthy, not decorative. Judge the real rendering with the user.
- Maker signature: subordinate in the header; SchemaForge remains the product.
- States: quiet document text; Stale gets an alert; diagnostic symbols/text, not
  systematic badges. Selection is not a diagnostic severity.
- Canonical cover F and mint #63D6AE are locked. No alternate F or monogram.
  Superseding owner instructions in #25 and commit `2930298` provide the exact
  `docs/forge/forge-studio-ui/brand/assets/forge-f.svg` source. The earlier cover
  extraction experiment was discarded. `rasterize_brand.cjs` rasterizes this
  SVG using sharp, preserving the full 160x210 viewBox ratio at 32x42 pixels.
  View renders its generated alpha runs at 16x21 logical pixels using native
  Frames: no upload, remote dependency, AI, cover tracing or alternate geometry.
  The canonical family spec, machine-readable palette and SchemaForge identity
  spec are now binding sources. The geometry is not product-specific.

## Reference gap map

| Current accepted view | Preserve | First reversible refinement |
|---|---|---|
| Header | Compact contract/tag/class/scope | Distinguish product, maker, document; no extra header band |
| Findings | Dense list/detail, real categories | Separate neutral subset checkboxes from diagnostic markers |
| Expected/Actual | Equal heights, real values | One comparison surface, quiet rule/observed labels, central divider |
| Repair | Bounded additive operation | Strongest restrained mint moment; no giant checkmark |
| Diagnostic-only | No automatic repair | Deliberate labeled review state instead of an orphan sentence |
| Rules | Inline inspector, compact collection | More precise selected-rule marker, lighter input surfaces |
| Commands | Stable footer, explicit Preview | Keep primary/secondary hierarchy and safety unchanged |

Visual thesis: a quiet diagnostic tool whose exact rule/value comparison makes
the decision clear; the maker signature supports rather than occupies the work.
Content: persistent identity -> rules/findings -> selected evidence -> explicit
decision. Interaction: precise stationary hover/focus/selection; no ornamental
motion, automatic Preview, modal inspection or 3D preview.

References: mandatory #25 documents and approved mockup; Kern composition,
Untitled navigation, Linear list/detail, Raycast restraint, Figma inspector.
The accepted baseline captures are in `refined-review`.

## Iteration gates

Compile/build and focused native navigation/Preview smoke only. Capture useful
320/560 native views. Do not rerun the 53/41 suite or the full theme/size matrix
until explicit visual acceptance. Engine/Schema/Store remain frozen.
No #24, public asset update, commercial media, listing or outreach.

Next review question after the real Audit render: which part feels most
SchemaForge now, and which part still feels generic?
The user accepted the actual canonical-SVG 560/320 renders without requesting
another visual iteration. Do not reopen design choices without new feedback.

## First Native Review / 2026-10-03

Candidate SHA256: `2a46a83c0cabd2867a699e0b888ea3a27eb99d905f4ea8a76af32b1d5cef3cc8`.
Canonical SVG SHA256: `8486b53c0bcda26fcb5d9ad1cc3dd10df9db14444ccbb5f52d97971c0a4cccbd`.

- PASS: View compilation, five-source package equality and reproducible binary.
- PASS: generated mark raster equals the canonical SVG rasterization.
- PASS: real Studio mount and Rules -> Audit navigation; 7 objects / 8 findings.
- PASS: explicit Preview calls the engine once, proposes 4 additions, and leaves
  the fixture unchanged (3 missing costs, 1 missing tag, invalid values retained).
- PASS: 320px list -> detail navigation and selected diagnostic comparison.
- PASS: native geometry checks on the visited Rules/Audit/Preview 560 views and
  Preview/Audit/detail 320 views. This is not the full matrix.
- NON TESTED this iteration: Apply/Undo/Redo, persistence, all themes/widths,
  complete 53/41 regression. Historical #23 results are not transferred.
- At first review: visual acceptance and final regression were pending. See the
  subsequent accepted-candidate results below; the first review is historical.

The existing disposable harness imports the exact commercial artifact sources;
its QA copy disables Main and mounts View with the real engine. No QA enters dist.
The 320 view uses a 320x640 native host inside the wider floating test window.
Internal captures are pixel-only crops, never redraws or commercial media:
`brand-review/dark-560-audit.png` and `brand-review/dark-320-detail.png`.
Raw native windows are retained alongside them; crop origin (48,86), dimensions
1120x1280 and 640x1280 physical pixels (Retina 2x). No color/scale retouching.
`brand-review/native-smoke.txt` contains only the tagged native QA output.
Main, Engine, Schema and Store are unchanged. Canonical asset untouched.

## Post-Acceptance Final Validation

Same accepted candidate SHA256, no production changes after visual acceptance.
Studio 0.741.19.7411056, isolated Edit-mode exact-binary gate:
**53 PASS / 0 FAIL, 41/41 technical matrix rows PASS, outer gate PASS**.
Evidence: `brand-review/native-technical.txt` and
`../tests/technical-1.2.0-results.json` (candidate hash verified by collector).
Includes native transactions, persistence, typed repairs, stale checks and
Undo/Redo. These are native suite results, not claims of GUI menu clicks.

The final Rules geometry probe passed all five sizes in Dark (240x360,
320x640, 400x640, 560x640, 560x900). The repeated matrix calls remained on
Rules: attempted navigation did not reliably land. Do not count them as Audit
or Repairs coverage. An incidental Save on the unloaded fixture was correctly
blocked by the existing saved-schema conflict guard; it made no source change.

Final GUI access then failed: CUA reported `noWindowsAvailable`; System Events
no longer exposed the main window, and the Mac foreground was a full-screen
browser. Targeted mouse attempts left the intended navigation unchanged.
The user was asked to leave Studio visible. No failed attempt is counted PASS.
Tagged evidence: `brand-review/native-final-attempt.txt`.

Remaining final checks before #25 closes:
- Light rendering and the short/narrow actual screenshot on this exact binary;
- per-view Light/Dark geometry and live theme behavior for the changed controls;
- controlled GUI subset/Apply/Undo/Redo and stale action spot check.
The existing accepted Dark 320/560 captures and read-only Preview smoke remain
valid for this same binary. No need to rerun the 53/41 technical suite unless
production source changes. Do not mark #25 READY yet or start #24.

## Accepted Pattern Inventory

These are design contracts for later products, not a shared UI framework.

| Pattern | Classification | Boundary |
|---|---|---|
| Canonical flat F + quiet Forge Studio signature | FORGE FAMILY | Rasterize the provided SVG; preserve ratio; no logo variants or remote dependency |
| Product/maker/document hierarchy | FORGE FAMILY | Compact header; maker subordinate; do not force the same pane widths |
| Neutral surfaces, BuilderSans, independent semantic colors | FORGE FAMILY | Product accent does not replace warning/error meaning |
| Quiet document metadata with exceptional alert | FORGE FAMILY | Distinguish document state from item selection and diagnosis |
| Neutral subset checkbox + diagnostic marker | FORGE FAMILY | Selection is separate from validity; retain a 28px target |
| Explicit command hierarchy and nonredundant tooltips | FORGE FAMILY | One primary command; never auto-preview on inspection |
| Contract/rule/finding -> decision composition | SCHEMAFORGE-SPECIFIC | Not a template for paths, recipes or assemblies |
| Expected/Actual paired surface and bounded safe repair | SCHEMAFORGE-SPECIFIC | Real engine values; equal comparison bottoms; missing/additive repair only |
| Mint repairability and manual-review language | SCHEMAFORGE-SPECIFIC | Wrong types/invalid values never imply automatic repair |
| Raster-cover tracing and generated replacement monograms | DO NOT REUSE | Superseded by the canonical SVG source |
| Metallic/glow cover styling inside the functional UI | DO NOT REUSE | Cover art is not DockWidget chrome |
| Three-pane SchemaForge layout copied across all products | DO NOT REUSE | Each product keeps its own work-object composition |

Typography exceptions retained for compact Studio docks: 13px bold product,
11px maker/document metadata, 17px contract, 10px comparison labels and 15px
comparison values. Native screenshots were accepted with this hierarchy; no
font dependency or viewport-dependent font scaling is introduced.
