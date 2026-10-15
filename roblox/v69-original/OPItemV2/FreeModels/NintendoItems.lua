-- Handmade, native Roblox geometry. No generated assets, paid services, or IDs.
-- Front faces point toward -Z. Every detail scales with the shared art builder.
local M = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local pi = math.pi
local METAL, PLASTIC = Enum.Material.Metal, Enum.Material.SmoothPlastic
local WOOD, NEON = Enum.Material.Wood, Enum.Material.Neon
local white = Color3.fromRGB(251, 247, 224)
local ivory = Color3.fromRGB(228, 221, 192)
local black = Color3.fromRGB(21, 24, 34)
local gold = Color3.fromRGB(255, 192, 44)
local paleGold = Color3.fromRGB(255, 229, 117)
local darkGold = Color3.fromRGB(159, 92, 19)
local silver = Color3.fromRGB(215, 229, 242)
local steel = Color3.fromRGB(108, 133, 159)
local blue = Color3.fromRGB(31, 107, 233)
local navy = Color3.fromRGB(12, 39, 94)
local green = Color3.fromRGB(48, 157, 54)
local lime = Color3.fromRGB(121, 210, 64)
local red = Color3.fromRGB(217, 48, 43)

local function disc(b, name, p, diameter, depth, color, material)
    return b:cylinder(name, V(depth, diameter, diameter), C(p) * A(0, pi / 2, 0), color, material)
end

local function discY(b, name, p, diameter, depth, color, material)
    return b:cylinder(name, V(depth, diameter, diameter), C(p) * A(0, 0, pi / 2), color, material)
end

local function ellipse(b, name, cf, rx, ry, width, color, count, material)
    count = count or 20
    for i = 0, count - 1 do
        local t, u = i * 2 * pi / count, (i + 1) * 2 * pi / count
        b:line(name .. i, cf * V(rx * math.cos(t), ry * math.sin(t), 0),
            cf * V(rx * math.cos(u), ry * math.sin(u), 0), width, width, color, material)
    end
end

local function cone(b, name, base, tip, radius, color, count)
    count = count or 6
    local axis = (tip - base).Unit
    local ref = math.abs(axis.Y) < .9 and V(0, 1, 0) or V(1, 0, 0)
    local x = axis:Cross(ref).Unit
    local z = axis:Cross(x).Unit
    for i = 0, count - 1 do
        local t, u = i * 2 * pi / count, (i + 1) * 2 * pi / count
        local a = base + (x * math.cos(t) + z * math.sin(t)) * radius
        local c = base + (x * math.cos(u) + z * math.sin(u)) * radius
        b:triangle(name .. i, a, c, tip, color, .025, PLASTIC)
    end
end

local function leaf(b, name, center, tip, spread, color, thickness)
    local mid = (center + tip) * .5
    local sideways = V(-(tip-center).Y, (tip-center).X, 0).Unit * spread
    local ridge = mid + V(0, 0, -.13)
    b:triangle(name .. "Left", center, mid + sideways, ridge, color, thickness or .06, PLASTIC)
    b:triangle(name .. "LeftTip", mid + sideways, tip, ridge, color, thickness or .06, PLASTIC)
    b:triangle(name .. "Right", center, mid - sideways, ridge, lime, thickness or .06, PLASTIC)
    b:triangle(name .. "RightTip", mid - sideways, tip, ridge, lime, thickness or .06, PLASTIC)
    b:line(name .. "Vein", center + V(0, 0, -.08), tip + V(0, 0, -.08), .045, .035, Color3.fromRGB(35, 104, 34), PLASTIC)
end

