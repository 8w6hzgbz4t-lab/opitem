-- Optional native scenery replacement. Existing gameplay anchors retain their identity.
local FreeModels = require(script.Parent.FreeModels)
local Primitives = require(script.Parent.Primitives)
local HoOhAssembler = require(script.Parent.HoOhAssembler)
local W = {}
local V, C, A = Vector3.new, CFrame.new, CFrame.Angles

local function childrenCopy(parent)
 local copy = {}
 for _, child in ipairs(parent:GetChildren()) do copy[#copy + 1] = child end
 return copy
end

local function removeNamed(parent, names)
 if not parent then return end
 for _, child in ipairs(childrenCopy(parent)) do
  if names[child.Name] then child:Destroy() end
 end
end

function W.tower(parent)
 removeNamed(parent, {SunlitBellPagoda = true})
 return FreeModels.create(parent, {
  model = "hooh_bell_tower", name = "SunlitBellPagoda", cframe = C(44, 0, 113),
 })
end

local function moveRainbowAndRemoveClouds(aesthetics)
 local sky = aesthetics and aesthetics:FindFirstChild("PrismaticSky")
 if not sky then return end
 local transform = C(160, 0, 0) * A(0, math.pi / 2, 0) * C(0, 0, 165)
 for _, child in ipairs(childrenCopy(sky)) do
  if child.Name == "SoftCloud" then
   child:Destroy()
  elseif child:IsA("BasePart") and child.Name:match("^RainbowBand") then
   -- Repeated decoration builds must not move the already transformed rainbow.
   local original = child:GetAttribute("NativeArtOriginalCF")
   if not original then
    original = child.CFrame
    child:SetAttribute("NativeArtOriginalCF", original)
   end
   child.CFrame = transform * original
  end
 end
 sky:SetAttribute("RainbowLocation", "EastSky")
end

local function wristConnections(parent, aesthetics, circleCF)
 local guardian = aesthetics and aesthetics:FindFirstChild("FivePieceAncientGuardian")
 if not guardian then return end
 local b = Primitives.new(parent, {
  name = "GuardianWristConnections", model = "GuardianWristConnections",
  alignBase = false, partBudget = 260,
 })
 local chainColor = Color3.fromRGB(163, 141, 189)
 local gold = Color3.fromRGB(216, 163, 55)
 for _, entry in ipairs({{"LeftArm", V(-10, 21, -1.5)}, {"RightArm", V(10, 21, -1.5)}}) do
  local arm = guardian:FindFirstChild(entry[1])
  local palm = arm and arm:FindFirstChild("HandPalm", true)
  if palm and palm:IsA("BasePart") then
   local start, finish = circleCF * entry[2], palm.Position
   local delta = finish - start
   if delta.Magnitude > .1 then
    local along = delta.Unit
    local side = along:Cross(V(0, 0, 1))
    if side.Magnitude < .01 then side = along:Cross(V(0, 1, 0)) end
    side = side.Unit
    local normal = along:Cross(side).Unit
    local links = 7
    local halfLength = delta.Magnitude / (links - 1) * .62
    for index = 0, links - 1 do
     local t = index / (links - 1)
     local center = start:Lerp(finish, t) + V(0, -.35 * math.sin(t * math.pi), 0)
     local widthAxis = index % 2 == 0 and side or normal
     for segment = 0, 7 do
      local first, second = segment * math.pi / 4, (segment + 1) * math.pi / 4
      local a = center + along * (math.cos(first) * halfLength) + widthAxis * (math.sin(first) * .42)
      local c = center + along * (math.cos(second) * halfLength) + widthAxis * (math.sin(second) * .42)
      b:line(entry[1] .. "ChainLink_" .. index .. "_" .. segment, a, c, .17, .17, chainColor, Enum.Material.Metal)
     end
    end
   end
   b:ring(entry[1] .. "WristCuff", C(finish) * A(0, math.pi / 2, 0), 1.05, .28, gold, 10, Enum.Material.Metal)
  end
 end
 b.model:SetAttribute("DecorativeOnly", true)
 b.model:SetAttribute("ConnectedToGuardianWrists", true)
 return b:finish()
end

function W.decorate(world)
 assert(world and world.folder, "A built world is required for native scenery")
 local old = world.folder:FindFirstChild("NativeFreeArt")
 if old then old:Destroy() end
 local root = Instance.new("Folder")
 root.Name = "NativeFreeArt"
 root.Parent = world.folder
 root:SetAttribute("DecorativeOnly", true)
 root:SetAttribute("ArtSource", "NativeRobloxParts")

 -- DetailedArt still owns the racetrack, dragons, arena bounds and other landmarks.
 local landmarks = world.folder:FindFirstChild("DetailedLandmarks")
 removeNamed(landmarks, {godRa = true, godObelisk = true, CrownArenaTower = true, RiftArchiveCard = true})
 FreeModels.create(root, {
  model = "winged_dragon_ra", name = "DetailedWingedDragonOfRa", scale = 1.2,
  cframe = C(75, 34, 155),
 })
 FreeModels.create(root, {
  model = "obelisk_tormentor", name = "DetailedObeliskTheTormentor", scale = 1.2,
  cframe = C(-35, 34, 155),
 })
 for _, x in ipairs({-125, 125}) do
  FreeModels.create(root, {
   model = "clash_crown_tower", name = "DetailedCrownArenaTower", scale = 1.1,
   cframe = C(x, 24, 28),
  })
 end
 FreeModels.create(root, {
  model = "mtg_black_lotus_card", name = "DetailedBlackLotusCard",
  cframe = C(104, 38, 110),
 })

 local background = world.folder:FindFirstChild("BackgroundArt")
 removeNamed(background, {MirrorForceReflectionPlanet = true})
 FreeModels.create(root, {
  model = "mirror_force_card", name = "MirrorForceCardBackdrop",
  cframe = C(-60, 66, -149) * A(0, math.pi, 0),
 })
 local circleCF = C(-40, 29, -116) * A(0, math.pi, 0)
 FreeModels.create(root, {
  model = "exodia_spellbinding_circle_chains", name = "ExodiaSpellbindingCircle",
  cframe = circleCF,
 })
 local aesthetics = world.folder:FindFirstChild("Aesthetics")
 wristConnections(root, aesthetics, circleCF)
 moveRainbowAndRemoveClouds(aesthetics)

 -- Keep the original invisible, solid/queryable prompt anchors in place.
 -- Visual furniture never acquires collection, purchase or protection authority.
 for index, base in ipairs(world.bases or {}) do
  if base.upgrade then base.upgrade.Transparency = 1 end
  FreeModels.create(root, {
   model = "detailed_workbench", name = "NativeUpgradeWorkbench" .. index,
   scale = .8, cframe = base.cf * C(16, 1, -16),
  })
 end
 if world.powerShop then world.powerShop.Transparency = 1 end
 FreeModels.create(root, {
  model = "power_console", name = "NativePowerConsole", scale = .8,
  cframe = C(0, .1, 19),
 })
 HoOhAssembler.create(root, C(44, 39, 113) * A(0, math.pi, 0), 1.25)
 world.nativeArt = root
 return root
end
return W
