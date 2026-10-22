# V80 private verification before checkout

The delivered file has checkout **off**. All 15 IDs are owner supplied, and neither their Roblox ownership/prices nor live fulfillment have been verified. Do not make the game public or enable public checkout based on the offline results.

## Choose the test experience

For this first release, use the intended experience while it is **Private**. Confirm that each ID in [PRODUCT_IDS.md](PRODUCT_IDS.md) belongs to that same experience. If an existing game is already public, use a separate private test experience and create its own Developer Products. Product IDs cannot be reused across experiences. A private server or second place in one experience shares its published saved data.

Keep a backup of the delivered `.rbxlx`. Opening or saving a local file does not update a published server; the owner must explicitly publish any private test version and start a new server.

## Verify configuration and saving first

1. In Creator Dashboard, check all 15 product names, IDs, intended rewards, sale status and fixed Robux prices against [ProductSetup.csv](ProductSetup.csv). Keep **Managed pricing off**. The game does not implement Price Levels API transfer checks, so do not claim those checks exist in Roblox's pricing prompt.
2. Keep `CashShopConfig.Enabled=false` and `PreviewOnly=true` while checking setup. Confirm the server initializes without errors and that unconfigured or unavailable offers cannot open checkout.
3. Join the private game with test accounts. Earn cash, deliver items, change powers/settings and upgrade a base. Leave and join a new server; confirm progress returns once with the same ownership/slots. Test buying, bidding, theft and recovery with multiple accounts. Never clear or reset production data to simulate a failure.
4. For Studio DataStore checks, enable **Game Settings → Security → Enable Studio Access to API Services** only for the chosen private test experience if needed. Studio uses the `StealAnOPItem_TESTProfiles_v1` and `StealAnOPItem_TESTTransfers_v1` stores; published private servers use the normal store names. Check real permissions, failures, retry behavior, budgets and rejoin behavior before purchases.

## Controlled private purchase tests

Only after the configuration and saving prerequisites above pass, prepare an explicitly controlled **private test version** with `Enabled=true` and `PreviewOnly=false`. Keep the delivered release and any public version off. All 15 IDs must be valid and unique; the flags must be opposites. Do not delete offers or change paid product-to-reward mappings to bypass validation.

The server checks Roblox product information and its configured price before a new prompt. A price mismatch, unavailable listing or API failure should block the offer. Product information may cache for 120 seconds; start a new test server after changing prices/configuration.

**A published purchase test can charge real Robux.** Review Roblox's confirmation amount before approving any test purchase. A simulated Studio purchase is not proof of a real receipt or durable fulfillment.

- Cancel checkout: no reward should appear.
- Complete a controlled purchase: confirm the server grants the exact mapped reward only after the receipt and reward are saved together. Leave and join a new server; verify the reward remains exactly once.
- Test representative cash, level and power purchases. Confirm owned powers and maximum levels block new offers. Choose the free starter before testing Dash; do not pay for an already-owned power.
- Exercise leaving during delivery and joining a different server. Record delayed/retried receipt behavior. Use the supplied offline harness for reproducible duplicate callbacks, ambiguous writes and storage failures; record actual Roblox observations separately.
- Verify a legitimate delayed receipt still fulfills when new checkout is disabled. An unavailable power or capped level reward uses the documented cash fallback, and overflow remains saved credit. Never delete or repurpose IDs after accepting payment.
- Confirm clients cannot grant rewards through purchase-finished events or arbitrary remotes. Test a non-developer account; it must never receive developer menus, gifts, flight, protection or Royal Seal through a purchase.

Return the private test configuration to `Enabled=false`, `PreviewOnly=true` while reviewing results. Public checkout remains a separate owner decision after durable fulfillment and all release gates pass.

## Audio and remaining release gates

Upload `releases/Version76/Audio/relic-rivalry-loop.ogg` through **Creator Dashboard → Creations → Development Items → Audio → Upload Asset** under the owner account/group. Wait for moderation, grant the correct universe permission under **Permissions → Experiences**, then send the numeric audio asset ID. Music remains silent until that ID is connected. Custom SFX uploads are optional; built-in fallback effects already exist.

After configuration, check looping, permissions, device volume, separate music/SFX sliders, mute and saved preferences. Complete [Version78/LAUNCH_CHECKLIST.md](../Version78/LAUNCH_CHECKLIST.md), including real multiplayer, every power, mobile/controller controls, full-server performance, solid geometry, spawn safety, asset permissions and Dashboard requirements. Preserve the V79 checks for conveyor disposal, hologram/real-carry separation, no paid-loss refund, bid refunds, stored items surviving death, safe Exodia respawn and visible owner-only theft alerts.

Record the date, game version, universe, account roles, device, expected result and observed result for each live test. Offline evidence and Studio/private-server evidence must remain separate. V80 is not yet verified for public launch.
