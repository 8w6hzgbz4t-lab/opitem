# V81: Move beside Sell

Open `StealAnOPItem_81_BaseItemMove.rbxlx` from [Version81_Game.zip](../Version81_Game.zip) in Studio. [Version81_SourceAndGame.zip](../Version81_SourceAndGame.zip) contains the editable Lua, tests, game, backups, product icons and audio. This build has not been published to Roblox.

Your existing **Sell for 50%** is the removal feature. There is no new Remove button. Selling still asks for confirmation. Sold items cannot subsequently be carried, stolen, moved or sold again.

Inside your own base, use the **MOVE / SELL ITEMS** console near the entrance, or open **Inventory**. Select an item, choose **Move to an empty slot**, then choose the destination. Ground-floor slots 1–8 are always available; upstairs slots unlock at base level five. Occupied and reserved slots cannot be selected. The original item stays on its pedestal until its new slot is saved. Moving adds no item or equipped-power slot and costs no cash.

Move selection lasts 20 seconds. **Cancel Move**, Back or closing the menu leaves the item in its original slot. You cannot sell an item during its active move selection or move/sell an item being carried. Death, buying/bidding and a successful theft invalidate the selection. Move does not grant theft immunity: if a thief gets the item first, the old move token cannot retrieve it. Final movement and sales use the existing durable save path before the server acknowledges them.

All 76 collectible designs/stats/spawn weights and the original place objects/backups are preserved. Eight slots per floor, the level-five upstairs unlock, 5% income per level, ten normal powers and developer-only tools remain. V79 conveyor cleanup, hologram/actual-carry separation, owner theft alerts, paid carry loss without refund, unfinished-bid refunds and the safe Exodia respawn exception remain included.

## Keep your existing products

Updating the **same Roblox experience** keeps the same 15 Developer Product IDs. Items do not need new collectible IDs for this update. Creating a separate experience would require products belonging to that new experience.

All 15 owner-supplied product mappings are unchanged from V80; see [ProductSetup.csv](../Version80/ProductSetup.csv) and [PRODUCT_IDS.md](../Version80/PRODUCT_IDS.md). Roblox ownership and actual prices still need verification. Checkout remains **off** (`Enabled=false`, `PreviewOnly=true`). Follow [PRIVATE_TEST_STEPS.md](../Version80/PRIVATE_TEST_STEPS.md), including fixed prices with Managed pricing off and real receipt/storage tests, before enabling it.

Your terminal can edit the Lua source or apply changes to a `.rbxlx`; opening a local file does not update the published game. Back up your latest Studio file. When you explicitly choose to upload this build, use Studio's **File → Publish to Roblox As…** and select the existing **Steal An OP Item** experience and place. Do not create a new experience to install an update. Review the selected destination before confirming. Changes made only in a local Studio file after the supplied baseline must be merged before replacing that local file.

## Music next

Download [Version81_AudioUpload.zip](../Version81_AudioUpload.zip), extract it and upload **AudioUpload/relic-rivalry-loop.ogg** through **Creator Dashboard → Creations → Development Items → Audio → Upload Asset** under the game's owner account/group. Wait for approval, grant the experience permission and send **`Music: YOUR_AUDIO_ASSET_ID`**. See [AUDIO_UPLOAD.md](AUDIO_UPLOAD.md) for exact steps and the optional ten SFX uploads.

Music remains silent until that uploaded asset ID is configured. Existing built-in SFX fallbacks and separate music/SFX on/off switches and volume sliders remain. Audio setup does not change product IDs or enable checkout.

## Verify in Studio

The offline evidence is in [TEST_RESULTS.md](TEST_RESULTS.md). Production Luau checks use API/storage/GUI doubles; actual Studio multiplayer, live purchases/storage, native input, audio permission/playback and performance remain untested here.

1. With two players, move a ground-floor item, cancel a move, wait past 20 seconds, move between floors after level five, then rejoin. The same item must occupy exactly one saved slot.
2. Attempt Sell during Move; it must refuse. Cancel, then confirm Sell; the item disappears once and pays 50% once. A stale steal prompt or move request must not retrieve it.
3. Let another player steal an item during your selection. Your move must cancel; neither Sell nor Move may change the carried item. Check drop/return and successful delivery ownership.
4. Verify console access only in your own base, occupied/reserved slots, death, simultaneous requests, save failures and mobile/controller navigation. No writable fresh profile may replace a failed load.
5. Complete the [full launch checklist](../Version78/LAUNCH_CHECKLIST.md) and V80 private purchase checks. Record real observations separately from the offline reports. Public launch readiness remains unverified.
