# Three genuine Studio captures

## Actual 1.1.0 captures, final-binary recapture pending

Captured 2026-09-27 from the real local commercial plugin in the licensed greenhouse.
Artifact SHA256 at capture:
`9a3fb2322245438b74c1d634b260db6bc6b4b9b61abe2dec0fdbdcab77a3cc39`.
The subsequent isolated focus-restoration correction changes the final artifact hash.
These PNGs are genuine, but **not yet final-artifact release evidence**. No generated
interface, compositing or invented selections/results. Desktop crop only: 2940 x 1450
pixels, logical rectangle (0, 158, 1470, 725), excluding account/title/toolbars/Command Bar.

1. `media/01-explicit-project-contract.png`: Greenhouse pots loaded; name/tag/scope,
   required Contents/Plant child and designer note in Rules.
2. `media/02-audit-tagged-objects.png`: 8 checked / 3 match / 6 findings; reason All,
   field Cost, three visible findings/affected objects, Expected/Actual/note context.
3. `media/03-preview-missing-defaults.png`: exactly two missing Cost defaults on
   Cabbage_03 and Cabbage_06, each 25, with the Apply count visible.

Reproduction: open a disposable copy of `SchemaForge-Media.rbxl`, select
PlantGreenhouse/ProductionPots, then Library > Greenhouse pots. Rules > Children gives
scene 1. Audit > Audit, field Cost and Select affected gives scene 2. Reset the audit
to all findings, Preview gives scene 3. Do not repair invalid values or child structure.
Use the installed final artifact listed in `../dist/manifest.json`; repeat actual clicks
and captures, then replace the three files. See `../tests/GREENHOUSE_V11.md` for the
executed walkthrough and `../v2/RELEASE_GATE.md` for remaining acceptance.

Source/license: [scene/README.md](scene/README.md). Media is separate from the paid plugin.
