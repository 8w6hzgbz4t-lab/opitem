-- Collectible technology, wearables, and spinning tops. Geometry only.
local M = {}
local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local pi = math.pi
local METAL = Enum.Material.Metal
local NEON = Enum.Material.Neon
local PLASTIC = Enum.Material.SmoothPlastic
local BLACK = Color3.fromRGB(25, 29, 36)
local STEEL = Color3.fromRGB(145, 157, 170)
local SILVER = Color3.fromRGB(209, 222, 233)
local WHITE = Color3.fromRGB(237, 241, 236)
local GREEN = Color3.fromRGB(103, 255, 82)
local GOLD = Color3.fromRGB(214, 164, 52)

local function cylinderZ(b, name, position, diameter, depth, color, material)
    return b:cylinder(name, V(depth, diameter, diameter), C(position) * A(0, pi / 2, 0), color, material)
end

local function cylinderY(b, name, position, diameter, height, color, material)
    return b:cylinder(name, V(height, diameter, diameter), C(position) * A(0, 0, pi / 2), color, material)
end

local function ellipse(b, name, center, rx, ry, thickness, color, segments, material)
    segments = segments or 16
    for i = 0, segments - 1 do
        local a, c = i * 2 * pi / segments, (i + 1) * 2 * pi / segments
        b:line(name .. i, center + V(math.cos(a) * rx, math.sin(a) * ry, 0),
            center + V(math.cos(c) * rx, math.sin(c) * ry, 0), thickness, thickness, color, material)
    end
end

local function screw(b, name, position, color)
    cylinderZ(b, name, position, .09, .035, color or STEEL)
    b:box(name .. "Slot", V(.055, .012, .008), C(position + V(0, 0, -.022)), BLACK)
end

local function portalgun(b)
    local BLUE = Color3.fromRGB(51, 192, 255)
    local ORANGE = Color3.fromRGB(255, 132, 33)
    b:box("BlackReceiver", V(1.12, 1.1, 2.35), C(0, .28, .18), BLACK)
    b:box("UpperWhiteShell", V(1.22, .25, 1.72), C(0, .89, .38) * A(-.09, 0, 0), WHITE, PLASTIC)
    b:box("LowerWhiteShell", V(1.16, .22, 1.6), C(0, -.33, .48) * A(.1, 0, 0), WHITE, PLASTIC)
    for _, s in ipairs({ -1, 1 }) do
        b:box("SideShell" .. s, V(.19, .97, 1.54), C(s * .64, .28, .42) * A(0, s * -.09, 0), WHITE, PLASTIC)
        b:wedge("RearShellTaper" .. s, V(.18, .85, .7), C(s * .57, .28, 1.47) * A(0, pi, 0), WHITE, PLASTIC)
        b:box("ShellSeam" .. s, V(.026, .055, 1.3), C(s * .75, .28, .38), BLACK)
        b:box("ShellBadge" .. s, V(.035, .26, .48), C(s * .752, .49, .64), BLACK)
        for j = 1, 5 do
            b:box("RearVent" .. s .. "_" .. j, V(.025, .31, .045), C(s * .725, .19, .54 + j * .12), BLACK)
        end
    end
    cylinderZ(b, "BarrelCore", V(0, .3, -.99), .98, .48, BLACK)
    cylinderZ(b, "MuzzleRecess", V(0, .3, -1.35), .74, .17, BLACK)
    b:ring("MuzzleSteel", C(0, .3, -1.46), .44, .08, STEEL, 20)
    b:ring("BlueAperture", C(0, .3, -1.49), .31, .04, BLUE, 20, NEON)
    b:ball("EnergyCore", V(.24, .24, .08), C(0, .3, -1.505), BLUE, NEON)
    for i = 0, 2 do
        local angle = i * 2 * pi / 3 + pi / 2
        local dx, dy = math.cos(angle), math.sin(angle)
        local base = V(dx * .51, .3 + dy * .51, -.78)
        local elbow = V(dx * .83, .3 + dy * .83, -1.3)
        local tip = V(dx * .59, .3 + dy * .59, -1.98)
        b:line("ClawUpper" .. i, base, elbow, .13, .14, BLACK)
        b:line("ClawLower" .. i, elbow, tip, .095, .115, STEEL)
        b:line("ClawTip" .. i, tip, V(dx * .34, .3 + dy * .34, -2.08), .075, .08, BLACK)
        b:ball("ClawHinge" .. i, .18, C(elbow), STEEL)
        b:line("ClawCable" .. i, base + V(0, .04, 0), elbow + V(0, .04, .07), .035, .035, BLUE, NEON)
    end
    b:box("CarryGrip", V(.32, .35, .95), C(0, 1.15, .28), BLACK)
    b:box("CarryGripTop", V(.31, .12, .92), C(0, 1.39, .28), WHITE)
    for _, z in ipairs({ -.09, .64 }) do
        b:box("GripSupport" .. z, V(.21, .42, .17), C(0, 1.12, z), STEEL)
    end
    b:box("PistolGrip", V(.33, .91, .45), C(0, -.79, .65) * A(-.23, 0, 0), BLACK)
    for j = 1, 5 do
        b:box("GripRib" .. j, V(.37, .055, .46), C(0, -.42 - j * .13, .63) * A(-.23, 0, 0), STEEL)
    end
    b:line("TriggerGuardFront", V(0, -.39, -.01), V(0, -.85, .02), .07, .1, BLACK)
    b:line("TriggerGuardBottom", V(0, -.85, .02), V(0, -.88, .46), .07, .1, BLACK)
    b:box("Trigger", V(.06, .22, .065), C(0, -.51, .21) * A(.22, 0, 0), STEEL)
    b:ball("ModeLightBlue", .09, C(-.2, .91, -.03), BLUE, NEON)
    b:ball("ModeLightOrange", .09, C(.2, .91, -.03), ORANGE, NEON)
    for _, x in ipairs({ -.48, .48 }) do
        for _, y in ipairs({ -.04, .64 }) do
            screw(b, "FaceScrew" .. x .. "_" .. y, V(x, y, -.96))
        end
    end
