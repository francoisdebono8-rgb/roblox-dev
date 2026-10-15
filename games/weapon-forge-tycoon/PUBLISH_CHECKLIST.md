# Publication checklist

## Dashboard / Studio actions

1. Open `dist/ForgeAndFlex.rbxlx` (not QA) and Publish to Roblox **as a new experience**. Do not overwrite any existing game/plugin. Keep it private for validation.
2. In experience configuration set server capacity to **6**, enable desktop/mobile, retain landscape orientation. Test the actual private place on a phone; enable console only after controller QA. Complete the truthful content maturity/compliance questionnaire, including the actual randomized item and monetization design. No paid RNG product is implemented, but passes can modify free-earned progression; answer the current platform questions as presented.
3. For Studio persistence testing only, enable API Services on the private test experience. Test save → leave → rejoin, offline income, simultaneous server lock and purchase persistence. Live DataStores require a published universe. Do not test against production player data.
4. Create the eight monetization assets listed in SETUP_MONETIZATION.md, paste IDs into Config, rebuild and publish the updated release. Verify metadata/prices and durable receipt handling privately before enabling sales.
5. Upload a reviewed icon and at least two thumbnails using THUMBNAIL_BRIEF.md. Configure title/description below.
6. Review QA_REPORT.md. Complete any gates marked unverified before public release. Configure public access/distribution only after those gates pass.

## Title

Forge & Flex ⚒️ Weapon Tycoon

## Description

⚒️ FORGE powerful weapons
✨ Discover RARE mutations
🔀 MERGE weapons into better rarities
🏛️ DISPLAY your best creations for passive income
💰 SELL the rest and upgrade your forge
🔥 Unlock Magma & Arcane Forges

Can you forge a MYTHIC weapon?

## Analytics validation

Server wrapper uses current AnalyticsService LogCustomEvent and onboarding funnel calls. Published production only; Studio skips uploads. Events: session_start, tutorial_start, tutorial_complete, first_forge, first_sell, first_upgrade, first_merge, first_display, zone_2_unlock, zone_3_unlock, prestige, shop_open, purchase_prompt, purchase_success, session_seconds and session_10_minutes. First-action flags persist. Onboarding arrival and completion bound the initial funnel; first action events locate drop-off. Read actual dashboards after traffic has accumulated, not Studio logs. session_seconds is a leaving-session aggregate; session_10_minutes independently records retention even if the final leave event is lost.

Track tutorial completion, first upgrade, 10-minute retention, Zone 2 conversion, shop openings and prompt → success before changing prices. Compare cohorts before/after tuning. Avoid adding new systems until the free loop has been tested with real players.

Reference: [AnalyticsService](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService).

## Optional after launch

Reviewed audio IDs/music, lifetime-value/prestige leaderboard, simple daily chest. Further zones, combat, trading, pets and quests remain outside V0.
