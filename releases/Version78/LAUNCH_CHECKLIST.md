# V78 launch gates

This build has not been published to Roblox and is not yet launch-verified. The cloud can execute production Luau with storage/engine adapters and inspect native geometry. It cannot start Roblox Studio, connect real players, configure your Creator Dashboard or verify account-owned audio/products.

## Before Studio Play

1. Keep the V77 backup. Extract the V78 game ZIP and open its `.rbxlx` in Studio.
2. Save a **private test experience** under the account/group that will own the game. Enable Studio API access for that test experience if needed to test DataStore APIs. Do not change production permissions or data to run experiments. Studio automatically uses the separate `StealAnOPItem_TESTProfiles_v1` and `StealAnOPItem_TESTTransfers_v1` stores; live servers use the names without `TEST`.
3. Profile loading must succeed before gameplay starts. A locked, corrupt, newer-schema or unavailable profile causes a safe rejection. There is no writable blank-profile fallback. Read Output for the precise cause. A disconnected server's stale lock expires after 120 seconds; a prepared transfer's decision expires after 60 seconds.
4. Confirm your numeric Roblox UserId in `AdminConfig`. The configured username is `Goverment_cheesee`; failed name lookup disables developer tools. No creator/group/Studio bypass authorizes another account.
5. Follow `PRODUCT_SETUP.md` and the existing `Version76/Audio/README.md`. Leave checkout off while IDs are zero. Upload the existing thumbnail/icon through Creator Dashboard.

## Required live tests — currently unperformed

| Area | Pass condition |
| --- | --- |
| Saves | Cash, bank, both inventory floors, levels, powers, index, settings and rewards survive leaving and joining a different server. No extra starter item appears. |
| Failed loads | Simulated API failure/locked profile cannot create or overwrite a fresh profile. Stale server writes fail. |
| Shutdown/crash | A paid carry loses its price and returns with its UID/pickup point after recovery; unfinished bids release money. Check bank checkpoint recovery. |
| Theft transfer | Interrupt each side of the durable transfer. Rejoin both accounts: exactly one account owns the UID. Repeat a confirmed transfer without duplication. |
| Receipts | Use a controlled test experience. Verify delayed/retried receipts, cancelled prompts, offline buyers and already-owned/capped reward fallback. Grant and receipt must persist together. No reward comes from closing a prompt. |
| Controls | Click/number keys select and highlight only. F/right trigger/touch Use fires once. Typing, menus, carrying and bidding block activation. |
| Powers | Lightning locks one nearest visible opponent, rechecks cover/range; Ki aims in 3D with six-stud blast cover checks; Slow Field places at the reticle within 16 studs; tornado hits each target once; Slam rubble fades without collision. |
| Developer | Second account cannot use menu, fourth power, flight, immunity, gifts or admin requests. Three Space presses start/stop flight. R6/R15 face travel in Superman pose, restore on landing/death and use no gyroscope. |
| Items/index | Review all 76 in the actual Studio conveyor and Index. Geometry, labels, rarity, price and income match. No clipped models or missing card/label details. Offline sheet is a review aid. |
| Bases | Eight slots per floor; upstairs unlock at level 5; 5% income per level; solid walls/roofs and stairs; protection lines work; stored items survive death. |
| Devices/performance | Test desktop, phone/tablet, controller and an eight-player server. Measure FPS, memory, network traffic and storage budgets during purchases/theft. Test with latency. Economy changes serialize while a durable write is pending; storage latency must remain acceptable. |
| Audio | Actual owner-uploaded assets play after approval/permission. Music loops quietly; sliders/mute persist; power/buy/delivery/lock/level sounds are audible without bursts or clipping. |

The bank checkpoints every 30 seconds and restores up to 60 seconds of income on reconnect. This bounded recovery also provides up to one minute of offline income. Receipts are never evicted; new checkout stops before ledger/profile capacity. A confirmed delayed capped/owned reward converts to game cash; overflow is retained as saved paid cash credit and redeems when cash space opens.

## Dashboard/public launch

- Configure the experience owner, access, supported devices, server size **8**, accurate description, thumbnail/icon, content/maturity questionnaire and applicable publishing/account requirements shown by Roblox.
- Complete the asset permission review. Do not imply licensing has been verified by native geometry or AI artwork.
- Finish the live test table. Record failures and fix critical ones before public access. Keep checkout off until receipt/storage tests and product prices pass.
- Start with a small release, inspect errors/save latency and gather first-session feedback. Keep rollback copies. A rollback must retain the V1 profile/receipt schema and product mappings; do not revert to V77's session-only server after accepting paid purchases.
- Publish or change public access only after the owner reviews the concrete build and remaining gates. No automatic publication is authorized.
