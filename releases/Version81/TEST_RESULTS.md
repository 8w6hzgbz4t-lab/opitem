# V81 test results

**Offline checks pass. Real Studio and Roblox testing remain required.**

| Production-code suite | Assertions |
| --- | ---: |
| vault | 105 |
| vault-service | 24 |
| cashshop | 379 |
| session | 171 |
| power | 933 |
| conveyor | 212 |
| hud | 648 |
| vault-ui | 309 |
| server | 24 |
| admin | 527 |

Total: 3332 assertions. All 107 active sources compile verbatim in the official Luau CLI.

The new vault suite executes actual Core, ProfileCodec, ProfileStore and PersistentSession code. It verifies one saved UID after moving/rejoining, both floors, occupied/reserved-slot rejection, owner/token checks, cancellation/timeout/death, theft winning a race, Sell interlocks and exactly-once removal/payment. Before-write failures and ambiguous after-write failures recover the authoritative saved move or sale without recreating a sold item.

Request tests execute VaultService to check owner/base/floor boundaries, malformed inputs, storage/character safety and separate cancellation throttling. Actual Client GUI/event tests check Move, empty slot choices, confirmed existing Sell, absence of a Remove button, transit disabling, stale acknowledgements, cancellation and responsive layouts. Rendering and native controls are represented by doubles.

Existing saving, receipt, powers, conveyor, server, developer and HUD regressions pass on the current sources. All 15 IDs and checkout-off settings are unchanged from V80. The 312 original place objects/properties/hierarchy/backups remain; one new service module is added. All 76 collectible designs and stats are preserved by exact source hashes.

The original music and ten optional WAVs match their preserved file hashes. They have not been uploaded or played in Roblox. Background music remains silent with asset ID zero; existing SFX fallbacks remain.

No actual Studio multiplayer, production DataStore/Marketplace receipt, mobile/controller input, native physics/FPS or audio permission test was performed here. Keep checkout off and complete the V80 private purchase steps and V78 launch checklist. No automatic Roblox publication occurred. Public launch readiness is unverified.

Game SHA-256: `c31783ad964d8af34c7709f46aaace9ed847c67612590198201d56aa5961792f`.
