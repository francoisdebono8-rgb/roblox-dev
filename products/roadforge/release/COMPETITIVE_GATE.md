# RoadForge 1.0: pre-development gate

Issue: [#13](https://github.com/francoisdebono8-rgb/roblox-dev/issues/13)

Checked: 2026-09-27. Decision: **HOLD / gate not passed**.

The issue authorizes development only after a credible paid distinction is
established. The short public audit does not establish that distinction for the
full proposed V1. This is not a conclusion that nobody would buy RoadForge, or
that a competitor is technically reliable. It is a reason not to manufacture a
commercial validation from a feature list and some negative reviews.

## Observed evidence

Read-only Creator Store pages and the author's public CivilArc workflow were
inspected. No competitor was acquired, installed, run, benchmarked or copied.

| Product | Current public observation | Consequence for RoadForge |
| --- | --- | --- |
| [CivilArc Road Toolkit](https://create.roblox.com/store/asset/94221087121754/CivilArc-Road-Toolkit) | Store shows Get Plugin, no purchase price, 64%, 10+ votes, updated March 17, 2026. The [author's v2.1 documentation](https://devforum.roblox.com/t/civilarc-road-toolkit-fmr-bezier-curved-road-generator/3165280) describes surface/aerial points, preview, elevation, banking, lanes, shoulders, configurable markings, saved road editing and junction tools. Its workflow uses design-speed/simple curve modes. | Roads + elevation + banking + reopen/edit are already covered. A free acquisition route is displayed; market dominance and actual reliability are not established. |
| [Simple Bezier Road Creator](https://create.roblox.com/store/asset/12003902090/Simple-Bezier-Road-Creator/reviews) | Get Plugin without a purchase price; 86%, 200+ votes. Visible reviews include endpoint orientation difficulty (January 2026), marking colors/custom types/extra lanes (June 2025), crashes (May 2025) and sidewalks (February 2025), alongside positive reviews. | Concrete needs exist, but older complaints about this product do not demonstrate gaps in every current alternative. |
| [RoadBuilder v0.7.0](https://create.roblox.com/store/asset/14674744762/RoadBuilder-v070) | Buy for USD 4.99; 54%, 10+ votes; updated March 31, 2026; described as beta. | There is a paid competitor. Ratings do not prove either sales volume or demand for RoadForge at USD 9.99. |
| [Advanced Road Tools](https://create.roblox.com/store/asset/7275413149/Advanced-Road-Tools) | Get Plugin without a purchase price; 66%, 100+ votes; updated January 24, 2026. Description covers slopes, curves and highway segments and still calls the plugin work in progress. | Basic road generation and grades are not a paid differentiator. |

Prices and votes above are the displayed state, not completed purchase tests.
CivilArc's public known-issues/future-work text is not a reproduced defect report.
An undocumented feature is not an absent feature. No claim about a missing
native Studio capability was used to pass this gate. The anecdotal willingness
to pay cited in the issue is not a sales validation.

## Narrowed candidate, not an approved product

Constrain the candidate to **small industrial access roads with explicit manual
control and a predictable regeneration boundary**, keeping only capabilities
already requested in #13:

- Designer-entered roll at every ordered point, including endpoints; no
  design-speed engineering claims.
- A visible output budget, conservative cap and read-only footprint/count
  preview before any project mutation.
- Road, markings and optional curb/sidewalk profiles in one compact workflow.
- Scoped regeneration that preserves unrelated additions, with native Undo/Redo
  verified against the exact commercial artifact.

Exclude junctions, custom profiles, guardrails and snapping from V1. Do not
position it as a general highway toolkit or as faster/safer than alternatives
without a measured comparison. An industrial theme alone is not differentiation.

This narrowing is a **hypothesis**, not a gate PASS: public documentation does
not establish that the manual-control/output-budget combination is unavailable
or materially harder in CivilArc. Before coding, compare that exact workflow in
the current competitor or obtain concrete user evidence of an unmet need. If
the workflow is already straightforward, abandon this candidate instead of
rebranding an equivalent generator. Do not expand into a speculative V2 to
rescue the idea.

## Execution status

| Gate | Status |
| --- | --- |
| Short public competitor audit | PASS: pages actually inspected |
| Clearly differentiated paid V1 | NOT ESTABLISHED: development prerequisite unmet |
| Production code and artifact | NOT STARTED |
| Native Studio tests / GUI / Undo / media | NON TESTED |
| Roblox asset creation | NOT ATTEMPTED; no RoadForge asset ID |
| Overall issue #13 | OPEN; not release-ready |

No existing Forge product, plugin installation, Studio place or Roblox account
was modified for this audit. Do not publish RoadForge or claim the remaining
work is only Creator Hub configuration.
