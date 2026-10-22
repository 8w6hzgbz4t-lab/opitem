-- Detailed, asset-free collectible figures. Front faces negative Z.
-- This module creates visuals only; catalog values and gameplay stay elsewhere.
local M = {}
local V = Vector3.new
local C = CFrame.new
local R = CFrame.Angles
local PI = math.pi
local METAL = Enum.Material.Metal
local SMOOTH = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local GOLD = Color3.fromRGB(215, 161, 48)
local GOLD_LIGHT = Color3.fromRGB(255, 219, 116)
local GOLD_DARK = Color3.fromRGB(129, 83, 25)
local BLACK = Color3.fromRGB(24, 27, 35)
local STEEL = Color3.fromRGB(101, 112, 128)
local SILVER = Color3.fromRGB(188, 205, 218)
local WHITE = Color3.fromRGB(237, 238, 242)
local RED = Color3.fromRGB(172, 30, 39)
local BLUE = Color3.fromRGB(66, 199, 255)
local PURPLE = Color3.fromRGB(135, 60, 214)
local GREEN = Color3.fromRGB(46, 204, 128)

local function box(b, name, x, y, z, sx, sy, sz, color, angles, material)
    return b:box(name, V(sx, sy, sz), C(x, y, z) * (angles or C()), color, material or METAL)
end

local function ball(b, name, x, y, z, sx, sy, sz, color, material)
    return b:ball(name, V(sx, sy, sz), C(x, y, z), color, material or METAL)
end

local function disk(b, name, x, y, z, diameter, thickness, color, axis, material)
    local rotation = axis == "Z" and R(0, PI / 2, 0) or R(0, 0, PI / 2)
    return b:cylinder(name, V(thickness, diameter, diameter), C(x, y, z) * rotation, color, material or METAL)
end

local function line(b, name, a, c, width, color, material)
    return b:line(name, a, c, width, width, color, material or METAL)
end

local function gem(b, name, x, y, z, radius, depth, color)
    -- A bevelled six-sided gemstone, assembled from actual triangular faces.
    local center = V(x, y, z - depth)
    local edges = {}
    for i = 0, 5 do
        local angle = i * PI / 3
        edges[i + 1] = V(x + math.cos(angle) * radius, y + math.sin(angle) * radius, z)
    end
    for i = 1, 6 do
        local tone = i % 2 == 0 and color or color:Lerp(WHITE, .28)
        b:triangle(name .. "Facet_" .. i, center, edges[i], edges[i % 6 + 1], tone, .025, METAL)
    end
end

local function rivets(b, name, x, y, z, width, height, color)
    for _, side in ipairs({-1, 1}) do
        for _, vertical in ipairs({-1, 1}) do
            ball(b, name .. side .. "_" .. vertical, x + side * width / 2,
                y + vertical * height / 2, z, .065, .065, .065, color)
        end
    end
end

local function armorBody(b, name, body, trim, width)
    width = width or 1
    local function bx(label, x, y, z, sx, sy, sz, color, angles)
        return box(b, name .. label, x * width, y, z, sx * width, sy, sz, color, angles)
    end
    bx("TorsoCore", 0, 2.48, .03, 1.08, 1.13, .61, BLACK)
    bx("ChestPlate", 0, 2.65, -.29, .94, .72, .14, body)
    bx("UpperChest", 0, 3.00, -.20, 1.13, .20, .42, trim)
    bx("BackPlate", 0, 2.62, .35, 1.01, .87, .14, body)
    bx("Waist", 0, 1.98, 0, .80, .27, .57, BLACK)
    bx("Belt", 0, 2.04, -.29, .89, .15, .14, trim)
    bx("Buckle", 0, 2.04, -.39, .23, .22, .10, GOLD)
    for row = 0, 2 do
        bx("AbdominalPlate_" .. row, 0, 2.32 - row * .15, -.34, .65 - row * .07,
            .12, .15, row % 2 == 0 and body or trim)
    end
    for _, s in ipairs({-1, 1}) do
        local tag = s == -1 and "Left" or "Right"
        local x = .34 * s
        ball(b, name .. tag .. "Hip", x * width, 1.79, .02, .38, .38, .38, BLACK)
        bx(tag .. "ThighCore", x, 1.49, .02, .36, .69, .38, BLACK)
        bx(tag .. "ThighPlate", x, 1.48, -.20, .36, .54, .15, body, R(0, 0, -.04 * s))
        bx(tag .. "ThighEdge", x + .17 * s, 1.48, -.16, .06, .48, .15, trim)
        ball(b, name .. tag .. "KneeJoint", x * width, 1.08, .02, .33, .33, .33, BLACK)
        bx(tag .. "Kneecap", x, 1.08, -.25, .40, .26, .19, trim)
        bx(tag .. "ShinCore", x, .68, .02, .34, .65, .36, BLACK)
        bx(tag .. "Greave", x, .68, -.20, .34, .54, .16, body)
        bx(tag .. "ShinStripe", x, .68, -.30, .09, .45, .04, trim)
        bx(tag .. "Boot", x, .22, -.12, .47, .34, .71, body)
        bx(tag .. "ToeCap", x, .22, -.44, .46, .20, .14, trim)
        bx(tag .. "Sole", x, .065, -.12, .48, .09, .73, BLACK)
        ball(b, name .. tag .. "ShoulderJoint", .73 * s * width, 2.88, 0,
            .42, .42, .42, BLACK)
        bx(tag .. "ShoulderPlate", .76 * s, 2.98, -.03, .56, .40, .68, body, R(0, 0, -.13 * s))
        bx(tag .. "ShoulderTrim", .76 * s, 3.12, -.15, .50, .09, .45, trim, R(0, 0, -.13 * s))
        bx(tag .. "UpperArm", .84 * s, 2.54, 0, .33, .50, .36, body, R(0, 0, .08 * s))
        ball(b, name .. tag .. "Elbow", .86 * s * width, 2.23, -.02, .28, .28, .28, BLACK)
        bx(tag .. "Forearm", .89 * s, 1.99, -.04, .39, .44, .43, body)
        bx(tag .. "WristBand", .89 * s, 1.79, -.04, .43, .11, .46, trim)
        bx(tag .. "Hand", .90 * s, 1.59, -.08, .34, .29, .37, body)
        for i = 0, 2 do
            bx(tag .. "Knuckle_" .. i, .90 * s - .095 + i * .095, 1.62, -.285,
                .075, .15, .06, trim)
        end
    end
    disk(b, name .. "Neck", 0, 3.15, 0, .35, .25, BLACK, "Y")
