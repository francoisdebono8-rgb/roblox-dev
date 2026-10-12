# JointForge / Creator Store copy

Prepared 2026-10-03 for #41. Not uploaded. Status: **READY EXCEPT MEDIA**.

## Title
JointForge - Scan & Repair Assembly Connections

## One-line promise
Find connection problems, choose an explicit repair and rescan to see what remains.

## Short description
Inspect assembly issues, locate their joints and review explicit endpoint or field changes before applying. No guessed Fix All.

## Full description
A complex assembly can contain a broken connection that is hard to locate.

JointForge scans a selected assembly, parts or joints and groups connection issues. Open an issue to inspect its endpoints and locate the connection in Studio. Missing endpoints, duplicate paths, attachment alignment and anchored pairs become reviewable findings, not a wall of objects.

Choose the intended endpoint or supported field change yourself, Preview the repair, then Apply and Rescan. Changes use Studio Undo. Existing create, edit and batch tools remain available, but diagnosis comes first.

Native constraint visualization or a free welder is enough for a straightforward joint. JointForge is for repeated diagnosis and deliberate repairs across an assembly.

Scan is capped at 128 connections. Some classes are inspect-only; findings are not a physics simulation or proof that an assembly will work. No automatic Fix All or guessed endpoints. No network requests, analytics or external account.

## Search terms
joint inspector, constraint diagnostics, broken weld, missing endpoint, assembly repair, Motor6D, hinge, rescan, Roblox Studio

## Privacy and exact limits
- No HTTP, telemetry, remote storage or external account. Scan reads the place; explicit Apply changes native joints/constraints/attachments. No separate cloud database or runtime monitoring. Roblox's own platform services are outside this statement.
- Editable classes: WeldConstraint, Weld, Motor6D, HingeConstraint, BallSocketConstraint, RopeConstraint, RodConstraint, SpringConstraint, NoCollisionConstraint. Other discovered classes may be inspect-only, not editable equivalents.
- Full issue Scan accepts at most 128 scope objects and 128 connections, refusing oversized results. Underlying graph caps: 20,000 hierarchy visits, 8,000 part nodes/edges, 4,000 nodes per connected component, depth 128. A smaller selection may still hit the world-index limit; split huge projects for inspection.
- Findings such as Both anchored or Indirect physical path require interpretation, not automatic deletion/unanchoring. No physical simulation, rig validator, guessed endpoint or universal Fix All.
- Changes require explicit choices and a fresh Preview. Planner operations are bounded; unsupported/conflicting requests are refused. Undo/freshness checks do not promise cross-user locking or zero-risk concurrent Team Create edits.

## Version and asset
Internal **1.1.0** / **Forge Studio 0.2.5**; canonical **103958912217728**. [Frozen file/SHA](LAUNCH_CHECKLIST.md).

## Substitutes and price
Recommendation: **4.99 USD**, unvalidated one-time launch hypothesis, not an account change.

| Substitute | Evidence inspected 2026-10-03 | Positioning consequence |
| --- | --- | --- |
| [DWeld](https://create.roblox.com/store/asset/5019960405/DWeld-Weld-Models-and-Tools) | Live free acquisition, updated Feb 14, 2026; touching-part/root/selection welding and unwelding | Welding itself is not the paid reason. This maintained free tool is a sensible choice for ordinary creation. |
| [Native constraint visualization](https://create.roblox.com/docs/physics/mechanical-constraints) | Show Welds, Show Constraint Details and mechanism visualization | Studio already makes connections visible. Do not pretend visual inspection requires a paid plugin. |

Inference: the paid value is the grouped diagnosis, exact selected connection, explicit repair preview and rescan loop. The bounded 128-connection Scan and strong free creation tools argue for a modest floor price, not a high-priced "professional physics debugger" claim. No competitor was installed/benchmarked in this research; no assertion about unadvertised capabilities.

## Forbidden claims
No automatic repair of all joints, guaranteed physics correctness, unlimited assemblies, unique welding, automatic rig repair, guessed safe endpoints, sales/download figures or time-saving percentages. Never imply all findings disappear after one repair.
