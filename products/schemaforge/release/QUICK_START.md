# Quick start

1. Open SchemaForge from Studio's Plugins menu in edit mode.
2. Select one correctly configured, tagged object and click **Capture reference**.
3. Name the schema. Set the exact tag, expected class, attribute rules and required child paths. Save it in this project.
4. Open **Audit**. Choose selected roots (including descendants) or Workspace; click **Audit**. Filter by reason/field, then uncheck findings to limit the subset. **Select affected** selects those objects.
5. **Preview** opens **Repairs**: only absent required attributes with enabled defaults are listed. Check the count and targets, then **Apply**. Studio Undo reverses the change.

Reload saved rules from **Library**. Save the place to persist them. A stale preview requires a fresh audit.
