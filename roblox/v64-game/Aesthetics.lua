-- Original procedural scenery. No assets, particles, or frame callbacks.
local A={}
local C={stone=Color3.fromRGB(80,75,91),dark=Color3.fromRGB(32,32,48),gold=Color3.fromRGB(218,171,75),glow=Color3.fromRGB(126,237,218),wood=Color3.fromRGB(103,53,37),roof=Color3.fromRGB(38,64,74)}
local function group(parent,name)
 local m=Instance.new('Model'); m.Name=name; m.Parent=parent; return m
end
local function part(parent,name,size,cf,color,material)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic; p.Anchored=true
 p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent; return p
end
local function beam(parent,name,a,b,width,color,material)
 return part(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material)
end
function A.pillars(parent)
 local g=group(parent,'CelestialArenaPillars')
 -- Beyond the vault side walls, away from the portal and the central lane.
 for _,x in ipairs({-126,126}) do for _,z in ipairs({-84,-42,42,84}) do
  local m=group(g,'ArenaPillar')
  for _,v in ipairs({{0,1,11,2},{2,3,8,2},{5,20,5.5,32},{37,1,8,2},{40,1,10,2}}) do
   part(m,'StoneTier',Vector3.new(v[3],v[4],v[3]),CFrame.new(x,v[1]+v[4]/2,z),C.stone,Enum.Material.Slate)
  end
  for _,y in ipairs({5,15,26,37,41}) do
   part(m,'GoldCollar',Vector3.new(6.2,.45,6.2),CFrame.new(x,y,z),C.gold,Enum.Material.Metal)
  end
  for _,sx in ipairs({-1,1}) do
   part(m,'RunicInset',Vector3.new(.16,23,.22),CFrame.new(x+sx*2.8,21,z),C.glow,Enum.Material.Neon)
  end
 end end
 for _,p in ipairs(g:GetDescendants()) do if p:IsA('BasePart') and p.Name=='StoneTier' then p.CanCollide=true;p.CanQuery=true end end
