# JointForge UI #28

Status: FIRST REVIEW READY, NOT FINAL GATE PASS. No publication.

## Implemented

Paired Create endpoints, exact plan and fixed Apply area; Batch role rows with connection diagnostics; Inspect list/detail split, narrow list-to-detail navigation, separate removal review and confirmation.

Canonical Forge F raster reused unchanged from SchemaForge. BuilderSans,
neutral surfaces, product accent, local visual primitives, theme switching,
quiet secondary controls and fixed primary command area. Technical engine
sources and historical dist artifacts unchanged. No shared workflow framework.

## Exact Candidate

- Artifact: `JointForge-v1.1.0-ui28.rbxm`
- SHA256: `ccc7478418901dfda224860232e2c3aca1c74a19438cbcd2756f45519f452824`
- Canonical asset: `103958912217728`, NOT UPDATED.
- Internal screenshots: [dark 560](review/dark-560.png), [dark 320](review/dark-320.png).

## Verification (2026-10-03)

| Gate | Status |
| --- | --- |
| Luau compilation | PASS |
| Two identical builds, imported Sources match final source files | PASS |
| Commercial package contains only production source hierarchy | PASS |
| Native View mount at 560 and 320 | PASS |
| Real engine Preview and read-only fixture check | PASS |
| Real dark screenshots at 560 and 320 | CAPTURED, awaiting visual acceptance |
| Physical mouse/keyboard walkthrough of all controls | NON TESTED |
| Full final technical/native regression, Apply/Undo/Redo | NON TESTED, after visual acceptance |
| Basic Light sanity | NON TESTED, after visual acceptance |
| User visual acceptance / final issue closure | PENDING |

Studio 0.741.19.7411056, Edit mode. Separate QA harness imports the exact
binary, disables only the embedded Main, and captures callbacks over actual
native controls. These are callback-driven smoke checks, not physical clicks.
Only unmodified native window captures were cropped to the measured host:
560x640 or 320x640 logical pixels (Retina 2x). No image generation or repainting.

Build/review harness: `tools/forge-ui-review/build.py`. QA plugin is temporary;
none of its fixture/callback code is in the production artifact. The six
screenshots were taken after all three implementation passes, as requested.

The first combined smoke exposed AccessForge forwarding Engine.output's second
return into the viewport helper and a 320px grid rounding wrap. Both were
corrected in the UI layer; the final native Preview run passed. A clipped
window capture was discarded and recaptured, never counted as a visual PASS.

Next: accept this first review, then perform the one final regression and Light
sanity prescribed by FAST_TRACK_REMAINING_PRODUCTS.md. Leave this issue open.
