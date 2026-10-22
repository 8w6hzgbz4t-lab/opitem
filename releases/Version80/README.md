# V80: all 15 Developer Product IDs connected

Open `StealAnOPItem_80_ProductIDs.rbxlx` from [Version80_Game.zip](../Version80_Game.zip) in Roblox Studio. [Version80_SourceAndGame.zip](../Version80_SourceAndGame.zip) includes the editable source and verification evidence. Nothing has been published to Roblox automatically.

All 15 owner-supplied product IDs, including Dash `3720848352`, are recorded in [PRODUCT_IDS.md](PRODUCT_IDS.md), [ProductSetup.csv](ProductSetup.csv), [SetupProgress.json](SetupProgress.json) and `CashShopConfig.lua`. Roblox product ownership, experience association and current prices still require verification.

**Checkout stays off:** `Enabled=false`, `PreviewOnly=true`. Tag stays free; the shop offers cash, levels and nine optional regular powers. It sells no conveyor collectibles or developer privileges. Ordinary powers remain available for game cash, and buying one does not add an equipped slot.

Only `CashShopConfig.lua` changed from V79. The other 105 active sources, all 312 original place objects, all 76 collectible designs/stats and existing backups are preserved. V79 conveyor cleanup, carried-item limbo and theft alerts remain intact. Losing a purchased carry returns it to its pickup point without refunding the buyer; unfinished bids refund and the trusted safe Exodia respawn exception remains.

Offline checks passed: 379 shop assertions, 171 saved-session assertions and 24 server integration assertions. These use production Luau with simulated services. They do not establish live DataStore, receipt, multiplayer, device or performance readiness. See [TEST_RESULTS.md](TEST_RESULTS.md), [PRIVATE_TEST_STEPS.md](PRIVATE_TEST_STEPS.md) and the [full release checklist](../Version78/LAUNCH_CHECKLIST.md).

## Your next step: upload the music

You confirmed the music is not uploaded yet. `AudioConfig.Music.AssetId` remains `0`, so background music stays silent.

1. In [Creator Dashboard](https://create.roblox.com/dashboard/creations), select the account or group that owns the game. Go to **Creations → Development Items → Audio → Upload Asset**; labels may vary.
2. Upload **`releases/Version76/Audio/relic-rivalry-loop.ogg`** from the source download. In the earlier artwork/setup download, the same file is under `Audio/`.
3. Wait for moderation. Under the audio asset's **Permissions → Experiences**, grant the game access if required. Use the experience's **universe ID**, rather than a place ID; a separate test experience also needs permission.
4. Send back the numeric **audio asset ID** to connect it. No password or account credentials are needed.

The ten custom SFX IDs are also `0`; existing built-in fallback effects remain available. Their optional upload mapping is in [STORE_AND_AUDIO_SETUP.md](../Version79_ArtworkUpdate/STORE_AND_AUDIO_SETUP.md). Test music looping, separate music/SFX sliders, mute and saved settings after the audio is configured.

Keep **Managed pricing off** for these fixed-price products. This build does not implement Roblox Price Levels API transfer checks. Follow the private test steps before enabling any public checkout.
