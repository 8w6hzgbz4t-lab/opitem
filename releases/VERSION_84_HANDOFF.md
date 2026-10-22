# V84 handoff: clean collection earnings

V84 fixes the long decimal tails on base collection signs. The displayed amount is the whole-dollar amount available to collect. Fractional earnings remain in the bank and keep accumulating.

- [Studio game ZIP](Version84_Game.zip): `StealAnOPItem_84_CleanEarnings.rbxlx`.
- [Game and editable source ZIP](Version84_SourceAndGame.zip): source folder `roblox/v84-game` and offline verification evidence.
- [Instructions and exact one-line Studio replacement](Version84/README.md).

Only the `Server.lua` bank-sign formatting changes. All existing designs, economy rules, save-store names, settings, product IDs and configured audio remain. Robux checkout stays **off**. No Roblox publication or Studio playtest was performed here.

To keep your current Studio file and local edits: stop Play, save a backup, open **ServerScriptService → OPItemV2 → Server**, and replace:

```lua
b.bank.Text='$'..state.bank..' READY\nCOLLECT / DELIVER'
```

with:

```lua
b.bank.Text=string.format('$%.0f READY\nCOLLECT / DELIVER',math.floor(state.bank))
```

Alternatively, back up your file, extract the game ZIP and open V84. If you choose to update Roblox, use **Publish to Roblox As… → existing experience → existing place**. Opening or saving the local file alone does not update Roblox. Complete the remaining private release checks before public access or checkout.
