# Original music and sound effects

`relic-rivalry-loop.ogg` is an original **51.89-second, 148 BPM** synth battle loop composed for this update. It uses a dark minor-key bass line, changing arpeggios, lead phrases and synthesized drums. It contains no sampled recordings or copied theme melody. Ten short original WAV effects accompany it.

The game immediately uses built-in Roblox sounds for gameplay cues. The new music and custom effects require audio asset IDs from your Roblox account; a local OGG/WAV cannot play directly from a Roblox `Sound`. Music stays off until its ID is configured. Music and sound effects have separate on/off controls in **Settings**.

## Enable the custom audio

1. Upload the OGG and WAV files through Roblox Creator Dashboard's audio upload flow. Use the account or group that owns the experience, and grant this experience permission to use each uploaded asset if required. Wait for Roblox moderation to finish.
2. Open the Version 76 place in Studio while **not** running Play. In Explorer, open **ServerScriptService → OPItemV2 → AudioConfig**.
3. Replace `Music.AssetId=0` with the music's numeric audio asset ID. For each effect, replace its cue's `AssetId=0` with that upload's numeric ID. Keep IDs as numbers, without quotation marks or `rbxassetid://`.
4. Test Music and Sound effects toggles in Play. Test purchases, interrupted carries, delivery, protection activation/expiry, level-ups and powers with two players. Check Studio Output for permission or moderation errors. Save the place after configuring.

| File | `AudioConfig` location | Trigger |
| --- | --- | --- |
| `relic-rivalry-loop.ogg` | `Music.AssetId` | Quiet looping background music |
| `power-cast.wav` | `Cues.powerCast.AssetId` | Power activation |
| `power-hit.wav` | `Cues.powerHit.AssetId` | Successful power impact |
| `shield.wav` | `Cues.shield.AssetId` | Shield activation/block cue |
| `purchase.wav` | `Cues.purchase.AssetId` | Purchased item pickup |
| `item-lost.wav` | `Cues.lost.AssetId` | Carrier loses an item |
| `delivered.wav` | `Cues.deliver.AssetId` | Successful base delivery |
| `base-lock.wav` | `Cues.lock.AssetId` | Base protection activates |
| `base-unlock.wav` | `Cues.unlock.AssetId` | Base protection ends |
| `level-up.wav` | `Cues.levelup.AssetId` | Base level increases |
| `ui-tick.wav` | `Cues.ui.AssetId` | Game menu button activation |

Powers have individual pitch profiles. Positional cues become quieter with distance and stop beyond 160 studs. Rate limits and a 12-sound pool prevent noisy event bursts. The music defaults to 18% volume and effects to 55% before per-cue scaling. These are client playback controls; audio changes no gameplay outcome or developer permissions.

Reproduce the assets with `python tools/generate_v76_audio.py`. `audio-metrics.json` records file hashes, duration, peak/RMS, the lossless loop boundary and decoded OGG checks. The output has no clipping; the source loop ends at its initial sample value. Offline tests exercise playback routing, upload guards, settings, attenuation, limits and cleanup. Roblox asset permission, moderation and actual Studio playback need to be checked after uploading.
