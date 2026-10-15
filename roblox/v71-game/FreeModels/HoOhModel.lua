-- Native Roblox Ho-Oh sculpture. No mesh IDs, textures, paid services or NPC code.
-- All four components share the chest origin, facing -Z, with +Y up.
local M={}
local V,CF=Vector3.new,CFrame.new
local C=Color3.fromRGB
local SM=Enum.Material.SmoothPlastic
local RED=C(194,40,37)
local SCARLET=C(235,65,38)
local DARKRED=C(121,22,27)
local GREEN=C(31,127,93)
local TEAL=C(35,173,130)
local GOLD=C(248,197,58)
local PALE=C(255,231,135)
local IVORY=C(248,242,220)
local INK=C(23,31,38)

local function ellipsoid(b,name,a,c,width,thickness,color)
 local d=c-a
 return b:ball(name,V(width,thickness,d.Magnitude),CFrame.lookAt((a+c)*.5,c),color,SM)
end

-- A tapered feather with a colored shaft, pointed tip and lifted center ridge.
local function feather(b,name,a,c,width,color,ridge)
 local d=c-a
 local side=d:Cross(V(0,1,0))
 if side.Magnitude<.01 then side=V(1,0,0) end
 side=side.Unit*width*.5
 local shoulder=a+d*.66
 local n=V(0,.018,0)
 b:triangle(name.."Left",a,shoulder-side,c,color,.075,SM)
 b:triangle(name.."Right",a,c,shoulder+side,color,.075,SM)
 b:line(name.."Shaft",a+n,c+n,.035,.035,ridge or color,SM)
end

local function body(b)
 b:ball("ScarletChest",V(2.45,2.8,2.15),CF(0,0,0),RED,SM)
 b:ball("WarmBreast",V(1.95,2.35,.8),CF(0,-.12,-.87),SCARLET,SM)
 b:ball("CreamBelly",V(1.72,1.9,.56),CF(0,-.67,-1.13),IVORY,SM)
 b:ball("CreamLowerBelly",V(1.3,.82,.85),CF(0,-1.38,-.7),IVORY,SM)
 b:ball("BackShoulders",V(2.3,1.6,1.7),CF(0,.62,.25),DARKRED,SM)
 b:ball("Neck",V(1.28,1.6,1.32),CF(0,1.13,-.42),RED,SM)
 b:ball("Head",V(1.6,1.5,1.6),CF(0,2.05,-.65),SCARLET,SM)
 b:ball("Forehead",V(1.25,.83,.7),CF(0,2.39,-1.16),RED,SM)

 -- Three swept golden crest prongs; the outline remains readable at distance.
 for i=-1,1 do
  local x=i*.37
  local a=V(x,2.55,-.55)
  local c=V(i*.65,3.58-math.abs(i)*.17,-.06)
  feather(b,"GoldenCrest"..i,a,c,.49,GOLD,PALE)
 end
 b:ball("CrestRoot",V(1.17,.32,.56),CF(0,2.65,-.44),GOLD,SM)

 -- Cream eye masks, dark eyes, pinpoint glints and expressive red brows.
 for _,s in ipairs({-1,1}) do
  b:ball("EyeMask"..s,V(.57,.57,.35),CF(s*.59,2.12,-1.24)*CFrame.Angles(0,s*.24,0),IVORY,SM)
  b:ball("DarkEye"..s,V(.25,.32,.15),CF(s*.64,2.16,-1.405),INK,SM)
  b:ball("EyeGlint"..s,V(.075,.1,.06),CF(s*.615,2.225,-1.482),C(255,255,255),SM)
  b:line("AngledBrow"..s,V(s*.36,2.46,-1.38),V(s*.86,2.37,-1.3),.15,.14,DARKRED,SM)
  feather(b,"CheekPlume"..s,V(s*.54,1.96,-1.06),V(s*1.05,1.5,-.45),.37,RED,SCARLET)
 end
 b:ball("UpperGoldenBeak",V(.66,.52,.97),CF(0,1.99,-1.68),GOLD,SM)
 b:ball("BeakHook",V(.43,.6,.47),CF(0,1.79,-2.04)*CFrame.Angles(.22,0,0),GOLD,SM)
 b:wedge("SharpBeakTip",V(.34,.42,.37),CF(0,1.61,-2.08)*CFrame.Angles(0,math.pi,0),PALE,SM)
 b:line("BeakSeam",V(-.29,1.81,-1.76),V(.29,1.81,-1.76),.035,.045,C(133,88,25),SM)
 for _,s in ipairs({-1,1}) do
  b:ball("Nostril"..s,V(.07,.055,.09),CF(s*.17,2.14,-1.99),C(125,81,24),SM)
 end

 -- Layered belly and flank feathers conceal the primitive intersections.
 for row=0,2 do
  for col=-2,2 do
   local x=col*(.30-row*.025)
   local a=V(x,-.16-row*.42,-1.12+row*.015)
   local c=a+V(col*.035,-.66,.04)
   feather(b,"BreastFeather"..row.."_"..col,a,c,.38,IVORY,C(220,211,183))
  end
 end
 for _,s in ipairs({-1,1}) do
  for j=0,3 do
   feather(b,"Flank"..s.."_"..j,V(s*.89,.13-j*.35,-.13),V(s*(1.15-j*.03),-.66-j*.3,.5),.44,SCARLET,GOLD)
  end
  b:ball("ShoulderSocket"..s,V(.72,.88,.9),CF(s*1.1,.58,.06),RED,SM)
  -- Visible bent legs and three curled gold talons, suitable for a flying pose.
  b:line("UpperLeg"..s,V(s*.57,-1.25,-.15),V(s*.68,-1.92,-.3),.29,.29,GOLD,SM)
  b:line("LowerLeg"..s,V(s*.68,-1.92,-.3),V(s*.72,-1.96,-.72),.23,.24,GOLD,SM)
  for k=-1,1 do
   local a=V(s*.72+k*.16,-1.96,-.72)
   local c=V(s*.72+k*.24,-2.11,-1.15+(k==0 and -.1 or 0))
   b:line("Toe"..s.."_"..k,a,c,.105,.105,GOLD,SM)
   b:line("Claw"..s.."_"..k,c,c+V(0,.035,-.18),.062,.062,INK,SM)
  end
  b:line("RearToe"..s,V(s*.72,-1.96,-.6),V(s*.88,-2.07,-.17),.095,.095,GOLD,SM)
 end
