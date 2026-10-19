-- Detailed original native geometry: no external meshes, paid services, or textures.
-- The host supplies invisible structural collision proxies where required.
local M = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local METAL, WOOD, STONE = Enum.Material.Metal, Enum.Material.WoodPlanks, Enum.Material.Slate
local PLASTIC, NEON, FABRIC = Enum.Material.SmoothPlastic, Enum.Material.Neon, Enum.Material.Fabric
local charcoal = Color3.fromRGB(27, 32, 43)
local steel = Color3.fromRGB(104, 123, 142)
local lightSteel = Color3.fromRGB(183, 200, 207)
local gold = Color3.fromRGB(218, 162, 46)
local paleGold = Color3.fromRGB(255, 218, 112)
local blue = Color3.fromRGB(29, 101, 208)
local lightBlue = Color3.fromRGB(71, 184, 255)
local cedar = Color3.fromRGB(130, 63, 34)
local redWood = Color3.fromRGB(151, 40, 35)
local ivory = Color3.fromRGB(239, 218, 175)

local function box(b, name, x, y, z, sx, sy, sz, color, material, cf)
 return b:box(name, V(sx, sy, sz), (cf or C()) * C(x, y, z), color, material)
end
local function cyl(b, name, x, y, z, height, diameter, color, material, cf)
 return b:cylinder(name, V(height, diameter, diameter), (cf or C()) * C(x, y, z) * A(0, 0, math.pi / 2), color, material)
end
local function line(b, name, a, c, thickness, color, material, cf, depth)
 cf = cf or C()
 return b:line(name, cf * a, cf * c, thickness, depth or thickness, color, material)
end
local function tri(b, name, a, c, d, color, material, cf, depth)
 cf = cf or C()
 b:triangle(name, cf * a, cf * c, cf * d, color, depth or .08, material)
end
local function quad(b, name, a, c, d, e, color, material, cf, depth)
 tri(b, name .. "A", a, c, d, color, material, cf, depth)
 tri(b, name .. "B", a, d, e, color, material, cf, depth)
end

