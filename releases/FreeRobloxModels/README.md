# Free native Roblox models — version 64

These are actual finished Roblox part models and complete Lua builders. They require no Meshy account, API key, generation credits, external model asset IDs, or paid AI service.

## Open the game

Open the parent release file `StealAnOPItem_64_FreeModels.rbxlx` in Roblox Studio and press Play. It preserves version 63 and adds 17 buyable items for 63 total catalog entries. The original Millennium Puzzle and the original 46 items' IDs and stats are unchanged.

New items: Kirby Sword, Golden Spatula, Krabby Patty, Gary Shell, Super Star, Fire Flower, Hylian Shield, Companion Cube, Proton Pack, six separate Legendary Infinity Stones, P.E.K.K.A, and Mega Knight. Blue Shell gets an improved model; Dragon Balls remain buyable.

The integrated scenery includes a detailed workstation in each base, a physical power console, crown towers, Ra and Obelisk, a Black Lotus card, a framed Mirror Force card, Exodia's Spellbinding Circle with chains reaching his wrists, an improved bell tower, and an animated Ho-Oh. The rainbow moves to the side and the old cloud blobs are removed. Existing walls, roofs, shop anchors, conveyor, delivery line and protection systems are retained.

## Reuse the models in your latest local game

If your local game is newer than version 63, merge the models and integration changes instead of replacing your newer gameplay with this place.

- `models/*.rbxmx`: 34 complete importable model files, including separate Ho-Oh components and one complete static bird.
- `FreeNativeBuilders.rbxmx`: complete `FreeModels` ModuleScript folder. Import it under the server game package.
- `FreeNativeModelGallery.rbxmx` and `.rbxlx`: inspection galleries with models scaled to fit individual display spaces. The individual model files preserve their intended sizes.
- `obj/*.obj` and matching `.mtl`: optional freely generated mesh geometry for Blender or another 3D editor. Keep each OBJ beside its MTL. Review materials and triangle counts before a Studio mesh import.
- `gallery.html`, `NewItems.png`, `NewDecorations.png`, and `previews/`: previews rendered from the actual geometry. Studio lighting differs.
- `roblox/free_models/` in the complete ZIP: editable Lua modules.
- `roblox/v64-game/` in the ZIP: complete staged game sources for the ready-made release.

Use `FreeModels.create(parent, {model="kirby_sword", itemId=yourCatalogId, name="Kirby Sword"})` to construct a model. Keep `Primitives`, `Assets`, `Labels`, all family modules, and `FreeModels` as siblings. `FactoryIntegration.install(factory)` replaces visuals without changing economy or ownership. `CatalogAdditions.lua` defines item47–item63 for the supplied version 63 baseline; resolve IDs before merging with a newer catalog.

Ho-Oh uses `HoOhAssembler.create(parent, towerOriginCFrame, 1.25)` and `HoOhFlight.pose(bird, origin, elapsedTime)` on the client. The supplied version 64 already installs both. It uses a repeating 32-second circuit with wing and tail movement. It is a decorative bird, not an NPC or stealable item.

## One reference remains missing

The exact Squidward “Force of Despair” meme image was not supplied. A finished painting frame/canvas is included and marked `ReferenceRequired`; no guessed picture was inserted. The blank frame is excluded from the game world. Supply the exact image to finish that artwork.

## Scope of this release

This is the free model and visual-integration update. The separate prompt's eight-power rebalance/VFX, HUD resizing, weapon spawn reduction, Rare/Epic boost, conveyor speed change, and Infinity Stone level-up/comet event are not implemented by this model release. Existing version 63 gameplay remains intact. The Infinity Stones are real buyable Legendary collectibles here, but their collection event still needs that gameplay work.

## Validation

Native geometry, scaling, rotated pivots, collision flags, metadata, all 63 catalog entries and new-item transactions pass offline checks. The original six session test groups still pass. The place builder preserves all 242 original version 63 objects and changes five source scripts for catalog/visual integration.

Roblox Studio is unavailable in the cloud. Use Test → Server & Clients to check visual quality, mobile performance, carrying, new item purchases, protection, shop interaction, and Ho-Oh's flight before publishing. Nothing was published to Roblox.

From the extracted complete ZIP root, the repeatable checks are:

```sh
python3 tools/check_free_models.py --luau /path/to/luau
python3 tools/run_game_checks.py --root roblox/v64-game --baseline roblox/game --check tests/free_catalog_upgrade.lua --luau /path/to/luau
python3 tools/check_carry_presentation.py --root roblox/v64-game --luau /path/to/luau
texlua tests/world_integration.lua roblox/v64-game /tmp/opitem-v64-world.json
```

The build/export helpers use Python, NumPy, Pillow, Matplotlib, texlua and the official Luau CLI. The original version 63 place is included for source-preserving rebuilds. No API key is used by this workflow.
