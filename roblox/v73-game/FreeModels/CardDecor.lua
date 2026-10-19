-- Native, asset-free card art and Exodia binding ornament. Front faces local -Z.
-- Text and supplied reference images are installed by the integration module.
local M = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
local metal, neon, smooth, wood = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.SmoothPlastic, Enum.Material.Wood
local rgb = Color3.fromRGB
local black, ink = rgb(13, 12, 21), rgb(34, 28, 43)
local gold, paleGold = rgb(177, 132, 52), rgb(234, 205, 126)
local parchment, printColor = rgb(223, 210, 177), rgb(91, 77, 62)
local violet, lavender = rgb(119, 48, 215), rgb(219, 140, 255)

local function box(b, name, x, y, z, sx, sy, sz, color, material)
 return b:box(name, V(sx, sy, sz), C(x, y, z), color, material or smooth)
end

local function disc(b, name, x, y, z, radius, thickness, color, material)
 return b:cylinder(name, V(thickness, radius * 2, radius * 2), C(x, y, z) * A(0, math.pi / 2, 0), color, material or metal)
end

local function frame(b, prefix, x, y, z, w, h, width, color, material)
 box(b, prefix .. "Left", x - w / 2 + width / 2, y, z, width, h, width, color, material)
 box(b, prefix .. "Right", x + w / 2 - width / 2, y, z, width, h, width, color, material)
 box(b, prefix .. "Top", x, y + h / 2 - width / 2, z, w, width, width, color, material)
 box(b, prefix .. "Bottom", x, y - h / 2 + width / 2, z, w, width, width, color, material)
end

local function cardBody(b, prefix, w, h, border)
 box(b, prefix .. "Back", 0, h / 2, .25, w, h, .8, black)
 box(b, prefix .. "ColoredFace", 0, h / 2, -.22, w - .5, h - .5, .22, border)
 frame(b, prefix .. "BlackRim", 0, h / 2, -.39, w, h, .28, black, metal)
 frame(b, prefix .. "InsetBead", 0, h / 2, -.54, w - .95, h - .95, .08, paleGold, metal)
 for _, side in ipairs({-1, 1}) do
  for _, top in ipairs({.65, h - .65}) do
   disc(b, prefix .. "CornerPin_" .. side .. "_" .. top, side * (w / 2 - .65), top, -.61, .12, .06, gold)
  end
 end
end

local function finePrint(b, prefix, x, y, z, width, rows, step, color)
 -- Fine line geometry is texture, not invented writing. Actual readable text is separate.
 for row = 1, rows do
  local length = width * ((row == rows) and .62 or (row % 3 == 0 and .89 or .98))
  box(b, prefix .. "PrintedRule_" .. row, x - (width - length) / 2, y - (row - 1) * step, z, length, .025, .022, color)
 end
end

local function petal(b, name, base, tip, width, color, highlight)
 local d = tip - base
 local side = V(-d.Y, d.X, 0).Unit * width
 local middle = base:Lerp(tip, .57)
 local left, right = middle + side, middle - side
 local ridge = middle + V(0, 0, -.24)
 b:triangle(name .. "LeftFacet", base, left, ridge, color, .045, metal)
 b:triangle(name .. "RightFacet", base, ridge, right, highlight, .045, metal)
 b:triangle(name .. "LeftTip", left, tip, ridge, color, .045, metal)
 b:triangle(name .. "RightTip", ridge, tip, right, highlight, .045, metal)
end

