# Forge Studio 0.2.5

Master issue: #35. Product issues: #30-#34. Started 2026-10-03 from
`92e4463cea4dc20ee59375b062e80b1caba55894`.

**READY FOR HANDOFF / PASS. Five products GOOD. Forge Studio 0.2.5 feature freeze.**
No Creator Store publication or update authorized or performed.

Five product agents implement concurrently with disjoint product ownership.
One coordinator owns this audit and serializes native Studio interaction.
Forge Playground #29 and unrelated local work remain untouched.

## Current Gates

| Product | Issue | Exact candidate | Native regression | Dark 560/320 + Light | Hero workflow | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| SchemaForge | #30 | PASS | 63 PASS; 41 matrix rows PASS | PASS | PASS: 7 findings -> 3 safe additions -> 4 manual findings | GOOD |
| PresetForge | #31 | PASS | 94 PASS | PASS | PASS: 30 affected lights / 60 exact property writes | GOOD |
| CurveForge | #32 | PASS | 63 PASS | PASS | PASS: Cable 51 segments; Repeat 14 copies -> moved path -> Regenerate | GOOD |
| AccessForge | #33 | PASS | 65 PASS; 44 matrix rows PASS | PASS | PASS: contextual Start/End, Build 33 -> Regenerate 38 parts | GOOD |
| JointForge | #34 | PASS | 48 PASS; 56 matrix rows PASS | PASS | PASS: Scan 12 -> explicit repair -> Rescan 11 issues | GOOD |

Product evidence belongs in `products/<product>/ui/forge-0.2.5/STATUS.md`.
Historical evidence and captures do not count for changed artifacts.
Module/harness results alone do not prove the installed plugin's GUI workflow.

Executed on 2026-10-03 in Roblox Studio **0.741.19.7411056**, Edit mode,
using separate QA packages importing the exact commercial binaries: **333 test
cases PASS, zero FAIL**. Matrix rows overlap these cases and are not added to the
test count. Native Undo/Redo, stale refusal and data preservation are covered.
Each product retains a scoped native log identifying the actual SHA. CurveForge's
final evidence is `native-final-run.txt`; its earlier dark run is historical.
No product CreatorError was found in these five runs. Roblox's own startup warnings
are not presented as product failures or hidden as an entirely clean Studio log.

The five full enabled commercial plugins were installed byte-for-byte under their
existing local filenames, preserving plugin settings identity and backing up the
previous installations outside the plugin folder. Callback-driven View tests and
mounted geometry assertions remain distinct from real installed GUI validation.
The installed SchemaForge, PresetForge, CurveForge, AccessForge and JointForge hero workflows
were subsequently exercised through native mouse/keyboard actions. Each retains
actual unretouched Dark 560/320, Light sanity, intermediate and short-width captures
plus a scoped `GUI_EVIDENCE.md`. Independent screenshot comparisons support GOOD,
not an exhaustive every-control/every-size GUI certification. Exact coverage and
unexecuted combinations are explicitly recorded there. Native history and read-only
instance assertions corroborate the writes; harness callbacks are not GUI proof.

CurveForge's final installed GUI demonstrated Cable and custom Repeat, read-only
Preview, actual Existing/Proposed geometry, stale refusal, Regenerate and native
Undo/Redo. Read-only assertions confirmed all 42 generated BasePart transforms,
14 copies and original source identity/geometry. A real 240-short screenshot exposed
a collapsed viewport. Only compact-height layout and its success label were corrected;
the final binary then passed all 63 native cases, including a new geometry/success test,
and the installed workflow/captures were repeated. Historical pre-fix captures are
explicitly separated from final evidence. No focus or lock-screen guard was bypassed.

JointForge's bounded scan was measured with 128 connections and 2,000 unrelated
folders: 2,129.901 ms total, 128 heartbeat yields, longest step 11.073 ms. These are
observations on this machine, not a general performance guarantee.

The five applicable hero-workflow gates have actual 560/320 Dark captures, Light
sanity and compact checks. A 900px-tall physical capture is not claimed:
it exceeds the usable Mac display. Existing native geometry matrices remain separate.

## Artifact Contract

Current candidates use
`products/<product>/ui/forge-0.2.5/<Product>-ForgeStudio-0.2.5.rbxm`.
The common label is **Forge Studio 0.2.5**, not a reset of historical internal
product versions. Each candidate manifest records its product-version mapping.
Existing `dist/` binaries, public-version evidence and canonical asset IDs remain
historical and must not be overwritten for label normalization.

| Product | Internal version | Canonical asset ID | Current SHA256 |
| --- | --- | --- | --- |
| SchemaForge | 1.2.0 | 84085408748744 | `1e86dd4e581bdffbae2a55635b95ab41bfa4d41359826935c74ef59bbf9575fe` |
| PresetForge | 2.2.0 | 73596873703054 | `a9726d442d8376a658cdb042da2212cced695ab2b7e6a96c4b8a08e71d881a63` |
| CurveForge | 1.1.0 | 90642263224333 | `510b7dc3af0dfed72bdc97f7ebe83ce2bdacfc960ffac38dd9ab9735e78cdc7d` |
| AccessForge | 1.1.0 | 127360597946823 | `839798041fdc1884df19e8cabccf7e1f698c0087d6f1e3bc8c9ec5bd25b1089d` |
| JointForge | 1.1.0 | 103958912217728 | `e74b3f4d94de155faa634a0986dcea30efee105a1c009b8db7c9a324e36a2216` |

Run `python3 tools/forge-release/verify_freeze.py --rojo <rojo>` for read-only
rebuild equality, imported hierarchy/source equality and commercial-content checks.
This packaging check does not certify native behavior, visual quality or readiness.
The independent rebuild/import gate passes for all five. Its seven positive and
negative verifier tests pass. Commercial files contain only the expected enabled
Main and production Modules, with exact current sources and no QA/demo hierarchy.
The installed plugin hashes match this table. Temporary opt-in QA runners were
moved out of the local Plugins folder after completion; the five commercial plugins remain.

## Final Freeze

On 2026-10-03, all five products meet GOOD for the executed #30-#35 scope on the
exact hashes above. Real hero workflows, mandatory 560/320 Dark captures, Light sanity,
bounded technical regressions and independent before/after reviews are recorded.
The catalogue release gate passes. Feature and speculative polish development stops.

This is not an exhaustive certification of every historical GUI checklist cell.
Physical 900-high captures and each product's additional unexecuted combinations remain
NOT TESTED in its evidence. They are not silently converted to PASS. Compact CurveForge
projection can overlap nearby point markers; its ordered Path list remains available.
None of these scoped limitations hides a remaining blocker in the demonstrated workflows.

Further work requires buyer feedback, a concrete support issue, sales/conversion
evidence or repeated real workflow pain. Publication requires separate authorization.
