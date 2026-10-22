# V84: clean collection earnings

The earnings sign at each base now shows whole dollars that can actually be collected. For example, an internal balance of `1306.3000000000002` displays **$1306 READY**. Fractional earnings remain in the saved bank and continue accumulating; prices, income rates, rewards and collection rules are unchanged.

Download [Version84_Game.zip](../Version84_Game.zip) for `StealAnOPItem_84_CleanEarnings.rbxlx`, or [Version84_SourceAndGame.zip](../Version84_SourceAndGame.zip) for the game, editable `roblox/v84-game` source and offline evidence. This change has not been tested in Roblox Studio here. It does not establish public launch readiness.

All existing designs, product IDs, music ID, settings and save-store names remain. Robux checkout stays **off**. Nothing is published automatically.

## Update your current Studio file directly

1. Stop Play and save a backup of your current file.
2. In Explorer, open **ServerScriptService → OPItemV2 → Server**.
3. Search for `b.bank.Text='$'..state.bank` and replace this line:

```lua
b.bank.Text='$'..state.bank..' READY\nCOLLECT / DELIVER'
```

with:

```lua
b.bank.Text=string.format('$%.0f READY\nCOLLECT / DELIVER',math.floor(state.bank))
```

4. Save the file, press Play, and check that the base earnings sign has no decimal tail. Collect the money and confirm any remaining fraction continues accumulating.

## Open the complete V84 file

Back up your current Studio file, extract `Version84_Game.zip`, then open `StealAnOPItem_84_CleanEarnings.rbxlx`. Preserve or merge any local edits made after V83. Opening the file does not update Roblox.

If you choose to update the private published game, use **File → Publish to Roblox As…** and select the **existing experience and place**. Keep the same experience to retain its Developer Products and saved stores. Recheck the earnings sign in the published private game; the remaining live saving, multiplayer and purchase checks still apply.

## Artwork API message

If Output says `EditableImage` is not accessible, stop Play and check **File → Experience Settings → Security → Allow Mesh / Image APIs**, if that setting is available to your account. Enable it, save and restart Play. This controls the artwork renderer and is separate from the earnings display; the existing renderer includes a mosaic fallback when the API is unavailable.
