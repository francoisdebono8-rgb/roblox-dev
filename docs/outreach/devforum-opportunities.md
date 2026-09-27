# Roblox Developer Forum outreach opportunities

Last researched: 2026-09-27.

Status note: the indexed DevForum pages below did not show a "Closed" notice when re-checked on 2026-09-27. Always verify again immediately before posting because topic status can change.

---

## PresetForge

Issue #16 research refresh: **2026-09-27**, completed 16:01 UTC. Version **2.1.0**; price **USD 4.99**; canonical [Creator Store asset 73596873703054](https://create.roblox.com/store/asset/73596873703054). **Drafts only. Native QA and three real screenshots are complete; Studio successfully submitted the canonical update. No posting requested or performed; account posting permissions were not tested.** See the [release gate](../../products/presetforge/v2/RELEASE_GATE.md). Confirm customer availability and the website listing before posting.

For this section, live public Discourse `/t/<id>.json` responses supersede the document's general indexed-page status note. Both primary topics returned `closed: false`, `archived: false`, `visible: true`; their complete two-post discussions were read. Open status does not establish account permission or justify an advertising bump. Recheck topic state, latest replies and usefulness immediately before any separately authorized post.

### Searches and evidence method

DevForum's public search was queried in factory order, followed by current native documentation and public competitor listings:

- Studio Features: `category:24 presets order:latest` and `category:24 attributes copy order:latest`.
- Building Support: `category:56 properties copy order:latest` and `category:56 "properties" "multiple" order:latest`.
- Community Resources: `category:74 "copy properties" order:latest`.
- Plugins tag: `category:74 tags:plugins attributes order:latest`; web search `site:devforum.roblox.com/tag/plugins "preset"` also surfaced relevant `plugin`-tagged resources.
- Direct topic JSON checks for every numbered discussion below; live signed-out Creator Store checks for CopyProps, AttributeSheet and Quick Attribute Copier; author listing check for PresetManager. No competitor was installed or tested. Building Support produced no additional high-confidence reply target. This is a bounded search, not proof that no other tool or native feature exists.

### USE after release gates - Preset Manager request (1164752)

