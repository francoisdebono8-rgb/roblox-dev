# Greenhouse GUI execution, 2026-09-27

Studio 0.740.19.7400003, Edit mode, isolated copy of the licensed greenhouse.
Commercial local plugin 1.1.0, SHA256
`9a3fb2322245438b74c1d634b260db6bc6b4b9b61abe2dec0fdbdcab77a3cc39`.
This records the pre-focus-fix artifact, not an assertion that every GUI step was
repeated on the later final binary. No button signals were synthetically fired.

## Executed

- Actual empty-state Capture reference, existing Greenhouse pots library load and
  discard-draft confirmation. Three supported attributes captured; saved contract
  and greenhouse snapshot unchanged. Name, tag and scope remain visible.
- Real Audit click: 8 checked / 3 match / 6 findings. Missing, wrong type, invalid
  value and required-child cases; Expected / Actual / designer note visible.
- Real reason Missing and field Cost filters: two findings. Uncheck Cabbage_03,
  Select affected: exact selection Cabbage_06. Preview: one default on that object.
- Relevant attribute mutation disables Apply. Click on disabled Apply leaves the
  complete baseline unchanged. Fresh Audit / Preview returns two missing defaults.
- Actual Apply click, then Edit > Undo, Edit > Redo, Edit > Undo. Snapshot assertions
  verify exactly Cost=25 on Cabbage_03/06, followed by exact restoration. Existing
  Cost=-5, Variety=Cabage and Enabled="yes" remain unchanged, as do unrelated
  attributes, tags, hierarchy, names, transforms, geometry and appearance properties.
- Real width changes measured at 247, 299 and 356 x 731 logical pixels. Core actions
  fit at these observed sizes. This does not establish the four exact dock widths
  or a short dock; separate native layout evidence is needed.
- All three commercial PNGs captured from the actual Studio desktop. Cropped only
  to exclude account, title/toolbars and Command Bar. No compositing or invented UI.
- Loaded a disposable 32-field/32-child contract through Library. A real keyboard
  edit appended text to its designer note without replacing the form. Focus
  instrumentation exposed the input-service mismatch described below.

## Native assertion timestamps (UTC)

20:46:10 context and read-only PASS; 20:47:00 exact one-object subset PASS;
20:47:13 stale Apply disabled PASS; 20:47:34 disabled Apply read-only PASS;
20:51:13 menu Undo PASS; 20:51:24 menu Redo and exact two-default write scope PASS;
20:52:05 final Undo PASS; 20:52:13 original scene and saved contract preserved PASS.
21:09:10 disposable fixtures removed and greenhouse snapshot preserved PASS.

## Focus finding

At 21:06:00 the helper's global UserInputService focus assertion failed during a
real DockWidget edit. At 21:06:15, the actual TextBox reported IsFocused=true,
CursorPosition=22 and retained the typed text. Thus the assertion did not prove lost
typing focus; it exposed that the global focus API does not identify this dock input.
View.render used the same unsuitable query for restoration. The correction uses
TextBox:IsFocused(), matches the same logical rule, and rejects obsolete deferred
restores. See native DockWidget regression results before declaring this fixed.

Final artifact `92c6924b...`: exact dock widths, short Rules form and native
focus/caret/selection/scroll rerenders now pass in `native-v11-final-dark.txt`.
The disk-saved V1 contract loads in a fresh process in `native-v11-restart.txt`.
These do not replace complete rule-switch GUI, short-height Audit/Repairs interaction
or post-fix GUI/media revalidation; those remain explicitly pending in the release gate.