local function detailedWorkbench(b)
 local oak = Color3.fromRGB(145, 96, 51)
 local oakLight = Color3.fromRGB(185, 135, 76)
 local handle = Color3.fromRGB(62, 44, 32)
 -- Five separate worn-looking top boards and a dark rounded-off perimeter.
 box(b, "SteelApron", 0, 3.35, 0, 10.2, .48, 4, charcoal, METAL)
 for index = 0, 4 do
  box(b, "OakWorktopBoard_" .. index, 0, 3.73, -1.64 + index * .82, 10.5, .38, .78,
   index % 2 == 0 and oakLight or oak, WOOD)
 end
 for _, side in ipairs({-1, 1}) do
  box(b, "EndCap_" .. side, side * 5.25, 3.66, 0, .18, .5, 4.22, steel, METAL)
  for _, z in ipairs({-1.6, 1.6}) do
   box(b, "BenchLeg_" .. side .. "_" .. z, side * 4.5, 1.7, z, .44, 3.1, .44, charcoal, METAL)
   box(b, "RubberFoot_" .. side .. "_" .. z, side * 4.5, .16, z, .8, .24, .8, charcoal, PLASTIC)
   box(b, "LegCollar_" .. side .. "_" .. z, side * 4.5, 2.7, z, .56, .32, .56, steel, METAL)
   cyl(b, "ApronBolt_" .. side .. "_" .. z, side * 4.7, 3.97, z, .08, .16, lightSteel, METAL)
  end
  line(b, "DiagonalLegBrace_" .. side, V(side * 4.5, .6, -1.6), V(side * 4.5, 2.85, 1.6), .21, steel, METAL)
 end
 box(b, "LowerShelfFrame", 0, .86, 0, 9, .26, 3.4, charcoal, METAL)
 for index = -2, 2 do
  box(b, "LowerShelfSlat_" .. index, 0, 1.06, index * .62, 8.7, .16, .54, oak, WOOD)
 end
 -- Open shelves and individually outlined drawers make the underside readable.
 box(b, "DrawerCabinet", -2.8, 2.37, .1, 2.9, 1.65, 3.1, charcoal, METAL)
 for row = 0, 2 do
  local y = 1.86 + row * .52
  box(b, "InsetDrawer_" .. row, -2.8, y, -1.51, 2.62, .43, .16, steel, METAL)
  box(b, "DrawerLabel_" .. row, -3.45, y, -1.61, .4, .15, .035, ivory, PLASTIC)
  box(b, "DrawerHandle_" .. row, -2.55, y, -1.7, .95, .09, .18, lightSteel, METAL)
 end
 -- Back tool rack: two posts, slatted backing, organized tools, raised hooks.
 for _, x in ipairs({-4.65, 4.65}) do
  box(b, "ToolRackPost_" .. x, x, 4.65, 1.65, .22, 2.4, .26, charcoal, METAL)
 end
 box(b, "ToolRackFrame", 0, 5.15, 1.72, 9.6, 1.65, .22, steel, METAL)
 box(b, "ToolRackInset", 0, 5.15, 1.55, 9.1, 1.28, .14, charcoal, METAL)
 for row = 0, 2 do
  for index = -5, 5 do
   box(b, "PegHole_" .. row .. "_" .. index, index * .76, 4.75 + row * .37, 1.46, .1, .1, .035, steel, METAL)
  end
 end
 for index = 0, 2 do
  local x = -3.35 + index * .85
  line(b, "WrenchStem_" .. index, V(x, 4.5, 1.29), V(x, 5.48, 1.29), .13, lightSteel, METAL)
  line(b, "WrenchJawLeft_" .. index, V(x, 5.48, 1.29), V(x - .21, 5.72, 1.29), .13, lightSteel, METAL)
  line(b, "WrenchJawRight_" .. index, V(x, 5.48, 1.29), V(x + .21, 5.72, 1.29), .13, lightSteel, METAL)
  b:ring("WrenchClosedEnd_" .. index, C(x, 4.5, 1.29), .15, .07, lightSteel, 8, METAL)
 end
 for index = 0, 2 do
  local x = .65 + index * .7
  box(b, "DriverHandle_" .. index, x, 4.81, 1.29, .21, .58, .22, index == 1 and blue or redWood, PLASTIC)
  box(b, "DriverShaft_" .. index, x, 5.37, 1.29, .07, .58, .07, lightSteel, METAL)
  box(b, "DriverTip_" .. index, x, 5.68, 1.29, .12, .1, .04, steel, METAL)
 end
 line(b, "HammerHandle", V(3.4, 4.48, 1.25), V(3.4, 5.5, 1.25), .16, oakLight, WOOD)
 box(b, "HammerHead", 3.4, 5.58, 1.25, .86, .28, .32, steel, METAL)
 -- A working-looking bench vise, rotated jaws and a long screw handle.
 box(b, "ViseMount", 3.6, 4.05, -1.15, 1.45, .24, 1.1, blue, METAL)
 box(b, "ViseBody", 3.6, 4.4, -1.15, 1.14, .5, .86, blue, METAL)
 for _, x in ipairs({3.15, 4.05}) do
  box(b, "ViseJaw_" .. x, x, 4.8, -1.15, .22, .55, 1.05, steel, METAL)
  box(b, "ViseJawFace_" .. x, x + (x < 3.6 and .13 or -.13), 4.8, -1.15, .07, .35, .86, charcoal, METAL)
 end
 line(b, "ViseScrew", V(2.67, 4.4, -1.15), V(4.63, 4.4, -1.15), .16, lightSteel, METAL)
 line(b, "ViseHandle", V(4.72, 3.96, -1.15), V(4.72, 4.8, -1.15), .1, lightSteel, METAL)
 -- Blueprint, measured diagram, paint pot and a small parts tray on the top.
 box(b, "BlueprintPaper", -.2, 3.96, -.3, 3, .035, 2.1, Color3.fromRGB(40, 106, 157), PLASTIC)
 for index = -2, 2 do
  box(b, "BlueprintGridX_" .. index, -.2 + index * .5, 3.983, -.3, .018, .012, 1.9, lightBlue, PLASTIC)
  box(b, "BlueprintGridZ_" .. index, -.2, 3.983, -.3 + index * .38, 2.8, .012, .018, lightBlue, PLASTIC)
 end
 b:ring("BlueprintMachineOutline", C(-.2, 4, -.3) * A(math.pi / 2, 0, 0), .57, .045, ivory, 12, PLASTIC)
 box(b, "PartsTray", -3.6, 4.02, -.2, 1.5, .16, 1.2, steel, METAL)
 for _, x in ipairs({-4.32, -2.88}) do box(b, "PartsTraySide_" .. x, x, 4.16, -.2, .08, .22, 1.2, charcoal, METAL) end
 for index = 0, 3 do cyl(b, "LooseBolt_" .. index, -4.05 + index * .3, 4.16, -.22, .18, .15, lightSteel, METAL) end
 cyl(b, "PaintTin", -1.85, 4.22, 1, .5, .43, redWood, METAL)
 cyl(b, "PaintTinLid", -1.85, 4.5, 1, .07, .48, steel, METAL)
 box(b, "BenchFrontAccent", 0, 3.39, -2.08, 9.5, .08, .04, gold, METAL)
