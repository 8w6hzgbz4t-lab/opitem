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
    -- One continuous dome, individually surface-fitted seeds, and a complete
    -- ingredient stack make the collectible readable from every viewing angle.
    local bun = Color3.fromRGB(231, 160, 65)
    local toasted = Color3.fromRGB(179, 102, 36)
    local cutBun = Color3.fromRGB(242, 185, 93)
    local meat = Color3.fromRGB(91, 43, 26)
    local cheese = Color3.fromRGB(255, 195, 35)
    local lettuce = Color3.fromRGB(79, 170, 48)
    local lettuceLight = Color3.fromRGB(111, 191, 57)
    local tomato = Color3.fromRGB(216, 53, 37)
    local onion = Color3.fromRGB(246, 238, 214)
    local function foodDisc(name, p, width, depth, height, color)
        return b:cylinder(name, V(height, width, depth), C(p) * A(0, 0, pi / 2), color, PLASTIC)
    end
    -- The cylindrical cut faces conceal the lower halves of the rounded buns.
    -- This gives each bun a flat sandwich face without a second floating crown.
    b:ball("RoundedBottomBun", V(3.2, .48, 2.84), C(0, -.97, 0), bun, PLASTIC)
    foodDisc("BottomBunCutFace", V(0, -.86, 0), 3.18, 2.82, .27, cutBun)
    foodDisc("ToastedBottomCrust", V(0, -1.1, 0), 2.84, 2.48, .08, toasted)

    foodDisc("GrilledPattyCore", V(0, -.56, 0), 3.12, 2.76, .37, meat)
    b:ball("PattyRoundedShoulder", V(3.19, .37, 2.81), C(0, -.56, 0), meat, PLASTIC)
    for i = 0, 17 do
        local t = i * 2 * pi / 18
        local variation = math.sin(i * 2.1)
        b:ball("SearedPattyEdge" .. i, V(.47, .19 + .025 * variation, .18),
            C(math.cos(t) * 1.47, -.55 + .025 * variation, math.sin(t) * 1.29) * A(0, -t + pi / 2, .04 * variation),
            i % 3 == 0 and Color3.fromRGB(120, 65, 35) or Color3.fromRGB(71, 33, 22), PLASTIC)
    end
    for i = 0, 6 do
        local t = i * 2 * pi / 7
        local p = V(math.cos(t) * 1.51, -.55, math.sin(t) * 1.33)
        b:ball("PattyCharFleck" .. i, V(.09, .055, .045), C(p) * A(0, -t, .2), Color3.fromRGB(48, 25, 18), PLASTIC)
    end

    local cheeseRotation = A(0, .18, 0)
    -- The four corners are genuinely folded: their flat square corners are
    -- omitted, so each hanging tip joins the top instead of doubling it.
    b:box("MeltedCheeseCenter", V(1.48, .065, 2.54), C(0, -.345, 0) * cheeseRotation, cheese, PLASTIC)
    for _, sx in ipairs({ -1, 1 }) do
        b:box("MeltedCheeseSide" .. sx, V(.53, .065, 1.48), C(cheeseRotation * V(sx * 1.005, -.345, 0)) * cheeseRotation, cheese, PLASTIC)
    end
    for _, sx in ipairs({ -1, 1 }) do
        for _, sz in ipairs({ -1, 1 }) do
            local a = cheeseRotation * V(sx * 1.27, -.315, sz * .74)
            local c = cheeseRotation * V(sx * .74, -.315, sz * 1.27)
            local inner = cheeseRotation * V(sx * .74, -.315, sz * .74)
            local tip = cheeseRotation * V(sx * 1.27, -.64, sz * 1.27)
            b:triangle("CheeseCornerShoulder" .. sx .. "_" .. sz, a, inner, c, cheese, .04, PLASTIC)
            b:triangle("FoldedCheeseCorner" .. sx .. "_" .. sz, a, c, tip, cheese, .04, PLASTIC)
        end
    end

    foodDisc("TomatoSkin", V(0, -.15, -.025), 2.93, 2.63, .19, tomato)
    foodDisc("TomatoJuicyCutFace", V(0, -.043, -.025), 2.63, 2.35, .025, Color3.fromRGB(239, 97, 62))
    -- Pale seed pockets sit in the cut flesh rather than hovering over the tomato.
    for i = 0, 5 do
        local t = i * pi / 3
        b:ball("TomatoSeedPocket" .. i, V(.37, .025, .13), C(math.cos(t) * .87, -.027, -.025 + math.sin(t) * .75) * A(0, -t + pi / 2, 0),
            Color3.fromRGB(246, 158, 95), PLASTIC)
    end

    foodDisc("LettuceLeafCenter", V(0, .055, 0), 2.73, 2.39, .075, lettuce)
    for i = 0, 11 do
        local t = i * 2 * pi / 12
        local curl = .04 * math.sin(i * 2.3)
        local leafColor = i % 3 == 0 and lettuceLight or lettuce
        b:ball("OverlappingLettuceLeaf" .. i, V(.81, .105, .63),
            C(math.cos(t) * 1.2, .095 + curl, math.sin(t) * 1.04) * A(.09 * math.sin(t), -t, .08 * math.cos(t)), leafColor, PLASTIC)
        b:ball("FoldedLettuceFrill" .. i, V(.37, .08, .51),
            C(math.cos(t + .07) * 1.43, .12 + curl, math.sin(t + .07) * 1.25) * A(.14 * math.sin(t), -t + .22, .16 * math.cos(t)), lettuceLight, PLASTIC)
        b:line("LettuceLeafVein" .. i, V(math.cos(t) * 1.05, .154 + curl, math.sin(t) * .91),
            V(math.cos(t) * 1.46, .153 + curl, math.sin(t) * 1.27), .018, .022, Color3.fromRGB(146, 201, 81), PLASTIC)
    end

    -- A shallow visible onion ring and pickles keep the fillings readable beneath
    -- the bun lip while leaving the green lettuce silhouette unobstructed.
    ellipse(b, "OnionOuterRing", C(0, .29, 0) * A(pi / 2, 0, 0), 1.38, 1.23, .078, onion, 18, PLASTIC)
    ellipse(b, "OnionInnerRing", C(0, .296, 0) * A(pi / 2, 0, 0), 1.24, 1.09, .036, Color3.fromRGB(221, 204, 191), 18, PLASTIC)
    for i, p in ipairs({ V(-.68, .365, -.83), V(.56, .365, -.9), V(.11, .365, .86) }) do
        foodDisc("PickleRind" .. i, p, .77, .69, .12, Color3.fromRGB(56, 119, 37))
        foodDisc("PickleCutFace" .. i, p + V(0, .066, 0), .62, .55, .02, Color3.fromRGB(159, 182, 74))
        for j = 0, 2 do
            local t = j * 2 * pi / 3
            b:ball("PickleSeed" .. i .. "_" .. j, V(.05, .018, .095), C(p + V(math.cos(t) * .15, .08, math.sin(t) * .12)) * A(0, -t, 0), Color3.fromRGB(225, 222, 147), PLASTIC)
        end
    end

    local domeCenter, rx, ry, rz = .84, 1.62, .7, 1.44
    foodDisc("TopBunRecessedCutFace", V(0, .49, 0), 2.88, 2.54, .22, bun)
    b:ball("SingleDomedSesameBun", V(rx * 2, ry * 2, rz * 2), C(0, domeCenter, 0), bun, PLASTIC)
    for i = 0, 32 do
        local t = i * 2.3999632297
        local r = math.sqrt((i + .5) / 33) * .9
        local x, z = math.cos(t) * r * rx, math.sin(t) * r * rz
        local y = domeCenter + ry * math.sqrt(1 - r * r)
        local normal = V(x / (rx * rx), (y - domeCenter) / (ry * ry), z / (rz * rz)).Unit
        local direction = V(math.cos(t + .7), 0, math.sin(t + .7))
        local back = (direction - normal * direction:Dot(normal)).Unit
        local right = normal:Cross(back).Unit
        -- A seed's thin axis follows the dome normal; a small overlap keeps
        -- every seed attached to the rounded surface, including near the rim.
        local center = V(x, y, z) + normal * .014
        b:ball("SurfaceFittedSesameSeed" .. i, V(.067, .05, .157), CFrame.fromMatrix(center, right, normal, back),
            i % 3 == 0 and Color3.fromRGB(243, 232, 197) or Color3.fromRGB(255, 246, 220), PLASTIC)
    end
