# Version 78 — Powers and Saved Progress

Extract `Version78_Game.zip` and open `StealAnOPItem_78_PowersAndSavedProgress.rbxlx` in Studio. Keep V77 as a backup. Read **LAUNCH_CHECKLIST.md before Play**: saving now requires a private test experience with DataStore API access. Studio uses separate TEST stores. Failed/locked/corrupt profiles are rejected safely; there is no session-only blank fallback.

## Implemented

- Saved cash, bank, levels, both inventory floors, item UIDs, discoveries, power ownership/loadout/cooldowns, settings and collection reward history. Versioned profiles use session locks, autosaves, retries and shutdown saves. Theft transfers use a durable decision journal so both accounts recover one owner. Critical changes are acknowledged after storage commits; ambiguous failures stop play without overwriting confirmed data.
- Ten regular powers. **Lightning** auto-locks the nearest visible opponent and rechecks range/cover. **Ki Blast** aims in 3D and explodes within six studs, with per-target cover, shield and immunity checks. **Slow Field** places at the center reticle within 16 studs. **Spinjitzu** is a moving tornado with one hit per target. **Ground Slam** raises distinct stone rubble and glowing cracks that fade without collision. Effects are bounded and support reduced-effects mode.
- Clicking a power or pressing **1–3** selects and highlights it only. **F**, controller **R2**, or the separate touch **Use** button activates the selection. L2 selects Tag. Loadout Equip buttons never fire powers. Tag stays fixed with two optional regular slots; developer Royal Seal remains a private fourth selection.
- Developer tools remain exclusive to **Goverment_cheesee**, with numeric server authorization. Three Space/Jump presses start **or stop** flight. The character faces travel in a Superman pose, including vertical movement, and restores its joints/upright pose on landing. No gyroscope is created. Carrying/bidding/death clears mods.
- Separate music/SFX volume sliders and mute toggles for mouse, touch and controller; saved preferences and an opt-in first-play guide.
- Fifteen shop offers: cash, base levels and all nine optional regular powers. Cards show effect/rank/cooldown/price and a short preview. No conveyor collectibles or developer perks are sold. A free starter cannot be sold before the free choice. Real receipt processing saves reward plus receipt together; duplicate/delayed receipts, capped rewards and saved cash overflow have defined handling.
- All **76 item models, names, stats and spawn weights are preserved**. Conveyor and Index clone the same factory templates. Index lighting/framing fits every model across four viewport widths; `All76Items.png` and individual previews show the actual native geometry. Surface text in offline previews is approximate; final Studio review is required.

## Setup still required

**Checkout remains off, all Product IDs remain zero.** You said these products still need to be created. Follow `PRODUCT_SETUP.md` and `ProductSetup.csv`. Do not enable checkout before live storage/receipt tests pass.

**Music remains silent until its upload ID is configured.** Upload `Version76/Audio/relic-rivalry-loop.ogg` as the experience owner, grant this experience permission, then set `AudioConfig.Music.AssetId` while Play is stopped. Save and restart Play. The ten custom effects can be configured similarly; bundled Roblox fallback SFX already work. Audio/art assets and their instructions are included in the source package.

The cloud did not publish the game, modify your Creator Dashboard, upload audio, create products, verify franchise permissions or perform live Studio tests. Use `ASSET_PERMISSIONS.md`, `GAME_DESCRIPTION.txt`, `ANALYTICS_PLAN.md` and the launch checklist to finish those steps.

## Verification

Reports execute production code with official Luau or native geometry adapters: profile crashes/session locks, multi-profile transfers, receipt deduplication, saved settings/rewards, all powers, developer access/flight, HUD/store controls, all 76 factory models, Index framing, artifacts and base geometry. The builder preserves every original object/property/backup except the reviewed source edits. The packager checks current source/test hashes and ZIP contents.

These are offline checks. Real DataStore budgets/latency, shutdown timing, eight-player replication, actual touch/controller input, final materials/SurfaceGui rendering, audio permissions and Roblox receipt delivery remain live test gates. This build is **not yet verified ready for public launch**.
