-- Shared market finishes. This module owns presentation only; interaction anchors
-- and every original collision surface stay with their existing builders.
local P=require(script.Parent.Primitives)
local M={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local rgb=Color3.fromRGB
local navy=rgb(29,39,57)
local slate=rgb(75,87,104)
local seam=rgb(48,60,78)
local bronze=rgb(179,141,78)
local pale=rgb(211,214,202)
local teal=rgb(79,148,157)
local metal,stone=Enum.Material.Metal,Enum.Material.Slate

local function builder(parent,name,budget)
 return P.new(parent,{name=name,alignBase=false,partBudget=budget})
end
local function box(b,name,size,cf,color,material)
 return b:box(name,size,cf,color,material or metal)
end
local function flat(b,name,size,cf,color,material)
 local part=box(b,name,size,cf,color,material or stone)
 part.CastShadow=false
 return part
end
local function finish(b)
 local model=b:finish()
 model:SetAttribute('Kind',nil)
 model:SetAttribute('DecorativeOnly',true)
 model:SetAttribute('ArtVersion',72)
 return model
end
local function label(part,value)
 local gui=Instance.new('SurfaceGui')
 gui.Name='InsetPowerLabTitle';gui.Face=Enum.NormalId.Front
 gui.CanvasSize=Vector2.new(900,140);gui.LightInfluence=.35
 gui.AlwaysOnTop=false;gui.MaxDistance=70;gui.Parent=part
 local text=Instance.new('TextLabel')
 text.Name='Title';text.BackgroundTransparency=1
 text.Size=UDim2.fromScale(.92,.84);text.Position=UDim2.fromScale(.04,.08)
 text.Font=Enum.Font.GothamBold;text.Text=value;text.TextSize=80
 text.TextColor3=pale;text.TextStrokeTransparency=1;text.Parent=gui
end

local function promenades(parent)
 local b=builder(parent,'MarketPromenades',100)
 for _,side in ipairs({-1,1}) do
  local z=side*21.5
  flat(b,'StonePromenade'..side,V(216,.10,19),C(0,.08,z),slate)
  for _,edge in ipairs({12.08,30.92}) do
   flat(b,'BronzePromenadeEdge'..side..edge,V(216,.045,.11),C(0,.158,side*edge),bronze,metal)
   flat(b,'InsetPromenadeReveal'..side..edge,V(216,.035,.22),C(0,.147,side*(edge==12.08 and 12.38 or 30.62)),seam)
  end
  for x=-90,90,18 do
   flat(b,'StoneExpansionJoint'..side..x,V(.07,.025,18.4),C(x,.144,z),seam)
  end
  -- These flush approach marks finish before the delivery/protection lines.
  for _,x in ipairs({-84,-28,28,84}) do
   flat(b,'VaultApproachInset'..side..x,V(8.8,.045,4.8),C(x,.153,side*30.3),navy)
   for _,offset in ipairs({-4.3,4.3}) do
    flat(b,'VaultApproachEdge'..side..x..offset,V(.10,.035,4.8),C(x+offset,.19,side*30.3),bronze,metal)
   end
   for _,offset in ipairs({-1,1}) do
    flat(b,'ApproachChevron'..side..x..offset,V(.105,.035,1.25),C(x+offset*.39,.195,side*30.25)*A(0,side*offset*.7,0),pale,metal)
   end
  end
 end
 return finish(b)
end

local function medallions(parent)
 local b=builder(parent,'RelicMedallions',150)
 -- Alternating placements keep a clear approach to the central workstation.
 local sites={{-76,-21.5},{-38,-21.5},{76,-21.5},{-76,21.5},{38,21.5},{76,21.5}}
 for index,site in ipairs(sites) do
  local origin=C(site[1],.19,site[2])
  b:cylinder('MedallionStone'..index,V(.065,5.7,5.7),origin*A(0,0,math.pi/2),navy,stone)
  b:ring('BronzeRelicDial'..index,origin*A(math.pi/2,0,0),2.55,.065,bronze,12,metal)
  local function mark(name,size,x,z,angle,color)
   return flat(b,'Relic'..index..name,size,origin*C(x,.065,z)*A(0,angle or 0,0),color or bronze,metal)
  end
  if index==1 then
   -- An open archive, a relic rather than a card billboard.
   mark('BookLeft',V(1.18,.05,1.75),-.64,0,-.08)
   mark('BookRight',V(1.18,.05,1.75),.64,0,.08)
   mark('Binding',V(.09,.07,1.9),0,0,0,pale)
   for _,x in ipairs({-.64,.64})do mark('PageRule'..x,V(.68,.08,.07),x,-.38,0,navy)end
  elseif index==2 then
   -- A geometric machine core echoes the new technological collectibles.
   mark('MachineCore',V(1.65,.06,1.65),0,0,math.pi/4)
   mark('CoreInset',V(.75,.09,.75),0,0,math.pi/4,teal)
   for _,x in ipairs({-1,1})do
    mark('CoreContact'..x,V(.5,.06,.12),x*1.36,0,0)
    mark('CoreContactZ'..x,V(.12,.06,.5),0,x*1.36,0)
   end
  elseif index==3 then
   mark('Blade',V(.30,.065,2.1),0,-.35,0,pale)
   mark('SwordGuard',V(1.5,.065,.18),0,.54)
   mark('SwordGrip',V(.24,.065,.75),0,1.0)
   mark('SwordPommel',V(.42,.065,.22),0,1.42)
  elseif index==4 then
   b:ring('OrbitalInset',origin*C(0,.065,0)*A(math.pi/2,0,0),1.15,.085,pale,8,metal)
   mark('OrbitAxis',V(.10,.065,3.25),0,0,.6)
   mark('OrbitCore',V(.65,.085,.65),0,0,math.pi/4,teal)
  elseif index==5 then
   for edge=0,2 do
    local angle=edge*math.pi*2/3
    local nextAngle=(edge+1)*math.pi*2/3
    b:line('RuneTriangle'..edge,origin*V(math.cos(angle)*1.4,.065,math.sin(angle)*1.4),
     origin*V(math.cos(nextAngle)*1.4,.065,math.sin(nextAngle)*1.4),.08,.08,bronze,metal)
   end
   mark('RuneHeart',V(.7,.07,.7),0,0,math.pi/4,pale)
  else
   mark('CrownBand',V(2.65,.065,.28),0,.85)
   for _,x in ipairs({-1,0,1})do
    mark('CrownPoint'..x,V(.50,.065,1.2+(.35-math.abs(x)*.35)),x*.87,.07,0,bronze)
   end
  end
 end
 local model=finish(b)
 for _,part in ipairs(model:GetDescendants())do if part:IsA('BasePart')then part.CastShadow=false end end
 return model
end

local function powerLab(parent)
 local b=builder(parent,'PowerLabSurround',65)
 flat(b,'PowerLabFoundation',V(14.8,.12,12.6),C(0,.18,20.4),navy)
 flat(b,'PowerLabInsetFloor',V(13.8,.045,11.6),C(0,.265,20.4),slate)
 for _,side in ipairs({-1,1})do
  flat(b,'PowerLabFloorRail'..side,V(.13,.045,12.2),C(side*7.12,.30,20.4),bronze,metal)
  flat(b,'PowerLabThreshold'..side,V(14.2,.045,.13),C(0,.30,20.4+side*6.1),bronze,metal)
  box(b,'LabRearPier'..side,V(.65,4.8,.65),C(side*5.4,2.65,25.35),navy,stone)
  box(b,'LabPierCap'..side,V(.9,.18,.9),C(side*5.4,5.1,25.35),bronze)
  box(b,'LabPierFoot'..side,V(.9,.30,.9),C(side*5.4,.43,25.35),slate,stone)
  box(b,'PierInset'..side,V(.08,3.55,.06),C(side*5.4,2.8,24.99),bronze)
  box(b,'LabLowReturn'..side,V(2.0,1.0,.45),C(side*4.0,.84,25.35),slate,stone)
 end
 box(b,'LabBacksplash',V(10.1,3.2,.28),C(0,2.9,25.35),navy,stone)
 box(b,'LabBacksplashInset',V(9.65,2.72,.055),C(0,2.9,25.17),seam)
 for _,y in ipairs({1.44,4.37})do box(b,'BacksplashRail'..y,V(10.2,.075,.08),C(0,y,25.12),bronze)end
 local sign=box(b,'PowerLabNameplate',V(7.4,1.15,.07),C(0,3.65,25.10),navy)
 label(sign,'POWER LAB')
 for index=-2,2 do
  box(b,'LabPanelDivision'..index,V(.055,1.15,.07),C(index*1.7,2.12,25.09),slate)
 end
 -- Two restrained indicators on the rear trim, without lights or particles.
 for _,side in ipairs({-1,1})do
  box(b,'LabStatusAccent'..side,V(.55,.08,.08),C(side*4.42,4.1,25.08),teal,Enum.Material.Neon)
 end
 return finish(b)
end

local function portalArrival(parent)
 local b=builder(parent,'PortalArrivalTrim',55)
 flat(b,'ArrivalStoneApron',V(13.0,.14,30),C(117.15,.12,0),slate)
 flat(b,'ArrivalInnerApron',V(11.9,.045,28.8),C(117.15,.215,0),navy)
 for _,side in ipairs({-1,1})do
  flat(b,'PortalApronLongEdge'..side,V(.12,.045,29.2),C(117.15+side*6.20,.255,0),bronze,metal)
  flat(b,'PortalApronEndEdge'..side,V(12.5,.045,.12),C(117.15,.255,side*14.6),bronze,metal)
  -- Existing pylon and crystal remain visible within a finished bronze socket.
  flat(b,'PylonFootReveal'..side,V(5.5,.075,4.95),C(119,.26,side*10),bronze,metal)
  flat(b,'PylonFootInset'..side,V(5.1,.065,4.55),C(119,.33,side*10),seam)
  for _,edge in ipairs({-1,1})do
   flat(b,'PylonStoneJoint'..side..edge,V(.08,.045,4.4),C(119+edge*2.35,.375,side*10),bronze,metal)
  end
 end
 -- A shallow approach motif terminates beside the original rift ring.
 for index=0,3 do
  for _,side in ipairs({-1,1})do
   flat(b,'ArrivalChevron'..index..side,V(.12,.045,1.8),C(111.35+index*1.35,.285,side*.58)*A(0,side*math.pi/4,0),pale,metal)
  end
 end
 return finish(b)
end

function M.build(world)
 assert(world and world.folder,'PlazaPolish requires the existing world')
 local previous=world.folder:FindFirstChild('PlazaPresentation')
 if previous then previous:Destroy()end
 local root=Instance.new('Folder');root.Name='PlazaPresentation';root.Parent=world.folder
 root:SetAttribute('ArtVersion',72)
 root:SetAttribute('DecorativeOnly',true)
 root:SetAttribute('Style','Relic market: slate, navy, bronze')
 promenades(root);medallions(root);powerLab(root);portalArrival(root)
 local count=0
 for _,part in ipairs(root:GetDescendants())do
  if part:IsA('BasePart')then
   count=count+1
   assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,'Market art must remain noninteractive')
  end
 end
 assert(count<=350,'Market presentation exceeds its geometry budget')
 root:SetAttribute('PartCount',count)
 return root
end
return M