- [Thread](https://devforum.roblox.com/t/preset-manager-for-organizing-and-bulk-applying-properties-attributes-tags-and-collisiongroups-to-instances/1164752) / [live status endpoint](https://devforum.roblox.com/t/1164752.json).
- Category/date/activity: Studio Features, opened **2021-04-13**; latest post **2026-06-17**, an independent request bump; two posts. **OPEN**, not archived, on the live check. No solution or native delivery announcement in those posts.
- Exact need: remember and reuse combinations of properties, attributes, tags and collision groups; organize/find presets; capture configurations from existing instances and locate matches.
- Fit: high for repeatable configuration of **supported classes/fields**, capture, scoped Preview/Apply and name search/duplicate-to-edit. Changes-first results and Locate/Frame help inspect objects requiring a change; they are not a universal whole-place preset matcher.
- Boundaries: the existing whitelist stays. No CollisionGroup editing, arbitrary instance/property support, destructive reset-to-default mode, runtime recipe export, clipboard-to-Lua, recipe stacks or native Properties integration. The request's arbitrary Model and Lighting-service examples are not supported-class promises. Native UI styling already addresses part of its GUI-consistency example.
- Decision: **USE conditionally**, strongest existing-thread target. After exact-artifact native QA, canonical update confirmation and fresh relevance check, one useful reply is defensible because the request was independently revived in 2026. No automatic posting or repeated bump.

Tailored draft, held until customer availability and posting permission are confirmed:

> For repeated configurations, separating the fields to reuse from the objects that need changing makes the batch easier to review. Studio's configurable defaults can handle newly inserted objects; existing objects are the workflow I focused on.
>
> I'm the developer of PresetForge, a paid USD 4.99 plugin. It captures selected supported properties, with optional tags and attributes, as recipes for scoped Preview/Apply. The 2.1.0 update adds a responsive dock, changes-first review, Locate/Frame, recipe-name search and duplicate-to-edit. It passed native Studio acceptance and was submitted to the existing plugin asset.
>
> It keeps a controlled whitelist and does not cover collision groups, arbitrary classes or runtime preset export. [Canonical listing and supported workflow](https://create.roblox.com/store/asset/73596873703054).

### SKIP now / conditional reserve - Bulk copy and paste attributes (3576978)

- [Thread](https://devforum.roblox.com/t/bulk-copy-and-paste-attributes-in-property-window/3576978) / [live status endpoint](https://devforum.roblox.com/t/3576978.json).
- Category/date/activity: Studio Features, opened **2025-03-27**; latest reply **2025-03-29**; two posts. **OPEN**, not archived, on the live check. The follow-up supports the request; it does not report a solution.
- Exact need: select multiple attributes and paste onto one or more instances, with copying into Lua as a bonus.
- Fit: useful partial overlap for repeatedly applying captured attributes to supported targets with before/after review. PresetForge does not provide native Properties clipboard controls, arbitrary per-attribute clipboard selection or Lua export. Do not imply per-property selection means individual attribute-name selection.
- Decision: **SKIP now** because activity is about 18 months old and current simpler alternatives exist. Keep the tailored reserve below only for an independently renewed need that specifically benefits from saved recipes and review. Release success alone must not activate it. Do not revive this thread merely to announce 2.1.0.

Reserve draft for a newly confirmed repeated-configuration need in this still-open, noncompetitor thread:

> For a one-off transfer, [Quick Attribute Copier](https://create.roblox.com/store/asset/120879287668937/Quick-Attribute-Copier) advertises copy/paste and Undo and currently has a Get button; I haven't tested it. If the repeated setup also needs saved configurations and before/after review, that's the use case for PresetForge.
>
> I'm the developer; PresetForge is a paid USD 4.99 plugin. It can capture attributes from a supported source and preview applying them to supported selected or filtered targets. The 2.1.0 update improves the dock, changes-first review and recipe library; native Studio acceptance and the existing-asset Studio submission succeeded. It does not add clipboard controls to Properties or copy attributes into Lua. [Canonical listing](https://create.roblox.com/store/asset/73596873703054).

### SKIP - Further open requests and solved support

| Topic / live status source | Category; date and last activity | Need, fit and decision |
|---|---|---|
| [Support for copying attributes and tags](https://devforum.roblox.com/t/support-for-copying-attributes-and-tags/4642416) / [JSON](https://devforum.roblox.com/t/4642416.json): **OPEN**, not archived; 3 posts | Studio Features; 2026-05-18 to 2026-07-17 | Requests clipboard names or names + values in Properties. Latest reply already recommends Quick Attribute Copier. PresetForge offers a different recipe workflow and no clipboard export. **SKIP**, no useful incremental answer established; no promotional draft. |
| [Allow to duplicate Attributes](https://devforum.roblox.com/t/allow-to-duplicate-attributes/1909565) / [JSON](https://devforum.roblox.com/t/1909565.json): **OPEN**, not archived; 2 posts | Studio Features; 2022-08-05 only | Copy attributes across objects. Existing reply recommends PresetManager and explains that native copy/paste would be simpler. **SKIP**, dormant with an existing workaround. |
| [Highlight tagged/attributed instances in Explorer](https://devforum.roblox.com/t/highlight-instances-with-tags-or-attributes-in-the-explorer/3957685) / [JSON](https://devforum.roblox.com/t/3957685.json): **OPEN**, not archived; 5 posts | Studio Features; 2025-09-25 to 2025-09-29 | Wants persistent hierarchy markers; author explicitly distinguishes these from search/world highlights. **SKIP**, Locate/Frame does not implement that request. |
| [Filter by Attributes in Explorer](https://devforum.roblox.com/t/filter-by-attributes-in-explorer/2828954) / [JSON](https://devforum.roblox.com/t/2828954.json): **OPEN**, not archived; 10 posts | Studio Features; 2024-02-08 to 2025-03-22 | Wants attribute-name/value queries. PresetForge's class/name/tag filters and recipe-name search are different. **SKIP**, no attribute-query claim or promotional draft. |
| [Faster ways to add attributes](https://devforum.roblox.com/t/are-there-any-faster-ways-to-do-add-attributes/3165640) / [JSON](https://devforum.roblox.com/t/3165640.json): **CLOSED**, accepted answer; 17 posts | Platform Usage Support; 2024-09-20 discussion; system closure 2024-10-04 | Wants different attribute values for different units. Author accepted the lookup-table solution. **SKIP**, solved/closed and not a uniform-recipe use case. |

### Current native and competitor counterevidence

These are research sources, not promotion destinations. Listing claims were read, not independently reproduced. Search, duplication, filtering, Preview and Undo must not be described as inventions or unique to PresetForge.

- **Native Properties and configurable defaults:** [current Roblox documentation](https://create.roblox.com/docs/studio/properties) covers property editing, tags, attributes and Save as Default for newly inserted instances, including lights. **Native Explorer:** [documentation](https://create.roblox.com/docs/studio/explorer) covers duplication/paste and name/property/class/tag/ancestry searches. These can be sufficient for simple edits and template reuse. **Native UI styling:** [documentation](https://create.roblox.com/docs/ui/styling) provides selectors, shared style tokens and themes for GUI consistency. Do not claim Studio has no presets, tag management, filtering or reusable UI styling. These docs do not establish a native equivalent of the complete scoped recipe/diff workflow; absence from a page also does not prove a missing feature.
- **PresetManager by boatbomber:** [author listing](https://boatbomber.itch.io/presetmanager) currently shows **USD 1.00 minimum**, 4.8/5 from four ratings, and advertises name search, duplication, properties/attributes/tags/collision groups, matching-instance selection and runtime export. [Original discussion](https://devforum.roblox.com/t/preset-manager-plugin-bulk-apply-properties-attributes-tags-and-collisions/1187701) / [JSON](https://devforum.roblox.com/t/1187701.json): **Creations Feedback**, not Community Resources; opened 2021-04-25, latest 2021-07-10, 18 posts, **OPEN**, not archived. Current compatibility/maintenance is unverified; old activity does not prove abandonment. **SKIP** competitor showcase. Search and duplication are parity features.
- **CopyProps:** [Creator Store](https://create.roblox.com/store/asset/12545467703/CopyProps-Copypaste-instance-properties), live **Get Plugin** button with no USD purchase price, updated **2023-03-27**, zero reviews and insufficient ratings. Advertises copying/pasting/filtering properties. Do not charge the value proposition solely to basic property copying; current compatibility was not tested.
- **AttributeSheet:** [Creator Store](https://create.roblox.com/store/asset/77824934141606), live **Get Plugin**, updated **2026-09-13**, zero reviews and insufficient ratings. Advertises attribute tables, filters, locating, batch edits, pending-change review, stale-change blocking and one Studio Undo. This is a recent alternative, including for review safety; no claim that it lacks Preview/Undo. PresetForge's intended emphasis is reusable combinations of supported properties, tags and attributes, not another attribute spreadsheet.
- **Quick Attribute Copier:** [Creator Store](https://create.roblox.com/store/asset/120879287668937/Quick-Attribute-Copier), live **Get Plugin**, updated **2026-07-17**, two reviews and insufficient ratings. Advertises multiple-source attribute copying and Undo. Already linked in request 4642416; useful counterevidence to promoting a paid recipe manager for a simple transfer. Review contents and runtime behavior were not tested.
- **CopyPasteProperties:** [author's plugin-tagged Community Resources thread](https://devforum.roblox.com/t/i-made-a-copy-and-paste-properties-plugin/3644831) / [JSON](https://devforum.roblox.com/t/3644831.json): opened 2025-05-10, latest 2025-05-11, 9 posts, **OPEN**, not archived. Advertises chosen-property presets and shortcuts. Current price/compatibility unverified. **SKIP** competitor showcase.
- **Attribute Cloner / DKN's editor:** [Community Resources thread](https://devforum.roblox.com/t/plugin-attribute-cloner-dkns-attributes-editor/3253747) / [JSON](https://devforum.roblox.com/t/3253747.json): opened 2024-11-10, latest 2024-12-10, 4 posts, **OPEN**, not archived. Developer's last reply announces multiselect. **Attribute Manager:** [Community Resources thread](https://devforum.roblox.com/t/attribute-manager-plugin-for-all-your-attribute-needs/1562593) / [JSON](https://devforum.roblox.com/t/1562593.json): 2021-11-23, 3 posts, **OPEN**, not archived; discussion explicitly questions value beyond native editing. **SKIP** both competitor threads; current prices/compatibility unverified.

### USE after release gates - Community Resources update draft

[PresetForge 2.1.0 update draft](presetforge-v2-update.md) contains the paid-developer disclosure, USD 4.99 price, canonical link, three use cases, three actual Studio screenshot paths, limitations and feedback request. Posting remains conditional on customer availability and explicit authorization. Prefer updating our own existing product topic if one exists; no own-topic URL or posting permission was verified here. No post URLs exist from this task.

---

## JointForge

### HIGH — Adding Joint Types to tools

- URL: https://devforum.roblox.com/t/adding-joint-types-to-tools/4352889
- Category: Engine Features / Feature Request
- Date/activity: February-March 2026
- Need: easier Weld/Motor6D workflows for tools and animated assemblies.
- Fit: high for Studio-side assembly, but JointForge does NOT replace the requested engine/runtime Tool behavior.
- Use: YES, with that limitation stated explicitly.

Draft reply:

> This wouldn't replace the engine-level Tool.JointType behavior you're requesting, but I built a Studio-side tool for the assembly part of this problem. Disclosure: I'm the developer and it's paid.
>
> JointForge lets you choose a root, batch-connect static parts with WeldConstraints and moving parts with Motor6Ds, preview the connections before applying them, inspect existing/broken joints, and undo the whole operation natively.
>
> If the painful part for you is setting up the assembly in Studio, it may help: [CREATOR_STORE_LINK]

### SKIP — competitor showcase/support threads

Do not advertise JointForge in:
- "Welds and Motors" plugin showcase
- qPerfectionWeld / Bind / other plugin resource threads

These are useful competitor/review sources, not outreach targets.

---

## CurveForge

### HIGH — Studio Feature or Plugin that repeats a pattern on scaling or resizing

- URL: https://devforum.roblox.com/t/studio-feature-or-plugin-that-repeats-a-pattern-on-scaling-or-resizing/4095587
- Category: Building Support
- Date: November 2025
- Need: stop manually duplicating the same model repeatedly; repeat geometry/patterns, including around curves.
- Fit: very high for CurveForge Repeat Model mode.
- Use: YES.

Draft reply:

> If you're still looking for this kind of workflow, I built something specifically around it. Disclosure: it's my paid plugin.
>
> CurveForge can repeat your own Part or Model along an editable 3D path. You can set spacing or copy count, optionally align the copies to the path, Preview it first, then reopen the generated path later and Regenerate after moving the control points.
>
> So it's closer to "repeat this model along a path" than stretching the source object.
>
> [CREATOR_STORE_LINK]

### MEDIUM — How do I make a 90 degree smooth curve at an upward angle?

- URL: https://devforum.roblox.com/t/how-do-i-make-a-90-degree-smooth-curve-at-an-upward-angle/3518614
- Category: Building Support
- Date: March 2025
- Need: create a smooth upward curved railing in Studio without getting good results from common tools.
- Fit: partial. CurveForge can make a smooth cable/pipe-like curved element and repeat models along a 3D curve, but it is not a general-purpose mesh/CAD railing modeller.
- Use: ONLY if a genuine CurveForge demo reproduces something close to the requested shape. Otherwise skip.

Possible reply if validated:

> I ran into a similar "3D curve inside Studio" problem and built CurveForge. Disclosure: it's my paid plugin.
>
> It can create cable/pipe-style geometry along a multi-point 3D path, or repeat your own model along that path, and the result stays editable/regeneratable. It isn't a full CAD/mesh modeller, but for a railing made from repeated pieces or a simple rail profile it may fit.
>
> [CREATOR_STORE_LINK]

---

## AccessForge

Rechecked 2026-09-27 after issue #14 native and GUI gates passed. Studio created plugin asset **127360597946823**. Distribution and price are not enabled/verified by this task. [Actual asset link](https://create.roblox.com/store/asset/127360597946823).

No forum post was requested by issue #14, attempted or claimed. Account posting permissions were not tested. Preparing copy does not authorize posting it. This focused search found **no high-confidence existing-thread reply target** worth reviving just to promote the plugin.

### Searches performed

- `site:devforum.roblox.com "Studio Features" stairs railing`
- `site:devforum.roblox.com "Building Support" industrial stairs catwalk`
- `site:devforum.roblox.com "Community Resources" "stairs" plugin`
- `site:devforum.roblox.com/tag/plugins stairs catwalk`
- `site:devforum.roblox.com "stairs" "Studio Features" generator`

Direct title/URL lookups checked the two earlier candidates. The plugins tag and some direct topic pages returned an empty/challenge page, so indexed posts were used for content. **Current open/closed status is NOT VERIFIED for the targets below**, overriding the general status note at the top of this document. Index dates are not a live status check. Recheck latest replies and permissions before any future posting.

### SKIP now - Building stairs in Roblox

- [Thread](https://devforum.roblox.com/t/building-stairs-in-roblox/2471185), Building Support, July 16, 2023; indexed replies from the same day, no fresh activity established.
- Need: evenly aligning stair treads with the side structure. AccessForge's calculated straight stairs/rails partially fit, but it does not generate arbitrary solid side walls.
- Decision: SKIP. The existing replies already give a practical construction technique; no reason to revive the old thread with an advertisement.

Conditional tailored draft, only if the author independently reopens the need:

> Equalizing the rise first helps keep every tread at the same offset along a sloped rail. For a one-off staircase, the construction approach already shared here may be enough. Disclosure: I'm the developer of AccessForge, a paid plugin intended for repeated industrial builds. It calculates straight or switchback stairs with rails and editable regeneration, but it doesn't reproduce arbitrary solid side walls. [Details](https://create.roblox.com/store/asset/127360597946823).

### SKIP - Smooth upward 90-degree railing

- [Thread](https://devforum.roblox.com/t/how-do-i-make-a-90-degree-smooth-curve-at-an-upward-angle/3518614), Building Support, March 1, 2025; the indexed reply recommends Blender. Newer activity not established.
- Need: smooth upward curved geometry. AccessForge only builds straight/sloped rails around its supported assemblies, not continuous curved rails.
- Decision: SKIP, product mismatch. No promotional reply drafted.

### SKIP - Real measurement units

- [Thread](https://devforum.roblox.com/t/allow-developers-to-change-from-studs-to-real-units-for-measurement/425154), Studio Features, January 4-6, 2020 in the indexed discussion.
- Need: real-unit display/import scaling across Studio, with stairs as one example. AccessForge uses studs and does not implement this request.
- Decision: SKIP, product mismatch. No promotional reply drafted.

### SKIP - Competitor showcases

- [Quick Stairs](https://devforum.roblox.com/t/quick-stairs-quickly-create-stairs/1276810), Community Resources, June 7, 2021; indexed activity April 2, 2023. Relevant demand evidence for faster stair creation, not a place to advertise ours.
- [Click And Build](https://devforum.roblox.com/t/click-and-build-easily-create-walls-paths-and-more/3633000?page=4), Community Resources, building/plugin tags; indexed December 26, 2025 update adds calculated stairs. Relevant competitor, not an outreach target.
- Decision: SKIP both, regardless of whether replies are open. No promotional replies drafted.

### USE - Dedicated Community Resources announcement draft

Destination: [Community Resources](https://devforum.roblox.com/c/resources/community-resources/74), appropriate plugin tag when posting permissions allow. New topic; no open/closed state applies yet. **Draft only**, not posted. Before posting, verify the asset is available, confirm the final price, upload the three actual PNGs as forum attachments and request explicit posting authority.

Title: **AccessForge - Editable Industrial Stairs & Catwalks**

I'm the developer of AccessForge, a paid Roblox Studio plugin for building and revising industrial access assemblies. The intended price is USD 7.99; check the listing for the final price and availability.

Manually duplicating steps is manageable once. Reworking the stairs, landing and rails after a floor-height change is the workflow this tool aims to shorten.

Place Start and End markers, choose dimensions, inspect the read-only Preview, then Build. Later, select the assembly and use Edit Existing to change dimensions or move its original markers, preview and Regenerate. Build and Regenerate support native Studio Undo/Redo.

Three examples from a real MIT-licensed utility-facility scene:

- **Factory stair:** calculated straight treads, top landing and guardrails. Attach `products/accessforge/release/screenshots/01-factory-stair.png`.
- **Switchback access:** two return flights with a middle landing and left/right direction. Attach `products/accessforge/release/screenshots/02-switchback-access.png`.
- **Catwalk system:** a level elevated deck, guardrails and support posts down to a chosen baseline. Attach `products/accessforge/release/screenshots/03-catwalk-system.png`.

The output is Roblox-native Parts with transparent, non-executable edit metadata. The plugin uses no HTTP, telemetry or external services. Keep the control markers and metadata to regenerate later.

V1 is deliberately limited: no curved/spiral stairs, terrain fitting, collision checking, automatic welding or certified building-code compliance. Limits are 1,000 generated Parts and 256 steps per assembly. Test the result with your game's character/controller; this is visual construction geometry, not a navigation guarantee.

[AccessForge on Creator Store](https://create.roblox.com/store/asset/127360597946823)

I'd appreciate feedback from factory, warehouse and utility-map builders: which part of revising an access assembly still costs you the most manual work?

---

## SchemaForge - 2026-09-27

Canonical [Creator Store asset](https://create.roblox.com/store/asset/84085408748744), suggested USD 4.99. Drafts only; no posting requested in this factory run. Check final availability and price before using them.

Searches: Studio Features `attribute descriptions`, `attribute min max validation`, `query missing children`; Building Support `attributes tags`, `missing configuration`, `configure tag`; Community Resources/plugins `attribute manager`, `schema validator`; live Creator Store `schema`, `attribute`, `validator`. Building Support did not yield a strong matching case; no invented outreach target was added.

### USE - Attribute documentation for designer handoff

- [Custom descriptions for attributes](https://devforum.roblox.com/t/custom-descriptions-for-attributes-in-the-properties-panel/4664872), Studio Features, June 2-3, 2026, 13 posts. Live check Sep 27: Reply button present, no closed notice; posting permissions not tested (read-only signed-out browser).
- Need: designers and solo developers lose attribute meanings and associated tags. Fit: project-saved descriptions beside explicit rules. It does not add native Properties hover descriptions or synchronize notes with scripts.
- Draft: For handoff, a per-tag contract can keep the field meaning, expected type and allowed values together in the place. It still needs maintenance when code changes. I'm the developer of SchemaForge, a paid plugin that provides that separate panel and checks tagged objects against the saved rules. It does not add tooltips to native Properties or read your scripts. [Workflow and limitations](https://create.roblox.com/store/asset/84085408748744).

### USE - Repeated models with missing children

- [Query language and Explorer parity](https://devforum.roblox.com/t/parity-between-the-query-language-and-explorer-more-syntax/4893794), Studio Features, Sep 25-26, 2026, two posts. Live Sep 27: Reply button present, no closed notice.
- Need: combine checks to find invalid repeated rail models. Fit is partial and explicit: tag/class/required-child checks and attribute constraints; NOT Size/Vector3 property comparisons. Native queries remain preferable for those.
- Draft: A reusable required-child contract can cover the missing-hierarchy part without tagging intermediate query results each time. For the Size checks, your native query/script approach is still needed. I'm the developer of SchemaForge, a paid plugin for saved tag, attribute and child-path rules with selectable findings. It doesn't validate Vector3 properties or replace the broader query improvements requested here. [Details](https://create.roblox.com/store/asset/84085408748744).

### SKIP - Old attribute UX request

- [Studio-specific attribute features](https://devforum.roblox.com/t/a-number-of-studio-specific-attribute-features-to-improve-ux/1334456), Studio Features, July 2021; latest visible follow-up April 2024. Live Sep 27: Reply button present, no closed notice.
- Numeric constraints and string choices match our audit rules, but the request also concerns native editing/enforcement. Do not revive a dormant discussion just to advertise. Retain as research, no promotional reply.

### SKIP - Solved bulk editing and competitor showcases

- [Faster ways to add attributes](https://devforum.roblox.com/t/are-there-any-faster-ways-to-do-add-attributes/3165640), Platform Usage, September 2024, solved/closed October 2024 in research. Bulk editing is not our differentiation; no reply.
- [Attribute Manager](https://devforum.roblox.com/t/attribute-manager-plugin-for-all-your-attribute-needs/1562593), Community Resources, 2021; [Attribute Cloner](https://devforum.roblox.com/t/plugin-attribute-cloner-dkns-attributes-editor/3253747), Community Resources/plugins, 2024. Competitor showcases: SKIP regardless of open state. No advertising drafts for them.

Community Resources announcement: [schemaforge-launch.md](schemaforge-launch.md). Include the three real images, not UI mockups. Recheck topic activity before any reply and post only with separate user authority.

## Posting workflow

When the user's DevForum account gains reply permission:

1. Open the thread and verify it is still open.
2. Read the latest replies so the draft is not outdated.
3. Confirm the plugin still solves the problem exactly as described.
4. Replace `[CREATOR_STORE_LINK]` with the real public listing.
5. Shorten/customize the draft to match the conversation.
6. Clearly disclose "I'm the developer" and "paid plugin" where applicable.
7. Post once; do not bump repeatedly.
8. Record the post date/link here so the same thread is not targeted again.
