# Real Studio screenshots

Captured on 2026-09-26 from the installed production binary in Roblox Studio
0.740.19.7400931. Native screen-region captures only: no compositing, replacement
text, generated imagery or staged fake plugin state. Account chrome and local
filesystem paths are excluded.

- `01-batch-tool.png`: actual Handle, Static/Moving assignments and four-operation Preview.
- `02-inspect-graph.png`: existing connections and intentionally broken Weld endpoint.
- `03-one-step-undo.png`: actual restored state after Apply and one native Edit > Undo.

The last still shows the result, not a video proof of the whole sequence. Engine
assertions for the sequence are preserved in `../../tests/UI_RUN.txt`. The clean
demo place is separate and contains no QA scripts.
