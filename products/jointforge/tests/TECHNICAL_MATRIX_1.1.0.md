# JointForge 1.1.0 technical matrix

Issue #22. Candidate `dist/JointForge-v1.1.0.rbxm` is unpublished.
Final candidate SHA256: `9e73c5e8387190d324eac57c762818f452758ad731000db24e2ab522df04cc17`.

**Final-artifact native status: PASS.**
Executed in Roblox Studio 0.740.19.7400003 on 2026-09-28 at 11:45:48 UTC:
**38 native cases PASS / 0 FAIL, 56/56 matrix rows PASS, all 11 caps PASS**.
Evidence: [native-v11-technical.txt](native-v11-technical.txt) and
[technical-1.1.0-results.json](technical-1.1.0-results.json), verified against the
final candidate SHA above. Compilation and reproducible-source verification also PASS.

The preceding candidate `649b5e977a9ccf8f4fff3f2429c036d15799619289579067d08e60144f0a299f`
passed 38 native cases and all 56 rows on 2026-09-28 in Studio 0.740.19.7400003.
The complete gate was rerun after the attachment Preview text fix; the older run
is retained separately as historical evidence, not substituted for the final binary.

The native gate imports the exact candidate and public V1 binaries. It runs only in
the generated empty local Edit-mode place. A native baseline waypoint precedes every
Undo recording. QA-only failure injection and History adapters are labelled in the
suite. Real native setters and restored instance identities are asserted. The View
smoke mounts native controls and invokes captured callbacks; no human mouse-click,
screenshot, visual-design or publication acceptance is claimed.

