# Playground Architecture

## Boundary

This experience reuses current product files unchanged through explicit Rojo
mappings. It neither loads paid plugins into Roblox Player nor recreates their
editor UI. Production computation stays server-side; runtime-native controls send
bounded choices, never arbitrary source, Instances, schemas or property paths.

`Client` owns camera, navigation, controls and highlights. `Server` identifies the
caller through the RemoteFunction player argument, allocates at most six workshops
and validates/rate-limits requests. `Session` routes to five independent station
adapters, not a shared product workflow engine. Each station owns its fixture,
preview and reset. `World` builds the room; `Visuals` renders native parts and
temporary non-colliding geometry from real plans.

## Production Modules

| Product | Directly embedded modules | Runtime adapter |
| --- | --- | --- |
| AccessForge | Geometry, Settings | Render `Geometry.plan().parts`; validate again before committing Parts. |
| CurveForge | Curve, Engine, Settings | `Engine.plan/check/output`; parent actual output in fixture and replace prior generated output. Never call Studio `Engine.apply`. |
| JointForge | Schema, Graph, Planner | Graph diagnostics plus planner conflicts; `preview/check/consume/finish`; execute one scoped remove/reassign, with endpoint rollback on failure. No Transaction module. |
| SchemaForge | Schema, Engine | `audit/preview/isFresh`; only authorized missing attributes and required tags. No transaction/apply call. |
| PresetForge | CaptureService, PreviewService, TargetResolver, ExecutionPlan, DataGuard, Schema, Constants, PresetSerializer, PresetValidator, ValueCodec, AttributeCodec, StringCodec | Actual capture and PreviewService plans. PlaygroundApplyAdapter validates/consumes issued writes, confines them to fixture descendants and rolls back on failure. No ApplyService. |

Studio-only methods inside production Engine modules are left intact and never
invoked or bypassed. No plugin entry point, View, DockWidget or preference store is
embedded. Exact hashes in the manifest identify the build inputs.

## Fixtures And Limits

- Access: one START, three valid destinations, one intentionally coincident
  invalid destination. Fixed width/tread, optional rails, explicit build.
- Curve: four constrained points, offsets -6..6, Cable or 6..24 copies of a prepared
  two-part source. Real placement transforms and adaptive samples.
- Joint: anchored service door/hatch, incomplete WeldConstraint, duplicate welds,
  separated/misaligned attachments. Hinge disabled for a deterministic fixture.
  Anchored-both findings remain diagnostic, not silently fixed.
- Schema: 24 tagged crates in five four-object error groups plus four valid ones.
  Eight additive fixes; no replacement of invalid data or creation of hierarchy.
- Preset: 36 PointLights in 36 housings; 24 Accent/PGAccent targets, 12 ignored
  Maintenance lights. Six targets initially match Color. Two captured recipes.
  Housing color mirrors actual Light.Color for visible feedback; this presentation
  update is outside the production property-write count. Counts are not fabricated.

Plans and ghosts clear on departure. Reset reconstructs the baseline, not a Studio
Undo history. Runtime adapters cannot edit a visitor's own projects.

## Authority And Freshness

A whitelist precedes every request; burst four and refill three/second bound work.
Only the active station may mutate. Indexes are integers in 1..256 and must resolve
against that station's stored findings/fixture. No plan, Instance or recipe object
is accepted from a client. Curve, Joint, Schema and Preset retain production
freshness checks. Access recomputes from stored settings and fixed endpoints.

All mutations and production root scopes are confined to the caller's fixture.
Workshops are ordinarily replicated and visible, but cannot be edited through
another player's requests. ServerStorage modules do not replicate; the downloadable
Studio place nevertheless includes their source and must be distributed accordingly.

## Provenance

Builds consume the working tree, not necessarily Creator Store releases. Preset
Constants includes concurrent catalogue metadata `CATALOGUE_RELEASE = "Forge Studio
0.2.5"`; that unrelated product edit is not included in this Playground commit.
It has no influence on runtime decisions. Rebuilding another checkout can change
manifest hashes. Rerun native parity QA after any dependency update.

The later visual iteration can replace the simple hall while preserving adapters
and tests. Real-client multiplayer, devices, controller and performance acceptance
are separate gates before public release.
