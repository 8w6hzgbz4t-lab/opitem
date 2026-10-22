# Version 81 handoff

Current Studio file: **StealAnOPItem_81_BaseItemMove.rbxlx** inside [Version81_Game.zip](Version81_Game.zip). Editable source and evidence: [Version81_SourceAndGame.zip](Version81_SourceAndGame.zip). Active source folder: `roblox/v81-game/`.

Adds owner-base Move controls beside the existing confirmed Sell for 50%. There is no separate Remove feature. Moves select an empty unlocked slot and save the existing item UID atomically. Active selection prevents selling that item; carried, reserved and inconsistent items cannot be moved/sold. Theft invalidates selection without granting immunity. Sold UIDs cannot be recovered through stale interactions.

All 15 Developer Product IDs, checkout-off flags, collectible designs/stats, saved schema and original backups are preserved. Updating the existing Roblox experience keeps its product IDs. Nothing has been published automatically; when explicitly installing an update, select the existing experience/place in Studio rather than creating a new one. Preserve and merge any unsupplied local edits first.

Audio: [Version81_AudioUpload.zip](Version81_AudioUpload.zip) includes the original music and optional ten SFX. Upload `AudioUpload/relic-rivalry-loop.ogg`, approve/grant experience access, and return its numeric audio asset ID. Current music ID is zero; built-in SFX fallbacks remain. Follow [AUDIO_UPLOAD.md](Version81/AUDIO_UPLOAD.md).

Read [Version81/README.md](Version81/README.md), [TEST_RESULTS.md](Version81/TEST_RESULTS.md), the [V80 private purchase steps](Version80/PRIVATE_TEST_STEPS.md) and the [full launch checklist](Version78/LAUNCH_CHECKLIST.md). Offline production-code checks do not establish real Roblox purchase/save/multiplayer/device/audio readiness. Keep checkout off until those tests pass.
