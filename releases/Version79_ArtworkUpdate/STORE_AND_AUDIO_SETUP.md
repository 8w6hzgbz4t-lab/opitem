# Connect the V79 Robux shop and music

The current V79 game has **checkout turned off, all 15 product IDs set to zero, and no uploaded music ID**. You can prepare the products and uploads without charging players. Keep those defaults until saved progress has been tested successfully.

## 1. Choose the right private game

If this is your first release, open your current V79 `.rbxlx` in Roblox Studio. Use **File → Publish to Roblox** (or **Publish to Roblox As…**) to create the game under the account or group that will own it. Keep the experience **Private**. This can be the same experience you later release publicly; publishing a private copy does not make it public.

If your game is already public, use a **separate private test experience** and create that test experience's own products. A second place or a private server inside the public experience shares its saved data. Do not put test-experience product IDs into the public experience.

Before testing purchases, check that cash, items, levels, powers and settings survive leaving and rejoining. For Studio DataStore tests, enable **Game Settings → Security → Enable Studio Access to API Services** for the private test experience if needed. Studio uses the separate `StealAnOPItem_TESTProfiles_v1` and `StealAnOPItem_TESTTransfers_v1` stores. Published servers, including private servers, use the normal store names. DataStore isolation between published test and production games requires separate experiences.

## 2. Create and connect all 15 Developer Products

