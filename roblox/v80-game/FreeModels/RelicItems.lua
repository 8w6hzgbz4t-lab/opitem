-- Original procedural collectible geometry: no paid services or external assets.
-- All parts are anchored, non-colliding display geometry built through Primitives.
local M={}
local V,CF,RGB=Vector3.new,CFrame.new,Color3.fromRGB
local METAL,GLASS,PLASTIC,NEON=Enum.Material.Metal,Enum.Material.Glass,Enum.Material.SmoothPlastic,Enum.Material.Neon
local TAU=math.pi*2

local function companionCube(b)
 local body,edge,panel,inset=RGB(98,106,113),RGB(178,188,195),RGB(153,164,170),RGB(50,58,66)
 local pink,darkPink=RGB(242,148,177),RGB(159,76,113)
 b:box("WeightedStorageCore",V(3.28,3.28,3.28),CF(0,1.9,0),body,METAL)
 -- Rounded-looking corner caps are layered independently from the six inset faces.
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
  local p=V(x*1.57,1.9+y*1.57,z*1.57)
  b:box("CornerRecess",V(.66,.66,.66),CF(p),inset,METAL)
  b:box("CornerArmor",V(.52,.52,.52),CF(p+V(x*.09,y*.09,z*.09)),edge,METAL)
 end end end
 for _,a in ipairs({-1,1}) do for _,c in ipairs({-1,1}) do
  b:box("VerticalRecessSpine",V(.13,2.74,.13),CF(a*1.63,1.9,c*1.63),inset,METAL)
  b:box("HorizontalRecessSpineX",V(2.74,.13,.13),CF(0,1.9+a*1.63,c*1.63),inset,METAL)
  b:box("HorizontalRecessSpineZ",V(.13,.13,2.74),CF(a*1.63,1.9+c*1.63,0),inset,METAL)
 end end
 local faces={
  CF(0,1.9,-1.71)*CFrame.Angles(0,math.pi,0),CF(0,1.9,1.71),
  CF(-1.71,1.9,0)*CFrame.Angles(0,-math.pi/2,0),CF(1.71,1.9,0)*CFrame.Angles(0,math.pi/2,0),
  CF(0,3.61,0)*CFrame.Angles(-math.pi/2,0,0),CF(0,.19,0)*CFrame.Angles(math.pi/2,0,0),
 }
 for i,f in ipairs(faces) do
  local prefix="Face"..i
  b:box(prefix.."DarkInset",V(2.85,2.85,.10),f,inset,METAL)
  for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
   b:box(prefix.."Quadrant",V(1.22,1.22,.13),f*CF(x*.69,y*.69,.08),panel,METAL)
   b:box(prefix.."CornerBevel",V(.49,.49,.16),f*CF(x*1.29,y*1.29,.12)*CFrame.Angles(0,0,math.pi/4),edge,METAL)
   b:ball(prefix.."RecessedBolt",V(.085,.085,.035),f*CF(x*1.16,y*1.16,.165),inset,METAL)
  end end
  for _,s in ipairs({-1,1}) do
   b:box(prefix.."HorizontalArmor",V(2.36,.18,.15),f*CF(0,s*1.46,.10),edge,METAL)
   b:box(prefix.."VerticalArmor",V(.18,2.36,.15),f*CF(s*1.46,0,.10),edge,METAL)
  end
  b:cylinder(prefix.."EmblemPlate",V(.15,1.43,1.43),f*CF(0,0,.17)*CFrame.Angles(0,math.pi/2,0),RGB(186,189,190),METAL)
  b:ring(prefix.."EmblemRecess",f*CF(0,0,.265),.66,.065,inset,12,METAL)
  -- A fully three-dimensional heart emblem on every face, including top/bottom.
  b:ball(prefix.."HeartLobeLeft",V(.45,.45,.07),f*CF(-.19,.13,.294),pink,PLASTIC)
  b:ball(prefix.."HeartLobeRight",V(.45,.45,.07),f*CF(.19,.13,.294),pink,PLASTIC)
  b:triangle(prefix.."HeartTip",f*V(-.40,.13,.32),f*V(.40,.13,.32),f*V(0,-.47,.32),darkPink,.055,PLASTIC)
 end
