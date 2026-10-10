# R15 animation replacement seam

Phase 6 supplies original, locally sampled key choreography in `Client/Presentation.luau`. These timed poses replace the static Phase 5 poses but are not final-quality published animation clips. Combat authority stays on the server.

Optional authored replacement: create original R15 clips under the owning Roblox account; publish them and fill each fighter's `AnimationIds` with the numeric IDs named by `Server/Animation.luau`'s `Required` list. The full set prevents mixing conflicting pose systems. Runtime sets `AuthoredAnimations` to disable local posing after successful load.

Required coverage includes locomotion/air/walls, guard/hit, four strikes, heavy/launcher, chase/air strikes/slam, grab/directional and upward throw, knockdown/wakeup, techniques, substitution and defeat. Use server attack startup/active/recovery values from `Shared/Attacks.luau` when authoring contact timing. Animation markers may add cosmetic hooks; never use client markers to authorize damage.

No account publication is needed to test the current place. Authored replacement and final visual feel require native/human verification; no placeholder-quality animation is labelled final.