end

local function pokeball(b, master)
    local radius, centerY, courses = 1.50, 1.54, 32
    local top = master and PURPLE or Color3.fromRGB(226, 42, 49)
    -- Separate hemisphere slices keep the two colors without borrowed meshes.
    for half = -1, 1, 2 do
        for i = 0, courses - 1 do
            local h = radius * (i + .5) / courses
            local r = math.sqrt(radius * radius - h * h)
            disk(b, (half == 1 and "Crown_" or "WhiteLower_") .. i, 0,
                centerY + half * h, 0, 2 * r, radius / courses + .009,
                half == 1 and top or WHITE, "Y", SMOOTH)
        end
    end
    disk(b, "BlackEquator", 0, centerY, 0, radius * 2 + .018, .13, BLACK, "Y", SMOOTH)
    disk(b, "FrontButtonSocket", 0, centerY, -1.485, .77, .16, BLACK, "Z", SMOOTH)
    disk(b, "FrontButtonSilverRim", 0, centerY, -1.583, .56, .10, SILVER, "Z")
    disk(b, "FrontButton", 0, centerY, -1.65, .42, .055, WHITE, "Z", SMOOTH)
    b:ring("ButtonFineRim", C(0, centerY, -1.69), .217, .025, BLACK, 16, SMOOTH)
    if master then
        local pink = Color3.fromRGB(244, 96, 179)
        for _, s in ipairs({-1, 1}) do
            ball(b, "PinkCrownSpot_" .. s, s * 1.04, centerY + .77, -.50,
                .65, .47, .68, pink, SMOOTH)
            ball(b, "SpotHighlight_" .. s, s * 1.07, centerY + .89, -.66,
                .21, .12, .15, Color3.fromRGB(255, 167, 219), SMOOTH)
        end
        local function surface(x, y)
            local relativeY = y - centerY
            local z = -math.sqrt(math.max(.1, radius * radius - x * x - relativeY * relativeY)) - .055
            return V(x, y, z)
        end
        local letters = {{-.41, 2.16}, {-.41, 2.64}, {0, 2.31}, {.41, 2.64}, {.41, 2.16}}
        for i = 1, #letters - 1 do
            -- Follow the shell curvature so the letter never cuts through it.
            for step = 0, 5 do
                local a, c = step / 6, (step + 1) / 6
                local x1, y1 = letters[i][1], letters[i][2]
                local x2, y2 = letters[i + 1][1], letters[i + 1][2]
                line(b, "EmbossedM_" .. i .. "_" .. step,
                    surface(x1 + (x2 - x1) * a, y1 + (y2 - y1) * a),
                    surface(x1 + (x2 - x1) * c, y1 + (y2 - y1) * c),
                    .095, WHITE, SMOOTH)
            end
        end
    else
        for _, s in ipairs({-1, 1}) do
            line(b, "TopPanelSeam_" .. s, V(s * .70, 2.36, -.99), V(s * .84, 2.14, -1.08),
                .025, Color3.fromRGB(143, 26, 35), SMOOTH)
            ball(b, "ShellFastener_" .. s, s * 1.10, centerY, -.98, .09, .09, .09, SILVER)
        end
    end
end

