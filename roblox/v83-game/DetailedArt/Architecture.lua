local ivory=Color3.fromRGB(240,230,207)
-- Anchored procedural architecture. Gameplay, ownership and prompts stay in their existing modules.
-- All measurements are local studs. Use alignBase=false for existing world anchors.
local M = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local stone = Enum.Material.Slate
local metal = Enum.Material.Metal
local wood = Enum.Material.WoodPlanks
local neon = Enum.Material.Neon
local dark = Color3.fromRGB(24, 20, 40)
local navy = Color3.fromRGB(36, 32, 57)
local slate = Color3.fromRGB(91, 91, 112)
local gold = Color3.fromRGB(200, 151, 58)
local lightGold = Color3.fromRGB(242, 207, 112)
local purple = Color3.fromRGB(133, 63, 228)

local function box(b, name, x, y, z, sx, sy, sz, color, material, solid, rotation)
 return b:box(name, V(sx, sy, sz), C(x, y, z) * (rotation or C()), color, material, solid)
end

local function uprightCylinder(b, name, x, y, z, height, diameter, color, material, solid)
 return b:cylinder(name, V(height, diameter, diameter), C(x, y, z) * A(0, 0, math.pi / 2), color, material, solid)
end

local function rune(b, name, x, y, z, size, color)
 -- A small original angular glyph, raised from its supporting face.
 b:line(name .. "A", V(x - size * .4, y - size * .5, z), V(x, y + size * .5, z), .09, .07, color, neon)
 b:line(name .. "B", V(x, y + size * .5, z), V(x + size * .4, y - size * .5, z), .09, .07, color, neon)
 b:line(name .. "C", V(x - size * .23, y - size * .1, z), V(x + size * .23, y - size * .1, z), .09, .07, color, neon)
end

local function baseBuilding(b)
 local accent = b.options.accent or purple
 local roofHeight = b.options.roofHeight or 14
 assert(roofHeight >= 14, "Base roof must leave at least fourteen studs of clearance")
 local rise = roofHeight - 14
 -- Existing gameplay retains its own floor, pedestals, sign and protection field.
 if b.options.standalone then
  box(b, "SolidFoundation", 0, .5, 0, 48, 1, 48, navy, stone, true)
 end
 box(b, "SolidBackWall", 0, 7.5 + rise / 2, 24, 48, 13 + rise, 1, navy, stone, true)
 for _, side in ipairs({-1, 1}) do
  box(b, "SolidSideWall_" .. side, side * 24, 7.5 + rise / 2, 0, 1, 13 + rise, 48, navy, stone, true)
  box(b, "CornerPier_" .. side, side * 23.5, 8 + rise / 2, 23.5, 2, 14 + rise, 2, slate, stone, true)
  -- Front jambs match the existing gate pillars, leaving the entire central entrance open.
  box(b, "GateJamb_" .. side, side * 20, 7.5 + rise / 2, -23, 4, 13 + rise, 4, navy, stone, true)
  box(b, "GateCap_" .. side, side * 20, 14 + rise, -23, 5, .65, 5, gold, metal)
  box(b, "EntryGlow_" .. side, side * 20, 8, -25.1, .25, 10, .2, accent, neon)
  for index = 1, 4 do
   local z = -15 + (index - 1) * 10
   box(b, "ExteriorButtress_" .. side .. "_" .. index, side * 24.75, 7.5 + rise / 2, z, 1.2, 13 + rise, 1.3, slate, stone)
   box(b, "WallInset_" .. side .. "_" .. index, side * 24.56, 7.5, z + 3.3, .11, 7, 4, dark, metal)
   box(b, "InsetGlow_" .. side .. "_" .. index, side * 24.65, 7.5, z + 3.3, .09, 5, .12, accent, neon)
  end
  box(b, "SideCornice_" .. side, side * 24, 13.6 + rise, 0, 2, .6, 49, gold, metal)
  box(b, "SideRoofGlow_" .. side, side * 25, 15.35 + rise, 0, .15, .12, 49.5, accent, neon)
 end
 -- The slab covers all 48x48 studs. Its underside is exactly options.roofHeight.
 box(b, "SolidFittedRoof", 0, 14.6 + rise, 0, 50, 1.2, 50, dark, metal, true)
 box(b, "SolidRaisedRoof", 0, 15.45 + rise, 0, 45, .5, 45, navy, stone, true)
 box(b, "RoofCrown", 0, 15.85 + rise, 0, 38, .3, 38, slate, metal)
 for _, z in ipairs({-25, 25}) do
  box(b, "RoofFascia_" .. z, 0, 14.8 + rise, z, 50.3, .65, .4, gold, metal)
  box(b, "RoofGlow_" .. z, 0, 15.36 + rise, z, 49.5, .12, .12, accent, neon)
 end
 for _, x in ipairs({-21, 21}) do
  for _, z in ipairs({-21, 21}) do
   uprightCylinder(b, "RoofVent_" .. x .. "_" .. z, x, 16.25 + rise, z, .7, 1.3, gold, metal)
   b:ball("VentGem_" .. x .. "_" .. z, .75, C(x, 16.8 + rise, z), accent, neon)
  end
 end
 for index = -2, 2 do
  box(b, "BackPanel_" .. index, index * 8.5, 7.5, 24.56, 6.5, 7, .12, slate, stone)
  box(b, "BackPanelInset_" .. index, index * 8.5, 7.5, 24.65, 4.9, 5.5, .09, dark, metal)
 end
 -- Small roof-only rune; no additional signs or GUI compete with existing ownership labels.
 rune(b, "EntranceRune", 0, 14.5 + rise, -25.3, 1.7, accent)
