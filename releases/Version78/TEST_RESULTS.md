# V78 test results

**Offline checks passed. Live launch readiness is unverified.**

Production modules ran under the official Luau CLI or Roblox API/native-geometry adapters. These adapters do not start Studio or prove multiplayer replication, live storage behavior, native input or performance.

| Offline area | Assertions/checks |
| --- | ---: |
| Profile locks, retries and injected crash boundaries | 147 |
| Actual economy/save/receipt/departure integration | 171 |
| Profile schema and all collectible round trips | 472 |
| All ten powers and developer Royal Seal | 903 |
| Bounded projectile, tornado, rubble and lock warnings | 3656 |
| Developer server authorization and commands | 527 |
| R6/R15 flight pose and restoration | 138 |
| Power controls, settings and small-screen HUD | 498 |
| Developer menu controls | 99 |
| Shop server pricing, prompts and receipts | 287 |
| Shop interface / bench geometry | 109 / 157 |
| All 76 Index templates at four viewport widths | 7601 |
| Collectible native geometry / catalog transactions | 290189 / 9634 |
| Eight expanded bases, stairs, roofs and walls | 1326582 |
| Developer puzzle / rod attachments | 12937 |
| Developer visual effects | 2448 |
| Progression / animated Slifer / audio routing | 118 / 350 / 114 |
| Server snapshot and audio glue | 16 |

The original six session groups and thirteen regression groups pass. All 76 models, names, stats and rarity weights match V77. The XML builder retained all 305 original instances and added seven modules. The packager verified current source/test hashes, preview geometry and ZIP integrity.

## Required live checks

No actual Roblox Studio multiplayer, DataStore/API budget/latency, shutdown timing, Marketplace receipt, touch/controller device, full-server physics/FPS, audio playback/permission or account lookup test ran in this cloud. Follow LAUNCH_CHECKLIST.md in a private test experience. Product IDs and the music upload ID remain unset; checkout is disabled.

Game SHA-256: `188f8827842ce36144c597113e4d31069516889297698aeffa0b227663c3706c`.
