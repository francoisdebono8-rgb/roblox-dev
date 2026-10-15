# Forge & Flex ⚒️ Weapon Tycoon

A standalone Roblox incremental game. Forge → sell / display / keep → quick merge → upgrades → Magma / Arcane → prestige. No combat, trading, external assets, packages or cross-project dependencies.

## Open / build

Open `dist/ForgeAndFlex.rbxlx` in Roblox Studio and press Play. The world is constructed on the server at runtime, so the edit viewport starts empty. An unpublished Studio place uses unsaved local profiles; the Settings menu identifies this mode and purchases are disabled. The release artifact never permits this fallback on a live server.

```sh
python3 games/weapon-forge-tycoon/build.py
python3 games/weapon-forge-tycoon/build.py --qa
LUAU=/path/to/luau python3 games/weapon-forge-tycoon/tests/run.py
```

Python 3 standard library builds the place; official Luau CLI runs tests. `--qa` adds native assertions and forces memory-only profiles in Studio. **Publish the release artifact only.** Never publish a QA file. Source files are authoritative; rebuild after edits. `dist/build.json` identifies the exact release hash.

## Controls

Mouse/touch: orange forge button; tap during heating for up to three acceleration hits. Walk to your anvil and use E / controller X. Controller R2 for forge/hammer, Y for inventory, B to close panels; selectable buttons support Roblox UI navigation. Sell and upgrade benches also open the respective menus. Inventory cards open Sell / Display / Lock actions. A locked weapon cannot be sold or merged. Displayed weapons cannot be sold or merged. Store a displayed weapon to free its slot.

Quick Merge previews exactly three inputs and the result before confirmation. The first input supplies the blueprint and mutation; rarity increases by one. Auto Merge uses the same rules, consumes the lowest eligible rarity first, and honors the configured maximum **input** rarity. It may consume mutations: lock anything you want to keep. Auto Forge stops on a full inventory.

## Layout

- `src/Shared/Config.luau`: single economy, rarity, mutation, weapon, sound and monetization configuration. No hidden balance constants in UI.
- `Economy`, `Profile`, `Actions`: portable pure game transitions and profile migration; same modules run in Studio and CLI tests.
- `WeaponModel`: nine original primitive silhouettes, reused for Viewports and public racks.
- `src/Server`: profile lease / persistence, plots, purchase receipts, analytics and remote dispatch.
- `src/Client`: responsive menus, local forge animation, bounded VFX and input.

The builder translates portable sibling module requires into Roblox Instance paths. No plugin code is embedded.

## Persistence and purchases

One `WeaponForgeTycoon_v1` DataStore record per user stores profile plus a 180-second session lease. `UpdateAsync` acquires and renews the unique lease; a second server cannot load an unexpired session. Autosave every 30 seconds, leave and shutdown save. Four retry attempts with capped backoff. After prolonged failed renewal, the session closes instead of continuing to mutate an uncertain profile. Future schema versions are rejected. Unfinished forge jobs are not serialized.

Developer product grant and receipt marker are saved together. `PurchaseGranted` is returned only after the profile transaction succeeds. A failed acknowledgement can retry without granting again. Receipt markers are retained permanently; do not prune them casually. Before very large purchase histories approach DataStore record limits, migrate archival storage transactionally.

All game actions are server-authoritative, rate limited and non-yielding. No client value/rarity/price is accepted. Public rack models are anchored and non-collidable. Coins, inventory and settings changes never trust client snapshots.

## Product choices

First craft always uses Iron Saber so even a Common sale buys the first 20-coin speed upgrade. Rarity and mutation still roll normally. Prestige resets **weapons too**, explicitly warned twice, while preserving collection discoveries, purchases, settings, lifetime stats and stars. Starter Pack is a one-time pass. No optional boosts, daily system or leaderboard in V0. Two shop tabs suffice without empty tabs. Landscape sensor is the intended mobile orientation; portrait is not a launch target.

Audio hooks intentionally have nil IDs: silent operation is expected until licensed, reviewed audio is configured. No fictitious audio or commerce IDs. See `SETUP_MONETIZATION.md`, `PUBLISH_CHECKLIST.md`, `THUMBNAIL_BRIEF.md` and `QA_REPORT.md` before release.
