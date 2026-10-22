# Connect the music

The music file is ready. Roblox needs an uploaded **audio asset ID** before the game can play it. The current music ID is `0`, so music is silent. Existing built-in sound-effect cues remain configured.

Start with the music; the ten custom sound effects can follow later.

1. Download and extract `Version81_AudioUpload.zip`. Find **`relic-rivalry-loop.ogg`** in its `AudioUpload` folder.
2. Open [Creator Dashboard](https://create.roblox.com/dashboard/creations). Use the account or group that owns **Steal An OP Item**.
3. Go to **Creations → Development Items → Audio → Upload Asset**. Dashboard labels may vary slightly. Select `relic-rivalry-loop.ogg`.
4. Use this name: **Relic Rivalry — Original Battle Loop**. Description: **Original synth battle loop for Steal An OP Item.** Complete the upload and wait for approval.
5. Open the uploaded audio asset. Under **Permissions → Experiences**, grant **Steal An OP Item** permission if required. If Roblox asks for an experience ID, use its **universe ID**, not a place ID. The universe ID appears in the Creator Dashboard experience URL after `/experiences/`.
6. Copy the audio's numeric **asset ID** from its asset menu or configuration page. Send it back as **`Music: YOUR_AUDIO_ID`**. This is separate from your Developer Product IDs.

The upload must be done in your Roblox account. No Roblox login credentials are needed in chat. If an upload fails, send the exact Roblox error so the next step can address that failure.

## After the ID is connected

The editable setting is **ServerScriptService → OPItemV2 → AudioConfig → Music.AssetId**. Use the numeric audio asset ID without quotes or `rbxassetid://`. Configure it while Studio Play is stopped, save, then restart Play. The background track loops at the saved music volume.

Test in the intended experience after approval and permission: music starts, loops, responds to the **Music** on/off switch and volume bar, and restores those settings after rejoining. Test SFX separately with their own switch and volume bar. Check Studio Output for asset-loading or permission errors. Real Roblox audio playback has not yet been verified.

Updating the same Roblox experience keeps the existing 15 Developer Product IDs. An audio upload creates its own new audio asset ID; it does not replace any product ID. Audio setup does not enable Robux checkout.

## Optional custom sound effects

All eleven files below are included in `AudioUpload`. The original files are preserved unchanged from Version 76. The music is an original 51.89-second, 148 BPM synth battle loop. Custom SFX IDs remain `0` until their uploads are connected; their built-in fallbacks remain available in the meantime.

Upload each optional WAV through the same flow, grant the experience permission, and record its audio asset ID in `AudioIDs.csv`. Send the completed sheet or paste the cue/ID pairs. The music is the only upload needed to begin background playback.

| File | Configuration field | Upload now? |
| --- | --- | --- |
| `relic-rivalry-loop.ogg` | `Music.AssetId` | Yes, for background music |
| `power-cast.wav` | `Cues.powerCast.AssetId` | Optional |
| `power-hit.wav` | `Cues.powerHit.AssetId` | Optional |
| `shield.wav` | `Cues.shield.AssetId` | Optional |
| `purchase.wav` | `Cues.purchase.AssetId` | Optional |
| `item-lost.wav` | `Cues.lost.AssetId` | Optional |
| `delivered.wav` | `Cues.deliver.AssetId` | Optional |
| `base-lock.wav` | `Cues.lock.AssetId` | Optional |
| `base-unlock.wav` | `Cues.unlock.AssetId` | Optional |
| `level-up.wav` | `Cues.levelup.AssetId` | Optional |
| `ui-tick.wav` | `Cues.ui.AssetId` | Optional |

The cloud has checked file integrity and formats. Upload approval, experience access, playback and looping still need testing in Roblox.