local function blueShell(b)
    b:ball("SapphireShellBody", V(2.85, 1.8, 2.5), C(0, .55, 0), blue, PLASTIC)
    b:ball("IvoryUnderside", V(3.05, .51, 2.72), C(0, -.04, 0), ivory, PLASTIC)
    b:ball("UndersideInset", V(2.54, .24, 2.2), C(0, -.26, 0), white, PLASTIC)
    ellipse(b, "ThickIvoryRim", C(0, .1, 0) * A(pi / 2, 0, 0), 1.47, 1.28, .17, white, 24, PLASTIC)
    ellipse(b, "BlueRimSeam", C(0, .26, 0) * A(pi / 2, 0, 0), 1.37, 1.17, .055, navy, 20, PLASTIC)
    -- Raised, curved shell panels separated by dark blue seams.
    for i = 0, 5 do
        local t = i * pi / 3
        local x, z = math.cos(t), math.sin(t)
        b:ball("RaisedShellPlate" .. i, V(.98, .53, .93), C(x * .69, 1.06, z * .6) * A(0, -t, 0),
            i % 2 == 0 and Color3.fromRGB(42, 133, 255) or Color3.fromRGB(30, 99, 221), PLASTIC)
        b:line("ShellPlateSeam" .. i, V(x * .44, 1.4, z * .39), V(x * 1.19, .82, z * 1.04), .052, .052, navy, PLASTIC)
    end
    b:ball("CrownPanel", V(1.03, .35, 1.03), C(0, 1.42, 0), Color3.fromRGB(70, 153, 255), PLASTIC)
    cone(b, "CrownSpike", V(0, 1.47, 0), V(0, 2.42, 0), .34, white)
    for i = 0, 3 do
        local t = pi / 4 + i * pi / 2
        local outward = V(math.cos(t), .43, math.sin(t))
        local base = V(math.cos(t) * .88, 1.12, math.sin(t) * .77)
        cone(b, "OuterSpike" .. i, base, base + outward * .88, .29, white)
    end
    -- Feathers form two fully dimensional, readable wings, rather than flat slabs.
    for _, s in ipairs({ -1, 1 }) do
        b:ball("WingShoulder" .. s, V(.5, .72, .68), C(s * 1.37, .72, .03) * A(0, 0, s * -.35), ivory, PLASTIC)
        b:ball("WingBody" .. s, V(.65, 1.38, .4), C(s * 1.81, 1.12, .06) * A(0, 0, s * -.55), white, PLASTIC)
        for j = 0, 5 do
            local x, y = 1.72 + j * .117, .77 + j * .145
            b:ball("LongFlightFeather" .. s .. "_" .. j, V(.21, 1.2 - j * .055, .22),
                C(s * x, y + .33, .02) * A(0, 0, s * (-.65 - j * .047)), white, PLASTIC)
            b:ball("FeatherRoot" .. s .. "_" .. j, V(.2, .58, .17),
                C(s * (x - .13), y + .03, -.145) * A(0, 0, s * -.73), ivory, PLASTIC)
        end
        b:line("WingLeadingEdge" .. s, V(s * 1.42, .48, -.17), V(s * 2.01, 1.95, -.17), .105, .105, white, PLASTIC)
    end
end

