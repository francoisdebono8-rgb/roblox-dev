# JointForge V2 programme audit

2026-09-27; issue #15, design only. Canonical `103958912217728`, current 1.0.0.

## Real Studio path

MIT TheDepths from Nexus-Battles, isolated copy of `release/scene/JointForge-Media.rbxl`.
Assigned two existing Arch BaseParts using the real Part0/Part1 buttons, Preview, Apply.
The initial same-part setup was correctly blocked. The corrected pair showed an anchored
warning, then created one WeldConstraint; native assertion checked exact endpoint references.
The scene contained 373 BaseParts at inspection. This is a connection workflow, not a
claim that welding already-anchored scenery adds gameplay value. No physics test run.
[Execution limits](../../../docs/v2/studio-audit-evidence.md): no Batch, Inspect edits,
removal or native Undo/Redo rerun in this pass. Opening Inspect alone is not an Inspect PASS.

## Most important friction

**P1: textual endpoint identity is ambiguous in a real repeated hierarchy.**
Two different parts both displayed `Workspace.Environment.Arena.Landscape.Arch.Part`.
The Preview repeats that same string on both sides, so a novice cannot confidently
distinguish the planned connection without going back to selection. Existing Select Part
buttons help, but do not communicate both endpoints together in context.

Other observations:
- Error display includes a raw plugin module/line prefix before "Part0 and Part1 must
  be different". Correct safeguard, poor user-facing recovery presentation.
- Initial narrow/short dock leaves Part1 and Preview below the fold; sequential assignment
  is easy to lose track of. At a wider dock the three workflows become understandable.
- Generic SELECT > TYPE > PREVIEW > APPLY label remains on Inspect, which has a different task.
- Anchored warning is useful and should stay; do not auto-unanchor to make a demo move.

## Demand, substitutes and reviews

[Duplicated weld failures](https://devforum.roblox.com/t/welds-not-working/2628030)
support endpoint diagnostics. [Efficient welding](https://devforum.roblox.com/t/looking-for-efficient-way-to-weld-parts-together/2863082)
also shows the counterargument: native Create Constraints is a valid solution.
[Joint Editor](https://create.roblox.com/store/asset/134658752694624), updated February
2026, offers root-based creation and pivot/connected-part editing without a USD price.
It has 8 reviews and 50%/10+ votes, not proof our alternative is preferred.
[Tool joint types](https://devforum.roblox.com/t/adding-joint-types-to-tools/4352889)
is runtime Engine Features demand: not a complete fit for a Studio assembly plugin.
Own product has zero visible reviews; no fresh Studio Features gap was established.

## Proposed scope, in order

| Change | Evidence / value | Frequency / confidence |
|---|---|---|
| Distinct Part0/Part1 context markers and frame/locate actions; show which endpoint is being assigned | Same-path pair reproduced in TheDepths | Frequent duplicated assemblies; high |
| Compact connection findings with broken/conflict filters and actionable endpoint recovery | Existing wrong-endpoint support request; current Inspect offers text lists | Frequent for maintenance, not simple welding; medium |
| Human-readable errors and stable Preview/action area at narrow widths | Real rejection and clipped first-use form | Every invalid/setup flow; high |

Maintain the current nine supported joint/constraint types and conflict policy. A
small endpoint overview is justified; a full editable node-graph system is not.
Do not silently repair endpoints: diagnostics can select candidates, the user chooses.

## Reject / defer

Animation editor, runtime tool-grip injection, auto-rigging, force auto-repair,
automatic unanchoring and a generic weld-all button presented as premium differentiation.
Interactive pivot editing is already covered by a maintained free competitor; first
prove a distinct inspection workflow before investing in parity.

## Acceptance target for a later release

Use repeated siblings named Part, locate both endpoints without renaming user objects,
Preview a connection without place writes, block conflicts and show a clear recovery.
Verify native Undo/Redo and world-pose preservation for supported operations in the
final binary. Do not turn an automation focus failure into a claimed product bug.
