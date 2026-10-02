# SchemaForge — Brand + Identity + Reference Convergence

Status: next binding visual phase for issue #23.

Baseline:
- current UI architecture and premium language from commits 65390454 and e0006e75;
- current final production candidate at the start of this phase: e0006e75...;
- functional engine remains frozen;
- SchemaForge product accent remains the approved premium mint #63D6AE.

Read first:
- ../BRAND_PRODUCT_IDENTITY_PASS.md
- ../VISUAL_DIRECTION.md
- ../SHARED_SYSTEM.md
- PREMIUM_VISUAL_PASS.md
- REFERENCE_SPEC.md
- REFERENCE_MOCKUP.html
- products/schemaforge/ui/PREMIUM_PASS.md
- products/schemaforge/ui/INSPECTOR_PASS.md

This phase must both:
1. add real Forge Studio / SchemaForge identity;
2. continue correcting remaining visual gaps versus Kern / Untitled / Linear /
   Raycast / Figma instead of declaring the current UI finished.

---

## 1. Current baseline: what is already good

Preserve:
- continuous low-chrome panes;
- compact 46px collection rows;
- section-level add actions;
- quiet narrow mode strip;
- wide rail -> collection -> inspector structure;
- compact inline inspector;
- BuilderSans hierarchy;
- restrained hover/focus/pressed;
- explicit inspection vs Preview;
- nonredundant tooltip behavior;
- stable command area.

Do not regress these while adding brand.

---

## 2. What is still unfinished

The current UI is more professional, but still lacks a strong identity layer.

Specific unfinished areas:

### Forge Studio identity
- product currently reads mainly as "SchemaForge";
- maker identity is not yet intentionally integrated;
- no canonical in-product brand signature has been proven;
- current navigation/icons feel functional but not yet clearly Forge Studio.

### SchemaForge identity
- mint currently functions mostly as selection/CTA color;
- contract/rule/audit/repair vocabulary is not yet a coherent visual motif;
- Rules can still resemble a generic property editor if the title is cropped;
- Audit must feel related to Rules but unmistakably diagnostic;
- Draft/Saved/Stale/Fixable/Diagnostic states need a coherent product language.

### Reference gap
Even after the premium pass, continue checking for:
- too much empty vertical space;
- overly obvious rectangular controls;
- inspector groups that still feel like a form;
- excessive weight on footer buttons;
- insufficiently editorial typography;
- navigation that could be calmer;
- product-specific details that feel bolted on rather than integrated.

---

## 3. First checkpoint — ask before code

Before touching production View code, surface a small batch of meaningful questions.

At least **one question must be open-ended**.

Suggested first batch:

### Open question 1
**When SchemaForge is shown with its title hidden, what should make it instantly
recognizable to you as SchemaForge rather than just another Forge Studio tool?**

Do not answer this on the user's behalf.
After their answer, translate the response into concrete motif/state/component decisions.

### Open question 2
**What should feel like the "signature moment" of SchemaForge: defining the contract,
discovering findings, comparing Expected/Actual, or seeing a safe repair become available?
Why?**

This decides where the strongest product identity belongs.

### Forge Studio signature — mark is already decided
The Forge F is **not an open design choice**. The canonical mark is the exact F already
approved across the five commercial covers.

The remaining implementation question is only:
- where/how strongly should that existing F appear in the plugin;
- how to recover/import the exact approved geometry if the reusable asset is not yet in repo.

Do not propose alternate F shapes, logo redesigns, shields, badges or new monograms.

A text-only "Forge Studio" treatment may be used temporarily if the exact approved F asset
cannot yet be recovered, but the final brand pass should use the approved F where practical.

### Structured question 4 — SchemaForge motif
Potential motifs that remain subtle enough for a professional tool:
A. validation/contract "bracket/grid/check" geometry;
B. rule/finding relationship through tiny aligned markers/rails;
C. almost no decorative motif; identity comes from state language + composition.

Do not decide only from aesthetics. Recommend based on how it supports the real workflow.

### Structured question 5 — state language
Should Draft/Saved/Stale/Fixable be expressed primarily through:
A. tiny dot + text;
B. compact outlined status chip;
C. typography + semantic icon with almost no container?

Recommendation should distinguish document state from diagnostic severity.

The agent may replace these questions with better ones if real code/references reveal
more important ambiguities.

---

## 4. Brand integration target

### Product lockup

Target hierarchy:
- SchemaForge = primary product identity;
- Forge Studio = quiet maker signature;
- current contract = active work/document identity.

Do not put all three at equal typographic weight.

Possible hierarchy:
SchemaForge
Forge Studio · Greenhouse Contract
#PlantPot · Part · Selection

or another composition chosen after the design question.

The brand should survive:
- 320px;
- 560px;
- Light;
- Dark.

Do not consume valuable work area just to show branding.

### Forge Studio signature

Needs one reusable family rule:
- same relative placement logic across products;
- same typography/mark treatment;
- same restraint;
- no product-specific redesign of the F.

If a canonical mark is not available, text is the fallback.
Do not synthesize a random logo in code. Use the approved cover F as the canonical geometry.

---

## 5. SchemaForge product identity

Locked accent: premium mint #63D6AE.

Mint should communicate:
- active contract/rule/finding;
- safe repairability;
- focus;
- product identity.

But repairability must remain semantically distinguishable from generic "selected".

### Identity motif

SchemaForge's real visual idea:
**contract -> rule -> finding -> decision**

