-- Extra collectible designs. Empty costume shells and display models only.
local M = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local pi = math.pi
local METAL, PLASTIC = Enum.Material.Metal, Enum.Material.SmoothPlastic
local BLACK = Color3.fromRGB(23, 22, 24)
local SILVER = Color3.fromRGB(173, 185, 190)
local DARKSTEEL = Color3.fromRGB(64, 73, 79)

local function cylinderY(b, name, p, diameter, height, color, material)
    return b:cylinder(name, V(height, diameter, diameter), C(p) * A(0, 0, pi / 2), color, material)
end

local function cylinderZ(b, name, p, diameter, depth, color, material)
    return b:cylinder(name, V(depth, diameter, diameter), C(p) * A(0, pi / 2, 0), color, material)
end

local function ellipse(b, name, center, rx, ry, thickness, color, segments)
    segments = segments or 16
    for i = 0, segments - 1 do
        local a, c = i * 2 * pi / segments, (i + 1) * 2 * pi / segments
        b:line(name .. i, center + V(math.cos(a) * rx, math.sin(a) * ry, 0),
            center + V(math.cos(c) * rx, math.sin(c) * ry, 0), thickness, thickness, color, PLASTIC)
    end
end

local function dragonballs(b)
    local ORANGE = Color3.fromRGB(245, 137, 30)
    local STAR = Color3.fromRGB(174, 33, 24)
    local GOLD = Color3.fromRGB(205, 145, 48)
    local layout = {
        V(0, 2.45, 0), V(-1.01, 1.48, 0), V(0, 1.48, 0), V(1.01, 1.48, 0),
        V(-1.01, .51, 0), V(0, .51, 0), V(1.01, .51, 0),
    }
    local starLayout = {
        { { 0, 0 } },
        { { -.15, 0 }, { .15, 0 } },
        { { 0, .16 }, { -.16, -.12 }, { .16, -.12 } },
        { { -.15, .15 }, { .15, .15 }, { -.15, -.15 }, { .15, -.15 } },
        { { -.17, .17 }, { .17, .17 }, { 0, 0 }, { -.17, -.17 }, { .17, -.17 } },
        { { -.18, .16 }, { 0, .16 }, { .18, .16 }, { -.18, -.16 }, { 0, -.16 }, { .18, -.16 } },
        { { 0, 0 }, { 0, .22 }, { .19, .11 }, { .19, -.11 }, { 0, -.22 }, { -.19, -.11 }, { -.19, .11 } },
    }
    b:box("DragonBallDisplayBase", V(3.13, .12, 1.02), C(0, .07, .08), Color3.fromRGB(66, 36, 26), PLASTIC)
    b:box("DisplayGoldEdge", V(3.16, .045, 1.05), C(0, .145, .08), GOLD, METAL)
    for number, center in ipairs(layout) do
        local orb = b:ball("DragonBall_" .. number, .86, C(center), ORANGE, Enum.Material.Glass)
        orb.Transparency = .14
        orb.Reflectance = .17
        b:ball("GlassHighlight_" .. number, V(.085, .11, .017), C(center + V(-.18, .23, -.33)), Color3.fromRGB(255, 221, 142), PLASTIC).Transparency = .16
        cylinderY(b, "OrbStand_" .. number, center + V(0, -.46, .035), .54, .075, GOLD)
        -- Every sphere has its exact number of legible five-line stars.
        for starIndex, offset in ipairs(starLayout[number]) do
            local r = number == 1 and .135 or .078
            local points = {}
            for i = 0, 4 do
                local t = -pi / 2 + i * 2 * pi / 5
                points[i + 1] = center + V(offset[1] + math.cos(t) * r, offset[2] + math.sin(t) * r, -.431)
            end
            for i = 1, 5 do
                local other = ((i + 1) % 5) + 1
                b:line("Ball" .. number .. "Star" .. starIndex .. "Stroke" .. i, points[i], points[other], .019, .014, STAR, PLASTIC)
            end
        end
    end
end

