# Forge & Flex — Weapon Forge Tycoon

Standalone six-player Roblox game: collect one material → heat → three hammer strikes → reveal → sell NPC / keep / equip / display / merge / list → upgrade → new resource zones → prestige. No combat, pets, external assets or cross-project imports.

## Open and build

Open `dist/ForgeAndFlex.rbxlx` in Roblox Studio and press Play. The world is built at runtime; the edit viewport initially contains no map. An unpublished Studio place uses unsaved local profiles and disables purchases. Publish only the release file, never `ForgeAndFlex-QA.rbxlx`.

```sh
python3 games/weapon-forge-tycoon/build.py
python3 games/weapon-forge-tycoon/build.py --qa
LUAU=/path/to/official/luau python3 games/weapon-forge-tycoon/tests/run.py
```

Python standard library builds the place. Official Luau CLI compiles all source and exercises the production game transitions. Build manifests contain artifact and source SHA-256 fingerprints. QA and release gameplay sources are checked for parity; QA alone adds fixtures/native assertions.

## Play

Four Iron units let the first forge start immediately. Return to your anvil for the contextual orange action or E / controller X. Heat, then tap three strikes; three timely gold hits improve value and luck. A late hit has no penalty. Each started forge consumes one selected material; incomplete jobs do not survive reconnect. Auto Forge uses stock and stops when it runs out or inventory fills.

Walk to Village Mine for Iron/Steel, Magma Quarry for Obsidian/Emberstone, Arcane Ruins for Arcane Crystal. Hold a deposit prompt to collect a batch. Server verifies distance, unlocked zone, stock cap and a per-player/per-material cooldown. Equip one stored weapon: Mining Power reduces that cooldown; Forge Luck slightly changes rare weights. Axes/hammers favor mining, katana/Arcane rolls favor luck. These are the only two weapon properties.

Inventory cards use 3D models. Equipped, displayed or locked weapons cannot be sold, merged or listed. Displayed weapons must be stored before equipping. Merge previews three equal-rarity weapons and deterministically raises rarity by one, retaining the first weapon's parts/material/mutation; paid provenance propagates from any input. Auto Merge uses the same eligibility rules and configured maximum input rarity.

The Book has Weapons, Materials, Rarities, Mutations and Special Variants. Each records first discovery, best found value/roll and source. Missing entries use silhouettes. Permanent completion rewards: 10% small luck, 25% rack slot, 50% forge cosmetic, 75% Collector title, 100% Master aura. Selling/merging/prestige never remove discoveries or best rolls. Legacy discoveries without a surviving item honestly show that another roll is needed to record metadata.

Prestige resets Coins, material stock, zones and main upgrades. Weapons, escrow listings, sales history, collection, settings, purchases and cosmetics remain. Keep at most 30 inventory weapons before resetting the capacity upgrade. Production/luck/speed bonuses diminish and are capped; each prestige costs 12% of the base amount more than the previous one. Starting Steel increases modestly. See the economy report for assumptions and measured simulations.

## Player market — actual scope

This is **server-local discovery with persistent escrow/settlement**, not a global auction house. Offers are visible in their hosting server. Three free listing slots, +2 optional pass, chosen integer Coins price, 8% rounded-up tax, 24-hour expiry, cancellation, filters, three sorts, exact-price purchase confirmation and last 20 purchases/sales. Cards show model/name/rarity/mutation/material/properties/base value/seller/price/expiry. An inspected public armory weapon links to its owner's offers.

Seller disconnect does not remove offers from that running server. Proceeds reconcile when the seller returns. If the hosting server ends, escrow survives; offers are republished when the seller joins a new server. No global offline search is claimed. At the currency cap, excess proceeds remain in a saved wallet until there is room.

Persistence protocol:
1. Save seller profile with weapon removed from inventory and held in listing escrow.
2. Publish immutable listing record through `UpdateAsync`.
3. Save buyer's exact Coins reservation and pending transaction before deciding a sale.
4. Conditionally commit the listing once. This single record is the authoritative sale decision.
5. Idempotently deliver to buyer and settle seller escrow/net proceeds in their own profile saves.

Roblox has no atomic transaction spanning arbitrary user keys. This is recoverable settlement, not a claim of cross-key atomic visibility. Uncertain saves block economic actions until retry/reconciliation; reconnect resumes from the saved pending operation. Cancellation/expiry return items once, or retain cancelled escrow safely until inventory space exists. A store adapter/discovery boundary allows a later global catalogue without replacing settlement.

Coin Packs/Starter Coins cannot directly pay other players: market uses the earned portion of Coins. Paid item provenance propagates through boosts, equipped paid-luck weapons and merges. Both participants are checked through PolicyService. Resource boosts conservatively mark subsequent production paid until prestige; eligibility is fail-closed. Configure real IDs only after policy and live receipt QA.

## Persistence, boundaries and launch

`WeaponForgeTycoon_v1`: versioned profile, exclusive 180-second lease, autosave/leave/shutdown saves, retry/backoff, stale-owner rejection, future-schema rejection. Existing store identity is preserved. `WeaponForgeMarket_v1`: immutable listing identity and sale/cancellation decision. Never manually delete committed listing records while pending deliveries might reference them.

Receipt grant and marker share a durable profile save; ACK only after success, retries grant once. Nil IDs render unavailable instead of prompting fictitious products. Audio IDs are intentionally unconfigured; the game is silent until licensed audio is supplied.

Only `games/weapon-forge-tycoon/` belongs to this product. See `QA_REPORT.md`, `ECONOMY_REPORT.md`, `SETUP_MONETIZATION.md`, `PUBLISH_CHECKLIST.md` and `docs/FINAL_REFERENCE_AUDIT.md` for evidence and remaining release gates. A passing build alone is not commercial playtest approval.