end

local function riftPortal(b)
 local plane = C(0, 10, 0) * A(0, math.pi / 2, 0)
 b:ring("OuterStoneRing", plane, 9.15, .6, dark, 32, stone)
 b:ring("GoldRing", C(.15, 10, 0) * A(0, math.pi / 2, 0), 8.75, .28, gold, 32, metal)
 b:ring("PurpleRiftRing", C(-.18, 10, 0) * A(0, math.pi / 2, 0), 8.3, .18, purple, 32, neon)
 b:ring("InnerRiftRing", C(-.22, 10, 0) * A(0, math.pi / 2, 0), 7.75, .1, Color3.fromRGB(213, 132, 255), 24, neon)
 for index = 0, 11 do
  local angle = index * math.pi / 6
  local y, z = 10 + math.sin(angle) * 9.18, math.cos(angle) * 9.18
  local face = C(-.48, y, z) * A(angle, 0, 0)
  b:box("RingKeystone_" .. index, V(.5, .7, 1.1), face, gold, metal)
  local a = V(-.8, y - .32, z - .22)
  local c = V(-.8, y + .32, z)
  local d = V(-.8, y - .32, z + .22)
  b:line("RuneLeft_" .. index, a, c, .085, .085, lightGold, neon)
  b:line("RuneRight_" .. index, c, d, .085, .085, lightGold, neon)
 end
 for _, side in ipairs({-1, 1}) do
  box(b, "PortalPlinth_" .. side, 0, .65, side * 10, 5, 1.3, 4.5, dark, stone)
  box(b, "PortalPylon_" .. side, 0, 3.6, side * 10, 2.5, 4.6, 2.5, slate, stone)
  b:ball("PylonCrystal_" .. side, V(1, 2, 1), C(0, 6.9, side * 10), purple, neon)
  b:line("PylonBrace_" .. side, V(0, 4.3, side * 10), V(0, 7.4, side * 8.7), .6, .6, gold, metal)
 end
 -- Everything remains noncolliding: the conveyor's item passage is unchanged.
end

local function pagodaRoof(b, label, y, width)
 local red = Color3.fromRGB(114, 35, 44)
 local tile = Color3.fromRGB(49, 42, 61)
 box(b, label .. "SolidDeck", 0, y, 0, width, .7, width, tile, stone, true)
 box(b, label .. "RaisedDeck", 0, y + .55, 0, width * .77, .6, width * .77, tile, stone, true)
 box(b, label .. "UpperDeck", 0, y + 1.02, 0, width * .5, .5, width * .5, tile, stone, true)
 for side = 0, 3 do
  local rotation = A(0, side * math.pi / 2, 0)
  local base = C(0, y, 0) * rotation
  b:box(label .. "Eave_" .. side, V(width + .3, .3, .4), base * C(0, 0, -width / 2), red, wood)
  for _, sign in ipairs({-1, 1}) do
   local tip = base * V(sign * width * .5, 1.1, -width * .52)
   b:line(label .. "CurvedTip_" .. side .. "_" .. sign,
    base * V(sign * width * .30, .05, -width * .50), tip, .32, .32, red, wood)
   b:ball(label .. "TipCap_" .. side .. "_" .. sign, .45, C(tip), gold, metal)
  end
  for index = -2, 2 do
   b:line(label .. "RoofRib_" .. side .. "_" .. index,
    base * V(index * width * .12, .75, -width * .31),
    base * V(index * width * .12, .39, -width * .49), .16, .13, slate, stone)
  end
 end
 for side=0,3 do
  local base=C(0,y,0)*A(0,side*math.pi/2,0)
  -- Curved eaves built from overlapping pitched tile strips.
  for strip=0,5 do
   local z=-width*(.18+strip*.065)
   local rise=.95-strip*.16+(strip>=4 and (strip-3)^2*.17 or 0)
   b:box(label.."CurvedRoofStrip"..side..strip,V(width*(.54+strip*.085),.14,width*.08),base*C(0,rise,z)*A(-.14+strip*.065,0,0),tile,stone)
   b:box(label.."GoldenEave"..side..strip,V(width*(.54+strip*.085),.055,.06),base*C(0,rise+.08,z-.2),gold,metal)
  end
 end
