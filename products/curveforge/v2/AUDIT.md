# CurveForge V2 programme audit

2026-09-27; issue #15, design only. Canonical `90642263224333`, current 1.0.0.

## Real Studio path

MIT RavenRock from Nexus-Battles, copy of `release/scene/CurveForge-Scenes.rbxl`.
Selected the saved cable, clicked Edit Selected CurveForge Model, loaded four points,
changed to the blue swatch, inspected the updated Preview and clicked Regenerate.
Native assertion verified blue on all 125 output parts. Successful existing-output
workflow, not a rerun of the earlier full Cable/Repeat/Undo QA. Native Undo/Redo,
Repeat and new-path Build were not reexecuted in this audit.
[Shared execution record](../../../docs/v2/studio-audit-evidence.md).

## Most important friction

**P1: the isolated Preview is too weak to judge the actual edit in the environment.**
The dark cable was barely visible against the dark ViewportFrame. The view contains
only the cable, so pole alignment and clearance cannot be judged there. The existing
world output remains visible, but is not the proposed regenerated result.

Other observations:
- Edit Existing is below the new path, settings and Preview sections, even when an
  existing output is selected. It should be a first-class entry, not a footer discovery.
- Four control rows each use Up/Down/Remove text buttons; the point name gets little
  room. Moving/remapping points needs stronger order/selection feedback.
- Preview/Regenerate and success feedback shift vertically when preview content vanishes.
- The initial short dock requires substantial scrolling. `Modules/View.luau` does
  preserve CanvasPosition, a behavior to retain while improving layout.

## Demand, substitutes and reviews

[Pattern repetition](https://devforum.roblox.com/t/studio-feature-or-plugin-that-repeats-a-pattern-on-scaling-or-resizing/4095587)
has a genuine building need, but also existing Ropeater/Archimedes recommendations.
[Pipe Placer](https://create.roblox.com/store/asset/5027226818) already offers angle
snapping and material/size control, with 96%/100+ votes and 14 reviews. It and
[CDS Cabler](https://create.roblox.com/store/asset/378960861) expose Get Plugin rather
than a USD purchase button. Native duplication also covers simple straight arrays.
No fresh Studio Features request uniquely validates expanding CurveForge's geometry types.
Own reviews: zero visible. Cable search rank 2 of 3 is visibility, not sales evidence.

## Proposed scope, in order

| Change | Evidence / value | Frequency / confidence |
|---|---|---|
| Read-only contextual world preview with clear proposed-vs-existing distinction; usable contrast in fallback mini-view | Pole/cable scene cannot be judged in the current isolated dark preview | Every spatial edit; high |
| Top-level Edit selected and ordered point selection/locating with concise icon controls | Existing-output workflow and current four-row form | Frequent re-editing; high |
| Preserve draft/scroll and stable Preview/Regenerate feedback; expose count/spacing clearly for repeated models | Repeated-pattern request plus observed layout movement | Frequent iteration; medium-high |

Contextual preview must not introduce persistent geometry, history pollution or output
selection conflicts. Define the technical approach in implementation and verify it in
Studio; this document does not promise an untested API. Keep current bounded paths.

## Reject / defer

Terrain sculpting/roads, mesh extrusion, hollow pipes, automatic obstacle routing,
terrain snapping, arbitrary spline frameworks, procedural city generation and marketplace
asset libraries. [Contour Terrain discussion](https://devforum.roblox.com/t/plugin-contour-terrain-v121-30-off-draw-extend-roads-decorate/4875253)
is a warning about competitive/native overlap, not a reason to enter that category.

## Acceptance target for a later release

Judge a cable against both poles before Apply; identify/move a numbered control, re-preview,
regenerate the same output, verify original source preservation and native Undo/Redo.
Also exercise Repeat's spacing/count/orientation on the saved lamp source. No fabricated
terrain snapping, hollow geometry or automatic routing in media/copy.
