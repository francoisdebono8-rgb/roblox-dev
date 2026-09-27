# Forge catalogue baseline

Observed 2026-09-27, Europe/Paris. Issue #15, first execution block only.
Source checkout: `04d354b`. Catalogue frozen at five canonical products. No Product 6,
product-code change, upload, price change or outreach post was made in this audit.

## Canonical public state

Read the actual Creator Store pages, signed out, French locale, displayed USD prices.
Dates below are public Created / Updated dates, not inferred release timestamps.
Versions are the local commercial releases; the public page does not expose their
semantic version and the remote binary was not downloaded for comparison.

| Product / exact public title | Canonical asset | Price USD | Local version | Created / updated |
|---|---|---:|---|---|
| PresetForge - Safe Bulk Editor | [73596873703054](https://create.roblox.com/store/asset/73596873703054) | 4.99 | 2.0.0 | 2026-09-26 / 2026-09-26 |
| JointForge - Joint & Constraint Editor | [103958912217728](https://create.roblox.com/store/asset/103958912217728) | 7.99 | 1.0.0 | 2026-09-27 / 2026-09-27 |
| CurveForge - Cable & Path Builder | [90642263224333](https://create.roblox.com/store/asset/90642263224333) | 7.99 | 1.0.0 | 2026-09-27 / 2026-09-27 |
| AccessForge - Industrial Stairs & Catwalks | [127360597946823](https://create.roblox.com/store/asset/127360597946823) | 7.99 | 1.0.0 | 2026-09-27 / 2026-09-27 |
| SchemaForge - Tagged Object Configuration Audit | [84085408748744](https://create.roblox.com/store/asset/84085408748744) | **7.99** | 1.0.0 | 2026-09-27 / 2026-09-27 |

SchemaForge's actual public price differs from the roadmap's 4.99 recommendation.
It was also 7.99 in the authenticated configuration page; no correction was made.
AccessForge asset `136358269001448` is the known duplicate, never the update target.
"Catalogue V1" does not mean every package is version 1: PresetForge is already 2.0.0.

All five public pages showed **0 reviews** and **insufficient ratings**, with no
numeric vote count displayed. This does not establish zero purchases or zero votes.

## Descriptions at baseline

Exact public copy below, with whitespace normalized. Owned product copy, not a new listing.

### PresetForge

Bulk-edit exactly what you want, exactly where you want. Create reusable recipes for properties, tags and attributes, target selections or filtered descendants, preview every change before applying, and undo the entire operation in one step. Supports BaseParts, lights, sounds, particles, decals, textures, common UI objects and ProximityPrompts. No analytics, telemetry or network requests.

### JointForge

Create, inspect and batch-build Roblox joints and constraints from one focused Studio panel. Build multi-part tools and mechanical assemblies by choosing a root, assigning Static parts to WeldConstraint and Moving parts to Motor6D, then preview every operation before applying. Inspect existing connections, locate endpoints, detect missing endpoints and edit key properties. Supports WeldConstraint, Weld, Motor6D, HingeConstraint, BallSocketConstraint, RopeConstraint, RodConstraint, SpringConstraint and NoCollisionConstraint. Existing connections are preserved by default, conflicts block Apply, and every Apply supports native Studio Undo/Redo. No HTTP requests, analytics, telemetry or external services.

### CurveForge

Build smooth cables, pipes and repeated models along custom paths directly in Roblox Studio. Create a path with 2-8 control points, preview the result, then generate clean geometry along the curve. Cable & Pipe mode lets you create cables, pipes and hoses with control over thickness, material, color, collision and anchoring. Repeat Model mode distributes your own Part or Model along a curved path with adjustable spacing or copy count and optional tangent alignment. Generated CurveForge creations can be reopened, edited and regenerated later. Features: Editable multi-point paths; Live Preview; Cable & pipe generation; Repeat Parts/Models along curves; Edit Existing & Regenerate; Native Studio Undo/Redo; Source objects preserved; No HTTP, telemetry, analytics or external services. Useful for cables, pipes, hoses, fences, rails, lamp posts, decorations, obbies and environment building.

### AccessForge

Build editable industrial stairs, landings and catwalks directly in Roblox Studio. Choose your start and end elevations, preview the calculated structure, then generate clean Roblox-native geometry without manually duplicating and aligning every step. AccessForge can calculate straight stairs, build switchback stairs with landings, add guardrails, create elevated catwalks and place simple supports. Reopen generated assemblies later, change dimensions or rail settings, then regenerate safely. Features: Automatic step/rise calculation; Straight & switchback stairs; Editable landings; Catwalk/platform builder; Left/right guardrails; Optional support posts; Read-only Preview; Edit Existing & Regenerate; Native Studio Undo/Redo; No HTTP, telemetry or external services. Built for factories, warehouses, industrial maps, docks, utility areas and sci-fi facilities.

### SchemaForge

Catch misconfigured tagged objects before playtesting. SchemaForge saves explicit configuration rules in your project: required attributes, number ranges, integer values, allowed strings, designer notes and required child paths with expected classes. Capture a reference, refine the rules, then audit selected roots and descendants or the Workspace. Select affected objects directly from the findings. Preview optional repairs before applying them. Only missing required attributes with enabled defaults are added. Existing values, wrong types and children are never overwritten. Native Studio Undo/Redo supports repairs and schema storage changes. V1 supports number, string and boolean attributes. Edit mode only; no runtime enforcement or automatic hierarchy repair. No HTTP, analytics or external services. Best for teams reusing configured gameplay objects.

CurveForge/AccessForge list bullets and the 2-8 range above are normalized to ASCII;
wording is preserved. No claims in this copy were newly certified by this UX audit.

## Media inventory

Every public page rendered a product icon, preview image and `+3` gallery badge.
Opening the public gallery prompted sign-in; full-size public media were not audited.
SchemaForge's authenticated configuration showed three media entries and distribution
enabled. That confirms count, not a pixel-for-pixel match with local PNGs.

| Product | Tracked local media | Important provenance/state |
|---|---|---|
| PresetForge | `products/presetforge/release/media/{01-exact-fields,02-filter-preview,03-safe-apply}.png` | Original demo captures. DodgeballArena replacement plan still says pending. |
| JointForge | `products/jointforge/release/screenshots/{01-batch-tool,02-inspect-graph,03-one-step-undo}.png` | Original gray-scene captures. TheDepths replacement plan still says pending. |
| CurveForge | `products/curveforge/release/screenshots/{01-village-cable,02-village-pipe,03-village-repeat}.png` | Real RavenRock captures, MIT provenance. |
| AccessForge | `products/accessforge/release/screenshots/{01-factory-stair,02-switchback-access,03-catwalk-system}.png` | Real adapted hacker-tycoon facility, MIT provenance. |
| SchemaForge | `products/schemaforge/release/media/{01-explicit-project-contract,02-audit-tagged-objects,03-preview-missing-defaults}.png` | Real adapted Roblox Plant models, MIT provenance. |

Do not silently relabel the old PresetForge/JointForge PNGs as the issue #12 real-project
captures. Today's audit is not a replacement commercial shoot. Public icon files were
visible, but no verified mapping to tracked local icon originals was established.

## Search point-zero: 25 live queries

Same date and browser session; Creator Store > Plugins, default ordering, no price
filter, signed out. Search entered through the visible search box. Ranks are one-based
`pagePosition + 1`, deduplicated by asset ID. **Not seen/N** means absent from the N
rendered results inspected, not absent from the entire Store or a claim of rank N+1.
Search is dynamic; this is a reproducible observation, not an impression metric.

| Product | Exact query | Displayed total | Inspected | Canonical rank |
|---|---|---:|---:|---|
| PresetForge | [preset](https://create.roblox.com/store/category/plugins?keyword=preset) | 53 | 39 | Not seen/39 |
| PresetForge | [bulk editor](https://create.roblox.com/store/category/plugins?keyword=bulk+editor) | 3 | 3 | 3 |
| PresetForge | [copy properties](https://create.roblox.com/store/category/plugins?keyword=copy+properties) | 4 | 4 | Not seen/4 |
| PresetForge | [attributes](https://create.roblox.com/store/category/plugins?keyword=attributes) | 48 | 40 | Not seen/40 |
| PresetForge | [PresetForge](https://create.roblox.com/store/category/plugins?keyword=PresetForge) | 1 | 1 | 1 |
| JointForge | [joint](https://create.roblox.com/store/category/plugins?keyword=joint) | 30 | 30 | 15 |
| JointForge | [weld](https://create.roblox.com/store/category/plugins?keyword=weld) | 474 | 40 | Not seen/40 |
| JointForge | [constraint](https://create.roblox.com/store/category/plugins?keyword=constraint) | 35 | 35 | 29 |
| JointForge | [Motor6D](https://create.roblox.com/store/category/plugins?keyword=Motor6D) | 53 | 40 | Not seen/40 |
| JointForge | [JointForge](https://create.roblox.com/store/category/plugins?keyword=JointForge) | 1 | 1 | 1 |
| CurveForge | [cable](https://create.roblox.com/store/category/plugins?keyword=cable) | 3 | 3 | 2 |
| CurveForge | [pipe](https://create.roblox.com/store/category/plugins?keyword=pipe) | 17 | 17 | Not seen/17 |
| CurveForge | [curve](https://create.roblox.com/store/category/plugins?keyword=curve) | 39 | 30 | Not seen/30 |
| CurveForge | [repeat model](https://create.roblox.com/store/category/plugins?keyword=repeat+model) | 0 | 0 | No results |
| CurveForge | [CurveForge](https://create.roblox.com/store/category/plugins?keyword=CurveForge) | 1 | 1 | 1 |
| AccessForge | [stairs](https://create.roblox.com/store/category/plugins?keyword=stairs) | 14 | 14 | 13 |
| AccessForge | [catwalk](https://create.roblox.com/store/category/plugins?keyword=catwalk) | 2 | 2 | 1 |
| AccessForge | [railing](https://create.roblox.com/store/category/plugins?keyword=railing) | 0 | 0 | No results |
| AccessForge | [switchback](https://create.roblox.com/store/category/plugins?keyword=switchback) | 0 | 0 | No results |
| AccessForge | [AccessForge](https://create.roblox.com/store/category/plugins?keyword=AccessForge) | 1 | 1 | 1 |
| SchemaForge | [schema](https://create.roblox.com/store/category/plugins?keyword=schema) | 2 | 2 | 2 |
| SchemaForge | [attribute](https://create.roblox.com/store/category/plugins?keyword=attribute) | 52 | 30 | Not seen/30 |
| SchemaForge | [validator](https://create.roblox.com/store/category/plugins?keyword=validator) | 4 | 4 | Not seen/4 |
| SchemaForge | [audit](https://create.roblox.com/store/category/plugins?keyword=audit) | 24 | 24 | 24 |
| SchemaForge | [SchemaForge](https://create.roblox.com/store/category/plugins?keyword=SchemaForge) | 1 | 1 | 1 |

Zero query results do not establish demand or an unoccupied business opportunity.
Brand rank 1 with one result is not meaningful acquisition evidence.

## Competitors checked live

Read-only listing comparison, not installation or functional certification. "Get"
means the page offered Get Plugin rather than a USD purchase button; where the search
card said Free, that was consistent. Last update alone does not prove maintenance quality.

| Product | Competitor / public state | Consequence |
|---|---|---|
| PresetForge | [CopyProps](https://create.roblox.com/store/asset/12545467703): Get, updated 2023-03-27, 0 reviews, insufficient ratings | Copy/filter properties alone is not a paid differentiator. |
| PresetForge | [Preset Manager](https://devforum.roblox.com/t/preset-manager-plugin-bulk-apply-properties-attributes-tags-and-collisions/1187701): original author advertises search, duplication, tags, attributes, collision groups and matching objects; external paid link | Significant overlap. Current external price and maintenance unverified. |
| JointForge | [Joint Editor](https://create.roblox.com/store/asset/134658752694624): Get, updated 2026-02-28, 50%, 10+ votes, 8 reviews | Already creates Motor6Ds/welds and edits pivots/connected offsets. |
| CurveForge | [Pipe Placer](https://create.roblox.com/store/asset/5027226818): Get, updated 2022-10-08, 96%, 100+ votes, 14 reviews | Direct pipe placement and angle snapping already exist. |
| CurveForge | [CDS Cabler](https://create.roblox.com/store/asset/378960861): Get, updated 2016-03-07, 0 reviews, insufficient ratings | Cable creation alone is not novel; listing is too sparse for detailed feature claims. |
| AccessForge | [Quick Stairs](https://create.roblox.com/store/asset/6917372104): Get, updated 2026-01-04, 90%, 400+ votes, 22 reviews | Current strong free alternative for ordinary stairs; advertises free Redupe too. |
| AccessForge | [Stairs Creator](https://create.roblox.com/store/asset/110359758215433): Get, updated 2025-07-15, 18%, 10+ votes, 2 reviews | Already advertises endpoints, rails and live 3D preview. One Feb 2026 review reports endpoint-turning difficulty; not an independently reproduced competitor bug. |
| SchemaForge | [Attribute QA](https://create.roblox.com/store/asset/87556490782458): 4.99 USD, updated 2026-08-29, 0 reviews, insufficient ratings | Reference/inferred-schema audit and select findings already sold; saved explicit contracts and child requirements must carry SchemaForge. |
| SchemaForge | [AttributeSheet](https://create.roblox.com/store/asset/77824934141606): Get, updated 2026-09-13, 0 reviews, insufficient ratings | Table comparison, filters, batch edits, Preview and Undo already offered. Do not build another attribute spreadsheet. |

Additional live-search incumbents: [Constraint Editor](https://create.roblox.com/store/asset/804263305),
[Motor6D Welder](https://create.roblox.com/store/asset/2117731664),
[Bezier Curve Editor](https://create.roblox.com/store/asset/18696218289).
These were observed as search results, not fully audited listings.

## Account-visible commercial signal

Read-only Creator Hub > Finances > Transactions > Creator Store > Incoming payments,
2026-09-27 around 17:20 Europe/Paris. Price filter All; date fields blank.
Displayed: **No results**, total completed payouts **EUR 0.00**, pending revenue
**EUR 0.00**, available balance **EUR 0.00**. No export or payment action taken.

This is an empty account-level transaction view at observation time, not a verified
lifetime sales count for each asset. Per-product purchases, impressions, clicks,
conversion, refunds and acquisition attribution: **unavailable**. Publication is
less than two days old; there is no commercial winner to infer from this baseline.
No credentials, customer records or account screenshot are committed.

## Stored outreach and next comparison

Existing drafts: [DevForum opportunities](../outreach/devforum-opportunities.md),
[SchemaForge launch](../outreach/schemaforge-launch.md). No posting in this task.

| Product | Stored target / qualification |
|---|---|
| PresetForge | Preset manager request `1164752`, revived June 2026; bulk-copy attributes `3576978`. Recheck latest activity before replying. |
| JointForge | Tool joint types `4352889` only partially fits: runtime grip is outside our scope. Old welding threads are research, not automatic ad targets. |
| CurveForge | Repeated pattern `4095587`; upward railing `3518614` conditional on a real reproduction. Existing free recommendations must be disclosed. |
| AccessForge | No strong fresh reply target established. Old solved stair threads and measurement requests are not an excuse to advertise. Community Resources draft exists. |
| SchemaForge | Attribute descriptions `4664872`; query parity `4893794` only partial fit. Old constraints request and solved bulk-copy threads should not be revived for promotion. |

Next measurement should repeat the same 25 queries, locale and bounded rank method,
record public updates/reviews and the same transaction view, then compare after a
single product change. Do not attribute an observed difference causally without evidence.
Implementation decision: [implementation-order.md](implementation-order.md).