end

local function bellTower(b)
 local cedar = Color3.fromRGB(111, 62, 38)
 local pale = Color3.fromRGB(219, 192, 144)
 box(b, "StoneFoundation", 0, 1, 0, 22, 2, 22, slate, stone, true)
 for step = 1, 3 do
  box(b, "FrontStep_" .. step, 0, .35 * step, -12.5 + step * .4, 10, .7, 1.5, slate, stone, true)
 end
 for tier = 1, 3 do
  local width = 17 - (tier - 1) * 3
  local y = 2 + (tier - 1) * 9.5
  local corner = width / 2 - .75
  box(b, "TierFloor_" .. tier, 0, y + .25, 0, width, .5, width, cedar, wood, true)
  for _, x in ipairs({-corner, corner}) do
   for _, z in ipairs({-corner, corner}) do
    box(b, "TimberPost_" .. tier .. "_" .. x .. "_" .. z, x, y + 4.2, z, .9, 8, .9, cedar, wood, true)
    box(b, "PostCollar_" .. tier .. "_" .. x .. "_" .. z, x, y + 1, z, 1.2, .5, 1.2, gold, metal)
   end
  end
  for side = 0, 3 do
   local frame = C(0, y, 0) * A(0, side * math.pi / 2, 0)
   b:box("CrossBeam_" .. tier .. "_" .. side, V(width, .65, .9), frame * C(0, 7.4, -corner), cedar, wood)
   if tier < 3 then
    b:box("PlasterPanel_" .. tier .. "_" .. side, V(width - 2.4, 3.8, .4), frame * C(0, 4.3, -corner), pale, Enum.Material.SmoothPlastic)
    b:box("WindowInset_" .. tier .. "_" .. side, V(4, 2.8, .15), frame * C(0, 4.5, -corner - .28), dark, metal)
    for bar = -1, 1 do
     b:box("WindowBar_" .. tier .. "_" .. side .. "_" .. bar, V(.14, 2.9, .16), frame * C(bar * 1.25, 4.5, -corner - .39), cedar, wood)
    end
    b:box("WindowSill_" .. tier .. "_" .. side, V(4.4, .2, .8), frame * C(0, 3, -corner - .4), cedar, wood)
   end
  end
  pagodaRoof(b, "PagodaRoof_" .. tier, y + 8.2, width + 5)
 end
 b:line("BellHanger", V(0, 27.8, 0), V(0, 25.4, 0), .16, .16, dark, metal)
 uprightCylinder(b, "BellCrown", 0, 25.3, 0, 1, 2.4, gold, metal)
 uprightCylinder(b, "BellBody", 0, 23.6, 0, 2.8, 3.7, Color3.fromRGB(159,104,50), metal)
 uprightCylinder(b, "BellLip", 0, 22.1, 0, .45, 4.3, lightGold, metal)
 uprightCylinder(b, "BellDarkInterior", 0, 21.86, 0, .05, 3.5, dark, metal)
 b:ball("BellClapper", .75, C(0, 21.45, 0), gold, metal)
 box(b, "FinialStem", 0, 31.6, 0, .5, 2.4, .5, gold, metal)
 b:ball("Finial", 1.1, C(0, 33, 0), gold, metal)
end

