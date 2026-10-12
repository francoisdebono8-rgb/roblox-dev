# SchemaForge / Forge Studio 0.2.5

**GOOD; NATIVE REGRESSION AND INSTALLED HERO WORKFLOW PASS.** Issues #30 / #35.
Internal product version 1.2.0; canonical asset 84085408748744. No publication.
Ready for the parent's catalogue freeze; no further feature development proposed.

Candidate: [SchemaForge-ForgeStudio-0.2.5.rbxm](SchemaForge-ForgeStudio-0.2.5.rbxm).
Exact SHA256, six production source hashes and QA hashes: [candidate.json](candidate.json).
The commercial Main is enabled; only duplicate QA imports have Main disabled.

- Audit has a dedicated, unboxed results band: checked, valid, objects with issues,
  findings, safely repairable findings. Counts use actual Engine results, count
  affected Instances once, and remain independent of filters/subsets.
- Fresh startup opens the contract load/capture route in Audit. Saved contracts
  open Audit; Rules -> Audit runs the check directly. Captures open contract
  settings for review and retain opt-in missing-value defaults.
- Expected/Actual/note, selection, filter/subset, read-only Preview, missing-only
  Apply and stale protection remain. Stale summary values are explicitly historical.
- Existing accepted canonical F and BuilderSans lockup preserved. The native
  window title carries Forge Studio 0.2.5 without changing the internal semver.

| Gate | Status |
| --- | --- |
| Compile production + QA Luau | PASS |
| Offline summary regression | 6 PASS / 0 FAIL |
| Reproducible bytes / exact embedded sources / enabled commercial Main | PASS |
| Exact QA imports, isolated from commercial binary | PASS |
| Engine/Schema/Store and existing dist/capture hashes preserved | PASS |
| Full native regression: 53 existing + 6 summary + 4 hero | 63 PASS / 0 FAIL; 41/41 matrix rows PASS; outer SUMMARY PASS |
| Exact-binary module execution / six known production scripts | PASS in native QA import |
| Safe missing-only repair, stale refusal, native Undo/Redo | PASS in native module tests |
| Installed Main: Load -> Audit -> Preview -> Apply, selection, stale, native history | PASS for the recorded hero workflow |
| Dark 560/320 and Light 560/320 | PASS; actual installed-plugin captures |
| Dark 400 and 240x360 short | PASS for reviewed layout/footer; short body very compact |
| Final comparison with accepted branding and prior Audit composition | GOOD; evidence-based visual review |
| Advanced first-use/capture/filter/subset GUI combinations | NOT EXHAUSTIVELY RUN; not claimed as GUI PASS |

Native run: **Studio 0.741.19.7411056, Edit mode, Dark**, 2026-10-03,
exact candidate SHA256 `1e86dd4e581bdffbae2a55635b95ab41bfa4d41359826935c74ef59bbf9575fe`.
[Native evidence](native-dark-run.txt) confirms all three suite summaries and outer
PASS. Separate [installed GUI evidence](GUI_EVIDENCE.md) records the parent-operated
full plugin, actual screenshots and CreatorOutput markers from the
`20261003T141548Z` session. Audit/Preview: 8/3/5/7/3; Preview proposes three additions
on two objects without writes. Real Apply and native Undo/Redo, then re-audit:
8/5/3/4/0. Another native Undo restores 8/3/5/7/3. Select in Studio is asserted PASS;
deferred Cost=99 mutation produces visible Stale and disabled Apply.

Independent screenshot comparison supports GOOD: preserved F/BuilderSans lockup,
readable result hierarchy, exact diagnostic context and conservative repair review.
The 240x360 body is a compact scroll viewport; footer remains usable. Dark native
Qt title text has poor contrast after theme switching, outside the correct plugin
content. This is not exhaustive GUI certification or a full width/height/theme matrix.

[Offline evidence](offline-verification.txt), [native handoff](NATIVE_QA.md),
[baseline and UI mapping](WORK_NOTE.md). Module QA and actual installed GUI evidence
are distinct. Parent owns the catalogue freeze decision. This signoff changed only
current evidence documents; no Studio action, source/binary edit, rebuild or git operation.
