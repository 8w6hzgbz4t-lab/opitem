# Version 72 design review

The design direction is recognizable crossover collectibles presented together in a shared relic vault. The three new Transformers props use native Roblox geometry, with the same compact display scale and restrained metal, stone and energy accents as the existing collection.

| Collectible | Visible identifying details | Geometry |
| --- | --- | --- |
| Transformers AllSpark | Closed metal cube, six recessed faces, 36 angular glyphs and 12 fitted edge rails | 238 parts |
| Transformers Matrix of Leadership | Two open finger handles, gold energy ring, faceted blue crystal and silver crown | 209 parts |
| Optimus Prime Energon Axe | Sharp orange crescent, visible cutting edge, red and blue emitter, recognizable faceplate badge | 187 parts |

All 69 catalog items execute through the actual item factory. The checks cover finite geometry, rigid carry pivots, distinct visible models, noninteractive decoration, a maximum horizontal display footprint of 5.5 studs and a maximum of 240 parts per collectible. All 66 previous catalog definitions, model geometry, hierarchy and SurfaceGui properties remain identical to Version 71, including the Millennium Puzzle, revised Gary shell, Krabby Patty and Secret Formula.

The eight bases now share dark stone wall panels, bronze inlays, fitted display frames, Roman numeral display plaques and numbered entrance jambs. Matching promenade inlays, six relic medallions, a power lab surround and a restrained arrival trim connect the bases to the market. These additions contain no colliders or query/touch surfaces. Actual world-builder comparisons preserve the original instance properties, eight storage slots per base, owner labels, upgrade anchors, spawn positions, full-width green entrance lines, solid roofs and perimeter walls, shops and item-only disposal.

The original two-stage rarity selection remains: roll a rarity tier, then select a weighted item within that tier. Adding the three collectibles does not change tier frequency. Exact normalized probabilities for all 69 items are recorded in `spawn-rates.csv` and `spawn-rates.json`.

Preview images are renders of actual generated geometry. They are useful for silhouette and palette review; they do not reproduce Roblox lighting, bloom, physics, multiplayer behavior or frame rate. Native SurfaceGui text may be absent from some three-quarter geometry renders. A live Studio playtest remains necessary before publication.