local function kirbySword(b)
    -- Sword-copy-ability blade: broad silver diamond section, blue handle, gold guard.
    local y0, shoulder, tip = -.12, 2.64, 3.22
    local left, right = V(-.4, y0, 0), V(.4, y0, 0)
    local shoulderLeft, shoulderRight = V(-.38, shoulder, 0), V(.38, shoulder, 0)
    local apex = V(0, tip, 0)
    for _, side in ipairs({ -1, 1 }) do
        local ridgeBase, ridgeTop = V(0, y0, side * .145), V(0, shoulder, side * .12)
        b:triangle("BladeLeftLower" .. side, left, shoulderLeft, ridgeBase, silver, .026, METAL)
        b:triangle("BladeLeftUpper" .. side, shoulderLeft, ridgeTop, ridgeBase, Color3.fromRGB(238, 246, 255), .026, METAL)
        b:triangle("BladeRightLower" .. side, right, shoulderRight, ridgeBase, steel, .026, METAL)
        b:triangle("BladeRightUpper" .. side, shoulderRight, ridgeTop, ridgeBase, silver, .026, METAL)
        b:triangle("BladeTipLeft" .. side, shoulderLeft, apex, ridgeTop, white, .026, METAL)
        b:triangle("BladeTipRight" .. side, shoulderRight, apex, ridgeTop, silver, .026, METAL)
        b:line("BladeCenterRidge" .. side, V(0, .08, side * .155), V(0, 2.67, side * .125), .025, .025, white, METAL)
        b:box("RicassoInset" .. side, V(.25, .24, .025), C(0, .01, side * .16), darkGold, METAL)
    end
    b:box("GoldGuardCore", V(.89, .26, .46), C(0, -.18, 0), gold, METAL)
    for _, s in ipairs({ -1, 1 }) do
        b:line("SweptCrossguard" .. s, V(s * .27, -.13, 0), V(s * .91, .03, 0), .23, .4, gold, METAL)
        b:triangle("GuardPoint" .. s, V(s * .62, -.22, -.22), V(s * 1.07, .12, -.22), V(s * .53, .12, -.22), paleGold, .08, METAL)
        b:ball("GuardTerminal" .. s, V(.23, .28, .4), C(s * .91, .03, 0), gold, METAL)
        b:line("GuardEngraving" .. s, V(s * .34, -.11, -.24), V(s * .83, .035, -.24), .025, .025, paleGold, METAL)
    end
    disc(b, "GuardBlueJewel", V(0, -.16, -.27), .35, .09, Color3.fromRGB(36, 150, 252), METAL)
    disc(b, "RearGuardBlueJewel", V(0, -.16, .27), .35, .09, blue, METAL)
    b:cylinder("BlueGrip", V(.99, .35, .35), C(0, -.84, 0) * A(0, 0, pi / 2), navy, PLASTIC)
    for j = 0, 7 do
        local y = -.4 - j * .119
        ellipse(b, "GripBinding" .. j, C(0, y, 0) * A(pi / 2, 0, 0), .19, .19, .04, blue, 6, PLASTIC)
    end
    b:cylinder("GripGoldCollar", V(.15, .43, .43), C(0, -.38, 0) * A(0, 0, pi / 2), gold, METAL)
    b:cylinder("PommelGoldCollar", V(.14, .43, .43), C(0, -1.4, 0) * A(0, 0, pi / 2), gold, METAL)
    b:ball("BluePommel", V(.55, .45, .5), C(0, -1.62, 0), blue, PLASTIC)
    b:ball("PommelHighlight", V(.17, .12, .055), C(-.11, -1.51, -.23), Color3.fromRGB(128, 203, 255), PLASTIC)
    ellipse(b, "PommelBand", C(0, -1.62, 0) * A(pi / 2, 0, 0), .275, .25, .055, gold, 12, METAL)
end

local function goldenSpatula(b)
    -- Built around real open slots: no black rectangles pretending to be holes.
    b:box("SpatulaHeadTop", V(1.55, .18, .18), C(0, 1.93, 0), paleGold, METAL)
    b:box("SpatulaHeadBottom", V(1.55, .2, .18), C(0, .71, 0), gold, METAL)
    for _, s in ipairs({ -1, 1 }) do
        b:box("HeadOuterRail" .. s, V(.19, 1.22, .18), C(s * .68, 1.32, 0), gold, METAL)
        b:ball("RoundedHeadCorner" .. s, V(.21, .21, .18), C(s * .67, 1.95, 0), paleGold, METAL)
        b:box("HeadEdgeBevel" .. s, V(.035, 1.14, .06), C(s * .78, 1.31, -.04), paleGold, METAL)
    end
    for i = -2, 2 do
        b:box("GoldSlotDivider" .. i, V(.11, 1.12, .16), C(i * .215, 1.31, 0), gold, METAL)
        b:box("DividerHighlight" .. i, V(.029, 1.04, .025), C(i * .215 - .025, 1.31, -.089), paleGold, METAL)
    end
    b:triangle("HeadNeckLeft", V(-.76, .62, 0), V(0, .19, 0), V(0, .62, 0), gold, .17, METAL)
    b:triangle("HeadNeckRight", V(.76, .62, 0), V(0, .19, 0), V(0, .62, 0), paleGold, .17, METAL)
    b:line("GoldShaft", V(0, .39, 0), V(0, -1.05, .07), .16, .16, gold, METAL)
    b:line("ShaftHighlight", V(-.042, .37, -.088), V(-.042, -.94, -.02), .03, .03, paleGold, METAL)
    b:ball("RoundedWoodHandle", V(.43, 1.24, .38), C(0, -1.41, .09), Color3.fromRGB(124, 62, 29), WOOD)
    for i = 0, 8 do
        local y = -.94 - i * .112
        ellipse(b, "GripRing" .. i, C(0, y, .09) * A(pi / 2, 0, 0), .19, .165, .025,
            i % 2 == 0 and Color3.fromRGB(164, 89, 40) or Color3.fromRGB(79, 39, 21), 6, WOOD)
    end
    b:cylinder("GripGoldFerrule", V(.15, .42, .38), C(0, -.84, .09) * A(0, 0, pi / 2), gold, METAL)
    b:cylinder("GripEndCap", V(.1, .34, .32), C(0, -2.01, .09) * A(0, 0, pi / 2), gold, METAL)
    ellipse(b, "HangingLoop", C(0, -2.23, .09), .16, .21, .06, gold, 12, METAL)
    disc(b, "HandlePin", V(0, -1.1, -.115), .11, .025, paleGold, METAL)
