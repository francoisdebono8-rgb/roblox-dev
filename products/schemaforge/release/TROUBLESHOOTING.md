# Troubleshooting

- **No matches:** check exact tag spelling, scope and selected roots. A tag is required; the class is an additional check, not a replacement for the tag.
- **Nothing to repair:** repairs only add absent required attributes with enabled valid defaults. Correct existing wrong values/types and child issues yourself.
- **Stale preview / history changed:** run a fresh audit after edits, selection-scope moves or Undo/Redo.
- **Save conflict:** reload the saved schema before editing it again. Do not manually edit the storage folder while the panel is open.
- **Invalid rule:** correct the highlighted error, bounds, defaults, duplicate names or child path. Empty numeric bounds mean unbounded.
- **Ambiguous child:** rename duplicate siblings so the path identifies one child.
- **Scan limit:** audit a smaller selection. An exceeded limit stops the audit instead of presenting a partial success.
