# Real-project media - PresetForge 2.1.0

Environment: **DodgeballArena**, TheNexusAvenger's **Nexus-Battles**. Author/owner: TheNexusAvenger; upstream repository describes the original Roblox Battle remaster. [Pinned source](https://github.com/TheNexusAvenger/Nexus-Battles/blob/fd6505c3cb12c94272532e1a0b0a30bf8499fc52/src/ServerStorage/Maps/DodgeballArena.rbxmx). MIT reuse; full license and source hash in `scene`. Use the included attribution with distributed scene files. No endorsement is claimed.

`scene/PresetForge-Media.rbxl` contains 177 retained native instances, including 21 PointLights and 18 SpotLights. Only geometry/light data is reused. Scripts, joints, textures, remote meshes, asset references and branding/UI are excluded. A disposable copy was configured and visually reviewed in Studio for issue #16.

## Capture order and captions

1. `media/v2.1/01-target-the-arena.png` - **Target the arena lights, not every object.** Actual Descendants + PointLight + ArenaLight name + ArenaLighting tag filters; one environment selected.
2. `media/v2.1/02-review-exact-changes.png` - **Review exact changes first.** 176 scanned, 21 compatible, 20 changed, one matching, 155 ignored; 40 exact Color/Brightness writes. Arena asserted unchanged during Preview.
3. `media/v2.1/03-apply-safely.png` - **Apply one lighting recipe with native Undo.** Actual success after 20 PointLights changed. Unselected properties/tags/attributes verified unchanged; subsequent Edit > Undo and Edit > Redo both verified against instance state.

Captured from the real installed commercial 2.1.0 artifact on 2026-09-27. These are uncomposited macOS region screenshots at 2560 x 1272. The crop excludes title/menu bars, account avatar and Command Bar. No generated UI, retouching or fabricated results. Earlier images outside `media/v2.1` are historical and are not the issue #16 deliverables.

Excluded macOS title/menu bars, account avatar and private paths. Viewport context preserves the real arena. Keep the existing public plugin asset **73596873703054**, successfully updated from Studio for 2.1.0. Website media changes belong to the user.
