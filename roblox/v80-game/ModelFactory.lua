-- Procedural collectible art; no external asset scripts.
local F={}
local SuppliedDesigns=require(script.Parent.FreeModels.FreeModels)
local suppliedKeys={
 stardust_dragon='stardust_dragon',
 blue_eyes_white_dragon='blue_eyes_white_dragon',
 michael_jackson_glove='michael_jackson_glove',
 tungs_bat='tungs_bat',
 moms_credit_card='moms_credit_card',
 sonic_gold_ring='sonic_gold_ring',
 captain_america_shield='captain_america_shield',
 transformers_allspark='transformers_allspark',transformers_matrix='transformers_matrix',optimus_energon_axe='optimus_energon_axe',
 item05='blue_shell',item43='dragon_balls',
 kirby_sword='kirby_sword',golden_spatula='golden_spatula',krabby_patty='krabby_patty',gary_shell='gary_shell',
 super_star='super_star',fire_flower='fire_flower',hylian_shield='hylian_shield',companion_cube='companion_cube',proton_pack='proton_pack',
 space_stone='infinity_space',mind_stone='infinity_mind',reality_stone='infinity_reality',power_stone='infinity_power',time_stone='infinity_time',soul_stone='infinity_soul',
 pekka='pekka',mega_knight='mega_knight',krabby_patty_formula='krabby_patty_formula',
}
local NewArt=require(script.Parent.DetailedArt.NewCollectibles)
local DetailedArt=require(script.Parent.DetailedArt.ItemArt)
local MillenniumPuzzle=require(script.Parent.MillenniumPuzzle)
local ExpandedModels=require(script.Parent.ExpandedModels)
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local gold=rgb(238,184,60); local steel=rgb(174,193,208); local dark=rgb(30,36,51)
local cyan=rgb(50,240,245); local purple=rgb(103,48,181); local green=rgb(54,255,114)
function F.part(parent,name,size,cf,color,material,shape)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=cf
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
 p.Color=color or steel; p.Material=material or Enum.Material.SmoothPlastic
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end
 p.Parent=parent; return p
