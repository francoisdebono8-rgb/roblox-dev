# JointForge 1.1.0 technical matrix

Issue #22. Candidate `dist/JointForge-v1.1.0.rbxm` is unpublished.
Final candidate SHA256: `9e73c5e8387190d324eac57c762818f452758ad731000db24e2ab522df04cc17`.

**Final-artifact native status: awaiting coordinator rerun.**
The preceding candidate `649b5e977a9ccf8f4fff3f2429c036d15799619289579067d08e60144f0a299f`
passed 38 native cases and all 56 rows on 2026-09-28 in Studio 0.740.19.7400003.
That evidence is not substituted for the final binary after its attachment Preview text fix.

The native gate imports the exact candidate and public V1 binaries. It runs only in
the generated empty local Edit-mode place. A native baseline waypoint precedes every
Undo recording. QA-only failure injection and History adapters are labelled in the
suite. Real native setters and restored instance identities are asserted. The View
smoke mounts native controls and invokes captured callbacks; no human mouse-click,
screenshot, visual-design or publication acceptance is claimed.

| # | Required check | Status | Evidence scope |
| ---: | --- | --- | --- |
| 1 | WeldConstraint create | NON TESTED | Exact endpoints, read-only Preview, native Undo/Redo |
| 2 | Weld create | NON TESTED | Exact endpoints, offsets and native Undo/Redo |
| 3 | Motor6D create | NON TESTED | Exact endpoints, offsets and native Undo/Redo |
| 4 | Hinge create | NON TESTED | Exact endpoint/attachment identities and history |
| 5 | BallSocket create | NON TESTED | Exact endpoint/attachment identities and history |
| 6 | Rope create | NON TESTED | Exact endpoint/attachment identities and history |
| 7 | Rod create | NON TESTED | Exact endpoint/attachment identities and history |
| 8 | Spring create | NON TESTED | Exact endpoint/attachment identities and history |
| 9 | NoCollision create | NON TESTED | Exact endpoints and native history |
| 10 | Same-part refusal | NON TESTED | Pair diagnostics |
| 11 | Direct duplicate conflict | NON TESTED | Reversed exact identity pair |
| 12 | Indirect connection conflict | NON TESTED | A-B-C physical path |
| 13 | NoCollision separate semantics | NON TESTED | Physical coexistence, separate duplicates and graph components |
| 14 | Broken endpoint diagnostic | NON TESTED | Missing Motor6D endpoint; unsupported unary inspection |
| 15 | Invalid attachment ancestry | NON TESTED | Nested attachment refusal and Inspect diagnosis |
| 16 | Anchored-both warning | NON TESTED | Pair diagnostic |
| 17 | Hinge-axis warning | NON TESTED | Rotated explicit attachment axes |
| 18 | Separated-pivot warning | NON TESTED | Explicit noncoincident attachment pivots |
| 19 | Exact plan one-use | NON TESTED | Frozen nested data, private consumption and View invalidation |
| 20 | Copied/forged plans reject | NON TESTED | Copied and fabricated plan identities; mutation refusal |
| 21 | Relevant graph change stales | NON TESTED | New incident edge, graph change inside recording open |
| 22 | Unrelated graph change stays fresh | NON TESTED | Distant joint addition/removal, name, Enabled and endpoint pose |
| 23 | Endpoint reparent/delete stales | NON TESTED | Ancestor move and endpoint detachment from Workspace |
| 24 | Attachment move/reparent/delete stales | NON TESTED | Tiny local movement, reparent and Destroy |
| 25 | Edited field change stales | NON TESTED | Tiny C0 change compared before History |
| 26 | Field preflight/readback | NON TESTED | Every exposed field; enums, clamps and finite-to-infinite refusal |
| 27 | Cross-field bounds | NON TESTED | Hinge, BallSocket and Spring invalid paired limits |
| 28 | C0/C1 finite validation | NON TESTED | NaN and infinity refusal |
| 29 | Explicit Part reassignment | NON TESTED | All four Part-based classes; fields and identities |
| 30 | Explicit attachment reassignment | NON TESTED | All five attachment classes; existing and explicitly new |
| 31 | Broken joint explicit repair | NON TESTED | Missing Part/Attachment repaired only through explicit input |
| 32 | Preserve-pose reassignment | NON TESTED | Weld/Motor6D, unanchored parts and old physical neighbor; Transform restriction |
| 33 | Batch static | NON TESTED | 128-entry mixed assembly; exact WeldConstraint semantics |
| 34 | Batch moving | NON TESTED | 128-entry mixed assembly; exact Motor6D offsets |
| 35 | Mixed batch | NON TESTED | Deterministic ordered mixed operations and native history |
| 36 | Duplicate/root batch refusal | NON TESTED | Root, duplicate, invalid mode and whole-plan rejection |
| 37 | Bounded large batch | NON TESTED | 128 entries plus full Preview benchmark against embedded V1 |
| 38 | Owned attachment failure cleanup | NON TESTED | Injected postwrite/commit faults; existing attachments remain |
| 39 | Rope/Rod length initialization | NON TESTED | Planned actual distance and minimum-distance refusal |
| 40 | Spring FreeLength initialization | NON TESTED | Planned actual distance and minimum-distance refusal |
| 41 | Remove confirmation | NON TESTED | No History begin without explicit confirmation |
| 42 | Remove exact rollback identity | NON TESTED | Exact same detached/restored native Instances |
| 43 | Recording refusal | NON TESTED | No mutation and consumed one-use plan |
| 44 | Mutation during recording open | NON TESTED | Revalidate pose/new edge; external changes preserved |
| 45 | Mid-create failure rollback | NON TESTED | QA-only postwrite injection after attachment/first batch joint |
| 46 | Mid-edit failure rollback | NON TESTED | QA-only postwrite injection; fields and world poses restored |
| 47 | Mid-remove failure rollback | NON TESTED | QA-only postwrite injection; visited/unvisited instance identities |
| 48 | Commit failure rollback | NON TESTED | QA-only History adapter for create/edit/reassign/remove |
| 49 | Native Undo/Redo create | NON TESTED | All nine classes plus mixed batch |
| 50 | Native Undo/Redo edit/reassign | NON TESTED | Raw C0/C1, numeric field, all nine endpoint classes |
| 51 | Native Undo/Redo remove | NON TESTED | Same joint identity; attachments retained |
| 52 | Graph/operation caps | NON TESTED | Individual scan/node/edge/component/batch/operation/remove/request/depth/selection fixtures |
| 53 | Deterministic duplicate-name identity | NON TESTED | 128 repeated names, existing suffix collision, stable preview ordering |
| 54 | No runtime exception on success | NON TESTED | Native suite and monitored ScriptContext; callback-based View smoke |
| 55 | Exact artifact/source correspondence | NON TESTED | Reproducible bytes and imported candidate Sources; QA-copy Main disabled |
| 56 | No network/telemetry/runtime payload | NON TESTED | Imported six-script/eight-item allowlist and source scan |

