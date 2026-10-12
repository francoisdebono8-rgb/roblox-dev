# AccessForge V2 programme audit

2026-09-27; issue #15, design only. Canonical `127360597946823`, current 1.0.0.
Never use accidental duplicate `136358269001448` as a relaunch target.

## Real Studio path

Isolated copy of `release/scene/AccessForge-Media.rbxl`, adapted MIT hacker-tycoon
utility facility. Provenance: [SOURCE](../release/scene/SOURCE.md).
Selected FactoryStair, Edit Existing, changed width 7 to 8, Preview, Regenerate,
Confirm Regenerate. Preview showed 15 steps, rise 12, run 30 and 42 parts; native
assertion verified Width=8 on the regenerated assembly metadata.
Keyboard automation initially entered 87, corrected before Apply; not a parsing defect.
Switchback, Catwalk and native Undo/Redo were not rerun in this pass.
[Execution record](../../../docs/forge/v2/studio-audit-evidence.md).

## Most important friction

**P1: restored narrow docking hides whole modes and actions.**
At roughly 190 px wide, Switchback was cut off and Catwalk absent; lower controls were
out of view. Widening and removing adjacent dock panes was necessary. Users should not
need to know the plugin has hidden third-column controls to recover the interface.

Other reproduced issues:
- After changing width, Preview disappeared and Regenerate disabled, but the green
  "Preview ready" message and old metrics remained. The write safeguard worked; the
  state label is stale. Record as a V2 correction, not a new feature.
- The bottom action row jumps when the preview is removed/restored.
- Preview shows a small isolated assembly, not whether the new width fits the platform.
- Start: Start / End: End tells little about which marker to locate. Edit Existing works
  once discovered and preserves explicit control of replacement.

## Demand, substitutes and reviews

[Quick Stairs](https://create.roblox.com/store/asset/6917372104), updated January 2026,
has 90%/400+ votes, 22 reviews and Get Plugin; it explicitly points to free Redupe.
[Stairs Creator](https://create.roblox.com/store/asset/110359758215433) already advertises
click endpoints, rails and live preview. A February 2026 visible review complains about
repositioning endpoints; not independently reproduced. Ordinary stairs are well served.
The industrial combined assembly/re-edit workflow is the plausible differentiator,
not automatic steps, rail toggles or a generic staircase button.
No strong fresh Studio Features/Building Support outreach target was established in
the current bounded search. Own public reviews: zero. Catwalk rank 1/2 is not demand proof.

## Proposed scope, in order

| Change | Evidence / value | Frequency / confidence |
|---|---|---|
| Responsive mode/navigation layout, fixed actions, accurate stale-preview state | Reproduced missing modes and stale success text | Every constrained dock/parameter edit; high |
| Explicit start/end locating and reversible endpoint assignment | Marker ambiguity; competitor review on endpoint repositioning | Frequent fitting work; medium-high |
| Contextual assembly preview showing platform relationship, with clear replacement target | Real factory landing width cannot be inspected in isolated view | Frequent fitting work; high |

No extra generator is needed for this scope. Reuse the established Straight/Switchback/
Catwalk engine and saved metadata. Keep industrial presentation, without implying that
generated structures satisfy real-world engineering or accessibility codes.

## Reject / defer

Spiral stairs, ladders, whole-building generation, terrain/roads, arbitrary decorative
styles and automatic code-compliance certification. Do not add a feature because a
competitor has it; the current paid reason is a coherent editable industrial assembly.

## Acceptance target for a later release

All modes and essential actions reachable at 240/320/400 px widths. Parameter editing
immediately marks Preview stale, with stable layout. Fit the same facility stair to
its landing, inspect proposed geometry before replacement, then verify native Undo/Redo
and user-added-object protection. Rerun Switchback/Catwalk before claiming full release PASS.
