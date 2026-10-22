# Steal An OP Item

Latest cloud build: **Version 80**, based on the preserved Version 79 place.

- Game: `releases/Version80_Game.zip`. Extract `StealAnOPItem_80_ProductIDs.rbxlx` and open it in Studio.
- Editable source, game, tests, reports, product icons and audio: `releases/Version80_SourceAndGame.zip`.
- Current configuration and private test steps: `releases/Version80/README.md`, `PRODUCT_IDS.md`, `ProductSetup.csv` and `PRIVATE_TEST_STEPS.md`.
- Revised Dragon Ball icon/collectible thumbnail, uploadable audio and beginner store/music guide: `releases/Version79_DragonBallArtworkAndSetup.zip` and `releases/Version79_ArtworkUpdate/STORE_AND_AUDIO_SETUP.md`. Gameplay stays V79; checkout remains off.
- All 15 shop icons: `releases/StoreProducts_All15_IconsAndSetup.zip`. Its original worksheet is historical; use the V80 worksheet for all 15 configured product IDs, including Dash `3720848352`.
- Changes and test results: `releases/Version80/TEST_RESULTS.md` and `validation-report.json`.
- Before Play: `releases/Version78/LAUNCH_CHECKLIST.md`. Use a private test experience with DataStore access; Studio uses separate TEST stores. Failed loads never create a writable blank fallback.
- Products/audio: `releases/Version78/PRODUCT_SETUP.md`, `ProductSetup.csv` and `releases/Version76/Audio/README.md`.
- Terminal handoff: `releases/VERSION_80_HANDOFF.md`.

V80 records all 15 owner-supplied Developer Product IDs. Checkout stays off (`Enabled=false`, `PreviewOnly=true`). Only `CashShopConfig.lua` changes from V79; every other active source, place property, backup and collectible design is preserved. Offline checks verify all product-to-reward mappings and retry behavior using API adapters; actual Roblox product ownership, current prices and live fulfillment remain unverified.

V79 fixes unsold items piling up at the conveyor exit, retains carried items after their holograms disappear, removes the automatic carry timeout, adds owner-only taken/recovered/stolen banners, and makes power text smaller/lighter. Power hits still return paid carries to their original pickup point without refunds. All 76 collectible designs, names, stats and spawn weights are preserved.

V78 saving, recoverable theft transfers, receipt handling, ten powers, aimed Slow Field/Ki Blast, auto-lock Lightning, fading Slam rubble, select-then-activate controls, saved audio sliders and private triple-jump Superman flight remain included. Developer tools remain exclusive to `Goverment_cheesee`; no developer perks or conveyor collectibles are sold.

The owner has not uploaded the original music yet, so `AudioConfig.Music.AssetId` remains zero. Next, upload `releases/Version76/Audio/relic-rivalry-loop.ogg` through Creator Dashboard → Creations → Development Items → Audio → Upload Asset, then send its numeric audio asset ID after approval and experience permission. Custom SFX uploads are optional for now; existing built-in fallback cues remain configured. Actual Roblox Studio multiplayer, native input, live storage latency/budgets, audio permissions and receipts still need owner testing. Public launch readiness is unverified. Nothing has been published to Roblox by this cloud build.

Main/checkout HEAD remain unchanged. Downloads are handed off on `codex/version-63-handoff`; earlier releases and the original uploaded game remain preserved. Active editable sources: `roblox/v80-game/`.
