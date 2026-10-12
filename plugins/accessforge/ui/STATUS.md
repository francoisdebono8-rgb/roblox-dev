# AccessForge UI #27

Status: FIRST REVIEW READY, NOT FINAL GATE PASS. No publication.

## Implemented

Start/End identities and assignment/locate actions; grouped Layout/Rails/Finish; permanent wide assembly preview and adjacent metrics; dedicated narrow Preview without horizontal form scrolling.

Canonical Forge F raster reused unchanged from SchemaForge. BuilderSans,
neutral surfaces, product accent, local visual primitives, theme switching,
quiet secondary controls and fixed primary command area. Technical engine
sources and historical dist artifacts unchanged. No shared workflow framework.

## Exact Candidate

- Artifact: `AccessForge-v1.1.0-ui27.rbxm`
- SHA256: `8605ae5f948132bf9b309fe8b2b61b6a92023e0f0aca98eb2ba3f02185feedc1`
- Canonical asset: `127360597946823`, NOT UPDATED.
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
