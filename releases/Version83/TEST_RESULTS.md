# V83 test results

**Offline checks pass. Actual Studio/private-server testing remains required.**

| Production-code suite | Assertions |
| --- | ---: |
| power | 971 |
| prompt-client | 36 |
| conveyor | 212 |
| session | 171 |
| vault | 105 |
| cashshop | 379 |
| vault-service | 24 |
| hud | 696 |
| vault-ui | 363 |
| server | 24 |
| join | 36 |
| admin | 527 |
| audio | 140 |
| base-workbench | 18338 |

All 109 active Lua sources compile verbatim in official Luau. The owner prompt test follows the actual 0.35-second server hold through confirmation, without changing money early; it verifies visitor theft, full vault sales, Move/carry/save/LOS gates, theft during a hold and stale sold UIDs. Client tests check personalized labels before display, ownership changes, late metadata, lifecycle cleanup and no authority changes.

Actual GUI/event checks cover item-specific confirmation/cancellation, Favorite preserving its stored preference action, stolen/deleted selection rejection, plain single-line power text and border-only selection outlines across desktop/phone/landscape layouts. Native rendering and controller/touch input are not simulated.

The actual Server join function assigns eight unique vaults and spawn points, rejects a ninth admitted player, avoids duplicate reservations under concurrent loads and releases failed/departed loads. Request-wiring checks retain Sell, Favorite and base upgrades near either workbench. These use controlled players and storage boundaries, rather than Roblox matchmaking.

Workbench tests record actual generated geometry for all eight bases: 64 parts each, bounds/door/pedestal clearance, retained anchor/callbacks, idempotent rebuilding and unobstructed forward prompt attachment segments in both orientations. Physics and visual appearance still need Studio inspection.

Saving/receipt, conveyor, power, developer and configured-audio regressions pass on the current source hashes. All 76 collectible designs/stats, music ID and product IDs match V82. All 313 existing objects and backups remain; two modules are added. The one approved non-source property change is Players.MaxPlayersInternal12→8; verify the published Dashboard setting separately.

No actual Studio multiplayer, live save/purchase, native device rendering/input, physics/FPS or Roblox audio/asset permission test occurred here. Checkout remains off. Nothing was published to Roblox automatically. Public launch readiness remains unverified. See RELEASE_QUESTIONS.md, the full launch checklist and private purchase steps.

Game SHA-256: `85878dd2e91db6c3778ab2f6267e76154c2a65fc7ca2f9ec12dcb21e394bbe7c`.
