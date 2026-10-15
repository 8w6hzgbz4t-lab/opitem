# Meshy model code handoff

Download `releases/MeshyModelCode.zip`, or use the `meshy/` folder directly from this branch. This contains generation code, 33 art briefs, a Roblox Model loader, a visual-only factory hook, and offline checks. No new Meshy models have been generated yet.

Paste into terminal Codex:

```text
Fetch the latest codex/version-63-handoff branch from 8w6hzgbz4t-lab/opitem.
Read meshy/README.md. Run python3 meshy/generate_models.py plan.
Use the Meshy generation client to generate the requested models after my Meshy API key is configured securely. Start with blue_shell for review. Never put my key in chat, Lua, or Git.
Import approved GLB/FBX files into Roblox Studio, configure their actual Model asset IDs, and use the provided loader/factory hook to replace visuals while preserving current item IDs and stats.
The Squidward painting needs my exact reference image. Preserve my Millennium Puzzle and existing game files. Do not publish the game.
```

Offline checks passed: 18 Python tests and 153 native Luau loader assertions. Live Meshy generation, generated mesh quality, Roblox imports and asset permissions remain untested. See `meshy/README.md` for complete instructions and the separate gameplay work still required.
