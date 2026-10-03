# JointForge / five images

**Commercial gallery pending.** Actual [installed GUI evidence](../../ui/forge-0.2.5/GUI_EVIDENCE.md) is the starting proof, not newly captured commercial media.

## Setup
Use a disposable clean copy of `products/jointforge/ui/forge-0.2.5/JointForge025-Demo.rbxl` and the exact frozen full Main. Original primitive assembly from the checked-in fixture; no third-party media. Restore BrokenConnection.Part1 missing before each take. Avoid overwriting the user's locally changed `JointForge025QA.rbxl`.

Baseline observed: 12 joints, 12 issues, 11 affected connections. Explicitly assigning BrokenC to Part1 and applying one operation produced 11 issues / 10 affected, not zero. Dark 560 dock next to the actual assembly. Keep endpoint objects visually distinct; no private names/paths, QA command bar or account chrome. Do not introduce invented labels/counters into the interface.

| Output to produce | Exact real state | Caption | Required visible proof | Must not be faked |
| --- | --- | --- | --- | --- |
| `images/01-hero.png` | Scan baseline, BrokenConnection selected | Find the broken connection in the assembly. | Assembly context, issues list and missing Part1 | No claim that all 12 issues are broken endpoints. |
| `images/02-diagnostic.png` | BrokenConnection detail before choosing replacement | Know which endpoint is missing. | Part0 identity, Part1 Missing, exact finding | No automatic suggested endpoint invented by copy. |
| `images/03-repair.png` | Select BrokenC in Studio, assign Part1, Preview repair only | You choose the endpoint. Review before Apply. | Explicit BrokenC choice, preview and Apply 1 | Part1 must still be nil until actual Apply. |
| `images/04-locate.png` | Locate selected connection in Studio | Jump from a finding to the real joint. | Native selection and corresponding actual assembly object | No overlay pretending the plugin adds new 3D connections. |
| `images/05-rescan.png` | Apply 1, Rescan | One repair confirmed. Remaining issues stay visible. | Part1=BrokenC, 11 issues / 10 affected and selected joint now clean | Never hide remaining findings or claim full physics validation. |

Only accept the result shot after checking the real endpoint property. For comparisons preserve camera and explicit before/after labels; no fabricated side-by-side UI. On capture append timestamp, exact candidate SHA and image SHA. Reserved output names do not indicate files already exist.

Use [canonical copper/F](../../../../docs/forge-studio-ui/brand/CANONICAL_COVER_FAMILY.md); reuse the mark, not the historical creation-first cover copy as the new hero promise. Final cover/icon exports require review. [Video plan](VIDEO_PLAN.md).
