# Create the remaining 14 shop products

**Progress: 1 of 15 product IDs recorded.** Pocket Cash already has ID **3720840251**, for 5,000 game cash at the proposed price of 25 Robux. Its ownership and live Roblox price have not been verified here. Do not create Pocket Cash again. Its icon is `pocket.png`.

The remaining products below match the **V80 setup draft**. Checkout stays off: `Enabled=false` and `PreviewOnly=true`. All 15 products need different, valid Developer Product IDs before checkout can be enabled, and saved progress and receipt delivery must pass controlled testing first.

## Create each product

1. In [Creator Dashboard](https://create.roblox.com/dashboard/creations), choose **Creations → your game → Monetization → Developer Products → Create Developer Product**. Use the same experience as the existing Pocket Cash product.
2. Copy the exact product name and customer description from the table. Upload the matching PNG from this folder as the product's image.
3. Enter the listed Robux price. Leave **Managed Pricing off** for this fixed-price setup. Save the product.
4. Open the product's menu and choose **Copy Asset ID**. Record that numeric Developer Product ID in the matching row of [ProductSetup.csv](ProductSetup.csv), replacing its zero. Keep the existing Pocket Cash ID.
5. Repeat for all 14. Send Codex the product names and IDs to connect them to V80. IDs are public identifiers; no password or login credentials are needed. Updating this worksheet alone does not change the game.

Start with **Vault Stack**. [QUICK_NEXT.txt](QUICK_NEXT.txt) has its copy-ready fields and the full checklist.

Prefer a spreadsheet? [CREATE_PRODUCTS.csv](CREATE_PRODUCTS.csv) contains these 14 remaining products, their descriptions, prices, icon filenames and empty ID placeholders. [ProductSetup.csv](ProductSetup.csv) keeps the full 15-product configuration worksheet, including the existing Pocket Cash ID.

| Exact product name | Customer description | Proposed Robux | Icon filename |
| --- | --- | ---: | --- |
| Vault Stack | Add 20,000 game cash to your saved balance. | 100 | `stack.png` |
| Treasure Chest | Add 50,000 game cash to your saved balance. | 250 | `chest.png` |
| Grand Fortune | Add 100,000 game cash to your saved balance. | 500 | `fortune.png` |
| One Base Level | Add 1 base level and another 5% of base item income to your income bonus. | 25 | `level_one.png` |
| Five Base Levels | Add 5 base levels and another 25% of base item income to your income bonus. | 100 | `level_five.png` |
| Dash Unlock | Unlock Dash for a quick movement burst that respects solid walls. | 2 | `unlock_dash.png` |
| Pull Unlock | Unlock Pull to draw nearby opponents inward and interrupt their grabs. | 6 | `unlock_gravity.png` |
| Slow Field Unlock | Unlock Slow Field to aim a slowing zone that can knock carried loot loose. | 8 | `unlock_slow.png` |
| Ground Slam Unlock | Unlock Ground Slam to erupt the ground and knock nearby opponents' carried loot loose. | 25 | `unlock_slam.png` |
| Knockback Pulse Unlock | Unlock Knockback Pulse to blast nearby opponents outward and knock carried loot loose. | 70 | `unlock_repulse.png` |
| Force Field Shield Unlock | Unlock a shield that lasts up to 3 seconds and blocks one incoming hit. | 90 | `unlock_shield.png` |
| Lightning Strike Unlock | Unlock Lightning Strike to lock onto a nearby visible opponent, briefly stun them and drop their carried loot. | 325 | `unlock_lightning.png` |
| Ki Blast Unlock | Unlock Ki Blast to fire an aimed energy projectile with an explosion that can knock carried loot loose. | 325 | `unlock_kiblast.png` |
| Spinjitzu Unlock | Unlock Spinjitzu to surround yourself with a short tornado that knocks nearby opponents back and drops carried loot. | 80 | `unlock_spinjitzu.png` |

Base-level income bonuses add **5% of the item's base income per level**; they do not compound. Reaching base level 5 unlocks the upstairs floor. A level pack is unavailable if it would exceed the maximum base level.

Power purchases unlock normal powers and follow their usual cooldown, range, wall, shield and immunity rules. They do not add equipped slots. Tag remains free, and the other normal powers remain obtainable with game currency. No developer privilege, developer-only ability or conveyor collectible is sold by these products.

## Before anyone can buy

Keep `Enabled=false` and `PreviewOnly=true` while IDs are missing. This build requires all 15 distinct nonzero IDs; do not enable only one offer or delete the other rows. The configured base Robux prices must match Roblox. The Roblox confirmation window supplies the final price.

After all IDs are connected, verify product ownership and prices, durable saved progress, cancelled purchases, actual receipt fulfillment and rejoining in a controlled private setup. Offline checks do not prove actual Roblox purchase delivery. Keep existing public checkout off until those checks pass. Never repurpose an ID after accepting purchases, because delayed paid receipts still need their original reward mapping.

The V80 setup draft is not a newly published Studio game. Creating Dashboard products and uploading these icons does not publish the game or enable checkout.

Official Roblox guide: [Developer Products](https://create.roblox.com/docs/production/monetization/developer-products).
