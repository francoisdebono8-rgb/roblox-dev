# PresetForge / Forge Studio 0.2.5

Issue #31 under #35. Product version remains **2.2.0**; the existing footer shows
**Forge Studio 0.2.5**, with internal version in its tooltip. Native dock identity,
settings key, canonical asset `73596873703054`, canonical F and BuilderSans remain.

**GOOD. NATIVE SUITE 94/94 PASS. INSTALLED HERO WORKFLOW AND VISUAL REVIEW PASS.**
Use [candidate.json](candidate.json) for the exact current binary/source/fixture/QA
hashes. PresetForge is ready for the #35 catalogue audit; code and candidate remain
frozen. No rebuild or source change followed execution.

- Commercial: `PresetForge-ForgeStudio-0.2.5.rbxm` (enabled full Main + 19 modules).
- Script-free real scene: `PresetForge-LightingWorkshop.rbxl`.
- Separate opt-in QA: `qa/PresetForge025Gate.rbxm` + `qa/PresetForge025Gate.rbxl`.
- Build: `python3 plugins/presetforge/ui/forge-0.2.5/build_candidate.py` from repo root.
- Runner: `[PresetForge025Gate]`, **94/94 PASS, 0 FAIL**, native local Edit mode.
- Instructions and actual installed GUI checks: [NATIVE.md](NATIVE.md).
- Actual GUI log excerpts and independent before/after review: [GUI_EVIDENCE.md](GUI_EVIDENCE.md).

| Gate | Status / evidence |
| --- | --- |
| Luau compilation | PASS: 38 product/test/runner sources |
| Exact source/artifact/import equality | PASS: 20 production Sources; independent byte-equal rebuild |
| Commercial packaging | PASS: only enabled Main + product Modules, no fixture/QA |
| Historical dist and original demo preservation | PASS: before/after hashes in candidate.json |
| Engine, Controller and Main preservation | PASS: byte-equal to `92e4463`; only Constants/UIFactory changed |
| Deterministic fixture structure | PASS offline: 197 scanned, 40 lights, 30 different, 10 matching |
| Full regression, selective capture, exact Apply, stale, native Undo/Redo | PASS: 94/94 in [native-dark-run.txt](native-dark-run.txt), including H01-H08 |
| Mounted Dark layout: 240/320/400/560 x 360/640/900 | PASS: 12 native layout cases in isolated UIFactory host; not installed DockWidget evidence |
| Native long paths at 240/320/400/560 | PASS: H08, real fixture data in isolated native host |
| Actual installed Main hero workflow | PASS: Project Warm worklights, filtered Descendants, Preview, Apply 30, Undo and clean uninterrupted Undo/Redo |
| Actual installed dock and real screenshots | PASS: Dark 320/560, Light 240-short/320/400/560 and after-Apply; seven direct native captures |
| Light sanity | PASS: independently inspected 320/560, plus 240-short/400 |
| Screenshot comparison and visual acceptance | PASS / GOOD: compared final captures with prior Arena and lighting-workshop drafts |
| Actual editor/selective capture and broader library GUI interactions | NON TESTED in this GUI session; applicable controller/native cases PASS in the 94-check suite |
| Actual GUI stale mutation / persistence after restart | NON TESTED in this GUI session; stale and in-session isolated persistence PASS natively, restart not claimed |

The parent executed this exact candidate in Studio **0.741.19.7411056**, local Edit
mode, on 2026-10-03. The scoped log ends at `13:17:39.329Z` with 94 individual PASS
rows and `[SUMMARY] PASS`. Its SHA-256 is recorded in candidate.json. Controller
checks use direct callbacks; layout checks mount the exact product UIFactory in an
isolated native host. Native history and preservation checks passed, but these are
not physical interactions with the installed full Main or commercial settings.
The separate actual full-Main session is recorded in GUI_EVIDENCE.md. Its final
uninterrupted Undo/Redo assertion passed at `14:14:50.346Z`. The earlier Redo assertion
failed after an intervening Command Bar read disrupted history; that invalid QA
procedure is disclosed and is not counted as PASS or attributed to a product error.

## Scope and evidence

Continues the Changes-first real-data UI at `92e4463`. Preserves the existing path
width clamp and full-path tooltip. Final small corrections raise the Select/Frame
and Filters click targets to 28 px, with the path below those controls. No engine
or feature expansion. Selective metadata remains in the focused capture editor;
matching/ignored remain secondary and collapsed.

The old workflow/layout assertions now follow actual result rows, explicit metadata
selection, the combined Targets/Changes workspace and the wide library pane. All
baseline cases remain and passed in the exact-artifact native run above.

The historical scene generator creates 186 descendants, despite the predecessor
native note reporting 197. This current fixture adds ten real metal rail supports
and their folder, making **197/40/30/10/157/60/0/0** reproducible from the shipped
fixture graph. On actual Studio opening, 21 additional `Snap` instances produced
**218 scanned / 178 ignored**. Read-only native class counts explain the difference;
40 compatible, 30 affected, 10 matching and 60 property writes stayed identical.
No counters are injected. Both recipes and source metadata are real.
The old fixture, `dist/` binaries and user-modified original demo stay untouched.

Baseline review is recorded in `../WORK_NOTE.md`; lighting-workshop draft screenshots
in `../review` belong to predecessor SHA `da434b...`, not this artifact. They serve
only as comparison references. The seven final captures in `review` show this SHA.
The preview composition maps to real repository recipes, resolver metrics and
execution-plan before/after values; Apply uses the existing guarded transaction.
No new shared framework, branding change, commercial media, publication or outreach.

No Studio interaction or plugin installation was performed by this agent. The parent
executed the native suite and actual GUI; this agent independently inspected their
saved evidence. The product assessment is GOOD, with the unexecuted GUI checks above
explicitly excluded. The parent owns the final catalogue decision. No further native
tests, rebuild, commercial media, publication or Git action was performed here.
