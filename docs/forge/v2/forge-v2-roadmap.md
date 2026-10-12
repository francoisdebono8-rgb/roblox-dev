# Forge V2 — catalogue upgrade phase

Started: 2026-09-27.

The V1 catalogue is complete. **Do not create Product 6 unless the user explicitly reopens catalogue expansion.**

Canonical V1 products:
- PresetForge — Safe Bulk Editor — asset 73596873703054 — recommended/current target USD 4.99
- JointForge — Joint & Constraint Editor — asset 103958912217728 — recommended/current target USD 7.99
- CurveForge — Cable & Path Builder — asset 90642263224333 — recommended/current target USD 7.99
- AccessForge — Industrial Stairs & Catwalks — canonical asset 127360597946823 — recommended/current target USD 7.99
  - accidental duplicate asset 136358269001448; never distribute/configure it as the canonical product
- SchemaForge — Tagged Object Configuration Audit — asset 84085408748744 — recommended/current target USD 4.99

## Goal

Turn five functional V1s into a coherent, credible Forge Tools catalogue with:
1. better real-project UX;
2. stronger product-specific differentiation;
3. one shared Forge design language;
4. improved Creator Store presentation;
5. a promotion/outreach engine tied to real developer pain;
6. measurable before/after baselines despite limited plugin analytics.

This is not a feature-creep pass. V2 features must be justified by real user pain, competitive gaps or observed workflow friction.

---

## Phase A — freeze and baseline

Before changing product code or listings:

For every canonical product, record:
- asset ID;
- current public title;
- current price;
- current description;
- current icon/media;
- publication/version date;
- current visible reviews/votes/ratings if any;
- current public Creator Store search position for 5–10 relevant keywords;
- exact search query and date;
- any known sales/revenue count available locally/account-side;
- known DevForum/Reddit outreach targets;
- current direct competitors and their visible public state.

Store in:
`docs/forge/v2/catalog-baseline.md`

The purpose is to preserve a V1 point-zero so later V2 changes can be compared against it.

Do not infer impressions/clicks that Roblox does not expose.

---

## Phase B — common Forge design system

Create:
`docs/forge/v2/forge-design-system.md`

Define a shared system for all five plugins:

### Shared
- consistent DockWidget spacing and sizing;
- top-level navigation/tab treatment;
- typography hierarchy;
- button hierarchy: primary / secondary / destructive;
- Preview / Apply / Regenerate / Undo states;
- warning/error/success language;
- empty states;
- inline onboarding;
- keyboard/selection feedback where supported;
- common naming conventions;
- common footer/version/help behavior.

### Product-specific identity
Keep the Forge family, but do not make five clones.

Suggested product accents:
- PresetForge — cyan / configuration / precision
- JointForge — steel blue / mechanics / connection graph
- CurveForge — electric blue or teal / paths / motion
- AccessForge — safety orange / graphite / industrial access
- SchemaForge — mint / validation / audit / structured data

Do not over-brand the functional UI. Product usability wins over decoration.

### Store-media family
Define:
- consistent logo/title placement;
- consistent Forge typography treatment;
- one clear hero promise per product;
- 3 screenshot composition rules;
- no tiny unreadable copy;
- real Studio/environment screenshots, not fake UI;
- each product must look distinct at thumbnail size.

---

## Phase C — product-by-product V2 audit

For each product create:
`plugins/<product>/v2/AUDIT.md`

Audit:
1. V1 real Studio workflow from a new-user perspective;
2. friction / confusing labels / unnecessary steps;
3. current direct competitors;
4. relevant Studio Features + Building Support + plugin-tag discussions;
5. public reviews/complaints if available;
6. features users repeatedly ask for;
7. features to reject;
8. V2 scope.

Use real project scenes, not only synthetic fixtures.

### Priority rule

Do not give every plugin equal engineering time.

Prioritize based on:
- commercial signal;
- breadth/frequency of problem;
- strength of outreach opportunities;
- obvious V1 friction;
- competitive gap;
- visual/marketing demonstrability.

If sales data is still zero/near-zero for all products, prioritize by external demand evidence and quality gap rather than inventing a winner.

---

## Phase D — V2 implementation

For each plugin:

- preserve the canonical Creator Store asset;
- update the existing asset, never create a V2 duplicate;
- improve UX before adding features;
- add only evidence-backed functionality;
- test exact final artifact in real Studio;
- run a novice-style end-to-end workflow;
- run at least one realistic project scenario;
- native Undo/Redo where claimed;
- update docs;
- create new screenshots;
- verify no regression against V1 core workflows.

Every product receives a product-specific version bump, e.g. 2.0.0 when the change is substantial.

---

## Phase E — promotion-first relaunch

For every V2:

1. refresh Creator Store title/description only when it materially improves search/clarity;
2. refresh icon/media;
3. prepare one Community Resources launch/update post;
4. re-check all stored DevForum opportunities;
5. find new current Studio Features / Building Support threads;
6. prepare tailored replies;
7. prepare Reddit posts only where relevant and allowed;
8. record every outreach action/date/link in:
   `docs/forge/v2/marketing-log.md`

Never spam. Disclose that the plugin is ours and paid.

When DevForum posting permissions become available, promotion should become an execution task, not a research task.

---

## Phase F — measurement

Track weekly:
- sales;
- revenue;
- visible reviews;
- visible rating/votes;
- keyword search positions;
- publication/update dates;
- outreach actions;
- notable user replies/feedback.

Store in:
`docs/forge/v2/catalog-tracker.md`

Do not fabricate impression/click metrics.

The main question is not only "did it sell?" but:
- which problem attracts attention;
- which search terms surface the product;
- which outreach channel creates a sale/reply;
- which V2 changes correlate with better visible signals.

---

## V2 exit criteria

The Forge V2 phase is successful when:
- all five canonical assets have a coherent but differentiated presentation;
- every product has passed a realistic-project V2 QA pass;
- major V1 UX friction is removed;
- every V2 scope is evidence-backed;
- all five have updated media/listing where useful;
- promotion assets and targeted outreach are ready or posted;
- the catalogue tracker contains at least one post-V2 observation cycle;
- no Product 6 was created merely to avoid marketing the existing catalogue.
