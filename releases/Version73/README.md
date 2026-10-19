# Version 73: skyline cleanup

Open `releases/StealAnOPItem_73_SkylineCleanup.rbxlx` in Roblox Studio and press **Play**. The map is generated when the server starts.

The Kaiba Corp tower has been removed. Legacy static Slifer statues remain excluded, and the scene builder removes imported copies with their known legacy names. The animated Slifer remains in its existing skyline location.

This changes only `DetailedArt/EnhancedScene.lua` from Version 72. All 69 items, their models and stats, the Millennium Puzzle, detailed Winged Dragon of Ra, Crimson Dragon, Shenron, other towers, base presentation and gameplay are preserved. Original uploads, backups and Version 72 remain available.

- Editable sources: `roblox/v73-game/`.
- Source and complete game: `releases/Version73_SourceAndGame.zip`.
- Rebuild the place: `python tools/build_v73_place.py` from the repository root.
- Validation: `scene-checks.json` and `preservation-report.json` beside this file.

Offline world-generation, geometry, animation and gameplay checks were run. Live Roblox Studio rendering, physics, performance and multiplayer still need a Studio playtest. Nothing has been published to Roblox.
