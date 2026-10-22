# V82: music asset configured

The owner-supplied music asset ID **111355988554529** is configured in `AudioConfig.Music.AssetId`. Open **StealAnOPItem_82_MusicConnected.rbxlx** from [Version82_Game.zip](../Version82_Game.zip). Editable source, game and verification evidence are in [Version82_SourceAndGame.zip](../Version82_SourceAndGame.zip).

Only the music ID changed from V81. Move/Sell, all 76 collectibles and their stats, saved progress/settings, ten powers, developer tools, all 15 product IDs, original place properties and backups are preserved. Checkout remains **off**. Nothing has been published to Roblox automatically.

## Hear it in Roblox

1. In Creator Dashboard, open the audio asset **111355988554529** under the account/group that uploaded it. Wait for Roblox approval if it is still pending.
2. Under the audio's **Permissions → Experiences**, grant **Steal An OP Item** access if required. When asked for an experience ID, use the **universe ID** shown in the experience's Creator Dashboard URL, rather than a place ID. A different test experience needs its own permission.
3. Open the V82 file in Studio and start a fresh Play session in the intended experience. In the game's **Settings**, turn **Music ON** and raise **Music volume** above zero. Check your Mac/device sound too. Saved mute/volume preferences are preserved rather than reset by this update.
4. Listen through the loop, test Music off/on and its volume slider, then rejoin to check saved preferences. Sound effects use their separate switch/slider. Check Studio **Output** for an asset-loading or permission error if music remains silent.

Asset type, ownership, moderation, experience permission and actual playback cannot be confirmed by the offline checks. The configured ID is treated as owner supplied; no claim is made that Roblox has approved it or that the game has already played it.

## Update your current Studio file instead

If your open file has additional local changes, keep that file and make this same one-line edit with Play stopped:

**Explorer → ServerScriptService → OPItemV2 → AudioConfig**

```lua
Music={AssetId=111355988554529,Volume=.18,PlaybackSpeed=1,Title='Relic Rivalry'},
```

Save and restart Play. Your terminal can make the same edit to the current source/place file; use `roblox/v82-game/AudioConfig.lua` as the reference. Merge unsupplied local changes before replacing a local file with the supplied V82 build.

When you explicitly choose to upload an update, select the **existing experience and place** in Studio's Publish workflow. The same experience keeps its 15 Developer Product IDs and saved data stores. Creating a new experience would not reuse those products or stores. This download does not publish or enable purchases.

## Sound effects and release checks

The ten optional custom SFX IDs remain zero and their existing built-in fallback cues remain. Use [AudioIDs.csv](AudioIDs.csv) to supply their uploaded IDs later. The original files are in [Version81_AudioUpload.zip](../Version81_AudioUpload.zip); do not upload the music again just to install V82.

See [TEST_RESULTS.md](TEST_RESULTS.md) for offline evidence. Actual Studio/private-server audio playback and the [full release checklist](../Version78/LAUNCH_CHECKLIST.md) remain required. The [V80 private purchase steps](../Version80/PRIVATE_TEST_STEPS.md) still apply to the shop. Public launch readiness remains unverified.