end

local function wing(b,s)
 local name=s<0 and "Left" or "Right"
 local function p(x,y,z) return V(s*x,y,z) end
 -- A curved leading edge and broad red upper wing, with green trailing coverts.
 local shoulder=p(1.08,.61,.02)
 local elbow=p(3.25,1.05,.35)
 local wrist=p(5.25,.84,1.05)
 local tip=p(7.55,.28,2.04)
 ellipsoid(b,name.."UpperWing",shoulder,elbow,1.25,.68,RED)
 ellipsoid(b,name.."ForeWing",elbow,wrist,1.03,.49,SCARLET)
 b:triangle(name.."ScarletSailA",shoulder,wrist,p(3.3,.55,2.55),RED,.18,SM)
 b:triangle(name.."ScarletSailB",wrist,tip,p(5.8,.25,3.04),SCARLET,.15,SM)
 b:triangle(name.."GreenPanel",p(1.65,.47,.96),p(4.8,.59,1.8),p(3.2,.32,3.14),GREEN,.15,SM)
 b:line(name.."LeadingEdge1",shoulder,elbow,.16,.17,DARKRED,SM)
 b:line(name.."LeadingEdge2",elbow,wrist,.12,.14,GOLD,SM)
 b:line(name.."LeadingEdge3",wrist,tip,.09,.10,GOLD,SM)

 -- Eight long golden primaries give the broad, fingered wing outline.
 for i=0,7 do
  local t=i/7
  local a=p(3.45+t*3.48,.78-t*.40,.65+t*1.27)
  local c=p(3.07+t*4.87,.12-t*.14,3.6+t*.30)
  feather(b,name.."GoldenPrimary"..i,a,c,.64-t*.19,GOLD,PALE)
  -- White underside is visible from the arena beneath the flying bird.
  feather(b,name.."PrimaryUnderside"..i,a-V(0,.075,0),c-V(0,.075,0),.56-t*.18,IVORY,GOLD)
 end
 -- Fan of shorter secondary feathers with alternating red and green coverts.
 for i=0,4 do
  local x=1.55+i*.44
  feather(b,name.."Secondary"..i,p(x,.58,.55+i*.12),p(x+.12,.24,2.77+i*.12),.60,GOLD,PALE)
  feather(b,name.."GreenCovert"..i,p(x,.65,.35+i*.1),p(x+.34,.47,1.98+i*.1),.55,i%2==0 and GREEN or TEAL,GOLD)
 end
 for i=0,5 do
  local x=1.53+i*.78
  feather(b,name.."ScarletCovert"..i,p(x,.91,.1+i*.09),p(x+.24,.68,1.25+i*.17),.61,i%2==0 and RED or SCARLET,GOLD)
 end
end

local function tail(b)
 b:ball("TailRoot",V(1.24,.72,1.44),CF(0,-.66,1.04)*CFrame.Angles(-.2,0,0),DARKRED,SM)
 -- Seven long feathers make Ho-Oh's distinctive broad golden tail fan.
 for i=-3,3 do
  local a=V(i*.13,-.76,1.42)
  local c=V(i*.7,-.55+math.abs(i)*.12,5.98-math.abs(i)*.34)
  feather(b,"GoldenTailFeather"..i,a,c,.81,GOLD,PALE)
  -- Red bases and light terminal flashes add layers rather than plain rods.
  feather(b,"RedTailCovert"..i,a+V(0,.08,0),a+(c-a)*.38+V(0,.08,0),.65,SCARLET,DARKRED)
 end
 for i=-2,2 do
  feather(b,"SmallGreenTailCovert"..i,V(i*.15,-.62,1.3),V(i*.34,-.46,2.65),.44,GREEN,TEAL)
 end
end

function M.build(b,key)
 key=string.lower(key or "")
 if key=="hooh_body" then body(b)
 elseif key=="hooh_wing_left" then wing(b,-1)
 elseif key=="hooh_wing_right" then wing(b,1)
 elseif key=="hooh_tail" then tail(b)
 elseif key=="hooh_complete" then body(b); wing(b,-1); wing(b,1); tail(b)
 else return false end
 return true
end
return M