end

local function krabbyPatty(b)
    local bun = Color3.fromRGB(220, 143, 57)
    local toasted = Color3.fromRGB(169, 90, 30)
    local meat = Color3.fromRGB(88, 39, 24)
    b:ball("BottomBun", V(3.2, .55, 2.84), C(0, -.82, 0), bun, PLASTIC)
    b:ball("ToastedBottomCrust", V(3.11, .19, 2.73), C(0, -1.02, 0), toasted, PLASTIC)
    b:ball("GrilledPatty", V(3.12, .42, 2.76), C(0, -.43, 0), meat, PLASTIC)
    for i = 0, 13 do
        local t = i * 2 * pi / 14
        b:ball("PattyCrag" .. i, V(.39, .22, .32), C(math.cos(t) * 1.4, -.42, math.sin(t) * 1.22),
            i % 2 == 0 and Color3.fromRGB(115, 57, 31) or Color3.fromRGB(66, 30, 20), PLASTIC)
    end
    for j = -2, 2 do
        b:line("GrillMark" .. j, V(-.8, -.18, j * .24), V(.8, -.18, j * .24), .055, .045, Color3.fromRGB(44, 22, 17), PLASTIC)
    end
    b:box("CheeseSlice", V(2.45, .065, 2.45), C(0, -.15, 0) * A(0, .25, 0), Color3.fromRGB(255, 190, 18), PLASTIC)
    for _, s in ipairs({ -1, 1 }) do
        b:triangle("DroopingCheeseFront" .. s, V(s * .4, -.12, -1.39), V(s * 1.17, -.12, -1.19), V(s * .91, -.55, -1.46), gold, .045, PLASTIC)
        b:triangle("DroopingCheeseBack" .. s, V(s * .4, -.12, 1.39), V(s * 1.17, -.12, 1.19), V(s * .91, -.48, 1.43), gold, .045, PLASTIC)
    end
    for i = 0, 15 do
        local t = i * 2 * pi / 16
        b:ball("RuffledLettuce" .. i, V(.65, .18, .59), C(math.cos(t) * 1.25, .015 + (i % 2) * .04, math.sin(t) * 1.09) * A(.09 * math.cos(t), -t, .1 * math.sin(t)),
            i % 2 == 0 and green or lime, PLASTIC)
        b:line("LettuceVein" .. i, V(math.cos(t) * 1.03, .13, math.sin(t) * .9),
            V(math.cos(t) * 1.51, .15, math.sin(t) * 1.31), .035, .035, Color3.fromRGB(178, 224, 98), PLASTIC)
    end
    for _, x in ipairs({ -.62, .62 }) do
        discY(b, "TomatoSlice" .. x, V(x, .2, -.15), 1.45, .19, red, PLASTIC)
        discY(b, "TomatoFlesh" .. x, V(x, .304, -.15), 1.15, .025, Color3.fromRGB(245, 105, 67), PLASTIC)
    end
    for i = 0, 3 do
        local t = pi / 4 + i * pi / 2
        discY(b, "PickleSlice" .. i, V(math.cos(t) * .66, .41, math.sin(t) * .6), .66, .13, green, PLASTIC)
        discY(b, "PickleCenter" .. i, V(math.cos(t) * .66, .48, math.sin(t) * .6), .47, .018, Color3.fromRGB(164, 186, 79), PLASTIC)
    end
    b:ball("DomedSesameBun", V(3.2, 1.33, 2.84), C(0, .87, 0), bun, PLASTIC)
    b:ball("BunGoldenCrown", V(2.75, .69, 2.46), C(0, 1.24, 0), Color3.fromRGB(239, 175, 79), PLASTIC)
    for i = 0, 24 do
        local t = i * 2.399963
        local r = math.sqrt((i + .5) / 25) * .9
        local x, z = math.cos(t) * r * 1.4, math.sin(t) * r * 1.22
        local y = 1.43 + .15 * math.sqrt(math.max(0, 1 - r * r))
        b:ball("SesameSeed" .. i, V(.072, .04, .16), C(x, y, z) * A(0, t, .12), white, PLASTIC)
    end