end
local function garyShell(b)
    local pink = Color3.fromRGB(244, 154, 188)
    local rose = Color3.fromRGB(195, 55, 89)
    local purple = Color3.fromRGB(117, 72, 159)
    local center, rx, ry, rz = V(-.13, .36, .16), 1.53, 1.47, .97
    -- A single smooth oval keeps the characteristic rounded shell silhouette.
    -- The markings are fitted to that oval, rather than floating on a flat plane.
    b:ball("SmoothPinkSpiralShell", V(rx * 2, ry * 2, rz * 2), C(center), pink, PLASTIC)
    local function surface(x, y, side)
        local dx, dy = x - center.X, y - center.Y
        local z = side * rz * math.sqrt(math.max(.002, 1 - (dx / rx)^2 - (dy / ry)^2))
        local normal = V(dx / (rx * rx), dy / (ry * ry), z / (rz * rz)).Unit
        return V(x, y, center.Z + z), normal
    end
    local function fittedMark(name, x, y, side, width, height, turn, color)
        local p, normal = surface(x, y, side)
        local right = V(0, 1, 0):Cross(normal).Unit
        local up = normal:Cross(right).Unit
        -- Thin, partly embedded ovals read as purple pigment instead of studs.
        b:ball(name, V(width, height, .026), CFrame.fromMatrix(p - normal * .003, right, up, normal) * A(0, 0, turn), color, PLASTIC)
    end
    local function spiral(name, side, count)
        local previous, previousNormal
        for i = 0, count do
            local fraction = i / count
            local t, radius = -.32 + fraction * (4 * pi + .32), .045 + 1.065 * fraction
            local x, y = -.23 + math.cos(t) * radius, .47 + math.sin(t) * radius * .96
            local p, normal = surface(x, y, side)
            p = p + normal * .003
            if previous then
                local delta = p - previous
                local along = delta.Unit
                local outward = (normal + previousNormal).Unit
                outward = (outward - along * outward:Dot(along)).Unit
                local right = along:Cross(outward).Unit
                -- Surface-oriented ribbons sit almost flush; their slight
                -- overlap makes one continuous red whorl without pokey joints.
                b:box(name .. i, V(.098 + fraction * .018, delta.Magnitude + .022, .026),
                    CFrame.fromMatrix((previous + p) * .5, right, along, right:Cross(along)), rose, PLASTIC)
            end
            previous, previousNormal = p, normal
        end
    end
    spiral("FrontSurfaceRedSpiral", -1, 72)
    spiral("BackSurfaceRedSpiral", 1, 54)
    -- The asymmetrical violet freckles are readable from either side.
    local spots = {
        { -1.19, .91, .23, .37, -.4 },
        { -1.37, .12, .22, .34, .38 },
        { -.69, -.77, .25, .38, -.7 },
        { .49, 1.5, .24, .34, .4 },
        { 1.05, .81, .24, .39, -.32 },
    }
    for i, spot in ipairs(spots) do
        for _, side in ipairs({ -1, 1 }) do
            fittedMark((side == -1 and "Front" or "Back") .. "FittedVioletSpot" .. i,
                spot[1], spot[2], side, spot[3], spot[4], spot[5], purple)
        end
    end
    fittedMark("SoftPinkShoulderGlint", -.76, 1.37, -1, .13, .31, -.57, Color3.fromRGB(255, 189, 210))

    -- The oval mouth projects beyond the solid shell. A hollow band joins the
    -- opening to a dark bowl set .26 studs behind it, leaving a visible recess.
    local mouth = C(1.04, -.51, -.87) * A(0, -.18, -.3)
    b:ball("RoundedShellThroat", V(1.32, 1.73, .44), mouth * C(0, 0, .53), Color3.fromRGB(232, 132, 174), PLASTIC)
    b:ball("DeepOpeningBowl", V(.99, 1.4, .105), mouth * C(0, 0, .285), Color3.fromRGB(65, 29, 67), PLASTIC)
    b:ball("OpeningInnerDepth", V(.78, 1.13, .035), mouth * C(.025, .045, .221), Color3.fromRGB(47, 24, 55), PLASTIC)
    for i = 0, 23 do
        local t, u = i * 2 * pi / 24, (i + 1) * 2 * pi / 24
        local mid = (t + u) * .5
        local a, c = mouth * V(math.cos(t) * .535, math.sin(t) * .747, 0), mouth * V(math.cos(u) * .535, math.sin(u) * .747, 0)
        local along = (c - a).Unit
        local outward = mouth:VectorToWorldSpace(V(0, 0, 1))
        local right = along:Cross(outward).Unit
        local lipColor = math.sin(mid) > .2 and Color3.fromRGB(255, 187, 210)
            or math.sin(mid) < -.25 and Color3.fromRGB(224, 118, 164) or Color3.fromRGB(249, 166, 199)
        -- Constant-width tube segments and small rounded seams form a smooth
        -- rolled lip, avoiding the scalloped look of a ring of separate beads.
        local radial = outward:Cross(along).Unit
        b:cylinder("RoundedOpeningLip" .. i, V((c - a).Magnitude + .015, .18, .195),
            CFrame.fromMatrix((a + c) * .5, along, radial, outward), lipColor, PLASTIC)
        b:ball("RoundedLipSeam" .. i, V(.18, .18, .195),
            CFrame.fromMatrix(a, along, radial, outward), lipColor, PLASTIC)
        local wa, wc = mouth * V(math.cos(t) * .462, math.sin(t) * .658, .15), mouth * V(math.cos(u) * .462, math.sin(u) * .658, .15)
        local wallAlong = (wc - wa).Unit
        local wallRight = wallAlong:Cross(outward).Unit
        b:box("RecessedOpeningWall" .. i, V(.105, (wc - wa).Magnitude + .015, .27),
            CFrame.fromMatrix((wa + wc) * .5, wallRight, wallAlong, outward), Color3.fromRGB(163, 77, 131), PLASTIC)
        b:line("FineInnerPinkRim" .. i, mouth * V(math.cos(t) * .452, math.sin(t) * .646, .027),
            mouth * V(math.cos(u) * .452, math.sin(u) * .646, .027), .045, .045, Color3.fromRGB(241, 149, 187), PLASTIC)
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
