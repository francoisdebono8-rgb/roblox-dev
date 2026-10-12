# SchemaForge 1.1.0 final GUI acceptance

Studio 0.740.19.7400003, Edit mode, licensed greenhouse copies. Executed
2026-09-27 UTC (2026-09-28 in Paris). Final commercial artifact SHA256:
`4c6768ba0c484164a576287b3cb623b8fd23c5ae90054b415e640c483a1906e9`.

Real native clicks/keyboard were used for the workflows below. The separate
`GreenhouseAcceptance.luau` helper sets up fixtures and asserts actual scene/UI/history
state; it does not invoke button signals and is absent from the paid artifact.

## Final-binary GUI revalidation

| Check | Result / UTC evidence |
|---|---|
| Reference capture | PASS; actual Capture reference, three supported attributes, zero unsupported |
| Existing library load and visible context | PASS; actual load/discard confirmation, name/tag/scope and unchanged saved contract, 22:33:39; fresh repeat 22:50:40 |
| Short 400x360 dock | PASS; actual Library load, Rules, Audit and Repairs; fixed Apply reachable, 22:33:39 / 22:34:33 |
| Light theme and live Dark switch | PASS; native Studio Settings; persistent title/footer/input labels match theme, 22:25:44 / 22:33:39 / 22:36:00 |
| Mixed greenhouse audit | PASS; actual Audit: 8 checked / 3 match / 6 findings |
| Expected / Actual / note and filters | PASS; actual reason Missing + field Cost; All + Cost yields three findings, visible in screenshot 2 |
| Exact affected subset | PASS; exclude Cabbage_03, Select affected selects only Cabbage_06, 22:37:53 |
| Read-only subset Preview | PASS; one missing default, full scene/contract snapshot unchanged, 22:38:29 |
| Stale Apply | PASS; relevant project change disables Apply, 22:34:35; actual disabled click writes nothing, 22:34:53 |
| Three-object inspection | PASS; All + Cost selects exactly Cabbage_03/04/06, read-only assertion 22:40:49 |
| Two permitted defaults | PASS; actual Preview shows only Cost=25 on Cabbage_03/06; read-only snapshot 22:41:25 |
| Apply only those defaults | PASS; actual Apply then full snapshot comparison, 22:41:52; fresh repeat below |
| Native Undo | PASS; fresh scene, actual Edit > Undo restores baseline, 22:51:38.248 |
| Native Redo | PASS; actual Edit > Redo reapplies exactly the two defaults, 22:52:28.095 |
| Invalid and unrelated data | PASS; Cost=-5, Variety=Cabage, Enabled="yes", other attributes, tags, hierarchy and measured BasePart properties preserved |
| Three commercial screenshots | PASS; all recaptured from this exact final binary, inspected; see MEDIA_PLAN |
| Runtime exceptions in successful clean path | PASS; no product/CreatorError entry in fresh final Apply/Undo/Redo run |

Primary GUI log: `0.740.19.7400003_20260927T222333Z_Studio_ce37c_last.log`.
Clean final history log: `0.740.19.7400003_20260927T224837Z_Studio_76ef7_last.log`.
The clean run installed its history observer before Apply, then waited for each native
menu operation to finish; no Command Bar execution occurred between Undo and Redo.

## Earlier GUI coverage, not relabelled as final

The preceding commercial artifact
`92c6924b897eeaefc9940f14ebf8a6e6d7dd24926778d83cb78cca0df377f653`
already included the native focus fix. Its only subsequent production difference is
the lifetime of theme registrations in `View.paint`; engine/editor logic is unchanged.
Log: `0.740.19.7400003_20260927T213315Z_Studio_cb965_last.log`.

- PASS: 32-field/32-child fixture, actual note typing retains textbox/focus/caret/scroll,
  22:06:41. Invalid `0x` gives inline error and disabled Save, 22:07:27; actual Backspace
  corrects it, 22:07:50, without saving the draft.
- PASS: actual field 1 > 2 > 1 switching retains the unsaved note and original stored
  contract, 22:11:24.
- PASS: two identical 96-character object names display distinct Model #6/#7 identities;
  actual Select object clicks select different instances without writes, 22:12:26.
- PASS: short 400x360 actual Apply writes exactly 32 disposable fixture defaults,
  greenhouse untouched, 22:18:06; Library load/discard succeeds, 22:19:24.

The complete physical long-rule switching/duplicate-name click sequence was **NOT
REPEATED after the theme-only fix**. Final-binary native long-form, validation,
identity and focused DockWidget rerender coverage passed in both Light and Dark
(91 checks each). The final GUI reran the affected theme paths and full primary
greenhouse workflow. Do not describe the earlier sequence as a final-hash GUI run.

## Interrupted attempts and limits

App/Space changes caused inaccessible windows, missed clicks and helper assertions
before capture/load/filter actions had completed. Earlier delayed AppleScript history
commands overlapped; Command Bar checks disturbed the history sequence. Those failed
helper snapshots are not accepted as PASS. A pristine scene and serial native menu
operations produced the clean final Undo/Redo evidence above.

No claim of globally empty Studio logs: native startup/widget warnings remain.
Fresh-process persistence covers the original disk-saved greenhouse contract, not
a newly GUI-edited contract followed by file save/reopen. All QA fixtures stayed local
and separate from the commercial model. Publication proof is in `../release`.