end

local function garyShell(b)
    local pink = Color3.fromRGB(239, 149, 185)
    local rose = Color3.fromRGB(181, 48, 87)
    local purple = Color3.fromRGB(108, 70, 156)
    b:ball("PinkShellMass", V(2.99, 2.8, 1.72), C(0, .37, .16), pink, PLASTIC)
    b:ball("ShellBackRound", V(2.57, 2.45, .61), C(0, .39, .9), Color3.fromRGB(219, 118, 165), PLASTIC)
    -- Actual open mouth at lower right: its rim is a ring, not a covered disc.
    ellipse(b, "ThickOpeningLip", C(.92, -.54, -.68) * A(0, -.28, -.38), .56, .76, .17, Color3.fromRGB(244, 172, 199), 20, PLASTIC)
    b:ball("RecessedOpeningInterior", V(.91, 1.24, .12), C(.98, -.54, -.46) * A(0, -.28, -.38), Color3.fromRGB(69, 32, 60), PLASTIC)
    ellipse(b, "OpeningInnerLip", C(.94, -.53, -.72) * A(0, -.28, -.38), .44, .63, .065, Color3.fromRGB(193, 93, 143), 16, PLASTIC)
    local previous
    for i = 0, 39 do
        local t = i * .22
        local r = .075 + i * .028
        local p = V(-.16 + math.cos(t) * r, .51 + math.sin(t) * r, -.74 - .12 * math.sqrt(math.max(0, 1 - (r / 1.35)^2)))
        if previous then b:line("RaisedRedSpiral" .. i, previous, p, .092, .08, rose, PLASTIC) end
        previous = p
    end
    for i, p in ipairs({ V(-1.11, 1.02, -.54), V(-1.27, -.05, -.48), V(-.55, -.86, -.51), V(.69, 1.47, -.46), V(1.12, .86, -.51) }) do
        b:ball("VioletShellSpot" .. i, V(.27 + (i % 2) * .08, .4, .065), C(p) * A(0, 0, i * .43), purple, PLASTIC)
    end
    for i = 0, 14 do
        local t = i * 2 * pi / 15
        b:line("ShellGrowthRidge" .. i, V(math.cos(t) * 1.16, .37 + math.sin(t) * 1.06, .82),
            V(math.cos(t) * 1.39, .37 + math.sin(t) * 1.29, .45), .035, .035, Color3.fromRGB(244, 168, 199), PLASTIC)
    end
    for i = 0, 11 do
        local t = i * 2 * pi / 12
        b:ball("BackVioletSpot" .. i, V(.16, .2, .055), C(math.cos(t) * .94, .39 + math.sin(t) * .85, 1.21), purple, PLASTIC)
    end
end

