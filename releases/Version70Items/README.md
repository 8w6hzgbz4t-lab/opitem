# Version 70 item review

These previews show the actual models built by the game's active `ModelFactory` for all 65 catalog entries. The 19 newer entries include the Nintendo/SpongeBob collectibles, Companion Cube, Proton Pack, six Infinity Stones, P.E.K.K.A, Mega Knight, Black Lotus, and Death Note.

- [New 19 items](New19Items.png)
- [All 65 items](All65Items.png)
- [Puzzle, Dragon Balls, Duel Runner, empty Freddy suits, Lotus, and notebook](RecentItemsAndPuzzle.png)
- [Machine-readable geometry and catalog audit](manifest.json)

The item audit instantiates every real factory route, checks finite dimensions and orthogonal frames, anchored noninteractive geometry, connected carry pivots, distinct models, compact display footprints, and new-item base alignment. It verifies all catalog values and spawn weights against the supplied Version 69, preserves the Millennium Puzzle's exact generated geometry, checks the Dragon Balls' seven individual star counts, and keeps both Freddy costumes empty.

Black Lotus, Death Note, and Krabby Patty received geometry refinements. All other collectible geometry is checked against Version 69 without changes.

The pictures use an offline geometry renderer. Roblox lighting, materials, and rounded surfaces will look different in Studio. The notebook's front preview includes its recorded SurfaceGui title; an additional `previews/death_note-3d.png` shows its dimensional covers and binding. Live Studio rendering, multiplayer, physics, and performance still require a Studio playtest.

To reproduce from the repository root:

```sh
python tools/audit_v70_items.py
```

The runner uses the official Luau CLI for source compilation and the local geometry recorder for the factory audit. It does not need paid services or external model assets.