end

local function powerConsole(b)
 local purple = Color3.fromRGB(140, 70, 213)
 local cyan = Color3.fromRGB(61, 222, 255)
 box(b, "ConsoleFoot", 0, .22, 0, 6.5, .44, 4, charcoal, METAL)
 box(b, "ConsoleFootTrim", 0, .48, 0, 6.2, .12, 3.7, gold, METAL)
 for _, side in ipairs({-1, 1}) do
  local frame = C(side * 2.6, 2.2, 0)
  box(b, "TaperedSupport_" .. side, 0, 0, 0, .72, 3.2, 2.9, charcoal, METAL, frame)
  box(b, "SupportBlueInset_" .. side, side * .39, .1, -.2, .08, 2.1, 1.8, blue, METAL, frame)
  for index = 0, 3 do
   box(b, "SupportVent_" .. side .. "_" .. index, side * .45, -.6 + index * .32, -.15, .06, .1, 1.25, lightSteel, METAL, frame)
  end
 end
 box(b, "RecessedCabinet", 0, 1.9, .3, 4.6, 2.6, 2.3, steel, METAL)
 box(b, "CabinetFront", 0, 1.9, -.9, 4, 2, .12, charcoal, METAL)
 for index = -2, 2 do box(b, "FrontHeatSink_" .. index, index * .58, 1.8, -1.02, .16, 1.45, .12, steel, METAL) end
 box(b, "StatusLight", 1.6, 2.6, -1.02, .23, .1, .08, cyan, NEON)
 local panel = C(0, 3.7, -.15) * A(math.rad(-19), 0, 0)
 box(b, "AngledControlDeck", 0, 0, 0, 6.5, .45, 3.8, charcoal, METAL, panel)
 box(b, "DeckGoldBorder", 0, .25, 0, 6.2, .06, 3.5, gold, METAL, panel)
 box(b, "DeckBlueInset", 0, .3, 0, 5.9, .06, 3.2, Color3.fromRGB(24, 43, 77), METAL, panel)
 for index = 0, 7 do
  local x, z = -2.23 + (index % 4) * 1.48, -.91 + math.floor(index / 4) * 1.1
  box(b, "PowerButtonSocket_" .. index, x, .4, z, 1.05, .12, .77, steel, METAL, panel)
  box(b, "PowerButton_" .. index, x, .5, z, .87, .15, .6,
   ({blue, redWood, gold, purple, cyan, Color3.fromRGB(85, 179, 113), ivory, lightBlue})[index + 1], PLASTIC, panel)
  box(b, "PowerButtonLight_" .. index, x, .59, z - .19, .48, .02, .045, paleGold, NEON, panel)
 end
 -- Screen standing behind the control deck, with real bevelled side cheeks.
 local screen = C(0, 5.08, 1.05) * A(math.rad(12), 0, 0)
 box(b, "MonitorOuterFrame", 0, 0, 0, 5.25, 2.9, .4, charcoal, METAL, screen)
 box(b, "MonitorGoldBezel", 0, 0, -.23, 4.96, 2.65, .12, gold, METAL, screen)
 box(b, "MonitorBlueBezel", 0, 0, -.31, 4.7, 2.39, .07, blue, METAL, screen)
 box(b, "MonitorScreen", 0, 0, -.36, 4.42, 2.12, .04, Color3.fromRGB(11, 29, 53), PLASTIC, screen)
 for index = 0, 3 do
  box(b, "ScreenDataRow_" .. index, .66, .63 - index * .38, -.39, 2.1 - index * .26, .075, .025, index == 0 and cyan or blue, NEON, screen)
 end
 b:ring("ScreenPowerSeal", screen * C(-1.25, .1, -.41), .65, .065, purple, 16, NEON)
 line(b, "ScreenLightningA", V(-1.2, .68, -.44), V(-1.55, .04, -.44), .08, paleGold, NEON, screen)
 line(b, "ScreenLightningB", V(-1.55, .04, -.44), V(-1.13, .12, -.44), .08, paleGold, NEON, screen)
 line(b, "ScreenLightningC", V(-1.13, .12, -.44), V(-1.44, -.51, -.44), .08, paleGold, NEON, screen)
 for _, side in ipairs({-1, 1}) do
  box(b, "MonitorSideCheek_" .. side, side * 2.75, 4.8, 1.08, .25, 2.85, .8, steel, METAL)
  box(b, "CheekGlow_" .. side, side * 2.9, 4.8, .8, .07, 2, .08, cyan, NEON)
  for index = 0, 4 do box(b, "RearVent_" .. side .. "_" .. index, side * 1.38, 4.52 + index * .24, 1.42, 1.7, .08, .08, charcoal, METAL) end
 end
 box(b, "MonitorCrownTrim", 0, 6.56, 1.06, 5.8, .18, .67, gold, METAL)