local function superStar(b)
    local front, back = V(0, .12, -.39), V(0, .12, .35)
    local points = {}
    for i = 0, 9 do
        local t = pi / 2 + i * pi / 5
        local r = i % 2 == 0 and 1.62 or .76
        points[i + 1] = V(math.cos(t) * r, .12 + math.sin(t) * r, 0)
    end
    for i = 1, 10 do
        local j = i % 10 + 1
        local a, c = points[i], points[j]
        b:triangle("GoldFrontFacet" .. i, front, a + V(0, 0, -.09), c + V(0, 0, -.09), i % 2 == 0 and gold or paleGold, .035, METAL)
        b:triangle("GoldBackFacet" .. i, back, a + V(0, 0, .09), c + V(0, 0, .09), gold, .035, METAL)
        b:triangle("StarEdgeA" .. i, a + V(0, 0, -.09), c + V(0, 0, -.09), a + V(0, 0, .09), darkGold, .025, METAL)
        b:triangle("StarEdgeB" .. i, c + V(0, 0, -.09), c + V(0, 0, .09), a + V(0, 0, .09), gold, .025, METAL)
    end
    for _, s in ipairs({ -1, 1 }) do
        b:ball("OvalStarEye" .. s, V(.15, .48, .08), C(s * .31, .21, -.397), black, PLASTIC)
        b:ball("EyeCatchlight" .. s, V(.043, .12, .023), C(s * .31 - .025, .34, -.439), white, PLASTIC)
    end
    b:ball("GoldGlint", V(.12, .17, .025), C(-.57, .66, -.293), white, METAL)
end

local function fireFlower(b)
    local orange = Color3.fromRGB(255, 120, 21)
    local center = V(0, .95, 0)
    -- Lobed flower ring with a yellow inset face and two tall black eyes.
    for i = 0, 11 do
        local t = i * 2 * pi / 12
        b:ball("OrangePetal" .. i, V(.73, .76, .54), C(center + V(math.cos(t) * .71, math.sin(t) * .73, 0)), orange, PLASTIC)
        b:ball("RedPetalOutline" .. i, V(.83, .86, .42), C(center + V(math.cos(t) * .77, math.sin(t) * .79, .18)), red, PLASTIC)
    end
    b:ball("FlowerYellowFace", V(1.66, 1.76, .51), C(0, .95, -.18), Color3.fromRGB(255, 224, 65), PLASTIC)
    b:ball("BackFlowerCalyx", V(1.1, 1.18, .46), C(0, .89, .42), green, PLASTIC)
    for _, s in ipairs({ -1, 1 }) do
        b:ball("FlowerEye" .. s, V(.13, .47, .09), C(s * .25, 1.03, -.438), black, PLASTIC)
        b:ball("FlowerEyeGlint" .. s, V(.035, .1, .024), C(s * .25 - .018, 1.17, -.485), white, PLASTIC)
    end
    b:line("ThickFlowerStem", V(0, .15, .08), V(0, -1.61, .08), .24, .24, green, PLASTIC)
    b:line("StemHighlight", V(-.055, .1, -.052), V(-.055, -1.58, -.052), .055, .035, lime, PLASTIC)
    leaf(b, "LeftLeaf", V(-.04, -.91, .05), V(-1.28, -.41, .05), .35, green)
    leaf(b, "RightLeaf", V(.04, -1.23, .05), V(1.23, -.67, .05), .35, green)
    for _, s in ipairs({ -1, 1 }) do
        for i = 1, 4 do
            local p = V(s * (.16 + i * .185), -.91 + (s == -1 and 0 or -.32) + i * .072, -.12)
            b:line("LeafVein" .. s .. "_" .. i, p, p + V(s * .13, .17, .04), .025, .025, Color3.fromRGB(80, 141, 44), PLASTIC)
        end
    end
    b:ball("StemFoot", V(.36, .18, .3), C(0, -1.63, .08), green, PLASTIC)
end

