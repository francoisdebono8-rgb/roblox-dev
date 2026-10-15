# Monetization setup

Create these assets under the **same experience** in Creator Hub. Targets below are setup suggestions, never displayed as live prices. Put each numeric ID in `src/Shared/Config.luau` → `C.Monetization.<Key>.Id`, replacing nil, then rebuild and publish the release place. Keep IDs stable after launch.

| Key | Type | Name | Target Robux | Grant |
|---|---|---|---:|---|
| AutoForge | Game pass | Auto Forge | 99 | Enables optional repeated forging in Settings |
| AutoMerge | Game pass | Auto Merge | 129 | Enables optional merge with input rarity limit |
| DoubleCoins | Game pass | 2× Coins | 149 | 2× sale and rack income; not purchased coin grants |
| DisplaySlots | Game pass | +2 Display Slots | 79 | Six rack slots, applied once |
| Starter | Game pass | Starter Pack | 49 | 500 coins once, +50% rare weight for 10 minutes, gold furnace trim |
| Small | Developer product | Coin Pouch | 29 | ~5 minutes current income; floor 250 / cap 100,000 |
| Medium | Developer product | Coin Chest | 79 | ~20 minutes; floor 1,200 / cap 500,000 |
| Large | Developer product | Coin Vault | 199 | ~60 minutes; floor 4,000 / cap 1,500,000 |

The current income estimate uses the current zone's middle blueprint × rarity expectation × value multipliers / forge duration plus rack income. Amount is calculated on the server at receipt time and may change with progression. The shop describes it as approximate. GetProductInfoAsync provides actual displayed prices; missing metadata, nil IDs, unavailable assets and unsaved sessions disable the CTA. Purchase prompts only follow an explicit Buy action. There is no spawn prompt or timed offer.

Before opening sales, test on a private published experience: new pass ownership after purchase and rejoin; Starter granted only once; coin receipt replay after network failure; cancelled prompts; unknown product deferred; nil IDs; save outage returns NotProcessedYet; two server joins do not share a profile lease. Use Roblox's supported purchase testing workflow and inspect the actual DataStore profile/receipt marker. Do not use real paid transactions as an unattended test.

Do not add a second ProcessReceipt callback elsewhere. All products must be routed through MonetizationService. Do not grant from PromptProductPurchaseFinished.

Reference: [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService), [player data and purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing).
