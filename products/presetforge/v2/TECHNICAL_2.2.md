# PresetForge 2.2.0 technical candidate

Public version remains 2.1.0. Canonical asset 73596873703054 is unchanged.

## Engine contract

`PreviewService:build(recipe, selection, options, revision)` returns the existing
read-only result data plus an immutable `plan` and planning `metrics`.
`ApplyService:apply(plan, currentContext)` consumes only an issued plan, including
on a failed attempt. Naked recipe/target writes and copied/forged plans are rejected.
The context contains `recipe`, `selection`, `options` and the selected recipe's
`revision`. A callback returning the context allows recording-start reentrancy to
be checked against live Selection/repository state. The controller uses that callback.

The plan freezes normalized recipe data, schema id/version, scope, ordered roots,
root ancestry, ordered compatible/affected identities, exact original values and
presence for every selected property/tag/attribute, and the exact ordered writes.
The controller tracks per-recipe in-session mutation revisions. Repository lookup
reloads the selected store read-only so independent saved-recipe edits are visible;
failed loads never return the previous cached recipe. Engine validation
also checks recipe content, options, target resolution, classes and full ancestry.
Before-values use exact codec equality, including arbitrarily small number changes;
post-write property readback uses the schema's existing numeric codec tolerance.

Apply validates before opening History and again immediately before writing.
Detached instances of the exact concrete target class probe controlled property
setters, interacting fields, tag names and attribute setters before project mutation.
Only changed entries in the approved plan execute. Every setter is journaled before
invocation so mutation-then-error also rolls back. Every write is read back, counts
must match, and the final transaction is checked before committing. Rollback restores
false/zero/empty attributes and absence separately, removes only newly added tags,
and reports rollback/cancel failures rather than masking them.

Selection navigation now requires a fresh Preview. Name changes without a name
filter, nonmatching added objects and unrelated fields do not invalidate an engine
plan. Watchers ask the same engine before clearing the controller preview.

## Selective capture and persistence

`CaptureService:capture(selection, options)` retains the existing property selector
and all-metadata booleans. Optional `tagNames` and `attributeNames` arrays choose
only those existing source names; absent, duplicate or oversized choices fail.
Omitting either array captures all available names in that enabled category.
Recapture preserves the saved names and refuses missing selected names. Apply adds
tags and adds/updates attributes; it never removes unrelated metadata.

No new persisted format is necessary: the existing version-2 `tags` list and
`attributes` map already encode exactly the chosen subset. Public 2.0/2.1 recipes
retain every stored field/tag/attribute. The version-1 legacy migration remains
supported. Loads do not rewrite local settings or project instances; an explicit
save writes format 2. Historical codecs are exercised from the exact commercial
2.0/2.1 binaries with current-to-old and old-to-current round trips.

Project writes prepare and verify a detached replacement library before starting a
single History transaction. The original root/content/instance set is rechecked
after recording starts. The old graph remains detached for identity-preserving
Undo/Redo. Failed commits restore the original graph. Duplicate roots, ambiguous
children, duplicate/nonsequential tag records, nested tag content, corrupted values,
cycles, sparse/extra indexed entries, constructor-defaulted/cast-corrupt values and
oversized input are rejected. Local saves verify the current library before writing
and restore the previous stored representation when a write or readback fails.

## Bounds

| Input | Maximum |
| --- | ---: |
| Selected roots (duplicates count toward bound) | 256 |
| Unique scanned descendants | 20,000 |
| Compatible targets | 5,000 |
| Affected targets | 2,000 |
| Planned writes across all categories | 20,000 |
| Recipes per library | 256 |
| Tags / attributes per recipe | 64 / 64 |
| Tag / attribute name bytes | 100 / 100 |
| Value string bytes | 16,384 |
| Serialized aggregate string bytes | 4 MiB |
| Persisted nesting / visited values | 16 / 200,000 |
| Target ancestry depth | 512 |

Descendants traversal visits overlapping subtrees once using an explicit stack;
it does not materialize repeated `GetDescendants()` arrays. Roblox `GetChildren()`
still materializes each immediate child list. Limits return an error with no partial
Preview and no mutation. Metrics report scanned, ignored, compatible, matching,
affected, property writes, tag writes and attribute writes.

## Evidence

See `../tests/TECHNICAL_GATE_2.2.md` for exact-artifact reproduction. Final native
Studio 0.740.19.7400003 execution passed 74/74 checks, including all 35 issue matrix
rows, on SHA-256 `535eb4da640adbbb8de5cea94a2778453620a74ce709e06e951436c3074b3857`.
The coordinating main agent executed Studio; sanitized evidence is retained in
`technical-2.2-native.txt`, with the complete matrix in `TECHNICAL_2.2_MATRIX.md`.
No UI redesign, screenshots, commercial media, listing, outreach or publication
is included. The current interface retains its capture-all checkboxes; selective
metadata is exposed through the bounded engine API and native technical tests.
