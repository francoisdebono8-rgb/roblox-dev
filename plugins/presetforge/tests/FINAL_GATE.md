# PresetForge 2.1.0 release gate (#16)

Build from the repository root after the commercial artifact is final:

```sh
python3 plugins/presetforge/tests/build_final_gate.py \
  --rojo /private/tmp/jointforge-tools/rojo/rojo \
  --output /private/tmp/PresetForgeReleaseGate-v2.1.0.rbxm
```

The only release input is `plugins/presetforge/dist/PresetForge-v2.1.0.rbxm`.
The builder does not rebuild or modify it. It rejects missing/stale binaries,
checks every embedded production source against the current source files, and
checks the commercial hierarchy contains no QA. Inside the QA copy, only the
commercial `Main.Disabled` property changes; its Source and every module Source
remain exact. The final QA binary is decoded again to verify that only `Runner`
can execute. Its root records the commercial filename and SHA256, also printed
at runtime. QA output is forbidden in commercial `dist/`.

Use the Python builder, not a direct build of `final-gate.project.json`: that
project is an intermediate import before the builder disables commercial Main.
The existing source-based test projects/runners remain available for the six
baseline specs. They are not the final-artifact gate.

## Native run

Use an isolated Studio Edit-mode QA place. Before loading/reloading the local
QA plugin, enable the explicit opt-in in the command bar:

```lua
workspace:SetAttribute("PresetForgeReleaseGate", true)
```

Load `/private/tmp/PresetForgeReleaseGate-v2.1.0.rbxm` as a local plugin. Without
that exact boolean attribute the runner returns before requiring any module,
creating UI, touching settings, or recording history. The attribute must already
be true when the plugin loads; changing it later does not start a waiting runner.

Expected success is **41/41 checks passed**:

| Coverage | Checks |
| --- | ---: |
| Six retained specs, including false-attribute commit rollback regression | 6 |
| Workflow: duplicate in all four library combinations, search, preview order/staleness, controller, Frame | 20 |
| Layout: 240 / 320 / 400 / 560 x 360 / 640 / 900 | 12 |
| Native Apply/Undo/Redo and isolated plugin settings | 2 |
| No asynchronous runtime errors from the QA bundle | 1 |

Each case reports PASS/FAIL, continues after an assertion failure, and runs its
registered cleanup even on failure. A failed suite load is reported as a failure,
not a skip. `Passed`, `Total`, and `Complete` attributes on the QA model provide
the final outcome. An assertion ends a failed run; inspect all preceding failures.

The controller uses the real binary modules and UIFactory, fake plugin settings,
a BindableEvent-backed mock Selection, and direct handler calls. The Apply guard
case deliberately disconnects preview watchers so it tests the final synchronous
comparison independently; another case verifies normal watcher invalidation.
Camera framing uses a fake camera and checks the actual bounds passed to
`ZoomToExtents`, plus instance nonmutation.

Layout checks render UIFactory in a CoreGui ScreenGui with an exact-size Frame.
Every size exercises four views, long names/values, rename, populated library,
expanded results, capture fields, header/footer positions, horizontal bounds,
text fit, and action reachability by vertical scrolling. These are native layout
geometry checks, not real DockWidget clicks or visual approval.

The native history case uses the actual ApplyService and ChangeHistoryService
on its own workspace fixtures, then one Undo and one Redo. It changes the QA
place's history and does not reset the existing history stack. Plugin storage
uses `PresetForgeReleaseGate_v2_1_0_IsolatedSettings`; it restores the previous
value and verifies restoration even after failure. It never writes the product's
normal store key. Reopening a store in this session is not a Studio restart test.

## Human acceptance still required

- Real dock resize, clicks, focus, scrolling, theme, and visual overlap checks.
- Licensed-scene capture, mixed Selection and filtered Descendants workflows.
- Real Studio selection/camera appearance and commercial Main Undo/Redo hooks.
- Persistence across a Studio restart and final publication checks.

Run those on the commercial artifact, not the QA bundle. Disable/uninstall QA
afterward and remove the `PresetForgeReleaseGate` workspace attribute. Never
publish the QA plugin as the product. No native PASS is claimed by building or
compiling this bundle.