local function evolutionStone(b, style)
    local ringA, ringB, ringC = {}, {}, {}
    local bottom = V(0, .10, 0)
    local top = V(.05, 3.88, .02)
    for i = 0, 5 do
        local angle = i * PI / 3 + PI / 6
        ringA[i + 1] = V(math.cos(angle) * .67, .77, math.sin(angle) * .50)
        ringB[i + 1] = V(math.cos(angle) * 1.02, 1.99, math.sin(angle) * .72)
        ringC[i + 1] = V(math.cos(angle) * .61, 3.22, math.sin(angle) * .45)
    end
    local shades = {Color3.fromRGB(34, 119, 69), Color3.fromRGB(61, 199, 106),
        Color3.fromRGB(118, 236, 148), Color3.fromRGB(26, 153, 89),
        Color3.fromRGB(49, 179, 96), Color3.fromRGB(92, 212, 137)}
    if style == "fire" then
        shades = {Color3.fromRGB(160, 43, 19), Color3.fromRGB(233, 98, 31),
            Color3.fromRGB(255, 180, 62), Color3.fromRGB(190, 65, 22),
            Color3.fromRGB(243, 127, 34), Color3.fromRGB(255, 211, 104)}
    elseif style == "water" then
        shades = {Color3.fromRGB(20, 88, 154), Color3.fromRGB(48, 161, 212),
            Color3.fromRGB(143, 238, 247), Color3.fromRGB(27, 126, 190),
            Color3.fromRGB(61, 193, 222), Color3.fromRGB(111, 217, 242)}
    end
    for i = 1, 6 do
        local j = i % 6 + 1
        b:triangle("LowerPoint_" .. i, bottom, ringA[i], ringA[j], shades[i], .04, SMOOTH)
        b:triangle("LowerFacetA_" .. i, ringA[i], ringB[i], ringB[j], shades[i], .04, SMOOTH)
        b:triangle("LowerFacetB_" .. i, ringA[i], ringB[j], ringA[j], shades[j], .04, SMOOTH)
        b:triangle("UpperFacetA_" .. i, ringB[i], ringC[i], ringC[j], shades[j], .04, SMOOTH)
        b:triangle("UpperFacetB_" .. i, ringB[i], ringC[j], ringB[j], shades[i], .04, SMOOTH)
        b:triangle("UpperPoint_" .. i, ringC[i], top, ringC[j], shades[i], .04, SMOOTH)
    end
    if style == "fire" then
        local yellow = Color3.fromRGB(255, 230, 135)
        b:triangle("FlameLeft", V(-.40, 1.48, -.78), V(.12, 1.39, -.78),
            V(-.28, 2.65, -.70), yellow, .06, SMOOTH)
        b:triangle("FlameRight", V(-.10, 1.39, -.79), V(.41, 1.56, -.78),
            V(.32, 2.30, -.75), yellow, .06, SMOOTH)
        b:triangle("FlameCore", V(-.23, 1.45, -.84), V(.20, 1.44, -.84),
            V(.08, 2.37, -.82), Color3.fromRGB(255, 158, 33), .04, SMOOTH)
        for i = 0, 5 do
            line(b, "FireCrack_" .. i, V(-.42 + (i % 2) * .80, 1.0 + i * .32, -.65),
                V(-.26 + (i % 2) * .49, 1.19 + i * .30, -.77), .03, yellow, SMOOTH)
        end
    elseif style == "water" then
        local ice = Color3.fromRGB(210, 255, 255)
        ball(b, "DropBase", 0, 1.80, -.77, .61, .73, .075, ice, SMOOTH)
        b:triangle("DropTip", V(-.27, 1.98, -.81), V(.27, 1.98, -.81),
            V(0, 2.74, -.69), ice, .04, SMOOTH)
        for i = 0, 5 do
            local x = -.62 + i * .24
            line(b, "WaterRipple_" .. i, V(x, 1.20 + math.sin(i) * .05, -.66),
                V(x + .20, 1.20 + math.sin(i + 1) * .05, -.66), .035, ice, SMOOTH)
        end
    else
        local vein = Color3.fromRGB(189, 246, 126)
        -- A lightning-shaped yellow vein identifies the Thunder Stone.
        local points = {V(.11, 3.05, -.58), V(-.26, 2.27, -.77),
            V(.16, 2.27, -.77), V(-.13, 1.36, -.67)}
        for i = 1, #points - 1 do
            line(b, "ThunderVein_" .. i, points[i], points[i + 1], .095, vein, SMOOTH)
        end
        for i = 0, 3 do
            local y = 1.30 + .39 * i
            for _, s in ipairs({-1, 1}) do
                line(b, "CrystalVein_" .. i .. "_" .. s, V(.02, y, -.75),
                    V(.40 * s, y + .23, -.65), .025, vein, SMOOTH)
            end
        end
    end
end

