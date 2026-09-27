# V2 evidence and counter-evidence

Read/search date: 2026-09-27. Primary sources only for technical conclusions.
Forum posts demonstrate a request, not purchase intent. Competitor marketing describes
claimed capability, not a verified implementation. No posting or competitor installation.

## Studio Features first

| Evidence | Date/activity observed | Interpretation and limit |
|---|---|---|
| [Preset manager request](https://devforum.roblox.com/t/preset-manager-for-organizing-and-bulk-applying-properties-attributes-tags-and-collisiongroups-to-instances/1164752) | April 2021, bumped June 17 2026 | Reusable configurations, organization/search, matching objects. PresetForge already covers much of it; find/duplicate recipes is a better extension than adding arbitrary classes. |
| [Attribute descriptions](https://devforum.roblox.com/t/custom-descriptions-for-attributes-in-the-properties-panel/4664872) | June 2026 | Designer handoff/context. SchemaForge notes already exist; surface them at the finding, do not count notes as a new feature. Cannot promise injecting hints into native Properties. |
| [Attribute UX constraints](https://devforum.roblox.com/t/a-number-of-studio-specific-attribute-features-to-improve-ux/1334456) | July 2021, later activity April 2024 | Ranges, integers and choices are established pain, already in SchemaForge V1. Not fresh demand for a rewrite. |
| [Highlight tagged/attributed instances in Explorer](https://devforum.roblox.com/t/highlight-instances-with-tags-or-attributes-in-the-explorer/3957685) | September 2025 | Author distinguishes hierarchy visibility from search/world highlights. Do not misrepresent our Select button as the requested native Explorer feature. |
| [Explorer attribute filtering](https://devforum.roblox.com/t/filter-by-attributes-in-explorer/2828954) | 2024, later discussion 2025 | Discoverability in large projects. Recheck native capabilities; old absence is not proof of a 2026 gap. |

Searches for current Studio Features on curve paths, stairs and welding did not establish
an equally direct fresh request. Do not manufacture one to balance the five products.
[Tool joint types](https://devforum.roblox.com/t/adding-joint-types-to-tools/4352889)
(February-March 2026) is **Engine Features**, about runtime tool grips, not a Studio
Feature request that JointForge fully solves. No runtime injection or animation product.

## Building Support second

| Evidence | Date | Decision |
|---|---|---|
| [Efficient welding](https://devforum.roblox.com/t/looking-for-efficient-way-to-weld-parts-together/2863082) | March 2024 | 43-constraint assembly; replies recommend native Create Constraints. Strong counterargument to charging for basic batch weld alone. |
| [Welds not working](https://devforum.roblox.com/t/welds-not-working/2628030) | October 2023 | Duplicated objects with wrong connections despite a welding plugin. Supports endpoint diagnosis/locating, not more creation buttons. Old thread, no promotional revival. |
| [Repeat a pattern while resizing](https://devforum.roblox.com/t/studio-feature-or-plugin-that-repeats-a-pattern-on-scaling-or-resizing/4095587) | November 2025 | Repetition demand is real, but replies already recommend Ropeater and Archimedes. Improve editable placement, not a generic array clone. |

No strong new Building Support case uniquely justifying SchemaForge or a broader
AccessForge generator was established. Existing solved stair/attribute threads remain
weak outreach targets. Real local scene friction is labelled separately in the audits.

## Community Resources / plugins third

- [Preset Manager](https://devforum.roblox.com/t/preset-manager-plugin-bulk-apply-properties-attributes-tags-and-collisions/1187701), 2021: searchable reusable properties/attributes/tags/collisions and duplication already advertised. Search is expected parity, not our invention. Current external price/maintenance unverified.
- [Contour Terrain](https://devforum.roblox.com/t/plugin-contour-terrain-v121-30-off-draw-extend-roads-decorate/4875253), September 2026: road/terrain tool and discussion questioning paid value against forthcoming native tools. Reject terrain/roads expansion. A promised native release is not asserted already shipped.
- [TriTerrain](https://devforum.roblox.com/t/triterrain-a-triangle-terrain-generator/4045295), update March 2026: editable point-driven construction raises the interaction bar. Not evidence that CurveForge should become terrain software.
- [Attribute Manager](https://devforum.roblox.com/t/attribute-manager-plugin-for-all-your-attribute-needs/1562593) and [Attribute Cloner](https://devforum.roblox.com/t/plugin-attribute-cloner-dkns-attributes-editor/3253747): existing batch-management alternatives. Do not market generic attribute editing as unserved.

## Creator Store fourth

Current prices, dates, ratings and links are in [catalog-baseline.md](catalog-baseline.md).
Especially important: free/current Joint Editor and Quick Stairs; September 2026
AttributeSheet; paid Attribute QA. Stairs Creator's visible February 2026 complaint
about changing endpoint direction supports reversible placement, but was not reproduced
in that competitor. Our five products have no public customer review evidence yet.

## Native substitution gate

- [Properties](https://create.roblox.com/docs/studio/properties) already exposes properties,
  tags and attributes. One-off edits and duplicate configured objects often need no plugin.
- [Explorer](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/explorer.md)
  supports name, property, class, tag and ancestry filtering. Do not sell bare descendant
  selection as a unique capability.
- [QueryDescendants](https://create.roblox.com/docs/reference/engine/classes/Instance#QueryDescendants)
  documents attribute selectors, negation and child matching. A programmer can write an
  audit query. SchemaForge must provide saved understandable contracts and actionable
  findings, not claim that native Roblox cannot find missing attributes/children.
- Native duplication/transform tools, Create Constraints and small known project scripts
  remain valid cheaper alternatives. Full auto-repair, runtime enforcement, animation,
  road generation, universal schemas and cloud collaboration are outside this evidence.

No Reddit evidence was needed to justify this block. Research is bounded, not proof of
market exhaustiveness. Recheck active threads and competitive deltas before implementing.
