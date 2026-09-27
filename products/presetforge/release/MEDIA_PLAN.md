# Real-project media - pending capture

Environment: **DodgeballArena**, TheNexusAvenger's **Nexus-Battles**. Author/owner: TheNexusAvenger; upstream repository describes the original Roblox Battle remaster. [Pinned source](https://github.com/TheNexusAvenger/Nexus-Battles/blob/fd6505c3cb12c94272532e1a0b0a30bf8499fc52/src/ServerStorage/Maps/DodgeballArena.rbxmx). MIT reuse; full license and source hash in `scene/`. Use the included attribution with distributed scene files. No endorsement is claimed.

`scene/PresetForge-Media.rbxl` contains 177 retained native instances, including 21 PointLights and 18 SpotLights. Only geometry/light data is reused. Scripts, joints, textures, remote meshes, asset references and branding/UI are excluded. The saved camera uses the map's authored loading view. Appearance still needs visual review in Studio.

## Capture order and captions

1. `01-filter-arena-lights.png` - **Target the arena lights, not every object.** Configure one existing PointLight as source; save a recipe selecting Color and Brightness only. Tag intended arena PointLights `ArenaLighting`. Select the environment, use Descendants + PointLight + tag filter. Keep arena geometry visible and the actual filtering UI readable.
2. `02-exact-light-diff.png` - **Review exactly which light fields will change.** Preview that recipe; show actual before/after Color and Brightness. Verify the existing environment is unchanged before Apply.
3. `03-apply-arena-lighting.png` - **Apply one lighting recipe with native Undo.** Apply, show the real changed lighting and success state. Execute Undo then Redo and verify the same targets are restored. A nighttime view may make the change more visible, but keep geometry readable.

The tagging and source configuration above are pending setup, not features already exercised through the GUI. Existing `media/` images are earlier original-demo captures; they are not the new issue #12 deliverables. Never composite UI or manufacture an Apply result.

Exclude macOS title/menu bars, account avatar and private paths. Preserve enough viewport context to recognize a real arena. Do not replace the public plugin asset: existing ID **73596873703054**. Website media changes belong to the user.