end

local function raygun(b)
    local RED = Color3.fromRGB(172, 37, 44)
    local DARKRED = Color3.fromRGB(94, 25, 32)
    b:box("RayReceiver", V(.88, .84, 1.35), C(0, .29, .27), RED)
    b:box("ReceiverSpine", V(.32, .19, 1.42), C(0, .79, .27), DARKRED)
    cylinderZ(b, "ReactorTube", V(0, .31, -.94), .58, 1.12, BLACK)
    cylinderZ(b, "ReactorGlass", V(0, .31, -.83), .43, .9, GREEN, NEON)
    for i = 1, 3 do
        b:ring("EnergyCoil" .. i, C(0, .31, -.56 - i * .27), .39, .075, GREEN, 16, NEON)
    end
    b:ring("MuzzleBand", C(0, .31, -1.62), .32, .09, STEEL, 16)
    cylinderZ(b, "DarkMuzzle", V(0, .31, -1.65), .43, .065, BLACK)
    cylinderZ(b, "Emitter", V(0, .31, -1.7), .21, .035, GREEN, NEON)
    for i = 0, 3 do
        local t = pi / 4 + i * pi / 2
        b:line("ReactorRail" .. i, V(math.cos(t) * .47, .31 + math.sin(t) * .47, -.37),
            V(math.cos(t) * .35, .31 + math.sin(t) * .35, -1.55), .065, .075, STEEL)
    end
    for _, s in ipairs({ -1, 1 }) do
        b:box("ReceiverPanel" .. s, V(.045, .57, .94), C(s * .463, .32, .26), DARKRED)
        for i = 1, 5 do
            b:box("ReceiverVent" .. s .. "_" .. i, V(.05, .29, .045), C(s * .494, .34, -.14 + i * .14), BLACK)
        end
        b:box("SideBadge" .. s, V(.052, .16, .22), C(s * .5, .57, .42), GOLD)
    end
    cylinderZ(b, "RearCap", V(0, .31, 1.04), .64, .23, STEEL)
    cylinderZ(b, "RearStatus", V(0, .31, 1.19), .31, .075, GREEN, NEON)
    b:box("Grip", V(.39, .98, .45), C(0, -.54, .41) * A(-.22, 0, 0), DARKRED)
    b:box("GripHeel", V(.5, .18, .53), C(0, -1.08, .54) * A(-.22, 0, 0), BLACK)
    for i = 1, 5 do
        b:box("GripRib" .. i, V(.43, .044, .47), C(0, -.26 - i * .135, .34 + i * .025) * A(-.22, 0, 0), BLACK)
    end
    b:line("TriggerGuardA", V(0, -.12, -.24), V(0, -.66, -.19), .075, .09, STEEL)
    b:line("TriggerGuardB", V(0, -.66, -.19), V(0, -.72, .23), .075, .09, STEEL)
    b:box("Trigger", V(.07, .23, .075), C(0, -.28, -.02), GOLD)
    b:box("RearSight", V(.29, .15, .12), C(0, .94, .81), BLACK)
    b:box("FrontSight", V(.08, .19, .12), C(0, .83, -.42), STEEL)
    for _, x in ipairs({ -.31, .31 }) do
        for _, y in ipairs({ .07, .56 }) do
            screw(b, "ReceiverScrew" .. x .. y, V(x, y, -.445))
        end
    end
