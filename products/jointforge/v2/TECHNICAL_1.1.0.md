# JointForge 1.1.0 technical candidate

Issue #22. Public version remains 1.0.0 and canonical asset 103958912217728 is unchanged.
This is an unpublished local candidate. No publication, listing, media or art-direction work.
The nine existing classes remain the complete supported set.

## Exact plans and graph

`Planner.preview(workspace, request)` issues a recursively frozen plan. Its request,
ordered operations, endpoint/attachment identities, before-state, names, accepted native
field values and diagnostics are immutable. A private weak registry owns consumption
and invalidation. Copies and fabricated tables cannot apply. Use `Planner.invalidate(plan)`
when inputs change; never write fields on a plan.

Apply checks freshness before native History and again immediately after
`TryBeginRecording`. A recording attempt consumes the plan, including refusal, failure
and rollback. Re-preview to retry. Missing removal confirmation does not consume it.

Preview builds one bounded hierarchy/graph index. Physical connected components and
direct endpoint pairs are indexed once, including available physical endpoints from
unsupported classes conservatively. NoCollision edges do not form physical paths.
Disabled physical connections still block duplicates. Identity uses Instances, not paths
or names. Duplicate sibling names remain distinct.

Freshness captures requested endpoints and their physical components; incident edges;
selected joints; attachment identities/local and world frames; relevant native fields;
Motor6D.Transform; ancestor identity chains; removal child content; and occupied child
names at planned creation parents. Exact CFrame components are compared before writes.
Unrelated distant graph changes stay fresh. A new edge touching the relevant component,
an ancestor move, or a planned name collision requires a new Preview.

Diagnostics distinguish direct duplicates, indirect paths, missing/same endpoints,
invalid direct attachment ownership, both-anchored endpoints, hinge-axis mismatch,
separated pivots and inspect-only classes. There is no automatic repair.

## Explicit endpoint reassignment

Part-based classes accept:

```lua
{ kind = "reassign", joint = joint, endpoint0 = newPart0, endpoint1 = newPart1 }
```

Either explicit endpoint may be omitted to retain the old one. At least one must be
supplied, and both resolved endpoints must be valid, distinct parts in Workspace.
The existing joint is excluded only from its own conflict check. Other existing
physical paths and duplicate NoCollision edges remain blocking.

Attachment classes accept an existing direct-child Attachment, or an explicit
creation description:

```lua
{
    kind = "reassign", joint = constraint,
    endpoint1 = { create = true, part = newPart, worldCFrame = chosenWorldCFrame },
}
```

A BasePart alone never guesses a replacement attachment. Missing old endpoints can
only be repaired by explicit valid input. Existing attachments are never moved or
deleted by reassignment. Existing unrelated fields, including Length/FreeLength,
remain unchanged; only newly created constraints initialize lengths from distance.

The default `poseMode = "preserve"` retains world poses. Weld/Motor6D keep C1 and
derive C0 from the new parts' world frames. Nonidentity Motor6D.Transform is explicitly
refused in preserve mode because its deferred native application needs further proof.
This narrow case is deferred, not claimed supported. Explicit `poseMode = "raw"`
retains C0/C1/Transform and warns that native assembly motion may result. Direct
C0/C1 edits and identity resets also deliberately use raw-frame semantics.

The existing Inspect workflow has local endpoint assignment and Preview controls.
Attachment Preview identifies the actual replacement attachment or the exact new
attachment parent/name. No layout or visual programme is implemented.

## Native fields, attachment creation and transactions

Every exposed editable field is validated on a detached native instance. Submitted
values must have the exact native type; enums must belong to the correct EnumType;
numbers and CFrames must be finite. Explicit numeric bounds prevent tiny clamps from
hiding inside floating-point tolerance. Joint cross-field limits must be ordered.
Finite-to-infinite conversion rejects. Native infinite defaults in unedited fields
are preserved.

Postwrite readback checks every editable field, not only submitted changes. Floating
point tolerance applies only to native numeric/CFrame representation after writes,
never to before-state freshness. Field assignment order expands bounds before moving
the paired lower limit when necessary.