local function legendFeather(b)
    local colors = {Color3.fromRGB(247, 78, 77), Color3.fromRGB(255, 145, 49),
        Color3.fromRGB(254, 220, 78), Color3.fromRGB(104, 217, 132),
        Color3.fromRGB(57, 196, 224), Color3.fromRGB(93, 115, 234),
        Color3.fromRGB(185, 107, 237)}
    line(b, "GoldenQuill", V(0, .10, .02), V(0, 3.98, .02), .085, GOLD_LIGHT)
    line(b, "QuillSpine", V(0, .49, -.045), V(0, 3.91, -.045), .036, GOLD)
    for row = 0, 14 do
        local t = row / 14
        local y = .68 + t * 3.13
        local width = .96 * math.sin((.10 + t * .87) * PI)
        local color = colors[math.min(7, math.floor(t * 7) + 1)]
        for _, side in ipairs({-1, 1}) do
            local base = V(side * .025, y - .13, -.015)
            local root = V(side * .025, y + .10, -.015)
            local tip = V(side * width, y + .23, .025)
            local lowerTip = V(side * width * .90, y + .10, .02)
            b:triangle("FeatherBarbUpper_" .. side .. "_" .. row,
                base, root, tip, color, .045, SMOOTH)
            b:triangle("FeatherBarbLower_" .. side .. "_" .. row,
                base, tip, lowerTip, color:Lerp(WHITE, .15), .045, SMOOTH)
            line(b, "FeatherRib_" .. side .. "_" .. row, root, tip, .018,
                color:Lerp(GOLD_LIGHT, .35), SMOOTH)
        end
    end
    for i = 0, 4 do
        disk(b, "QuillWrap_" .. i, 0, .16 + i * .073, .02, .14, .037, GOLD, "Y")
    end
end

local function missingno(b)
    local pixel = .23
    local grays = {WHITE, Color3.fromRGB(151, 154, 163), BLACK, Color3.fromRGB(81, 84, 94)}
    for row = 0, 16 do
        for col = 0, 9 do
            -- The upper-right void preserves the familiar broken column shape.
            if col < 5 or row < 7 then
                local code = (row * 13 + col * 7 + row * col) % 17
                local color = grays[(row + col * 2) % 4 + 1]
                if code == 0 or code == 3 then color = Color3.fromRGB(218, 54, 63) end
                if code == 11 then color = Color3.fromRGB(68, 176, 204) end
                local depth = code % 3 == 0 and .30 or .19
                box(b, "GlitchPixel_" .. row .. "_" .. col, (col - 4.5) * pixel,
                    .20 + row * pixel, ((col + row) % 3 - 1) * .035,
                    pixel * .96, pixel * .96, depth, color, nil, SMOOTH)
            end
        end
    end
    for i = 0, 8 do
        local side = i % 2 == 0 and -1 or 1
        box(b, "DetachedPixel_" .. i, side * (1.34 + (i % 3) * .11),
            .49 + i * .38, -.04, .13, .13, .13,
            i % 3 == 0 and RED or WHITE, nil, SMOOTH)
    end
end

local function ironman(b)
    armorBody(b, "Iron", RED, GOLD, 1)
    box(b, "HelmetShell", 0, 3.59, 0, .75, .86, .73, RED)
    box(b, "HelmetGoldFaceplate", 0, 3.60, -.386, .57, .61, .09, GOLD)
    box(b, "HelmetForehead", 0, 3.90, -.37, .46, .18, .10, GOLD_LIGHT, R(.18, 0, 0))
    box(b, "HelmetChin", 0, 3.29, -.39, .43, .13, .12, GOLD_DARK, R(-.17, 0, 0))
    box(b, "MouthSlot", 0, 3.40, -.45, .26, .032, .028, BLACK)
    for _, s in ipairs({-1, 1}) do
        box(b, "HelmetEyeSocket_" .. s, s * .16, 3.64, -.445, .24, .086, .035,
            BLACK, R(0, 0, -.10 * s))
        box(b, "HelmetEye_" .. s, s * .16, 3.65, -.47, .19, .040, .02,
            BLUE, R(0, 0, -.10 * s), NEON)
        box(b, "HelmetCheek_" .. s, s * .25, 3.46, -.40, .10, .25, .12,
            GOLD_LIGHT, R(0, 0, -.15 * s))
        disk(b, "HelmetEar_" .. s, s * .40, 3.60, 0, .28, .10, GOLD, "Z")
        box(b, "ChestWing_" .. s, s * .34, 2.77, -.39, .37, .22, .095,
            GOLD, R(0, 0, -.17 * s))
        box(b, "GoldBicep_" .. s, s * .84, 2.49, -.20, .16, .33, .055, GOLD)
        disk(b, "PalmRepulsor_" .. s, s * .90, 1.57, -.31, .15, .045, BLUE, "Z", NEON)
        box(b, "CalfGoldPanel_" .. s, s * .34, .69, .22, .22, .45, .055, GOLD)
        rivets(b, "ShoulderRivet_" .. s, s * .76, 2.99, -.39, .35, .18, GOLD_LIGHT)
    end
    disk(b, "ReactorSocket", 0, 2.66, -.405, .43, .10, BLACK, "Z")
    disk(b, "ReactorRing", 0, 2.66, -.469, .35, .05, SILVER, "Z")
    disk(b, "ArcReactor", 0, 2.66, -.506, .26, .03, BLUE, "Z", NEON)
    for i = 0, 5 do
        local a = i * PI / 3
        ball(b, "ReactorBolt_" .. i, math.cos(a) * .174, 2.66 + math.sin(a) * .174,
            -.51, .035, .035, .035, GOLD_LIGHT)
    end
