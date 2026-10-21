# Steal An OP Item

Latest cloud build: **Version 78**, based on the preserved Version 77 place.

- Game download: `releases/Version78_Game.zip`. Extract the `.rbxlx` and open it in Roblox Studio.
- Editable source, game, audio, artwork and reports: `releases/Version78_SourceAndGame.zip`.
- Read before Play: `releases/Version78/LAUNCH_CHECKLIST.md`. Saved profiles now require DataStore API access in a private test experience; Studio automatically uses separate TEST stores. Failed loads never create a writable blank fallback.
- Changes and evidence: `releases/Version78/README.md` and `validation-report.json`.
- Product setup: `releases/Version78/PRODUCT_SETUP.md` and `ProductSetup.csv`.
- Actual shared item previews: `releases/Version78/All76Items.png`.
- Terminal handoff: `releases/VERSION_78_HANDOFF.md`.

V78 implements saved profiles, recoverable theft transfers and receipt fulfillment; adds Ki Blast and Spinjitzu; auto-locks Lightning; aims Slow Field; adds fading Ground Slam rubble; separates power selection from F/R2/touch activation; saves audio sliders; and makes private flight a triple-jump toggle with a travel-facing Superman pose. All 76 collectible models, names, stats and spawn weights are preserved. Conveyor and Index use the same templates.

Developer tools remain exclusive to `Goverment_cheesee`. No developer perks or conveyor collectibles are sold. All fifteen Product IDs remain zero and checkout is off until the owner configures products and finishes live tests. The original music needs its owner-uploaded audio ID; fallback SFX work immediately. Audio/thumbnail/icon assets are in `releases/Version76/Audio` and `Art`, included in the source package.

Offline production-code, storage/crash, GUI, geometry and preservation checks pass. Live Roblox Studio multiplayer, device input, storage latency/budgets, audio permissions and receipt delivery are **not tested here**. The build is not verified ready for public launch. Nothing has been published to Roblox.

Main and the checkout HEAD remain unchanged. Reviewed downloads are handed off on `codex/version-63-handoff`. Earlier releases and the original uploaded game remain preserved. Active editable sources: `roblox/v78-game/`.