local function duelrunner(b)
    local RED = Color3.fromRGB(172, 28, 40)
    local REDLIGHT = Color3.fromRGB(221, 45, 51)
    local RUBBER = Color3.fromRGB(28, 29, 31)
    local BLUE = Color3.fromRGB(58, 192, 226)
    local WHITE = Color3.fromRGB(223, 228, 224)
    local wheels = { { "Front", -1.61 }, { "Rear", 1.61 } }
    for _, data in ipairs(wheels) do
        local name, z = data[1], data[2]
        b:cylinder(name .. "Tire", V(.41, 1.17, 1.17), C(0, .64, z), RUBBER, PLASTIC)
        b:cylinder(name .. "Axle", V(.68, .19, .19), C(0, .64, z), SILVER)
        for _, side in ipairs({ -1, 1 }) do
            local frame = C(side * .225, .64, z) * A(0, pi / 2, 0)
            b:ring(name .. "WheelRim" .. side, frame, .42, .055, SILVER, 12)
            b:cylinder(name .. "WheelHub" .. side, V(.055, .27, .27), C(side * .259, .64, z), DARKSTEEL)
            for i = 0, 5 do
                local t = i * pi / 3
                b:line(name .. "Spoke" .. side .. "_" .. i,
                    V(side * .255, .64, z),
                    V(side * .255, .64 + math.cos(t) * .4, z + math.sin(t) * .4), .035, .045, SILVER)
            end
        end
        for i = 0, 11 do
            local t = i * pi / 6
            b:box(name .. "TireTread" .. i, V(.37, .024, .085),
                C(0, .64 + math.cos(t) * .586, z + math.sin(t) * .586) * A(t, 0, 0), Color3.fromRGB(46, 47, 48), PLASTIC)
        end
    end
    b:box("MainChassis", V(.63, .45, 2.48), C(0, .93, .12), DARKSTEEL)
    b:box("EngineBlock", V(.71, .63, .87), C(0, .82, .37), BLACK)
    b:box("CentralTank", V(.76, .46, 1.2), C(0, 1.45, -.16) * A(-.12, 0, 0), RED)
    b:box("TankSpine", V(.17, .07, 1.04), C(0, 1.72, -.16) * A(-.12, 0, 0), REDLIGHT)
    b:box("RiderSeat", V(.63, .16, .78), C(0, 1.45, .79) * A(.05, 0, 0), BLACK, PLASTIC)
    b:box("SeatBack", V(.65, .25, .24), C(0, 1.56, 1.19) * A(-.22, 0, 0), RED)
    b:wedge("LongFrontNose", V(.58, .48, 1.26), C(0, 1.24, -1.67) * A(0, pi, 0), RED)
    b:box("FrontNoseStripe", V(.13, .045, .8), C(0, 1.485, -1.72), WHITE)
    b:box("FrontTip", V(.39, .16, .31), C(0, 1.02, -2.36), REDLIGHT)
    b:box("Headlight", V(.29, .085, .035), C(0, 1.09, -2.527), BLUE, Enum.Material.Neon)
    b:box("RearTail", V(.58, .28, .75), C(0, 1.44, 1.58) * A(.12, 0, 0), RED)
    b:box("RearBrakeLight", V(.39, .08, .045), C(0, 1.44, 1.98), REDLIGHT, Enum.Material.Neon)
    for _, side in ipairs({ -1, 1 }) do
        b:line("FrontFork" .. side, V(side * .28, .65, -1.61), V(side * .38, 1.47, -.82), .095, .095, SILVER)
        b:line("RearSwingArm" .. side, V(side * .29, .64, 1.61), V(side * .4, .87, .48), .12, .13, DARKSTEEL)
        b:box("FrontFairing" .. side, V(.18, .7, 1.42), C(side * .49, 1.18, -.94) * A(-.13, side * -.12, side * .13), RED)
        b:wedge("SideNoseWing" .. side, V(.13, .43, .9), C(side * .49, 1.02, -1.96) * A(0, pi, 0), REDLIGHT)
        b:box("LowerFairing" .. side, V(.12, .34, 1.34), C(side * .47, .65, -.07) * A(.09, 0, 0), RED)
        b:box("FairingStripe" .. side, V(.025, .09, .91), C(side * .599, 1.29, -.93) * A(-.1, 0, 0), WHITE)
        for i = 1, 5 do
            b:box("EngineVent" .. side .. "_" .. i, V(.035, .27, .048), C(side * .417, .87, -.02 + i * .115), SILVER)
        end
        b:line("ExhaustPipe" .. side, V(side * .4, .68, .65), V(side * .47, .84, 1.54), .13, .13, DARKSTEEL)
        cylinderZ(b, "ExhaustMouth" .. side, V(side * .47, .84, 1.58), .13, .035, BLACK)
        b:line("Handlebar" .. side, V(0, 1.7, -.67), V(side * .55, 1.74, -.59), .075, .075, SILVER)
        b:line("HandleGrip" .. side, V(side * .55, 1.74, -.59), V(side * .68, 1.74, -.46), .11, .11, BLACK, PLASTIC)
        b:line("BrakeLever" .. side, V(side * .55, 1.78, -.63), V(side * .72, 1.78, -.54), .025, .025, SILVER)
        b:box("FootRest" .. side, V(.26, .065, .16), C(side * .54, .49, .56), SILVER)
        b:box("SideDeckSlot" .. side, V(.11, .33, .53), C(side * .47, 1.44, .77), REDLIGHT)
    end
    b:box("Dashboard", V(.49, .12, .27), C(0, 1.74, -.71) * A(.26, 0, 0), DARKSTEEL)
    b:box("DashboardScreen", V(.34, .018, .17), C(0, 1.81, -.72) * A(.26, 0, 0), BLUE, Enum.Material.Neon)
    local windscreen = b:box("Windscreen", V(.53, .42, .04), C(0, 1.77, -.99) * A(.36, 0, 0), Color3.fromRGB(82, 121, 132), Enum.Material.Glass)
    windscreen.Transparency = .48
