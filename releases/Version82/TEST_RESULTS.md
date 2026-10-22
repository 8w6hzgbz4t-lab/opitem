# V82 test results

**Offline audio checks pass. Actual Roblox playback remains unverified.**

- 140 assertions exercise actual AudioClient/AudioConfig: 129 through the existing Roblox sound/GUI adapter and 11 in native official Luau.
- All 107 active production sources compile verbatim in official Luau. The configured ID becomes exactly `rbxassetid://111355988554529`, without precision loss or scientific notation.
- Looping, quiet default volume, independent Music/SFX mute and sliders, zero-volume pause/resume, all ten ordinary power cues plus Royal Seal, cue whitelist, distance/malformed inputs, rate limits and cleanup pass with doubles.
- Only the music ID changes from V81. All other 106 sources, all 313 place objects/properties/hierarchy/backups and all 76 collectible designs/stats are preserved. Move/Sell, saving, product IDs and checkout-off settings match V81.
- Original music/SFX file hashes still match the preserved assets. Ten custom SFX IDs remain zero with built-in fallback cues.

The sound adapter records playback intent; it cannot establish that Roblox approved the upload, that the ID belongs to the correct audio/owner, that the experience has permission, or that a device audibly plays/loops it. Test those in the intended Roblox experience. Saved mute/volume preferences remain active.

Unchanged gameplay evidence is inherited by exact source hashes from Version81/validation-report.json. Its 3332 assertions were not rerun for this one-line configuration change. Existing live save/purchase/multiplayer/device/performance gates remain. Checkout stays off; no automatic Roblox publication occurred.

Reproduce audio checks: `python3 tools/run_v82_audio_checks.py --root roblox/v82-game --report releases/Version82/audio-checks.json --luau /path/to/luau` (requires texlua and official Luau CLI).

Game SHA-256: `6ec75ff8f854692e05cf77ed516cbb11a6b457e756e0493b2591ad00f4da97fe`.
