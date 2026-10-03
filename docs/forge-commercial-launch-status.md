# Forge Studio / commercial launch preparation

Date: **2026-10-03**. Master **#36**, product packs **#37-#41**, Playground **#42**.
Frozen product baseline: commit `ee76d2fbb8061d6b00ca4a74bd19f479002de30a`.

**Preparation delivered; public launch is not complete. Nothing was published or
updated on Roblox.** No price, distribution, identity, seller or account setting
was changed. A separate explicit go-ahead is required for every release operation.
Plugin code, frozen binaries and Playground runtime were not changed by this pass.

## Catalogue handoff
Each linked pack contains STORE_LISTING, MEDIA_PLAN, VIDEO_PLAN and LAUNCH_CHECKLIST.
The five prices below are researched hypotheses, not user approval or observed sales.

| Issue / pack | Positioning | Recommended USD | Binary | Media | Status |
| --- | --- | --- | --- | --- | --- |
| #37 [SchemaForge](../products/schemaforge/commercial/forge-0.2.5/STORE_LISTING.md) | Audit repeated objects; Expected/Actual; reviewed missing-only repairs | 4.99 | PASS | 5 shots + 28s video specified, final exports pending | **READY EXCEPT MEDIA** |
| #38 [PresetForge](../products/presetforge/commercial/forge-0.2.5/STORE_LISTING.md) | Exact affected subset; Before/After; Apply N | 4.99 | PASS | LightingWorkshop 5 shots + 28s video specified, exports pending | **READY EXCEPT MEDIA** |
| #39 [CurveForge](../products/curveforge/commercial/forge-0.2.5/STORE_LISTING.md) | Custom Repeat first; editable path and contextual regeneration | 4.99 | PASS | Repeat/Cable 5 shots + 28s video specified, exports pending | **READY EXCEPT MEDIA** |
| #40 [AccessForge](../products/accessforge/commercial/forge-0.2.5/STORE_LISTING.md) | Complete Start/End access assembly, not just treads | 4.99 | PASS | Platforms/assembly 5 shots + 29s video specified, exports pending | **READY EXCEPT MEDIA** |
| #41 [JointForge](../products/jointforge/commercial/forge-0.2.5/STORE_LISTING.md) | Scan, locate issue, explicit repair, rescan | 4.99 | PASS | BrokenConnection 5 shots + 28s video specified, exports pending | **READY EXCEPT MEDIA** |
| #42 [Forge Playground](../experiences/forge-playground/PUBLIC_READINESS.md) | Hands-on runtime samples, not plugin ownership | Free demo proposed | Functional V1 retained | Public-world art, actual media and network/device acceptance pending | **NOT READY** |

`READY EXCEPT MEDIA` means binary and copy preparation are ready, not permission to
publish. Final icon/cover exports, galleries and footage remain open. No product is
declared `READY TO PUBLISH`. #36 remains open; product/media follow-up is not silently
handed to the user as if only website clicks remained.

## Exact upload candidates
Reference the existing frozen files; no second copy with an ambiguous version name.
All live asset updates must target these canonical IDs, never create new listings.

| Product | Internal version / catalogue | Canonical asset | Candidate |
| --- | --- | --- | --- |
| SchemaForge | 1.2.0 / 0.2.5 | `84085408748744` | [RBXM](../products/schemaforge/ui/forge-0.2.5/SchemaForge-ForgeStudio-0.2.5.rbxm) |
| PresetForge | 2.2.0 / 0.2.5 | `73596873703054` | [RBXM](../products/presetforge/ui/forge-0.2.5/PresetForge-ForgeStudio-0.2.5.rbxm) |
| CurveForge | 1.1.0 / 0.2.5 | `90642263224333` | [RBXM](../products/curveforge/ui/forge-0.2.5/CurveForge-ForgeStudio-0.2.5.rbxm) |
| AccessForge | 1.1.0 / 0.2.5 | `127360597946823` | [RBXM](../products/accessforge/ui/forge-0.2.5/AccessForge-ForgeStudio-0.2.5.rbxm) |
| JointForge | 1.1.0 / 0.2.5 | `103958912217728` | [RBXM](../products/jointforge/ui/forge-0.2.5/JointForge-ForgeStudio-0.2.5.rbxm) |

