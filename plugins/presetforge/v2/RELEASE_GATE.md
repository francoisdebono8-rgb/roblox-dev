# PresetForge 2.1.0 release gate

Issue #16, 2026-09-27. Canonical asset **73596873703054** only.
Status: **STUDIO ACCEPTANCE PASS. CANONICAL UPDATE SUBMITTED SUCCESSFULLY.**

Commercial SHA-256: `54746b6e7798094155bab145288723e19acc9e8bba010161d83f79e3649f1f15`.
Roblox Studio `0.740.19.7400003`, macOS, Edit mode, 2026-09-27.
The final binary passed **41/41 native checks** at 16:25 UTC. Its installed
production Main then ran the real GUI acceptance below. See `native-run.txt`.

This is a backward-compatible UX iteration on 2.0.0. The controlled schema,
V1 migration and storage format remain unchanged. No other product is modified.

## Execution record

| Required check | Status | Evidence |
|---|---|---|
| Real arena recipe capture | PASS | Actual Save Recipe; Color/Brightness only, real PointLight source |
| 240 / 320 / 400 / 560 px layout | PASS | 12 native geometry/text-fit cases: four exact widths x three heights; actual dock walkthrough at measured 241/327/402 px |
| Capture fields and primary actions reachable | PASS | Actual narrow-dock capture and resize retained draft; native scroll reachability assertions |
| Mixed Selection Preview | PASS | GUI: four selected, two compatible, one changed, one matching, two ignored |
| Filtered Descendants Preview | PASS | GUI: PointLight + name ArenaLight + tag ArenaLighting; 176 scanned, 20 changed |
| Changes-first order and matching/ignored groups | PASS | Native stable ordering; GUI changed rows first, matching/ignored collapsed |
| Select / Frame affected and duplicate object names | PASS | Real buttons selected exactly 20 changing lights; camera changed; arena untouched |
| Preview read-only | PASS | Baseline compares hierarchy, transforms, light/part fields, tags and attributes |
| Stale Preview blocks Apply | PASS | Real target Brightness change disabled Apply; native scope/filter/tag/ancestry cases |
| Apply only chosen fields | PASS | Actual Apply: exactly 40 Color/Brightness writes on 20 PointLights |
| Preserve unrelated properties/tags/attributes | PASS | Post-Apply snapshot assertions, including false attributes and existing tags |
| Native Undo / Redo | PASS | Actual Edit > Undo and Edit > Redo after GUI Apply; both object states asserted |
| Local persistence | PASS | Full Studio restart reloaded original and edited Local variant at 17:04 UTC |
| Explicit Project storage and persistence | PASS | Real Project save; exactly two fields in ServerStorage; saved place reopened after restart |
| Search populated library | PASS | Typed arena: matching Local/Project recipes shown, unrelated test recipe hidden |
| Duplicate/edit variant preserves original | PASS | Real Duplicate, then Edit removing Color; variant has only Brightness; original retains both fields |
| Long recipe names and duplicate object paths | PASS | Native long-name fixtures; real identically named ArenaLight paths have distinct numbered results |
| No product exception in successful flows | PASS | Native async error trap and scoped Studio log review; harness errors distinguished below |
| Exact final source / binary / installed correspondence | PASS | All 18 Sources and clean hierarchy audited; independent build byte-identical; installed hash identical |

## Corrections and harness notes

- Fixed rollback of a pre-existing boolean `false` attribute after a failed Apply.
- Fixed wrapped control sizing in clipped scrolling containers at narrow widths.
  Text-fit tests measure the same control outside ancestor clipping when native
  `TextFits` reports viewport clipping; scroll reachability is asserted separately.
- Initial Command Bar Undo/Redo probing produced `Attempt to play beyond change
  history`: Command Bar execution interfered with the redo stack. Replaced with
  actual Edit menu actions and pre-registered read-only assertions; both passed.
- One GUI assertion raced a pending AppleScript command against navigation and
  inspected the wrong recipe. Serial rerun verified the variant and original.
  These are recorded harness failures, not silently counted as product passes.
- Exact-width layout tests invoke production UIFactory in a native test host, not
  manual docking at all four exact widths. GUI actions use the separately installed,
  unmodified commercial artifact. No synthetic Controller click is called a GUI test.

Three real, visually inspected captures are in `../release/media/v2.1`.
The saved licensed arena is `../release/scene/PresetForge-v2.1-Arena.rbxl`.
The QA local plugin was removed after the 41/41 run. The installed commercial
plugin retains its old local filename solely to preserve the settings namespace.

## Scope

Use the existing MIT Nexus-Battles DodgeballArena adaptation in
`../release/scene`, not the user-modified original demo place. Work only in a
disposable copy for QA. Keep tests/fixtures out of the commercial model.

Deterministic Controller-handler tests are not GUI clicks. Native engine Undo/Redo
must assert object state after both operations. Commercial screenshots must be
uncomposited captures of the actual plugin in the licensed arena.

## Publication guard

Studio's **Publish as Plugin > Overwrite an existing asset** selected the existing
`PresetForge - Safe Bulk Editor` entry. Its title matched the read-only public
metadata for canonical asset **73596873703054**. One Save submission returned
**Successfully submitted!**, explicitly showing ID **73596873703054**.
Evidence: `studio-update-success.png`. No retry, new asset or duplicate.

This confirms Studio submission, not a new customer download or website
distribution/moderation decision. The existing title, icon and description were
preserved by the overwrite flow. Updated listing copy and the three new images
are ready for the user on Creator Hub, along with price/distribution confirmation.
No Creator Hub website changes or forum posts were performed.
