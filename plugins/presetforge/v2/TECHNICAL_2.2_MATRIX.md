# Issue #19 technical matrix

Candidate: PresetForge 2.2.0, unpublished. SHA-256:
`535eb4da640adbbb8de5cea94a2778453620a74ce709e06e951436c3074b3857`.

Native Studio 0.740.19.7400003, Edit mode, 2026-09-28: **74/74 PASS, 0 FAIL** on
this exact candidate. The coordinating main agent executed the isolated QA place.
Each M row below is a real native test in `tests/V22.spec.luau`, run using exact
candidate modules and historical commercial artifacts. Sanitized product-prefixed
evidence: `technical-2.2-native.txt`.

| # | Requirement | Status |
| --- | --- | --- |
| 1 | Legacy 2.0 Local/Project load and save round trip | PASS |
| 2 | 2.1 Local/Project load and save round trip | PASS |
| 3 | Current Local real isolated plugin settings round trip | PASS |
| 4 | Current Project round trip and failure rollback | PASS |
| 5 | Selective property subset | PASS |
| 6 | Selective tag subset and recapture | PASS |
| 7 | Selective attribute subset and recapture | PASS |
| 8 | Unrelated tags preserved | PASS |
| 9 | Unrelated attributes preserved | PASS |
| 10 | Mixed Selection immutable exact plan; Preview read-only | PASS |
| 11 | Overlapping Descendants roots deduplicated | PASS |
| 12 | Class/name/tag filtering | PASS |
| 13 | Added matching descendant stales plan | PASS |
| 14 | Removed matching descendant stales plan | PASS |
| 15 | Reparenting and ancestry stales plan | PASS |
| 16 | Exact property before-value freshness, including tiny changes | PASS |
| 17 | Exact attribute presence/value freshness | PASS |
| 18 | Planned tag presence freshness | PASS |
| 19 | Unrelated properties/nonmatching additions remain fresh | PASS |
| 20 | Recipe content changes stale plan | PASS |
| 21 | Matching targets and unchanged fields receive zero setters | PASS |
| 22 | Actual write counts equal plan; metrics | PASS |
| 23 | Actual native integer clamp preflight; readback mismatch rollback | PASS |
| 24 | Recording failure and recording-start mutation | PASS |
| 25 | Mid-property mutation-then-error rollback | PASS |
| 26 | Mid-tag mutation-then-error rollback | PASS |
| 27 | Mid-attribute mutation-then-error rollback | PASS |
| 28 | Commit failure; exact false/zero/empty/absent restoration | PASS |
| 29 | Native Apply Undo and target identities | PASS |
| 30 | Native Redo; Project CRUD exact graph Undo/Redo | PASS |
| 31 | One-use, stale, copied and forged plans rejected | PASS |
| 32 | Root/scan/compatible/affected/write caps | PASS |
| 33 | Malformed/oversized/duplicate/cyclic/nested persisted data | PASS |
| 34 | No network/telemetry/runtime code added | PASS |
| 35 | Exact binary/source correspondence and historical versions | PASS |

Additional native cases cover Selection order, filter membership, revision changes,
detached preflight refusal, recording-start recipe/Selection changes, controller
revision/watchers, Project reentrant mutations and nonarchivable clones, independent
Project storage edits before Apply and during recording start through the live
repository callback, corrupt Local cache refusal and failed-save restoration, all
supported attribute codecs and exact Decal/Texture compatibility. Existing six
baseline specs, twenty workflow tests and two native release tests are retained.

Compilation of 36 Luau files: PASS. Exact-artifact package/source/hierarchy checks:
PASS. Native assertions are not inferred from either static check.

Excluded from this issue: GUI/DA redesign, screenshots/media, listing/outreach,
Creator Hub configuration, publication and canonical asset update. Studio restart
persistence is NON TESTED; in-session real settings persistence is covered above.
