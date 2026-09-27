# SchemaForge

Catch misconfigured tagged objects before playtesting. Version 1.0.0.

Install `dist/SchemaForge-v1.0.0.rbxm` as a local Studio plugin, or install the published Creator Store asset. Open the SchemaForge toolbar button in edit mode. See [Quick start](release/QUICK_START.md), [limitations](release/LIMITATIONS.md) and [test results](tests/RESULTS.md).

The commercial model contains only Main and four production modules. Test and media places are separate; never upload them as the plugin.

Build with Rojo 7.7: `rojo build products/schemaforge/release.project.json -o products/schemaforge/dist/SchemaForge-v1.0.0.rbxm`.

Verify: `python3 products/schemaforge/tools/verify_release.py --rojo /path/to/rojo`.