local function squidHouse(b)
 local rock = Color3.fromRGB(95, 119, 132)
 local highlight = Color3.fromRGB(125, 148, 157)
 local window = Color3.fromRGB(34, 91, 125)
 box(b, "HousePlinth", 0, .65, 0, 19, 1.3, 18, slate, stone, true)
 uprightCylinder(b, "StoneHead", 0, 16.5, 0, 31, 14, rock, stone, true)
 box(b, "Forehead", 0, 28.5, 0, 13.8, 6.2, 11.5, rock, stone, true)
 box(b, "CrownCap", 0, 32, 0, 12.5, 1.4, 11, highlight, stone)
 for _, side in ipairs({-1, 1}) do
  box(b, "Ear_" .. side, side * 7.4, 23.6, 0, 2.3, 7, 4.5, highlight, stone, true)
  box(b, "Brow_" .. side, side * 3.55, 25.1, -6.5, 5.6, 1.5, 2.3, highlight, stone, true, A(0, 0, side * -.10))
  b:ball("EyeStoneSocket_" .. side, V(4.3, 5.4, 1.5), C(side * 3.35, 21.55, -6.48), highlight, stone)
  b:ball("EyeGlass_" .. side, V(3.1, 4.1, .45), C(side * 3.35, 21.55, -7.29), window, Enum.Material.Glass)
  box(b, "EyeMullion_" .. side, side * 3.35, 21.55, -7.6, .18, 3.7, .1, gold, metal)
  box(b, "EyeCrossbar_" .. side, side * 3.35, 21.55, -7.6, 2.9, .18, .1, gold, metal)
 end
 box(b, "LongStoneNose", 0, 18.3, -7.7, 3.1, 11.5, 3.5, rock, stone, true)
 b:ball("NoseTip", V(3.2, 2.8, 3.6), C(0, 12.9, -7.7), highlight, stone, true)
 box(b, "MouthStoneRidge", 0, 10.4, -6.85, 8, .6, .65, highlight, stone)
 for _, side in ipairs({-1, 1}) do
  b:line("CheekRidge_" .. side, V(side * 5.8, 18.6, -4.8), V(side * 5.4, 12.1, -4.9), .35, .35, highlight, stone)
  b:line("BrowCrease_" .. side, V(side * 1.8, 27.2, -5.91), V(side * 5.8, 27.8, -5.91), .1, .06, slate, stone)
  b:line("StoneCrackA_" .. side, V(side * 5.4, 29.8, -5.92), V(side * 4.9, 28.4, -5.92), .11, .07, slate, stone)
  b:line("StoneCrackB_" .. side, V(side * 4.9, 28.4, -5.92), V(side * 5.1, 27.3, -5.92), .11, .07, slate, stone)
 end
 box(b, "DoorInset", 0, 4.6, -7.07, 4.4, 7, .2, dark, wood)
 for _, x in ipairs({-2.55, 2.55}) do
  box(b, "DoorFrame_" .. x, x, 4.6, -7.2, .55, 7.8, .7, highlight, stone)
 end
 box(b, "DoorLintel", 0, 8.55, -7.2, 5.6, .7, .8, highlight, stone)
 for seam = -1, 1 do
  box(b, "DoorPlank_" .. seam, seam * 1.15, 4.6, -7.22, .06, 6.6, .03, gold, metal)
 end
 b:ball("DoorKnob", .4, C(1.55, 4.3, -7.45), gold, metal)
 for step = 1, 3 do
  box(b, "DoorStep_" .. step, 0, .32 * step, -10.5 + .6 * step, 7, .64, 2, slate, stone, true)
 end
 for index = 1, 9 do
  local angle = index * math.pi * 2 / 9
  box(b, "StoneCourse_" .. index, math.cos(angle) * 6.6, 10 + index % 3 * 4, math.sin(angle) * 6.6, 1.5, .15, .3, highlight, stone, false, A(0, -angle, 0))
 end
 for index = 1, 5 do
  local angle = .22 + index * .19
  local x = math.sin(angle) * 7.08
  local z = -math.cos(angle) * 7.08
  for _, side in ipairs({-1, 1}) do
   b:line("LowStoneSeam_" .. side .. "_" .. index,
    V(side * x, 2.4 + index % 2 * 1.4, z), V(side * x, 4.1 + index % 2 * 1.4, z), .085, .05, slate, stone)
  end
 end
end

local function cardFrame(b, key, color)
 box(b, key .. "Plinth", 0, 1, 0, 29, 2, 8, dark, stone, true)
 box(b, key .. "Backing", 0, 20, 0, 24, 36, 1.5, color, metal)
 box(b, key .. "InnerPanel", 0, 22, - .85, 20.5, 26.8, .2, dark, stone)
 for _, x in ipairs({-11.45, 11.45}) do
  box(b, key .. "FrameSide_" .. x, x, 20, -.96, .65, 34.8, .5, gold, metal)
 end
 for _, y in ipairs({2.9, 37.1}) do
  box(b, key .. "FrameEnd_" .. y, 0, y, -.96, 23.2, .65, .5, gold, metal)
 end
 box(b, key .. "TitleBand", 0, 35.8, -1.15, 18.5, .8, .2, lightGold, metal)
 box(b, key .. "LowerTablet", 0, 6.1, -1.02, 20, 4.4, .3, Color3.fromRGB(149, 120, 74), stone)
 for index = -3, 3 do
  rune(b, key .. "Glyph_" .. index, index * 2.4, 6.1, -1.24, 1.4, lightGold)
 end
 for _, x in ipairs({-11, 11}) do
  for _, y in ipairs({3.4, 36.6}) do
   b:ball(key .. "CornerGem_" .. x .. "_" .. y, .8, C(x, y, -1.4), color, neon)
  end
 end
end