end

local function megaknight(b)
    local darkArmor = Color3.fromRGB(45, 49, 57)
    armorBody(b, "Knight", darkArmor, STEEL, 1.27)
    box(b, "ClosedHelmet", 0, 3.64, .015, 1.00, .91, .86, darkArmor)
    box(b, "HelmetBrow", 0, 3.82, -.46, 1.06, .18, .19, STEEL)
    box(b, "DarkVisor", 0, 3.63, -.463, .75, .22, .035, BLACK)
    box(b, "GoldenVisorSlit", 0, 3.64, -.49, .62, .055, .023, GOLD_LIGHT)
    box(b, "HelmetJaw", 0, 3.36, -.45, .78, .18, .17, STEEL)
    for i = -1, 1 do
        box(b, "FaceVent_" .. i, i * .16, 3.43, -.546, .055, .13, .018, BLACK)
    end
    box(b, "HelmetCentralRidge", 0, 3.98, .01, .16, .20, .77, STEEL)
    for _, s in ipairs({-1, 1}) do
        box(b, "HeavyShoulder_" .. s, s * 1.04, 3.02, .03, .89, .52, .91,
            darkArmor, R(0, 0, -.10 * s))
        box(b, "ShoulderFrontRim_" .. s, s * 1.04, 2.97, -.45, .80, .14, .09, STEEL)
        box(b, "HeavyGauntlet_" .. s, s * 1.15, 1.82, -.13, .70, .63, .72, darkArmor)
        box(b, "GauntletRim_" .. s, s * 1.15, 2.11, -.13, .74, .13, .77, STEEL)
        for i = 0, 2 do
            local x = s * 1.04 + (i - 1) * .24
            b:triangle("ShoulderGoldSpike_" .. s .. "_" .. i,
                V(x - .09, 3.28, -.03), V(x + .09, 3.28, -.03),
                V(x + s * .10, 3.64 + (i == 1 and .10 or 0), -.05), GOLD, .18)
            box(b, "HeavyKnuckle_" .. s .. "_" .. i,
                s * 1.15 + (i - 1) * .19, 1.69, -.52, .15, .23, .16, STEEL)
        end
        for i = 0, 2 do
            ball(b, "HelmetRivet_" .. s .. "_" .. i, s * .42, 3.42 + i * .19,
                -.49, .065, .065, .065, GOLD)
        end
        rivets(b, "ChestRivet_" .. s, s * .39, 2.70, -.39, .19, .42, SILVER)
    end
    box(b, "ChestCrownBand", 0, 2.68, -.40, .50, .12, .09, GOLD)
    for i = -1, 1 do
        b:triangle("ChestCrownPoint_" .. i,
            V(i * .17 - .08, 2.74, -.46), V(i * .17 + .08, 2.74, -.46),
            V(i * .17, 2.96, -.46), GOLD_LIGHT, .045)
    end
end

local function pekka(b)
    local armor = Color3.fromRGB(88, 101, 133)
    local lavender = Color3.fromRGB(192, 136, 239)
    armorBody(b, "Pekka", armor, SILVER, 1.14)
    box(b, "HornedHelmet", 0, 3.65, .04, .87, .91, .86, armor)
    box(b, "HelmetFrontPlate", 0, 3.58, -.43, .77, .61, .17, STEEL)
    box(b, "HelmetRidge", 0, 3.89, -.11, .18, .35, .70, SILVER)
    box(b, "VisorSocket", 0, 3.65, -.529, .69, .15, .035, BLACK)
    for _, s in ipairs({-1, 1}) do
        box(b, "BlueEye_" .. s, s * .21, 3.65, -.552, .22, .08, .025, BLUE, nil, NEON)
        box(b, "HelmetCheekGuard_" .. s, s * .34, 3.40, -.45, .16, .31, .19, SILVER,
            R(0, 0, -.18 * s))
        line(b, "HornBase_" .. s, V(s * .36, 3.90, 0), V(s * .70, 4.16, .015), .24, PURPLE)
        line(b, "HornCurve_" .. s, V(s * .70, 4.16, .015), V(s * .83, 4.45, -.01), .18, PURPLE)
        line(b, "HornTip_" .. s, V(s * .83, 4.45, -.01), V(s * .71, 4.65, -.07), .10, lavender)
        box(b, "PurpleShoulderInset_" .. s, s * .86, 3.03, -.37, .33, .20, .065, PURPLE)
        box(b, "WaistSkirt_" .. s, s * .32, 1.91, -.40, .40, .34, .11, armor,
            R(0, 0, -.10 * s))
        rivets(b, "PekkaShoulderBolt_" .. s, s * .86, 2.98, -.44, .32, .19, SILVER)
        box(b, "PurpleGreaveInset_" .. s, s * .39, .69, -.31, .10, .31, .045, PURPLE)
    end
    for i = -1, 1 do
        box(b, "HelmetMouthVent_" .. i, i * .13, 3.40, -.54, .055, .12, .025, BLACK)
    end
    gem(b, "ChestGem", 0, 2.70, -.405, .17, .10, PURPLE)
    -- Compact upright sword beside the right hand, with an actual angular tip.
    local swordX = 1.36
    box(b, "SwordGrip", swordX, 1.58, -.17, .16, .45, .18, BLACK)
    disk(b, "SwordPommel", swordX, 1.30, -.17, .24, .12, GOLD, "Y")
    box(b, "SwordGuard", swordX, 1.83, -.17, .69, .13, .22, SILVER)
    box(b, "SwordBladeCore", swordX, 2.61, -.17, .38, 1.45, .13, STEEL)
    box(b, "SwordBladeFront", swordX - .06, 2.61, -.253, .15, 1.43, .035, SILVER)
    b:triangle("SwordPoint", V(swordX - .19, 3.33, -.18), V(swordX + .19, 3.33, -.18),
        V(swordX, 3.69, -.18), SILVER, .12)
    for i = 0, 4 do
        box(b, "SwordGripWrap_" .. i, swordX, 1.41 + i * .075, -.17, .18, .035, .20, PURPLE)
    end
