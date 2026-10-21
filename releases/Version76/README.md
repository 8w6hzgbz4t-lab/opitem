# Version 76 — Conveyor Clash

Download `Version76_Game.zip`, extract `StealAnOPItem_76_ConveyorClash.rbxlx`, and open it with **Roblox Studio → File → Open from File**. The source bundle also includes editable Lua, music, sound effects, artwork, checks and the preserved V75 baseline. No Studio plugin or Meshy subscription is required.

## Changes

- **Developer access stays exclusive to `Goverment_cheesee`.** The server resolves that account to its numeric UserId and rejects all other accounts. No developer powers, flight, protection, gifts or menu access are sold for Robux. Failed username resolution disables developer access instead of authorizing someone else.
- Open the gold **DEVELOPER / F8** menu and enable **Developer mode**. A fourth **Royal Seal** ability appears only for that account, with its own 15-second cooldown. Three normal ability slots stay unchanged for other players. The Millennium Rod/Puzzle effects remain.
- Press jump three distinct times within 1.2 seconds with developer mode on to fly. Keyboard Space, controller A and the native touch jump button are supported. Flight holds a fixed upright facing and zeroes angular velocity; no gyroscope is created. Use Land to stop. Carrying, bidding, death or revocation clears developer mode and movement mods.
- **Paid pickup is a wager.** Losing a purchased carried relic to a valid offensive power, death, timeout or disconnect returns the same item to its recorded conveyor pickup point, without refunding the amount paid. An auction winner loses their winning bid. Unfinished/withdrawn/losing bids still refund. Failed theft restores the original owner's item. A forced Exodia safe-respawn event keeps its explicit safe recovery policy.
- All offensive powers dislodge carriers only after targeting, line-of-sight, shield, immunity and cooldown checks. Carrying/bidding continues to disable powers. Stored items survive normal deaths and can still be stolen from unprotected bases.
- The retired static Slifer builder and exact legacy copies are removed; one detailed animated Slifer remains. Ra, Shenron, Crimson Dragon and framed art are preserved.
- A detailed second **Cash Shop** bench previews proportional cash packs. Proposed rate: 200 game cash per Robux. Packs: 25→5,000; 100→20,000; 250→50,000; 500→100,000. **Nothing can be charged or purchased in this build.** It has no Marketplace purchase prompt or receipt callback. Live sales require persistent player profiles, atomic cash/receipt grants, configured Developer Products and fresh validation.
- Sound cues cover powers, shields, item pickups/losses/delivery, protection activation/expiry, level-ups and menu buttons. Music and sound effects have separate Settings toggles. Nearby power cues attenuate with distance and audio is bounded to prevent noisy bursts.
- Original **Relic Rivalry** battle music (51.89 seconds, 148 BPM), ten original sound effects, a 1920×1080 thumbnail and 512×512 icon are included. Follow [Audio/README.md](Audio/README.md) to upload custom audio and set numeric IDs in `ServerScriptService → OPItemV2 → AudioConfig`. Until then built-in SFX work and custom music remains silent. Upload artwork through Creator Dashboard; no artwork or audio has been published for you.

## Validation and limits

All 99 active Luau sources compile. Offline checks exercise actual session transactions, all 76 item geometries, powers, developer authorization/commands, jump input, private HUD metadata, cash shop denial paths, audio routing/limits, animated Slifer, wearable artifacts, base progression and upper-floor collision geometry. Reports retain source and test hashes; the packager rejects stale reports. The builder preserves all 299 original place objects and their non-source properties/backups and adds six scripts/modules.

The game is still a **session alpha: progress resets on leaving**. Roblox Studio is unavailable in this cloud environment. Live account lookup, multiplayer replication, physics, native touch behavior, asset permissions and rendering/performance need Studio verification. Cash purchases are disabled; nothing was published to Roblox.

Before publishing, test with your account and a second account: only you can open developer tools/use slot four; three jump presses start stable flight; a shield blocks an attack; an unshielded carrier loses item and price; losing bids refund; delivery succeeds once; both floors retain stored items after death; no static Slifer remains. Upload/configure audio and inspect Studio Output. Keep cash packs disabled until durable purchase support is built and tested.

See `validation-report.json` for final counts and `preservation-report.json` for the complete place/source manifest. Earlier V75 files remain unchanged.
