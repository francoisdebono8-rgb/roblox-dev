# Existing-asset update checklist

- [x] Keep existing asset **73596873703054**. No second PresetForge asset created.
- [x] Verify `dist/PresetForge-v2.1.0.rbxm`: SHA-256 `54746b6e7798094155bab145288723e19acc9e8bba010161d83f79e3649f1f15`.
- [x] 41/41 native checks plus real GUI Apply/Undo/Redo and full restart Local/Project persistence. See `../v2/RELEASE_GATE.md`.
- [x] Complete production UI walkthrough and three genuine images in `media/v2.1`; see `MEDIA_PLAN.md`.
- [x] Studio overwrite of **73596873703054** returned **Successfully submitted!**. See `../v2/studio-update-success.png`. Do not resubmit this release.
- [ ] User updates existing Creator Hub listing using `CREATOR_STORE.md`, version `2.1.0`, USD **4.99**, and reviewed images. User retains all account/payment/tax/distribution steps.

For a later binary update, Studio must explicitly target asset **73596873703054**. Stop if update-vs-new is ambiguous.