end

local function bfg(b)
    local OLIVE = Color3.fromRGB(80, 105, 57)
    local LIGHTOLIVE = Color3.fromRGB(127, 144, 78)
    b:box("HeavyReceiver", V(1.45, 1.35, 2.15), C(0, .15, .24), OLIVE)
    b:box("UpperArmor", V(1.76, .29, 1.87), C(0, .96, .25), LIGHTOLIVE)
    b:box("LowerArmor", V(1.51, .21, 1.67), C(0, -.63, .31), BLACK)
    for _, s in ipairs({ -1, 1 }) do
        b:box("SideArmor" .. s, V(.2, 1.12, 1.52), C(s * .88, .22, .3) * A(0, 0, s * -.06), OLIVE)
        b:box("SidePlate" .. s, V(.045, .67, .85), C(s * 1.01, .25, .25), LIGHTOLIVE)
        for i = 1, 6 do
            b:box("HeatVent" .. s .. "_" .. i, V(.04, .48, .055), C(s * 1.04, .29, -.38 + i * .17), BLACK)
            b:box("VentInset" .. s .. "_" .. i, V(.045, .19, .021), C(s * 1.065, .29, -.38 + i * .17), GREEN, NEON)
        end
        b:line("Brace" .. s, V(s * .87, -.2, -.45), V(s * .8, .72, .85), .075, .095, STEEL)
    end
    cylinderZ(b, "BarrelHousing", V(0, .16, -1.11), 1.45, .72, BLACK)
    b:ring("MuzzleArmor", C(0, .16, -1.53), .72, .13, LIGHTOLIVE, 20)
    b:ring("ReactorRing", C(0, .16, -1.57), .53, .065, GREEN, 20, NEON)
    cylinderZ(b, "MuzzleCore", V(0, .16, -1.58), .74, .065, BLACK)
    cylinderZ(b, "EmitterCore", V(0, .16, -1.63), .33, .04, GREEN, NEON)
    for i = 0, 5 do
        local t = i * pi / 3
        local p = V(math.cos(t) * .54, .16 + math.sin(t) * .54, -1.21)
        cylinderZ(b, "BarrelSleeve" .. i, p, .16, .55, STEEL)
        cylinderZ(b, "BarrelMouth" .. i, p + V(0, 0, -.3), .1, .04, BLACK)
    end
    b:box("CarryHandle", V(.4, .17, 1.3), C(0, 1.44, .21), BLACK)
    for _, z in ipairs({ -.32, .73 }) do
        b:box("HandlePost" .. z, V(.33, .4, .16), C(0, 1.16, z), STEEL)
    end
    b:box("RearGrip", V(.42, .89, .5), C(0, -.98, .75) * A(-.13, 0, 0), BLACK)
    b:box("FrontGrip", V(.44, .69, .49), C(0, -.86, -.53), BLACK)
    for i = 1, 4 do
        b:box("RearGripRib" .. i, V(.45, .045, .53), C(0, -.64 - i * .16, .7 + i * .02), STEEL)
        b:box("FrontGripRib" .. i, V(.47, .045, .52), C(0, -.6 - i * .13, -.53), STEEL)
    end
    for _, x in ipairs({ -.56, .56 }) do
        for _, y in ipairs({ -.38, .7 }) do
            screw(b, "ArmorBolt" .. x .. y, V(x, y, -.867))
        end
    end
    b:box("RearPowerPack", V(.89, .86, .31), C(0, .15, 1.49), BLACK)
    for i = 1, 4 do
        b:box("RearChargeCell" .. i, V(.12, .52, .055), C(-.33 + i * .14, .15, 1.68), GREEN, NEON)
    end