local function blackLotusCard(b)
 local w, h = 16, 23
 local moss, deepGreen = rgb(61, 73, 56), rgb(22, 47, 38)
 cardBody(b, "LotusCard", w, h, moss)
 box(b, "TitleSurface", 0, 21.12, -.66, 13.8, 1.55, .14, parchment)
 frame(b, "TitleKeyline", 0, 21.12, -.77, 14, 1.75, .08, gold, metal)
 disc(b, "ZeroManaCost", 6.02, 21.12, -.88, .45, .09, rgb(175, 177, 169))
 b:ring("ZeroManaRim", C(6.02, 21.12, -.95), .31, .048, ink, 12, metal)
 box(b, "ArtWindowSurface", 0, 14.36, -.7, 13.7, 11.5, .15, deepGreen)
 frame(b, "ArtWindowGilding", 0, 14.36, -.86, 13.85, 11.65, .12, gold, metal)
 box(b, "ArtWindowDusk", 0, 17.7, -.82, 13.2, 4.3, .05, rgb(48, 53, 66))
 -- The still pond, thin mist, sloped leaves and sharply layered blossom stay inside the art.
 box(b, "LotusPond", 0, 10.35, -.88, 13.2, 3.1, .06, rgb(27, 53, 53))
 for i = 1, 9 do
  local yy = 9.1 + i * .36
  box(b, "WaterReflection_" .. i, ((i % 3) - 1) * .6, yy, -.94, 5.6 + (i % 3) * 1.45, .026, .028, rgb(63, 95, 84))
 end
 for _, s in ipairs({-1, 1}) do
  local base = V(s * .65, 10.7, -1.03)
  b:triangle("BroadLotusLeaf_" .. s, base, V(s * 5.6, 11.55, -1.02), V(s * 3.9, 13.05, -1.04), rgb(46, 93, 65), .055, smooth)
  b:triangle("LeafShadow_" .. s, base, V(s * 4.3, 10.1, -1.05), V(s * 5.6, 11.55, -1.02), rgb(27, 67, 47), .055, smooth)
  b:line("LeafVein_" .. s, base, V(s * 5.25, 11.56, -1.12), .035, .035, rgb(95, 139, 83))
 end
 b:line("CurvedStemLower", V(.15, 9.6, -1), V(-.2, 11.6, -1.04), .16, .16, rgb(61, 93, 53))
 b:line("CurvedStemUpper", V(-.2, 11.6, -1.04), V(0, 13, -1.12), .13, .13, rgb(86, 115, 64))
 for i = 0, 8 do
  local angle = i * math.pi * 2 / 9
  local tip = V(math.cos(angle) * 4.5, 14 + math.sin(angle) * 3.35, -1.15)
  petal(b, "OuterBlackPetal_" .. i, V(0, 13.3, -1.17), tip, 1.0, rgb(27, 20, 43), rgb(65, 42, 89))
 end
 for i = 0, 6 do
  local angle = i * math.pi * 2 / 7 + .22
  local tip = V(math.cos(angle) * 2.75, 14.15 + math.sin(angle) * 2.4, -1.6)
  petal(b, "InnerVioletPetal_" .. i, V(0, 13.7, -1.58), tip, .67, rgb(43, 29, 65), rgb(100, 62, 132))
 end
 for i = 0, 6 do
  local a = i * math.pi * 2 / 7
  b:ball("GoldenLotusStamen_" .. i, V(.16, .3, .13), C(math.cos(a) * .45, 14.1 + math.sin(a) * .37, -1.99), paleGold, metal)
 end
 disc(b, "BlossomHeart", 0, 14, -1.92, .23, .14, rgb(223, 166, 75))
 for i = 1, 5 do
  box(b, "ArtMist_" .. i, (i % 2 == 0 and 1 or -1) * 3.15, 17.8 + i * .27, -1.05, 2.3 + i * .28, .045, .04, rgb(111, 122, 114))
 end
 box(b, "TypeSurface", 0, 7.52, -.68, 13.8, 1.2, .14, parchment)
 frame(b, "TypeKeyline", 0, 7.52, -.79, 13.95, 1.35, .07, gold, metal)
 disc(b, "SetSymbol", 6.08, 7.52, -.9, .28, .08, ink)
 b:triangle("SetSymbolPoint", V(5.84, 7.43, -.98), V(6.08, 7.91, -.98), V(6.31, 7.43, -.98), paleGold, .025, metal)
 box(b, "RulesSurface", 0, 4.1, -.67, 13.8, 5.2, .16, parchment)
 frame(b, "RulesKeyline", 0, 4.1, -.78, 13.95, 5.35, .08, gold, metal)
 finePrint(b, "LotusRules", -.2, 5.8, -.79, 11.8, 5, .42, printColor)
 finePrint(b, "LotusFlavor", -.2, 3.14, -.79, 10.7, 2, .36, rgb(130, 112, 85))
 box(b, "FooterCredit", -1.8, .92, -.64, 9.5, .035, .025, parchment)
 box(b, "FooterCollector", 5.2, .92, -.64, 1.8, .035, .025, parchment)
 b.model:SetAttribute("DisplayTitle", "Black Lotus")
 b.model:SetAttribute("CardType", "Artifact")
 b.model:SetAttribute("NativeArtwork", true)
end