New Hinge/BallSocket attachment pivots meet at the existing chosen attachment, or at
the midpoint with Part0 orientation when neither attachment exists. Rope/Rod/Spring
new attachments start at part world frames. Planned local and world frames are verified.
Rope requires distance >= 0.001 studs, Rod >= 0.2, Spring >= 0.1. Shorter distances
refuse instead of silently accepting a native clamp.

Names are reserved at Preview with stable `_2`, `_3` suffixes. A failed batch blocks
the complete plan. Static creates WeldConstraint; Moving creates Motor6D with world
pose preserved. Root-as-child, duplicate entries and sparse arrays reject.

The transaction journals before every setter, including parenting, so a setter that
mutates and then throws has a restoration entry. Failures restore existing fields,
endpoints, parents and affected world poses and destroy only newly created instances.
Rollback continues through individual restoration errors and reports them. No external
recording-open mutation is overwritten when no transaction write has begun.

Remove needs explicit confirmation and exact selected supported joint identities.
Children, duplicates and mixed supported/unsupported selections refuse wholly.
Removal detaches the same joint instance; it never destroys it after commit and never
removes attachments. Native Undo/Redo retains exact instance identity.

## Conservative limits

| Limit | Maximum |
| --- | ---: |
| Hierarchy instances visited | 20,000 |
| BasePart nodes | 8,000 |
| Joints/constraints scanned and indexed | 8,000 |
| Nodes in a physical connected-component traversal | 4,000 |
| Input batch entries | 256 |
| Planned operations: joint action plus each new attachment | 128 |
| Input removal selections | 256 |
| Recursive request values | 8,192 |
| Request table depth | 16 |
| Relevant hierarchy depth | 128 |

The operation cap also limits an ordinary batch/removal to 128 joint actions.
Limits are checked independently; overflow returns an error and no executable partial
plan. The hierarchy walker uses bounded child enumeration, never whole-Workspace
`GetDescendants()`. A single native `GetChildren()` necessarily materializes its immediate
child list before its size can be rejected; traversal never continues past the budget.
Inspector selection is additionally capped at 8,000 inputs.

## Build and exact-artifact QA

From the repository root:

```sh
python3 products/jointforge/tools/verify_candidate.py --build --rojo /private/tmp/jointforge-tools/rojo/rojo
python3 products/jointforge/tests/build_technical_gate.py --rojo /private/tmp/jointforge-tools/rojo/rojo --output-dir /private/tmp/JointForge22QA
```

The candidate verifier rebuilds reproducible bytes and imports the final binary to
check all six production Sources and the eight-item allowlist. V1's SHA256 must remain
`24f43cf04c7d4e8cf92310b3c725f827e36b1ea22d9806e20325a4af4d2633bd`.

The opt-in QA plugin imports exact candidate and V1 binaries. Only Main.Disabled changes
in the embedded copies; Sources and original binary bytes remain unchanged. The only
enabled Script is the separate QA runner. It requires an empty, local, nonrunning
place with Workspace attribute `JointForgeTechnicalGate=true`.

The coordinator owns Studio execution and plugin installation. The suite tests native
Undo/Redo with a baseline waypoint before each recording. Failure paths use explicitly
labelled QA-only History adapters and environment injection after real native setters.
Those assertions are not claims that Studio itself experienced an actual setter or
commit failure. The native View smoke uses real controls and QA-captured callbacks,
not screenshot or visual acceptance.

The sparse benchmark compares full Preview against the embedded public V1 on the
same fixture: 5,833 descendants, 1,000 distant edges, 32 entries; two warmups and five
measured repetitions. Report measured medians only, with no generalized speed claim.

Collect a completed exact-artifact run with:

```sh
python3 products/jointforge/tests/collect_technical_evidence.py /absolute/path/to/versioned_Studio.log
```

Native status belongs to `tests/TECHNICAL_MATRIX_1.1.0.md` and the collected results,
not to a successful compile/build. Publication and all later UI/marketing work remain
outside this issue.