local function godObelisk(b)
 local blue = Color3.fromRGB(48, 87, 163)
 local lightBlue = Color3.fromRGB(77, 142, 194)
 cardFrame(b, "Obelisk", blue)
 box(b, "TitanTorso", 0, 22, -2.3, 7.5, 9, 2.3, blue, metal)
 box(b, "ChestPlate", 0, 24, -3.55, 7.2, 3.4, .5, lightBlue, metal)
 box(b, "AbdomenPlate", 0, 20, -3.55, 4.5, 3.4, .4, blue, metal)
 box(b, "TitanWaist", 0, 17.3, -2.3, 5.3, 1.2, 2.3, gold, metal)
 box(b, "TitanHead", 0, 29.4, -2.5, 4.4, 4.8, 2.4, blue, metal)
 box(b, "FaceMask", 0, 29.3, -3.8, 2.8, 2.3, .4, lightBlue, metal)
 box(b, "Brow", 0, 30.3, -4.1, 3.5, .4, .3, gold, metal)
 for _, side in ipairs({-1, 1}) do
  b:ball("Eye_" .. side, V(.6, .3, .25), C(side * .85, 29.8, -4.15), Color3.fromRGB(231, 51, 83), neon)
  b:wedge("HeadHorn_" .. side, V(1.4, 4.3, 1.2), C(side * 2.2, 32.1, -2.1) * A(0, 0, side * -.3), lightBlue, metal)
  box(b, "ShoulderArmor_" .. side, side * 5.4, 25.7, -2.1, 3.5, 3.3, 2.8, lightBlue, metal, false, A(0, 0, side * -.2))
  box(b, "UpperArm_" .. side, side * 6.8, 22.5, -2.1, 2.6, 4.5, 2.2, blue, metal, false, A(0, 0, side * -.16))
  box(b, "Gauntlet_" .. side, side * 7.5, 18.8, -2.5, 3, 3.5, 3, lightBlue, metal)
  for finger = 1, 3 do
   box(b, "Knuckle_" .. side .. "_" .. finger, side * 7.5 + (finger - 2) * .75, 17.2, -4.1, .6, 1.2, .4, gold, metal)
  end
  box(b, "LegArmor_" .. side, side * 1.75, 13.6, -2.3, 2.7, 6.3, 2.7, blue, metal)
  box(b, "KneePlate_" .. side, side * 1.75, 14.2, -3.8, 2.2, 2, .6, lightBlue, metal)
  box(b, "TitanFoot_" .. side, side * 1.8, 10.2, -3, 3.1, 1.3, 4, lightBlue, metal)
 end
 for index = 1, 3 do
  box(b, "AbdominalBand_" .. index, 0, 18.4 + index * 1.1, -3.84, 4.4, .14, .08, gold, metal)
 end
 for index=1,6 do
  local y=18.3+index*1.05
  for _,side in ipairs({-1,1}) do
   b:wedge("RibArmor_"..side..index,V(1.9,.75,.55),C(side*1.8,y,-3.85)*A(0,0,side*.15),index%2==0 and blue or lightBlue,metal)
  end
 end
 b:wedge("AngularJaw",V(2.7,1.1,.8),C(0,28.1,-4),lightBlue,metal)
 box(b,"ObeliskMouth",0,28.5,-4.25,1.8,.14,.12,dark,metal)
 for tooth=-2,2 do box(b,"TitanTooth"..tooth,tooth*.3,28.4,-4.35,.15,.25,.07,ivory,metal) end
 for _,side in ipairs({-1,1}) do
  b:wedge("FaceCheek"..side,V(.8,1.6,.5),C(side*1.4,29,-4)*A(0,0,side*.2),blue,metal)
  for spike=1,3 do b:wedge("ShoulderSpike"..side..spike,V(.65,2.4,.65),C(side*(4.3+spike*.6),27.7,-2.2)*A(0,0,-side*.4),lightBlue,metal) end
 end
end