local function hylianShield(b)
    local outline = { V(0, 2.08, 0), V(1.23, 1.73, 0), V(1.41, .68, 0), V(.99, -.8, 0), V(0, -1.82, 0), V(-.99, -.8, 0), V(-1.41, .68, 0), V(-1.23, 1.73, 0) }
    local centerFront, centerBack = V(0, .23, -.3), V(0, .23, .22)
    for i = 1, #outline do
        local j = i % #outline + 1
        local a, c = outline[i], outline[j]
        b:triangle("BlueShieldFace" .. i, centerFront, a * .86 + V(0, .025, -.08), c * .86 + V(0, .025, -.08), i % 2 == 0 and blue or navy, .075, METAL)
        b:triangle("SteelShieldBack" .. i, centerBack, a + V(0, 0, .1), c + V(0, 0, .1), steel, .08, METAL)
        b:line("SculptedSilverRim" .. i, a + V(0, 0, -.08), c + V(0, 0, -.08), .18, .27, silver, METAL)
        b:line("InnerRaisedRim" .. i, a * .86 + V(0, .025, -.13), c * .86 + V(0, .025, -.13), .064, .08, steel, METAL)
        b:ball("RimRivet" .. i, .13, C(a + V(0, 0, -.23)), white, METAL)
    end
    -- Raised Triforce, with the center triangle left blue.
    local ty, unit = 1.06, .33
    for i, p in ipairs({ V(0, ty + .35, -.27), V(-.34, ty - .23, -.32), V(.34, ty - .23, -.32) }) do
        b:triangle("Triforce" .. i, p + V(0, unit, 0), p + V(-unit, -.24, 0), p + V(unit, -.24, 0), gold, .09, METAL)
    end
    local scarlet = Color3.fromRGB(213, 35, 54)
    b:triangle("BirdBodyLeft", V(0, .44, -.36), V(-.24, -.34, -.36), V(0, -.64, -.36), scarlet, .07, METAL)
    b:triangle("BirdBodyRight", V(0, .44, -.36), V(.24, -.34, -.36), V(0, -.64, -.36), scarlet, .07, METAL)
    b:line("BirdNeck", V(0, .12, -.4), V(0, .62, -.36), .11, .06, scarlet, METAL)
    b:triangle("BirdHead", V(0, .61, -.35), V(.25, .56, -.35), V(0, .75, -.35), scarlet, .065, METAL)
    for _, s in ipairs({ -1, 1 }) do
        b:line("BirdWingSpine" .. s, V(s * .13, -.12, -.37), V(s * .92, .49, -.27), .115, .07, scarlet, METAL)
        for i = 0, 3 do
            local x, y = .34 + i * .18, -.05 + i * .14
            b:triangle("BirdWingFeather" .. s .. "_" .. i, V(s * x, y, -.36 + i * .025),
                V(s * (x + .13), y + .54, -.35 + i * .025), V(s * (x + .2), y + .14, -.35 + i * .025), scarlet, .06, METAL)
        end
        b:line("BirdTalon" .. s, V(s * .1, -.47, -.37), V(s * .36, -.69, -.31), .065, .06, scarlet, METAL)
        b:line("BirdLowerTail" .. s, V(s * .07, -.56, -.36), V(s * .27, -1.03, -.25), .08, .06, scarlet, METAL)
        -- Rear leather straps are genuinely raised off the back of the shield.
        b:line("RearStrapMount" .. s, V(s * .59, .88, .26), V(s * .59, -.72, .26), .2, .1, Color3.fromRGB(80, 44, 26), WOOD)
        b:line("RearStrapUpper" .. s, V(s * .59, .62, .29), V(s * .59, .26, .62), .19, .105, Color3.fromRGB(129, 76, 38), WOOD)
        b:line("RearStrapLower" .. s, V(s * .59, .26, .62), V(s * .59, -.48, .29), .19, .105, Color3.fromRGB(129, 76, 38), WOOD)
        for _, y in ipairs({ -.56, .7 }) do
            disc(b, "RearStrapStud" .. s .. y, V(s * .59, y, .33), .12, .05, gold, METAL)
        end
    end
end

local builders = {
    blue_shell = blueShell,
    kirby_sword = kirbySword,
    golden_spatula = goldenSpatula,
    krabby_patty = krabbyPatty,
    gary_shell = garyShell,
    super_star = superStar,
    fire_flower = fireFlower,
    hylian_shield = hylianShield,
}
function M.build(b, key)
    local build = builders[key]
    if not build then return false end
    build(b)
    return true
end
return M
