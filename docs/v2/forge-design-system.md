# Forge functional design system

Proposal, 2026-09-27. No implementation in issue #15's first block. Applies to the
five existing canonical assets, not a new framework or catalogue expansion.

## Foundations

- A Studio work tool, not a landing page: compact navigation, legible data, quiet surfaces.
- Follow Studio light/dark theme for surfaces, borders and text. Product accent is
  an identity cue, never the only error/status cue. No forced dark island in light Studio.
- Logical-pixel spacing: 4 / 8 / 12 / 16 / 24. Outer padding 12; row gap 8;
  control height 30-32; icon target at least 28; radius 4, maximum 8.
- Body 14, supporting 12-13, section 14 semibold, product title 18-20. No negative
  letter spacing, viewport-scaled fonts, hero headings or all-caps paragraphs.
- Default dock target 400-440 wide, 640 high. Validate at widths 240/320/400/560
  and heights 360/640/900, including saved narrow layouts. Minimum size is not a
  substitute for reflow: no clipped tabs, missing actions or horizontal form scrolling.
- One column below 480. Libraries become a view/drawer, not a fixed sidebar that
  consumes the editor. Preserve scroll, focus, draft values and selection on updates.
- Stable header: product, current document/assembly, dirty state. Compact navigation;
  stable action footer; body scrolls. Collapse nonessential header content at low height.

## Product identity

Accent seeds below are design targets, not contrast-certified final UI tokens.
Test text contrast in both themes before implementing; use dark text on bright fills.

| Product | Accent seed | Secondary visual identity | Primary work surface |
|---|---|---|---|
| PresetForge | cyan `#22B8CF` | precise field marks, value columns | Recipe / Targets / Changes |
| JointForge | steel blue `#6F9DD9` | endpoint pairs, mechanical connections | Create / Batch / Inspect |
| CurveForge | electric blue `#458BDF` | path line with ordered control markers | Path / Output / Preview |
| AccessForge | safety amber `#ECA72C` | stair/landing silhouette on graphite | Layout / Rails / Finish |
| SchemaForge | mint `#63D6AE` | rule rows and validation marks | Rules / Audit / Repairs |

Shared functional hierarchy does not mean five teal panels. Use each accent sparingly;
error, warning, selected and success states remain semantically consistent across products.
Toolbar icons must distinguish products; today's five generic diamonds do not.

## Controls and language

- Tabs change views; segmented controls choose small modes; menus choose long option sets.
- Real checkbox/toggle affordances for booleans, not text `[x]` buttons. Numeric inputs
  get units and bounded stepping only when a real engine/product constraint exists.
- Color swatches plus editable value; labelled/selectable enums; not repeated cycle buttons.
- Use familiar icon assets for reorder, locate, refresh and remove; accessible label and
  tooltip. No unlabelled custom symbol, text-only Up/Down grid or decorative icon catalogue.
- One primary action per stage. Preview is non-destructive; Apply/Build/Regenerate is
  the explicit write action. Destructive actions are separate from frequent editing.
- Use domain labels: Start/End, Root/Connected part, Source/Targets, Rule/Expected/Actual.
  Technical names can remain in details. Keep full paths accessible without using them
  as the only identity for two siblings named Part.
- No permanent tutorial paragraphs. Empty-state instruction is one actionable sentence,
  e.g. "Select one light to capture a recipe." Detailed instructions belong in Help.
- Footer offers exact version and local Help. No network service needed for onboarding.
  Do not display debug source paths, raw Lua stack traces or private machine paths.

## Transaction state contract

| State | Visible feedback | Allowed action |
|---|---|---|
| Empty/incomplete | Missing input and precise next action | Select/capture/configure; no write |
| Draft valid | Target scope, pending choices | Preview |
| Preview computing | Progress only if measurable; no fake percentage | Cancel where safe; no Apply |
| Preview ready | Changes count, affected objects, skips, warnings; before/after | Apply N / Build N / Regenerate named assembly |
| Stale | "Selection or values changed. Preview again." | Refresh Preview; write disabled |
| Blocked | Specific reason next to input/object plus recovery action | Fix/select offending item; no write |
| Success | Actual committed count and target; concise native Undo affordance | Inspect result, new Preview |
| Failure | No false success; say whether rollback completed | Recover/retry after fresh Preview |

An old "Preview ready" must disappear on invalidation. Summaries and action positions
must not jump when a preview is hidden. Show changed items first; matching objects are
a collapsed count, not the first several pages of a change review.

Saving a Project recipe/schema is a project write; only capture/draft inspection and
Preview may be described as read-only when they actually are. "New Path"/"New markers"
create helper instances and must not imply a no-write operation.

Apply uses the existing transactional safeguards. Stale selection, deleted references,
changed sources or conflicting joints block the write. No silent overwrite or broadening
of scope. Confirmation is meaningful for deletion/replacement, not an extra generic
click on every harmless action. Show the exact named assembly and replacement count.

Undo/Redo uses native Studio history. Do not invent a custom Undo stack or claim an
undo occurred from a success message alone. Verification requires observing scene state
after native Undo and Redo, on the final release artifact. Selection remains independent
of Apply: Locate/Frame must not unexpectedly rebuild the scene.

## Onboarding and errors

Start with the shortest useful path per product: capture one recipe; assign two joint
endpoints; create a path; set two stair endpoints; load/capture one schema. Existing
documents/outputs should have a visible "Edit selected" entry at the top, not below
the entire new-object form. Explain prerequisites in context, not a mandatory tour.

Schema errors distinguish wrong type, missing, invalid value and required child.
Joint errors distinguish missing endpoint, same endpoint, existing connection and
anchored motion warning. Geometry errors identify the dimension/marker, never only
"invalid". A warning is not a safety or engineering certification.

## Store-media family

- Preserve the canonical asset IDs. Product name and literal promise should be readable
  at thumbnail size; no five visually identical generic Forge marks.
- Square icon: one product-specific silhouette, neutral background, restrained accent.
  No Roblox endorsement or certification implication.
- Three actual Studio screenshots: (1) useful result in the licensed environment,
  (2) configuration plus precise Preview, (3) safe change/re-edit or diagnosis in context.
- Reserve roughly two thirds for the real scene and one third for a readable panel;
  adapt to the product rather than hiding controls to hit a rigid ratio.
- Capture native UI, not a recreated mockup. Cropping may remove account/title/command
  chrome without altering pixels in the scene/panel. Never manufacture a PASS, selection
  outline, diff, Undo result, preview overlay or non-existent feature.
- Same product-name typography, caption length and ordering; distinct scenario/accent.
  Caption is short and outside the functional UI. No tiny text collage or unverifiable
  speed/commercial claims. Include source/license beside redistributed scenes.
- Creator Store title is literal and searchable; description under 1000 characters,
  core benefit first, limits explicit. Recheck the actual upload UI at release time.

## Acceptance before each implementation release

One real-project novice-style workflow, new + existing item, empty/invalid/stale states,
narrow dock, both Studio themes, long names and duplicate names, native Undo/Redo,
source preservation and artifact/source correspondence. Test only supported promises;
mark unexecuted checks explicitly. No remote telemetry or artificial growth metrics.

Implement locally in the first chosen product. Extract a shared component only after
two products actually need the same tested behavior, not as a prerequisite framework.