end
function A.monument(parent)
 local g=group(parent,'FivePieceAncientGuardian')
 local origin=CFrame.new(-40,0,-103)*CFrame.Angles(0,math.pi,0)
 local function p(m,n,s,x,y,z,c,mat,rot)
  return part(m,n,s,origin*CFrame.new(x,y,z)*(rot or CFrame.new()),c,mat)
 end
 p(g,'FloatingStoneDais',Vector3.new(47,5,28),0,-1,0,C.dark,Enum.Material.Slate)
 p(g,'GoldDaisEdge',Vector3.new(44,.4,25),0,1.8,0,C.gold,Enum.Material.Metal)
 p(g,'AncientStoneTop',Vector3.new(42,1,23),0,2.4,0,C.stone,Enum.Material.Slate)
 local torso=group(g,'CentralHeadTorso')
 p(torso,'Torso',Vector3.new(11,12,5),0,21,0,C.stone,Enum.Material.Slate)
 p(torso,'ChestPlate',Vector3.new(9,7,.6),0,22,-2.8,C.gold,Enum.Material.Metal)
 p(torso,'Waist',Vector3.new(12,2,6),0,14.5,0,C.gold,Enum.Material.Metal)
 p(torso,'Head',Vector3.new(6,7,5),0,31,0,C.stone,Enum.Material.Slate)
 p(torso,'SculptedNose',Vector3.new(1,1.8,1),0,30.8,-2.9,C.gold,Enum.Material.Metal)
 p(torso,'MouthInset',Vector3.new(2,.3,.15),0,29.6,-2.65,C.dark)
 for _,side in ipairs({-1,1}) do
  p(torso,'CheekFacet',Vector3.new(1.4,2,.65),side*2.1,30.3,-2.5,C.gold,Enum.Material.Metal,CFrame.Angles(0,0,side*.15))
  p(torso,'BrowRidge',Vector3.new(2,.45,.6),side*1.4,31.5,-2.7,C.gold,Enum.Material.Metal)
 end
 for layer=0,3 do p(torso,'LayeredHeadgear',Vector3.new(7.2+layer*.4,.45,5.6+layer*.2),0,33.2+layer*.5,0,C.gold,Enum.Material.Metal) end
 p(torso,'ForeheadGem',Vector3.new(.9,.9,.3),0,33.5,-3.1,C.glow,Enum.Material.Glass,CFrame.Angles(0,0,math.pi/4))
 p(torso,'CrownBand',Vector3.new(8,1,6),0,34,0,C.gold,Enum.Material.Metal)
 for i=-2,2 do p(torso,'CrownRay',Vector3.new(.8,3+math.abs(i),1),i*1.6,36,0,C.gold,Enum.Material.Metal) end
 for _,x in ipairs({-1.4,1.4}) do p(torso,'QuietEye',Vector3.new(1.3,.35,.2),x,31,-2.6,C.glow,Enum.Material.Neon) end
 local emblem=p(torso,'ChestSigil',Vector3.new(2.7,2.7,.3),0,22,-3.2,C.glow,Enum.Material.Neon,CFrame.Angles(0,0,math.pi/4)); emblem.Transparency=.35
 for _,side in ipairs({-1,1}) do
  local arm=group(g,side<0 and 'LeftArm' or 'RightArm')
  p(arm,'ShoulderArmor',Vector3.new(5,4,6),side*9,25,0,C.gold,Enum.Material.Metal)
  p(arm,'UpperArm',Vector3.new(4,7,4),side*10,20,0,C.stone,Enum.Material.Slate)
  p(arm,'Bracer',Vector3.new(5,3,5),side*11,15,0,C.gold,Enum.Material.Metal)
  p(arm,'ClosedHand',Vector3.new(4.5,4,4.5),side*11,11.5,0,C.stone,Enum.Material.Slate)
  local leg=group(g,side<0 and 'LeftLeg' or 'RightLeg')
  p(leg,'Thigh',Vector3.new(4.5,5,4.5),side*3.8,10.5,0,C.stone,Enum.Material.Slate)
  p(leg,'KneeGuard',Vector3.new(5,2,5),side*3.8,8,0,C.gold,Enum.Material.Metal)
  p(leg,'Shin',Vector3.new(4,4,4),side*3.8,5.5,0,C.stone,Enum.Material.Slate)
  p(leg,'Foot',Vector3.new(5,2,7),side*3.8,3.5,-1,C.gold,Enum.Material.Metal)
 end
 for _,x in ipairs({-18,18}) do
  p(g,'Obelisk',Vector3.new(3,13,3),x,9,4,C.stone,Enum.Material.Slate)
  p(g,'ObeliskRune',Vector3.new(.4,8,.15),x,9,2.4,C.glow,Enum.Material.Neon)
 end
 -- Scale the existing five-part design rather than replacing it.
 g:ScaleTo(1.3)
 local lifted=origin*CFrame.new(0,20,0)
 g:PivotTo(lifted*origin:Inverse()*g:GetPivot())
 for _,name in ipairs({'LeftArm','RightArm'}) do
  local arm=g[name];local side=name=='LeftArm' and -1 or 1
  local shoulder=arm.ShoulderArmor.CFrame
  arm:PivotTo(shoulder*CFrame.Angles(0,0,side*math.rad(138))*shoulder:Inverse()*arm:GetPivot())
 end
 part(parent,'MonumentRaisedPlinth',Vector3.new(60,20,40),CFrame.new(-40,8,-103),C.dark,Enum.Material.Slate)
end
function A.tower(parent)
 local g=group(parent,'SunlitBellPagoda'); local cx,cz=44,110
 part(g,'ScenicIsland',Vector3.new(40,5,35),CFrame.new(cx,-1,cz),C.stone,Enum.Material.Slate)
 part(g,'GardenMoss',Vector3.new(37,.4,32),CFrame.new(cx,1.7,cz),Color3.fromRGB(87,124,97),Enum.Material.Grass)
 for tier=0,3 do
  local y=3+tier*12; local width=25-tier*4
  part(g,'TimberFloor',Vector3.new(width,1,width),CFrame.new(cx,y,cz),C.wood,Enum.Material.WoodPlanks)
  for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
   part(g,'TimberColumn',Vector3.new(1,9,1),CFrame.new(cx+sx*(width/2-2),y+5,cz+sz*(width/2-2)),C.wood,Enum.Material.Wood)
  end end
  -- Segmented eaves rise at their outer edges to suggest curved roofs.
  for _,side in ipairs({-1,1}) do for segment=0,2 do
   local span=(width/2+2)/3
   local dy=({2.1,.5,.9})[segment+1]
   part(g,'CurvedRoofPanel',Vector3.new(span+.2,.6,width+5),CFrame.new(cx+side*(segment+.5)*span,y+10+dy,cz)*CFrame.Angles(0,0,side*({-.36,-.12,.25})[segment+1]),C.roof,Enum.Material.Slate)
  end end
  for _,z in ipairs({-1,1}) do
   beam(g,'GoldEave',Vector3.new(cx-width/2-2,y+11,cz+z*(width/2+2.6)),Vector3.new(cx+width/2+2,y+11,cz+z*(width/2+2.6)),.2,C.gold,Enum.Material.Metal)
  end
 end
 -- Visible in the open top storey, including from the plaza below.
 part(g,'BellHanger',Vector3.new(.3,2,.3),CFrame.new(cx,46,cz),C.gold,Enum.Material.Metal)
 local bell=part(g,'BronzeBell',Vector3.new(4.5,5,4.5),CFrame.new(cx,42.5,cz),C.gold,Enum.Material.Metal)
 bell.Shape=Enum.PartType.Cylinder; bell.CFrame=bell.CFrame*CFrame.Angles(0,0,math.pi/2)
 part(g,'BellLip',Vector3.new(5,.6,5),CFrame.new(cx,40,cz),C.gold,Enum.Material.Metal)
 part(g,'Clapper',Vector3.new(.5,1.8,.5),CFrame.new(cx,39.5,cz),C.dark,Enum.Material.Metal)
 part(g,'RoofFinial',Vector3.new(.6,5,.6),CFrame.new(cx,53,cz),C.gold,Enum.Material.Metal)
 for _,x in ipairs({-9,9}) do
  local lantern=part(g,'WarmLantern',Vector3.new(1.5,2,1.5),CFrame.new(cx+x,7,cz-10),Color3.fromRGB(255,203,123),Enum.Material.Neon)
  local light=Instance.new('PointLight'); light.Color=lantern.Color; light.Brightness=.65; light.Range=14; light.Shadows=false; light.Parent=lantern
 end
