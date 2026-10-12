# Bangla animation setup — Phase 6B

The old procedural punch/kick timeline has been removed. The imported Bangla moves are R6 animation references; the fighters remain R15. `DonorAnimations.retarget` preserves their sequence timing/transforms and maps the R6 joint bases into the R15 hierarchy. That mapping still needs visual QA on real donor clips.

In Studio, `Animation` attempts to retrieve and retarget Punch, HardSmack, MegaPunch and Parry. Successful sequences appear in `ServerStorage/BanglaR15Sequences`; temporary registered tracks allow Studio playback. Failures are explicit `[NinjaDuelAnimation] BLOCKED` messages and the actor attribute `DonorAnimationStatus=Blocked`. A native gate checks actual loaded track length and playback. No procedural combat animation fallback masks a failure.

The public asset download endpoint returned HTTP 403 for Punch on 10 October 2026. This does not prove the authenticated Studio account can or cannot load the other assets. Studio window control also timed out, so final native playback/visual acceptance is pending.

Manual publication step, if authenticated Studio can fetch the sequences:

1. Open the normal place and Test. Copy `ServerStorage/BanglaR15Sequences`, Stop, then paste that folder into the edit place.
2. Preview each sequence on an R15 rig in Animation Editor. Check arm/root orientation and choreography; retain the donor timing.
3. Publish those four retargeted sequences under the **same creator/group as the experience** and grant the experience animation permissions.
4. Put the four resulting R15 IDs in `../../src/Shared/AnimationBindings.luau` (`Punch`, `HardSmack`, `MegaPunch`, `Parry`) and rebuild both places.
5. Run the QA place and the 15-step normal-place acceptance route. Published play requires those owned IDs; temporary Studio registration is insufficient.

If Studio also denies access, obtain the four original KeyframeSequences or explicit asset access from the donor author. Do not replace them with guessed local poses and call the migration complete.

The missing ninja branches currently reuse donor moves. A dedicated launcher, kick, slam, grab/throw and victim reaction clip set remains a **visual acceptance gap**, not a validated donor feature. Their server mechanics are preserved; do not describe the candidate as a finished battleground fighter until native choreography and human feel are accepted.