end

local function emptyBearSuit(b, golden)
    local FUR = golden and Color3.fromRGB(173, 139, 44) or Color3.fromRGB(124, 76, 40)
    local LIGHT = golden and Color3.fromRGB(218, 184, 82) or Color3.fromRGB(177, 126, 76)
    local DARK = golden and Color3.fromRGB(107, 82, 29) or Color3.fromRGB(79, 47, 29)
    local prefix = golden and "GoldenFreddy" or "Freddy"
    local torsoY = golden and 1.3 or 1.93
    local headY = torsoY + .97
    -- Body is a costume shell. There are no humanoids, eyes, or internal machinery.
    b:ball(prefix .. "BackShell", V(1.17, 1.3, .44), C(0, torsoY, .24), FUR, PLASTIC)
    for _, side in ipairs({ -1, 1 }) do
        b:ball(prefix .. "BodySide" .. side, V(.38, 1.12, .66), C(side * .48, torsoY, .03), FUR, PLASTIC)
        b:box(prefix .. "ChestPanel" .. side, V(.42, .77, .11), C(side * .23, torsoY + .04, -.35) * A(0, side * .1, 0), LIGHT, PLASTIC)
        b:line(prefix .. "TorsoSeam" .. side, V(side * .46, torsoY - .4, -.38), V(side * .46, torsoY + .43, -.37), .018, .018, DARK, PLASTIC)
    end
    b:box(prefix .. "BodyLowerRim", V(.86, .13, .57), C(0, torsoY - .57, .02), FUR, PLASTIC)
    cylinderY(b, prefix .. "DarkEmptyNeck", V(0, torsoY + .65, .01), .49, .08, BLACK, PLASTIC)
    b:ring(prefix .. "NeckOpeningRim", C(0, torsoY + .7, .01) * A(pi / 2, 0, 0), .25, .07, FUR, 12, PLASTIC)
    b:ball(prefix .. "ButtonUpper", .11, C(0, torsoY + .19, -.432), BLACK, PLASTIC)
    b:ball(prefix .. "ButtonLower", .11, C(0, torsoY -.1, -.432), BLACK, PLASTIC)
    -- Hollow face: front features surround open sockets. The rear is recessed.
    b:ball(prefix .. "HeadBackShell", V(1.35, 1.18, .54), C(0, headY + .11, .28), FUR, PLASTIC)
    b:box(prefix .. "RecessedHeadInterior", V(1.02, .73, .035), C(0, headY + .05, -.005), BLACK, PLASTIC)
    b:box(prefix .. "Forehead", V(1.19, .25, .38), C(0, headY + .58, -.19), FUR, PLASTIC)
    for _, side in ipairs({ -1, 1 }) do
        b:ball(prefix .. "Temple" .. side, V(.3, .75, .54), C(side * .63, headY + .18, -.14), FUR, PLASTIC)
        ellipse(b, prefix .. "OpenEyeSocket" .. side .. "_", V(side * .32, headY + .28, -.405), .22, .225, .055, DARK, 12)
        b:box(prefix .. "Brow" .. side, V(.4, .075, .1), C(side * .32, headY + .57, -.44) * A(0, 0, side * -.09), BLACK, PLASTIC)
        b:ball(prefix .. "Muzzle" .. side, V(.48, .25, .29), C(side * .225, headY -.055, -.47), LIGHT, PLASTIC)
        b:ball(prefix .. "Ear" .. side, V(.39, .41, .22), C(side * .61, headY + .76, .03), FUR, PLASTIC)
        b:ball(prefix .. "EarInset" .. side, V(.24, .25, .045), C(side * .61, headY + .76, -.105), DARK, PLASTIC)
        for j = 1, 3 do
            b:ball(prefix .. "MuzzleFreckle" .. side .. "_" .. j, .027, C(side * (.13 + j * .06), headY -.065, -.618), DARK, PLASTIC)
        end
    end
    b:ball(prefix .. "Nose", V(.28, .17, .19), C(0, headY + .055, -.625), BLACK, PLASTIC)
    ellipse(b, prefix .. "OpenMouthRim_", V(0, headY -.29, -.38), .46, .16, .08, DARK, 12)
    b:box(prefix .. "LowerJaw", V(.86, .12, .38), C(0, headY -.465, -.2), FUR, PLASTIC)
    for i = 1, 4 do
        b:box(prefix .. "CostumeTooth" .. i, V(.075, .07, .045), C(-.23 + i * .092, headY -.183, -.428), Color3.fromRGB(213, 200, 165), PLASTIC)
    end
    cylinderY(b, prefix .. "HatBrim", V(0, headY + .795, .02), .92, .095, BLACK, PLASTIC)
    cylinderY(b, prefix .. "TopHat", V(0, headY + 1.025, .02), .6, .39, BLACK, PLASTIC)
    cylinderY(b, prefix .. "HatBand", V(0, headY + .89, .02), .618, .075, DARK, PLASTIC)
    b:ball(prefix .. "BowKnot", .15, C(0, torsoY + .48, -.43), BLACK, PLASTIC)
    for _, side in ipairs({ -1, 1 }) do
        b:triangle(prefix .. "BowTie" .. side, V(side * .035, torsoY + .48, -.44),
            V(side * .29, torsoY + .63, -.44), V(side * .29, torsoY + .34, -.44), BLACK, .06, PLASTIC)
        local shoulderY = torsoY + .35
        local elbowY = torsoY -.18
        local handY = torsoY -.71
        b:ball(prefix .. "ShoulderShell" .. side, V(.47, .48, .5), C(side * .77, shoulderY, .02), FUR, PLASTIC)
        b:ball(prefix .. "UpperArmShell" .. side, V(.41, .61, .43), C(side * .85, shoulderY -.32, .01) * A(0, 0, side * .1), FUR, PLASTIC)
        b:ball(prefix .. "ElbowCloth" .. side, .24, C(side * .89, elbowY -.14, .01), DARK, PLASTIC)
        b:ball(prefix .. "ForearmShell" .. side, V(.38, .48, .42), C(side * .91, elbowY -.4, -.02), FUR, PLASTIC)
        b:ball(prefix .. "EmptyGlove" .. side, V(.4, .31, .4), C(side * .92, handY -.25, -.05), FUR, PLASTIC)
        for j = 1, 3 do
            b:line(prefix .. "GloveSeam" .. side .. "_" .. j,
                V(side * (.78 + j * .065), handY -.2, -.245), V(side * (.78 + j * .065), handY -.31, -.23), .014, .014, DARK, PLASTIC)
        end
        if golden then
            b:ball(prefix .. "SeatedUpperLeg" .. side, V(.46, .47, .76), C(side * .3, .64, -.23), FUR, PLASTIC)
            b:ball(prefix .. "SeatedLowerLeg" .. side, V(.43, .36, .54), C(side * .34, .34, -.64), FUR, PLASTIC)
            b:ball(prefix .. "SeatedFoot" .. side, V(.53, .26, .71), C(side * .35, .2, -.92), LIGHT, PLASTIC)
        else
            b:ball(prefix .. "UpperLegShell" .. side, V(.45, .64, .47), C(side * .29, 1.06, .01), FUR, PLASTIC)
            b:ball(prefix .. "KneeCloth" .. side, .24, C(side * .29, .76, .01), DARK, PLASTIC)
            b:ball(prefix .. "LowerLegShell" .. side, V(.42, .55, .46), C(side * .29, .48, .01), FUR, PLASTIC)
            b:ball(prefix .. "EmptyFoot" .. side, V(.55, .28, .76), C(side * .29, .17, -.19), LIGHT, PLASTIC)
        end
    end
    b.model:SetAttribute("EmptyCostume", true)
    b.model:SetAttribute("ContainsCharacter", false)
end

local builders = {
    dragonballs = dragonballs,
    duelrunner = duelrunner,
    freddysuit = function(b) emptyBearSuit(b, false) end,
    goldenfreddysuit = function(b) emptyBearSuit(b, true) end,
}

function M.build(b, key)
    local build = builders[key]
    if not build then return false end
    build(b)
    return true
end

return M