end

local function brolyJewelry(b)
    local necklaceY = 2.58
    local count = 24
    for i = 0, count - 1 do
        local a, c = i * PI * 2 / count, (i + 1) * PI * 2 / count
        local va = V(math.cos(a) * 1.07, necklaceY + math.sin(a) * 1.12, .08)
        local vc = V(math.cos(c) * 1.07, necklaceY + math.sin(c) * 1.12, .08)
        line(b, "NecklaceLink_" .. i, va, vc, .14, i % 2 == 0 and GOLD or GOLD_LIGHT)
        ball(b, "NecklaceJoint_" .. i, va.X, va.Y, va.Z, .19, .19, .19, GOLD)
    end
    box(b, "PendantMount", 0, 1.40, -.04, .28, .20, .19, GOLD_DARK)
    disk(b, "PendantGoldSetting", 0, 1.03, -.04, .96, .15, GOLD_LIGHT, "Z")
    gem(b, "PendantGreenGem", 0, 1.03, -.14, .35, .20, GREEN)
    for _, s in ipairs({-1, 1}) do
        local x = 1.32 * s
        b:ring("BraceletOuter_" .. s, C(x, .60, 0), .42, .12, GOLD, 16)
        b:ring("BraceletInner_" .. s, C(x, .60, -.15), .35, .075, GOLD_LIGHT, 16)
        gem(b, "BraceletGem_" .. s, x, .60, -.24, .17, .09, GREEN)
    end
end

