# Forge Studio — Brand + Product Identity + Reference Convergence Pass

Status: reusable visual phase for the five Forge Studio plugins.

Use this phase **after**:
1. the functional V2 engine is complete;
2. the main UI architecture is structurally correct;
3. the product has already received its first premium-layout pass.

This phase is where a product stops looking like "a very clean plugin" and starts
looking like **a recognizable Forge Studio product with its own visual personality**.

It is not a marketing-skin pass. It must also continue correcting any remaining gap
between the real UI and the agreed professional-interface references.

---

## 1. Purpose

This phase combines three jobs that must happen together:

### A. Reference convergence
Continue pushing the real interface toward the approved quality references:
- Kern: developer-tool silhouette and split-pane seriousness;
- Untitled UI: quiet navigation;
- Linear: dense list/detail hierarchy and progressive disclosure;
- Raycast: low-chrome macOS-like restraint;
- Figma: compact inspector/property grouping;
- Apple HIG principles: hierarchy, predictability, restraint, alignment.

Do not freeze a mediocre UI merely because the architecture is already correct.

### B. Forge Studio brand integration
Introduce a restrained, repeatable Forge Studio identity:
- consistent product lockup treatment;
- common brand signature;
- shared typography/surface/spacing behavior;
- coherent icon and interaction language;
- family-level visual polish.

### C. Product identity
Make the plugin recognizable as **this specific Forge product**, not merely as a
recolored member of a family.

Product identity must emerge from:
- accent;
- domain-specific visual motif;
- work-object silhouette;
- status language;
- iconography;
- empty states;
- characteristic list/detail/preview composition.

---

## 2. Reusable order of work

Every product runs this phase in the same order.

### Phase 1 — Current UI vs references
Review real screenshots and identify:
- what already matches the references;
- what still reads as Roblox/default/admin/form UI;
- what is structurally correct but visually weak;
- what is over-designed;
- what lacks product identity.

Output a concise **Reference Gap Map**.

### Phase 2 — Implicit design questions
Before production changes, surface the questions that materially affect:
- brand;
- product personality;
- family reuse;
- information hierarchy;
- recognizable signature;
- wide/narrow behavior.

Use the question protocol below.

### Phase 3 — Brand layer
Define and implement:
- in-product Forge Studio signature;
- product name treatment;
- brand/product relationship;
- accent usage;
- shared icon rules;
- common status/interaction grammar.

### Phase 4 — Product identity layer
Define and implement:
- product-specific motif;
- product-specific icon/state language;
- characteristic work-surface details;
- empty states;
- compact identity details that survive without the title.

### Phase 5 — Reference convergence polish
Return to the real reference gap map and fix remaining mismatches:
- density;
- alignment;
- typography weight;
- list rhythm;
- inspector rhythm;
- controls;
- footer/command restraint;
- surface depth;
- selection/focus/hover;
- excessive cards or whitespace.

Branding must not become an excuse to stop improving the core UI.

### Phase 6 — Reuse inventory
Document each pattern as:
- **FORGE FAMILY**
- **PRODUCT-SPECIFIC**
- **DO NOT REUSE**

Only patterns proven in the real product qualify for reuse.

---

## 3. Question protocol

The assistant/user must participate in meaningful design decisions.

Codex/agent must classify each design ambiguity before deciding it.

### Level A — Open question
Use when the answer cannot be reduced honestly to a UI toggle because it concerns
product character, perception or brand.

Examples:
- "When somebody opens this product for the first time, what should feel most
  distinctive before they read any text?"
- "What should make this product feel more specialized than a generic developer tool?"
- "Which part of the workflow should visually feel like the product's signature moment?"
- "Should the product feel more analytical, more tactile, more spatial, or more editorial?"
- "What would make you recognize this plugin from a cropped screenshot with its title hidden?"
- "What currently still feels too generic to you, even if you cannot name the exact UI fix?"
- "What should feel expensive/premium here: the navigation, the work object, the inspector,
  the transitions, or the command area?"

For an open question:
- do not immediately collapse it into A/B/C;
- invite a short natural-language answer;
- after the answer, translate it into concrete UI decisions.

### Level B — Structured design question
Use when the intent is known but multiple concrete patterns remain plausible.

Format:

**Design decision needed**

**Question:** ...

**Why it matters:** ...

**Option A:** ...
**Option B:** ...
**Option C:** ... only if useful.

**Recommendation:** ...

**Safe reversible default:** ...

Examples:
- text-only brand signature vs small F mark + wordmark;
- selected row = tint only vs tint + rail;
- add action in section header vs compact terminal row;
- Draft/Saved = plain metadata vs dot+label vs chip;
- wide inspector = persistent vs contextual;
- icon+label vs text-only navigation.

### Level C — Autonomous implementation decision
Use for details that do not materially affect brand or family language:
- 1–2px optical alignment;
- exact separator alpha;
- internal padding within already-approved range;
- minor truncation behavior;
- harmless implementation refactor.

Do not interrupt the user for Level C decisions.

---

## 4. Question cadence

Do not dump 20 questions at once.

Recommended cadence:

### Checkpoint A — Before code
Ask 2–5 high-impact questions:
- at least one may be open-ended;
- the rest may be structured;
- explain why each question matters.

### Checkpoint B — After first real render
Ask only questions revealed by the actual rendering.

Examples:
- "Does the brand mark feel too present?"
- "Which area still feels most generic?"
- "Does the accent feel like identity or merely state color?"
- "Is the product-specific motif strong enough without the title?"

### Checkpoint C — Before freeze
Ask at most 1–2 unresolved questions.

If there is no meaningful ambiguity, do not invent one.

---

## 5. Forge Studio brand layer

The family must feel related without becoming identical.

Shared:
- BuilderSans hierarchy;
- surface logic;
- interaction states;
- icon discipline;
- restrained command bar;
- responsive principles;
- tooltip policy;
- brand signature placement logic;
- low-chrome professional tone.

Do not share:
- exact pane architecture;
- product-specific motif;
- accent;
- domain icons;
- primary work object;
- preview shape;
- workflow-specific states.

### In-product brand signature

The commercial covers have a locked Forge Studio family identity.

Inside plugins:
- keep Forge Studio visible but subordinate to the product;
- never reproduce glossy/metal cover effects literally;
- do not turn the DockWidget into advertising;
- product name remains primary;
- Forge Studio acts as maker signature.

The canonical Forge **F is already locked**: it is the F used in the approved five-product
cover family. It is not an open design question and must not be redesigned.

If that exact approved F is not yet available as a reusable in-product asset:
- do not invent, reinterpret or "improve" its geometry;
- use the approved cover F as the sole visual reference;
- if the exact asset cannot be recovered faithfully, surface an implementation question
  about how to import/reconstruct the existing mark, not a branding question about choosing
  a new one;
- a restrained text-only "Forge Studio" signature is only a temporary reversible fallback,
  never a substitute brand direction.

---

## 6. Product accent family

Locked cover-family accents:

- PresetForge — warm amber / yellow-orange — seed #D1A348
- SchemaForge — premium mint — seed #63D6AE
- CurveForge — steel/electric blue — seed #4D7DD2
- AccessForge — refined violet — seed #A34BC5
- JointForge — copper / warm orange — seed #D77A3E

These are product identity accents, not whole-screen themes.

Target normal accent coverage:
- generally 3–7%;
- slightly more only when a product-specific preview/work object genuinely requires it.

Semantic warning/error/success remain separate from identity accent.

---

## 7. Reference-convergence checklist

After branding, the UI still fails if it remains behind the references in core craft.

Review:

### Shell
- does it look like one coherent app, not stacked Roblox controls?
- are surfaces continuous where appropriate?
- are separators doing more work than cards?

### Navigation
- quiet enough?
- selected state precise?
- icon language consistent?
- does navigation avoid becoming decoration?

### Lists
- compact and scannable?
- exact baseline alignment?
- metadata sufficiently quiet?
- selected row restrained?

### Inspector
- grouped like a real property inspector?
- values more important than labels?
- related controls horizontally grouped where useful?
- advanced options visually quieter?

### Command area
- one dominant action?
- secondary actions ghost/text-level?
- status/metadata subordinate?

### Type
- enough contrast between title/body/metadata?
- too many semibold labels?
- any accidental form-like wall of text?

### Brand
- Forge Studio visible but not promotional?
- product identity recognizable beyond accent?
- could the product still be identified if its title were cropped?

---

## 8. Product-identity requirement

Accent color alone never passes product identity.

Each plugin needs at least three identifiers:

1. **Accent**
2. **Domain motif**
3. **Distinctive work silhouette**

Examples:
- SchemaForge: mint + contract/validation motif + contract→finding→decision.
- PresetForge: amber + recipe lineage motif + source→recipe→targets.
- CurveForge: blue + path/control-point motif + ordered points→output.
- AccessForge: violet + structural/endpoint motif + endpoints→assembly.
- JointForge: copper + connection motif + Part0↔Part1 relationship.

Optional fourth identifier:
- domain-specific icon family / state marks.

---

## 9. Evidence during this phase

This phase prioritizes visual iteration over exhaustive QA.

Required during iteration:
- compile/build sanity;
- one useful narrow screenshot;
- one useful wide screenshot when possible;
- screenshots from the exact current candidate;
- basic smoke check for obviously broken navigation/actions.

Not required on every iteration:
- full regression;
- full width/theme matrix;
- publication gate.

After explicit visual acceptance:
- run one final full regression once.

---

## 10. Definition of Done

This phase is complete only when:

- the UI is visibly closer to the agreed real references than the prior pass;
- Forge Studio is present as a restrained maker identity;
- the product has a distinct identity beyond color;
- accent usage matches the locked cover family;
- no major section still looks like generic Roblox/form/admin UI;
- narrow and wide both preserve product character;
- user/assistant accepts the real screenshot;
- reusable patterns are recorded;
- only then can the family move efficiently to the next product.

The final question is:

> If the title were hidden and the screenshot appeared beside the other four Forge
> products, would this still feel like the same studio **and** a different tool?
