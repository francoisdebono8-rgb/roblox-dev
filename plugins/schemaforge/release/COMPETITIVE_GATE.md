# SchemaForge competitive gate

Checked 2026-09-27, before implementation. Decision: PASS for the focused scope below, not evidence of proven sales.

## Ordered demand research

1. Studio Features: [attribute descriptions](https://devforum.roblox.com/t/custom-descriptions-for-attributes-in-the-properties-panel/4664872), June 2026, multiple developers describe designer handoff and forgotten field meanings. [Studio attribute validation](https://devforum.roblox.com/t/a-number-of-studio-specific-attribute-features-to-improve-ux/1334456), 2021 with 2024 follow-up, requests numeric bounds and string choices. [Invalid repeated rail models](https://devforum.roblox.com/t/parity-between-the-query-language-and-explorer-more-syntax/4893794), September 25, 2026, requires missing-child and value checks together.
2. Building Support: searched `attributes tags`, `missing configuration`, `configure tag` and model setup. No strong independent schema demand in that category: do not relabel Scripting/Platform threads as Building Support evidence. The adjacent [bulk attribute support thread](https://devforum.roblox.com/t/are-there-any-faster-ways-to-do-add-attributes/3165640) is Platform Usage, solved and closed in 2024. Its joking willingness-to-pay is NOT commercial proof.
3. Community Resources and plugins searches: [Attribute Manager](https://devforum.roblox.com/t/attribute-manager-plugin-for-all-your-attribute-needs/1562593) and [Attribute Cloner](https://devforum.roblox.com/t/plugin-attribute-cloner-dkns-attributes-editor/3253747) cover editing/copying. [RoZod](https://devforum.roblox.com/t/rozod-%E2%80%93-schema-validator-coercion/4616817) is a code library, not a designer-facing Studio audit tool. No competitor code used.
4. Live Creator Store search in browser, not just search-engine index: `schema` returned one unrelated Color Schema plugin; `attribute` returned 52 results; `validator` returned four specialized size/emote/train/VFX tools. Inspected the closest listings directly:

| Product | Price / recency / rating observed | Relevant boundary |
| --- | --- | --- |
| [Attribute QA](https://create.roblox.com/store/asset/87556490782458/Attribute-QA-Find-Missing-Wrong-Types) | $4.99; updated Aug 29, 2026; insufficient ratings, 0 reviews | Real direct competitor: reference/inferred schema, missing/wrong types/outliers, read-only. A mere missing-attribute scanner is REJECTED. |
| [AttributeSheet](https://create.roblox.com/store/asset/77824934141606/AttributeSheet-Attribute-Table-Batch-Editor) | Free; Sep 13, 2026; insufficient ratings, 0 reviews | Strong maintained table/batch editor, preview, Undo and stale checks. Generic attribute editing is REJECTED. No saved documented validation contracts advertised. |
| [Aura Attribute Suite](https://create.roblox.com/store/asset/72573393005300/Aura-Attribute-Suite) | $5.99; May 12, 2026; insufficient ratings, 0 reviews | Broad editing, conversion, batch operations, comparison/export. No required-child contracts or reusable validation rules advertised. |
| [Attribute Tools](https://create.roblox.com/store/asset/9516206594/Attribute-Tools) | Free; May 2, 2022; insufficient ratings, 0 reviews | Bulk creation only. |

Listings and media presence were inspected, not purchased or reverse-engineered. This is not an exhaustive catalog census; absence of an advertised feature is not proof that no competitor has it. No download/sales estimates fabricated.

## Native and internal competition

[Properties](https://create.roblox.com/docs/studio/properties) already edits tags/attributes; [Explorer](https://create.roblox.com/docs/studio/explorer) filters and selects objects. Instance.QueryDescendants also supports attribute presence/equality and negation. Native search or a short script is better for one-off checks. Neither inspected native workflow provides saved, documented, per-tag rules with explicit ranges/choices plus required-child validation and reviewed missing-only repairs.

PresetForge applies chosen recipes; SchemaForge checks project-specific correctness without homogenizing existing values. No geometry, joints, curves or access assemblies. No second property editor.

## Paid V1 contract

Promise: **Catch misconfigured tagged objects before playtesting.**

- Capture a starting schema from one reference, then edit explicit rules in a GUI.
- Required/optional number, string and boolean attributes; numeric min/max/integer, string choices, field descriptions and opt-in defaults.
- Named child paths with expected class, including duplicate-name ambiguity reporting; never create missing children automatically.
- Tag plus expected class; audit Workspace or selected roots including descendants; select findings.
- Project-saved contracts, load/edit/delete, native Undo for writes.
- Read-only audit and exact repair preview. Repair ONLY absent required attributes with explicitly enabled valid defaults. Never overwrite wrong values/types or unrelated data.
- Graphite, mint and coral secondary identity. Three genuine scenes: rule contract, broken objects audit, safe missing-default repair.
- Recommended $4.99, an unvalidated price hypothesis. Best customer: small teams with repeated configured gameplay objects; little value for static-only builders or teams already running equivalent custom validators.

Not V1: runtime validation, code execution/generation, schema inference from majority, all Roblox property types, CSV/spreadsheets, auto tagging, script analysis, automatic hierarchy repair, continuous scanning, shared cloud data, telemetry or HTTP requests.

## Real-project check and API feasibility

Roblox/resources at `ee51421b99234a436aa22d417a31316541b1575d`, MIT (Roblox Corporation), inspected locally. Plant's `Utility/getAttribute.luau` asserts required attributes and its `ComponentCreator` uses tags; configured prefabs provide a credible audit workflow. Gold Rush uses a Gold tag but comparatively little configuration: a schema plugin adds little there, so it is not used to inflate demand.

Current documented Instance GetAttributes/SetAttribute/HasTag/GetChildren, Selection, JSON encoding and ChangeHistoryService recording APIs suffice. JSON encoding uses HttpService locally, not HTTP requests. Native tests remain mandatory before release.
