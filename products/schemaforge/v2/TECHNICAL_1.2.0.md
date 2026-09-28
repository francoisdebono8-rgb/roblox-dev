# SchemaForge 1.2.0 technical candidate

Historical functional baseline for issue #20. Its hashes and results below are
preserved as executed. Issue #23 subsequently changed View only; the current binary
and its fresh 53-test native regression are recorded in
[UI release status](../ui/RELEASE_STATUS.md) and `../dist/candidate-1.2.0.json`.

Issue [#20](https://github.com/francoisdebono8-rgb/roblox-dev/issues/20).
Unpublished candidate. Public 1.1.0 binary, public manifest, release records and
media remain historical and unchanged. Canonical asset 84085408748744 is untouched.

Candidate: `../dist/SchemaForge-v1.2.0.rbxm`, SHA256
`1ffab441b8ee88db2372e113776d2fb7cfdb5b890e8576cbae36ff378229fbec`.
Reproducible source hashes: `../dist/candidate-1.2.0.json`.

## Contract and migration

Format 2 adds Vector2, Vector3, Color3, CFrame, UDim, UDim2, BrickColor and
NumberRange. Existing number/string/boolean rules retain their behavior. A stored
format-1 contract loads without any storage write; explicit Save writes format 2
under the same folder and entry, preserving values, flags, choices, notes and child
paths. The storage folder marker remains 1: it describes the container, not the
individual contract format. The old plugin cannot read format 2; native Undo of
the migration restores the original JSON. No manual migration is required.
Malformed shapes, unknown schema/rule keys and future versions are refused at
load/validation, before copying or writing. Format 1 cannot activate format-2 tag,
typed or optional-child rules; adding those rules requires an explicit format-2
draft/save. The authored V1 format is preserved, including inactive defaults.

Typed defaults and optional `exact` constraints are serialized as `{kind,
components}` with decimal strings containing 17 significant digits. Component
orders: Vector2 X/Y; Vector3 X/Y/Z; Color3 R/G/B; CFrame position X/Y/Z followed by
the nine row-major rotation components; UDim scale/offset; UDim2 X scale/offset,
Y scale/offset; BrickColor numeric palette ID; NumberRange min/max. Decode rejects
wrong shapes, non-finite values and components which the native constructor would
round or clamp. Captured native components therefore round-trip exactly. Equality
is exact component equality, with no tolerance widening numeric/scalar semantics.
User-entered decimal components use the native datatype's numeric representation.

Reference capture retains default values but does not enable missing-value repair
without the explicit flag. The existing rule controls expose the new types,
component defaults/exact values, vector bounds and tag lists with local wiring;
layout, styling and design direction are unchanged.

Vector2/Vector3 accept partial `axisMin` / `axisMax` dictionaries keyed by X/Y/Z,
and inclusive nonnegative `magnitudeMin` / `magnitudeMax`. No predicates or implicit
coercion. `requiredTags` and `forbiddenTags` each permit at most 16 distinct names;
overlaps and the primary target tag in either list are rejected. The target tag
remains the scope key. Tag rules apply to every matching object, including a
wrong-class target; attribute/child rules remain gated by expected class.

Only missing required attributes with a valid saved default and missing required
tags have repairs. Forbidden tags, invalid/wrong-type attributes and hierarchy
findings are diagnostic. Existing unrelated tags and user hierarchy are preserved.
Optional children accept absence; a present ambiguous path or wrong class is still
a finding. Duplicate names at every path segment are checked.

## Freshness and transactions

Preview retains the exact original findings and subset. Apply validates the source
schema/version, roots, matching object identities/ancestry, relevant attribute
presence/values, required/forbidden tags and required-path child identities before
recording and again immediately after recording opens. Matching objects entering,
leaving or moving inside scope invalidate the plan. Required-path rename or
replacement invalidates it. Unread attributes/tags, unrelated properties/children
and target/ancestor names do not invalidate it. Session identities distinguish
duplicate-named objects; findings and candidates have deterministic ordering.
Contracts returned by Store.load also bind to the original storage entry/folder,
name, marker and exact saved token. Separate edits, entry replacement or duplicate
storage invalidate direct engine plans, including changes made while the history
recording opens; this is not dependent on the View's token check.

Repairs read back native state immediately and at the end of the transaction.
Rollback attempts every journal entry in reverse order and reports any restoration
failure. A stale plan makes no repairs. A failure cancels history after restoration.
Native QA includes deterministic injected failures at the readback assertion
immediately after the first attribute write and first tag write, before the next
planned operation. This proves journal rollback of real native state following a
post-setter failure; it does not claim that Roblox's valid native setter itself
failed. QA temporarily substitutes the isolated function's assertion environment,
restores it after the protected call, and leaves candidate source untouched. A
separate injected rollback-check error proves every remaining entry is attempted.
Store save/delete re-read folder/entry identity and the expected token after
TryBeginRecording; a concurrent external writer is preserved. Duplicate folders,
wrong marker/class, duplicate entry names and conflicting entry types fail closed.
Save/delete recording refusal and commit failures preserve prior storage.

## Limits and Performance

The normal scan calls CollectionService:GetTagged and filters candidates against
validated roots and supported project services. It never discovers targets by
walking untagged descendants. The fallback is the prior bounded scope walk and is
used only if GetTagged throws, not when it returns zero matches. Native Edit mode
exposes descendants of DataModel through GetTagged; detached roots are rejected.

Limits: 32 fields, 32 child paths, 8 segments per path, 16 tags per tag-rule list,
5000 matching objects, 2000 findings, 5000 roots, 100000 candidate inspections and
100000 cached child inspections per scan. The fallback retains the 100000-instance
scope-walk cap. With the candidate-first path, unvisited untagged descendants do
not consume the inspection budget. Each child parent is indexed only once per
scan across all matching objects/rules. Schema payloads are capped at 64000 bytes,
4096 table entries and 16 nesting levels before copying/encoding; cycles fail.

The native benchmark uses a fixed 20000-descendant scope with 20 targets, two
warmups, seven repetitions and the median of each complete audit. It compares the
actual imported public 1.1.0 Engine to the candidate Engine, not discovery-only
timings against a full audit. It also reports 20001 old visited scope objects,
20 candidate visits and bounded child visits. Timing results are recorded only
after actual native execution.

Final native Studio 0.740.19.7400003 measurement: old complete-audit median
**20.367583 ms**, candidate complete-audit median **0.171417 ms**, with zero child
inspections for this sparse empty-rule contract. These are measurements of this
fixture and machine, not a promise for every project or dense contract.

## Verification

Compilation and exact-artifact packaging: **PASS**. Native final candidate:
**52 PASS / 0 FAIL**, all **41/41** issue matrix rows PASS, outer technical gate
PASS, no asynchronous candidate exception. Executed by the main coordinator in
Studio 0.740.19.7400003 Edit mode on 2026-09-27 at 23:58 UTC (2026-09-28 Paris).
[Final native evidence](../tests/native-v12-technical.txt),
[machine-readable results](../tests/technical-1.2.0-results.json),
[41-row matrix](../tests/TECHNICAL_MATRIX_1.2.0.md).

The final run includes all eight datatypes through capture/codec/Store/repair and
native Undo/Redo, mixed attribute/tag rollback, independent saved-contract edits,
recording-opening races, work caps and real DockWidget mount/text-edit smoke.
The DockWidget checks are non-graphical control/validation assertions. No visual
quality, screenshot, layout polish or GUI walkthrough acceptance is claimed.

Earlier executed runs are retained as historical evidence only:
[46-case initial run](../tests/native-v12-initial.txt), candidate `0a5b3d65...`,
and [50-case expanded run](../tests/native-v12-expanded.txt), candidate
`5579b212...`. Neither substitutes for the final `1ffab441...` run.

```sh
python3 products/schemaforge/tools/verify_candidate.py --rojo /private/tmp/jointforge-tools/rojo/rojo --build
python3 products/schemaforge/tests/build_technical_gate.py --rojo /private/tmp/jointforge-tools/rojo/rojo --output-dir /tmp/SchemaForge20QA
```

The main coordinator alone installs the generated `SchemaForgeTechnicalGate.rbxm`
as a local plugin and opens `SchemaForge20QA.rbxl` in Edit mode. The runner requires
the explicit Workspace opt-in attribute, PlaceId 0 and empty project services.
It imports the exact commercial candidate binary, checks its five sources against
the worktree, disables commercial Main scripts, and adds a separate QA runner.
No test code enters `dist/SchemaForge-v1.2.0.rbxm`.

```sh
python3 products/schemaforge/tests/collect_technical_evidence.py /absolute/path/to/versioned_Studio.log
```

The collector accepts only a complete successful run of the current candidate hash
and all 41 matrix rows. It retains product-prefixed output only and records native
results/benchmark separately from historical 1.1.0 evidence.

API references, checked 2026-09-28:
[Instance attributes](https://create.roblox.com/docs/studio/properties#instance-attributes),
[CollectionService.GetTagged](https://create.roblox.com/docs/reference/engine/classes/CollectionService#GetTagged).
An independent Studio 0.740 datatype probe confirmed Set/Get, Clone and Undo/Redo
for all eight types; the candidate suite independently tests codec, Store, repair
and native Undo/Redo. Probe support alone is not candidate acceptance.

Deferred: broader Roblox datatypes, generalized hierarchy constraints, automatic
hierarchy repair, inferred schemas and runtime enforcement. UI/DA/media/listing,
outreach and publication remain outside this issue.