```text
SchemaForge  1e86dd4e581bdffbae2a55635b95ab41bfa4d41359826935c74ef59bbf9575fe
PresetForge  a9726d442d8376a658cdb042da2212cced695ab2b7e6a96c4b8a08e71d881a63
CurveForge   510b7dc3af0dfed72bdc97f7ebe83ce2bdacfc960ffac38dd9ab9735e78cdc7d
AccessForge  839798041fdc1884df19e8cabccf7e1f698c0087d6f1e3bc8c9ec5bd25b1089d
JointForge   e74b3f4d94de155faa634a0986dcea30efee105a1c009b8db7c9a324e36a2216
```

Do not use old `dist/`, `publish/`, fixture `.rbxl` or QA runner files merely because
their titles look like a release. AccessForge's historical duplicate must not be
touched; the canonical ID above is authoritative.

## Research and pricing decision
Public Creator Store pages were inspected live, signed out, on 2026-10-03. No
competitor purchase/install, rating inference or performance comparison was made.

| Observed substitute | Price / recency | Consequence for this launch |
| --- | --- | --- |
| [Attribute QA](https://create.roblox.com/store/asset/87556490782458/Attribute-QA-Find-Missing-Wrong-Types) | 4.99 USD, Aug 29, 2026 | Schema must show saved explicit contracts and bounded repair, not just missing-field detection. |
| [AttributeSheet](https://create.roblox.com/store/asset/77824934141606/AttributeSheet-Attribute-Table-Batch-Editor) | 4.99 USD, Sep 29, 2026 | Old free-price observation is stale. Review/Undo/stale protection are not exclusive to Forge. |
| [Copy&PasteProperties](https://create.roblox.com/store/asset/132373628730536/CopyPasteProperties) | Free acquisition, Jun 19, 2025 | Preset's paid story is exact subset + diff review, not copying selected fields or saved presets alone. |
| [RopeTool](https://create.roblox.com/store/asset/109225618409920/Stravant-RopeTool) | Free acquisition, Aug 3, 2026 | Cable-only marketing is weak; lead Curve with custom Repeat and regeneration. |
| [Redupe](https://create.roblox.com/store/asset/73064993918325/Stravant-Redupe-REpeated-DUPElicate) | Free acquisition, Feb 2, 2026 | Generic arrays also are not a moat. |
| [Quick Stairs](https://create.roblox.com/store/asset/6917372104/Stravant-Quick-Stairs) | Free acquisition, Jan 4, 2026 | Access must demonstrate a whole access assembly with endpoint-driven revisions. |
| [DWeld](https://create.roblox.com/store/asset/5019960405/DWeld-Weld-Models-and-Tools) | Free acquisition, Feb 14, 2026 | Joint should sell reviewed diagnosis/repair, not ordinary welding. |

The [Roblox monetization documentation](https://create.roblox.com/docs/production/monetization)
currently states a **4.99 USD paid-plugin minimum**. The common launch price is a
deliberate conservative response to free overlap and the observed direct scanner
price, not automatic reuse of old catalogue prices. There is no evidence supporting
a higher tier, discount anchor, bundle price or validated willingness-to-pay yet.
For simple jobs, all five listings acknowledge that native tools/free substitutes
may be enough. These are positioning judgments, not proof of competitor deficiencies.

After an authorized release, compare qualified feedback and account-provided
commercial signals before revising pricing. No tracking SDK, telemetry or speculative
sales numbers were introduced for this purpose.

## Media and commercial-quality gate
- Five exact scene/state/caption plans and one video sequence per product are prepared.
- Existing 0.2.5 captures are genuine internal QA, mostly floating-window crops.
  They have not been represented as 25 new finished Store images. No new commercial
  images or videos were captured in this pass; Studio was inspected at its home
  screen, not a product workflow. This is outstanding work, not a claimed tool failure.
- Use the exact frozen installed plugin, not a reimplemented View or staged HTML.
  Scene data may be prepared separately; results and visible UI must be actual.
- Existing fixtures are original primitive geometry. Keep any older licensed-scene
  adaptation's source/licence record if reused; do not pull unlicensed Toolbox art.
- Canonical [F and cover family](forge-studio-ui/brand/CANONICAL_COVER_FAMILY.md) stay
  locked. No final icon/cover export is asserted merely from that design reference.
- Approve the first frame only when a fresh viewer can identify problem, reviewed
  action and result without Forge jargon. No imaginary speed, sales or exclusivity.
- No new UI polish, product behavior or engine features are justified by this pack.

## Playground relevance and blockers
[PUBLIC_READINESS](../experiences/forge-playground/PUBLIC_READINESS.md),
[MEDIA_PLAN](../experiences/forge-playground/MEDIA_PLAN.md) and
[PUBLICATION_CHECKLIST](../experiences/forge-playground/PUBLICATION_CHECKLIST.md)
define the five station flows, entrance mapping, art/copy and actual acceptance protocol.

All listings would lead to one common entrance, then their named station tab. No
station-specific deep link is implemented, no public place ID has been recorded and
playing does not install or grant a plugin. Final art/identity convergence, real
devices, controller navigation, two-client lifecycle and six-player soak remain
unexecuted public gates. They do not invalidate the separately recorded functional V1.

The official [Try-in-Roblox announcement](https://devforum.roblox.com/t/try-in-roblox-for-the-creator-store/4473605)
describes Models/MeshParts, not plugin eligibility. The generic Store docs do not
confirm the option for these five plugin IDs. Treat linkage as conditional: confirm
the field later, otherwise use a permitted ordinary demo link once a real public URL
exists. Do not create a duplicate model/plugin to obtain the feature.

## Verification in this sprint
| Check | Result |
| --- | --- |
| Freeze verifier: five hashes, production hierarchy and exact embedded source equality | **PASS**, rerun 2026-10-03 |
| Packaging verifier's seven positive/negative unit tests | **PASS 7/7**, rerun; not Studio tests |
| Scoped copy/link/hash/description-length validation | **PASS**: 24 Markdown files, local links, five IDs/SHA values, five planned shots per plugin; titles <=50 characters and full descriptions <1000; no private filesystem paths |
| Playground manifest consistency | **PASS**: saved artifact SHA and 35 source hashes; not native execution or independent binary decoding |
| Prior native product tests | **333 PASS / 0 FAIL** retained from #35; not rerun here |
| Prior installed product GUI | Five **GOOD** scoped reviews retained; their untested states remain untested |
| Fresh commercial image/video capture | **NON TESTED / NOT PRODUCED** |
| Playground public network, physical devices, controller and soak | **NON TESTED** |
| Roblox update/publication/account actions | **NOT PERFORMED**, intentionally unauthorized |

Reproduce the packaging checks from repository root:

```sh
python3 -B tools/forge-release/verify_freeze.py --rojo /path/to/rojo
python3 -B -m unittest discover -s tools/forge-release -p 'test_verify_freeze.py' -v
```

Validated full-description lengths: Schema 937, Preset 982, Curve 953, Access 986,
Joint 985 characters. These bounds are a conservative copy constraint, not a claim
that the current upload form enforces these exact limits. Paste only each pack's
Full description section into the description field, not its internal research.

## Final release checklist
1. Complete actual media locally and the Playground public gates. Record file paths,
   hashes and evidence; do not check off plans as execution. Keep all seven issues
   open while their capture/public-polish work remains.
2. Get explicit user approval of media, price and release operations. Seller identity,
   payment/tax steps and distribution confirmation remain user-owned.
3. Verify each frozen SHA; inspect canonical live asset/version and capture a rollback
   backup of binary, copy, media and settings. Do not rely on local historic versions
   as proof of the currently published state.
4. Only then perform one Studio update per existing canonical ID. Stop and inspect
   version history on ambiguity; never duplicate or blindly retry a submission.
5. User completes Creator Hub title/description/media/price/distribution. Current
   [Store guidance](https://create.roblox.com/docs/production/creator-store) allows
   up to five images and one video; verify actual fields/eligibility at upload time.
6. Confirm Store-installed behavior and any permitted demo link. If an update fails,
   restore the backed-up version/settings on the same ID; keep Playground private
   until its independent gates pass. Log the real returned versions and URLs.

Pre-existing local edits in QA places, SchemaForge `dist/`, older screenshots and
untracked user files are outside this preparation commit and remain untouched.
