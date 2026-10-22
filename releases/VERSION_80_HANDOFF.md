# Version 80 handoff

**All 15 owner-supplied Developer Product IDs are connected; checkout remains off.**

- Studio file: `StealAnOPItem_80_ProductIDs.rbxlx`, inside [Version80_Game.zip](Version80_Game.zip).
- Editable source, tests, evidence and media: [Version80_SourceAndGame.zip](Version80_SourceAndGame.zip).
- Product worksheet: [Version80/ProductSetup.csv](Version80/ProductSetup.csv); readable IDs: [Version80/PRODUCT_IDS.md](Version80/PRODUCT_IDS.md).
- Instructions: [Version80/README.md](Version80/README.md) and [private test steps](Version80/PRIVATE_TEST_STEPS.md).

V80 changes only `CashShopConfig.lua` from V79. It preserves all 312 original place objects, 106 active source files, 76 collectible designs/stats, backups and existing gameplay. The 105 other sources match V79 exactly. Cash, level and nine optional regular-power offers are configured; Tag remains free. Neither conveyor collectibles nor developer privileges are sold.

Offline verification passed 379 shop assertions, 171 saved-session assertions and 24 server integration assertions. This includes product-to-reward mapping and simulated receipt retries/durable fulfillment, not live Roblox purchases. Read [Version80/TEST_RESULTS.md](Version80/TEST_RESULTS.md) for evidence and limits.

The owner confirmed the music is **not uploaded yet**. Music ID stays `0`. Next, upload `releases/Version76/Audio/relic-rivalry-loop.ogg` from the source download through **Creator Dashboard → Creations → Development Items → Audio → Upload Asset**, wait for moderation, grant the experience permission and send the numeric audio asset ID. Ten optional custom SFX IDs also remain zero; built-in fallback effects remain available.

No Roblox products were created or edited automatically, and nothing was published to Roblox. Actual product ownership/prices, audio permissions, DataStore behavior, live receipt delivery and Studio multiplayer/device/performance tests remain unfinished. Use fixed pricing with Managed pricing off until appropriate transfer checks exist. Keep the release's `Enabled=false`, `PreviewOnly=true`; only use a controlled private test configuration after its prerequisites pass. The [full launch checklist](Version78/LAUNCH_CHECKLIST.md) still applies.
