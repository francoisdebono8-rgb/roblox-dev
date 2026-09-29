# SchemaForge

Catch misconfigured tagged objects before playtesting. Version 1.1.0.

Install `dist/SchemaForge-v1.1.0.rbxm` as a local Studio plugin. Canonical Creator Store asset: `84085408748744`; see [release gate](v2/RELEASE_GATE.md) for the actual submission/test status. Open the SchemaForge toolbar button in edit mode. See [Quick start](release/QUICK_START.md) and [limitations](release/LIMITATIONS.md).

The commercial model contains only Main and four production modules. Test and media places are separate; never upload them as the plugin.

The public 1.1.0 artifact is frozen. Current sources build the unpublished 1.2.0 candidate;
do not overwrite the historical public binary with them.

Build/verify with Rojo 7.7:
`python3 products/schemaforge/tools/verify_candidate.py --rojo /path/to/rojo --build`.

Issue #23 UI candidate: [native quality gates and before/after evidence](ui/RELEASE_STATUS.md).
Human visual acceptance is pending after the first pass was rejected; do not treat
the candidate as the approved Forge Studio reference.
The functional engine is unchanged. No Creator Store update is included.
