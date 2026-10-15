# Steal An OP Item — version 63

Open `releases/StealAnOPItem_63_DetailedArt.rbxlx` in Roblox Studio and press **Play**. The game builds its world when the server starts. This is based on the complete uploaded version 62, whose untouched file remains in `roblox/original/`.

## Included changes

- Detailed native Roblox models for all original 42 collectibles. The Millennium Puzzle design, original item IDs, prices, income, rarity and abilities are preserved.
- Four new conveyor collectibles: Dragon Balls (seven-ball display), Yusei Fudo Red Duel Runner, Freddy Fazbear Empty Suit, and Golden Freddy Empty Suit. These are display collectibles, with no NPC behavior.
- Rebuilt architecture and landmarks: fitted solid roofs/walls, detailed Exodia statue, bell tower, Squidward-style stone house, tournament pillars, Egyptian god monuments, lotus/card display, crown towers, pancakes and decorated portal.
- Purple domain dome, pastel sky flowers and rainbow, Mirror Force-inspired reflection planet, raised 5D’s-style perimeter circuit, Crimson Dragon and Shenron. The circuit is decorative; the original conveyor and arena collision remain authoritative.
- Purchase and theft holds reduced to **0.35 seconds**. Carried items follow their carrier on every rendered frame; server snapshots run every 0.2 seconds. Ownership, hits, money and delivery checks remain server-controlled.
- Smaller pixel-sized item nameplates with cached geometry measurements.
- A flat green line spans each base entrance. The wider server detection zone completes an owner’s delivery and activates ready protection on entry. Protection lasts **30 seconds**, with the existing 60-second recharge. Standing on or repeatedly crossing the line does not bypass recharge. The original earnings pad remains.
- Pokémon relative spawn multiplier reduced from 0.4 to 0.2. Including the four additions, total Pokémon offer probability falls from approximately **13.81% to 7.61%**. Conveyor cadence and rarity tier probabilities are unchanged.

Each base still has eight slots, including reserved incoming items. This remains the original session-only alpha: progress resets on leaving. The updated place is not published.

## Files

- `roblox/game/`: editable version 63 game sources.
- `roblox/art/`: canonical procedural art modules; the build copies them into `roblox/game/DetailedArt/`.
- `releases/DetailedArt/`: individual `.rbxmx` models, builder modules, importable gallery, previews and manifest.
- `releases/StealAnOPItem_63_Complete.zip`: place, editable sources, models, previews and usage notes.

## Validation

From this repository root, with Python 3, NumPy, Pillow, Matplotlib, texlua, and the official Luau CLI installed:

```sh
python tools/build_art_upgrade.py
python tools/run_game_checks.py --root roblox/game --baseline roblox/v62-original --luau /tmp/opitem-luau/build/release/luau --syntax-root roblox/art --check tests/catalog_upgrade.lua --check tests/base_entrance.lua
python tools/check_carry_presentation.py --luau /tmp/opitem-luau/build/release/luau
texlua tests/art_world.lua
texlua tests/world_integration.lua
```

The native Luau runner executes the original six session test groups in both versions, validates every original item field, exercises all 46 art routes and new-item transactions, and checks the entrance/protection rules. Additional checks execute the actual carry snapshot, render callback and presentation code. Geometry recording verifies budgets, scaling, transforms and collision flags. The builder validates XML preservation of all 228 original objects.

## Studio playtest still required

This cloud machine does not run Roblox Studio. Open the release in Studio and inspect Output. Use **Test → Server & Clients** with two players to check purchase/theft holds, carried-item motion under simulated latency, interruption/refunds, entry delivery, protection/recharge and compact labels on desktop/mobile. Check that every base entrance stays accessible, roofs fade for the camera, the raised track and dragons are visible above the perimeter, and the disposal path remains closed to players. Review performance with several clients and many collected items before publishing.