| # | Required check | Status | Evidence scope |
| ---: | --- | --- | --- |
| 1 | WeldConstraint create | PASS | Exact endpoints, read-only Preview, native Undo/Redo |
| 2 | Weld create | PASS | Exact endpoints, offsets and native Undo/Redo |
| 3 | Motor6D create | PASS | Exact endpoints, offsets and native Undo/Redo |
| 4 | Hinge create | PASS | Exact endpoint/attachment identities and history |
| 5 | BallSocket create | PASS | Exact endpoint/attachment identities and history |
| 6 | Rope create | PASS | Exact endpoint/attachment identities and history |
| 7 | Rod create | PASS | Exact endpoint/attachment identities and history |
| 8 | Spring create | PASS | Exact endpoint/attachment identities and history |
| 9 | NoCollision create | PASS | Exact endpoints and native history |
| 10 | Same-part refusal | PASS | Pair diagnostics |
| 11 | Direct duplicate conflict | PASS | Reversed exact identity pair |
| 12 | Indirect connection conflict | PASS | A-B-C physical path |
| 13 | NoCollision separate semantics | PASS | Physical coexistence, separate duplicates and graph components |
| 14 | Broken endpoint diagnostic | PASS | Missing Motor6D endpoint; unsupported unary inspection |
| 15 | Invalid attachment ancestry | PASS | Nested attachment refusal and Inspect diagnosis |
| 16 | Anchored-both warning | PASS | Pair diagnostic |
| 17 | Hinge-axis warning | PASS | Rotated explicit attachment axes |
| 18 | Separated-pivot warning | PASS | Explicit noncoincident attachment pivots |
| 19 | Exact plan one-use | PASS | Frozen nested data, private consumption and View invalidation |
| 20 | Copied/forged plans reject | PASS | Copied and fabricated plan identities; mutation refusal |
| 21 | Relevant graph change stales | PASS | New incident edge, graph change inside recording open |
| 22 | Unrelated graph change stays fresh | PASS | Distant joint addition/removal, name, Enabled and endpoint pose |
| 23 | Endpoint reparent/delete stales | PASS | Ancestor move and endpoint detachment from Workspace |
| 24 | Attachment move/reparent/delete stales | PASS | Tiny local movement, reparent and Destroy |
| 25 | Edited field change stales | PASS | Tiny C0 change compared before History |
| 26 | Field preflight/readback | PASS | Every exposed field; enums, clamps and finite-to-infinite refusal |
| 27 | Cross-field bounds | PASS | Hinge, BallSocket and Spring invalid paired limits |
| 28 | C0/C1 finite validation | PASS | NaN and infinity refusal |
| 29 | Explicit Part reassignment | PASS | All four Part-based classes; fields and identities |
| 30 | Explicit attachment reassignment | PASS | All five attachment classes; existing and explicitly new |
| 31 | Broken joint explicit repair | PASS | Missing Part/Attachment repaired only through explicit input |
| 32 | Preserve-pose reassignment | PASS | Weld/Motor6D, unanchored parts and old physical neighbor; Transform restriction |
| 33 | Batch static | PASS | 128-entry mixed assembly; exact WeldConstraint semantics |
| 34 | Batch moving | PASS | 128-entry mixed assembly; exact Motor6D offsets |
| 35 | Mixed batch | PASS | Deterministic ordered mixed operations and native history |
| 36 | Duplicate/root batch refusal | PASS | Root, duplicate, invalid mode and whole-plan rejection |
| 37 | Bounded large batch | PASS | 128 entries plus full Preview benchmark against embedded V1 |
| 38 | Owned attachment failure cleanup | PASS | Injected postwrite/commit faults; existing attachments remain |
| 39 | Rope/Rod length initialization | PASS | Planned actual distance and minimum-distance refusal |
| 40 | Spring FreeLength initialization | PASS | Planned actual distance and minimum-distance refusal |
| 41 | Remove confirmation | PASS | No History begin without explicit confirmation |
| 42 | Remove exact rollback identity | PASS | Exact same detached/restored native Instances |
| 43 | Recording refusal | PASS | No mutation and consumed one-use plan |
| 44 | Mutation during recording open | PASS | Revalidate pose/new edge; external changes preserved |
| 45 | Mid-create failure rollback | PASS | QA-only postwrite injection after attachment/first batch joint |
| 46 | Mid-edit failure rollback | PASS | QA-only postwrite injection; fields and world poses restored |
| 47 | Mid-remove failure rollback | PASS | QA-only postwrite injection; visited/unvisited instance identities |
| 48 | Commit failure rollback | PASS | QA-only History adapter for create/edit/reassign/remove |
| 49 | Native Undo/Redo create | PASS | All nine classes plus mixed batch |
| 50 | Native Undo/Redo edit/reassign | PASS | Raw C0/C1, numeric field, all nine endpoint classes |
| 51 | Native Undo/Redo remove | PASS | Same joint identity; attachments retained |
| 52 | Graph/operation caps | PASS | Individual scan/node/edge/component/batch/operation/remove/request/depth/selection fixtures |
| 53 | Deterministic duplicate-name identity | PASS | 128 repeated names, existing suffix collision, stable preview ordering |
| 54 | No runtime exception on success | PASS | Native suite and monitored ScriptContext; callback-based View smoke |
| 55 | Exact artifact/source correspondence | PASS | Reproducible bytes and imported candidate Sources; QA-copy Main disabled |
| 56 | No network/telemetry/runtime payload | PASS | Imported six-script/eight-item allowlist and source scan |

## Limits and performance

All 11 limit assertions print individual CAP evidence: scan 20,000; nodes 8,000;
edges 8,000; physical component 4,000; batch input 256; planned operations 128;
removal input 256; request values 8,192; request depth 16; hierarchy depth 128;
Inspect selection 8,000. Any failure empties the executable operations list.

The benchmark compares full Preview against the embedded public V1 on the same
5,833-descendant fixture with 32 batch entries and 1,000 distant edges. It uses two
warmups and five measurements. Final measured medians: V1 83.535792 ms and candidate
15.488333 ms, with one graph scan per Preview. These are fixture-specific timings,
not a generalized performance claim.

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