end

local function crownEmblem(b, name, frame, width, height, color)
 -- Raised three-prong silhouette, with cuts between the peaks.
 local z, w = -.08, width / 2
 quad(b, name .. "Band", V(-w * .86, -height * .4, z), V(w * .86, -height * .4, z), V(w, -height * .08, z), V(-w, -height * .08, z), color, METAL, frame, .16)
 tri(b, name .. "LeftPeak", V(-w, -height * .1, z), V(-w * 1.08, height * .42, z), V(-w * .35, -height * .04, z), color, METAL, frame, .16)
 tri(b, name .. "MiddlePeak", V(-w * .45, -height * .04, z), V(0, height * .62, z), V(w * .45, -height * .04, z), color, METAL, frame, .16)
 tri(b, name .. "RightPeak", V(w * .35, -height * .04, z), V(w * 1.08, height * .42, z), V(w, -height * .1, z), color, METAL, frame, .16)
 box(b, name .. "BaseStripe", 0, -height * .23, z - .12, width * .79, height * .09, .08, paleGold, METAL, frame)
 box(b, name .. "BlueDiamond", 0, -height * .13, z - .18, height * .17, height * .17, .1, lightBlue, PLASTIC, frame * A(0, 0, math.pi / 4))
end

local function clashCrownTower(b)
 local rock = Color3.fromRGB(161, 166, 176)
 local lightRock = Color3.fromRGB(192, 196, 202)
 local darkRock = Color3.fromRGB(106, 116, 133)
 box(b, "BroadStoneFooting", 0, .65, 0, 15, 1.3, 15, darkRock, STONE)
 box(b, "BevelledFoundation", 0, 1.55, 0, 14, .5, 14, rock, STONE)
 box(b, "StoneCore", 0, 12.5, 0, 10.5, 21.5, 10.5, darkRock, STONE)
 -- Staggered large stone courses on all four sides.
 for side = 0, 3 do
  local frame = A(0, side * math.pi / 2, 0)
  for course = 0, 6 do
   for index = 0, 2 do
    local x = -3.45 + index * 3.45 + (course % 2 == 1 and .22 or -.1)
    box(b, "FaceStone_" .. side .. "_" .. course .. "_" .. index,
     x, 3.1 + course * 2.8, -5.28, 3.31, 2.64, .32,
     (course + index) % 3 == 0 and lightRock or rock, STONE, frame)
   end
  end
  box(b, "BlueBanner_" .. side, 0, 14.8, -5.58, 4.2, 8.5, .11, blue, FABRIC, frame)
  for _, x in ipairs({-2.02, 2.02}) do box(b, "BannerGoldEdge_" .. side .. "_" .. x, x, 14.8, -5.66, .13, 8.5, .08, gold, METAL, frame) end
  tri(b, "BannerPoint_" .. side, V(-2.1, 10.55, -5.58), V(0, 8.3, -5.58), V(2.1, 10.55, -5.58), blue, FABRIC, frame, .08)
  box(b, "BannerHanger_" .. side, 0, 19.3, -5.76, 5.5, .24, .25, gold, METAL, frame)
  crownEmblem(b, "BannerCrown_" .. side, frame * C(0, 15.5, -5.78), 3.25, 2.7, gold)
  -- A larger blue shield plaque below the upper battlement.
  box(b, "CrownPlaque_" .. side, 0, 22.6, -5.62, 6.6, 4.4, .3, charcoal, METAL, frame)
  box(b, "CrownPlaqueBlue_" .. side, 0, 22.6, -5.83, 6.15, 4, .15, blue, METAL, frame)
  crownEmblem(b, "GrandCrown_" .. side, frame * C(0, 22.5, -5.95), 4.8, 3.3, gold)
  for _, x in ipairs({-4.75, 4.75}) do
   line(b, "TimberBrace_" .. side .. "_" .. x, V(x, 2.5, -5.6), V(x * .7, 6.8, -5.6), .42, cedar, WOOD, frame)
  end
 end
 for _, x in ipairs({-5.28, 5.28}) do
  for _, z in ipairs({-5.28, 5.28}) do
   box(b, "CornerPillar_" .. x .. "_" .. z, x, 13, z, 1.15, 22.4, 1.15, lightRock, STONE)
   for y = 4, 22, 6 do box(b, "CornerStoneBand_" .. x .. "_" .. z .. "_" .. y, x, y, z, 1.42, .45, 1.42, darkRock, STONE) end
  end
 end
 box(b, "GoldCornice", 0, 25.1, 0, 13.4, .5, 13.4, gold, METAL)
 box(b, "UpperPlatform", 0, 25.7, 0, 14, .65, 14, lightRock, STONE)
 box(b, "CrownRoofInset", 0, 26.1, 0, 11.3, .17, 11.3, blue, METAL)
 for side = 0, 3 do
  local frame = A(0, side * math.pi / 2, 0)
  box(b, "BattlementWall_" .. side, 0, 26.6, -6.48, 13.6, .8, 1, rock, STONE, frame)
  for index = -2, 2 do
   box(b, "Crenel_" .. side .. "_" .. index, index * 2.73, 27.8, -6.45, 1.7, 1.7, 1.3, lightRock, STONE, frame)
   box(b, "CrenelCap_" .. side .. "_" .. index, index * 2.73, 28.72, -6.45, 1.86, .18, 1.5, gold, METAL, frame)
  end
 end
 -- A freestanding crown cap is readable from above and from every compass side.
 cyl(b, "CrownPedestal", 0, 27.3, 0, 2.3, 5.5, charcoal, METAL)
 cyl(b, "CrownLowerRim", 0, 28.5, 0, .65, 6.2, gold, METAL)
 cyl(b, "CrownBlueBand", 0, 29.05, 0, .45, 5.9, blue, METAL)
 for side = 0, 3 do
  local frame = A(0, side * math.pi / 2, 0) * C(0, 30.5, -2.6)
  crownEmblem(b, "RoofCrown_" .. side, frame, 5.2, 4.4, gold)
 end
