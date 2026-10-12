# Forge catalog release status

## Catalog V1: five canonical Studio assets

2026-09-27, after SchemaForge publication. Authenticated plugin creations list verified: six rows including the pre-existing AccessForge duplicate; exactly one SchemaForge. Five distinct products now have canonical Studio assets. This does not claim that SchemaForge's web distribution is enabled.

| Product | Canonical asset ID | This run |
| --- | --- | --- |
| PresetForge | 73596873703054 | 2.1.0 existing asset updated from Studio, issue #16 |
| JointForge | 103958912217728 | Existing, unchanged |
| CurveForge | 90642263224333 | Existing, unchanged |
| AccessForge | 127360597946823 | Existing, unchanged; 136358269001448 remains a pre-existing duplicate, not canonical |
| SchemaForge 1.1.0 | **84085408748744** | **READY / PASS**: 91 native checks in each theme, final GUI/media, one successful existing-asset update, issue #17 |

SchemaForge: [release status](../../plugins/schemaforge/release/RELEASE_STATUS.md), [final gate](../../plugins/schemaforge/v2/RELEASE_GATE.md), [media](../../plugins/schemaforge/release/MEDIA_PLAN.md), [publication guard](../../plugins/schemaforge/release/PUBLICATION.md). Existing asset update confirmed 2026-09-27 22:57 UTC (2026-09-28 Paris), no new asset. User web steps: listing, price, icon/screenshots and distribution. Outreach drafts are prepared, not posted. Other products and missing historical QA evidence are unchanged by issue #17.

## PresetForge issue #16

2026-09-27: **2.1.0 STUDIO ACCEPTANCE PASS; canonical update submitted successfully**.
41/41 native final-binary checks and real licensed-arena GUI acceptance passed,
including exact Apply, Edit-menu Undo/Redo, search, duplicate/edit isolation and
full Studio restart Local/Project persistence. Three genuine screenshots are in
`plugins/presetforge/release/media/v2.1/`. See
`plugins/presetforge/v2/RELEASE_GATE.md` and `native-run.txt` for precise coverage.

Clean publication place: `plugins/presetforge/release/PresetForge-Publication.rbxl`.
Studio's existing-asset overwrite flow returned **Successfully submitted!** and
ID **73596873703054**. No new asset or duplicate was created. Submission stopped
at this first success; proof: `plugins/presetforge/v2/studio-update-success.png`.
Creator Hub website media/price/distribution remain user-owned. Other products
and the historical evidence below are unchanged.

## Historical issue #12 snapshot

The following is the original issue #12 evidence, retained without relabeling unexecuted tests as PASS. Later Studio publication IDs above supersede its old asset-state column.

2026-09-27. **PARTIAL / BLOCKED: do not close issue #12.** No product functionality or commercial binary was changed.

| Product | Native engine gate | Production GUI, this pass | New real-project media | Asset state |
| --- | --- | --- | --- | --- |
| PresetForge 2.0.0 | PASS: six specs + native scoped Apply/Undo/Redo and real Local/Project storage | NON TESTED | NON TESTED: environment ready, three captures missing | Existing **73596873703054**, unchanged |
| JointForge 1.0.0 | PASS: 14 groups, all nine joint types, actual native Undo/Redo | NON TESTED; prior Batch/Preview/Apply/Undo evidence remains in product tests | NON TESTED: environment ready, three captures missing | Existing **103958912217728**, unchanged |
| CurveForge 1.0.0 | PASS: nine groups, Cable/Repeat/Regenerate, actual native Undo/Redo | PASS: New Path/order/Cable/Pipe/Repeat Preview/Build/Edit/Regenerate; actual native Edit Undo/Redo | PASS: three genuine village captures, reviewed | Not published; gates complete, Studio submission pending |

No deterministic product failure was observed. No plugin exception appeared in the scoped native run; Studio emitted its own internal widget warnings. This is not a claim of error-free unexecuted GUI workflows.

## Verified artifacts

All three commercial binaries rebuild byte-for-byte from the unchanged production sources. The local installed copies have the same hashes. Native tests imported those final binaries, with their entry Scripts disabled only in the isolated QA copy to prevent duplicate toolbars. No test/demo/debug code was added to commercial packages.

| Package | SHA-256 |
| --- | --- |
| `plugins/presetforge/dist/PresetForge-v2.0.0.rbxm` | `31401503260a2d6a95b17d41553601ebcba0c590b490ef5fced3a08b622618ec` |
| `plugins/jointforge/dist/JointForge-v1.0.0.rbxm` | `24f43cf04c7d4e8cf92310b3c725f827e36b1ea22d9806e20325a4af4d2633bd` |
| `plugins/curveforge/dist/CurveForge-v1.0.0.rbxm` | `476ee0fc81f9080130fe8b6914bac8e37a9a1021b71df93f7b87168ee164162b` |

Actual Studio evidence: [forge-catalog-native-run.txt](forge-catalog-native-run.txt), 01:01:11 UTC, Studio 0.740.19.7400931 edit mode. No inference from compilation or failed UI clicks is counted as PASS.

## Publication state