local function exodiaHead(b)
    local blue = Color3.fromRGB(38, 63, 111)
    box(b, "TorsoCore", 0, .83, .05, 1.35, 1.29, .73, GOLD_DARK)
    box(b, "ChestPlate", 0, 1.00, -.37, 1.42, .83, .18, GOLD)
    box(b, "LowerTorsoPlate", 0, .37, -.33, 1.08, .30, .19, GOLD)
    for _, s in ipairs({-1, 1}) do
        ball(b, "ShoulderMass_" .. s, s * .89, 1.15, .01, .95, .89, .88, GOLD)
        box(b, "ShoulderTrim_" .. s, s * .91, 1.33, -.34, .72, .17, .22, GOLD_LIGHT,
            R(0, 0, -.13 * s))
        box(b, "ChestWing_" .. s, s * .47, 1.15, -.49, .49, .21, .10, GOLD_LIGHT,
            R(0, 0, -.12 * s))
        for i = 0, 3 do
            box(b, "CollarStripe_" .. s .. "_" .. i, s * (.24 + .16 * i),
                1.62 - .065 * i, -.39, .10, .16, .17, i % 2 == 0 and blue or GOLD_LIGHT,
                R(0, 0, -.24 * s))
        end
    end
    disk(b, "Neck", 0, 1.63, 0, .57, .35, GOLD_DARK, "Y")
    ball(b, "HeadMass", 0, 2.44, .01, 1.15, 1.48, .95, GOLD)
    box(b, "FaceFoundation", 0, 2.44, -.44, .89, 1.06, .15, GOLD)
    box(b, "ForeheadPlate", 0, 2.92, -.48, .89, .24, .19, GOLD_LIGHT)
    box(b, "NoseBridge", 0, 2.50, -.57, .14, .33, .20, GOLD_LIGHT)
    b:triangle("NoseTip", V(-.15, 2.34, -.58), V(.15, 2.34, -.58),
        V(0, 2.49, -.85), GOLD, .085)
    for _, s in ipairs({-1, 1}) do
        box(b, "EyeSocket_" .. s, s * .26, 2.63, -.55, .31, .17, .075, GOLD_DARK,
            R(0, 0, -.08 * s))
        box(b, "EyeWhite_" .. s, s * .26, 2.635, -.593, .23, .085, .023, GOLD_LIGHT)
        ball(b, "EyeIris_" .. s, s * .24, 2.635, -.616, .069, .075, .028, GREEN)
        box(b, "EyePupil_" .. s, s * .24, 2.635, -.635, .025, .056, .012, BLACK)
        line(b, "HeavyBrow_" .. s, V(s * .10, 2.76, -.63), V(s * .43, 2.81, -.57),
            .085, GOLD_DARK)
        box(b, "CheekPlane_" .. s, s * .35, 2.35, -.51, .23, .23, .15, GOLD_LIGHT,
            R(0, 0, -.18 * s))
        box(b, "Ear_" .. s, s * .56, 2.45, -.01, .18, .38, .31, GOLD_DARK)
        b:ring("Earring_" .. s, C(s * .60, 2.20, -.16), .11, .037, GOLD_LIGHT, 8)
    end
    box(b, "MouthDarkInset", 0, 2.17, -.59, .40, .08, .04, GOLD_DARK)
    box(b, "UpperLip", 0, 2.22, -.62, .42, .06, .07, GOLD_LIGHT)
    box(b, "LowerLip", 0, 2.12, -.61, .36, .06, .06, GOLD)
    for i = -2, 2 do
        box(b, "Tooth_" .. i, i * .065, 2.177, -.621, .050, .038, .018, GOLD_LIGHT)
    end
    box(b, "Chin", 0, 1.99, -.49, .47, .19, .20, GOLD)
    box(b, "PharaohBeard", 0, 1.77, -.53, .22, .54, .27, GOLD_DARK, R(-.15, 0, 0))
    for i = 0, 6 do
        box(b, "BeardBand_" .. i, 0, 1.52 + i * .069, -.695, .24, .038, .05,
            i % 2 == 0 and GOLD_LIGHT or blue)
    end
    -- Broad striped nemes headdress, with individual gold and lapis courses.
    for _, s in ipairs({-1, 1}) do
        for i = 0, 11 do
            local t = i / 11
            local x = s * (.56 + .19 * math.sin(t * PI))
            box(b, "HeaddressCourse_" .. s .. "_" .. i, x, 1.93 + i * .105, .00,
                .36 + .13 * math.sin(t * PI), .083, .88,
                i % 2 == 0 and GOLD_LIGHT or blue, R(0, 0, -.07 * s))
        end
        line(b, "HeaddressOuterTrim_" .. s, V(s * .72, 1.85, -.39),
            V(s * .90, 3.16, -.38), .085, GOLD)
    end
    box(b, "CrownBase", 0, 3.17, .01, 1.46, .18, 1.02, GOLD)
    box(b, "CrownFrontBand", 0, 3.16, -.54, 1.49, .14, .07, GOLD_LIGHT)
    b:triangle("CrownFrontPeak", V(-.54, 3.25, -.47), V(.54, 3.25, -.47),
        V(0, 4.13, -.17), GOLD, .13)
    b:triangle("CrownRearPeak", V(-.52, 3.25, .40), V(.52, 3.25, .40),
        V(0, 4.10, .13), GOLD_DARK, .13)
    for _, s in ipairs({-1, 1}) do
        b:triangle("CrownSidePeak_" .. s, V(s * .67, 3.25, -.34), V(s * .67, 3.25, .34),
            V(s * .83, 3.90, 0), GOLD_LIGHT, .09)
    end
    gem(b, "CrownEmerald", 0, 3.38, -.61, .18, .11, GREEN)
    ball(b, "CobraHead", 0, 3.70, -.40, .18, .23, .17, GOLD_LIGHT)
    line(b, "CobraNeck", V(0, 3.39, -.62), V(0, 3.69, -.42), .09, GOLD)
    gem(b, "ChestEmerald", 0, .95, -.50, .21, .12, GREEN)
    for i = 0, 4 do
        box(b, "TorsoEngraving_" .. i, 0, .51 + i * .12, -.484, .57 + i * .085,
            .026, .017, GOLD_DARK)
    end
end

