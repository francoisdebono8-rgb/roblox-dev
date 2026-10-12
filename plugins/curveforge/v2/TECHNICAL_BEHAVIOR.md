# CurveForge 1.1.0 technical behavior

Issue #18 supersedes the earlier UI/relaunch interpretation of the V2 audit.
Candidate only. Canonical **90642263224333** and public **1.0.0** are unchanged.
No UI redesign, media, listing, outreach, Creator Hub or Studio publication work.
UI differences are limited to the existing-style roll toggle and candidate version.

## Frames and roll

Catmull-Rom position interpolation and 2-8 ordered BaseParts are preserved. Adjacent
sample tangents transport the preceding normal by their minimal axis-angle rotation,
then orthogonalize it. Query frames transport from the lower sample to the analytic
tangent; no per-query world-up/Z-up switch occurs. The initial reference keeps V1's
world-up preference. Frames are deterministic regardless of query order.

This is discrete parallel transport, not the fourth-order double-reflection method.
The algorithmic context is described in [Wang et al., rotation-minimizing frames](https://i.cs.hku.hk/GraphicsGroup/publications/pdf/Computation%20of%20rotation%20minimizing%20frames.pdf).
Native rotations use [CFrame](https://create.roblox.com/docs/reference/engine/datatypes/CFrame).
An exact reversal/cusp has no unique smooth tangent: the previous normal is retained
for a deterministic half-turn. This cannot turn a cusped path into a smooth one.

`ControlRoll=false` by default, including V1 metadata. Control rotations then do not
affect the plan. Horizontal planar orientation/source-offset semantics are retained;
steep/3D V1 frames deliberately lose their old threshold-induced roll jumps. This is
not a promise of identical old/new 3D output rotations after regeneration.

With `ControlRoll=true`, project each control's UpVector onto its tangent-normal
plane; unwrap successive signed angles by the shortest turn and interpolate them
with smoothstep in arc length between controls. A parallel guide retains the previous
angle (zero at the first control). Exactly opposite guides use a deterministic -pi
turn. Orientation guides do not change path positions. UpVectors cannot encode an
extra whole revolution; multi-turn twist and closed-loop holonomy are not supported.

Repeat tangent orientation uses these frames. `PreserveRotation=true` retains the
source rotation offset from the first frame; the same offset is saved/reloaded without
recalculation drift. `Orient=false` preserves source world rotation. PivotTo moves
clones without scaling; original sources are not modified.

## Adaptive sampling

Each Catmull-Rom span is converted to its equivalent cubic Bezier and subdivided by
de Casteljau. A leaf is accepted only when both control-point distances to its chord
are <= **0.005 studs** and its control-polygon excess length is <=
`max(1e-8, polygonLength * 0.00001)`. The polygon/chord length bracket bounds the
local length estimate; checking both controls avoids missing an S bend whose midpoint
lies on the chord. Path lookup linearly interpolates this arc-length polyline.

Cap: **8192 total samples**, **18 recursive levels per span**. Failure refuses the
plan before mutation; no silent degraded-quality fallback. Maximum path length stays
below 10000 studs and adjacent controls remain >=0.05 studs apart. Work is bounded.
Subdivisions and length sums use coordinates relative to the first control, avoiding
manufactured curvature from float32 precision far from the world origin. Original
control/end positions are retained; Roblox's world-coordinate quantization still
applies to output parts. Frame matrices are built from directions, not position+unit
direction subtraction at large coordinates.

Native fixtures enforce <=0.02-stud equal-arc position discrepancy against a
4096-subdivision/span reference and length discrepancy <=max(0.001 stud, 0.01%).
Actual repeated copies on the independent 3D fixture must have <=0.01-stud arc-step
error. These are measured regression tolerances, not universal promises at every
coordinate/scale. Straight spans use only their endpoints; curved paths may use more
samples than V1. No overall CPU/performance improvement is claimed.

## Cable and distribution

Deterministic continuity rule: chord-aligned solid cylinders share the same planned
endpoints, with a diameter-matched sphere centered at every interior endpoint. No
start/end sphere is added, preserving flat ends. Geometry tests require both cylinder
tips and shared joints within **0.001 stud** of their planned endpoints. Chords below
0.001 stud are rejected during planning, not after output allocation. There are no
independently approximated endpoints that can leave an accidental hole. Tight bends
can self-intersect; this is not a hollow/CAD extrusion or visual seam certification.
Diameter/material/color/Anchored/CanCollide/CastShadow semantics are unchanged.

Count mode produces exactly Count copies. Endpoints on uses 0 and full length;
off uses interior fractions `i/(Count+1)`. Spacing mode retains V1's fixed-spacing
interior copies; endpoints on adds both endpoints, so the last interval can be shorter
than Spacing. Endpoints off excludes both. Spacing does not rescale the entire series
to force the last interval to match, and never creates a duplicate endpoint.

`plan.estimates` exposes `pathLength`, `sampleCount`, `segmentCount`, `copyCount`,
`sourceInstanceCount`, `outputInstanceCount`. Counts include all repeated descendants
and clone roots; they exclude the containing Output Model and metadata. Cable output
count is `2 * segmentCount - 1`. Limits remain 512 segments, 500 copies, 5000 repeated
instances and 1000 source instances, enforced before project writes.

## Freshness, metadata and transactions

Collision-free typed snapshots (not string hashes) retain ordered control identities,
parents and relevant transforms; settings; source pivot; every source descendant's
identity/name/parent/Archivable state; BasePart relative CFrame/Size/PivotOffset and
basic appearance/physics flags; Model pivot/PrimaryPart/scale; ObjectValue references;
attributes and tags. Renaming a source child **does invalidate** Preview. New, removed,
reparented or replaced same-name descendants invalidate too. Rotation invalidates
controls only with roll on. Source rotation/pivot changes always invalidate Repeat.
This is not serialization of every possible property on every Roblox class.
Scripted sources are rejected; scripts are never hashed/evaluated.

Build/Regenerate checks freshness before allocation and again after acquiring the
native recording, protecting against reentrant changes. Stale plans refuse without
partial writes. Recording refusal/throw cleans detached output and metadata.
Commit failure restores the previous Output/data and cancels the recording. Native
Undo/Redo is used, not a custom stack. Controls/source cannot be inside the replaced
target, and unrelated siblings survive Regenerate.

Metadata **Version=2** adds typed `ControlRoll`; V1 is accepted with false, requiring
no manual migration. Next successful Regenerate writes V2. Duplicate/gapped control
references, unknown versions, malformed settings and invalid/nonfinite/translated
rotation offsets fail safely. The native migration tests generate actual V1 outputs
using the unchanged historical commercial binary, not fabricated V1 test metadata.