## Limits and performance

All 11 limit assertions print individual CAP evidence: scan 20,000; nodes 8,000;
edges 8,000; physical component 4,000; batch input 256; planned operations 128;
removal input 256; request values 8,192; request depth 16; hierarchy depth 128;
Inspect selection 8,000. Any failure empties the executable operations list.

The benchmark compares full Preview against the embedded public V1 on the same
5,833-descendant fixture with 32 batch entries and 1,000 distant edges. It uses two
warmups and five measurements and reports medians. Final values are supplied by the
exact-candidate evidence collector; no generalized performance claim is made.

## Restrictions and deferrals

- Preserve-pose reassignment of a Motor6D with nonidentity Transform is explicitly
  refused. Identity Transform is covered; explicit raw mode preserves the current
  offsets and Transform with a motion warning.
- Unsupported classes remain inspect-only. Mixed supported/unsupported removals
  reject the complete request. Removal never deletes attachments.
- Source-based legacy Suite.luau was adapted and syntax-compiled, not rerun as part
  of this acceptance. V11.spec.luau supplies the exact-binary coverage above.
- Functional native work only. No UI redesign, screenshots/media, listing/outreach,
  Creator Store update, price/distribution change or canonical asset overwrite.

See [technical contract](../v2/TECHNICAL_1.1.0.md) for requests, transaction semantics,
limits, reproduction commands and the exact QA boundary.
