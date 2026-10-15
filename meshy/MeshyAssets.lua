-- Server-owned whitelist for Meshy exports imported/uploaded as Roblox Models.
-- Every AssetId is deliberately 0: NOT_CONFIGURED. These are not generated meshes.
-- Replace only 0 with your own uploaded Model asset ID after checking the import.
-- Never put a Meshy API key, GLB URL, or MeshPart MeshId here.
-- No catalog stats are assigned by this file. Add new item IDs through the game catalog.
local Assets = {
    detailed_workbench = {
        Name = "Detailed workbench", AssetId = 0,
        TargetHeight = 6, MaxSpan = 10, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    power_console = {
        Name = "Power selection and upgrade console", AssetId = 0,
        TargetHeight = 6, MaxSpan = 7, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    clash_crown_tower = {
        Name = "Clash Royale crown tower", AssetId = 0,
        TargetHeight = 33, MaxSpan = 14, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    blue_shell = {
        Name = "Mario Kart Blue Shell", AssetId = 0,
        TargetHeight = 3.4, MaxSpan = 4.8, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        ItemId = "item05",
    },
    kirby_sword = {
        Name = "Kirby Sword", AssetId = 0,
        TargetHeight = 5.2, MaxSpan = 2.2, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    golden_spatula = {
        Name = "SpongeBob Golden Spatula", AssetId = 0,
        TargetHeight = 4.7, MaxSpan = 1.8, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    krabby_patty = {
        Name = "Krabby Patty", AssetId = 0,
        TargetHeight = 2.7, MaxSpan = 3.5, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    gary_shell = {
        Name = "Gary Shell", AssetId = 0,
        TargetHeight = 3.2, MaxSpan = 3.4, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    super_star = {
        Name = "Mario Super Star", AssetId = 0,
        TargetHeight = 3.3, MaxSpan = 3.4, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    fire_flower = {
        Name = "Mario Fire Flower", AssetId = 0,
        TargetHeight = 4.0, MaxSpan = 3.1, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    hylian_shield = {
        Name = "Hylian Shield", AssetId = 0,
        TargetHeight = 4.6, MaxSpan = 3.3, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    companion_cube = {
        Name = "Portal Companion Cube", AssetId = 0,
        TargetHeight = 3.2, MaxSpan = 3.2, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    proton_pack = {
        Name = "Ghostbusters Proton Pack", AssetId = 0,
        TargetHeight = 4.6, MaxSpan = 3.4, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    infinity_space = {
        Name = "Space Stone", AssetId = 0,
        TargetHeight = 2.1, MaxSpan = 1.6, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    infinity_mind = {
        Name = "Mind Stone", AssetId = 0,
        TargetHeight = 2.1, MaxSpan = 1.6, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    infinity_reality = {
        Name = "Reality Stone", AssetId = 0,
        TargetHeight = 2.1, MaxSpan = 1.6, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    infinity_power = {
        Name = "Power Stone", AssetId = 0,
        TargetHeight = 2.1, MaxSpan = 1.6, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    infinity_time = {
        Name = "Time Stone", AssetId = 0,
        TargetHeight = 2.1, MaxSpan = 1.6, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    infinity_soul = {
        Name = "Soul Stone", AssetId = 0,
        TargetHeight = 2.1, MaxSpan = 1.6, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Set ItemId only after allocating a unique ID in your current game catalog.
    },
    pekka = {
        Name = "Clash Royale P.E.K.K.A", AssetId = 0,
        TargetHeight = 5.1, MaxSpan = 3.7, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    mega_knight = {
        Name = "Clash Royale Mega Knight", AssetId = 0,
        TargetHeight = 5.1, MaxSpan = 4.2, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    dragon_balls = {
        Name = "Seven Dragon Balls collectible set", AssetId = 0,
        TargetHeight = 2.6, MaxSpan = 4.0, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        ItemId = "item43",
    },
    winged_dragon_ra = {
        Name = "The Winged Dragon of Ra monument", AssetId = 0,
        TargetHeight = 32, MaxSpan = 41, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    obelisk_tormentor = {
        Name = "Obelisk the Tormentor monument", AssetId = 0,
        TargetHeight = 38, MaxSpan = 25, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    mtg_black_lotus_card = {
        Name = "Detailed Magic card decoration", AssetId = 0,
        TargetHeight = 23, MaxSpan = 16, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    mirror_force_card = {
        Name = "Mirror Force card surrounding energy planet", AssetId = 0,
        TargetHeight = 47, MaxSpan = 32, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    squidward_force_of_despair_painting = {
        Name = "Squidward Force of Despair meme painting", AssetId = 0,
        TargetHeight = 16, MaxSpan = 13, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    exodia_spellbinding_circle_chains = {
        Name = "Exodia Spellbinding Circle and chains", AssetId = 0,
        TargetHeight = 40, MaxSpan = 40, PivotMode = "center",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    hooh_bell_tower = {
        Name = "Ho-Oh Bell Tower", AssetId = 0,
        TargetHeight = 42, MaxSpan = 20, PivotMode = "bottom",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
    },
    hooh_body = {
        Name = "Ho-Oh body and head", AssetId = 0,
        TargetHeight = 5.5, MaxSpan = 8.0, PivotMode = "preserve",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Keep the fitted Blender/Studio shoulder or tail origin; loader cannot invent a rig.
    },
    hooh_wing_left = {
        Name = "Ho-Oh left wing", AssetId = 0,
        TargetHeight = 2.0, MaxSpan = 9.0, PivotMode = "preserve",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Keep the fitted Blender/Studio shoulder or tail origin; loader cannot invent a rig.
    },
    hooh_wing_right = {
        Name = "Ho-Oh right wing", AssetId = 0,
        TargetHeight = 2.0, MaxSpan = 9.0, PivotMode = "preserve",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Keep the fitted Blender/Studio shoulder or tail origin; loader cannot invent a rig.
    },
    hooh_tail = {
        Name = "Ho-Oh tail-feather fan", AssetId = 0,
        TargetHeight = 1.0, MaxSpan = 9.0, PivotMode = "preserve",
        Orientation = CFrame.Angles(0, 0, 0), Collidable = false, MaxParts = 600,
        -- Keep the fitted Blender/Studio shoulder or tail origin; loader cannot invent a rig.
    },
}

-- Keep the whitelist immutable while the server is running.
for _, entry in pairs(Assets) do table.freeze(entry) end
return table.freeze(Assets)