local function godRa(b)
 cardFrame(b, "Ra", gold)
 b:ball("SunDisk", V(9, 9, .3), C(0, 25, -1.1), Color3.fromRGB(115, 74, 30), metal)
 b:ring("SunHalo", C(0, 25, -1.4), 4.7, .18, lightGold, 24, neon)
 b:ball("BirdTorso", V(5, 8, 2.8), C(0, 21, -2.9), gold, metal)
 b:ball("BirdNeck", V(2.2, 5.2, 2), C(0, 26.3, -3.2), lightGold, metal)
 box(b, "BirdHead", 0, 29.5, -3.6, 2.8, 2.4, 2, gold, metal)
 b:wedge("GoldenBeak", V(1.2, 1.4, 2.7), C(0, 29, -5), lightGold, metal)
 for _, side in ipairs({-1, 1}) do
  b:ball("Eye_" .. side, V(.4, .3, .3), C(side * 1.25, 29.8, -4.4), Color3.fromRGB(231, 82, 45), neon)
  b:line("HeadCrest_" .. side, V(side * .8, 30.3, -3), V(side * 1.6, 33.6, -2.5), .5, .5, lightGold, metal)
  b:triangle("WingMembrane_" .. side, V(side * 1.8, 25, -2), V(side * 9.8, 30.5, -2), V(side * 8.8, 20, -2), gold, .4, metal)
  for feather = 0, 5 do
   local start = V(side * (2.1 + feather * .75), 25.8 + feather * .5, -2.65)
   local finish = V(side * (5 + feather * .9), 15.8 + feather * 1.2, -2.65)
   b:line("WingFeather_" .. side .. "_" .. feather, start, finish, .6, .25, feather % 2 == 0 and lightGold or gold, metal)
  end
  b:line("BirdLeg_" .. side, V(side * 1.2, 18, -2.7), V(side * 2.1, 12.5, -3), .6, .6, gold, metal)
  for claw = -1, 1 do
   b:line("Claw_" .. side .. "_" .. claw, V(side * 2.1, 12.5, -3), V(side * 2.1 + claw * .6, 11.4, -3.5), .2, .2, lightGold, metal)
  end
 end
 for index = -1, 1 do
  b:line("TailFeather_" .. index, V(index * .6, 18.3, -2.1), V(index * 1.5, 10, -2), .5, .2, gold, metal)
 end
 for band=1,7 do
  local y=19+band*.8
  b:box("RaChestSegment"..band,V(3.6-band*.13,.45,.3),C(0,y,-4.25),band%2==0 and lightGold or gold,metal)
 end
 b:wedge("RaJawArmor",V(1.7,.65,.8),C(0,28.6,-4.5),gold,metal)
 b:line("RaBeakSeam",V(0,28.9,-5.6),V(0,29.1,-4.6),.07,.07,dark,metal)
 for _,side in ipairs({-1,1}) do
  b:wedge("RaBrow"..side,V(.75,.28,.65),C(side*.85,30.2,-4.6)*A(0,0,side*-.25),lightGold,metal)
  for feather=1,8 do
   b:line("RaWingRib"..side..feather,V(side*2,25,-3),V(side*(3+feather*.85),19+feather*.85,-3),.17,.1,lightGold,metal)
   b:wedge("RaFeatherTip"..side..feather,V(.5,2.5,.2),C(side*(3+feather*.85),18+feather*.85,-3)*A(0,0,-side*.3),gold,metal)
  end
 end
end

local function blackLotus(b)
 local petal = Color3.fromRGB(27, 19, 42)
 local edge = Color3.fromRGB(70, 41, 102)
 local green = Color3.fromRGB(44, 76, 61)
 uprightCylinder(b, "LotusPedestal", 0, .8, 0, 1.6, 12, dark, stone, true)
 b:ring("LotusPedestalRim", C(0, 1.64, 0) * A(math.pi / 2, 0, 0), 5.4, .14, gold, 24, metal)
 for index = 0, 7 do
  local angle = index * math.pi / 4
  b:ball("LotusLeaf_" .. index, V(2.7, .4, 5), C(math.sin(angle) * 2.4, 1.8, math.cos(angle) * 2.4) * A(0, angle, 0), green, Enum.Material.SmoothPlastic)
 end
 for layer = 1, 3 do
  local amount = 10 - layer
  local radius = 3.3 - layer * .72
  for index = 0, amount - 1 do
   local angle = (index + layer * .35) * math.pi * 2 / amount
   b:ball("DarkPetal_" .. layer .. "_" .. index, V(1.65, .6, 4.6 - layer * .6),
    C(math.sin(angle) * radius, 1.8 + layer * .55, math.cos(angle) * radius) * A(0, angle, 0) * A(.15 + layer * .18, 0, 0),
    index % 2 == 0 and petal or edge, Enum.Material.SmoothPlastic)
  end
 end
 uprightCylinder(b, "LotusHeart", 0, 3.7, 0, .45, 1.25, gold, metal)
 for index = 0, 5 do
  local angle = index * math.pi / 3
  b:ball("LotusStamen_" .. index, .2, C(math.cos(angle) * .38, 4.1, math.sin(angle) * .38), lightGold, neon)
 end
end

local function pancakes(b)
 local crust = Color3.fromRGB(179, 113, 50)
 local crumb = Color3.fromRGB(223, 173, 101)
 local syrup = Color3.fromRGB(100, 51, 22)
 uprightCylinder(b, "ServingPlate", 0, .3, 0, .6, 14, Color3.fromRGB(231, 222, 208), Enum.Material.SmoothPlastic, true)
 for index = 1, 6 do
  local y = .65 + (index - 1) * .7
  uprightCylinder(b, "PancakeCrust_" .. index, 0, y + .3, 0, .6, 10.5, crust, Enum.Material.SmoothPlastic)
  uprightCylinder(b, "PancakeTop_" .. index, 0, y + .61, 0, .06, 10.15, crumb, Enum.Material.SmoothPlastic)
 end
 uprightCylinder(b, "SyrupPool", 0, 4.84, 0, .12, 8.2, syrup, Enum.Material.SmoothPlastic)
 for index = 0, 5 do
  local angle = index * math.pi / 3 + .3
  b:ball("SyrupDrip_" .. index, V(.6, 1 + index % 3 * .5, .5), C(math.cos(angle) * 5.05, 4.15 - index % 3 * .25, math.sin(angle) * 5.05), syrup, Enum.Material.SmoothPlastic)
 end
 box(b, "ButterPat", -.5, 5.2, .25, 2.3, .55, 1.9, Color3.fromRGB(255, 225, 115), Enum.Material.SmoothPlastic, false, A(0, .3, 0))
 box(b, "ButterMelt", -.5, 4.94, .25, 3, .09, 2.6, Color3.fromRGB(246, 211, 91), Enum.Material.SmoothPlastic, false, A(0, .3, 0))
 for index = 1, 5 do
  b:ball("Blueberry_" .. index, .65, C(2.3 + index % 2 * .7, 5, -1.9 + index * .6), Color3.fromRGB(57, 48, 105), Enum.Material.SmoothPlastic)
 end