local function mirrorForceCard(b)
 local w, h = 32, 47
 cardBody(b, "MirrorForce", w, h, rgb(144, 63, 119))
 -- Trap-frame marbling uses restrained bevel panels rather than a flat magenta slab.
 for _, x in ipairs({-14.5, 14.5}) do
  for j = 0, 5 do
   box(b, "TrapMarble_" .. x .. "_" .. j, x, 6 + j * 6.1, -.49, .75, 3.9, .05, j % 2 == 0 and rgb(166, 85, 139) or rgb(115, 47, 97))
  end
 end
 box(b, "TitleSurface", 0, 43.2, -.68, 28.1, 3.6, .18, rgb(173, 104, 150))
 frame(b, "TitleShadow", 0, 43.2, -.85, 28.3, 3.8, .13, rgb(75, 32, 68), metal)
 box(b, "CardTypeSurface", 4, 39.82, -.7, 19.6, 1.5, .13, rgb(156, 76, 129))
 disc(b, "TrapIconGold", 13.18, 43.23, -.97, .93, .2, paleGold)
 disc(b, "TrapIconPurple", 13.18, 43.23, -1.11, .71, .12, rgb(132, 40, 123))
 b:line("TrapIconHourglassTop", V(12.74, 43.69, -1.22), V(13.61, 43.69, -1.22), .11, .11, parchment)
 b:line("TrapIconHourglassBottom", V(12.74, 42.78, -1.22), V(13.61, 42.78, -1.22), .11, .11, parchment)
 b:line("TrapIconCrossA", V(12.82, 43.62, -1.22), V(13.52, 42.85, -1.22), .09, .09, parchment)
 b:line("TrapIconCrossB", V(13.52, 43.62, -1.22), V(12.82, 42.85, -1.22), .09, .09, parchment)
 box(b, "ArtWindowSurface", 0, 27.3, -.7, 27.4, 21.8, .2, rgb(10, 25, 54))
 frame(b, "ArtWindowBlackEdge", 0, 27.3, -.89, 27.75, 22.15, .18, ink, metal)
 frame(b, "ArtWindowSilverLip", 0, 27.3, -1, 27.35, 21.75, .09, rgb(167, 172, 183), metal)
 -- Every part of the old planet/reflection motif is bounded by the rectangular artwork.
 disc(b, "ReflectionHaloBackdrop", 0, 27.3, -.92, 9.55, .14, rgb(39, 54, 100))
 disc(b, "MirrorShieldFace", 0, 27.3, -1.05, 7.28, .18, rgb(97, 141, 179))
 disc(b, "MirrorShieldInner", 0, 27.3, -1.17, 6.86, .12, rgb(164, 202, 218))
 disc(b, "MirrorShieldGlass", -.6, 28.05, -1.27, 6.04, .1, rgb(85, 139, 170))
 b:ring("MirrorShieldBevel", C(0, 27.3, -1.29), 7.35, .36, rgb(217, 233, 240), 40, metal)
 b:ring("VioletEnergyRing", C(0, 27.3, -1.39), 8.22, .19, rgb(160, 88, 255), 36, neon)
 b:ring("IceEnergyRing", C(0, 27.3, -1.45), 8.62, .11, rgb(132, 242, 255), 32, neon)
 -- Metallic shield facets converge toward a central reflection and create visible depth.
 for i = 0, 11 do
  local a, c = i * math.pi * 2 / 12, (i + 1) * math.pi * 2 / 12
  local p = V(math.cos(a) * 6.4, 27.3 + math.sin(a) * 6.4, -1.42)
  local q = V(math.cos(c) * 6.4, 27.3 + math.sin(c) * 6.4, -1.42)
  b:triangle("MirrorFacet_" .. i, V(-.9, 28.2, -2.02), p, q,
   i % 3 == 0 and rgb(219, 240, 246) or (i % 3 == 1 and rgb(126, 178, 201) or rgb(75, 123, 162)), .035, metal)
 end
 for i = 0, 15 do
  local angle = i * math.pi * 2 / 16 + .1
  local inner, outer = 8.95, (i % 2 == 0 and 10.05 or 9.6)
  local a = V(math.cos(angle) * inner, 27.3 + math.sin(angle) * inner, -1.38)
  local mid = V(math.cos(angle + .045) * (outer - .35), 27.3 + math.sin(angle + .045) * (outer - .35), -1.49)
  local tip = V(math.cos(angle - .04) * outer, 27.3 + math.sin(angle - .04) * outer, -1.37)
  b:line("ReflectionBoltA_" .. i, a, mid, .12, .1, rgb(192, 218, 255), neon)
  b:line("ReflectionBoltB_" .. i, mid, tip, .09, .09, lavender, neon)
 end
 -- Side shards remain inside x +/-13 and y 17..38, instead of crossing the frame.
 for _, s in ipairs({-1, 1}) do
  for i = 1, 5 do
   local y = 19.2 + i * 2.65
   local x = s * (11.4 + (i % 2) * .7)
   b:triangle("ReflectedShard_" .. s .. "_" .. i, V(x, y, -1.45), V(x - s * 2.5, y + .75, -1.83), V(x - s * .15, y + 1.5, -1.42), rgb(146 + i * 12, 201 + i * 5, 229), .08, metal)
  end
 end
 b:line("ShieldBrightDiagonal", V(-4.3, 23.1, -2.08), V(3.45, 31.4, -2.08), .17, .06, rgb(219, 248, 255), neon)
 b:line("ShieldBrightReflection", V(-3.9, 23.2, -2.06), V(3.8, 31.5, -2.06), .045, .045, rgb(127, 236, 255), neon)
 box(b, "EditionSurface", -7.3, 15.35, -.69, 12, .65, .08, rgb(165, 90, 137))
 box(b, "RulesSurface", 0, 8.75, -.71, 28.0, 11.4, .18, rgb(232, 214, 197))
 frame(b, "RulesDarkKeyline", 0, 8.75, -.87, 28.2, 11.6, .12, rgb(78, 38, 71), metal)
 finePrint(b, "MirrorRules", -.3, 12.6, -.83, 25.3, 7, .91, printColor)
 box(b, "SerialSurface", -10, 1.7, -.68, 7, .035, .025, parchment)
 box(b, "CopyrightSurface", 5.25, 1.7, -.68, 12.2, .035, .025, parchment)
 box(b, "SecurityFoil", 14.36, 1.3, -.76, .75, .75, .12, gold, metal)
 b.model:SetAttribute("DisplayTitle", "Mirror Force")
 b.model:SetAttribute("CardType", "Trap Card")
 b.model:SetAttribute("ArtworkContained", true)
 b.model:SetAttribute("NativeArtwork", true)
