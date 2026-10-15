# Version 71 — Secret Formula, Ra and recognizable items

Open `releases/StealAnOPItem_71_SecretFormulaAndRa.rbxlx` in Roblox Studio. This release extends the completed Version 70, which was built from the user's complete Version 69 upload. Previous game files and backups are preserved.

## What changed

- Added **Krabby Patty Secret Formula** as a buyable Legendary item. Its native model has a transparent green bottle, fitted cork, rolled recipe, twine, red anchor wax seal and real **SECRET FORMULA / THE KRUSTY KRAB** surface labels. Price: $65,000; base income: $700 per second. It uses the existing purchase, carry, delivery, theft and inventory paths.
- Improved **Gary the Snail's Shell** with a curved pink silhouette, fitted spiral and markings, and a detailed shell opening.
- Added a detailed golden **Winged Dragon of Ra** statue and named pedestal on the east skyline. Its layered wings, solar halo, horns, face, talons, engravings and armored tail remain decorative. Animated Slifer stays at its Version 70 location.
- Clarified 31 generic or ambiguous display names. Examples: **Ho-Oh's Rainbow Wing**, **Cloud's Buster Sword**, **SpongeBob's Golden Spatula**, **Marvel Space Stone** and **MTG Black Lotus**.

The catalog now contains **66 buyable items**. All 65 previous item IDs, model routes, economic stats, powers and within-rarity weights are preserved. Only Gary's existing collectible geometry changes; the Millennium Puzzle, improved Krabby Patty, Black Lotus and Death Note are retained. Display names feed the conveyor, carried/stored labels, index, inventory and buy-battle list through the shared catalog.

## Rarity and spawn rates

The conveyor already rolls a rarity first, then selects an item from that rarity. Exact selection boundaries and every item's probability were checked. Adding the Formula does not increase the overall Legendary frequency.

| Rarity | Chance per item spawn |
| --- | ---: |
| Common | 37.383% |
| Uncommon | 23.364% |
| Rare | 21.028% |
| Epic | 11.682% |
| Legendary | 4.673% |
| Mythic | 1.589% |
| Ethereal | 0.280% |

The Secret Formula has approximately **0.243% chance per item spawn**, averaging one in 412 rolls. It is 5.2% of Legendary selections. These are probabilities, not a guarantee or pity timer. The earlier sword/axe/pickaxe reduction, Pokémon reduction and Rare/Epic increase are retained. Individual items use those existing modifiers within their rarity.

`spawn-rates.json` and `spawn-rates.csv` list exact probabilities for all 66 items. `item-names.csv` and `../../docs/v71-name-changes.json` show every name change.

## Assets and checks

- `Preview.png`: new Formula, Gary shell and Ra geometry.
- `SecretFormula.png`: actual bottle geometry and recorded label text.
- `GaryShellReview.png`: old and improved shell.
- `WingedDragonOfRa.png`: the placed monument.
- `models/`: standalone native Roblox models.
- `items-manifest.json`: all 66 actual factory models and source hashes.
- `preservation-report.json`: complete place-object and source preservation.
- `validation-report.json`: final check results.

The models need no paid service, Meshy API, textures or external model asset IDs. Previews are offline renders of the actual geometry. Live Roblox Studio rendering, performance and multiplayer playtests remain unperformed. Nothing has been published to Roblox.

Run from the repository root with Python, Pillow, NumPy, Matplotlib, `texlua` and the official Luau CLI:

```sh
python tools/build_v71_place.py releases/StealAnOPItem_70_SliferAndItems.rbxlx
python tools/run_game_checks.py --root roblox/v71-game --baseline roblox/v70-game --check tests/v71_catalog.lua --luau /path/to/luau
python tools/audit_v71_items.py --luau /path/to/luau
texlua tests/v71_ra.lua
texlua tests/slifer_upgrade.lua roblox/v71-game
python tools/package_v71_release.py
```

Handoff branch: `codex/version-63-handoff`. Editable game sources: `roblox/v71-game/`. The default branch remains unchanged.