end

local function pagodaRoof(b, label, y, width)
 local tile = Color3.fromRGB(39, 75, 80)
 local lightTile = Color3.fromRGB(58, 107, 104)
 -- Three hipped bands form a concave eave profile, rather than stacked flat slabs.
 local radii = {width * .18, width * .33, width * .46, width * .54}
 local heights = {2.35, 1.34, .63, 1.02}
 for side = 0, 3 do
  local frame = C(0, y, 0) * A(0, side * math.pi / 2, 0)
  for band = 1, 3 do
   local r1, r2, h1, h2 = radii[band], radii[band + 1], heights[band], heights[band + 1]
   quad(b, label .. "HippedTile_" .. side .. "_" .. band,
    V(-r1, h1, -r1), V(r1, h1, -r1), V(r2, h2, -r2), V(-r2, h2, -r2),
    band == 2 and lightTile or tile, STONE, frame, .16)
  end
  box(b, label .. "RedEave_" .. side, 0, .9, -width * .54, width * 1.08, .24, .3, redWood, WOOD, frame)
  box(b, label .. "GoldEave_" .. side, 0, 1.08, -width * .542, width * 1.09, .09, .13, gold, METAL, frame)
  -- Ribs follow both changes in the roof slope.
  for index = -1, 1, 2 do
   local fraction = index / 2
   for band = 1, 2 do
    line(b, label .. "TileRib_" .. side .. "_" .. index .. "_" .. band,
     V(radii[band] * fraction, heights[band] + .12, -radii[band]),
     V(radii[band + 1] * fraction, heights[band + 1] + .12, -radii[band + 1]), .07, lightTile, STONE, frame)
   end
  end
  for _, sign in ipairs({-1, 1}) do
   line(b, label .. "RaisedCorner_" .. side .. "_" .. sign,
    V(sign * width * .46, .7, -width * .46), V(sign * width * .57, 1.58, -width * .57), .2, gold, METAL, frame)
  end
 end
 box(b, label .. "UpperRoofDeck", 0, y + 2.33, 0, width * .36, .25, width * .36, tile, STONE)