local function exodiaArm(b, side)
    local blue = Color3.fromRGB(38, 63, 111)
    ball(b, "ShoulderJoint", 0, .48, .03, 1.02, .90, .90, GOLD_DARK)
    disk(b, "ShoulderRing", 0, .56, -.41, .87, .11, GOLD_LIGHT, "Z")
    gem(b, "ShoulderEmerald", 0, .56, -.49, .20, .11, GREEN)
    box(b, "UpperArmCore", side * .07, 1.28, .01, .55, 1.01, .62, GOLD)
    box(b, "UpperArmFront", side * .07, 1.30, -.34, .43, .76, .14, GOLD_LIGHT)
    for i = 0, 4 do
        box(b, "UpperArmEtching_" .. i, side * .07, 1.01 + i * .13, -.419,
            .28, .027, .019, GOLD_DARK)
    end
    ball(b, "ElbowJoint", side * .08, 1.86, 0, .65, .56, .65, GOLD_DARK)
    disk(b, "ElbowShield", side * .08, 1.87, -.33, .44, .10, GOLD_LIGHT, "Z")
    box(b, "GauntletCore", side * .05, 2.41, .01, .74, .88, .73, GOLD)
    box(b, "GauntletFrontPlate", side * .05, 2.43, -.39, .62, .72, .16, GOLD_LIGHT)
    for _, edge in ipairs({-1, 1}) do
        box(b, "GauntletBorder_" .. edge, side * .05 + edge * .32, 2.43, -.43,
            .075, .80, .10, GOLD_DARK)
    end
    for i = 0, 5 do
        box(b, "GauntletBand_" .. i, side * .05, 2.08 + i * .14, 0,
            .80, .05, .78, i % 2 == 0 and GOLD_DARK or blue)
    end
    gem(b, "GauntletEmerald", side * .05, 2.43, -.49, .16, .12, GREEN)
    box(b, "HandPalm", 0, 3.04, -.02, .70, .47, .39, GOLD)
    box(b, "HandBackPlate", 0, 3.04, .21, .57, .33, .13, GOLD_LIGHT)
    for finger = 0, 3 do
        local x = -.255 + finger * .17
        for joint = 0, 2 do
            local y = 3.31 + joint * .14
            box(b, "Finger_" .. finger .. "Joint_" .. joint, x, y, -.03 - joint * .025,
                .135, .12, .16, joint == 1 and GOLD_DARK or GOLD)
        end
        ball(b, "Knuckle_" .. finger, x, 3.24, -.22, .13, .13, .12, GOLD_LIGHT)
    end
    line(b, "ThumbBase", V(side * .31, 2.99, -.03), V(side * .50, 3.20, -.08), .17, GOLD)
    line(b, "ThumbTip", V(side * .50, 3.20, -.08), V(side * .54, 3.40, -.11), .145, GOLD_LIGHT)
end

local function exodiaLeg(b, side)
    local blue = Color3.fromRGB(38, 63, 111)
    box(b, "Foot", side * .02, .26, -.20, .94, .43, 1.28, GOLD)
    box(b, "SandalSole", side * .02, .06, -.20, .98, .10, 1.31, GOLD_DARK)
    box(b, "ToePlate", side * .02, .29, -.77, .87, .27, .18, GOLD_LIGHT)
    for i = 0, 4 do
        box(b, "ToeGroove_" .. i, side * .02 - .32 + i * .16, .28, -.873,
            .024, .18, .017, GOLD_DARK)
    end
    box(b, "ShinCore", 0, 1.24, .02, .66, 1.47, .66, GOLD)
    box(b, "GreaveFront", 0, 1.24, -.35, .60, 1.26, .17, GOLD_LIGHT)
    for _, edge in ipairs({-1, 1}) do
        box(b, "GreaveBorder_" .. edge, edge * .28, 1.25, -.46, .07, 1.27, .08, GOLD_DARK)
    end
    for i = 0, 7 do
        box(b, "ShinBand_" .. i, 0, .67 + i * .15, .02, .73, .04, .72,
            i % 2 == 0 and GOLD_DARK or blue)
    end
    ball(b, "KneeJoint", 0, 2.02, .04, .75, .65, .77, GOLD_DARK)
    disk(b, "KneeShield", 0, 2.03, -.39, .66, .12, GOLD_LIGHT, "Z")
    gem(b, "KneeEmerald", 0, 2.03, -.48, .20, .12, GREEN)
    box(b, "ThighCore", side * .06, 2.88, .04, .77, 1.27, .74, GOLD)
    box(b, "ThighFront", side * .06, 2.89, -.38, .65, 1.09, .16, GOLD_LIGHT)
    for i = 0, 5 do
        box(b, "ThighEtching_" .. i, side * .06, 2.47 + i * .15, -.469,
            .40 + .025 * (i % 2), .027, .02, GOLD_DARK)
    end
    disk(b, "UpperLegCollar", side * .06, 3.57, .03, .88, .15, GOLD_DARK, "Y")
    disk(b, "UpperLegTrim", side * .06, 3.67, .03, .85, .065, GOLD_LIGHT, "Y")
    for _, edge in ipairs({-1, 1}) do
        ball(b, "ThighRivet_" .. edge, side * .06 + edge * .25, 3.24, -.48,
            .075, .075, .06, GOLD_DARK)
    end
end

function M.build(b, key)
    if key == "masterball" then pokeball(b, true)
    elseif key == "pokeball" then pokeball(b, false)
    elseif key == "evolutionstone" then evolutionStone(b)
    elseif key == "firestone" then evolutionStone(b, "fire")
    elseif key == "waterstone" then evolutionStone(b, "water")
    elseif key == "legendfeather" then legendFeather(b)
    elseif key == "missingno" then missingno(b)
    elseif key == "ironman" then ironman(b)
    elseif key == "megaknight" then megaknight(b)
    elseif key == "pekka" then pekka(b)
    elseif key == "brolyjewelry" then brolyJewelry(b)
    elseif key == "exodiahead" then exodiaHead(b)
    elseif key == "exodialeftarm" then exodiaArm(b, -1)
    elseif key == "exodiarightarm" then exodiaArm(b, 1)
    elseif key == "exodialeftleg" then exodiaLeg(b, -1)
    elseif key == "exodiarightleg" then exodiaLeg(b, 1)
    else return false end
    return true
end

return M