Read-only public Roblox asset metadata confirmed [PresetForge](https://create.roblox.com/store/asset/73596873703054) and [JointForge](https://create.roblox.com/store/asset/103958912217728), both owned by VNM08080. Their current public prices were USD 4.99 and USD 7.99 respectively. No duplicate or update submission was performed; unchanged binaries do not require a re-upload in this pass. Future updates must explicitly target these IDs.

CurveForge's clean `plugins/curveforge/release/CurveForge-Publication.rbxl` is prepared from its exact final binary. Native tests, required GUI workflows and three reviewed captures now pass. No Studio asset submission has completed: file commands became disabled before the publication place could open. Suggested price remains USD 7.99. No Creator Hub website, seller, payment, identity, tax or distribution action was performed.

Existing English descriptions, keywords, versions, prices, limitations and quick starts were reviewed. PresetForge's Quick Start now distinguishes read-only Preview from explicit Project storage writes. No benchmark/time-saving claim was added.

## Licensed environments

The three distinct Nexus-Battles environments are DodgeballArena (PresetForge), TheDepths (JointForge) and RavenRock (CurveForge), pinned to `fd6505c3cb12c94272532e1a0b0a30bf8499fc52`. MIT license, author, URLs and hashes are stored beside each scene. Only an explicit native geometry/light property allowlist is retained. No upstream scripts, remote assets, restricted branding or UI are included. Initial camera positions come from authored map loading views. PresetForge and JointForge remain prepared environments; CurveForge has a completed native session and three visually reviewed captures.

Each product has a `release/MEDIA_PLAN.md` with concrete capture order, captions and remaining setup. CurveForge's cable, pipe and repeated-lamp images are genuinely captured and visually reviewed; six of the required nine new images remain missing. Earlier gray/demo captures are not relabeled as issue #12 media.

## Exact remaining blocker

Native UI control intermittently returns `timeoutReached` / `noWindowsAvailable`. After the user restored access, all required CurveForge workflows succeeded. Actual Command Bar assertions verified read-only Preview, unchanged source/environment, Cable Regenerate and Repeat Regenerate after actual native Edit Undo/Redo. See [20 actual GUI evidence lines](forge-catalog-gui-run.txt). Invalid numeric fields introduced by keyboard automation were rejected and recovered with valid values; no product bug was inferred.

The completed CurveForge session was saved as `plugins/curveforge/release/scene/CurveForge-Scenes.rbxl`. It contains the generated cable, 3D yellow pipe, 14 lamps, their controls and original two-part source. Workspace was asserted free of executable scripts. Three genuine cropped images are delivered, without private paths/account data or fabricated UI. Access failed again afterward: File/Window menus reported every command disabled, and the native window inventory found no visible Roblox window. CurveForge publication and all PresetForge/JointForge GUI workflows in these new scenes remain pending.

The temporary catalog QA plugin was removed from the local plugins folder; only the three exact commercial plugins remain installed. CurveForge's publication prerequisites now pass; its publication itself must still be verified.

After restoring access: publish CurveForge once from its clean publication place and record its ID; complete PresetForge/JointForge GUI workflows and six remaining images. Leave all Creator Hub web configuration to the user. Do not repeat successful CurveForge tests merely because the publication window was inaccessible.

## Repository files

New shared files:

- `docs/forge/forge-v1-release-checklist.md`
- `docs/forge/forge-catalog-native-run.txt`
- `docs/forge/forge-catalog-gui-run.txt`
- `docs/forge/forge-catalog-release-status.md`
- `tools/forge-release/README.md`
- `tools/forge-release/CatalogGate.plugin.luau`
- `tools/forge-release/gate.project.json`
- `tools/forge-release/place.project.json`
- `tools/forge-release/build_gate.py`
- `tools/forge-release/build_scenes.py`
- `tools/forge-release/collect_evidence.py`
- `tools/forge-release/verify_catalog.py`

For each of `plugins/presetforge`, `plugins/jointforge`, `plugins/curveforge`, new files are `release/MEDIA_PLAN.md`, `release/scene/LICENSE-Nexus-Battles.txt`, `release/scene/source.json`, and `release/scene/scene.project.json`. The new scene pairs are:

- `plugins/presetforge/release/scene/DodgeballArena-geometry.rbxmx`
- `plugins/presetforge/release/scene/PresetForge-Media.rbxl`
- `plugins/jointforge/release/scene/TheDepths-geometry.rbxmx`
- `plugins/jointforge/release/scene/JointForge-Media.rbxl`
- `plugins/curveforge/release/scene/RavenRock-geometry.rbxmx`
- `plugins/curveforge/release/scene/CurveForge-Media.rbxl`
- `plugins/curveforge/release/scene/CurveForge-Scenes.rbxl`
- `plugins/curveforge/release/screenshots/01-village-cable.png`
- `plugins/curveforge/release/screenshots/02-village-pipe.png`
- `plugins/curveforge/release/screenshots/03-village-repeat.png`

New publication files:

- `plugins/curveforge/release/publication.project.json`
- `plugins/curveforge/release/CurveForge-Publication.rbxl`
- `plugins/curveforge/release/PUBLICATION.md`

Updated files:

- `plugins/presetforge/release/QUICK_START.md`
- `plugins/presetforge/release/UPLOAD_CHECKLIST.md`
- `plugins/jointforge/release/CHECKLIST.md`
- `plugins/curveforge/release/CHECKLIST.md`
- `plugins/curveforge/release/screenshots/README.md`
- `plugins/curveforge/tests/RESULTS.md`

Unrelated pre-existing PresetForge demo changes, JointForge publication files and `../.DS_Store` files are excluded. No commercial source file was edited.