end

local function omnitrix(b)
    local GRAY = Color3.fromRGB(69, 76, 81)
    -- An open bracelet in the YZ plane, with a watch face on the front.
    for i = 0, 23 do
        local a, c = i * pi / 12, (i + 1) * pi / 12
        local middle = (a + c) / 2
        b:box("BraceletLink" .. i, V(1.15, .24, .33),
            C(0, math.sin(middle) * 1.1, math.cos(middle) * 1.1) * A(-middle, 0, 0), BLACK)
        if i % 3 == 0 then
            b:box("BraceletGreenInset" .. i, V(.7, .045, .13),
                C(0, math.sin(middle) * 1.225, math.cos(middle) * 1.225) * A(-middle, 0, 0), GREEN, NEON)
        end
    end
    cylinderZ(b, "WatchCase", V(0, 0, -1.19), 1.79, .35, GRAY)
    cylinderZ(b, "FaceBacking", V(0, 0, -1.4), 1.48, .095, BLACK)
    b:ring("OuterBezel", C(0, 0, -1.47), .79, .075, STEEL, 20)
    b:ring("GreenDialRing", C(0, 0, -1.5), .65, .055, GREEN, 20, NEON)
    cylinderZ(b, "GreenDial", V(0, 0, -1.49), 1.11, .03, GREEN, PLASTIC)
    -- Solid black hourglass insignia, without a GUI or uploaded image.
    b:triangle("HourglassUpper", V(-.39, .4, -1.515), V(.39, .4, -1.515), V(0, 0, -1.515), BLACK, .045)
    b:triangle("HourglassLower", V(-.39, -.4, -1.515), V(.39, -.4, -1.515), V(0, 0, -1.515), BLACK, .045)
    for i = 0, 3 do
        local t = pi / 4 + i * pi / 2
        b:box("CaseLug" .. i, V(.2, .2, .22), C(math.cos(t) * .86, math.sin(t) * .86, -1.21) * A(0, 0, t), BLACK)
        b:ball("DialStud" .. i, .13, C(math.cos(t) * .77, math.sin(t) * .77, -1.53), GREEN, NEON)
    end
    for _, s in ipairs({ -1, 1 }) do
        b:box("SideButton" .. s, V(.22, .35, .23), C(s * .97, 0, -1.2), STEEL)
        b:box("ButtonFace" .. s, V(.065, .24, .15), C(s * 1.11, 0, -1.2), GREEN)
        b:box("BandSideRail" .. s, V(.09, 1.1, .13), C(s * .56, 0, 1.14), GRAY)
    end
end

