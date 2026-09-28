# Issue #20 native technical matrix

The 41 rows below correspond exactly to issue #20. All PASS from the actual final
exact-binary gate: **52 tests PASS / 0 FAIL**, outer gate PASS, Studio
0.740.19.7400003 Edit mode. Candidate SHA256
`1ffab441b8ee88db2372e113776d2fb7cfdb5b890e8576cbae36ff378229fbec`.
[Sanitized native evidence](native-v12-technical.txt) and
[structured results](technical-1.2.0-results.json). No graphical acceptance claimed.

| # | Requirement | Native status |
|---|---|---|
| 1 | V1 load unchanged; old-engine parity; read-only load | PASS |
| 2 | Current schema roundtrip and V1 -> current -> reload | PASS |
| 3 | Future/invalid versions and malformed schemas rejected | PASS |
| 4 | Number rules | PASS |
| 5 | String choices | PASS |
| 6 | Boolean rules and false default | PASS |
| 7 | All eight added kinds captured | PASS |
| 8 | All eight kinds codec and Store roundtrip | PASS |
| 9 | All eight kinds missing-default repair | PASS |
| 10 | All eight kinds exact equality and different value | PASS |
| 11 | Vector2/Vector3 inclusive axis/magnitude bounds | PASS |
| 12 | Primary tag scope unchanged | PASS |
| 13 | Required tag finding and validation | PASS |
| 14 | Required tag additive repair | PASS |
| 15 | Forbidden tag finding | PASS |
| 16 | Forbidden tags never removed | PASS |
| 17 | Unrelated tags preserved | PASS |
| 18 | Wrong-type values preserved | PASS |
| 19 | Invalid existing values preserved | PASS |
| 20 | Missing required child; optional absence | PASS |
| 21 | Intermediate/leaf ambiguity and child limits/cache | PASS |
| 22 | Required/optional child wrong class | PASS |
| 23 | Hierarchy never auto-repaired | PASS |
| 24 | Exact subset and tamper resistance | PASS |
| 25 | Attribute/schema/version/scope/saved-token change stales | PASS |
| 26 | Required/forbidden tag change stales | PASS |
| 27 | Matching object added/removed/reparented stales | PASS |
| 28 | Required child change stales; work cap | PASS |
| 29 | Unrelated property/attribute/tag/name remains fresh | PASS |
| 30 | Measured 20k/20-tag complete-audit benchmark | PASS |
| 31 | 5000 targets accepted; 5001 refused | PASS |
| 32 | 2000 findings accepted; 2001 refused | PASS |
| 33 | Storage conflicts/concurrency; recording-opening race | PASS |
| 34 | Save rollback, new storage/entry/update; recording refusal | PASS |
| 35 | Delete rollback and native Undo/Redo | PASS |
| 36 | Repair rollback after attribute writes | PASS |
| 37 | Repair rollback after tag writes | PASS |
| 38 | Native typed attribute Undo/Redo for each added kind | PASS |
| 39 | Native required tag Undo/Redo | PASS |
| 40 | No network/telemetry/runtime enforcement | PASS |
| 41 | Exact candidate/source/package correspondence | PASS |

Separate static verification already passes reproducible bytes, exact five
production sources and absence of test/network payload. Public binaries and
historical QA files are retained unmodified.

Rows 36/37 include an injected post-setter readback failure immediately after the
first native write, before the second repair, plus commit failure after mixed
writes. They do not claim a real Roblox setter spontaneously failed. A separate
injected rollback-check error verifies that remaining journal entries are still
restored. Test-only assertion environments are always restored after protected
calls; no injection hook enters the commercial candidate.

Native benchmark: 20000 descendants, 20 tags, two warmups, seven iterations,
median full old audit **20.367583 ms** versus full candidate audit **0.171417 ms**.
Visits: old scope 20001, candidate 20, child 0. Fixture/machine-specific measurement.