end

local function chainLink(b, name, center, along, widthAxis, halfLength, halfWidth, color)
 for i = 0, 7 do
  local a, c = i * math.pi / 4, (i + 1) * math.pi / 4
  b:line(name .. "_" .. i,
   center + along * (math.cos(a) * halfLength) + widthAxis * (math.sin(a) * halfWidth),
   center + along * (math.cos(c) * halfLength) + widthAxis * (math.sin(c) * halfWidth),
   .17, .17, color, metal)
 end
end

local function bindingChain(b, name, origin, destination, links)
 local direction = (destination - origin).Unit
 local side = direction:Cross(V(0, 0, 1)).Unit
 local normal = direction:Cross(side).Unit
 local spacing = (destination - origin).Magnitude / (links - 1)
 for i = 0, links - 1 do
  local t = i / (links - 1)
  -- An alternating link turns about the chain's length axis and interlocks physically.
  local width = (i % 2 == 0) and side or normal
  local sag = V(0, -math.sin(t * math.pi) * .8, 0)
  local center = origin:Lerp(destination, t) + sag
  chainLink(b, name .. "Link_" .. i, center, direction, width, spacing * .66 + .15, .43, i % 2 == 0 and rgb(108, 91, 140) or rgb(172, 144, 203))
 end
 disc(b, name .. "CircleAnchor", origin.X, origin.Y, origin.Z, .64, .32, gold)
end

