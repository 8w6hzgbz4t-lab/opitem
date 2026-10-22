# V83: owner Sell, readable powers and base workbenches

Open **StealAnOPItem_83_SellAndWorkbenches.rbxlx** from [Version83_Game.zip](../Version83_Game.zip). The editable source and evidence are in [Version83_SourceAndGame.zip](../Version83_SourceAndGame.zip). Active source folder: `roblox/v83-game/`. Nothing has been published to Roblox automatically.

## Your items show Sell

Your own stored items show **Sell · $amount (50%)** instead of Steal. Hold E, controller X or touch for 0.35 seconds to open a confirmation naming that exact item. **Confirm Sell** pays the existing 50% value and removes the item; **Cancel** keeps it. Other players see **Steal** on your stored items and retain the normal theft rules. Conveyor items still show Buy.

The server chooses the action from live ownership, rather than trusting the displayed label. Opening a sale confirmation changes no money or ownership. Final sales recheck ownership and your base location, then use the existing durable save path. Moving, carried, reserved, stolen or deleted items cannot be sold. If a thief gets the item before confirmation, the stale sale fails. A full vault can still sell its stored items.

## Two base workbenches

The **green MY VAULT workbench** replaces the plain manager block. It has a wood/steel top, four legs, drawers, keyboard, display, ledger and relic tray. It opens the existing Inventory controls for Move, Sell and base levels. Its interaction prompt sits above the front edge so the desk does not block access.

The **Power Lab workbench** keeps its existing power shop/loadout functions. Base upgrades work near either workbench. Entrances, delivery/protection lines, item slots and upstairs geometry remain clear.

**Equip in Power Lab** places an owned ability in optional slot 2 or 3. Select its hotbar button, then press F, controller R2 or touch Use to activate it. Tag remains in slot 1. The collectible Inventory's former Equip button is now **Favorite**: it marks a stored item with a star. It does not carry the item, change income or grant an ability. Its saved preference remains compatible with earlier versions.

## Plain power labels

Every power hotbar button now uses smaller 10-point medium text, no text stroke, no automatic scaling and no wrapping. The selection outline explicitly draws around the **button border**, rather than around the letters. This applies to Tag, all optional powers and the private Royal Seal slot. Button/touch target sizes remain unchanged.

## Eight players and automatic vaults

The game configuration is eight players with eight bases. The place file's saved `Players.MaxPlayersInternal` is corrected from **12 to 8**. The server reserves a unique free vault before loading progress, spawns the player at that vault, rejects a ninth admitted player and releases reservations after failed loads or departure. Lobby vault assignments are session-specific; saved collectibles and progress return in the assigned vault.

When updating Roblox, select the **existing experience and place** to keep your products and saved stores. Verify the published place's **Maximum Players** is **8** in Creator Dashboard as well; that remote Dashboard setting cannot be confirmed by editing this local file. Keep a backup and merge any unsupplied local edits before replacing your current Studio file.

## Preserved setup and verification

All 76 collectible designs/stats/spawn weights, eight slots per floor, level-five upstairs unlock, 5% income increases, ten powers, developer-only authorization, saved schema, original backups and existing gameplay remain. Music asset **111355988554529** and all 15 product IDs are unchanged. Checkout stays **off** pending the [private purchase checks](../Version80/PRIVATE_TEST_STEPS.md).

See [TEST_RESULTS.md](TEST_RESULTS.md). Offline checks execute production code with controlled player/storage/GUI/geometry adapters. Actual Studio multiplayer, native input/rendering, physics/FPS, Roblox audio permissions and live saving/purchases still need testing.

In a two-player Studio/private test, confirm that each viewer sees the correct Sell/Steal label, sales require confirmation and pay once, moving/stolen items cannot be sold, both workbenches work, every selected power label stays plain, and each joining character spawns at its own vault. Test full-server behavior with eight players and verify Dashboard capacity separately. Complete the [full launch checklist](../Version78/LAUNCH_CHECKLIST.md) before public release. Public launch readiness remains unverified.

For durable multiplayer tests, use real accounts in a private published experience. Studio local test clients that use negative/synthetic UserIds are rejected by the current strict saved-profile identity validation. Do not disable saving or weaken live profile validation to make those accounts load. Studio's separate TEST stores do not by themselves add synthetic-account support.
