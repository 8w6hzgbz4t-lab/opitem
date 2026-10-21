-- Original small procedural collectibles; no scripts inside art or external assets.
local M={}
local gold=Color3.fromRGB(232,182,64); local silver=Color3.fromRGB(178,194,211)
local dark=Color3.fromRGB(32,38,52); local teal=Color3.fromRGB(55,220,212)
local green=Color3.fromRGB(57,224,120); local purple=Color3.fromRGB(171,102,245)
local wood=Color3.fromRGB(113,67,38)
function M.build(d,m,F)
 local function p(n,x,y,z,sx,sy,sz,c,mat,rot)
  return F.part(m,n,Vector3.new(sx,sy,sz),CFrame.new(x,y,z)*(rot or CFrame.new()),c or silver,mat or Enum.Material.Metal)
 end
 local function ball(n,x,y,z,size,c,mat)
  local a=p(n,x,y,z,size,size,size,c,mat); a.Shape=Enum.PartType.Ball; return a
 end
 local function beam(n,a,b,w,c,mat)
  return F.part(m,n,Vector3.new(w,w,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),c,mat or Enum.Material.Metal)
 end
 local function ring(n,x,y,z,r,c,segments)
  for i=0,(segments or 20)-1 do
   local a=i*math.pi*2/(segments or 20); local b=(i+1)*math.pi*2/(segments or 20)
   beam(n,Vector3.new(x+math.cos(a)*r,y+math.sin(a)*r,z),Vector3.new(x+math.cos(b)*r,y+math.sin(b)*r,z),.09,c)
  end
 end
 local function wedge(n,size,cf,c)
  local a=Instance.new('WedgePart'); a.Name=n; a.Size=size; a.CFrame=cf
  a.Anchored=true; a.CanCollide=false; a.CanTouch=false; a.CanQuery=false
  a.Material=Enum.Material.Metal; a.Color=c; a.Parent=m; return a
 end
 local k=d.model
 if k=='triforce' then
  -- Three solid triangular prisms with a genuine open triangular center.
  local width=1.6;local height=width*math.sqrt(3)/2
  for index,point in ipairs({Vector2.new(-width/2,0),Vector2.new(width/2,0),Vector2.new(0,height)}) do
   for _,side in ipairs({-1,1}) do
    local right=Vector3.new(0,0,side);local up=Vector3.yAxis;local back=Vector3.new(-side,0,0)
    local center=Vector3.new(point.X+side*width/4,point.Y+height/2+.15,0)
    wedge('GoldenTriangle'..index,Vector3.new(.32,height,width/2),CFrame.fromMatrix(center,right,up,back),gold)
    local faceCenter=Vector3.new(point.X+side*width*.23,point.Y+height*.51+.15,-.175)
    wedge('PolishedFacet'..index,Vector3.new(.035,height*.9,width*.45),CFrame.fromMatrix(faceCenter,right,up,back),Color3.fromRGB(255,220,104))
   end
  end
 elseif k=='ironArmor' then
  local red=Color3.fromRGB(163,38,44);local pale=Color3.fromRGB(160,235,255)
  p('ChestArmor',0,2.15,0,1.2,1.2,.65,red)
  p('ChestFacet',0,2.45,-.36,1.05,.3,.12,gold)
  ball('ReactorHousing',0,2.25,-.36,.4,silver)
  ball('ArcReactor',0,2.25,-.53,.24,pale,Enum.Material.Neon)
  p('CompleteHelmet',0,3.13,0,.82,.85,.7,red)
  p('GoldFaceplate',0,3.12,-.38,.65,.68,.12,gold)
  for _,side in ipairs({-1,1}) do
   p('HelmetEye',side*.17,3.22,-.46,.2,.06,.04,pale,Enum.Material.Neon)
   p('ShoulderArmor',side*.83,2.62,0,.55,.55,.7,red)
   p('UpperArm',side*.9,2.13,0,.38,.65,.42,gold)
   p('ForearmGauntlet',side*.96,1.58,0,.45,.6,.52,red)
   p('Hand',side*.96,1.2,-.02,.4,.3,.45,red)
   ball('PalmRepulsor',side*.96,1.25,-.27,.16,pale,Enum.Material.Neon)
   p('ThighArmor',side*.34,1.13,0,.48,.68,.52,gold)
   p('KneeArmor',side*.34,.73,-.1,.51,.28,.55,red)
   p('ShinArmor',side*.34,.35,0,.5,.65,.58,red)
   p('Boot',side*.34,-.02,-.15,.54,.25,.85,red)
  end
  p('WaistArmor',0,1.5,0,1,.3,.65,red)
 elseif k=='buster' then
  p('WrappedGrip',0,.2,0,.28,1,.32,dark)
  for i=0,5 do p('GripBand',0,-.2+i*.14,0,.3,.045,.34,wood) end
  p('Guard',0,.76,0,1.6,.18,.5,dark)
  p('BroadBladeSpine',-.15,2,0,1.05,2.3,.23,Color3.fromRGB(113,133,153))
  -- Real triangular wedges taper each blade face down to a narrow cutting ridge.
  wedge('FrontCuttingBevel',Vector3.new(2.3,.17,.4),CFrame.new(.57,2,-.055)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(224,235,244))
  wedge('BackCuttingBevel',Vector3.new(2.3,.17,.4),CFrame.new(.57,2,.055)*CFrame.Angles(0,math.pi,math.pi/2),silver)
  wedge('AngularTip',Vector3.new(.23,.8,1.45),CFrame.new(.03,3.5,0)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(192,211,227))
  p('CuttingRidge',.77,2,0,.025,2.3,.025,Color3.fromRGB(245,248,255))
  for _,y in ipairs({1.1,1.5}) do
   ball('MateriaSocket',-.35,y,-.15,.22,dark); ball('SocketCore',-.35,y,-.24,.12,teal,Enum.Material.Glass)
  end
  p('SpineFacet',-.57,2,0,.12,2.25,.26,dark)
 elseif k=='jellyNet' then
  p('LongWoodHandle',0,.85,0,.14,2.7,.14,wood,Enum.Material.Wood)
  p('GripWrap',0,-.25,0,.21,.45,.21,Color3.fromRGB(214,179,117),Enum.Material.Fabric)
  ring('CircularHoop',0,2.9,0,.86,silver,24)
  -- Curved mesh basket: bounded hoop chords plus radial strands.
  for i=-3,3 do
   local offset=i*.21; local half=math.sqrt(.86*.86-offset*offset)
   beam('NetHorizontal',Vector3.new(-half,2.9+offset,.12),Vector3.new(half,2.9+offset,.12),.027,Color3.fromRGB(219,239,232),Enum.Material.Fabric)
   beam('NetVertical',Vector3.new(offset,2.9-half,.15),Vector3.new(offset,2.9+half,.15),.027,Color3.fromRGB(219,239,232),Enum.Material.Fabric)
  end
  for i=0,7 do local a=i*math.pi/4
   beam('BasketStrand',Vector3.new(math.cos(a)*.86,2.9+math.sin(a)*.86,0),Vector3.new(0,2.55,.65),.03,silver,Enum.Material.Fabric)
  end
