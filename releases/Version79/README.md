# Version 79 — conveyor cleanup and theft alerts

Extract `Version79_Game.zip` and open `StealAnOPItem_79_ConveyorAndTheftAlerts.rbxlx` in Roblox Studio. V78 is preserved as a backup.

## Changes

- Unsold conveyor items now despawn at their disposal point. Previously, the save wrapper rejected expiry because an unbought item had no player profile. A narrowly checked world-only expiry now uses the existing mutex/rollback pipeline without any DataStore writes. Bids, owned items, active carries and unresolved transactions cannot enter that exception. The conveyor can replenish after many complete waves.
- A carried item's separate hologram can leave the belt without deleting the real item. The real item remains visible above its carrier with its offer reserved in `InTransit`. The old 50-second automatic carry drop is removed. Valid power hits, defender recovery, death, disconnect and invalid movement still resolve carries; successful base delivery stores the item. A lost paid item returns to its original pickup point with no refund. Unfinished/losing bids still refund.
- Base owners receive a separate compact theft banner naming the item and carrier. It distinguishes **taken**, **recovered** and **stolen**, without blocking movement or replacing ordinary notifications. Alerts follow committed state and go only to the original owner.
- Power hotbar/action text uses a smaller, lighter font. Power menu names and descriptions are more compact. Selection and F/R2/touch Use controls are preserved.
- `Art/` contains the new square icon and widescreen thumbnail. `GAME_DESCRIPTION.txt` contains the short listing description. These promotional illustrations are separate from gameplay geometry.

## Before Play and public release

The V78 saving requirements still apply: use a private test experience with Studio DataStore API access. Studio uses separate TEST stores. Read `../Version78/LAUNCH_CHECKLIST.md` and `../Version78/PRODUCT_SETUP.md`. All Developer Product IDs remain zero and checkout remains off; the original music still needs its owner-uploaded audio ID. This update does not reset profiles, change product mappings, sell developer powers or change any of the 76 collectible designs/stats/spawn weights.

The focused checks run actual Luau with storage/engine/UI adapters. They reproduced both the old disposal failure and timed carry loss before the fix. They do not replace real Studio multiplayer testing. In Studio, watch several complete conveyor cycles, carry an item past its hologram's exit and longer than 50 seconds, intercept it with a power, deliver it, and check owner alerts using two accounts. Review the smaller text on a real phone/controller display.

No game, image, product or audio asset has been published/uploaded to Roblox automatically. Public launch readiness remains unverified.
