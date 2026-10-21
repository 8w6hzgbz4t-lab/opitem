-- Static scenery upgrades. Gameplay anchors, state, prices and remotes are unchanged.
local L=require(script.Parent.LandmarkArt)
local P=require(script.Parent.Primitives)
local E=require(script.Parent.ExtraDecor)
local W={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local function group(parent,name)
 local g=Instance.new("Model");g.Name=name;g.Parent=parent;return g
end
function W.pillars(parent)
 local root=group(parent,"CelestialArenaPillars")
 for _,x in ipairs({-126,126}) do
  for _,z in ipairs({-84,-42,42,84}) do
   L.create(root,{model="tournamentPillar",name="DetailedArenaPillar",cframe=C(x,0,z),scale=1.5})
  end
 end
end
function W.monument(parent)
 return L.create(parent,{model="guardian",name="FivePieceAncientGuardian",scale=5.7,cframe=C(-40,20,-108)*A(0,math.pi,0)})
end
function W.tower(parent)
 return L.create(parent,{model="bellTower",name="SunlitBellPagoda",scale=1.7,cframe=C(44,0,113)})
end
function W.stoneHead(parent)
 return L.create(parent,{model="squidHouse",name="TidalStoneHead",scale=1.5,cframe=C(-94,14,-114)*A(0,math.pi,0)})
end
function W.roofs(parent,bases)
 local root=group(parent,"VaultRoofs")
 for i,base in ipairs(bases) do
  local m=L.create(root,{model="baseBuilding",name="BaseRoof"..i,cframe=base.cf,
   roofHeight=17.5,accent=Color3.fromHSV((i-1)/#bases,.48,.86)})
  m:SetAttribute("BaseCF",base.cf)
 end
end
function W.skyFlowers(parent)
 local root=group(parent,"PastelSkyFlowers")
 local sites={V(-118,90,-150),V(120,104,-155),V(-85,86,145),V(105,82,150)}
 for i,position in ipairs(sites) do
  L.create(root,{model="skyFlower",name="SkyFlower"..i,cframe=C(position),scale=.8+(i%2)*.15})
 end
end
function W.applyLighting()
 local lighting=game:GetService("Lighting")
 lighting.ClockTime=0.2;lighting.Brightness=2
 lighting.Ambient=Color3.fromRGB(135,111,156)
 lighting.OutdoorAmbient=Color3.fromRGB(115,91,145)
 lighting.ExposureCompensation=.12
 local atmosphere=lighting:FindFirstChildOfClass("Atmosphere")
 if not atmosphere then atmosphere=Instance.new("Atmosphere");atmosphere.Name="AestheticsAtmosphere";atmosphere.Parent=lighting end
 atmosphere.Density=.025;atmosphere.Offset=.05
 atmosphere.Color=Color3.fromRGB(164,137,193)
 atmosphere.Decay=Color3.fromRGB(65,37,94)
 atmosphere.Glare=0;atmosphere.Haze=.08
end
function W.domain(parent)
 local b=P.new(parent,{model="DomainDome",name="VioletDomainDome",alignBase=false,partBudget=800})
 local radius,height=260,180
 local bands,sectors=6,16
 local function point(row,column)
  local elevation=row/bands*math.pi*.5
  local angle=column/sectors*math.pi*2
  return V(radius*math.cos(elevation)*math.cos(angle),height*math.sin(elevation),
   radius*math.cos(elevation)*math.sin(angle))
 end
 for row=0,bands-1 do
  for col=0,sectors-1 do
   local a,c,d,e=point(row,col),point(row,col+1),point(row+1,col+1),point(row+1,col)
   local color=Color3.fromRGB(22+row*2,12+row,37+row*3)
   b:triangle("DomainPanelA_"..row.."_"..col,a,c,d,color,.5,Enum.Material.SmoothPlastic)
   b:triangle("DomainPanelB_"..row.."_"..col,a,d,e,color,.5,Enum.Material.SmoothPlastic)
  end
 end
 for col=0,sectors-1,2 do
  for row=0,bands-1 do
   b:line("DomainMeridian_"..col.."_"..row,point(row,col)*.997,point(row+1,col)*.997,.2,.2,
    Color3.fromRGB(94,43,143),Enum.Material.Neon)
  end
 end
 for i=1,34 do
  local angle=i*2.399963;local r=75+(i%5)*9
  local position=V(math.cos(angle)*r,137+(i%4)*5,math.sin(angle)*r)
  b:ball("DomainStar_"..i,.3+(i%3)*.12,C(position),Color3.fromRGB(235,202,255),Enum.Material.Neon)
 end
 -- A dark backstop fills any view outside the faceted hemisphere.
 for _,side in ipairs({-1,1}) do
  b:box("DomainBackstopX"..side,V(1,1200,1200),C(side*600,0,0),Color3.fromRGB(17,9,29),Enum.Material.Neon)
  b:box("DomainBackstopZ"..side,V(1200,1200,1),C(0,0,side*600),Color3.fromRGB(17,9,29),Enum.Material.Neon)
 end
 b:box("DomainBackstopTop",V(1200,1,1200),C(0,600,0),Color3.fromRGB(17,9,29),Enum.Material.Neon)
 return b:finish()
end
function W.buildBackground(world)
 local old=world.folder:FindFirstChild("BackgroundArt");if old then old:Destroy() end
 local root=group(world.folder,"BackgroundArt")
 W.domain(root)
 L.create(root,{model="riftPortal",name="OrnateRiftFrame",cframe=C(119,0,0)})
 E.mirrorForcePlanet(root,C(14,106,-152)*A(0,math.pi,0))
 return root
end
function W.addDecorations(world)
 local previous=world.folder:FindFirstChild("DetailedLandmarks")
 if previous then previous:Destroy() end
 local phase=world.folder:FindFirstChild("PhaseDecor")
 if phase then
  for _,name in ipairs({"MidnightLotus","LotusScenicPedestal","LotusGem","RiftArchiveCard"}) do
   local old=phase:FindFirstChild(name);if old then old:Destroy() end
  end
 end
 local root=group(world.folder,"DetailedLandmarks")
 L.create(root,{model="blackLotus",name="MidnightLotus",scale=2,cframe=C(-70,31,106)})
 L.create(root,{model="squidHouse",name="SquidwardHouse",scale=1.5,cframe=C(-94,14,-114)*A(0,math.pi,0)})
 -- The Egyptian Gods are displayed as one framed painting, built client side.
 for _,x in ipairs({-125,125}) do
  L.create(root,{model="clashTower",name="CrownArenaTower",scale=1.1,cframe=C(x,24,28)})
 end
 E.racetrack(root)
 E.crimsonDragon(root,C(-84,68,114))
 E.shenron(root,C(92,66,-120)*A(0,math.pi,0))
 return root
end
return W

