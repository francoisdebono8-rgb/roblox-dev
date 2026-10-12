# SchemaForge / Creator Store copy

Prepared 2026-10-03 for #37. Not uploaded. Status: **READY EXCEPT MEDIA**.

## Title
SchemaForge - Audit & Repair Object Configuration

## One-line promise
Find misconfigured gameplay objects and review missing-only repairs before changing anything.

## Short description
Audit tagged objects against saved contracts. See Expected/Actual, locate each problem, and preview safe missing defaults or required tags.

## Full description
Repeated gameplay objects should follow the same rules, not necessarily have identical values.

SchemaForge audits tagged objects against saved project contracts. Check attribute types, numeric bounds, choices, required children and tag rules. Open a finding to see Expected/Actual and select the object in Studio.

Review the exact proposed changes before applying missing defaults or additive required tags. Wrong existing values, forbidden tags and missing children remain visible for manual review. Re-audit to see what is still unresolved. Writes support Studio Undo.

Use it for repeated doors, pickups, enemies or configurable props. Native Properties or a script may be enough for a one-off check; SchemaForge is for recurring, documented audits and reviewed repairs.

Studio edit-time plugin, not a runtime validator. Supported types and bounded scopes only. No network requests or telemetry; contracts are stored in your place.

## Search terms
attribute validation, tagged objects, configuration audit, missing attributes, required children, project contracts, safe repair, Roblox Studio

## Privacy and limits
- No HTTP requests, analytics, external account or remote storage. HttpService is used only for local JSON serialization. Contracts live in `ServerStorage/_SchemaForgeSchemas`; collaborators with place access can read them. Studio/Roblox platform services are outside this plugin-specific statement.
- Attribute kinds: number, string, boolean, Vector2, Vector3, Color3, CFrame, UDim, UDim2, BrickColor, NumberRange. No arbitrary script/property analysis or runtime enforcement.
- Only missing required attributes with valid, explicitly enabled defaults and additive required tags are repairable. Never overwrite an invalid existing value, remove a forbidden tag or invent a child.
- 32 project contracts; each has up to 32 attribute rules, 32 child rules and 16 required/16 forbidden tags. Named child paths, not wildcard hierarchy repair.
- Audit caps: 100,000 scope visits, 5,000 tagged targets, 2,000 findings; oversized work is refused. Narrow the scope. Freshness checks are not a cross-user transaction guarantee.

## Version and asset
Internal **1.2.0**, visual/catalogue release **Forge Studio 0.2.5**. These are different version axes, not a new asset. Canonical plugin **84085408748744**. Exact candidate and SHA in [LAUNCH_CHECKLIST.md](LAUNCH_CHECKLIST.md).

## Market and launch price
Recommendation: **4.99 USD**, one-time launch price hypothesis, not approved account configuration or validated willingness-to-pay.

Public Creator Store pages inspected live, signed out, on 2026-10-03:

| Substitute | Observation | Positioning consequence |
| --- | --- | --- |
| [Attribute QA](https://create.roblox.com/store/asset/87556490782458/Attribute-QA-Find-Missing-Wrong-Types) | 4.99 USD; updated Aug 29, 2026; reference/inferred schema, missing/wrong types/outliers, read-only | A scanner alone does not justify another purchase. Lead with reusable explicit contracts and bounded repair review. |
| [AttributeSheet](https://create.roblox.com/store/asset/77824934141606/AttributeSheet-Attribute-Table-Batch-Editor) | Now 4.99 USD, updated Sep 29, 2026; table editing, pending-change review, Undo/stale checks | Supersedes our Sep 27 free-price observation. Do not claim exclusive safe batch editing. |
| [Native Properties](https://create.roblox.com/docs/studio/properties) and team scripts | No extra plugin purchase; direct inspection/editing | Better for a few objects or teams already maintaining equivalent validation. |

Paid rationale: a designer-readable saved contract, exact diagnostics and deliberately limited repair in one repeatable workflow. Match the observed direct scanner price, rather than charging a premium without buyer evidence. Reassess after qualified feedback; no demand/sales proof is implied. Competitors were inspected, not purchased or benchmarked; unadvertised features remain unknown.

## Forbidden claims
No "fixes all errors", "guaranteed safe Team Create", "all Roblox types", runtime protection, unique/only validator, invented sales/reviews/time savings, or implication that the Playground grants a plugin licence.