end

local function hoohBellTower(b)
 local foundation = Color3.fromRGB(116, 116, 114)
 local bronze = Color3.fromRGB(159, 107, 41)
 local darkBronze = Color3.fromRGB(91, 57, 24)
 box(b, "GardenStoneFoundation", 0, .65, 0, 23, 1.3, 23, foundation, STONE)
 box(b, "FoundationRaisedCourse", 0, 1.5, 0, 20.5, .4, 20.5, Color3.fromRGB(171, 166, 150), STONE)
 for step = 0, 3 do
  box(b, "FrontStair_" .. step, 0, .2 + step * .38, -13 + step * .65, 10 - step * .35, .4, 1.5, foundation, STONE)
 end
 for _, side in ipairs({-1, 1}) do
  box(b, "GardenBed_" .. side, side * 9.1, 1.57, 1, 2, .25, 15.5, Color3.fromRGB(65, 91, 63), Enum.Material.Grass)
  for index = 0, 4 do
   box(b, "GardenBorder_" .. side .. "_" .. index, side * 10.4, 1.8, -5 + index * 3, .55, .55, 2.8, foundation, STONE)
  end
 end
 for tier = 1, 5 do
  local y = 1.8 + (tier - 1) * 7.2
  local width = 15.2 - (tier - 1) * 1.55
  local corner = width / 2 - .5
  box(b, "TierTimberDeck_" .. tier, 0, y, 0, width + .8, .4, width + .8, cedar, WOOD)
  for _, x in ipairs({-corner, corner}) do
   for _, z in ipairs({-corner, corner}) do
    box(b, "RedTimberPost_" .. tier .. "_" .. x .. "_" .. z, x, y + 2.6, z, .58, 5.2, .58, redWood, WOOD)
    box(b, "GoldPostShoe_" .. tier .. "_" .. x .. "_" .. z, x, y + .35, z, .74, .35, .74, gold, METAL)
   end
  end
  for side = 0, 3 do
   local frame = C(0, y, 0) * A(0, side * math.pi / 2, 0)
   box(b, "UpperTimberBeam_" .. tier .. "_" .. side, 0, 4.9, -corner, width, .5, .65, redWood, WOOD, frame)
   if tier < 5 then
    box(b, "IvoryWallPanel_" .. tier .. "_" .. side, 0, 2.6, -corner, width - 1.4, 3.5, .2, ivory, PLASTIC, frame)
    box(b, "DarkLatticeWindow_" .. tier .. "_" .. side, 0, 2.8, -corner - .17, width * .48, 2.5, .15, charcoal, PLASTIC, frame)
    for index = -1, 1 do box(b, "WindowLattice_" .. tier .. "_" .. side .. "_" .. index, index * width * .12, 2.8, -corner - .28, .11, 2.55, .1, cedar, WOOD, frame) end
    box(b, "WindowSill_" .. tier .. "_" .. side, 0, 1.46, -corner - .26, width * .55, .16, .5, redWood, WOOD, frame)
   else
    -- The open upper pavilion exposes the bronze bell from every side.
    box(b, "BellPavilionHandrail_" .. side, 0, 1.25, -corner, width, .16, .22, redWood, WOOD, frame)
    box(b, "BellPavilionRailBase_" .. side, 0, .5, -corner, width, .15, .2, cedar, WOOD, frame)
    for index = -2, 2 do box(b, "BellPavilionBaluster_" .. side .. "_" .. index, index * width * .16, .88, -corner, .1, .7, .1, gold, METAL, frame) end
   end
  end
  pagodaRoof(b, "TierRoof_" .. tier, y + 5.15, width + 3)
 end
 -- Ringed hollow bell with a flared lip, dark underside, clapper and hanger.
 line(b, "BellHangingChain", V(0, 35.4, 0), V(0, 34.5, 0), .17, darkBronze, METAL)
 cyl(b, "BronzeBellCrown", 0, 34.25, 0, .45, 1.5, bronze, METAL)
 cyl(b, "BronzeBellShoulder", 0, 33.75, 0, .55, 2.4, bronze, METAL)
 cyl(b, "BronzeBellBody", 0, 32.8, 0, 1.5, 2.8, bronze, METAL)
 cyl(b, "BronzeBellLowerFlare", 0, 31.95, 0, .35, 3.35, bronze, METAL)
 cyl(b, "BellFlaredRim", 0, 31.67, 0, .2, 3.75, gold, METAL)
 cyl(b, "BellHollowUnderside", 0, 31.54, 0, .04, 3.05, darkBronze, METAL)
 for index = 0, 11 do
  local angle = index * math.pi / 6
  box(b, "BellEmbossedRib_" .. index, 0, 32.8, 0, .1, 1.6, .1, gold, METAL,
   C(math.cos(angle) * 1.39, 0, math.sin(angle) * 1.39))
 end
 line(b, "BellClapperStem", V(0, 32.2, 0), V(0, 31, 0), .14, gold, METAL)
 cyl(b, "BellClapperDisc", 0, 30.95, 0, .25, .7, bronze, METAL)
 -- A traditional spire composed of discs and a pointed finial, without floating orbs.
 cyl(b, "TopSpirePole", 0, 40.5, 0, 4.2, .26, gold, METAL)
 for index = 0, 4 do cyl(b, "SpireRing_" .. index, 0, 39.2 + index * .52, 0, .12, 1.35 - index * .17, gold, METAL) end
 tri(b, "SpireTip", V(-.3, 42.4, 0), V(0, 43.5, 0), V(.3, 42.4, 0), paleGold, METAL, C(), .14)
end

local builders = {
 detailed_workbench = detailedWorkbench,
 power_console = powerConsole,
 clash_crown_tower = clashCrownTower,
 hooh_bell_tower = hoohBellTower,
}
function M.build(b, key)
 local build = builders[key]
 if not build then return false end
 build(b)
 return true
end
return M