end
function F.create(d,parent)
 local supplied=suppliedKeys[d.id]
 if supplied then return SuppliedDesigns.create(parent,{name=d.name,itemId=d.id,model=supplied}) end
 if NewArt.supports(d.model) then return NewArt.create(d,parent) end
 if d.id~='item08' and DetailedArt.supports(d.model) then
  return DetailedArt.create(parent,{name=d.name,itemId=d.id,model=d.model})
 end
 if d.id=='item08' then
  return MillenniumPuzzle.create(parent,{name=d.name,itemId=d.id})
 end
 local m=Instance.new('Model'); m.Name=d.name
 local root=F.part(m,'Root',Vector3.new(.1,.1,.1),CFrame.new(),dark); root.Transparency=1; m.PrimaryPart=root
 local function p(n,x,y,z,sx,sy,sz,c,mat,shape,rot)
  return F.part(m,n,Vector3.new(sx,sy,sz),CFrame.new(x,y,z)*(rot or CFrame.new()),c,mat,shape)
 end
 local function ball(n,x,y,z,s,c) return p(n,x,y,z,s,s,s,c,nil,Enum.PartType.Ball) end
 local function ring(n,x,y,z,r,c)
  for i=1,24 do local a=i*math.pi/12
   p(n,x+math.cos(a)*r,y+math.sin(a)*r,z,.2,.34,.2,c,Enum.Material.Metal,nil,CFrame.Angles(0,0,a-math.pi/2))
  end
 end
 local function inscription(part,word,color)
  local g=Instance.new('SurfaceGui'); g.Face=Enum.NormalId.Front; g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud=80; g.Parent=part
  local t=Instance.new('TextLabel'); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=word; t.TextScaled=true; t.TextColor3=color; t.Font=Enum.Font.GothamBold; t.Parent=g
 end
 local k=d.model
 if ExpandedModels.build(d,m,F) then
  -- New art and the beveled Buster Sword are supplied by the extension module.
 elseif k=='pixel' then
  p('BrownGrip',0,.1,0,.3,.9,.22,rgb(104,62,34))
  p('TealGuard',0,.65,0,1.2,.28,.23,rgb(23,116,119))
  for i=1,7 do
   p('DiamondPixel',0,.7+i*.32,0,.46,.34,.2,cyan)
   if i<7 then p('PixelEdge',.32,.7+i*.32,0,.2,.34,.2,rgb(28,164,178)) end
  end
 elseif k=='master' or k=='buster' then
  p('Grip',0,.15,0,.28,1,.3,k=='master' and purple or dark)
  p('Pommel',0,-.4,0,.4,.22,.4,gold,Enum.Material.Metal)
  p('Blade',0,2.05,0,k=='buster' and 1.3 or .55,2.5,.18,steel,Enum.Material.Metal)
  if k=='master' then
   p('WingGuard',0,.75,0,1.8,.22,.35,purple)
   for _,x in ipairs({-.75,.75}) do p('Wing',x,.92,0,.25,.55,.3,purple,nil,nil,CFrame.Angles(0,0,-x*.7)) end
   local emblem=p('Triforce',0,1.08,-.12,.34,.3,.04,gold); inscription(emblem,'▲',gold)
  else
   p('Guard',0,.72,0,1.5,.18,.4,dark)
   for _,y in ipairs({1.1,1.5}) do ball('MateriaSocket',-.25,y,-.13,.2,dark) end
   p('SharpenedEdge',.6,2.05,0,.09,2.5,.2,Color3.new(.95,.98,1))
  end
 elseif k=='energy' then
  p('Hilt',0,.4,0,.8,.35,.4,dark,Enum.Material.Metal)
  for _,x in ipairs({-.45,.45}) do
   p('PlasmaProng',x,1.85,0,.27,2.6,.17,cyan,Enum.Material.Neon,nil,CFrame.Angles(0,0,-x*.3))
   p('PlasmaTip',x*1.6,3,0,.18,.65,.17,cyan,Enum.Material.Neon,nil,CFrame.Angles(0,0,-x*.8))
  end
 elseif k=='gauntlet' then
  p('Cuff',0,.15,0,1.65,.5,1.1,gold,Enum.Material.Metal)
  p('Palm',0,1,0,1.5,1.4,.8,gold,Enum.Material.Metal)
  for i=1,4 do
   p('Finger',-.75+i*.3,2,0,.24,.9,.6,gold,Enum.Material.Metal)
   ball('InfinityStone',-.75+i*.3,1.8,-.46,.23,Color3.fromHSV((i-1)/6,1,1))
  end
  p('Thumb',-.9,1.1,0,.4,.95,.6,gold,nil,nil,CFrame.Angles(0,0,-.4))
  ball('MindStone',0,1,-.48,.4,rgb(255,232,37)); ball('TimeStone',-.9,1.2,-.35,.25,green)
 elseif k=='oneRing' then
  ring('GoldBand',0,1.4,0,1.1,gold); ring('InnerBand',0,1.4,.16,1.1,gold)
  for i=1,12 do local a=i*math.pi/6
   p('FieryInscription',math.cos(a)*1.1,1.4+math.sin(a)*1.1,-.13,.08,.19,.03,rgb(255,100,24),Enum.Material.Neon,nil,CFrame.Angles(0,0,a))
  end
 elseif k=='emerald' then
  local a=p('EmeraldCore',0,1.35,0,1.5,1.5,1.5,green,Enum.Material.Glass,nil,CFrame.Angles(0,0,math.pi/4)); a.Transparency=.12
  for _,side in ipairs({-1,1}) do p('CutFacet',side*.66,1.35,0,.55,1.25,1.2,rgb(20,171,78),Enum.Material.Glass,nil,CFrame.Angles(0,0,side*.45)) end
  p('CrownFacet',0,2.2,0,1.1,.3,1.1,rgb(144,255,185),Enum.Material.Neon)
 elseif k=='shell' then
  local a=p('BlueDome',0,1,0,2.1,1.5,2,Color3.fromRGB(28,87,235),nil,Enum.PartType.Ball)
  p('WhiteRim',0,.55,0,2.25,.22,2.1,Color3.new(1,1,1),nil,Enum.PartType.Ball)
  for _,x in ipairs({-1,1}) do
   p('Wing',x*1.4,1.2,.1,.85,.22,1.4,Color3.new(1,1,1),nil,nil,CFrame.Angles(0,0,x*.3))
   for i=1,3 do p('Feather',x*(1.2+i*.18),1.23,.35-i*.3,.25,.2,.7,steel) end
  end
  for i=-1,1 do p('Spike',i*.6,1.88,0,.22,.7,.22,Color3.new(1,1,1),nil,nil,CFrame.Angles(0,0,-i*.35)) end
 elseif k=='puzzle' then
  for i=1,24 do local w=i/24*2.6; p('PuzzleLayer',0,(i-1)*.095,0,w,.095,w,gold,Enum.Material.Metal) end
  ring('PendantLoop',0,2.7,0,.4,gold)
  for i=1,5 do p('Seam',0,.45+i*.31,-(.45+i*.31)/2.28*1.3-.03,.4+i*.36,.025,.03,dark) end
  local eye=p('EyePanel',0,1.6,-1.03,1.1,.5,.04,gold); inscription(eye,'◉',dark)
 elseif k=='hammer' then
  p('LeatherGrip',0,.5,0,.28,1.8,.28,rgb(105,63,34))
  for i=1,7 do p('GripWrap',0,-.3+i*.2,0,.32,.05,.32,steel) end
  p('HammerHead',0,1.95,0,2.25,1.2,1,steel,Enum.Material.Metal)
  for _,x in ipairs({-1,1}) do p('EngravedCap',x*1.14,1.95,0,.14,1.05,.9,dark,Enum.Material.Metal) end
  ring('WristLoop',0,-.65,0,.25,rgb(105,63,34))
 elseif k=='masterball' then
  ball('WhiteSphere',0,1.3,0,2,Color3.new(1,1,1))
  p('PurpleCrown',0,1.75,0,1.92,1.05,1.92,purple,nil,Enum.PartType.Ball)
  p('BlackBelt',0,1.28,0,2.04,.16,2.04,dark,nil,Enum.PartType.Ball)
  for _,x in ipairs({-.65,.65}) do ball('PinkSpot',x,1.98,-.43,.55,rgb(244,70,170)) end
  ball('ButtonRing',0,1.3,-.98,.52,dark); ball('Button',0,1.3,-1.13,.33,Color3.new(1,1,1))
  inscription(p('Monogram',0,1.82,-.86,.6,.45,.04,purple),'M',Color3.new(1,1,1))
 elseif k=='cards' then
  local names={'LEFT ARM','LEFT LEG','EXODIA','RIGHT LEG','RIGHT ARM'}
  for i=1,5 do
   local x=(i-3)*.7; local y=1.15+(i==3 and .35 or 0); local z=math.abs(i-3)*.14
   p('CardBorder',x,y,z,.78,1.25,.06,gold)
   p('CardArtwork',x,y+.13,z-.04,.65,.75,.03,rgb(114,68,30))
   inscription(p('CardTitle',x,y+.48,z-.07,.68,.15,.02,gold),names[i],dark)
   p('SealedLimb',x,y+.12,z-.08,i==3 and .35 or .17,.5,.03,gold)
   if i==3 then ball('ExodiaHead',x,y+.35,z-.1,.27,gold) end
   p('CardText',x,y-.38,z-.04,.65,.25,.03,rgb(240,214,158))
  end
 elseif k=='zenobutton' then
  p('WhiteController',0,1,0,1.3,1.9,.55,Color3.new(.95,.95,1))
  p('BlueSide',-.58,1,0,.2,1.8,.6,rgb(65,185,240)); p('PurpleSide',.58,1,0,.2,1.8,.6,purple)
  ball('RedButton',0,1.3,-.38,.65,rgb(245,45,73))
  inscription(p('ZenoLabel',0,.6,-.3,.9,.25,.03,dark),'ZENO',gold)
 elseif k=='portalgun' then
  p('WhiteShell',0,1,0,1.15,.85,2.1,Color3.new(.95,.95,1),Enum.Material.Metal)
  p('BlackCore',0,1,-1,.7,.65,1.2,dark)
  ball('PortalCore',0,1.15,-1.6,.6,cyan)
  for i=1,3 do local a=i*math.pi*2/3
   p('MechanicalClaw',math.cos(a)*.6,1+math.sin(a)*.6,-1.65,.16,.16,1.3,dark)
  end
  p('CarryHandle',0,1.65,.3,.3,.2,1,dark)
 elseif k=='raygun' then
  p('RedReceiver',0,1,0,.65,.7,1.5,rgb(198,45,44),Enum.Material.Metal)
  p('Grip',0,.3,.45,.35,.9,.4,dark,nil,nil,CFrame.Angles(-.25,0,0))
  p('Muzzle',0,1,-1.1,.4,.4,1.1,steel,Enum.Material.Metal)
  for i=1,4 do ball('GreenCoil',0,1,-.7-i*.2,.55,green) end
  p('Antenna',.4,1.5,0,.08,.6,.08,gold); ball('AntennaTip',.4,1.85,0,.2,green)
 elseif k=='bfg' then
  p('HeavyReceiver',0,1,0,1.8,1.1,2.8,rgb(63,90,55),Enum.Material.Metal)
  p('Muzzle',0,1,-1.8,1.3,.8,1,dark)
  ball('GreenPlasma',0,1,-2.35,.8,green)
  for _,x in ipairs({-.95,.95}) do p('EnergyRail',x,1,0,.18,.6,2.7,green,Enum.Material.Neon) end
  p('Handle',0,1.8,.2,.3,.3,1.2,dark); p('Grip',0,.2,.6,.4,.8,.5,dark)
 else error('No art for '..tostring(k)) end
 m:SetAttribute('Kind',d.id); m:SetAttribute('AnimatedCharacter',false)
 m.Parent=parent; return m
end
return F

