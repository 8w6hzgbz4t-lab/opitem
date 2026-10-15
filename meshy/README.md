# Meshy model generation and Roblox import

This folder contains model-generation code and art briefs for the requested update after version 63. **No Meshy meshes have been generated or imported by this package.** All 33 asset records in `assets.json` start with `status: "not_generated"`; all Roblox model IDs in `MeshyAssets.lua` start at `0`.

The manifest contains 19 collectible records and 14 decoration/component records. Fifteen collectible records request new catalog items. Blue Shell and Dragon Balls retain their known IDs, `item05` and `item43`. P.E.K.K.A and Mega Knight already have art builders, but their catalog IDs were not established by the inspected catalog; check the current game before creating either entry.

## Files

- `assets.json`: 33 stable asset keys, complete generation prompts, detailed art direction, triangle targets, texture targets, dimensions, pivots, known catalog mappings, and reference requirements.
- `generate_models.py`: Python 3 client for Meshy's text-to-3D v2 preview and PBR refine workflow. No third-party Python packages are required.
- `MeshyAssets.lua`: server-owned mapping from stable keys to Roblox Model asset IDs. Zero means not configured.
- `MeshyModelLoader.lua`: loads approved Model IDs and prepares their geometry for the game. It does not generate meshes or call Meshy.
- `FactoryIntegration.lua`: optional visual-only factory hook. It uses configured Meshy imports for existing Blue Shell/Dragon Balls IDs and keeps the current model as a fallback.
- `check_code.py`: runs the offline Python checks and the native Luau loader checks when a Luau CLI is available.

These files do not modify the existing game's catalog, economy, item ownership, powers, or scenery automatically.

## Generate a first model

Run these commands from the extracted project folder in your Mac's terminal:

```bash
python3 meshy/generate_models.py plan
python3 meshy/generate_models.py generate --asset blue_shell --prompt-key
```

`plan` validates the brief list and makes no API requests. `generate` submits Meshy generation work using your account. The second command asks for the Meshy API key with hidden local input. Keep the key in your local terminal; do not paste it into chat or put it in the game files. The client can also read the local environment variable `MESHY_API_KEY`.

The generation client creates a geometry preview, requests PBR refinement, waits for completion, and downloads the available GLB, FBX, and textures into `meshy/output/<asset_key>/`. The root manifest's `not_generated` fields describe the handoff baseline; actual task IDs and download status are tracked separately in each output folder's `state.json`.

Start with one item and inspect the result before submitting the rest. For a selected batch:

```bash
python3 meshy/generate_models.py generate --asset detailed_workbench power_console clash_crown_tower --prompt-key
```

`--all` explicitly selects the entire list. The Squidward painting is blocked until its exact artwork reference is available, so use selected keys while that reference is missing. Do not substitute a guessed meme image.

If a task is still running when the command times out, run the same command again. It resumes saved task IDs. If a submission fails after the request may already have reached Meshy, the client deliberately avoids another automatic submission. Find the existing task ID in Meshy, then resume the single asset with `--resume-preview TASK_ID` or `--resume-refine TASK_ID` as appropriate. Keep the existing output folder and `state.json`.

This package has not been tested against a live Meshy generation account. No API credentials were available in the cloud environment. The client uses the text-to-3D v2 preview/refine contract; it does not assume access to a particular latest Meshy model. If your account rejects a parameter, check its current API documentation before changing the request. Triangle and texture values in the manifest are art targets, not a claim that the API enforces every target exactly.

## Approve the geometry before integration

Every prompt contains the key silhouette and color requirements, fits within 600 characters, and requests no baked lettering. `design_brief` retains the fuller art direction. `negative_prompt` is checklist metadata, not a separate API field.

Inspect each result in Meshy or Blender. Reject plain placeholder geometry, melted faces, incorrect anatomy, floating fragments, paper-thin structures, or muddy colors. Check all sides and the normal gameplay viewing distance. Follow each record's triangle and texture targets; decimate hidden geometry and use normal maps for small grooves.

Check these details explicitly:

- Blue Shell: recognizable cobalt shell, ivory rim, spikes, and both feathered wings.
- Dragon Balls: exactly seven balls, carrying exactly one through seven red stars. Correct star counts with decals or geometry if generation gets them wrong.
- Infinity Stones: six separate meshes with distinct shapes and their correct blue, yellow, red, purple, green, and orange colors.
- Ra and Obelisk: detailed recognizable heads, clear anatomy, correct silhouettes, and visibility above the walls.
- Cards: the artwork remains inside a complete card frame. Keep title bars and rules panels clean for accurate Roblox overlays.
- Clash tower: crown emblem and blue banners remain readable from across the arena.
- Workstations: recognizable benches and consoles with usable open approach space.

The Millennium Puzzle remains the quality reference. This package does not replace its existing design.

## Import into Roblox Studio

1. Import an approved GLB or FBX with Studio's 3D Importer. Verify its textures and PBR maps. Correct the mesh in Blender if required.
2. Normalize its scale and rotation. Roblox uses +Y up and -Z forward. Set the pivot as specified in `assets.json`; most items and buildings need a bottom-center display pivot.
3. Keep card titles, symbols, screen contents, and rules text as Roblox SurfaceGui elements or approved image overlays. AI-baked text is not reliable.
4. Group each approved asset into a Model and upload it under the game's owner or group. Record its numeric **Model asset ID**. This is not a MeshPart's MeshId, a Meshy task ID, or a GLB download URL.
5. Put that Model ID into the corresponding `AssetId` in `MeshyAssets.lua`. Leave unimported assets at zero. Install `MeshyAssets` and `MeshyModelLoader` as sibling ModuleScripts in a server-only folder such as ServerStorage.
6. Call the loader from trusted server code with an existing manifest key. Connect returned models to the existing model factory or decoration builder. Preserve catalog IDs and stats when replacing visuals.
7. Use simple invisible Roblox parts for structural collision. Keep ornate details noncollidable. Test viewing distance, carry visibility, portal/conveyor clearance, roof clearance, and memory usage in Studio.

Changing a model ID does not create a catalog entry. Allocate unique item IDs in the latest game catalog for the requested new collectibles. Resolve any existing P.E.K.K.A and Mega Knight records first to avoid duplicates.

For the existing version 63 factory, put all three Luau modules in `ServerStorage.MeshyModels`, then install the hook before the server builds its model templates:

```lua
local Factory = require(script.Parent.ModelFactory)
local MeshyIntegration = require(game:GetService("ServerStorage").MeshyModels.FactoryIntegration)
MeshyIntegration.install(Factory)
```

The hook changes visuals only. New catalog items need their real allocated IDs mapped through the second argument to `install`. Leave the Millennium Puzzle factory path unchanged.

## Offline code checks

From the extracted project root:

```bash
python3 meshy/check_code.py --luau /path/to/luau
```

The Python checks simulate API responses without submitting tasks. The Luau checks execute the actual loader with Roblox API doubles. They validate task resumption, geometry handling and metadata; they do not validate Meshy's generated appearance, live API compatibility, Roblox asset permissions or Studio rendering.

## Ho-Oh animation requires assembly

Ho-Oh is deliberately split into `hooh_body`, `hooh_wing_left`, `hooh_wing_right`, and `hooh_tail`. Meshy output is not assumed to contain a working bird rig.

Fit the separate wings and tail to the body in Blender or Studio. Keep each shoulder pivot at its attachment socket, with the left wing extending toward -X and the right wing toward +X while the bird faces -Z. The tail extends toward +Z from its root. Check the approved components against the same reference so their proportions and feather colors match. Mirroring an approved wing in Blender may give more consistent results than generating both independently.

Build a real Roblox animation assembly or animate the decorative parts around those pivots. Add a repeating flight path from the open bell pavilion, around the tower, and back. Test wing movement and tail clearance. Do not claim animation is complete merely because separate meshes were generated.

## Reference still required

`squidward_force_of_despair_painting` needs the exact meme artwork requested by the user. No exact reference was supplied. The correct solution is a clean frame and canvas mesh with the approved image applied as a texture. Keep it a painting, without trading-card borders, mana symbols, or rules text. Continue other assets while obtaining this reference.

## Gameplay remains separate

Meshy creates geometry and textures. The requested eight powers and their effects, smaller HUD, spawn weighting, faster conveyor, death-safe stored items, legitimate theft, Infinity Stone level reward, comet celebration, Exodia event, rainbow placement, and scenery cleanup still require game code and Studio validation. The generation briefs do not imply those changes have been implemented.
