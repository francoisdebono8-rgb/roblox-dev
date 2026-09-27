# Local Forge release tools

These are repository QA tools, never commercial plugin contents.

- `verify_catalog.py --rojo <rojo>` rebuilds each commercial binary in a temporary directory and compares bytes and embedded source to production files.
- `build_gate.py --rojo <rojo> --output <local-plugin-folder>/ForgeCatalogGate.rbxm` creates an isolated QA plugin from the three final binaries. It runs only when Workspace has `ForgeCatalogGate=true`.
- Build `place.project.json` with Rojo, then open that place in Studio edit mode. The runner prints the six PresetForge spec results, a real native scoped Apply/Undo/Redo/storage result, 14 JointForge groups and nine CurveForge groups. Read the individual totals; invocation alone is not a PASS.
- `collect_evidence.py <Studio-log> --since <UTC-timestamp>` saves only scoped QA result lines without private paths, account IDs or telemetry.
- `build_scenes.py --source <pinned-Nexus-Battles-checkout> --rojo <rojo>` recreates the three licensed primitive-only environments and provenance records. It does not generate screenshots or assert visual approval.

Remove the temporary `ForgeCatalogGate.rbxm` from the local plugin folder after the run. Keep the production plugins installed. The runner uses a dedicated temporary settings key and restores its old value; it must not run in a user's working project. A failed test may leave disposable fixtures in the isolated QA place.

See `docs/forge-v1-release-checklist.md` for the required GUI/media/publication gate. Engine assertions do not replace production UI clicks.
