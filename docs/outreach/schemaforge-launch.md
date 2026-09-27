# Draft only: SchemaForge - Configuration Contracts for Tagged Objects

Destination: Community Resources, plugins tag. Not posted. Confirm distribution and the final price before posting; attach the actual PNGs below.

I'm the developer of **SchemaForge**, a paid Roblox Studio plugin. Suggested launch price: **USD 4.99**; check the listing for final price and availability.

Duplicating a gameplay object is easy. Remembering its required attributes, allowed values and child hierarchy across dozens of copies is less easy. SchemaForge keeps those expectations in an explicit, documented contract saved with the place.

Capture one reference, refine its rules, then audit an exact tag across Workspace or selected roots and descendants. Findings select the actual objects. The audit doesn't modify your project objects.

Three useful workflows:

1. Hand a designer a documented contract: required numbers/booleans/strings, bounds, integer rules and string choices.
2. Check repeated interactive prefabs for missing or ambiguous child paths and unexpected classes before playtesting.
3. Review an exact missing-default repair list, apply it and undo it natively. Existing values, wrong types and hierarchy are never overwritten.

Attach, in order:

- `products/schemaforge/release/media/01-explicit-project-contract.png`: required plant child and designer note.
- `products/schemaforge/release/media/02-audit-tagged-objects.png`: eight pots, six findings, five objects selected.
- `products/schemaforge/release/media/03-preview-missing-defaults.png`: two missing Costs previewed as 25.

These are real Studio screenshots of an adapted official Roblox Plant scene (Roblox/resources, MIT). The scene isn't included in the paid plugin.

V1 supports number, string and boolean attributes. It does not validate all Roblox properties, enforce rules during gameplay, analyze scripts or repair hierarchy. Schemas and notes need updating when your code changes. Native Explorer/Properties or your own validator may be enough for one-off checks.

No HTTP, telemetry or external services. Project schemas are readable non-executable JSON. Repairs and schema changes support Studio Undo/Redo.

[SchemaForge on Creator Store](https://create.roblox.com/store/asset/84085408748744)

I'd welcome concrete feedback: which repeated configuration mistakes still slip through before your first playtest?