local function spellbindingCircle(b)
 local center = V(0, 21, .65)
 b:ring("OuterVioletBindingRing", C(center), 20, .43, violet, 48, metal)
 b:ring("MiddleMagentaRunicRing", C(0, 21, .55), 18.45, .22, rgb(219, 75, 208), 48, neon)
 b:ring("InnerLavenderBindingRing", C(0, 21, .48), 15.5, .16, lavender, 48, neon)
 -- Open central region deliberately leaves the Exodia head and chest readable.
 for i = 0, 5 do
  local a, c = i * math.pi / 3 + math.pi / 2, (i + 2) * math.pi / 3 + math.pi / 2
  b:line("SixPointSeal_" .. i, V(math.cos(a) * 15.2, 21 + math.sin(a) * 15.2, .82), V(math.cos(c) * 15.2, 21 + math.sin(c) * 15.2, .82), .1, .1, rgb(100, 41, 137), metal)
 end
 for i = 0, 11 do
  local a = i * math.pi / 6
  local glyph = C(0, 21, .3) * A(0, 0, a) * C(0, 17, 0)
  local name = "BindingGlyph_" .. i
  b:line(name .. "Left", glyph * V(-.42, -.5, 0), glyph * V(0, .5, 0), .1, .1, lavender, neon)
  b:line(name .. "Right", glyph * V(0, .5, 0), glyph * V(.42, -.5, 0), .1, .1, lavender, neon)
  b:line(name .. "Cross", glyph * V(-.28, -.1, 0), glyph * V(.28, -.1, 0), .08, .08, lavender, neon)
  b:ball("OuterRingStud_" .. i, .5, C(math.cos(a) * 20, 21 + math.sin(a) * 20, .46), gold, metal)
 end
 local cuffEndpoints = {
  {"LeftWrist", V(-18, 29, .5), V(-10, 21, -1.5)},
  {"RightWrist", V(18, 29, .5), V(10, 21, -1.5)},
  {"LeftTorso", V(-15, 7.5, .5), V(-4.2, 12.2, -1.5)},
  {"RightTorso", V(15, 7.5, .5), V(4.2, 12.2, -1.5)},
 }
 for _, entry in ipairs(cuffEndpoints) do
  local name, origin, target = entry[1], entry[2], entry[3]
  bindingChain(b, name .. "Chain", origin, target, 10)
  b:ring(name .. "BindingCuff", C(target) * A(0, math.pi / 2, 0), .96, .3, gold, 8, metal)
  b:ring(name .. "CuffMagic", C(target + V(.04, 0, 0)) * A(0, math.pi / 2, 0), 1.08, .075, lavender, 8, neon)
  b.model:SetAttribute(name .. "CuffLocal", string.format("%.3f,%.3f,%.3f", target.X, target.Y, target.Z))
 end
 b.model:SetAttribute("CircleCenterLocal", "0,21,0.65")
 b.model:SetAttribute("DisplayTitle", "Spellbinding Circle")
end

local function paintingFrame(b)
 local brown, warm = rgb(71, 43, 31), rgb(142, 91, 49)
 box(b, "CanvasBack", 0, 8.1, .32, 13, 16, .5, brown, wood)
 box(b, "ReferenceCanvasSurface", 0, 8.1, -.06, 11.0, 14, .2, rgb(203, 193, 174))
 frame(b, "CarvedOuterFrame", 0, 8.1, -.1, 13.5, 16.5, .65, brown, wood)
 frame(b, "RaisedWalnutBead", 0, 8.1, -.45, 13.04, 16.04, .14, warm, wood)
 frame(b, "AntiqueGoldBead", 0, 8.1, -.56, 12.5, 15.5, .13, gold, metal)
 frame(b, "InnerMat", 0, 8.1, -.25, 12.1, 15.1, .5, rgb(231, 223, 202))
 frame(b, "CanvasLip", 0, 8.1, -.44, 11.25, 14.25, .08, warm, wood)
 for _, s in ipairs({-1, 1}) do
  for _, y in ipairs({.12, 16.08}) do
   disc(b, "CornerRosette_" .. s .. "_" .. y, s * 6.44, y, -.55, .29, .12, gold)
   for i = 0, 3 do
    local a = i * math.pi / 2
    b:ball("RosettePetal_" .. s .. "_" .. y .. "_" .. i, V(.2, .2, .08), C(s * 6.44 + math.cos(a) * .26, y + math.sin(a) * .26, -.65), paleGold, metal)
   end
  end
 end
 b:line("PictureHangingWireLeft", V(-4.7, 13.7, .7), V(0, 16.95, .7), .065, .065, rgb(126, 125, 119), metal)
 b:line("PictureHangingWireRight", V(0, 16.95, .7), V(4.7, 13.7, .7), .065, .065, rgb(126, 125, 119), metal)
 disc(b, "HangingHook", 0, 16.95, .7, .15, .13, gold)
 b.model:SetAttribute("ReferenceRequired", true)
 b.model:SetAttribute("ArtStatus", "FrameReadyReferenceRequired")
 b.model:SetAttribute("DisplayTitle", "Force of Despair Painting")
 -- No substitute meme, generated face, or invented artwork is stamped on this canvas.
end

local builders = {
 mtg_black_lotus_card = blackLotusCard,
 mirror_force_card = mirrorForceCard,
 exodia_spellbinding_circle_chains = spellbindingCircle,
 squidward_force_of_despair_painting = paintingFrame,
}
function M.build(b, key)
 local builder = builders[key]
 if not builder then return false end
 builder(b)
 return true
end
return M
