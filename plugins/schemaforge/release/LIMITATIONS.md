# SchemaForge 1.1 boundaries

- Studio edit mode, explicit tagged-object contracts, not runtime/server validation.
- Number, boolean and string attributes only. Other reference attributes are skipped and counted.
- Numeric bounds/integer and exact string choices; no expressions, regex, code analysis or generated scripts.
- Child paths use exact names separated by `/`. Duplicate sibling names are reported as ambiguous. Required children are never created/replaced.
- Repairs only add missing required attributes with explicitly enabled defaults. Existing values/types, tags, properties and hierarchy stay unchanged.
- Schemas live in the current place, not a global/cloud library. Saving under a new name creates another schema; delete the old one separately if desired.
- Limits: 32 schemas; 32 attributes and 32 child rules per schema; 100,000 visited instances, 5,000 tagged matches, 2,000 findings per audit. Exceeding a limit fails the scan.
- Native Properties/Explorer or a short script is preferable for one-off checks. Teams with equivalent validators may not need this plugin.
- Findings are contract diagnostics, not a guarantee that gameplay is correct. Object identity numbers distinguish same-name objects within the current plugin session, not across sessions.
