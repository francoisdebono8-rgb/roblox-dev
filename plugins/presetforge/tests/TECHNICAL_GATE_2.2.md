# PresetForge 2.2.0 technical gate (#19)

This candidate is local and unpublished. The public 2.0.0 and 2.1.0 artifacts,
release evidence, demo and media are retained. Asset 73596873703054 is untouched.

## Reproduce

From the isolated product worktree:

```sh
/private/tmp/jointforge-tools/rojo/rojo build plugins/presetforge/release.project.json -o plugins/presetforge/dist/PresetForge-v2.2.0.rbxm
python3 plugins/presetforge/tests/build_technical_gate.py --rojo /private/tmp/jointforge-tools/rojo/rojo --compile /private/tmp/jointforge-tools/luau/luau-compile --output-dir /tmp/PresetForge19QA
```

The builder imports the exact 2.2.0, 2.1.0 and 2.0.0 commercial binaries. It
compares every candidate Source against the worktree, checks the one-Main model
structure, rejects network/runtime additions, disables only commercial Main in
the QA copies, then checks the final QA binary again. No test module enters the
commercial model. Compilation and packaging are not native execution evidence.

Only the coordinating main agent installs/loads the isolated QA plugin and opens
`/tmp/PresetForge19QA/PresetForge19QA.rbxl` in native Studio Edit mode. The plugin
is `/tmp/PresetForge19QA/PresetForgeTechnicalGate.rbxm`. It runs only when Workspace
has `PresetForgeTechnicalGate = true`, the place is local and empty, and Studio
is not running a simulation. It refuses other places. Do not publish either QA
artifact or install it alongside another active QA runner.

Output uses `[PresetForgeTechnicalGate]`. Each assertion reports PASS/FAIL;
baseline specs, existing controller workflows and the complete issue matrix are
included. Real History fixtures have a baseline waypoint. Both Apply and Project
create/update/rename/delete exercise native Undo/Redo. Settings use a unique QA
key (plus the dedicated 2.2 regression key), restore the previous value and verify
restoration. The installed commercial store key is never written by the runner.

After a successful exact-artifact run:

```sh
python3 plugins/presetforge/tests/collect_technical_evidence.py /path/to/Studio.log plugins/presetforge/v2/technical-2.2-native.txt
```

The collector rejects missing matrix rows, wrong candidate hashes, failed runs
and non-product/private log content. Any production change requires rebuilding
and rerunning the exact candidate. Do not claim PASS from compilation, simulated
Instances or an earlier candidate.

No graphic acceptance, media, listing, store configuration or publication is
part of this technical gate. Persistence is reopened within the same real Studio
session; restart durability is not represented as tested.