local function facemask(b)
    local FRAME = Color3.fromRGB(27, 30, 32)
    local PANEL = Color3.fromRGB(120, 145, 157)
    -- Eye rings remain empty. Clear panels cover cheeks and forehead only.
    for _, s in ipairs({ -1, 1 }) do
        ellipse(b, "EyeRim" .. s .. "_", V(s * .48, .32, -.37), .43, .27, .055, FRAME, 16)
        local panel = b:box("ClearForehead" .. s, V(.9, .36, .09), C(s * .46, .87, -.31) * A(0, s * -.13, 0), PANEL, Enum.Material.Glass)
        panel.Transparency = .56
        local cheek = b:box("ClearCheek" .. s, V(.77, .58, .09), C(s * .62, -.28, -.26) * A(0, s * -.24, s * .15), PANEL, Enum.Material.Glass)
        cheek.Transparency = .52
        b:line("CheekLowerEdge" .. s, V(s * .22, -.61, -.33), V(s * .94, -.47, -.14), .055, .055, FRAME)
        b:line("SideFrame" .. s, V(s * 1.01, -.43, -.12), V(s * 1.05, .82, -.12), .055, .07, FRAME)
        b:line("BrowFrame" .. s, V(s * .08, 1.09, -.33), V(s * .96, 1.07, -.2), .055, .065, FRAME)
        b:box("EarAnchor" .. s, V(.18, .26, .18), C(s * 1.06, .38, .02), FRAME)
        b:line("UpperStrap" .. s, V(s * 1.05, .56, .01), V(s * .77, .58, 1.16), .095, .08, BLACK)
        b:line("LowerStrap" .. s, V(s * 1.02, -.25, -.04), V(s * .79, -.25, 1.16), .085, .07, BLACK)
        b:box("StrapBuckle" .. s, V(.18, .31, .095), C(s * .79, .19, 1.19), STEEL)
        b:box("BuckleInset" .. s, V(.09, .17, .035), C(s * .79, .19, 1.25), BLACK)
        for i = 1, 4 do
            cylinderZ(b, "Vent" .. s .. "_" .. i, V(s * (.45 + i * .095), -.25, -.325), .045, .022, FRAME)
        end
        for _, y in ipairs({ -.4, .85 }) do
            screw(b, "Rivet" .. s .. "_" .. y, V(s * .93, y, -.18), STEEL)
        end
    end
    b:line("NoseBridge", V(-.12, .6, -.4), V(.12, .6, -.4), .09, .12, FRAME)
    b:line("NoseLeft", V(-.15, .58, -.39), V(-.14, -.09, -.64), .06, .07, FRAME)
    b:line("NoseRight", V(.15, .58, -.39), V(.14, -.09, -.64), .06, .07, FRAME)
    b:line("NoseBase", V(-.14, -.09, -.64), V(.14, -.09, -.64), .065, .09, FRAME)
    local nose = b:box("ClearNoseGuard", V(.21, .65, .09), C(0, .23, -.53) * A(.33, 0, 0), PANEL, Enum.Material.Glass)
    nose.Transparency = .57
    b:line("CenterBrow", V(-.12, 1.08, -.34), V(.12, 1.08, -.34), .06, .065, FRAME)
    b:box("BackUpperStrap", V(1.62, .12, .09), C(0, .58, 1.19), BLACK)
    b:box("BackLowerStrap", V(1.62, .1, .08), C(0, -.25, 1.19), BLACK)
    b:box("BackPadding", V(.58, .57, .11), C(0, .15, 1.15), FRAME)
end

local function jellynet(b)
    local PINK = Color3.fromRGB(226, 123, 149)
    local ROPE = Color3.fromRGB(222, 228, 214)
    local radius, cy = 1.14, 1.14
    b:ring("HoopOuter", C(0, cy, 0), radius, .105, Color3.fromRGB(233, 164, 78), 24)
    b:ring("HoopBinding", C(0, cy, .075), radius - .035, .028, ROPE, 24, PLASTIC)
    local function netPoint(x, y)
        local depth = .58 * math.max(0, 1 - (x * x + y * y) / (radius * radius))
        return V(x, cy + y, depth)
    end
    for i = -4, 4 do
        local coord = i * .22
        local limit = math.sqrt(radius * radius - coord * coord) * .97
        for j = 0, 3 do
            local start = -limit + 2 * limit * j / 4
            local finish = -limit + 2 * limit * (j + 1) / 4
            b:line("NetVertical" .. i .. "_" .. j, netPoint(coord, start), netPoint(coord, finish), .025, .025, ROPE, PLASTIC)
            b:line("NetHorizontal" .. i .. "_" .. j, netPoint(start, coord), netPoint(finish, coord), .025, .025, ROPE, PLASTIC)
        end
    end
    b:line("Handle", V(0, -2.12, 0), V(0, .02, 0), .15, .15, PINK, PLASTIC)
    b:line("HandleCore", V(0, -2.27, 0), V(0, -1.68, 0), .185, .185, Color3.fromRGB(117, 79, 60))
    for i = 0, 5 do
        cylinderY(b, "GripWrap" .. i, V(0, -2.2 + i * .095, 0), .207, .038, ROPE, PLASTIC)
    end
    b:line("HoopBraceLeft", V(0, -.16, 0), V(-.34, .08, 0), .065, .065, GOLD)
    b:line("HoopBraceRight", V(0, -.16, 0), V(.34, .08, 0), .065, .065, GOLD)
    b:box("HandleCollar", V(.27, .19, .19), C(0, -.11, 0), GOLD)
    b:ball("HandleEnd", .19, C(0, -2.31, 0), GOLD)
end

