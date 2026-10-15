# Version 70 — Slifer and item review

Open `releases/StealAnOPItem_70_SliferAndItems.rbxlx` in Roblox Studio. This game is built directly from the user's uploaded `StealAnOPItem_69_ArtAndLotus.rbxlx`, not from the older cloud version 64. The original upload is preserved at `roblox/original/StealAnOPItem_69_ArtAndLotus.rbxlx`.

## Changes

- The animated Slifer now occupies the former statue site at X -105, Z 155. It has one horned head with two mouths, tapered coils, pointed teeth, claws and articulated wings. It clears the perimeter walls. The old Slifer around Kaiba Corp is removed; the tower stays.
- Slifer animates on each client, with a 30 Hz cap, distance culling, reduced-effects support and connection cleanup.
- Krabby Patty has a coherent rounded bun, sesame seeds fitted to its surface, a seared patty, folded cheese, ruffled lettuce, tomato, onion and pickle details.
- Black Lotus has folded, cupped petals, stamens and a veined lotus pad.
- Death Note has front and back covers, a rounded binding, stitching, page edges, bookmark and a readable title.
- The development-only `ArtChecks` utility now checks model identity, finite geometry, part budgets and specific details on the three refined items.

All 65 catalog entries were reviewed through their actual factory routes, including all 19 newer items. Their IDs, prices, income, rarity, abilities and spawn weights are unchanged. The Millennium Puzzle's exact model is unchanged. The Ra-related builders and all scenery outside Slifer are unchanged.

Version 69 already contains the eight-power system and Infinity Stone reward logic. This release preserves them; it does not revert them to the earlier version 64 code.

## Previews and validation

- `../Version70Items/New19Items.png`: all 19 newer collectibles.
- `../Version70Items/All65Items.png`: full catalog.
- `KrabbyPattyReview.png`: actual before/after burger geometry.
- `Slifer.png`: actual replacement geometry.
- `preservation-report.json`: original object/property and script preservation checks.
- `validation-report.json`: final automated check results and limitations.

Previews render actual native geometry offline. Roblox Studio lighting and SurfaceGui rendering can differ. Studio visual, device-performance and multiplayer playtests have not been performed here. Nothing has been published to Roblox.

## Rebuild and check

Run from the repository root with Python 3, Pillow, NumPy, Matplotlib, `texlua`, and the official Luau CLI available:

```sh
python tools/build_v70_place.py roblox/original/StealAnOPItem_69_ArtAndLotus.rbxlx
python tools/run_game_checks.py --root roblox/v70-game --baseline roblox/v69-original/OPItemV2 --check tests/v70_preservation.lua --luau /path/to/luau
python tools/audit_v70_items.py --luau /path/to/luau
texlua tests/slifer_upgrade.lua
texlua tests/v70_world.lua
```

The handoff is on `codex/version-63-handoff`; the default branch is unchanged. Editable active game sources are in `roblox/v70-game/`. Treat the original upload and `roblox/v69-original/OPItemV2/` as immutable baselines.
