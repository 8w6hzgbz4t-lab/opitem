# V84 offline checks

Only one display statement in Server.lua changes from V83. The base collection sign displays whole dollars; it does not modify banked earnings, prices, level boosts or collection/saving rules.

- All 109 active Lua sources compile verbatim in official Luau.
- Existing durable session suite: 171 assertions pass, covering bank checkpoint/rejoin, items, receipts, recoverable theft and saved settings.
- Existing server snapshot/audio/owner-alert suite: 24 assertions pass.
- Exact production sign statement: the reported 1306.3000000000002 renders as $1306; accumulated 22.049999999999997 renders as $22. Zero, a sub-dollar balance and the two-billion bank cap are also checked. Each underlying fractional balance is unchanged.
- All 315 V83 place objects, references, properties, hierarchy and backups are preserved except the one approved source statement. The other 108 active source files are byte-identical, including every collectible model, catalog, power, profile and purchase module.

These are offline checks with API/storage adapters. No Studio playtest, native UI inspection, published-server saving, product purchase or performance test was performed here. Broader unchanged gameplay evidence remains in the V83 report. Checkout stays off and public launch readiness remains unverified.
