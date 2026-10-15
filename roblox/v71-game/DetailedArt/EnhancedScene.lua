-- Decorative upgrades use the existing interaction anchors and never own gameplay state.
local P=require(script.Parent.Primitives)
local E=require(script.Parent.ExtraDecor)
local Slifer=require(script.Parent.SliferArt)
local FreeModels=require(script.Parent.Parent.FreeModels.FreeModels)
local M={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local rgb=Color3.fromRGB
local gold,dark,steel,ivory=rgb(231,181,67),rgb(24,31,48),rgb(133,151,172),rgb(239,229,204)
local metal,wood,stone,neon=Enum.Material.Metal,Enum.Material.Wood,Enum.Material.Slate,Enum.Material.Neon
local function text(part,value,color,size)
 local gui=Instance.new('SurfaceGui');gui.Name='ReadableDisplay';gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(800,200);gui.LightInfluence=0;gui.AlwaysOnTop=false;gui.Parent=part
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.fromScale(.94,.88);t.Position=UDim2.fromScale(.03,.06);t.Text=value;t.TextColor3=color or ivory;t.TextSize=size or 35;t.TextWrapped=true;t.Font=Enum.Font.GothamBold;t.Parent=gui
 return gui
end
local function box(b,n,size,cf,c,mat) return b:box(n,size,cf,c,mat or metal) end
function M.workstation(parent,anchor,index)
 local b=P.new(parent,{name='DetailedWorkstation'..index,alignBase=false,cframe=anchor.CFrame,partBudget=160})
 -- Original anchor keeps its prompt, position and event connections.
 anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false
 local cyan=rgb(55,211,232)
 box(b,'ChamferedWorktop',V(4,.25,2.8),C(0,.15,0),steel)
 box(b,'InsetDesk',V(3.65,.1,2.45),C(0,.33,0),dark)
 for _,side in ipairs({-1,1}) do
  box(b,'AngledFrame'..side,V(.25,2.1,.3),C(side*1.6,-.8,.6)*A(0,0,side*.1),steel)
  box(b,'FootRail'..side,V(.65,.18,2.3),C(side*1.6,-1.85,0),dark)
  box(b,'ShelfBracket'..side,V(.17,.9,.17),C(side*1.6,-.8,-.65),gold)
 end
 box(b,'ToolShelf',V(3.3,.16,1.1),C(0,-1.15,.3),rgb(105,72,50),wood)
 for i=1,3 do
  box(b,'SupplyDrawer'..i,V(.85,.58,.8),C(-1.05+(i-1)*1.05,-.75,.35),rgb(42,55,72))
  box(b,'DrawerPull'..i,V(.4,.08,.07),C(-1.05+(i-1)*1.05,-.75,-.08),gold)
 end
 box(b,'DisplayStand',V(.4,.65,.35),C(0,.65,.65),steel)
 local frame=C(0,1.4,.65)*A(math.rad(-12),0,0)
 box(b,'ScreenBezel',V(2.7,1.5,.25),frame,dark)
 local screen=box(b,'ReadablePowerScreen',V(2.45,1.24,.04),frame*C(0,0,-.15),rgb(12,54,67),Enum.Material.SmoothPlastic)
 text(screen,'POWER LAB\n8 POWERS  |  3 SLOTS\nSELECT  •  EQUIP  •  READY',cyan,32)
 for _,side in ipairs({-1,1}) do box(b,'ScreenTrim'..side,V(.065,1.5,.06),frame*C(side*1.29,0,-.16),gold) end
 for row=0,2 do for col=0,6 do box(b,'KeyboardKey'..row..col,V(.2,.05,.14),C(-.72+col*.24,.43,-.55+row*.18),row==0 and cyan or steel) end end
 for i=1,3 do b:cylinder('ControlButton'..i,V(.08,.24,.24),C(1.25,.47,-.75+i*.38)*A(0,0,math.pi/2),({cyan,gold,rgb(235,86,109)})[i],neon) end
 b:line('ToolHandle',V(-1.5,.43,-.9),V(-1.1,.43,-.35),.12,.12,rgb(148,87,47),wood)
 box(b,'WrenchHead',V(.32,.08,.24),C(-1.05,.43,-.28)*A(0,.3,0),steel)
 b:line('SolderTool',V(1.25,.43,.4),V(1.6,.43,.9),.09,.09,gold)
 b:ring('CableCoil',C(1.4,.45,.1)*A(math.pi/2,0,0),.2,.035,dark,12,metal)
 for _,x in ipairs({-1.75,1.75}) do for _,z in ipairs({-1.1,1.1}) do b:ball('Rivet'..x..z,.09,C(x,.35,z),gold) end end
 return b:finish()
end
local function circleAndChains(parent)
 -- Statue faces toward the arena; circle stays behind its head and raised arms.
 local origin=C(-40,20,-108)*A(0,math.pi,0)
 local b=P.new(parent,{name='ExodiaSpellbindingCircle',alignBase=false,cframe=origin,partBudget=700})
 local violet=rgb(193,85,248);local center=C(0,36,7)
 for _,radius in ipairs({17,18.5,22}) do b:ring('SpellbindingRing'..radius,center,radius,.22,violet,64,neon) end
 for i=0,11 do
  local angle=i*math.pi/6
  b:line('CircleSpoke'..i,center*V(math.cos(angle)*18.5,math.sin(angle)*18.5,0),center*V(math.cos(angle)*22,math.sin(angle)*22,0),.15,.15,gold,neon)
  local cf=center*C(math.cos(angle)*20,math.sin(angle)*20,0)*A(0,0,angle)
  b:line('RuneStem'..i,cf*V(0,-.65,0),cf*V(0,.65,0),.16,.12,violet,neon)
  b:line('RuneCrown'..i,cf*V(-.4,.5,0),cf*V(.4,.5,0),.16,.12,violet,neon)
 end
 for i=0,5 do local a=i*math.pi/3;local c=(i+2)*math.pi/3
  b:line('SealingStar'..i,center*V(math.cos(a)*16.5,math.sin(a)*16.5,0),center*V(math.cos(c)*16.5,math.sin(c)*16.5,0),.14,.14,violet,neon)
 end
 local paths={{V(-20,39,7),V(-12,35,0)},{V(20,39,7),V(12,35,0)},{V(-17,25,7),V(-5,29,-1)},{V(17,25,7),V(5,29,-1)}}
 for chain,path in ipairs(paths) do
  for i=0,12 do local t=i/12;local p=path[1]:Lerp(path[2],t)+V(0,-math.sin(t*math.pi)*2,0)
   local rot=i%2==0 and A(0,0,0) or A(0,math.pi/2,0)
   -- Alternating open rectangular links read clearly at arena distance.
   local cf=C(p)*rot
   for _,x in ipairs({-.37,.37}) do box(b,'ChainSide'..chain..i..x,V(.16,1.1,.16),cf*C(x,0,0),gold) end
   for _,y in ipairs({-.55,.55}) do box(b,'ChainEnd'..chain..i..y,V(.74,.16,.16),cf*C(0,y,0),gold) end
  end
 end
 return b:finish()
end
local function framedMirror(parent)
 local frame=C(16,85,-150)*A(0,math.pi,0)
 local b=P.new(parent,{name='MirrorForceTrapCard',alignBase=false,cframe=frame,partBudget=80})
 local pink=rgb(166,65,132);local pale=rgb(226,192,216)
 box(b,'CardBack',V(40,58,1),C(),dark)
 box(b,'TrapCardFrame',V(38,56,.3),C(0,0,-.65),pink)
 for _,x in ipairs({-18.3,18.3}) do box(b,'SilverBorder'..x,V(.25,54,.25),C(x,0,-.9),pale) end
 local title=box(b,'MirrorForceTitle',V(34,5,.2),C(0,23,-.95),pale);text(title,'MIRROR FORCE',dark,64)
 local typeLine=box(b,'TrapTypeLine',V(34,2.4,.2),C(0,18.8,-.95),pink);text(typeLine,'[ TRAP CARD ]   ↻',ivory,35)
 box(b,'ArtworkWindow',V(34,29,.25),C(0,1.7,-1),rgb(18,45,79))
 local rules=box(b,'CardRulesArea',V(34,12,.2),C(0,-20,-.95),ivory)
 local gui=text(rules,'When an opponent declares an attack:\nreflect the assault in a brilliant wall of light.\n\nMIRROR FORCE   •   ARENA GALLERY',dark,31);gui.CanvasSize=Vector2.new(900,320)
 local model=b:finish()
 -- Existing detailed mirror energy sculpture is contained inside its art window.
 local art=E.mirrorForcePlanet(model,C());art:ScaleTo(.49);art:PivotTo(frame*C(0,2,-1.7))
 return model
end
local function framedPainting(parent,name,title,center,width,height)
 local painting=P.new(parent,{name=name,alignBase=false,cframe=center,partBudget=40})
 for _,x in ipairs({-width/2,width/2}) do
  box(painting,'CarvedWoodFrame'..x,V(1.5,height,.8),C(x,0,-.3),rgb(91,53,32),wood)
  box(painting,'GoldFrameInset'..x,V(.16,height-2,.1),C(x*.97,0,-.77),gold)
 end
 for _,y in ipairs({-height/2,height/2}) do
  box(painting,'PaintingFrameRail'..y,V(width,1.5,.8),C(0,y,-.3),rgb(91,53,32),wood)
  box(painting,'FrameRailTrim'..y,V(width-2,.14,.1),C(0,y*.96,-.77),gold)
 end
 local board=box(painting,'PaintingCanvas',V(width-2,height-2,.3),C(),ivory,Enum.Material.Fabric)
 board.Name='ArtworkCanvas'
 painting:finish()
 painting.model:SetAttribute('PaintingTitle',title)
 return painting.model
end
local function garden(parent)
 local b=P.new(parent,{name='BellTowerGarden',alignBase=false,cframe=C(44,0,113),partBudget=180})
 box(b,'GardenFoundation',V(48,1,43),C(0,.15,0),rgb(65,75,64),stone)
 for _,side in ipairs({-1,1}) do
  box(b,'GravelBed'..side,V(7,.2,30),C(side*20,.8,0),rgb(154,157,143),Enum.Material.Pebble)
  for i=0,5 do b:ball('GardenRock'..side..i,V(2+i%2,1.5,2),C(side*(18+i%2*3),1.3,-12+i*5),rgb(83,95,88),stone) end
  for i=0,3 do
   local cf=C(side*20,1.3,-10+i*7)
   for j=0,4 do local a=j*math.pi*2/5;b:ball('GardenLeaf'..side..i..j,V(.4,1.8,.5),cf*A(0,a,.5),rgb(55,119,65),Enum.Material.Grass) end
  end
 end
 for i=0,5 do box(b,'ApproachStone'..i,V(7,.24,2.2),C(0,.8,-19+i*2),ivory,stone) end
 b:finish()
end
local function hooh(parent)
 local b=P.new(parent,{name='HoOhFlight',alignBase=false,partBudget=240})
 local red,green,white=rgb(214,48,37),rgb(54,158,87),rgb(248,243,222)
 b:ball('RedBreast',V(3.3,4.6,3.2),C(0,0,0),red,Enum.Material.SmoothPlastic)
 b:ball('WhiteBelly',V(2.7,2.9,1.5),C(0,-.5,-1.4),white,Enum.Material.SmoothPlastic)
 b:ball('GoldenNeck',V(2.3,2.4,2.2),C(0,2,-.4),gold,metal)
 b:ball('RedHead',V(2.2,2.2,2.2),C(0,3.3,-.65),red,Enum.Material.SmoothPlastic)
 b:wedge('HookedGoldenBeak',V(1.2,1.1,2),C(0,3.05,-2),gold,metal)
 for _,side in ipairs({-1,1}) do
  b:ball('EyeWhite'..side,V(.15,.55,.65),C(side*1.05,3.5,-1.2),white)
  b:ball('EyePupil'..side,V(.17,.3,.35),C(side*1.12,3.5,-1.3),dark)
  b:line('BlackEyeMask'..side,V(side*.6,3.7,-1.5),V(side*1.14,3.65,-.5),.12,.14,dark)
  for i=0,3 do b:ball('GoldenCrest'..side..i,V(.4,1.8+i*.12,.3),C(side*(.3+i*.25),4.3+i*.2,.1+i*.18)*A(0,0,-side*.3),gold,metal) end
  b:line('Leg'..side,V(side*.8,-1.5,0),V(side*1.05,-2.8,-.4),.4,.4,gold)
  for toe=-1,1 do b:line('Talon'..side..toe,V(side*1.05,-2.8,-.4),V(side*1.05+toe*.3,-2.9,-1.15),.14,.14,gold) end
  b:ball('WingShoulder'..side,V(3,1.2,2),C(side*2,.7,.1),red)
  for i=1,10 do
   local x=side*(2+i*.57);local y=.7+math.sin(i/10*math.pi)*1.4
   b:ball('WingRed_'..side..'_'..i,V(1,3.6-i*.08,.3),C(x,y-.7,.1+i*.15)*A(0,0,-side*.65),red)
   b:ball('WingGold_'..side..'_'..i,V(.92,1.45,.32),C(x+side*.7,y-1.8,.1+i*.15)*A(0,0,-side*.65),gold,metal)
   b:ball('WingGreen_'..side..'_'..i,V(.85,1.05,.34),C(x+side*1.05,y-2.3,.1+i*.15)*A(0,0,-side*.65),green)
   b:ball('WingWhiteTip_'..side..'_'..i,V(.8,.65,.35),C(x+side*1.25,y-2.65,.1+i*.15)*A(0,0,-side*.65),white)
  end
 end
 for i=-3,3 do
  local cf=C(i*.65,-2.4,3.3+math.abs(i)*.18)*A(math.rad(48),0,-i*.1)
  b:ball('LongGoldTail'..i,V(.8,7-math.abs(i)*.35,.3),cf,gold,metal)
  b:ball('GreenTailBand'..i,V(.82,1.3,.34),cf*C(0,-2,0),green)
  b:ball('RedTailTip'..i,V(.8,.8,.36),cf*C(0,-2.8,0),red)
 end
 local bird=b:finish()
 bird:SetAttribute('FlightOrigin',V(44,66,113));bird:SetAttribute('FlightPeriod',28)
 bird:PivotTo(C(44,66,113));return bird
end
local function kaibaTower(parent)
 local b=P.new(parent,{name='KaibaCorpTower',alignBase=false,cframe=C(0,0,-144),partBudget=220})
 local blue=rgb(34,111,206);local pale=rgb(210,226,239)
 box(b,'TowerFoundation',V(26,2,24),C(0,1,0),dark,stone)
 box(b,'GrandEntry',V(13,12,5),C(0,7,-10),blue,metal)
 for floor=0,8 do
  local y=13+floor*8;local taper=1-floor*.035
  box(b,'GlassTowerLevel'..floor,V(19*taper,7.5,18*taper),C(0,y,0),floor%2==0 and blue or pale,Enum.Material.Glass)
  for _,side in ipairs({-1,1}) do
   box(b,'GoldPillar'..floor..'_'..side,V(.45,7.6,.55),C(side*8.7*taper,y,8.4*taper),gold,metal)
   box(b,'BlueCorner'..floor..'_'..side,V(.6,7.4,.6),C(side*8.8*taper,y,-8.4*taper),blue,metal)
  end
  box(b,'FloorBand'..floor,V(20*taper,.42,19*taper),C(0,y-3.8,0),gold,metal)
 end
 box(b,'CrownRoof',V(15,2.2,15),C(0,82,0),blue,metal)
 for i=0,3 do local a=i*math.pi/2;local pos=V(math.cos(a)*6,86,math.sin(a)*6);b:wedge('AerialFin'..i,V(2,7,2),C(pos)*A(0,a,0),gold,metal) end
 box(b,'KaibaCorpSign',V(12,3,.4),C(0,18,-9.5),dark,metal)
 local sign=b.model:FindFirstChild('KaibaCorpSign');local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(900,220);gui.LightInfluence=0;gui.Parent=sign
 local label=Instance.new('TextLabel');label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.Text='KAIBA CORP';label.TextColor3=rgb(89,190,255);label.TextScaled=true;label.Font=Enum.Font.GothamBlack;label.Parent=gui
 return b:finish()
end
local function wingedDragonOfRa(parent)
 -- The earlier art pass removed the legacy god statues. Restore one complete,
 -- detailed Ra monument on the east skyline, clear of Slifer and the gallery.
 local statue=FreeModels.create(parent,{
  model='winged_dragon_ra',name='WingedDragonOfRaStatue',
  scale=1.3,cframe=C(75,34,155),
 })
 statue:SetAttribute('Kind',nil)
 statue:SetAttribute('DecorativeOnly',true)
 statue:SetAttribute('CharacterName','The Winged Dragon of Ra')
 statue:SetAttribute('Franchise','Yu-Gi-Oh!')
 statue:SetAttribute('ArtVersion',71)
 local b=P.new(parent,{name='WingedDragonOfRaPedestal',alignBase=false,cframe=C(75,0,155),partBudget=80})
 b:cylinder('ObsidianPlinth',V(3.8,10.6,10.6),C(0,31.6,0)*A(0,0,math.pi/2),dark,stone)
 b:cylinder('GoldenPlinthFoot',V(.4,11.4,11.4),C(0,29.9,0)*A(0,0,math.pi/2),gold,metal)
 b:cylinder('GoldenPlinthCrown',V(.4,11.4,11.4),C(0,33.8,0)*A(0,0,math.pi/2),gold,metal)
 for i=0,7 do
  local angle=i*math.pi/4
  box(b,'GoldPedestalFlute'..i,V(.16,2.9,.16),C(math.cos(angle)*5.22,31.6,math.sin(angle)*5.22),gold)
 end
 local plaque=box(b,'RaMonumentNameplate',V(7.7,1.5,.12),C(0,31.8,-5.35),gold)
 text(plaque,'THE WINGED DRAGON OF RA',dark,36)
 local pedestal=b:finish();pedestal:SetAttribute('Kind',nil);pedestal:SetAttribute('DecorativeOnly',true)
 return statue
end
function M.build(world)
 local old=world.folder:FindFirstChild('EnhancedScene');if old then old:Destroy() end
 -- Remove only legacy Slifer scenery; Ra and the other landmarks are retained.
 for _,v in ipairs(world.folder:GetDescendants()) do
  if v:IsA('Model') and (v.Name=='godSlifer' or v.Name=='SliferStatue' or v.Name=='SliferTablet' or v.Name=='SliferAroundKaibaTower' or v.Name=='SliferAnimatedLandmark') then v:Destroy() end
 end
 local root=Instance.new('Folder');root.Name='EnhancedScene';root.Parent=world.folder
 for i,base in ipairs(world.bases) do M.workstation(root,base.upgrade,i) end
 M.workstation(root,world.powerShop,'Central')
 for _,v in ipairs(world.folder:GetDescendants()) do
  if v.Name=='SoftCloud' or v.Name=='WhiteBall' or v.Name=='CloudBlob' or v.Name:match('^DomainStar_') then v:Destroy() end
 end
 local oldMirror=world.folder:FindFirstChild('MirrorForceReflectionPlanet',true);if oldMirror then oldMirror:Destroy() end
 circleAndChains(root);framedMirror(root);garden(root);hooh(root);kaibaTower(root);Slifer.create(root);wingedDragonOfRa(root)
 framedPainting(root,'ForceOfDespairPainting','Force of Despair',C(-94,76,-100)*A(0,math.pi,0),41,29)
 framedPainting(root,'ExodiaPainting','Exodia',C(74,69,152),46,31)
 framedPainting(root,'EgyptianGodsPainting','Egyptian Gods',C(-37,65,152),86,48)
 return root
end
return M
