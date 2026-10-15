# Weapon Forge Tycoon — QA report

Date: 15 October 2026. **Playable local release candidate; public commercial release is gated on the published-experience checks below.** This report does not certify untested cloud purchases, real device performance or six-client load.

## Source / artifacts

Started from fetched `origin/main` at `1baf3ef5e811b1b86c06aed63ccc760edea7b5cf`, in an isolated checkout on `codex/weapon-forge-tycoon-v0`. Original checkout changes were preserved. Only `games/weapon-forge-tycoon/` is changed versus that remote base.

Release: `dist/ForgeAndFlex.rbxlx`

- SHA-256: `869328d40884f243a1bb6c44c028dd48663bbdedf705105d783a83c8ec685631`
- Gameplay source SHA-256: `63453e972f8e74b1aab0eb77f38f72402b7ae267f56e86f4a65fb7849433e494`

Native final QA: `dist/ForgeAndFlex-QA.rbxlx`, opened as `/tmp/WFT-ReleaseQA-6.rbxlx` to ensure Studio loaded the new file rather than an already-open document.

- SHA-256: `45c207313b98876ef4681608ae9e13cde4427326acc87e0ce6a72ffb27db6d82`
- Same gameplay source fingerprint as release. Automated XML comparison confirms all shipped scripts are identical, apart from QA's explicit memory-mode prefix. NativeQA and the memory bootstrap are excluded from release.
- Studio: 0.743.0.7431133. Luau CLI: official 0.742 macOS distribution from luau-lang/luau.

## Automated results — PASS

`LUAU=/path/to/luau python3 games/weapon-forge-tycoon/tests/run.py`

- All 14 Luau sources compile; deterministic release/QA place builds; source parity and QA exclusion.
- 18 core test cases: rarity/mutation weights, insufficient funds, double sell, locked/displayed sale rejection, merge consumption/replay/duplicate IDs/rarity restrictions, hammer/cooldown, max upgrades, zone costs and cap, prestige retention/reset, receipt marker replay, profile load and old/future schema handling, malformed data and duplicate IDs, offline cap/clock reversal, pass idempotency, nil commerce IDs, rack and inventory capacity.
- Production DataService with contended/failing adapter: active lease refuses a second server, serializable save excludes in-flight craft, failed save preserves the durable record, retry/release/rejoin succeeds, stale owner cannot write, expired lease can be recovered.
- Production MonetizationService callback with failing save adapter: failed persistence returns NotProcessedYet, retry grants no second benefit, successful acknowledgement requires durable save, repeated delivery is idempotent; unknown products, missing players, busy and memory sessions defer.
- Architecture checker passed against this checkout using the existing workspace checker from the original checkout (remote main did not contain that tool). No dynamic external imports were introduced; sibling requires become fixed Roblox Instance paths during build.

Evidence is in `qa/{all-tests,core-tests,persistence-tests,receipt-tests,build-tests,architecture}.txt`. Tests execute the production modules, not a Python rewrite of the economy.

## Economy simulation — PASS as an initial balance model

Five deterministic seeds, free active player, three acceleration hits, four seconds of decision/walking allowance per craft, first four above-common weapons displayed, subsequent output sold; upgrades bought with a bounded fraction of cash. Explicit assumptions live in `tests/simulate.luau`.

| Milestone | Observed range |
|---|---:|
| Zone 2 | 10.6–11.9 min |
| Zone 3 | 27.1–28.6 min |
| First prestige | 43.6–46.0 min |

10/30/60-minute snapshots for every seed are in `qa/economy-simulation.txt`. The model is not a measured player-retention study. Fast menu use, passive play, saving rare items and purchases change the timing. No instant runaway inflation was observed; first prestige is near the fast edge of the requested window.

## Native Studio results

Multiple Play Solo sessions were used to find and fix:

1. Unpublished places threw at DataStore module initialization. Store acquisition is now lazy; unpublished Studio and explicit local QA use unsaved profiles. Live servers never silently fall back to memory.
2. Initial Roblox character placement could override the workshop teleport. Every plot now has its own SpawnLocation and RespawnLocation assignment, plus a deferred reposition. Final native assertion checks proximity to the assigned workshop.
3. The orientation token initially selected portrait. Final file uses LandscapeSensor. Portrait is intentionally outside the configured launch modes.
4. Result actions originally required scrolling. Sell / Display / Keep now share one row, with a compact weapon preview above them on short screens. Touch navigation leaves room for the movement and jump controls.

Final native assertions PASS: six constructed plots, nine renderable weapon models, anchored/non-collidable weapon parts, native HttpService JSON profile round trip and assigned-workshop spawn. `qa/native-final-output.txt` records the final-artifact run. There were no WFT CreatorError entries in that final run at capture. Earlier exploratory command-bar test mistakes are not counted as game-script failures.

Observed through native UI across the iteration sessions: forge/reveal, sale, inventory, display and passive rate, upgrades, collection entry points, merge preview with three inputs and expected output, Zone 2/3 HUD and unlock costs, and the two-stage prestige review/reset. Development-only seeded coins/items were used in an unsaved server session to reach late progression; no published player profile was touched.

Final-artifact mobile smoke: iPhone XR landscape; workshop spawn and contextual anvil prompt, forge heat/hammer progress, result silhouette/rarity/value, Sell/Display/Keep row, sale advancement to the first-upgrade tutorial step, rack income and inventory. Final-artifact desktop inventory was also inspected after switching the simulator back to the current computer device. Native screenshots are retained, not generated mockups.

| Gate | Status / scope |
|---|---|
| Native model / JSON / spawn assertions | PASS on final QA artifact |
| Desktop and mobile local free loop | PASS smoke; screenshots retained |
| Nil-ID shop | PASS native smoke in preceding candidate; final change only refines unavailable copy; nil-ID logic also tested |
| Late progression / prestige | PASS transitions in CLI, native UX exercised in preceding candidate |
| Exact 16:9 desktop preset | UNVERIFIED; desktop smoke used Studio's current-device viewport |
| Physical controller | UNVERIFIED; bindings/selectable controls implemented |
| Six simultaneous local clients, cross-client racks, death/respawn | UNVERIFIED; simulator control began returning noWindowsAvailable/timeouts before this pass could run |
| Physical phone FPS / memory | UNVERIFIED; emulator visual checks do not establish device performance |
| Real DataStore rejoin/offline and cross-server lease | BLOCKED until a private experience exists with appropriate API access; adapter tests passed |
| Real pass/product receipts and metadata | BLOCKED until experience-owned asset IDs exist; callback fault tests passed |
| Analytics ingestion / commerce conversion | BLOCKED until a published experience receives eligible traffic |

The incomplete gates are **not** silently marked PASS. Do not open public monetization before the relevant private/live checks pass.

## Screenshot index

- `release-mobile-reveal.png`: final source artifact, actual iPhone XR landscape result with weapon preview and all three decisions visible.
- `release-desktop-inventory.png`: final source artifact, actual desktop inventory with visible rack state/income.
- `native-mobile-spawn.png`, `native-final-reveal.png`, `native-merge-preview.png`, `native-prestige-review.png`: preceding candidate evidence for fixes and native progression review.
- Files suffixed `before` are intermediate evidence, not final approval images.

## Remaining Roblox actions

The complete account-side sequence is in PUBLISH_CHECKLIST.md:

1. Publish the release place as a **new private experience**; configure six-player capacity and supported devices.
2. Validate the unverified local/native gates above and private save/rejoin/offline/cross-server scenarios before public release.
3. Create/configure five passes and three repeatable products, set their IDs in Config, rebuild/re-publish; privately verify real metadata, ownership and receipt persistence.
4. Upload reviewed icon/thumbnails, set title/description, complete platform questionnaires and distribution/access configuration.
5. Enable public access only after those gates pass. Observe tutorial, 10-minute retention, Zone 2, shop and purchase analytics.

No game was published or existing Creator Store/game asset overwritten. No paid transaction was initiated. Audio is intentionally silent with nil hooks; supplying approved audio is optional. Leaderboards, daily systems and P2 features are deferred.
