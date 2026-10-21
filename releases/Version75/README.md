# Version 75: dragons, developer tools and upper galleries

Open `releases/StealAnOPItem_75_DragonsAndDevTools.rbxlx` in Roblox Studio and press **Play**. The server generates the map. Original uploads, backups and earlier releases are preserved.

## Collectibles

The conveyor, index, inventory, carrying, delivery and theft systems now support **76 items**. All 69 previous definitions, stats and models—including the 137-part Millennium Puzzle—are unchanged.

| New item | Rarity | Price | Base income | Native parts |
| --- | --- | ---: | ---: | ---: |
| Stardust Dragon | Legendary | $85,000 | $900 | 239 |
| Blue-Eyes White Dragon | Mythic | $330,000 | $3,100 | 234 |
| Michael Jackson's Glove | Epic | $17,500 | $240 | 145 |
| Tungs Bat | Rare | $5,500 | $95 | 131 |
| Moms Credit Card | **Ethereal** | $1,500,000 | $11,000 | 123 |
| Sonic's Golden Ring | Uncommon | $1,800 | $38 | 119 |
| Captain America's Shield | Legendary | $95,000 | $1,000 | 126 |

These are native Roblox models with no paid service or external model asset requirement. The dragons have distinct sculpted heads, eyes, mouths/fangs, polygon wings, claws and tapered tails. The five additional collectibles have individual geometry and details. All models fit the existing display and overhead carry envelopes. Standalone `.rbxmx` models are in `models/`.

Rarity is rolled first, then the item within that rarity. The seven rarity frequencies and existing Pokémon/weapon reductions are preserved. Exact probabilities for all 76 items are in `spawn-rates.json` and `spawn-rates.csv`.

## Developer menu

The menu is restricted to **Goverment_cheesee**, resolved to its numeric Roblox UserId by the server. Every command checks the actual sender. Failed lookup grants no access. The unchanged authorization policy never grants access through a display name, Studio test identity, group membership or client-supplied ID.

- Use the gold **DEVELOPER / F8** button at the top right. The menu opens Flight, Powers, Items, Gifts and Console pages with shared Back/Close behavior. Opening another game menu closes the previous one.
- Flight uses WASD relative to the camera and Q/E to descend/ascend. Release input to hover. **LAND** stays accessible while flying; mobile has separate hold controls. Normal power shortcuts do not fire while using flight controls.
- Gifts lists online players by account name, display name and UserId, including yourself. Choose a target and enter a positive whole amount. **Gift money** creates session currency without charging your developer balance. **Gift levels** adds 1–100 levels per request, up to level 1,000. Currency cannot exceed $2 billion including escrow. Pending requests and server receipts prevent an accidental duplicate grant. Departed targets receive nothing.
- **Royal Seal** is a unique developer spell with a separate 15-second cooldown. It draws a gold Millennium seal after a 0.65-second warning, briefly stuns unshielded opponents within 18 studs and knocks carried loot loose through the normal refund/return system. Walls, shields, immunity and carrying/bidding restrictions still apply. Clearing ordinary power cooldowns does not clear Royal Seal's cooldown.
- Enabling developer ability protection or casting the developer Shield equips a detailed **Millennium Puzzle pendant**. It disappears when protection ends, is consumed, or is interrupted by carrying/bidding/respawn. World hazards and character resets remain effective.
- Powers cast through the developer menu briefly equip the **Millennium Rod** in your right hand. Its eye supplies a server-controlled cosmetic ray origin. Royal Seal adds its own eye, rings and rune effects. These replicas are welded, massless and noninteractive; they never enter the item ledger.

Existing currency, inventory, protection, teleport, announcement, kick and session-ban commands remain available. Destructive commands retain exact-command confirmation, rate limits and audit logs. Bans affect the current server only.

## Player HUD and bases

The status panel, navigation and three power slots are compact and share a single active menu. Inventory and index support search; narrow screens use list/detail pages with Back. Buy Battle and Exodia rewards use small opt-in banners. Touch movement remains enabled. Layout checks include desktop, portrait, landscape and Roblox/device safe insets. Reduced effects also simplify the new developer visuals.

Base upgrades now use collected in-game money. Visit your base console and use **Inventory → Upgrade**. The first level costs $1,500; later costs grow by 1.6 per level, capped at $2 billion. Each level adds **5% of base income** to the owner's items: level 1 is 1.05×, level 2 is 1.10×, and level 5 is 1.25×. Fractional income stays in the bank; collection pays whole currency. Protection starts at 30 seconds and gains five seconds per level, up to 180 seconds.

At **level 5**, the base gains a second floor with **eight more slots**, for **16 total**. It has fitted solid walls/windows and roof, numbered display plinths, matching bronze/navy trim, rear switchback stairs and a green upstairs arrival/protection line. Camera fading includes the raised roof and upper walls. The original eight ground slots, entrances, anchors, spawn positions and base presentation are preserved. An owner leaving removes the extension and restores the original roof for the next player. Paid, gifted, Exodia and Infinity levels use the same progression transition.

The animated Slifer, detailed Ra, the other scenery and Version 73's removal of the old Slifer statue/Kaiba tower are retained.

## Validation and handoff

Final checks execute production code with official Luau or controlled Roblox API adapters:

- All 76 distinct models: 290,189 geometry/catalog checks; all 69 old model hierarchies/GUI properties and the original Puzzle preserved exactly.
- Catalog/transactions: 9,634 checks, six original session groups and thirteen regression groups, including the seven additions and upstairs slot reservations/theft/death/refunds.
- Administration: 473 assertions, 208 command dispatches and fourteen groups, including gifts, outsider denial and lifecycle cleanup.
- All eight powers plus Royal Seal: 665 assertions across seventeen groups.
- Developer menu: 84 behavior assertions. Player HUD and power menus: 246 assertions including safe inset layouts.
- Wearable artifacts: 12,937 geometry/weld/lifecycle assertions for R6 and R15. Spell visuals: 2,448 assertions covering rod origin, warnings, reduced effects, geometry bounds and cleanup.
- Progression: 118 checks. Upper floors: 1,326,582 geometry checks across all eight bases, including stairs/headroom, solid shells, all 64 upstairs pivots, original anchors, owner reuse and repeat builds.

Reports, actual geometry previews and seven standalone models accompany this README. `UpperFloor.png` labels its interior cutaway; the hidden walls and roof remain solid in the game. Offline previews approximate Studio appearance.

Editable sources: `roblox/v75-game/`. Complete source/game bundle: `releases/Version75_SourceAndGame.zip`. Rebuild with `python tools/build_v75_place.py`, then package with `python tools/package_v75_release.py` after validation. The new checks use the existing official Luau CLI and `texlua`; rendering helpers additionally use Python/Pillow/NumPy/Matplotlib.

Live Roblox identity lookup, Studio rendering, native physics, performance and multiplayer remain untested in this cloud environment. A Studio playtest is still required. Progress remains session-only. **Nothing has been published to Roblox.**