-- A tiny captured jellyfish, tucked behind the hoop inside its mesh basket.
local pink=Color3.fromRGB(245,148,209)
local dome=p('JellyfishBell',0,3.02,.4,.72,.46,.46,pink,Enum.Material.SmoothPlastic);dome.Shape=Enum.PartType.Ball
local rim=p('JellyfishRim',0,2.87,.4,.74,.1,.48,Color3.fromRGB(223,106,184));rim.Shape=Enum.PartType.Ball
for _,side in ipairs({-1,1}) do
 ball('JellyfishEye',side*.12,3.03,.155,.07,dark)
 ball('JellyfishSpot',side*.21,3.12,.19,.09,Color3.fromRGB(192,82,170))
end
for i=-1,1 do
 local x=i*.18
 beam('JellyfishTentacle',Vector3.new(x,2.85,.4),Vector3.new(x+i*.04,2.65,.44),.055,pink,Enum.Material.SmoothPlastic)
 beam('JellyfishTentacleCurl',Vector3.new(x+i*.04,2.65,.44),Vector3.new(x-i*.05,2.53,.4),.045,pink,Enum.Material.SmoothPlastic)
end
 elseif k=='faceMask' then
  local clear=Color3.fromRGB(181,211,231)
  for _,side in ipairs({-1,1}) do
   local shield=p('ClearCheekShield',side*.56,1.3,0,.8,1.2,.12,clear,Enum.Material.Glass,CFrame.Angles(0,side*.24,side*.08)); shield.Transparency=.24
   ring('EyeOpeningRim',side*.43,1.85,-.12,.3,dark,16)
   p('TempleStrap',side*.95,1.7,.33,.12,.25,.85,dark,Enum.Material.Fabric)
   p('VentSlot',side*.58,1.1,-.09,.36,.06,.04,dark)
   ball('StrapRivet',side*.84,1.6,-.11,.11,silver)
  end
  p('BrowBridge',0,2.18,0,1.75,.14,.16,dark)
  p('NoseGuard',0,1.55,-.2,.27,.82,.3,clear,Enum.Material.Glass).Transparency=.15
  p('LowerBridge',0,.83,.02,1.1,.12,.15,dark)
  p('RearElastic',0,1.7,.8,1.8,.18,.12,dark,Enum.Material.Fabric)
 elseif k=='brolyJewelry' then
  ring('GoldTorque',0,2,0,.85,gold,24)
  for i=0,9 do local a=math.pi+i*math.pi/9
   ball('ChainBead',math.cos(a)*.86,2+math.sin(a)*.86,-.05,.17,gold)
  end
  p('PendantFrame',0,.77,0,.95,1.15,.3,gold)
  p('EmeraldPendant',0,.8,-.2,.65,.75,.2,green,Enum.Material.Glass,CFrame.Angles(0,0,math.pi/4))
  for _,side in ipairs({-1,1}) do
   ring('Bracelet',side*1.25,.8,0,.36,gold,14)
   ball('BraceletGem',side*1.25,1.15,-.09,.22,purple,Enum.Material.Glass)
  end
 elseif k=='pokeBall' then
  ball('WhiteShell',0,1.3,0,1.9,Color3.new(.94,.96,1))
  local top=p('RedCrown',0,1.78,0,1.65,.95,1.65,Color3.fromRGB(229,65,71));top.Shape=Enum.PartType.Ball
  local band=p('EquatorBand',0,1.3,0,1.94,.13,1.94,dark);band.Shape=Enum.PartType.Ball
  ball('ButtonRim',0,1.3,-.9,.48,dark);ball('CatchButton',0,1.3,-1.08,.29,Color3.new(1,1,1))
 elseif k=='evolutionStone' or k=='fireStone' or k=='waterStone' or k=='arkenstone' then
  local c=k=='arkenstone' and Color3.fromRGB(192,227,255) or (k=='fireStone' and Color3.fromRGB(241,115,67) or (k=='waterStone' and Color3.fromRGB(67,159,229) or Color3.fromRGB(232,195,64)))
  p('StoneCore',0,1.35,0,1.25,1.65,1,c,Enum.Material.Glass,CFrame.Angles(.2,0,.3)).Transparency=.15
  for _,side in ipairs({-1,1}) do p('CrystalFacet',side*.52,1.35,0,.35,1.35,.9,side<0 and teal or silver,Enum.Material.Glass,CFrame.Angles(0,0,-side*.3)) end
  if k=='fireStone' then
   ball('EmberGlyph',0,1.35,-.58,.4,Color3.fromRGB(255,214,105),Enum.Material.Neon)
   wedge('FlameTip',Vector3.new(.08,.5,.3),CFrame.new(0,1.72,-.58)*CFrame.Angles(0,math.pi/2,0),gold)
  elseif k=='waterStone' then
   ball('DropletGlyph',0,1.35,-.58,.35,teal,Enum.Material.Glass)
   wedge('DropletTip',Vector3.new(.08,.35,.25),CFrame.new(0,1.6,-.58)*CFrame.Angles(0,math.pi/2,0),teal)
  elseif k=='evolutionStone' then
   beam('LightningGlyph',Vector3.new(-.12,1.95,-.58),Vector3.new(.12,1.4,-.58),.1,green,Enum.Material.Neon)
   beam('LightningGlyph',Vector3.new(.12,1.4,-.58),Vector3.new(-.16,.9,-.58),.1,green,Enum.Material.Neon)
  else
   ring('GoldDisplaySetting',0,.45,0,.6,gold,16)
   ball('InnerLight',0,1.4,-.4,.3,Color3.fromRGB(231,245,255),Enum.Material.Neon)
  end
 elseif k=='legendFeather' then
  beam('FeatherQuill',Vector3.new(-.55,.1,0),Vector3.new(.55,3.1,0),.09,gold)
  for i=1,12 do
   local y=.35+i*.2;local x=(y-.1)/3*1.1-.55; local width=math.sin(i/13*math.pi)*.7
   local c=Color3.fromHSV((i-1)/14,.55,.95)
   for _,s in ipairs({-1,1}) do beam('PrismaticBarb',Vector3.new(x,y,0),Vector3.new(x+s*width,y+.3,0),.12,c) end
  end
 elseif k=='millenniumRod' then
  p('GoldStaff',0,1.2,0,.2,2.7,.2,gold)
  ball('EyeFrame',0,2.7,0,.8,gold)
  p('EyeInlay',0,2.7,-.4,.5,.23,.06,dark)
  ball('EyePupil',0,2.7,-.45,.14,teal,Enum.Material.Glass)
  for _,side in ipairs({-1,1}) do p('WingFlange',side*.63,2.65,0,.8,.18,.2,gold,nil,CFrame.Angles(0,0,side*.22)) end
 elseif k=='duelDisk' then
  p('WristMount',-.6,.9,0,.8,.7,.8,dark)
  p('CardRail',0,1.4,0,2.9,.25,.9,silver,nil,CFrame.Angles(0,0,.15))
  for i=0,4 do
   p('CardSlot',-1.1+i*.55,1.58+i*.08,-.04,.45,.055,.65,dark)
   p('CardInsert',-1.1+i*.55,1.62+i*.08,-.04,.34,.03,.5,Color3.fromRGB(108,78,147))
  end
  ball('LifeDial',-.8,1.2,-.48,.45,teal,Enum.Material.Neon)
 elseif string.sub(k,1,6)=='exodia' then
  if k=='exodiaHead' then
   p('GoldTorso',0,1.2,0,1.8,1.5,.85,gold)
   p('AncientHead',0,2.4,0,1.05,1,.8,gold)
   p('SculptedNose',0,2.38,-.48,.15,.3,.22,gold)
   p('MouthInset',0,2.15,-.43,.36,.045,.04,dark)
   for _,side in ipairs({-1,1}) do p('CheekFacet',side*.35,2.28,-.43,.2,.3,.12,gold);p('BrowRidge',side*.22,2.55,-.45,.32,.08,.1,gold) end
   for layer=0,2 do p('LayeredHeadgear',0,2.85+layer*.12,0,1.18+layer*.12,.11,.88+layer*.06,gold) end
   p('ForeheadGem',0,2.83,-.5,.21,.21,.08,teal,Enum.Material.Glass,CFrame.Angles(0,0,math.pi/4))
   for i=-2,2 do p('CrownRay',i*.27,3.05,0,.15,.6,.3,gold,nil,CFrame.Angles(0,0,-i*.12)) end
   for _,s in ipairs({-1,1}) do p('Eye',s*.22,2.45,-.43,.23,.07,.05,teal,Enum.Material.Neon) end
   p('ChestSeal',0,1.3,-.5,.5,.5,.1,teal,Enum.Material.Glass,CFrame.Angles(0,0,math.pi/4))
  else
   local isArm=string.find(k,'Arm')~=nil; local side=string.find(k,'Left') and -1 or 1
   p('SealedLimb',0,1.5,0,.65,1.8,.65,gold,nil,CFrame.Angles(0,0,side*.15))
   p('EngravedCuff',0,1.15,0,.85,.35,.85,dark)
   p(isArm and 'Fist' or 'Foot',side*.12,.45,isArm and 0 or -.2,.85,.65,isArm and .85 or 1.25,gold)
   for i=0,2 do p('SealMark',-.2+i*.2,1.7,-.35,.07,.4,.05,teal,Enum.Material.Neon) end
   ring('BindingChain',0,2.3,0,.46,gold,12)
  end
 elseif k=='diamondAxe' or k=='enchantedPickaxe' then
  for i=0,8 do p('PixelHandle',0,.1+i*.26,0,.22,.27,.22,wood,Enum.Material.Wood) end
  if k=='diamondAxe' then
   for x=0,3 do for y=0,2 do if x<3 or y>0 then p('DiamondAxePixel',.12+x*.25,2.05+y*.25,0,.25,.25,.22,teal) end end end
  else
   for x=-4,4 do p('PickHeadPixel',x*.25,2.4-math.abs(x)*.08,0,.26,.26,.22,teal) end
   for _,s in ipairs({-1,1}) do for i=1,2 do p('PickTip',s*(1+i*.03),2.05-i*.2,0,.22,.22,.22,teal) end end
   for i=0,3 do p('EnchantmentRune',0,1.35+i*.25,-.13,.14,.06,.03,purple,Enum.Material.Neon) end
  end
 elseif k=='endCrystal' then
  p('ObsidianBase',0,.3,0,1.8,.4,1.8,dark,Enum.Material.Slate)
  p('CrystalCore',0,1.65,0,1.1,1.1,1.1,purple,Enum.Material.Neon,CFrame.Angles(.55,.4,.6)).Transparency=.3
  for _,x in ipairs({-.72,.72}) do for _,z in ipairs({-.72,.72}) do p('GlassCagePost',x,1.65,z,.07,2.4,.07,silver,Enum.Material.Glass) end end
  for _,y in ipairs({.48,2.85}) do
   for _,s in ipairs({-1,1}) do p('GlassCageBar',s*.72,y,0,.07,.07,1.5,silver);p('GlassCageBar',0,y,s*.72,1.5,.07,.07,silver) end
  end
 elseif k=='commandBlock' then
  p('CommandCube',0,1.4,0,1.8,1.8,1.8,Color3.fromRGB(197,135,80))
  for _,s in ipairs({-1,1}) do
   p('FacePanel',0,1.4,s*.92,1.35,1.35,.06,Color3.fromRGB(232,199,155))
   for i=-1,1 do for j=-1,1 do p('CommandPixel',i*.32,1.4+j*.32,s*.97,.16,.16,.04,(i+j)%2==0 and dark or gold) end end
   p('SidePort',s*.92,1.4,0,.05,.7,.7,dark)
  end
 elseif k=='sting' or k=='gunblade' then
  p('Grip',0,.2,0,.26,.9,.3,wood)
  p('Guard',0,.75,0,k=='sting' and 1.1 or 1.4,.18,.3,silver)
  p('Blade',0,1.9,0,k=='sting' and .35 or .65,2.2,.15,silver)
  wedge('TaperedPoint',Vector3.new(.15,.6,k=='sting' and .35 or .65),CFrame.new(0,3.25,0)*CFrame.Angles(0,math.pi/2,0),silver)
  if k=='sting' then
   for i=0,4 do p('BlueRunes',0,1.1+i*.35,-.085,.15,.09,.025,teal,Enum.Material.Neon) end
  else
   local cylinder=p('RevolverCylinder',.4,.9,0,.45,.6,.45,dark);cylinder.Shape=Enum.PartType.Cylinder
   p('Trigger',.4,.45,0,.35,.3,.16,silver)
   for i=0,3 do ball('CylinderRivet',.65,.7+i*.12,-.1,.06,gold) end
  end
 elseif k=='dwarfTreasure' then
  p('Chest',0,.7,0,2,1,1.25,wood,Enum.Material.WoodPlanks)
  p('OpenLid',0,1.6,.45,2,.2,1.25,wood,Enum.Material.WoodPlanks,CFrame.Angles(-.8,0,0))
  for _,s in ipairs({-1,1}) do p('GoldBinding',s*.7,.8,-.65,.12,.9,.05,gold) end
  for i=0,8 do
   local coin=p('Coin',-.7+(i%3)*.65,1.25+math.floor(i/3)*.06,-.35+math.floor(i/3)*.3,.35,.07,.35,gold);coin.Shape=Enum.PartType.Cylinder;coin.CFrame=coin.CFrame*CFrame.Angles(0,0,math.pi/2)
  end
  ball('TreasureGem',.3,1.5,-.15,.45,purple,Enum.Material.Glass)
 elseif k=='materia' then
  ball('MateriaOrb',0,1.4,0,1.65,green,Enum.Material.Glass).Transparency=.18
  ball('LifestreamCore',0,1.4,0,.65,teal,Enum.Material.Neon)
  ring('BronzeSetting',0,.6,0,.65,gold,20)
 else return false end
 return true
end
return M