1. Open [Creator Dashboard](https://create.roblox.com/dashboard/creations). Go to **Creations → your game → Monetization → Developer Products → Create Developer Product**.
2. Create one product for each row below. Enter its name, description and listed Robux price; add an icon if requested. These are **Developer Products**, not game passes.
3. From each product's menu, choose **Copy Asset ID**. Record that number in [ProductSetup.csv](ProductSetup.csv) beside the matching name. It is the Developer Product ID, not your UserId, place ID, universe ID or audio ID.
4. You can send the product names and IDs back to Codex to have them wired into the game. These IDs are public identifiers, not passwords. No login credentials are needed. Filling out the CSV alone does not configure the game.
5. After saved progress works, stop Studio Play. In **Explorer → ServerScriptService → OPItemV2 → CashShopConfig**, replace each matching `productId=0` with its numeric ID. Keep every offer's `id`, reward and price intact. Do not use quotation marks around IDs.

| Product name | Reward | Robux |
| --- | --- | ---: |
| Pocket Cash | 5,000 cash | 25 |
| Vault Stack | 20,000 cash | 100 |
| Treasure Chest | 50,000 cash | 250 |
| Grand Fortune | 100,000 cash | 500 |
| One Base Level | +1 level | 25 |
| Five Base Levels | +5 levels | 100 |
| Dash Unlock | Dash | 2 |
| Pull Unlock | Pull | 6 |
| Slow Field Unlock | Slow Field | 8 |
| Ground Slam Unlock | Ground Slam | 25 |
| Knockback Pulse Unlock | Knockback Pulse | 70 |
| Force Field Shield Unlock | Force Field Shield | 90 |
| Lightning Strike Unlock | Lightning Strike | 325 |
| Ki Blast Unlock | Ki Blast | 325 |
| Spinjitzu Unlock | Spinjitzu | 80 |

**All 15 products need different, nonzero IDs before checkout can be enabled.** This build cannot enable only one offer by deleting the other rows or leaving their IDs at zero. Invalid configuration can stop the server script during initialization.

Leave checkout off while configuring:

```lua
Enabled=false,
PreviewOnly=true,
```

Only after all IDs, prices and saved progress are ready, use this pair in the **controlled private test setup**:

```lua
Enabled=true,
PreviewOnly=false,
```

Those flags must be opposites. Save and publish the updated private version, then start a new server. Editing a local module does not update an already-running published server. Keep checkout off in an existing public game while its separate private test copy is being tested. After private testing, keep checkout off until the remaining release checks pass and you choose to enable it.

The Dashboard base price must match the matching `robux` value. Otherwise the server makes that offer unavailable. Price checks can cache for 120 seconds; restart a test server after changing configuration. Cash uses 200 game cash per proposed Robux, and regular-power prices follow their gameplay prices. Review configuration before changing those ratios. Roblox's confirmation window shows the final amount, which may differ with regional pricing.

Tag stays free. The shop sells no conveyor collectibles or developer privileges. Ordinary powers remain available for game currency. Buying a power does not add an equipped slot.

### Check purchases before public checkout

Use the private setup and a controlled tester account. Published purchase confirmations can spend real Robux; review the amount before confirming.

- Visit the Robux bench with a loaded profile and no carried item or active bid. Choose the free starter in Powers first when testing Dash. Already-owned powers are unavailable for purchase.
- Cancel a purchase. Confirm that no reward is granted.
- Complete an actual purchase. Confirm delivery follows the Roblox receipt, then leave and join a new server. Verify the reward remains saved exactly once.
- Test leaving during delivery, reconnecting, delayed or retried receipts, and an already-owned power or capped level reward. A legitimate delayed purchase converts an unavailable reward to the documented game-cash fallback; cash overflow remains saved credit.
- Test storage failures and repeated receipt delivery in a controlled test harness. The reward and receipt must save together. Closing the purchase window or receiving a purchase-finished event must never grant a reward by itself.

The existing offline checks use simulated Roblox and storage adapters. They do not charge Robux, verify your Dashboard products, prove Roblox actually delivered a receipt or replace published multiplayer/rejoin tests. Record those live results separately. Keep each product ID mapped to its original reward: disabling new checkout still allows known, already-paid delayed receipts to finish. Do not delete or repurpose mappings after accepting purchases.

## 3. Upload and connect the original music

The supplied original music is **`Audio/relic-rivalry-loop.ogg` in this download**. V79 uses this same track, originally supplied in `releases/Version76/Audio`. It will not play from your Downloads folder directly; Roblox needs an uploaded audio asset.

1. In Creator Dashboard, select the account or group that owns the game. Go to **Development Items → Audio → Upload Asset** and upload `relic-rivalry-loop.ogg`.
2. Wait for moderation. Open the audio asset's **Permissions → Experiences → Add experiences** and grant your game access if required. This permission uses the game's **universe ID**, not an individual place ID. A separate private test experience needs its own permission too.
3. Copy the uploaded **audio asset ID**. Stop Studio Play and open **Explorer → ServerScriptService → OPItemV2 → AudioConfig** in your current **V79** game.
4. Replace only the music ID:

```lua
Music={AssetId=YOUR_NUMERIC_AUDIO_ID,Volume=.18,PlaybackSpeed=1,Title='Relic Rivalry'},
```

Replace `YOUR_NUMERIC_AUDIO_ID` with the actual number. Do not leave that placeholder, add quotation marks or include `rbxassetid://`.

5. Save, restart Play and test. For a published test, publish the configured private version and start a new server. Open the game's **Settings**, turn Music on and raise its volume slider. Check Roblox and device volume too.

Music automatically loops when configured and unmuted. Its current zero ID deliberately leaves it silent. If it stays silent, check **Studio → Output** for a permission, moderation or asset-loading error, then confirm you used the audio asset ID and granted the correct universe access. Test looping and saved volume/mute settings after a rejoin.

## 4. Optional: upload the ten original sound effects

Built-in effects already work with their current zero IDs. To use the custom WAVs, upload each through the same audio flow, grant experience permission, and enter its numeric asset ID at the matching location in **AudioConfig**:

| Supplied file | Configuration location | Sound |
| --- | --- | --- |
| `power-cast.wav` | `Cues.powerCast.AssetId` | Power activation |
| `power-hit.wav` | `Cues.powerHit.AssetId` | Power impact |
| `shield.wav` | `Cues.shield.AssetId` | Shield |
| `purchase.wav` | `Cues.purchase.AssetId` | Conveyor item purchase |
| `item-lost.wav` | `Cues.lost.AssetId` | Carried item lost |
| `delivered.wav` | `Cues.deliver.AssetId` | Item delivered |
| `base-lock.wav` | `Cues.lock.AssetId` | Base protection starts |
| `base-unlock.wav` | `Cues.unlock.AssetId` | Base protection ends |
| `level-up.wav` | `Cues.levelup.AssetId` | Level increase |
| `ui-tick.wav` | `Cues.ui.AssetId` | Menu button |

Restart and test each cue. **Settings → Sound effects** has its own mute and volume slider. Verify both music and effects settings survive rejoining, and test audibility with multiple players. Uploading music and effects does not enable Robux checkout.

Official Roblox instructions:

- [Developer Products](https://create.roblox.com/docs/production/monetization/developer-products)
- [Audio assets](https://create.roblox.com/docs/audio/assets)
- [Asset privacy and permissions](https://create.roblox.com/docs/projects/assets/privacy)
- [Data stores and Studio access](https://create.roblox.com/docs/cloud-services/data-stores)
