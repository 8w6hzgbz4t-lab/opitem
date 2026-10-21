# Connect the fifteen Robux offers

The code now supports server-verified prompts and durable receipt grants. **All product IDs are still zero and checkout is off** because you have not created the products. Nothing in this build can charge a player with the default configuration.

1. In Roblox Creator Dashboard, choose the correct private test experience, then its monetization/developer-products area. Create one product per row below. Use the proposed price or review the entire conversion before changing it.
2. Copy each **Developer Product ID**, not your UserId, place ID, game pass ID or an image/audio asset ID. Enter its numeric value into the matching `productId` in `ServerScriptService → OPItemV2 → CashShopConfig` while Play is stopped.
3. Retain stable product mappings for delayed receipts. Do not replace or delete a product mapping that may have unpaid/unprocessed receipt deliveries. Each offer must have a different ID.
4. Test durable saves and receipt handling in the test experience first. Set `Enabled=true, PreviewOnly=false` only after all fifteen IDs and the current base Roblox prices match. Invalid configuration fails closed. Roblox's confirmation prompt gives the final price; regional pricing can differ.
5. Save, restart the server, verify your developer-only powers are absent from the store, and run the receipt cases in `LAUNCH_CHECKLIST.md`. Cloud tests use controlled API adapters, not real charges.

| Offer ID | Reward | Proposed Robux |
| --- | --- | ---: |
| pocket | 5,000 cash | 25 |
| stack | 20,000 cash | 100 |
| chest | 50,000 cash | 250 |
| fortune | 100,000 cash | 500 |
| level_one | +1 base level | 25 |
| level_five | +5 base levels | 100 |
| unlock_dash | Dash | 2 |
| unlock_gravity | Pull | 6 |
| unlock_slow | Slow Field | 8 |
| unlock_slam | Ground Slam | 25 |
| unlock_repulse | Knockback Pulse | 70 |
| unlock_shield | Force Field Shield | 90 |
| unlock_lightning | Lightning Strike | 325 |
| unlock_kiblast | Ki Blast | 325 |
| unlock_spinjitzu | Spinjitzu | 80 |

Cash uses 200 per proposed Robux; ordinary powers round their gameplay cash cost up at that rate. Tag is always free. No conveyor collectible, developer menu, Royal Seal, flight, protection mode or admin gift ability is sold. Ordinary gameplay currency can still buy regular powers and levels; purchasing a power never adds another loadout slot.

The server blocks new prompts for owned powers, full level packs beyond level 1000, cash-cap conflicts, unready profiles, exhausted receipt capacity, remote requests away from the bench and unverified prices. The server grants only on a real `ProcessReceipt` callback. If a legitimate delayed receipt arrives after a power became owned, it grants that power's gameplay cash value. Excess capped levels convert proportionally to the pack's proposed cash value. Cash overflow becomes saved credit. Every grant and receipt are saved together; duplicate confirmed receipts do not award twice.

Receipt ledgers are bounded to 10,000 entries and profile JSON to 1.5 MB so a two-snapshot transfer remains below Roblox's record limit. No receipt is silently evicted. Plan durable receipt archival before an account reaches capacity; checkout is blocked before that point and affected pending receipts remain unacknowledged until fulfillment can be stored.

Roblox reference: https://create.roblox.com/docs/production/monetization/developer-products
