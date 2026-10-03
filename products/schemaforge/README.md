# SchemaForge

Catch misconfigured tagged objects before playtesting.

Current candidate: **Forge Studio 0.2.5**, internal product version **1.2.0**.
See [current status](ui/forge-0.2.5/STATUS.md), [exact candidate manifest](ui/forge-0.2.5/candidate.json)
and [native QA instructions](ui/forge-0.2.5/NATIVE_QA.md). Native regression and the
installed hero-workflow GUI gate pass; scoped visual review is GOOD. See the evidence
for untested combinations. No Creator Store update is included.

Install `dist/SchemaForge-v1.1.0.rbxm` as a local Studio plugin. Canonical Creator Store asset: `84085408748744`; see [release gate](v2/RELEASE_GATE.md) for the actual submission/test status. Open the SchemaForge toolbar button in edit mode. See [Quick start](release/QUICK_START.md) and [limitations](release/LIMITATIONS.md).

The public 1.1.0 model contains Main and four production modules. The current
candidate adds only the AuditSummary presentation adapter. Test and fixture places
are separate; never upload them as the plugin.

Historical `dist/` artifacts and their manifests are frozen. Current sources build
`ui/forge-0.2.5/SchemaForge-ForgeStudio-0.2.5.rbxm`; do not overwrite historical binaries.

Build/verify with Rojo and the Luau compiler/interpreter:
`python3 products/schemaforge/ui/forge-0.2.5/build.py --rojo /path/to/rojo --compiler /path/to/luau-compile --luau /path/to/luau`.

Historical #23/#25 evidence remains in [UI release history](ui/RELEASE_STATUS.md).
The accepted F/BuilderSans lockup is preserved. Engine, Schema and Store are unchanged.
