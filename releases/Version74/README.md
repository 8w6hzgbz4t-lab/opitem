# Version 74: developer menu

Open `releases/StealAnOPItem_74_DeveloperMenu.rbxlx` in Roblox Studio and press **Play** while signed in as **Goverment_cheesee**. Once the server verifies your account, use **DEV / F8** to open the menu. On touch devices, use the DEV button.

The server resolves `Goverment_cheesee` through Roblox's `Players:GetUserIdFromNameAsync` at startup, then authorizes only that numeric UserId. The configuration remains in ServerScriptService. Other players receive no developer GUI, and every remote command checks the actual sending player's UserId. There is no Studio, display-name, group-member or client-supplied identity bypass. If Roblox cannot resolve the configured account, access remains locked and the server prints a diagnostic. An explicit positive `DeveloperUserId` in `AdminConfig.lua` can pin access permanently to your account if you later change your username.

The menu has four tabs:

- **Mods:** flight, noclip, ability immunity, heal, return home, speed from 16 to 64, jump power from 50 to 120, and reset mods. Ability immunity blocks other players' powers; world hazards and character resets still apply. Flight uses WASD with Q/E for down/up, with separate touch hold controls.
- **Powers:** unlock all eight powers, clear your power cooldowns, and cast Tag, Dash, Pull, Slow Field, Ground Slam, Knockback Pulse, Force Field Shield and Lightning Strike. Casts use the normal server power system, range, line of sight, windup and cooldown checks. Face your character toward the target. A selected power is equipped into an optional slot when needed; Tag stays fixed.
- **Items:** search the complete current catalog, grant one item to your own base, or spawn a buyable conveyor offer. Grants respect the eight-item base limit.
- **Console:** inspect players and inventory, adjust currency/protection, teleport, announce, kick, and manage bans for the current server session. Destructive commands require confirmation of the exact command. Commands are rate limited and recorded in a bounded server audit log. Bans are not persistent or global.

Developer character mods are disabled during carrying and bid battles and reset on death/respawn or disconnect. Movement overrides restore the original character settings. Return home rejects carried loot and checks for solid geometry. Power unlocks and granted items remain part of the current session; reset mods restores movement/immunity rather than removing items or relocking powers.

This update preserves Version 73's skyline cleanup, animated Slifer, Ra, all other scenery, and all 69 item models, definitions and stats. It updates only the four administration scripts, `Server.lua` and `PhaseService.lua`.

Editable sources are in `roblox/v74-game/`. The full source/game bundle is `releases/Version74_SourceAndGame.zip`. Rebuild the place with `python tools/build_v74_place.py` from the repository root.

Offline checks execute production code with the official Luau CLI and controlled Roblox API doubles. They cover authorization, identity lookup failure, outsider requests, commands, confirmations, movement cleanup, the client controls and all eight powers. Final checks passed: 374 admin assertions with 152 command dispatches, 596 power assertions, 44 client-control assertions, 7,112 catalog/transaction assertions, six existing session groups and thirteen regression groups. Reports are included beside this file. The cloud's external Roblox API lookup was unavailable, so the real username lookup is performed by the Roblox server at startup; a live identity lookup and Studio rendering, physics, performance and multiplayer still require a Studio playtest. Nothing has been published to Roblox.

To reproduce the new checks with the official Luau CLI installed, run:

```bash
python tools/run_admin_checks.py --luau /path/to/luau
python tools/run_power_checks.py --luau /path/to/luau
python tools/run_admin_client_checks.py --luau /path/to/luau
```
