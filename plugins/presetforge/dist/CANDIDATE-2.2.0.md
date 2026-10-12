# PresetForge 2.2.0 candidate (unpublished)

`PresetForge-v2.2.0.rbxm` contains one commercial `Main` Script and nineteen
production ModuleScripts, all inside the existing single-model package. There
are no QA modules, fixtures, runtime scripts, network calls or telemetry in it.

SHA-256:

```text
535eb4da640adbbb8de5cea94a2778453620a74ce709e06e951436c3074b3857  PresetForge-v2.2.0.rbxm
```

Public version remains 2.1.0. Preserved artifacts:

```text
31401503260a2d6a95b17d41553601ebcba0c590b490ef5fced3a08b622618ec  PresetForge-v2.0.0.rbxm
54746b6e7798094155bab145288723e19acc9e8bba010161d83f79e3649f1f15  PresetForge-v2.1.0.rbxm
```

Changes: immutable one-use execution plans, exact relevant freshness, live recipe
storage checks, detached preflight, verified transactional writes and rollback,
selective metadata capture, deterministic planning bounds, strict persistence
validation and native ProjectStore history transactions. Storage format remains
version 2; old recipes retain the complete persisted field/tag/attribute subset.

See `../v2/TECHNICAL_2.2.md` for API, limits and migration details, and
`../tests/TECHNICAL_GATE_2.2.md` for isolated exact-binary testing. QA artifacts live
outside `dist/`. This package does not authorize any Creator Store update.

Final verification: 36 Luau files compile, exact package/source correspondence
passes, native Studio 0.740.19.7400003 passes 74/74 tests and all 35 issue matrix
rows on this exact binary. Evidence: `../v2/technical-2.2-native.txt`.
