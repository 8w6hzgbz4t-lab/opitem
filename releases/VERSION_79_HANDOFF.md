# Version 79 terminal handoff

Fetch `codex/version-63-handoff` from `8w6hzgbz4t-lab/opitem` and read `releases/Version79/README.md`. Open `releases/StealAnOPItem_79_ConveyorAndTheftAlerts.rbxlx` in Studio. Keep the V78 backup.

Only five active sources change: Client, PhaseClient, PhaseService, PersistentSession and Server. Ownerless unsold offers now expire safely. InTransit carried items are retained after their holograms leave; the old 50-second carry timeout is removed. Powers/death/disconnect/invalid movement/defender recovery still resolve carries, and lost paid items return to their pickup point with no refund. Owner-only theft banners identify taken/recovered/stolen items. Power text is smaller/lighter.

The new icon/thumbnail and short listing copy are under `releases/Version79/Art` and `GAME_DESCRIPTION.txt`. Use Creator Dashboard to upload/review them. Nothing is automatically published.

Saving, receipt schema, TEST/live store separation, all 76 models/stats and developer authorization are inherited from V78. Product/audio IDs remain unconfigured, checkout stays off and real Studio multiplayer/storage/receipt/device tests are still required before release.