end

local function tournamentPillar(b)
 local concrete = Color3.fromRGB(136, 139, 156)
 box(b, "PillarFoundation", 0, .8, 0, 8, 1.6, 8, dark, stone, true)
 uprightCylinder(b, "LowerPlinth", 0, 2.1, 0, 1.1, 6.3, concrete, stone, true)
 uprightCylinder(b, "ColumnCore", 0, 16.8, 0, 28, 4.2, concrete, stone, true)
 for index = 0, 9 do
  local angle = index * math.pi / 5
  uprightCylinder(b, "ColumnFlute_" .. index, math.sin(angle) * 2.02, 16.8, math.cos(angle) * 2.02, 27.4, .37, slate, stone)
 end
 for _, y in ipairs({3.1, 11, 22.5, 30.4}) do
  uprightCylinder(b, "ColumnBand_" .. y, 0, y, 0, .45, 4.9, gold, metal)
 end
 uprightCylinder(b, "CapitalLower", 0, 31.2, 0, 1.2, 5.8, concrete, stone, true)
 box(b, "CapitalTop", 0, 32.2, 0, 7, .85, 7, concrete, stone, true)
 box(b, "CrownInset", 0, 32.8, 0, 5.7, .4, 5.7, dark, stone)
 b:ball("ArenaCrystal", V(1.5, 2.8, 1.5), C(0, 34.2, 0), purple, neon)
 for side = 0, 3 do
  local frame = C(0, 31.5, 0) * A(0, side * math.pi / 2, 0)
  b:box("CapitalInset_" .. side, V(2.4, .35, .1), frame * C(0, 0, -2.99), gold, metal)
 end
end

local function mtgCard(b)
 local jade = Color3.fromRGB(48, 94, 78)
 local black = Color3.fromRGB(26, 21, 35)
 box(b, "ArchiveCardFoot", 0, 1, 0, 34, 2, 9, dark, stone, true)
 box(b, "ArchiveCard", 0, 25, 0, 30, 46, 1.2, gold, metal)
 box(b, "JadeInset", 0, 25, -.71, 28.3, 44, .2, jade, metal)
 box(b, "DarkArtPanel", 0, 28.6, -.9, 24.5, 29, .2, black, stone)
 box(b, "TitlePlaque", 0, 45.4, -.95, 25, 2.5, .25, lightGold, metal)
 box(b, "RulesTablet", 0, 8.6, -.95, 24.5, 8.2, .25, Color3.fromRGB(177, 156, 112), stone)
 for _, x in ipairs({-14.35, 14.35}) do
  box(b, "ArchiveBorder_" .. x, x, 25, -.97, .34, 44.5, .34, lightGold, metal)
 end
 for _, y in ipairs({3.2, 46.8}) do
  box(b, "ArchiveBorder_" .. y, 0, y, -.97, 28.7, .34, .34, lightGold, metal)
 end
 -- Raised midnight lotus art replaces text-only scenery and requires no imported texture.
 for layer = 1, 3 do
  local amount = 10 - layer
  local radius = 5.8 - layer * 1.25
  for index = 0, amount - 1 do
   local angle = (index + layer * .28) * math.pi * 2 / amount
   local p = C(math.sin(angle) * radius, 29 + math.cos(angle) * radius, -1.6 - layer * .25) * A(0, 0, -angle)
   b:ball("ArchiveLotusPetal_" .. layer .. "_" .. index, V(2.6, 7.8 - layer, .75), p,
    index % 2 == 0 and Color3.fromRGB(51, 31, 75) or Color3.fromRGB(82, 48, 112), metal)
  end
 end
 b:ball("ArchiveLotusHeart", V(2.3, 2.3, .55), C(0, 29, -2.9), gold, metal)
 b:ring("ArchiveArtHalo", C(0, 29, -1.16), 10, .12, gold, 28, metal)
 for index = -3, 3 do rune(b, "ArchiveGlyph_" .. index, index * 3.2, 8.8, -1.15, 1.6, black) end
 for index = -2, 2 do
  b:ball("TitleGem_" .. index, V(.7, .7, .2), C(index * 2.6, 45.4, -1.15), jade, metal)
 end
