# Important questions before release

The core loop exists: buy/bid, carry, interrupt, steal, deliver, earn, protect and upgrade. The main remaining work is proving that loop with real players and deciding its pacing. Offline code tests cannot answer whether it is fun, fair or reliable on Roblox's actual services/devices.

## Questions to answer in the first private playtest

1. **Can a new player complete the loop without help?** Ask someone who has never seen the game to buy an item, deliver it, collect income and protect the base. Measure time and where they get stuck. A short Help/tutorial exists; its effectiveness is untested.
2. **How fast should progress feel?** Choose targets for the first purchase, first upgrade and level-five second floor. Then time real sessions and adjust prices/income/spawn rates only from evidence. Keep ordinary powers earnable without Robux.
3. **Can one strong player prevent a newcomer from progressing?** Test repeated raids and carrier interruptions. Starting protection exists, but its sufficiency and higher-rank power balance need real-player observation. Paid carry losses remain punishing by the owner's choice; this is not a proposal to add refunds.
4. **Can a player rebuild after a big theft?** Test a nearly empty base, a full base, lost carry and no affordable belt offer. Check for a meaningful recovery path rather than assuming it works because income exists.
5. **Why return tomorrow?** Ask testers what they want to collect or achieve next. The Index, levels and rare collection events already provide goals. Measure whether they motivate a second session before adding more systems.
6. **Do controls and the map work under real pressure?** Test owner Sell/visitor Steal simultaneously, confirmation during theft, both workbenches, all ten powers, eight players, small phones, controllers and slow connections. Observe FPS, camera clipping, stairs, entrance lines and prompt visibility.

## Reliability questions that must be proved

- Does saved cash, bank, inventory/slots, levels, powers, settings and rewards return exactly once after changing servers? What happens during a failed load, a shutdown and a theft transfer? There are production-code recovery tests, but actual Roblox storage tests remain unfinished.
- Which accounts will run the multiplayer test? Use real accounts in a private published experience for durable progress/receipt tests. Studio local clients with negative/synthetic UserIds are rejected by the current strict profile identity validator; separate TEST stores do not add synthetic-account support. That is a known local-test limitation, not a reason to disable saving or relax live identity checks.
- Does every real paid receipt grant and save exactly once, including delayed delivery, disconnects and capped/already-owned rewards? Product IDs exist, but ownership/current prices and live fulfillment still need verification. **Checkout remains off.**
- Is each joining player assigned one unique vault and spawned there? Offline concurrent-join/failed-load tests pass. The local place limit is now8; verify the published Dashboard Maximum Players8 and actual full-server matching separately.
- Does music asset111355988554529 play after approval and experience permission, loop, and obey saved mute/volume settings? Its configured routing passes offline; audible Roblox playback remains unverified.

## Ownership and operations questions

- Do you have the necessary rights and Roblox permissions for the recognizable characters, item names, logos, card artwork, thumbnails and audio used in a public monetized game? AI/procedural creation and a valid asset ID do not establish those rights. Use the existing asset-permission checklist.
- Who is the intended audience, and do the actual experience and listing match the content/maturity information required by Creator Dashboard? Follow the requirements currently shown for the owner's account and experience.
- Where can players report bugs? Decide who reviews reports and how to capture version, device, what happened and reproducible steps without collecting unnecessary personal information.
- How will you detect failed saves, purchase issues, exits during the tutorial and poor mobile performance? An analytics plan exists; live instrumentation/dashboard access and operational alerts have not been verified here.
- Which build is the rollback, and who may publish? Keep the working backup. A rollback after purchases must preserve receipt/product mappings and the saved schema; never roll paid progress back to a session-only server.

## Already chosen — preserve these rules

Lost purchased carries return to their original belt pickup point without refund. Unfinished/losing bids refund. Stored items survive death. Theft remains allowed when protection is open. The trusted safe Exodia respawn has its deliberate recovery exception. Owners have8slots per floor, upstairs unlocks at level5 and levels add5%owner income. Tag stays fixed with at most two optional ordinary powers. Developer privileges are never sold. Updating the same Roblox experience keeps its existing products/stores.

Start with a small private test group. Record expected versus observed outcomes, fix critical failures, then decide whether broader testing is justified. See Version78/LAUNCH_CHECKLIST.md, Version80/PRIVATE_TEST_STEPS.md and Version78/ANALYTICS_PLAN.md in the source download. This build is not yet verified for public launch.
