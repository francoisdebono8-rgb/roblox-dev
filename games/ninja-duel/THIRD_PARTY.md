# Phase 6 resource audit — 10 October 2026

No downloaded third-party code, animation, audio or asset is bundled. Original local implementations are used because no named candidate supplied a legally reusable, accessible compatible component.

| Candidate | Evidence | Decision / reused files |
|---|---|---|
| [Tyrbropro/CombatSystem](https://github.com/Tyrbropro/CombatSystem) | GitHub tree has no LICENSE; README says R6 and Toolbox/pack animation/VFX ownership is not claimed. | Behavioral reference: active windows, lunge, block recoil. No copied files/assets. |
| [darrelwic15/3D-Fighting-Game-Roblox](https://github.com/darrelwic15/3D-Fighting-Game-Roblox) | No LICENSE; several assets explicitly say modified/not mine. | Behavioral reference: launch/chase/slam. No copied files/assets. |
| [Movement Base](https://github.com/cristophvolt-netizen/-Open-Source-Roblox-Movement-Base) | MIT, but tree contains only README/LICENSE/.gitignore; documented Releases API returns an empty list. | No executable donor available. No reused components, attribution not required. |
| [axiom-hitbox](https://github.com/zAxn1e/axiom-hitbox) | Named repository API returns 404; cached page is insufficient to verify release/license. | Reject dependency rather than blindly copying src. No reused files. |

Our hit windows use Roblox overlap queries plus range/facing/LOS checks on the server. Original keyed R15 choreography and primitive VFX need no third-party attribution. Authored asset replacement must have verified rights.

Development-only test runtime: [Lune v0.10.5](https://github.com/lune-org/lune/releases/tag/v0.10.5), MPL-2.0, downloaded official macOS ARM release into `/tmp`. No Lune binaries or source redistributed in the game. `tests/Combat.spec.luau` uses its Roblox datatypes with an explicit geometry adapter.

Audio references Roblox engine-bundled `rbxasset://sounds/` jump, landing, falling, swim and explosion resources. No sound file is copied or uploaded; these are baseline feedback, not a custom ninja sound pack. Verified paths in the installed official Studio content directory.