end

local function clashTower(b)
 local blue = Color3.fromRGB(49, 111, 199)
 local pale = Color3.fromRGB(164, 164, 176)
 uprightCylinder(b, "TowerFoot", 0, 1, 0, 2, 18, dark, stone, true)
 uprightCylinder(b, "CastleTower", 0, 15, 0, 26, 13, pale, stone, true)
 for course = 1, 6 do
  local y = 2 + course * 4
  b:ring("MasonryCourse_" .. course, C(0, y, 0) * A(math.pi / 2, 0, 0), 6.56, .13, slate, 16, stone)
 end
 uprightCylinder(b, "TowerCapital", 0, 28.5, 0, 1.4, 16, slate, stone, true)
 for index = 0, 7 do
  local angle = index * math.pi / 4
  box(b, "SolidBattlement_" .. index, math.sin(angle) * 7, 30.4, math.cos(angle) * 7, 2.3, 3.1, 2.3, pale, stone, true, A(0, angle, 0))
 end
 uprightCylinder(b, "BlueRoof", 0, 30, 0, 1.1, 11.5, blue, metal, true)
 for index = 0, 3 do
  local angle = index * math.pi / 2
  local frame = C(0, 0, 0) * A(0, angle, 0)
  b:box("ArrowSlit_" .. index, V(.8, 4.5, .15), frame * C(0, 18.2, -6.56), dark, metal)
  b:box("Banner_" .. index, V(3.8, 7, .2), frame * C(0, 9.5, -6.64), blue, Enum.Material.Fabric)
  b:box("CrownBand_" .. index, V(2.2, .6, .24), frame * C(0, 10, -6.81), gold, metal)
  for point = -1, 1 do
   b:wedge("CrownPoint_" .. index .. "_" .. point, V(.65, 1.2 + (point == 0 and .45 or 0), .25),
    frame * C(point * .75, 10.7, -6.81), lightGold, metal)
  end
 end
 box(b, "FlagPole", 0, 34.2, 0, .3, 7, .3, gold, metal)
 box(b, "Flag", 2.1, 36, 0, 4, 2.1, .16, blue, Enum.Material.Fabric)
 b:ball("FlagFinial", .65, C(0, 38, 0), lightGold, metal)
 -- Large crown crests above the walls, stone joints and load-bearing timber brackets.
 for side=0,3 do
  local cf=C()*A(0,side*math.pi/2,0)
  b:box("LargeCrownBase"..side,V(5.4,1.1,.5),cf*C(0,23,-6.9),gold,metal)
  for point=-1,1 do b:wedge("LargeCrownPoint"..side..point,V(1.6,2.6+(point==0 and .7 or 0),.5),cf*C(point*1.8,24.7,-6.9),lightGold,metal) end
  for course=1,6 do
   b:box("StoneJoint"..side..course,V(.13,3.7,.1),cf*C(course%2==0 and 2 or -2,3+course*3.7,-6.58),dark,stone)
  end
  for _,x in ipairs({-5.3,5.3}) do
   b:line("WoodenTowerSupport"..side..x,cf*V(x,18,-6),cf*V(x,27,-8),.55,.55,Color3.fromRGB(112,72,38),wood)
  end
  b:box("GoldCapitalTrim"..side,V(12,.25,.25),cf*C(0,27,-7.6),gold,metal)
 end
end

local function skyFlower(b)
 local color = b.options.accent or Color3.fromRGB(220, 161, 233)
 local function point(t)
  local radius = 11 + 5 * math.cos(5 * t)
  return V(math.cos(t) * radius, math.sin(t) * radius, 0)
 end
 for index = 0, 59 do
  b:line("PetalOutline_" .. index, point(index * math.pi / 30), point((index + 1) * math.pi / 30), .55, .22, color, neon)
 end
 b:ring("FlowerCenter", C(), 2.05, .45, color, 20, neon)
 for index = 0, 4 do
  local angle = index * math.pi * 2 / 5
  b:ball("PetalAccent_" .. index, V(.65, .65, .22), C(math.cos(angle) * 13.3, math.sin(angle) * 13.3, -.2), lightGold, neon)
 end
end

local builders = {
 baseBuilding = baseBuilding, riftPortal = riftPortal, bellTower = bellTower,
 squidHouse = squidHouse, godObelisk = godObelisk,
 godRa = godRa, blackLotus = blackLotus, pancakes = pancakes,
 tournamentPillar = tournamentPillar,
 mtgCard = mtgCard, clashTower = clashTower, skyFlower = skyFlower,
}

function M.build(b, key)
 local build = builders[key]
 if not build then return false end
 build(b)
 return true
end

return M