local function duelDisk(b)
    local RED = Color3.fromRGB(177, 48, 56)
    local BLUE = Color3.fromRGB(54, 166, 209)
    -- Open wrist cuff, rigid attachment, deck chamber and five separate trays.
    for i = 0, 19 do
        local t = (i + .5) * pi / 10
        b:box("WristCuff" .. i, V(.68, .13, .19),
            C(-1.18, -.29 + math.sin(t) * .57, .3 + math.cos(t) * .57) * A(-t, 0, 0), BLACK)
        if i % 4 == 0 then
            b:box("CuffMetalLink" .. i, V(.48, .05, .16),
                C(-1.18, -.29 + math.sin(t) * .645, .3 + math.cos(t) * .645) * A(-t, 0, 0), STEEL)
        end
    end
    b:box("WristAttachment", V(1.13, .23, 1.37), C(-1.18, .46, .24), BLACK)
    cylinderY(b, "DiskHub", V(-.81, .65, .04), 1.3, .19, WHITE)
    cylinderY(b, "HubInset", V(-.81, .775, .04), .98, .065, RED)
    b:ring("HubRing", C(-.81, .815, .04) * A(pi / 2, 0, 0), .4, .045, STEEL, 16)
    b:box("HubDisplay", V(.43, .045, .23), C(-.81, .835, .04), BLACK)
    for i = 1, 3 do
        b:box("HubIndicator" .. i, V(.07, .012, .12), C(-1.01 + i * .1, .863, .04), BLUE, NEON)
    end
    b:box("DeckChamber", V(.72, .44, .99), C(-1.65, .66, .39) * A(0, -.15, 0), RED)
    b:box("DeckLid", V(.65, .07, .92), C(-1.65, .925, .39) * A(0, -.15, 0), WHITE)
    b:box("DeckOpening", V(.45, .025, .68), C(-1.65, .97, .39) * A(0, -.15, 0), BLACK)
    for i = 1, 4 do
        b:box("StackedCard" .. i, V(.39, .018, .6), C(-1.65, .975 + i * .022, .39) * A(0, -.15, 0), Color3.fromRGB(126, 72, 46))
    end
    b:line("DiskArm", V(-.56, .58, -.25), V(1.72, .58, -.92), .21, .29, STEEL)
    b:line("DiskArmAccent", V(-.5, .76, -.25), V(1.76, .76, -.92), .04, .065, RED)
    local centers = {
        { -.2, -.4, -.3 }, { .37, -.66, -.15 }, { .98, -.81, .02 },
        { 1.59, -.82, .17 }, { 2.16, -.67, .33 },
    }
    for i, data in ipairs(centers) do
        local frame = C(data[1], .8, data[2]) * A(0, data[3], 0)
        b:box("CardTray" .. i, V(.56, .17, .91), frame, WHITE)
        b:box("CardRecess" .. i, V(.42, .024, .74), frame * C(0, .097, 0), BLACK)
        b:box("TrayBottomStripe" .. i, V(.45, .03, .07), frame * C(0, .105, .36), RED)
        for _, x in ipairs({ -.254, .254 }) do
            b:box("TraySideRail" .. i .. "_" .. x, V(.037, .048, .88), frame * C(x, .105, 0), STEEL)
        end
        for _, z in ipairs({ -.424, .424 }) do
            b:box("TrayEndRail" .. i .. "_" .. z, V(.53, .048, .035), frame * C(0, .105, z), STEEL)
        end
        for _, x in ipairs({ -.21, .21 }) do
            b:ball("TrayLamp" .. i .. "_" .. x, .049, frame * C(x, .137, -.34), BLUE, NEON)
        end
        b:box("TraySupport" .. i, V(.2, .18, .37), frame * C(0, -.16, .18), RED)
    end
    for _, x in ipairs({ -1.55, -1.1 }) do
        for _, z in ipairs({ -.24, .71 }) do
            cylinderY(b, "AttachmentBolt" .. x .. "_" .. z, V(x, .607, z), .068, .022, STEEL)
        end
    end
end

