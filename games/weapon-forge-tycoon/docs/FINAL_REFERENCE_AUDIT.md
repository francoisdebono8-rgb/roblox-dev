# Final loop audit — 15 October 2026, before implementation

Extends V02_REFERENCE_AUDIT.md (four visual references and saved captures). No Frontend Skill or borrowed assets.

| Reference | Evidence inspected | Adaptation | Boundary |
|---|---|---|---|
| Pet Simulator 99 | [Official Tech World update](https://www.biggames.io/post/pet-simulator-99-update-6), official booth presentation image 50.png, [official area database](https://db.biggames.io/wiki/areas) | Large framed world destination, readable price/owner, one unit price; item-first cards, explicit sold-unavailable feedback; geographically distinct resource pools. | Historical update checked against currently live official site. Booth image is promotional, not a live marketplace interaction test. No pets, auction bidding or extra currencies. |
| Islands (Easy.gg) | [Official experience](https://www.roblox.com/games/4872321990/Islands), [vending-machine reference](https://robloxislands.fandom.com/wiki/Vending_Machine) search excerpt | Player sets price; empty/offline has an explicit state; resources require travel and return to a production base. | Official description establishes resource/economic premise; vending behavior is secondary documentation. Not evidence of an actively updated game or touch UI. No automation factory/combat. |
| The Forge | Existing gameplay material-selection capture in V02 audit | One main material, clear selected stock, central heated weapon, strong confirmation button. | No recipe spreadsheet or copied minigame. |
| Forge a Weapon | Existing official weapon/workshop images | Large weapon silhouette; social armory beside production. | No proprietary assets. |
| Marble Merge Tycoon | Existing gameplay UI capture | Thick panel framing, large close/decision targets, rarity word plus color. | No claim to have playtested reference animations. |
| Build a Factory Tycoon | Existing official progression image | Upgrades visibly add machinery and unlocked destinations. | No conveyor subsystem. |

Implementation contract: keep Coins as the only currency, five stock counters, two weapon properties (Mining Power and Forge Luck), three resource destinations. Market cards prioritize weapon > rarity/mutation > economic properties > seller > exact Coins price > BUY. Confirm exact listing price/net proceeds and purchase price. Minimum 48px touch targets, mobile panel uses available screen, contextual forge action within physical reach only. Market means this server's offers; no global discovery claim.

Durability: escrow is saved before publishing a listing. Buyer Coins are reserved in a saved pending operation before a conditional UpdateAsync commits the listing sale. The listing record is the single sale decision; buyer delivery and seller payout reconcile idempotently from that decision. This is recoverable settlement, not a fictitious multi-key DataStore transaction. On uncertain saves, economic actions remain blocked until reconciliation. Seller can disconnect; payout is delivered on next join. Offers survive server loss in seller escrow and reappear when the seller joins a new server; they are not discoverable globally while no hosting server exists.

Policy sources: [Roblox monetization](https://create.roblox.com/docs/production/monetization), [paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items). Paid boosts and starter weapons must retain provenance; PolicyService trading restrictions apply to both participants. IDs remain unconfigured until Creator Hub setup and live commerce QA.

## Finishing pass — Book, continuity and retention

A short second check used five existing relevant experiences rather than adding features: The Forge's current official experience (resource/forge relationship); Pet Simulator 99's official Meme Cards update (categorised index with visible progress and rewards); Islands' production/sale premise; Forge a Weapon's weapon-first presentation; Marble Merge Tycoon's readable game panels. Sources above plus [PS99 Card Index rewards](https://www.biggames.io/post/pet-simulator-99-update-49) and [Roblox onboarding guidance](https://create.roblox.com/docs/production/game-design/onboarding).

Applied patterns: one immediately usable starter material; no shop interruption on spawn; book categories with silhouettes, a best-roll preview and source hint; permanent small milestones at 10/25/50/75/100%; market history and an explicit return summary before offline income. No copied assets or claims that a reference's retention numbers predict this game's results.

Long-run gate: simulations at 10/30/60/180/600 minutes initially exposed 73–90 prestiges after ten hours with linear bonuses. Production now uses diminishing capped value/luck/speed benefits and a +12% base prestige cost increase per completed prestige. Five seeds now produce 15–16 prestiges at ten hours; first prestige remains 46.8–52.8 minutes. Simulated decisions do not constitute user retention evidence.
