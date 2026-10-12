# CurveForge / Creator Store copy

Prepared 2026-10-03 for #39. Not uploaded. Status: **READY EXCEPT MEDIA**.

## Title
CurveForge - Editable Cables & Repeated Models

## One-line promise
Preview cables or your own repeated model along a path, then move the path and regenerate.

## Short description
Turn ordered control points into Cable or Repeat output. Compare Existing/Proposed with nearby context before regenerating your assembly.

## Full description
Your layout changed. Your cable or repeated props should follow.

CurveForge builds segmented cables or copies of your own model along an editable path. Order 2-8 control parts, choose Cable or Repeat, and inspect the proposed result before building. Repeat supports spacing or count and orientation controls.

Later, edit the path and compare Existing with Proposed output alongside a bounded snapshot of nearby geometry. Regenerate the managed output with Studio Undo. Keep the original controls and source so the assembly stays editable.

Free rope and array tools are excellent for simple jobs. CurveForge puts custom-model repetition and cable generation in the same reviewed path-edit/regenerate workflow.

Open paths only. Output is parts/models, not simulated rope or a continuous pipe mesh. Tight bends can intersect; preview is not collision validation. Sources and output sizes are bounded. No network requests, telemetry or external account.

## Search terms
cable builder, repeat model, editable path, control points, curved props, spacing, regenerate, procedural placement, Roblox Studio

## Privacy and exact limits
- No HTTP, analytics, remote service or external account. Geometry and editable `CurveForgeData` metadata stay in the place; collaborators can inspect them. Metadata is data, not executable code.
- 2-8 ordered BasePart controls, open paths. Cable is segmented Parts; no rope physics, mesh deformation or closed-loop/pathfinding promise.
- Maximum 512 cable segments, 500 copies, 5,000 repeated instances; source at most 1,000 instances. Repeat source must contain parts, be Archivable and have no scripts or external joint/object references.
- Bounded adaptive sampling: 8,192 samples, depth 18. Oversized/degenerate input is refused. Geometry can self-intersect at tight turns.
- Nearby preview is a limited snapshot of supported geometry, not a full scene clone or collision test. Small views can occlude point labels; the ordered Path list remains the alternative.
- Regenerate replaces owned Output and CurveForgeData. Manual edits inside replaced output are not retained; user-added siblings are preserved. Keep source and controls in the same place. Stale checks are not a collaborative-lock guarantee.

## Version and asset
Internal **1.1.0** / **Forge Studio 0.2.5**; canonical **90642263224333**. The new candidate is not proof that the public asset has been updated. [Binary handoff](LAUNCH_CHECKLIST.md).

## Current substitutes and price
Recommendation: **4.99 USD**, unvalidated one-time launch hypothesis. Do not increase it merely because two output modes exist.

Live public Store inspection, 2026-10-03:

| Substitute | Observed offer | Positioning consequence |
| --- | --- | --- |
| [Stravant RopeTool](https://create.roblox.com/store/asset/109225618409920/Stravant-RopeTool) | Free acquisition, updated Aug 3, 2026; editable segmented ropes/wires via dragger handles | Current free competition, not an abandoned tool. Cable creation alone is not a paid moat. |
| [Stravant Redupe](https://create.roblox.com/store/asset/73064993918325/Stravant-Redupe-REpeated-DUPElicate) | Free, updated Feb 2, 2026; geometric arrays, handles, spacing controls, open source | Generic repetition also has a strong free substitute. No claim that CurveForge invented editable arrays. |

Inference, not competitor benchmark: the paid wedge is one explicit path/control/source workflow with contextual Existing/Proposed review and regeneration of a custom repeated model. Buyers needing only simple ropes or arrays may reasonably choose the free tools. A higher price lacks conversion evidence; the minimum paid entry is defensible only if the Repeat/regeneration media makes this difference obvious. Unadvertised competitor behavior is unknown.

## Forbidden claims
No exclusive cable/array capability, terrain/collision intelligence, continuous mesh pipes, physical rope, arbitrary scripted sources, guaranteed no overlap, unlimited output or invented adoption/performance/time-saving figures.