end
function A.roofs(parent,bases)
 local g=group(parent,'VaultRoofs')
 for index,b in ipairs(bases) do
  local m=group(g,'BaseRoof'..index); m:SetAttribute('BaseCF',b.cf)
  local accent=Color3.fromHSV((index-1)/#bases,.38,.8)
  -- A fitted slab covers the 48 x 48 floor plus the outer pillar edges.
  -- Client-only transparency handles camera occlusion; physics stays unchanged.
  part(m,'FittedRoof',Vector3.new(50,1,50),b.cf*CFrame.new(0,18,0),C.roof,Enum.Material.Metal)
  for _,sx in ipairs({-1,1}) do
   part(m,'UpperSideWall',Vector3.new(1,8,48),b.cf*CFrame.new(sx*24,13.5,0),C.dark,Enum.Material.Slate)
   part(m,'SideEaveTrim',Vector3.new(.2,.2,48),b.cf*CFrame.new(sx*23.8,18.55,0),accent,Enum.Material.Neon)
   part(m,'FrontPillarExtension',Vector3.new(4,5.5,4),b.cf*CFrame.new(sx*20,14.75,-23),C.dark)
  end
  part(m,'UpperBackWall',Vector3.new(48,6,1),b.cf*CFrame.new(0,14.5,24),C.dark,Enum.Material.Slate)
  part(m,'FittedEntranceHeader',Vector3.new(48,4.5,2),b.cf*CFrame.new(0,15.25,-23),C.roof)
  part(m,'FrontEaveTrim',Vector3.new(48,.2,.25),b.cf*CFrame.new(0,18.55,-23.8),accent,Enum.Material.Neon)
  for _,p in ipairs(m:GetDescendants()) do if p:IsA('BasePart') and not string.find(p.Name,'Trim') then p.CanCollide=true;p.CanQuery=true end end
 end
end
function A.stoneHead(parent)
 local g=group(parent,'TidalStoneHead'); local center=Vector3.new(-94,14,-110)
 local function p(n,s,x,y,z,c,mat)
  return part(g,n,s,CFrame.new(center+Vector3.new(x,y,z)),c or C.stone,mat or Enum.Material.Slate)
 end
 p('ScenicRockShelf',Vector3.new(30,5,28),0,-1,0,C.dark)
 p('TallStoneHead',Vector3.new(17,42,14),0,26,0,Color3.fromRGB(78,102,111))
 p('CrownRidge',Vector3.new(18,5,15),0,47,0)
 p('ProminentNose',Vector3.new(5,16,9),0,31,10,Color3.fromRGB(104,125,128))
 p('NoseTip',Vector3.new(6,4,6),0,24,13)
 for _,side in ipairs({-1,1}) do
  p('WindowStoneFrame',Vector3.new(5.5,6,.8),side*5,38,7.3,C.dark)
  p('WindowGlass',Vector3.new(4.1,4.7,.15),side*5,38,7.8,Color3.fromRGB(111,172,185),Enum.Material.Glass).Transparency=.2
  p('WindowMullion',Vector3.new(.22,4.7,.3),side*5,38,8,C.gold,Enum.Material.Metal)
  p('StoneBrow',Vector3.new(6,1.6,2),side*5,42,7.5)
 end
 p('DoorRecess',Vector3.new(5,10,.2),0,10,7.1,C.dark)
 p('DoorLintel',Vector3.new(7,1.2,1),0,15.5,7.4,C.gold)
end
function A.skyFlowers(parent)
 local g=group(parent,'PastelSkyFlowers')
 local sites={Vector3.new(-118,90,-150),Vector3.new(120,104,-155),Vector3.new(-85,86,145),Vector3.new(105,82,150)}
 local colors={Color3.fromRGB(211,168,225),Color3.fromRGB(156,213,204),Color3.fromRGB(243,194,174),Color3.fromRGB(182,194,237)}
 for index,center in ipairs(sites) do
  local m=group(g,'SkyFlower'..index)
  local function point(t)
   local radius=11+5*math.cos(5*t)
   return center+Vector3.new(math.cos(t)*radius,math.sin(t)*radius,0)
  end
  for i=0,59 do
   local petal=beam(m,'PastelPetalOutline',point(i*math.pi/30),point((i+1)*math.pi/30),.65,colors[index])
   petal.Transparency=.12; petal.CastShadow=false
  end
  for i=0,11 do
   local a=i*math.pi/6; local b=(i+1)*math.pi/6
   local centerRing=beam(m,'FlowerCenter',center+Vector3.new(math.cos(a)*2,math.sin(a)*2,0),center+Vector3.new(math.cos(b)*2,math.sin(b)*2,0),.5,colors[index])
   centerRing.Transparency=.12; centerRing.CastShadow=false
  end
 end
end
function A.sky(parent)
 local g=group(parent,'PrismaticSky')
 local colors={Color3.fromRGB(246,106,125),Color3.fromRGB(255,174,101),Color3.fromRGB(255,224,128),Color3.fromRGB(128,222,164),Color3.fromRGB(111,191,237),Color3.fromRGB(145,145,233),Color3.fromRGB(208,147,230)}
 for band,color in ipairs(colors) do
  local radius=94-band*1.5
  for i=0,39 do
   local a=i*math.pi/40; local b=(i+1)*math.pi/40
   local p=beam(g,'RainbowBand'..band,Vector3.new(math.cos(a)*radius,30+math.sin(a)*radius,-165),Vector3.new(math.cos(b)*radius,30+math.sin(b)*radius,-165),1.4,color,Enum.Material.Neon)
   p.Transparency=.12; p.CastShadow=false
  end
 end
 for _,center in ipairs({Vector3.new(-90,74,-145),Vector3.new(92,66,-150),Vector3.new(-45,96,146),Vector3.new(85,108,100)}) do
  for i=-2,2 do
   local cloud=part(g,'SoftCloud',Vector3.new(19,7+((i+2)%2)*3,12),CFrame.new(center+Vector3.new(i*10,math.cos(i)*2,0)),Color3.fromRGB(239,235,250))
   cloud.Shape=Enum.PartType.Ball; cloud.Transparency=.3; cloud.CastShadow=false
  end
 end
end
function A.applyLighting()
 local lighting=game:GetService('Lighting')
 lighting.ClockTime=15.5; lighting.Brightness=2
 lighting.Ambient=Color3.fromRGB(122,121,145); lighting.OutdoorAmbient=Color3.fromRGB(156,165,184)
 lighting.ExposureCompensation=0
 local atmosphere=lighting:FindFirstChildOfClass('Atmosphere')
 if not atmosphere then atmosphere=Instance.new('Atmosphere'); atmosphere.Name='AestheticsAtmosphere'; atmosphere.Parent=lighting end
 atmosphere.Density=.12; atmosphere.Offset=.05; atmosphere.Color=Color3.fromRGB(207,218,255)
 atmosphere.Decay=Color3.fromRGB(171,145,190); atmosphere.Glare=0; atmosphere.Haze=.25
 -- No bloom/color grading: collectible rarity colors and HUD remain legible.
end
-- Detailed replacements retain the same world anchors and roof camera contract.
local DetailedWorld=require(script.Parent.DetailedArt.WorldArt)
A.pillars=DetailedWorld.pillars
A.monument=DetailedWorld.monument
A.tower=DetailedWorld.tower
A.stoneHead=DetailedWorld.stoneHead
A.roofs=DetailedWorld.roofs
A.skyFlowers=DetailedWorld.skyFlowers
A.applyLighting=DetailedWorld.applyLighting
function A.build(world)
 local old=world.folder:FindFirstChild('Aesthetics'); if old then old:Destroy() end
 local root=Instance.new('Folder'); root.Name='Aesthetics'; root.Parent=world.folder
 A.pillars(root); A.monument(root); A.tower(root); A.stoneHead(root)
 A.roofs(root,world.bases); A.sky(root); A.skyFlowers(root)
 require(script.Parent.BackgroundArt).build(world)
 return root
end
return A
