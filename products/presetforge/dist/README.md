# PresetForge 2.1 release package

`PresetForge-v2.1.0.rbxm` is the customer-ready Roblox Studio plugin model built from the production sources in this release. The 2.0.0 artifact is retained as a historical release.

## Install locally

1. Open a blank place in Roblox Studio and show **View > Explorer**.
2. Right-click `Workspace` and choose **Insert from File...**.
3. Select `PresetForge-v2.1.0.rbxm`.
4. Right-click the inserted `PresetForge` model and choose **Save as Local Plugin**.
5. Delete the temporary model without saving the blank place.
6. Open PresetForge from the **Plugins** toolbar. Restart Studio if the button is not immediately visible.

## Verified contents

The model contains one `Main` Script and seventeen production ModuleScripts under `Modules`. The final-binary gate compares every Source and the complete hierarchy to production files. It excludes Studio tests, QA fixtures and project data. See `../tests/FINAL_GATE.md` for reproduction and `../v2/RELEASE_GATE.md` for actual native results.

## SHA-256

```text
54746b6e7798094155bab145288723e19acc9e8bba010161d83f79e3649f1f15  PresetForge-v2.1.0.rbxm
```