end

local function cable(b,name,points,width,color)
 for i=1,#points-1 do b:line(name..i,points[i],points[i+1],width,width,color,METAL) end
end

local function protonPack(b)
 local black,charcoal,steel,brass=RGB(24,28,31),RGB(54,61,66),RGB(135,147,153),RGB(164,122,57)
 local red,blue=RGB(224,49,37),RGB(68,161,235)
 b:box("PackBackplate",V(2.5,3.82,.35),CF(0,2.46,.15),black,METAL)
 b:box("SteppedEquipmentBody",V(2.13,3.47,.67),CF(0,2.53,-.15),charcoal,METAL)
 b:box("UpperPowerBox",V(1.87,1.38,.28),CF(-.08,3.65,-.55),black,METAL)
 b:box("TopHandle",V(.90,.16,.25),CF(0,4.58,.05),steel,METAL)
 for _,s in ipairs({-1,1}) do
  b:box("CarryHandleBracket",V(.14,.33,.25),CF(s*.43,4.42,.05),black,METAL)
  b:box("BackplateSideRail",V(.16,3.48,.19),CF(s*1.17,2.49,.36),steel,METAL)
  b:box("LowerCornerArmor",V(.42,.28,.32),CF(s*.99,.75,-.03),black,METAL)
  -- Two broad straps remain visible from the player's side of the backpack.
  b:line("ShoulderStrapUpper",V(s*.72,4.1,.39),V(s*.73,3.30,.80),.22,.09,black,PLASTIC)
  b:line("ShoulderStrapLower",V(s*.73,3.30,.80),V(s*.69,1.1,.45),.22,.09,black,PLASTIC)
  b:box("StrapBuckle",V(.34,.34,.10),CF(s*.71,2.03,.71),steel,METAL)
  b:box("BuckleInset",V(.19,.19,.13),CF(s*.71,2.03,.735),black,METAL)
 end
 -- Concentric mechanical cyclotron, with exactly four red lens windows.
 local disc=CF(0,1.67,-.61)*CFrame.Angles(0,math.pi/2,0)
 b:cylinder("CyclotronOuterHousing",V(.24,2.22,2.22),disc,black,METAL)
 b:cylinder("CyclotronInsetFace",V(.29,1.93,1.93),disc,charcoal,METAL)
 b:ring("CyclotronRaisedRim",CF(0,1.67,-.80),1.055,.105,steel,20,METAL)
 b:ring("CyclotronInnerSeam",CF(0,1.67,-.815),.58,.038,black,16,METAL)
 b:cylinder("CyclotronCenter",V(.10,.56,.56),CF(0,1.67,-.83)*CFrame.Angles(0,math.pi/2,0),black,METAL)
 for i=0,3 do
  local a=math.pi/4+i*math.pi/2
  local p=V(math.cos(a)*.74,1.67+math.sin(a)*.74,-.84)
  b:ball("RedCyclotronLens"..i,V(.36,.36,.09),CF(p),red,NEON)
  b:ring("LensSteelBezel"..i,CF(p+V(0,0,-.045)),.205,.045,black,8,METAL)
 end
 -- Blue power-cell gauge, warning markings, and layered rear-side equipment.
 b:box("PowerCellFrame",V(.69,1.29,.22),CF(-.54,3.53,-.73),steel,METAL)
 b:box("PowerCellInset",V(.49,1.12,.24),CF(-.54,3.53,-.76),black,METAL)
 for i=0,7 do
  b:box("PowerCellSegment"..i,V(.34,.065,.04),CF(-.54,3.13+i*.115,-.91),i<6 and blue or charcoal,i<6 and NEON or METAL)
 end
 b:box("IonArmHousing",V(.58,1.6,.39),CF(.64,3.53,-.64),black,METAL)
 for i=0,4 do b:box("IonArmCoolingFin"..i,V(.71,.085,.52),CF(.64,2.96+i*.26,-.64),charcoal,METAL) end
 b:box("WarningLabelBacking",V(.63,.25,.035),CF(.62,4.00,-.93),RGB(218,190,83),PLASTIC)
 for i=0,3 do
  b:line("WarningStripe"..i,V(.36+i*.14,3.90,-.956),V(.47+i*.14,4.1,-.956),.045,.014,black,PLASTIC)
 end
 for _,s in ipairs({-1,1}) do
  for _,y in ipairs({.89,2.51,4.11}) do
   b:ball("HousingScrew",V(.075,.075,.04),CF(s*1.04,y,-.51),steel,METAL)
  end
 end
 for i=0,7 do
  b:box("SideVent"..i,V(.035,.11,.29),CF(-1.105,2.78+i*.12,-.17),black,METAL)
 end
 cable(b,"YellowInsulatedLead",{V(-1.13,3.82,-.57),V(-1.30,4.19,-.61),V(-1.07,4.39,-.61),V(.25,4.39,-.61),V(.45,4.15,-.69)},.075,RGB(205,171,64))
 cable(b,"RedAuxiliaryLead",{V(-.28,4.18,-.83),V(-.13,4.31,-.96),V(.1,4.24,-.97),V(.12,3.24,-.91),V(.38,3.02,-.87)},.055,red)
 -- Ribbed cable along the pack edge, clearly routed rather than floating.
 for i=0,17 do
  local a=-math.pi*.66+i/17*math.pi*1.18
  local p=V(-.25+math.cos(a)*1.17,2.42+math.sin(a)*1.66,-.67)
  local q=V(-.25+math.cos(a+.035)*1.17,2.42+math.sin(a+.035)*1.66,-.67)
  b:line("RibbedEdgeCable"..i,p,q,.14,.14,black,METAL)
 end
 -- Side-mounted neutrona wand, brass couplings, hand grip, and emitter muzzle.
 local wand=CF(1.69,2.60,-.20)*CFrame.Angles(0,0,-.12)
 b:box("WandMainBarrel",V(.38,2.21,.37),wand,charcoal,METAL)
 b:box("WandLowerGrip",V(.26,.89,.32),wand*CF(0,-1.02,.10),black,PLASTIC)
 b:box("WandTriggerGuard",V(.14,.48,.27),wand*CF(-.25,-.82,.08),steel,METAL)
 for i=0,6 do b:box("WandCoolingRib"..i,V(.44,.065,.43),wand*CF(0,-.09+i*.23,0),black,METAL) end
 for _,y in ipairs({-.50,.81,1.20}) do
  b:cylinder("WandBrassCoupling",V(.14,.49,.49),wand*CF(0,y,0)*CFrame.Angles(0,0,math.pi/2),brass,METAL)
 end
 b:cylinder("WandMuzzle",V(.20,.55,.55),wand*CF(0,1.39,0)*CFrame.Angles(0,0,math.pi/2),steel,METAL)
 b:cylinder("WandEmitterInset",V(.025,.32,.32),wand*CF(0,1.506,0)*CFrame.Angles(0,0,math.pi/2),black,METAL)
 b:box("WandRedToggle",V(.12,.16,.12),wand*CF(-.27,-.15,-.10),red,PLASTIC)
 local hose={}
 for i=0,13 do
  local t=i/13
  hose[#hose+1]=V(.79+1.0*t,.85-1.0*math.sin(t*math.pi)+.40*t,-.08)
 end
 cable(b,"MainWandHose",hose,.20,black)
 for i=1,#hose,2 do b:ball("HoseRib"..i,V(.23,.23,.23),CF(hose[i]),charcoal,METAL) end
 for _,p in ipairs({V(.79,.85,-.08),V(1.79,1.25,-.08)}) do
  b:cylinder("HoseBrassFitting",V(.28,.29,.29),CF(p)*CFrame.Angles(0,0,math.pi/2),brass,METAL)
 end
end

local stoneDefinitions={
 infinity_space={color=RGB(48,125,246),sides=8,height=2.3,rx=1.05,rz=.83,rings={{.0,.08},{.22,.83},{.73,1.0},{.90,.63},{1,.30}},rotation=math.pi/8},
 infinity_mind={color=RGB(248,210,57),sides=8,height=2.8,rx=.88,rz=.66,rings={{0,.03},{.20,.70},{.52,1},{.80,.70},{1,.03}},rotation=0},
 infinity_reality={color=RGB(208,39,63),sides=7,height=2.7,rx=.94,rz=.63,rings={{0,.08},{.21,.66},{.48,1},{.77,.60},{1,.02}},rotation=.22,irregular=true},
 infinity_power={color=RGB(154,73,231),sides=6,height=2.45,rx=1.06,rz=.95,rings={{0,.03},{.27,.83},{.64,1},{.86,.59},{1,.04}},rotation=math.pi/6},
 infinity_time={color=RGB(58,203,104),sides=10,height=2.3,rx=1.03,rz=.83,rings={{0,.08},{.23,.83},{.57,1},{.86,.71},{1,.27}},rotation=math.pi/10},
 infinity_soul={color=RGB(242,131,43),sides=8,height=2.6,rx=.94,rz=.73,rings={{0,.04},{.19,.68},{.54,1},{.84,.75},{1,.24}},rotation=math.pi/8},
}

local function infinityStone(b,key)
 local d=stoneDefinitions[key]
 if not d then return false end
 local rings={}
 for j,ring in ipairs(d.rings) do
  local points={}
  for i=0,d.sides-1 do
   local a=i*TAU/d.sides+d.rotation
   local modulation=d.irregular and (1+.13*math.sin(i*2.7+j*.4)) or 1
   local bend=d.irregular and .24*math.sin(ring[1]*math.pi*1.6) or 0
   points[i+1]=V(math.cos(a)*d.rx*ring[2]*modulation+bend,ring[1]*d.height,math.sin(a)*d.rz*ring[2]*modulation)
  end
  rings[j]=points
 end
 -- Closed crystalline geometry, with different cut proportions for all six stones.
 for j=1,#rings-1 do
  for i=1,d.sides do
   local k=i%d.sides+1
   local l=.09+((i*5+j*3)%9)*.039
   local shade=d.color:Lerp(RGB(255,255,255),l)
   local dark=d.color:Lerp(RGB(17,21,45),.13+((i+j)%3)*.055)
   local mat=(i+j)%4==0 and METAL or GLASS
   b:triangle("CrystalFacet"..j.."_"..i.."A",rings[j][i],rings[j+1][i],rings[j+1][k],shade,.025,mat)
   b:triangle("CrystalFacet"..j.."_"..i.."B",rings[j][i],rings[j+1][k],rings[j][k],dark,.025,GLASS)
  end
 end
 for _,j in ipairs({1,#rings}) do
  local centre=V(0,d.rings[j][1]*d.height,0)
  for i=1,d.sides do
   b:triangle("TerminalFacet"..j.."_"..i,centre,rings[j][i],rings[j][i%d.sides+1],d.color:Lerp(RGB(255,255,255),j==1 and .04 or .39),.025,GLASS)
  end
 end
 -- The narrow luminescent cut is embedded in the crystal, never a floating aura.
 local points=rings[3]
 local highlight=d.color:Lerp(RGB(255,255,255),.48)
 for i=1,d.sides do
  if i%3==0 then
   local k=i%d.sides+1
   b:line("IlluminatedGirdle"..i,points[i],points[k],.027,.027,highlight,NEON)
  end
 end
 b.model:SetAttribute("StoneType",key:sub(10))
 b.model:SetAttribute("CollectionFamily","InfinityStones")
 return true
end

function M.build(b,key)
 if key=="companion_cube" then companionCube(b)
 elseif key=="proton_pack" then protonPack(b)
 elseif stoneDefinitions[key] then return infinityStone(b,key)
 else return false end
 return true
end
return M
