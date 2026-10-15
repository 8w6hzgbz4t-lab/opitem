-- Complete local geometry. No uploaded meshes, external scripts, or asset dependencies.
local P=require(script.Parent.Primitives)
local N={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local rgb=Color3.fromRGB
local gold,ivory,dark,blue=rgb(239,185,48),rgb(246,240,222),rgb(30,35,48),rgb(34,91,211)
local metal,plastic,neon=Enum.Material.Metal,Enum.Material.SmoothPlastic,Enum.Material.Neon
local stones={spaceStone=rgb(45,125,255),mindStone=rgb(255,221,62),realityStone=rgb(230,39,59),powerStone=rgb(163,65,241),timeStone=rgb(54,230,117),soulStone=rgb(255,135,36)}
local function box(b,n,x,y,z,sx,sy,sz,c,mat,rot) return b:box(n,V(sx,sy,sz),C(x,y,z)*(rot or C()),c,mat or metal) end
local function face(b,n,x,y,z,sx,sy,c) return b:ball(n,V(sx,sy,.12),C(x,y,z),c,plastic) end
local function star(b,n,cf,r,color,depth)
 local points={};for i=0,9 do local a=math.pi/2+i*math.pi/5;local q=i%2==0 and r or r*.43;points[i+1]=cf*V(math.cos(a)*q,math.sin(a)*q,0) end
 for i=1,10 do b:triangle(n..i,cf.Position,points[i],points[i%10+1],color,depth or .15,metal) end
end
local function gem(b,key)
 local col=stones[key];local ring={};local count=8
 for i=0,count-1 do local a=i*math.pi*2/count;ring[i+1]=V(math.cos(a)*1.02,1.2,math.sin(a)*.76) end
 for i=1,count do
  local j=i%count+1;local h,s,v=col:ToHSV();local c=Color3.fromHSV(h,s,.64+(i%3)*.12)
  b:triangle('CrownFacet'..i,V(.12,2.5,0),ring[i],ring[j],c,.025,Enum.Material.Glass)
  b:triangle('PavilionFacet'..i,V(-.08,0,0),ring[j],ring[i],c:Lerp(ivory,.09),.025,metal)
  b:line('FacetEdge'..i,ring[i],ring[j],.025,.025,col:Lerp(ivory,.5),metal)
 end
 local heart=b:ball('RestrainedGlow',V(.8,1.1,.65),C(0,1.25,0),col,neon);heart.Transparency=.28
 local light=Instance.new('PointLight');light.Color=col;light.Range=4;light.Brightness=.35;light.Shadows=false;light.Parent=heart
 b:line('PrismaticInclusion',V(-.3,.55,-.15),V(.3,1.85,.13),.045,.045,ivory,metal)
end
local function shell(b)
 -- Layered blue dome, thick white rim, radial ivory spikes, paired feathered wings.
 b:ball('BlueDome',V(3.1,2.1,2.75),C(0,1.28,0),blue,plastic)
 b:ball('PaleUnderside',V(2.75,.65,2.5),C(0,.52,0),rgb(236,216,158),plastic)
 b:ring('WhiteShellRim',C(0,.75,0)*A(math.pi/2,0,0),1.48,.22,ivory,28,plastic)
 for i=0,5 do local a=i*math.pi/3
  b:line('HexagonalSeam'..i,V(0,2.32,0),V(math.cos(a)*1.35,1.1,math.sin(a)*1.2),.065,.065,rgb(16,55,145),plastic)
  local pos=V(math.cos(a)*1.18,1.52,math.sin(a)*1.05);local tip=pos+V(math.cos(a)*.48,.65,math.sin(a)*.48)
  for j=0,3 do local q=j*math.pi/2;local q2=(j+1)*math.pi/2
   b:triangle('WhiteSpike'..i..'_'..j,tip,pos+V(math.cos(q)*.27,-.05,math.sin(q)*.27),pos+V(math.cos(q2)*.27,-.05,math.sin(q2)*.27),ivory,.035,plastic)
  end
 end
 for _,side in ipairs({-1,1}) do
  b:ball('WingShoulder'..side,V(.65,1,.65),C(side*1.5,1.5,.35),ivory,plastic)
  for f=1,6 do
   local start=V(side*(1.35+f*.12),1.45+f*.12,.3)
   local finish=V(side*(2.1+f*.15),2.1+(7-f)*.18,.4+(f-1)*.14)
   b:ball('WingFeather'..side..'_'..f,V(.28,(finish-start).Magnitude+.35,.25),C((start+finish)*.5)*A(0,0,-side*.9),ivory:Lerp(rgb(170,191,220),f*.025),plastic)
   b:line('FeatherQuill'..side..'_'..f,start,finish,.045,.045,rgb(202,215,229),plastic)
  end
 end
end
local function kirby(b)
 box(b,'PurpleHandle',0,.5,0,.32,1,.32,rgb(118,50,162),plastic)
 for y=.1,.9,.16 do box(b,'GripBand'..y,0,y,0,.36,.055,.36,gold) end
 box(b,'GoldCrossguard',0,1.1,0,1.6,.22,.48,gold)
 star(b,'StarGuard',C(0,1.15,-.28),.48,gold,.18)
 box(b,'SilverBlade',0,2.35,0,.58,2.25,.15,ivory)
 b:triangle('BladeTip',V(-.29,3.48,0),V(.29,3.48,0),V(0,4,0),ivory,.15,metal)
 b:line('BladeFuller',V(0,1.4,-.1),V(0,3.5,-.1),.045,.03,rgb(140,204,238),metal)
 b:ball('Pommel',.43,C(0,-.02,0),gold,metal)
end
local function spatula(b)
 box(b,'WoodenGrip',0,.45,0,.36,1.1,.3,rgb(137,72,27),Enum.Material.Wood)
 box(b,'GoldShaft',0,1.6,0,.15,1.4,.12,gold)
 b:ball('GripRivet',.1,C(0,.6,-.17),gold)
 box(b,'SpatulaNeck',0,2.35,0,.45,.35,.14,gold)
 for _,x in ipairs({-.65,.65}) do box(b,'OuterFrame'..x,x,2.95,0,.18,1.4,.16,gold) end
 for _,y in ipairs({2.28,3.62}) do box(b,'EndFrame'..y,0,y,0,1.45,.18,.16,gold) end
 for x=-.36,.37,.24 do box(b,'SlottedBlade'..x,x,2.95,0,.12,1.25,.16,gold) end
 b:ring('HandleHangingHole',C(0,-.15,0),.18,.05,gold,12,metal)
end
local function patty(b)
 local tan=rgb(220,151,65)
 b:ball('LowerBun',V(2.9,.55,2.7),C(0,.3,0),tan,plastic)
 b:ball('GrilledPatty',V(2.9,.45,2.7),C(0,.7,0),rgb(92,44,25),Enum.Material.Slate)
 for i=0,7 do local a=i*math.pi/4;b:ball('LettuceRuffle'..i,V(.9,.22,.8),C(math.cos(a)*1.1,.99,math.sin(a)*1.03),rgb(82,168,42),plastic) end
 box(b,'CheeseSlice',0,.9,0,2.6,.09,2.6,rgb(255,198,33),plastic,A(0,.23,0))
 b:ball('Tomato',V(2.55,.2,2.4),C(0,1.14,0),rgb(208,46,31),plastic)
 b:ball('Onion',V(2.4,.15,2.3),C(0,1.29,0),ivory,plastic)
 b:ball('UpperBun',V(3,1.05,2.85),C(0,1.62,0),tan:Lerp(ivory,.15),plastic)
 for i=1,20 do local a=i*2.399;local r=.2+(i%5)*.2;b:ball('SesameSeed'..i,V(.16,.055,.08),C(math.cos(a)*r,2.12-r*r*.16,math.sin(a)*r)*A(0,a,0),ivory,plastic) end
end
local function gary(b)
 b:ball('PinkShell',V(2.8,2.6,1.7),C(0,1.35,0),rgb(231,135,172),plastic)
 local prev
 for i=0,50 do local t=i/50*math.pi*4.2;local r=1.05*(1-i/58);local p=V(math.cos(t)*r,1.35+math.sin(t)*r,-.88)
  if prev then b:line('RedSpiral'..i,prev,p,.105,.06,rgb(161,37,72),plastic) end;prev=p
 end
 for i=0,7 do local a=i*math.pi/4;face(b,'BlueShellSpot'..i,math.cos(a)*1.1,1.35+math.sin(a)*1.05,-.9,.22,.25,rgb(67,119,195)) end
 b:ball('ShellOpening',V(.8,.7,.2),C(.9,.45,-.65),rgb(128,57,93),plastic)
 b:ring('OpeningLip',C(.9,.45,-.78),.4,.09,rgb(255,189,197),18,plastic)
end
local function superstar(b)
 star(b,'GoldStar',C(0,1.6,0),1.6,rgb(255,215,58),.4)
 star(b,'RaisedStarFace',C(0,1.6,-.23),1.38,rgb(255,230,89),.08)
 for _,side in ipairs({-1,1}) do face(b,'BlackEye'..side,side*.34,1.8,-.33,.17,.55,dark);face(b,'EyeGlint'..side,side*.34,1.94,-.4,.065,.12,ivory) end
end
local function flower(b)
 b:line('GreenStem',V(0,0,0),V(0,1.5,0),.26,.25,rgb(32,159,59),plastic)
 for _,side in ipairs({-1,1}) do b:ball('Leaf'..side,V(.95,.45,.22),C(side*.42,.55,0)*A(0,0,side*.45),rgb(49,189,65),plastic) end
 b:ball('OrangePetalRing',V(2.4,2.1,.6),C(0,2.2,0),rgb(251,114,29),plastic)
 for i=0,9 do local a=i*math.pi/5
  b:ball('LayeredPetal'..i,V(.65,.65,.28),C(math.cos(a)*.91,2.2+math.sin(a)*.77,-.3),i%2==0 and rgb(255,119,32) or rgb(241,88,24),plastic)
 end
 b:ball('YellowFlowerFace',V(1.8,1.5,.4),C(0,2.2,-.35),rgb(255,220,55),plastic)
 b:ball('WhiteFace',V(1.25,1.05,.25),C(0,2.22,-.58),ivory,plastic)
 for _,s in ipairs({-1,1}) do
  face(b,'Eye'..s,s*.22,2.25,-.73,.13,.4,dark)
  face(b,'EyeGlint'..s,s*.22,2.36,-.8,.045,.09,ivory)
  b:line('LeafVein'..s,V(s*.16,.47,-.13),V(s*.78,.64,-.13),.035,.035,rgb(24,117,46),plastic)
 end
end
local function shield(b)
 local pts={V(-1.25,3.6,0),V(1.25,3.6,0),V(1.45,1.7,0),V(0,0,0),V(-1.45,1.7,0)}
 for i=1,5 do b:triangle('SteelShield'..i,V(0,2,0),pts[i],pts[i%5+1],rgb(177,193,209),.3,metal);b:line('SilverRim'..i,pts[i]+V(0,0,-.18),pts[i%5+1]+V(0,0,-.18),.13,.1,ivory) end
 for i=1,5 do b:triangle('BlueEnamel'..i,V(0,2,-.2),V(pts[i].X*.85,pts[i].Y*.85+.25,-.2),V(pts[i%5+1].X*.85,pts[i%5+1].Y*.85+.25,-.2),blue,.05,metal) end
 b:triangle('TriforceTop',V(0,3.4,-.3),V(-.3,2.88,-.3),V(.3,2.88,-.3),gold,.045,metal)
 for _,s in ipairs({-1,1}) do b:triangle('TriforceBase'..s,V(s*.3,2.88,-.3),V(s*.3-.3,2.36,-.3),V(s*.3+.3,2.36,-.3),gold,.045,metal)
  b:triangle('RedWing'..s,V(0,1.75,-.32),V(s*1.02,2.3,-.32),V(s*.55,1,-.32),rgb(191,37,45),.06,metal)
  for j=1,3 do b:line('WingCrest'..s..j,V(s*.4,1.7-j*.12,-.34),V(s*(.65+j*.12),1.5-j*.2,-.34),.08,.045,rgb(215,44,52)) end
 end
 box(b,'LeatherBackStrap',0,1.8,.3,.8,.22,.2,rgb(107,59,35),Enum.Material.Fabric)
end
local function cube(b)
 local grey=rgb(149,155,168);box(b,'WeightedCubeCore',0,1.5,0,2.8,2.8,2.8,grey)
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do box(b,'CornerArmor'..x..y..z,x*1.23,1.5+y*1.23,z*1.23,.55,.55,.55,rgb(205,209,217)) end end end
 for side=0,3 do local cf=C(0,1.5,0)*A(0,side*math.pi/2,0)*C(0,0,-1.44)
  b:ring('PinkFaceRing'..side,cf,.83,.09,rgb(229,128,176),20,plastic)
  for _,s in ipairs({-1,1}) do b:ball('HeartLobe'..side..s,V(.55,.55,.08),cf*C(s*.22,.12,-.05),rgb(235,139,185),plastic) end
  b:triangle('HeartPoint'..side,cf*V(-.47,.06,-.1),cf*V(.47,.06,-.1),cf*V(0,-.52,-.1),rgb(235,139,185),.04,plastic)
 end
 b:ring('TopPanel',C(0,2.95,0)*A(math.pi/2,0,0),.8,.08,rgb(229,128,176),20,plastic)
end
local function proton(b)
 box(b,'PackBackplate',0,1.9,0,2.2,3.6,.55,dark)
 box(b,'UpperPowerCell',0,2.65,-.48,1.75,1.5,.8,rgb(50,57,64))
 b:cylinder('Cyclotron',V(.65,1.8,1.8),C(0,1,-.65)*A(0,math.pi/2,0),dark,metal)
 b:ring('CyclotronOuterRing',C(0,1,-1),.9,.1,rgb(112,116,125),24,metal)
 for i=0,3 do local a=i*math.pi/2;b:ball('RedCyclotronLight'..i,V(.24,.24,.08),C(math.cos(a)*.58,1+math.sin(a)*.58,-1.05),rgb(255,58,37),neon) end
 for i=1,7 do box(b,'BluePowerMeter'..i,-.42,2.1+i*.13,-.92,.32,.07,.07,rgb(76,159,255),neon) end
 for _,s in ipairs({-1,1}) do box(b,'ShoulderStrap'..s,s*.7,1.9,.4,.2,3.1,.18,rgb(121,100,71),Enum.Material.Fabric) end
 for i=0,15 do local a=i/15*math.pi;b:line('CorrugatedHose'..i,V(1.08+math.sin(a)*.55,2.7-i*.13,-.5),V(1.08+math.sin(a+.2)*.55,2.7-(i+1)*.13,-.5),.14,.14,rgb(89,78,64)) end
 box(b,'NeutronaWand',1.42,1.7,-.3,.38,2.2,.45,dark)
 box(b,'WandGrip',1.42,.7,-.3,.47,.65,.5,rgb(63,66,72))
 for y=2.3,2.8,.1 do box(b,'BarrelCoolingFin'..y,1.42,y,-.3,.5,.045,.52,rgb(152,157,167)) end
 box(b,'WarningStripe',0,3.1,-.91,.65,.14,.03,gold)
end
local function blackLotus(b)
 -- A compact, recognizable black-violet lotus collectible with gold heart and stem.
 b:line('LotusStem',V(0,0,0),V(0,1.25,0),.22,.22,rgb(45,119,57),plastic)
 for side=-1,1,2 do
  b:triangle('LotusLeaf'..side,V(0,.55,.05),V(side*1.18,.65,.08),V(side*.72,1.12,.02),rgb(43,119,68),.08,plastic)
 end
 local center=V(0,1.48,-.08)
 for i=0,9 do
  local a=i*math.pi/5;local tip=center+V(math.cos(a)*1.36,math.sin(a)*.96,0)
  local shoulder=center+V(math.cos(a+.28)*.6,math.sin(a+.28)*.5,-.12)
  local other=center+V(math.cos(a-.28)*.6,math.sin(a-.28)*.5,-.12)
  b:triangle('ObsidianPetal'..i,center,shoulder,tip,i%2==0 and rgb(28,22,45) or rgb(49,33,72),.11,metal)
  b:triangle('VioletPetal'..i,center,tip,other,i%2==0 and rgb(67,43,99) or rgb(36,27,55),.11,metal)
  b:line('PetalRidge'..i,center,tip,.035,.03,rgb(136,93,174),metal)
 end
 b:ball('GildedHeart',V(.42,.42,.25),C(0,1.55,-.18),gold,metal)
 for i=0,6 do local a=i*math.pi*2/7;b:ball('GoldenStamen'..i,V(.11,.24,.11),C(math.cos(a)*.22,1.83+math.sin(a)*.14,-.36),rgb(255,214,91),metal) end
 b.model:SetAttribute('DisplayTitle','Black Lotus')
end
local function deathNote(b)
 local black=rgb(18,20,27);local red=rgb(178,35,43);local page=rgb(232,226,205)
 -- A recognizable upright leather notebook, with page block, binding, corner caps and title.
 box(b,'CreamPageBlock',0,2.35,0,3.55,4.9,.42,page,Enum.Material.Fabric)
 box(b,'BlackLeatherCover',0,2.35,-.27,3.9,5.25,.18,black,Enum.Material.Leather)
 box(b,'RedSpine',-1.78,2.35,-.39,.23,5.22,.13,red,metal)
 for _,x in ipairs({-1.82,1.82}) do
  for _,y in ipairs({-.1,4.8}) do
   box(b,'GiltCorner'..x..y,x,y,-.4,.32,.32,.1,gold,metal)
  end
 end
 box(b,'TitlePlaque',0,3.25,-.405,2.95,1.2,.055,black,metal)
 local plaque=b.model:FindFirstChild('TitlePlaque')
 local gui=Instance.new('SurfaceGui');gui.Name='DeathNoteTitle';gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(600,240);gui.LightInfluence=0;gui.Parent=plaque
 local title=Instance.new('TextLabel');title.Name='Title';title.BackgroundTransparency=1;title.Size=UDim2.fromScale(1,1);title.Text='DEATH NOTE';title.TextColor3=rgb(228,220,194);title.TextScaled=true;title.Font=Enum.Font.GothamBold;title.Parent=gui
 for i=1,9 do box(b,'PageRule'..i,0,.25+i*.39,.225,3.22,.025,.025,rgb(184,178,160),Enum.Material.Fabric) end
 box(b,'BookmarkRibbon',1.25,-.28,-.43,.12,.95,.07,red,plastic)
end
local builders={shell=shell,kirbySword=kirby,goldenSpatula=spatula,krabbyPatty=patty,garyShell=gary,superStar=superstar,fireFlower=flower,hylianShield=shield,companionCube=cube,protonPack=proton,blackLotusCollectible=blackLotus,deathNote=deathNote}
function N.supports(key) return builders[key]~=nil or stones[key]~=nil end
function N.create(d,parent)
 local b=P.new(parent,{name=d.name,itemId=d.id,model=d.model,partBudget=240})
 if stones[d.model] then gem(b,d.model) else assert(builders[d.model])(b) end
 return b:finish()
end
return N
