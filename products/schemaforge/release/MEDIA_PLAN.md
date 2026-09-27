# Three genuine Studio captures

## Actual final-binary 1.1.0 captures

Captured 2026-09-27 from the real local commercial plugin in the licensed greenhouse.
Artifact SHA256 at capture:
`4c6768ba0c484164a576287b3cb623b8fd23c5ae90054b415e640c483a1906e9`.
All three were recaptured after the final focus and theme fixes. No generated interface,
compositing or invented selections/results. Desktop crop only, excluding account,
title/toolbars/Command Bar: all three are 2940 x 1268, logical rectangle
(0, 190, 1470, 634). The actual floating commercial dock is 400 x 640.

1. `media/01-explicit-project-contract.png`: Greenhouse pots loaded; name/tag/scope,
   required Contents/Plant child and designer note in Rules.
2. `media/02-audit-tagged-objects.png`: reason All, field Cost, three filtered
   findings/affected objects, the first finding's Expected/Actual/note context.
   The body is scrolled; the overall 8 checked / 3 match / 6 findings count was
   verified before capture, not added as an overlay.
3. `media/03-preview-missing-defaults.png`: exactly two missing Cost defaults on
   Cabbage_03 and Cabbage_06, each 25, with the Apply count visible.

Reproduction: open a disposable copy of `SchemaForge-Media.rbxl`, select
PlantGreenhouse/ProductionPots, then Library > Greenhouse pots. Rules > Children gives
scene 1. Audit > Audit, field Cost and Select affected gives scene 2. Reset the audit
to all findings, Preview gives scene 3. Do not repair invalid values or child structure.
Use the installed final artifact listed in `../dist/manifest.json`.
See `../tests/FINAL_GUI_V11.md` for the post-fix walkthrough and
`../v2/RELEASE_GATE.md` for final acceptance. The canonical Studio update is complete;
these three PNGs are ready for the user's Creator Hub media upload.

Source/license: [scene/README.md](scene/README.md). Media is separate from the paid plugin.
