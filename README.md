# Steal An OP Item

Latest cloud build: **Version 84**, based on the preserved Version 83 place.

- Game: `releases/Version84_Game.zip`. Extract `StealAnOPItem_84_CleanEarnings.rbxlx` and open it in Studio.
- Editable source, game and verification evidence: `releases/Version84_SourceAndGame.zip`.
- Clean collection earnings and the exact one-line fix for your current Studio file: `releases/Version84/README.md`.
- Owner Sell/visitor Steal, base workbenches, Favorite, plain power labels and eight-player/vault details: `releases/Version83/README.md`.
- Music ID, permission/playback steps and one-line edit for your current file: `releases/Version82/README.md` and `AudioIDs.csv`.
- Previous full art/product-icon/media bundle: `releases/Version81_SourceAndGame.zip`.
- Move/Sell controls and update instructions: `releases/Version81/README.md`.
- Music and optional SFX ready to upload: `releases/Version81_AudioUpload.zip` and `releases/Version81/AUDIO_UPLOAD.md`.
- Current configuration and private test steps: `releases/Version80/README.md`, `PRODUCT_IDS.md`, `ProductSetup.csv` and `PRIVATE_TEST_STEPS.md`.
- Revised Dragon Ball icon/collectible thumbnail, uploadable audio and beginner store/music guide: `releases/Version79_DragonBallArtworkAndSetup.zip` and `releases/Version79_ArtworkUpdate/STORE_AND_AUDIO_SETUP.md`. Gameplay stays V79; checkout remains off.
- All 15 shop icons: `releases/StoreProducts_All15_IconsAndSetup.zip`. Its original worksheet is historical; use the V80 worksheet for all 15 configured product IDs, including Dash `3720848352`.
- Current checks: `releases/Version84/TEST_RESULTS.md` and `validation-report.json`. Previous full checks: `releases/Version83/TEST_RESULTS.md`.
- Before Play: `releases/Version78/LAUNCH_CHECKLIST.md`. Use a private test experience with DataStore access; Studio uses separate TEST stores. Failed loads never create a writable blank fallback.
- Products/audio: `releases/Version78/PRODUCT_SETUP.md`, `ProductSetup.csv` and `releases/Version76/Audio/README.md`.
- Terminal handoff: `releases/VERSION_84_HANDOFF.md`.

V84 fixes the base collection sign printing long decimal tails. It now shows whole dollars available to collect, such as $1306 instead of $1306.3000000000002. Fractional earnings remain in the bank. Only that display statement changes; all 109 sources, 315 place objects and other properties are checked against V83. Offline checks pass; actual Studio and published-server verification remain required.

V83 shows Sell with a 50% confirmation on your own stored items and Steal to other players. It replaces the plain base manager block with a detailed second workbench, preserves its inventory/Move/Sell/level functions and the existing Power Lab, and labels the collectible star selector Favorite. All power labels use smaller plain text with selection outlines on button borders. Eight players get eight unique vaults/spawns; the place's saved player limit changes from 12 to 8. Verify Dashboard Maximum Players is also 8 when explicitly updating the existing published place.

V82 configures the owner-supplied music asset ID `111355988554529`. This is the only change from V81; all other source, gameplay, designs, product IDs and checkout-off flags are preserved. Audio approval, ownership, experience permission and actual playback still need Roblox verification. Saved Music mute/volume preferences remain intact.

V81 adds Move beside the existing confirmed Sell for 50%; no separate Remove button is added. In your own base, select a stored item and an empty unlocked destination. The item stays stored until the final slot is saved. Moving selections expire after 20 seconds and block selling the selected item. Carried items cannot be moved/sold, theft cancels a pending move, and sold items cannot be retrieved with stale interactions. Use the dedicated MOVE / SELL ITEMS console near your entrance or Inventory. Product IDs and checkout-off settings remain unchanged; updating the same Roblox experience keeps its products.

V80 records all 15 owner-supplied Developer Product IDs. Checkout stays off (`Enabled=false`, `PreviewOnly=true`). Only `CashShopConfig.lua` changes from V79; every other active source, place property, backup and collectible design is preserved. Offline checks verify all product-to-reward mappings and retry behavior using API adapters; actual Roblox product ownership, current prices and live fulfillment remain unverified.

V79 fixes unsold items piling up at the conveyor exit, retains carried items after their holograms disappear, removes the automatic carry timeout, adds owner-only taken/recovered/stolen banners, and makes power text smaller/lighter. Power hits still return paid carries to their original pickup point without refunds. All 76 collectible designs, names, stats and spawn weights are preserved.

V78 saving, recoverable theft transfers, receipt handling, ten powers, aimed Slow Field/Ki Blast, auto-lock Lightning, fading Slam rubble, select-then-activate controls, saved audio sliders and private triple-jump Superman flight remain included. Developer tools remain exclusive to `Goverment_cheesee`; no developer perks or conveyor collectibles are sold.

Music ID `111355988554529` is now configured. Confirm approval and grant the intended experience access under the audio asset's Permissions → Experiences, then start a fresh Play session with Music on and its volume above zero. Custom SFX uploads are optional for now; existing built-in fallback cues remain configured. Actual Roblox Studio multiplayer, native input, live storage latency/budgets, audio permissions/playback and receipts still need owner testing. Public launch readiness is unverified. Nothing has been published to Roblox by this cloud build.

Main/checkout HEAD remain unchanged. Downloads are handed off on `codex/version-63-handoff`; earlier releases and the original uploaded game remain preserved. Active editable sources: `roblox/v84-game/`.
