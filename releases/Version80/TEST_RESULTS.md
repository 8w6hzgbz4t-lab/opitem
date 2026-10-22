# V80 test results

**Offline checks pass. Actual Studio and Roblox purchase testing remain required.**

| Production-code suite | Assertions |
| --- | ---: |
| cashshop | 379 |
| session | 171 |
| server | 24 |

All 106 active Lua sources compile. The shop suite checks every configured ID against its intended reward, cancellation, disabled checkout, price mismatch, owned/capped rewards and receipt retries. The session suite checks saved grants, rejoin, crash/ambiguous-write recovery and ownership transfers. The server suite checks snapshot, audio and owner-only theft notifications.

These suites execute actual production source with controlled Roblox API/storage doubles. They do not verify real Robux charges, Roblox ownership, current prices, production DataStore behavior or Studio multiplayer.

Only CashShopConfig.lua differs from V79. The other 105 active sources, all 312 original place objects, hierarchy/properties/backups and all 76 collectible designs/stats match the preserved baseline. Existing V79 evidence covers unchanged systems; those entire suites were not rerun for this configuration-only change.

All 15 IDs match the owner messages, CSV, setup JSON and embedded Studio source. Checkout stays off. Music has not been uploaded; its asset ID remains zero. All 15 provided product PNGs pass their recorded hashes and 512×512 PNG dimension checks.

Use PRIVATE_TEST_STEPS.md and the wider Version78/LAUNCH_CHECKLIST.md before release. Nothing has been published to Roblox by this build. Public launch readiness remains unverified.

Game SHA-256: `92aa800091dc32d54c8ef6d68b32c97eea3d4b6bdf84be8d2df3336e645110b8`.
