# Roblox Studio technical checklist

Use a published test experience and low-price test products. Developer Product tests may spend real Robux.

- [ ] With the default `Config`, no catalog entry or purchase prompt is available.
- [ ] Startup reports invalid placeholder IDs without exposing player or receipt identifiers.
- [ ] Each enabled Developer Product registers a filtered `BindReceiptHandler` using its own ProductId.
- [ ] An existing `ProcessReceipt` still receives products not filtered by BrickKit.
- [ ] A conflicting receipt binding disables only the affected product and does not overwrite the existing handler.
- [ ] Closing `PromptProductPurchaseFinished` never grants a reward.
- [ ] A valid receipt grants from server-side Config params, never client arguments.
- [ ] Replaying a receipt on one server does not grant twice.
- [ ] With API Services disabled or DataStore failing before grant, the reward is not granted and the receipt returns `NotProcessedYet`.
- [ ] Simulate a ledger write failure after grant; the same server does not grant again and logs the documented retry risk.
- [ ] Test the same receipt across two servers and confirm the documented non-absolute deduplication behavior.
- [ ] Owned and unowned Game Passes produce the expected server-side result.
- [ ] `WalkSpeedMinimum` survives respawn and repeated application without increasing above the configured minimum.
- [ ] Unknown IDs, malformed arguments, extra arguments, and rapid remote calls never open a prompt or grant a reward.
- [ ] `GetCatalog` returns only active, successfully bound entries and never exposes handler names or params.
- [ ] A pre-existing `ReplicatedStorage/BrickKitMonetization` causes a clear startup error and is not overwritten.
- [ ] No UI beyond the minimal client placeholder is installed by this milestone.
