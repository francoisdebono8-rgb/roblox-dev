# SchemaForge

Catch misconfigured tagged objects before playtesting. Version 1.1.0.

Install `dist/SchemaForge-v1.1.0.rbxm` as a local Studio plugin. Canonical Creator Store asset: `84085408748744`; see [release gate](v2/RELEASE_GATE.md) for the actual submission/test status. Open the SchemaForge toolbar button in edit mode. See [Quick start](release/QUICK_START.md) and [limitations](release/LIMITATIONS.md).

The commercial model contains only Main and four production modules. Test and media places are separate; never upload them as the plugin.

Build with Rojo 7.7: `rojo build products/schemaforge/release.project.json -o products/schemaforge/dist/SchemaForge-v1.1.0.rbxm`.

Verify: `python3 products/schemaforge/tools/verify_release.py --rojo /path/to/rojo`.
