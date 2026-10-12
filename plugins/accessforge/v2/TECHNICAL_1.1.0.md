# AccessForge technical candidate 1.1.0

Issue #21; technical changes only. The public 1.0.0 binary and manifest remain
unchanged. No Creator Store operation, publication, price or distribution change
is part of this work. The canonical and duplicate assets are not touched.

## Execution contract

`Geometry.plan` returns recursively frozen normalized settings, exact Part
specifications, warnings, diagnostics and metrics. `Engine.plan` adds marker,
target, output, metadata and ownership identities and issues that frozen object
through a private weak-key registry. A copied table, standalone geometry plan,
forged object or already attempted plan cannot be applied.

`Engine.output(plan)` creates a detached viewport model without consuming the
issued plan or writing Workspace. It checks freshness first. `Engine.apply`
consumes the plan on its first attempt, including refusal or rollback; Preview
again before retrying. The original mutable settings table is retained privately
and compared with the frozen settings so direct API changes invalidate a plan.
The existing View invalidates its preview on control changes and edits a copy of
loaded immutable settings. The View changes are limited to that editable copy
and the candidate's 1.1 version label.

Freshness is checked before allocation and again after `TryBeginRecording`:

- exact marker CFrames and the entire ancestry chain to Workspace;
- normalized settings, including mode;
- assembly/output/group/data identities and metadata attributes, references,
  children, registry order, count, tags and generated identities;
- owned Part parent, name, dimensions, CFrame, appearance, physics properties,
  surface types, tags, attributes and child identities;
- target/output PrimaryPart and relevant structural attributes.

Exact before-state comparisons never use native write tolerances. Unrelated
Workspace objects and ordinary user-added siblings under assembly/output/groups
do not stale a plan. Reserved-name collisions do: duplicate Generated,
AccessForgeData or required group names cannot be interpreted safely.

## Solver and geometry

Every count from 2 through 256 is considered without allocating Instances.
A feasible count has actual riser height at least `max(0.1, Thickness)` and no
greater than `RiserHeight`. With rails, height must exceed twice the actual
riser plus 0.2. Treads are 0.5 through 40 studs deep.

Straight chooses the feasible count minimizing absolute distance of actual
tread depth from the requested TreadDepth. Equal scores prefer fewer steps.
This fixes shallow, long runs that V1 refused by choosing too many tiny risers.

Switchback retains V1's minimum feasible step count, split floor/ceil across the
two flights. Both flights have equal horizontal length, with the upper flight
exactly matching target tread depth. For odd counts the lower flight has one
fewer tread, so its depth is `ceil(n/2)/floor(n/2) * TreadDepth`. This explicit
compatibility tradeoff preserves the footprint and landing elevation of existing
V1 switchbacks instead of adding a step solely to equalize tread depths. If the
initial count fails rail/thickness/depth limits, a later feasible count is used.

The final tread top is End.Y. A Straight top landing begins at End and shares
that elevation. The Switchback landing is at Start.Y plus the lower flight's
step count times the common actual riser. Catwalk retains the inclusive 0.01
stud endpoint tolerance and projects End to Start elevation, with a warning
when projection occurs. The tolerance uses the actual native marker positions.

Frames are constructed at the origin and translated, avoiding loss of direction
when a unit vector is added to large world positions. Input positions and planned
centers stay within the existing 20000-stud radial bound; input horizontal spans
remain 0.5 through 1000; rise remains 0.2 through 500. Generated size magnitude
remains below 2048 and every dimension is at least 0.05.

Preflight rejects degenerate beams, inverted/overlapping tread dimensions,
impossible rail posts, non-finite frames, invalid support floor ordering and
switchback flight/landing conflicts. Switchback requires entrance separation at
least Width + 0.5 and at most Width + 30, with landing depth at least Width/2.
These analytic restrictions separate flights and their shared landing; intentional
rail/stringer connections are not reported as collisions. Planned names within
each group are unique, including supports and stringers. The complete specification
list gives the exact generated Part count, capped at 1000 before history opens.

Metrics expose mode, rise, endpoint horizontal run, total flight path run, step
count, actual riser/tread depths, landing/rail-segment/rail-post/support counts
and total Part count. Diagnostics describe the completed preflight checks.

## Metadata and transaction safety

V1 metadata loads read-only, including its valid duplicate Part display names.
Registry identities are contiguous ordered numeric ObjectValue names, not Part
display names. Nil, duplicate, missing, renamed, reordered or moved references
refuse safely. Generated objects outside the registry also make ownership
ambiguous. User children inside an owned Part prevent regeneration.

Regeneration automatically writes Version 2 metadata with OwnedCount, per-Part
AccessForgeIndex, and each registry reference's expected Group. Output and group
Instances remain the same; only registered Parts and metadata are replaced.
User-added siblings at every structural level survive. Unknown metadata children
are refused so regeneration cannot delete user data implicitly.

Part allocation and setter readback happen detached before history starts.
Native readback allows small storage tolerances (size 0.002, position 0.003,
rotation 0.00001, color 1/255); these do not weaken freshness checks. Parent
changes are journaled before each setter and checked immediately after. Failure
restores every journal entry in reverse order, attempts recording cancellation,
cleans candidate objects and reports restoration/cancellation errors. Old Parts
and data are deliberately left detached after Commit: native Undo requires their
original identities. There is no custom undo stack.

New Markers validates finite bounded positions and known modes, allocates a
detached folder, and cleans it on recording refusal, recording exception or
commit failure. Successful creation uses one native recording.

## Deferred

Optional Start-marker orientation is deferred. Endpoint positions plus ReturnSide
already define unambiguous frames for the existing families; adding another guide
would change saved fitting semantics without a required use case. Marker rotation
still invalidates an issued plan conservatively. Environment obstruction queries
are deferred; no environmental object is queried for deletion or moved. Geometry
preflight is not code compliance or a guarantee of navigability.

## Validation

Use [TECHNICAL_MATRIX_1.1.0.md](../tests/TECHNICAL_MATRIX_1.1.0.md) for exact-artifact
commands and native status. Compilation and deterministic packaging alone do not
establish native transaction or V1 compatibility PASS.

The coordinator's final native run on 2026-09-28, Studio 0.740.19.7400003, passed
55 cases and all 44 matrix rows on candidate SHA256
`484faabbfa9f8b02717a537aeee46c87e26861b83f8a66adadade112a5d89959`.
This includes three V1 migrations, native Build/Regenerate/New Markers histories,
six mid-regeneration failure positions and commit-failure rollback. The sanitized
collector verified both binary SHAs and the outer gate's final PASS.