local function spinningTop(b, dark)
    local BLUE = Color3.fromRGB(38, 139, 227)
    local CRIMSON = Color3.fromRGB(185, 34, 61)
    local PURPLE = Color3.fromRGB(101, 37, 134)
    local body = dark and BLACK or BLUE
    local trim = dark and GOLD or SILVER
    local accent = dark and CRIMSON or Color3.fromRGB(41, 215, 246)
    local prefix = dark and "Nemesis" or "Pegasus"
    cylinderY(b, prefix .. "EnergyRing", V(0, .39, 0), 2.91, .21, body)
    cylinderY(b, prefix .. "MetalWheel", V(0, .15, 0), 2.69, .23, trim)
    cylinderY(b, prefix .. "LowerDisc", V(0, -.13, 0), 2.11, .27, body)
    cylinderY(b, prefix .. "SpinTrack", V(0, -.46, 0), .85, .42, dark and PURPLE or BLUE)
    cylinderY(b, prefix .. "TipCollar", V(0, -.74, 0), .57, .19, trim)
    b:ball(prefix .. "SpinTip", V(.33, .4, .33), C(0, -.92, 0), accent)
    b:ring(prefix .. "OuterTrim", C(0, .515, 0) * A(pi / 2, 0, 0), 1.35, .065, trim, 24)
    b:ring(prefix .. "InnerTrim", C(0, .6, 0) * A(pi / 2, 0, 0), .87, .055, accent, 20)
    cylinderY(b, prefix .. "FaceBolt", V(0, .65, 0), .77, .17, trim)
    cylinderY(b, prefix .. "Emblem", V(0, .76, 0), .59, .065, body)
    local finCount = dark and 6 or 4
    for i = 0, finCount - 1 do
        local t = i * 2 * pi / finCount
        local frame = C(0, .55, 0) * A(0, t, 0)
        b:wedge(prefix .. "AttackFin" .. i, V(.49, .26, .9), frame * C(.64, 0, -.98) * A(0, -.35, 0), trim)
        b:wedge(prefix .. "FinInset" .. i, V(.24, .085, .69), frame * C(.64, .135, -.93) * A(0, -.35, 0), body)
        b:box(prefix .. "FinEdge" .. i, V(.07, .07, .67), frame * C(.85, .1, -.88) * A(0, -.35, 0), accent)
        b:line(prefix .. "RadialSpoke" .. i, frame * V(.12, .04, -.4), frame * V(.4, .06, -1.09), .055, .07, trim)
        b:ball(prefix .. "Fastener" .. i, .08, frame * C(.34, .1, -.91), BLACK)
        for j = 1, 2 do
            b:box(prefix .. "WheelNotch" .. i .. "_" .. j, V(.12, .14, .25), frame * C(-.28 + j * .2, -.27, -1.17), BLACK)
        end
    end
    for i = 0, 11 do
        local t = i * pi / 6
        b:box(prefix .. "TrackFlute" .. i, V(.08, .29, .07), C(math.cos(t) * .42, -.48, math.sin(t) * .42) * A(0, -t, 0), trim)
    end
    if dark then
        -- Four pointed red crystal facets identify Nemesis without uploaded decals.
        for i = 0, 3 do
            local frame = A(0, i * pi / 2, 0)
            b:triangle("NemesisCrest" .. i, frame * V(0, .91, -.29), frame * V(.2, .91, -.02), frame * V(0, 1.04, .1), CRIMSON, .045)
        end
        b:ball("NemesisCore", V(.14, .13, .14), C(0, .99, 0), Color3.fromRGB(220, 83, 177), NEON)
    else
        -- Relief of a winged horse: muzzle, swept mane and two wings.
        b:box("PegasusHead", V(.13, .055, .29), C(.02, .825, -.05) * A(0, -.36, 0), SILVER)
        b:box("PegasusMuzzle", V(.17, .06, .12), C(-.055, .83, -.2) * A(0, -.36, 0), SILVER)
        b:line("PegasusNeck", V(.08, .83, .07), V(.15, .84, .2), .095, .035, SILVER)
        for _, s in ipairs({ -1, 1 }) do
            for j = 1, 3 do
                b:line("PegasusWing" .. s .. "_" .. j, V(s * .04, .83, .05), V(s * (.12 + j * .04), .84, .17 - j * .08), .025, .025, SILVER)
            end
        end
        b:ball("PegasusEye", .035, C(-.045, .87, -.12), BLACK)
    end
end

local builders = {
    portalgun = portalgun,
    raygun = raygun,
    bfg = bfg,
    omnitrix = omnitrix,
    facemask = facemask,
    jellynet = jellynet,
    duelDisk = duelDisk,
    dueldisk = duelDisk,
    pegasus = function(b) spinningTop(b, false) end,
    nemesis = function(b) spinningTop(b, true) end,
}

function M.build(b, key)
    local build = builders[key]
    if not build then return false end
    build(b)
    return true
end

return M