Express this through interface structure, not decoration.

Possible manifestations:
- consistent thin rule/finding marker language;
- contract/rule glyph family;
- tiny structural separators that visually connect definition and diagnosis;
- Expected/Actual comparison as a signature component;
- safe-repair state as the strongest mint moment;
- disciplined state marks beside findings/rules.

Avoid:
- big checkmark logos everywhere;
- green wash;
- cyber grid decoration;
- fake schema diagrams;
- code-themed ornaments.

---

## 6. Rules screen: continue converging toward Figma/Raycast

Rules must no longer merely be "good enough".

Review current Rules against:
- Figma property sidebar grouping;
- Raycast settings restraint;
- Untitled/Linear row rhythm.

Improve where real screenshot still shows generic form behavior.

Goals:
- Contract settings row looks like a real object entry;
- Attributes/Children sections feel like compact collections;
- Add actions feel integrated, not floating;
- selected rule uses one precise state language;
- inspector sections are aligned and compact;
- labels are lighter than values;
- default/repair controls do not dominate;
- destructive actions are separated and quiet;
- no giant blank regions.

At 320:
- list state should feel intentional;
- rule inspector should feel like its own compact property view;
- Back behavior must be obvious without becoming a giant button.

---

## 7. Audit screen: make SchemaForge unmistakable

Audit is the most product-specific screen and should carry more of the identity.

Keep:
- findings collection;
- selected detail;
- Expected/Actual;
- Suggested Repair;
- explicit Preview.

Refine:
- findings use a consistent diagnostic marker language;
- categories are recognizable without noisy colored badges;
- Expected/Actual feels like a SchemaForge signature component;
- safe repair is visually special but restrained;
- Diagnostic-only state looks intentional, not like missing UI;
- document state and finding severity do not use the same visual encoding;
- filters resemble a compact tool strip, not a form.

Question to ask after first Audit render:
**Which part feels most "SchemaForge" to you now, and which part still feels generic?**

That is intentionally open-ended.

---

## 8. Library and empty states

Library must inherit Forge Studio restraint:
- compact rows;
- loaded vs selected distinction;
- destructive delete visually separated;
- no giant cards.

Empty states are a key branding opportunity:
- tiny product-specific cue;
- one sentence;
- one action;
- optional Forge Studio signature if it does not become repetitive.

Do not use marketing slogans.

---

## 9. Iconography

Shared Forge family icons:
- navigation;
- add;
- locate/select;
- refresh;
- preview/apply;
- delete.

SchemaForge-specific semantic icons may be introduced for:
- contract;
- attribute rule;
- child rule;
- finding;
- safe repair;
- diagnostic-only.

Rules:
- monochrome line language;
- 14–16px;
- same stroke/optical weight;
- accent only when selected/semantic;
- no emoji;
- no mix of unrelated icon sources.

If high-quality consistent assets are unavailable, prefer simple geometric marks or
text over low-quality icon clutter.

---

## 10. Open-question opportunities during the pass

The agent should actively notice moments where a broader question would improve the result.

Good open prompts include:

- "If you ignore the colors, what part of this screen still looks most like a Roblox plugin to you?"
- "Do you want SchemaForge to feel more like a diagnostic instrument or more like a contract editor?"
- "When there are zero findings, should the UI feel celebratory, neutral, or simply quiet?"
- "What should look more valuable: the rule definition or the repair decision?"
- "Would you rather recognize SchemaForge through its state language, its inspector, or a stronger contract motif?"
- "Which detail in the current screenshot feels cheapest to you?"
- "If we removed all borders, what hierarchy would you still want to survive?"

Do not ask all of these. Use them when the actual rendering makes one useful.

---

## 11. Evidence and iteration rule

Do not launch another full QA campaign.

For each meaningful visual iteration:
- build/compile;
- capture one real 320 state;
- capture one real 560 state when possible;
- compare with current candidate and references;
- ask only the design questions that the rendering exposes.

Do not declare completion from source inspection.

One final functional regression comes only after explicit visual acceptance.

---

## 12. Reproducibility for next products

At the end, update/create a Brand Convergence Inventory.

For every accepted pattern mark:

### FORGE FAMILY
Examples:
- Forge Studio maker-signature placement;
- product lockup hierarchy;
- icon stroke/size;
- state-dot/chip grammar;
- selected row grammar;
- footer hierarchy;
- empty-state shell;
- accent-coverage rule.

### SCHEMAFORGE-SPECIFIC
Examples:
- contract/rule/finding motif;
- Expected/Actual;
- repairable vs diagnostic-only;
- contract status vocabulary.

### DO NOT REUSE
Examples:
- Schema-specific pane proportions;
- rule editor structure;
- finding categories;
- mint semantic mapping.

This inventory becomes input to the next product, but does not replace that product's
own open design questions.

---

## 13. Completion bar

Do not move to PresetForge yet.

SchemaForge becomes the reference only when:
- current premium structure remains intact;
- visual craft is closer again to the real reference apps;
- Forge Studio maker identity is intentionally present;
- SchemaForge is recognizable beyond mint;
- Rules no longer reads like a generic property form;
- Audit feels unmistakably SchemaForge;
- narrow and wide both carry the same brand/product character;
- real screenshots are accepted by the user/assistant.

The target is not "branded Roblox plugin".

The target is:

**a professional Forge Studio tool whose brand, product identity and interface quality
all feel designed together.**
