# Version 77 — Robux offers

Extract `Version77_Game.zip` and open `StealAnOPItem_77_RobuxOffers.rbxlx` in Roblox Studio. This incremental update preserves the complete V76 game, all 76 collectible models/stats, developer authorization, flight, audio, base progression and risky carry rules.

The shop bench now previews three tabs: **Cash**, **Levels**, and **Powers**. Prices are proposed, with no live checkout, Marketplace prompt or receipt grant. The server validates only the supported effects; conveyor collectibles and developer privileges are excluded. Tag remains free. Power purchases, when implemented in a future release, must unlock an ordinary power without increasing normal loadout slots or granting developer access.

| Offer | Proposed Robux |
| --- | ---: |
| 5,000 game cash | 25 |
| 20,000 game cash | 100 |
| 50,000 game cash | 250 |
| 100,000 game cash | 500 |
| +1 base level | 25 |
| +5 base levels | 100 |
| Dash | 2 |
| Pull | 6 |
| Slow Field | 8 |
| Ground Slam | 25 |
| Knockback Pulse | 70 |
| Force Field Shield | 90 |
| Lightning Strike | 325 |

Cash packs use 200 cash per Robux. Ordinary power prices round their existing gameplay cash price up at that same rate. These are proposed catalog prices, not live Roblox prices. Configured Developer Products and durable server receipt fulfillment remain required before any Robux charge. This game still has session-only progress; the preview cannot be enabled just by changing a Boolean.

Slow Field's old description incorrectly said it could not drop loot. Its description now matches V76 gameplay; every gameplay power statistic is preserved.

## Why music is silent

`ServerScriptService → OPItemV2 → AudioConfig` currently contains `Music={AssetId=0,...}`. Roblox cannot stream the bundled local OGG directly. Upload `releases/Version76/Audio/relic-rivalry-loop.ogg` through Creator Dashboard as the experience owner, wait for approval, grant this experience audio permission, and replace `AssetId=0` with that numeric audio ID while Studio Play is stopped. Save and restart Play. Check Settings → Music and Studio Output. The custom effects can be configured the same way; built-in SFX already work.

Detailed audio instructions, the original music, ten effects and display artwork remain in `releases/Version76/Audio/` and `Art/`, included in the source bundle. No audio or game was published to Roblox.

## Completion prompt and validation

Copy [FINISH_AND_PUBLISH_PROMPT.txt](FINISH_AND_PUBLISH_PROMPT.txt) to request the remaining publishing work. It covers saved progress, safe item ownership across theft/reconnects, receipt fulfillment, product configuration, exclusive developer access, audio IDs, multiplayer/device/performance tests and Creator Dashboard steps. It does not authorize automatic publication or promise revenue/player counts.

V77 checks compile all 99 active sources and execute actual shop validation, preview GUI, bench geometry, Server snapshot/audio routing and all eight power paths. The builder retains all 305 V76 objects and proves every other source/property/hierarchy/backup unchanged, apart from the six reviewed sources. Earlier V76 offline checks remain available for unchanged subsystems. Studio multiplayer, native devices, rendering and real audio/product configuration remain untested.
