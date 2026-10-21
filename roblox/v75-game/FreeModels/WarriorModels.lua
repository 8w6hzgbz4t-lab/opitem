-- Free, original native-part builders. No mesh service, textures or paid assets.
-- Front faces -Z. Figure sizes are collectible-sized; gods are scenic monuments.
local M = {}
local V, C, R = Vector3.new, CFrame.new, CFrame.Angles
local PI = math.pi
local METAL, NEON = Enum.Material.Metal, Enum.Material.Neon
local COL = Color3.fromRGB
local dark = COL(24, 23, 37)
local steel = COL(60, 63, 84)
local edge = COL(122, 127, 153)
local violet = COL(72, 43, 111)
local purple = COL(154, 73, 218)
local pink = COL(255, 93, 205)
local black = COL(8, 10, 18)
local gold = COL(219, 157, 39)
local paleGold = COL(255, 222, 120)
local goldShade = COL(125, 77, 18)
local ruby = COL(249, 45, 53)
local function box(b, n, x, y, z, sx, sy, sz, color, rot, material)
 return b:box(n, V(sx,sy,sz), C(x,y,z)*(rot or C()), color, material or METAL)
end
local function ball(b,n,x,y,z,sx,sy,sz,color,material)
 return b:ball(n,V(sx,sy,sz),C(x,y,z),color,material or METAL)
end
local function line(b,n,a,c,w,color,depth,material)
 return b:line(n,a,c,w,depth or w,color,material or METAL)
end
local function tri(b,n,a,c,d,color,t,material)
 return b:triangle(n,a,c,d,color,t or .045,material or METAL)
end
local function gem(b,n,x,y,z,r,depth,color)
 local tip=V(x,y,z-depth)
 for i=0,5 do
  local a=i*PI/3; local c=(i+1)*PI/3
  tri(b,n..i,tip,V(x+r*math.cos(a),y+r*math.sin(a),z),
   V(x+r*math.cos(c),y+r*math.sin(c),z),i%2==0 and color or color:Lerp(paleGold,.23),.025)
 end
end
local function horn(b,n,points,width,color,tipColor)
 for i=1,#points-1 do
  local w=width*(1-(i-1)/(#points-.25))
  line(b,n.."Segment"..i,points[i],points[i+1],w,color,w*.76)
  if i<#points-1 then ball(b,n.."Joint"..i,points[i+1].X,points[i+1].Y,points[i+1].Z,w*.86,w*.86,w*.86,color) end
 end
 local p=points[#points]; local q=points[#points-1]
 local d=(p-q).Unit
 tri(b,n.."SharpTip",p-d*width*.7+V(width*.20,0,0),p-d*width*.7-V(width*.20,0,0),p+d*width*.42,tipColor or color,.045)
end
local function platedSegment(b,n,x,y,z,width,height,depth,color,trim)
 box(b,n.."JointCore",x,y,z,width*.76,height,depth*.76,dark)
 box(b,n.."Face",x,y,z-depth*.40,width*.78,height*.83,depth*.30,color)
 for _,s in ipairs({-1,1}) do
  box(b,n.."Bevel"..s,x+s*width*.42,y,z-depth*.26,width*.18,height*.84,depth*.37,
   s==-1 and trim or color,R(0,-s*.45,0))
 end
 box(b,n.."TopEdge",x,y+height*.40,z-depth*.37,width*.83,height*.095,depth*.25,trim)
end

local function armoredKnight(b,mega)
 local body=mega and COL(64,72,91) or violet
 local trim=mega and COL(131,145,159) or COL(132,112,161)
 local accent=mega and gold or purple
 local prefix=mega and "MegaKnight" or "PEKKA"
 -- Broad, fully segmented body with beveled individual armor courses.
 box(b,prefix.."TorsoCore",0,2.72,.06,1.48,1.26,.80,dark)
 box(b,prefix.."UpperChest",0,3.16,-.16,1.55,.28,.78,body,R(-.09,0,0))
 for _,s in ipairs({-1,1}) do
  box(b,prefix.."ChestHalf"..s,s*.37,2.95,-.43,.70,.52,.21,body,R(0,s*.12,-s*.06))
  box(b,prefix.."ChestRim"..s,s*.37,3.18,-.55,.75,.085,.07,trim,R(0,0,-s*.07))
  box(b,prefix.."ChestSeam"..s,s*.075,2.91,-.56,.035,.41,.035,trim)
  ball(b,prefix.."ChestBolt"..s,s*.60,3.06,-.58,.10,.10,.06,accent)
 end
 for row=0,2 do
  box(b,prefix.."AbdominalCourse"..row,0,2.58-row*.17,-.45,1.12-row*.12,.135,.19,body)
  box(b,prefix.."AbdominalRim"..row,0,2.64-row*.17,-.56,1.10-row*.12,.025,.045,trim)
 end
 box(b,prefix.."BackArmor",0,2.85,.47,1.37,.94,.19,body)
 box(b,prefix.."Belt",0,2.05,0,1.20,.20,.86,black)
 box(b,prefix.."BeltTrim",0,2.08,-.46,1.20,.13,.09,trim)
 box(b,prefix.."Buckle",0,2.08,-.55,.30,.24,.10,accent)
 for _,s in ipairs({-1,1}) do
  local x=s*.44
  box(b,prefix.."HipSkirt"..s,s*.56,1.88,.01,.55,.43,.78,body,R(0,0,-s*.15))
  box(b,prefix.."HipSkirtFace"..s,s*.55,1.88,-.43,.46,.30,.08,trim,R(0,0,-s*.15))
  platedSegment(b,prefix.."Thigh"..s,x,1.43,.05,.56,.71,.63,body,trim)
  ball(b,prefix.."KneeJoint"..s,x,1.04,.04,.43,.41,.43,dark)
  box(b,prefix.."KneeCap"..s,x,1.05,-.36,.63,.31,.24,body,R(-.10,0,0))
  box(b,prefix.."KneeEdge"..s,x,1.16,-.50,.58,.06,.07,trim)
  platedSegment(b,prefix.."Shin"..s,x,.65,.03,.53,.59,.60,body,trim)
  box(b,prefix.."Boot"..s,x,.25,-.18,.66,.35,.99,body)
  box(b,prefix.."Sole"..s,x,.085,-.18,.69,.10,1.03,black)
  for toe=0,2 do box(b,prefix.."ToePlate"..s.."_"..toe,x+(toe-1)*.18,.27,-.70,.16,.22,.10,trim) end
  ball(b,prefix.."ShoulderJoint"..s,s*.88,3.13,0,.56,.56,.56,dark)
  box(b,prefix.."ShoulderBase"..s,s*1.01,3.26,.01,.84,.46,.94,body,R(0,0,-s*.14))
  box(b,prefix.."ShoulderTop"..s,s*1.03,3.45,-.02,.76,.13,.88,trim,R(0,0,-s*.14))
  box(b,prefix.."ShoulderFrontLip"..s,s*1.03,3.21,-.48,.79,.24,.10,body)
  platedSegment(b,prefix.."UpperArm"..s,s*1.12,2.77,.02,.44,.57,.52,body,trim)
  ball(b,prefix.."Elbow"..s,s*1.17,2.43,0,.35,.35,.35,dark)
  if mega then
   -- Huge spiked fist gauntlets are the silhouette-defining feature.
   box(b,prefix.."WristCuff"..s,s*1.22,2.31,-.04,.72,.23,.73,trim)
   box(b,prefix.."Gauntlet"..s,s*1.25,1.96,-.12,.84,.68,.86,body)
   box(b,prefix.."GauntletBack"..s,s*1.25,2.02,-.57,.76,.49,.14,trim)
   for finger=0,3 do
    box(b,prefix.."Finger"..s.."_"..finger,s*1.25+(finger-1.5)*.18,1.83,-.58,.15,.35,.21,body)
    box(b,prefix.."Knuckle"..s.."_"..finger,s*1.25+(finger-1.5)*.18,2.08,-.68,.16,.16,.11,trim)
   end
   box(b,prefix.."Thumb"..s,s*.79,1.96,-.23,.20,.39,.32,body,R(0,0,s*.22))
   for spike=0,2 do
    local sx=s*1.25+(spike-1)*.24
    tri(b,prefix.."FistSpike"..s.."_"..spike,V(sx-.12,2.20,-.65),V(sx+.12,2.20,-.65),V(sx,2.60,-.71),edge,.12)
   end
   for rivet=0,1 do ball(b,prefix.."GauntletBolt"..s..rivet,s*1.25+(rivet-.5)*.51,2.23,-.60,.10,.10,.07,gold) end
  else
   platedSegment(b,prefix.."Forearm"..s,s*1.17,2.13,-.01,.53,.54,.59,body,trim)
   box(b,prefix.."WristCuff"..s,s*1.17,1.84,-.05,.57,.14,.63,trim)
   box(b,prefix.."Hand"..s,s*1.17,1.64,-.11,.43,.33,.47,body)
   for finger=0,3 do box(b,prefix.."Finger"..s..finger,s*1.17+(finger-1.5)*.09,1.63,-.38,.075,.25,.10,trim) end
  end
 end
 -- Layered hollow face opening, cheeks and separate helmet crest.
 box(b,prefix.."Neck",0,3.51,.04,.49,.27,.49,dark)
 if mega then
  b:cylinder(prefix.."RoundSteelHelmet",V(.88,1.12,1.12),C(0,3.98,.02)*R(0,0,PI/2),body,METAL)
  ball(b,prefix.."RoundedHelmetCrown",0,4.29,.02,1.10,.40,.94,body)
  for i=0,5 do
   local a=i*PI/3
   box(b,prefix.."HelmetNeckRim"..i,math.cos(a)*.45,3.62,.02+math.sin(a)*.45,.43,.09,.16,trim,R(0,-a+PI/2,0))
  end
 else box(b,prefix.."HelmetCore",0,3.98,.02,1.11,.90,.88,body) end
 box(b,prefix.."FaceVoid",0,3.97,-.47,.86,.43,.09,black)
 box(b,prefix.."Brow",0,4.22,-.50,1.01,.14,.21,trim,R(-.10,0,0))
 for _,s in ipairs({-1,1}) do
  box(b,prefix.."Cheek"..s,s*.47,3.87,-.44,.22,.55,.24,body,R(0,s*.20,s*.10))
  box(b,prefix.."Eye"..s,s*.22,4.03,-.603,.27,.065,.035,mega and paleGold or pink,R(0,0,-s*.12),NEON)
  box(b,prefix.."JawPlate"..s,s*.23,3.65,-.43,.49,.21,.26,trim,R(0,0,s*.07))
  ball(b,prefix.."HelmetRivet"..s,s*.40,4.29,-.53,.085,.085,.05,accent)
 end
 box(b,prefix.."NoseGuard",0,3.95,-.57,.12,.39,.15,body)
 if mega then
  box(b,prefix.."HelmetCrest",0,4.47,.01,.20,.33,.86,trim)
  for rib=0,3 do box(b,prefix.."HelmetCrestRib"..rib,0,4.65,-.30+rib*.20,.27,.08,.09,body) end
  for _,s in ipairs({-1,1}) do
   horn(b,prefix.."ShoulderSpike"..s,{V(s*1.16,3.45,.10),V(s*1.29,3.78,.13),V(s*1.40,3.96,.14)},.20,edge)
  end
 else
  for _,s in ipairs({-1,1}) do
   horn(b,prefix.."CurvedHorn"..s,{V(s*.47,4.26,.05),V(s*.76,4.48,.08),V(s*.88,4.87,.03),V(s*.74,5.21,-.04)},.30,purple,COL(226,154,255))
  end
  -- Real sharp blade geometry, double beveled rather than a rectangular slab.
  local sx=-1.65
  box(b,prefix.."SwordGrip",sx,1.48,-.34,.17,.65,.18,black)
  for wrap=0,4 do box(b,prefix.."SwordWrap"..wrap,sx,1.28+wrap*.11,-.35,.20,.045,.20,accent) end
  box(b,prefix.."SwordGuard",sx,1.85,-.34,.82,.17,.27,trim)
  ball(b,prefix.."SwordPommel",sx,1.10,-.34,.27,.22,.25,trim)
  local base,tip=2.02,4.69
  tri(b,prefix.."BladeLeft",V(sx-.36,base,-.34),V(sx,tip,-.34),V(sx,base,-.48),edge,.075)
  tri(b,prefix.."BladeRight",V(sx,base,-.48),V(sx,tip,-.34),V(sx+.36,base,-.34),COL(192,199,216),.075)
  tri(b,prefix.."BladeRearLeft",V(sx-.36,base,-.34),V(sx,base,-.20),V(sx,tip,-.34),COL(81,83,106),.055)
  tri(b,prefix.."BladeRearRight",V(sx,base,-.20),V(sx+.36,base,-.34),V(sx,tip,-.34),trim,.055)
  line(b,prefix.."BladeFuller",V(sx,2.16,-.50),V(sx,4.28,-.41),.055,purple,.035,NEON)
 end
end

local function ra(b)
 -- A gold avian god with individually layered swept blade feathers.
 local shell=COL(233,173,43)
 local lit=COL(255,224,126)
 local shade=COL(151,92,17)
 ball(b,"RaTorsoCore",0,10.4,.5,5.0,7.4,3.6,shade)
 for _,s in ipairs({-1,1}) do
  box(b,"RaSculptedPectoral"..s,s*1.08,12.21,-1.13,2.14,1.70,1.03,shell,R(0,s*.16,-s*.14))
  box(b,"RaPectoralBevel"..s,s*1.06,12.84,-1.73,2.01,.28,.18,lit,R(0,0,-s*.14))
  line(b,"RaClavicle"..s,V(s*.13,13.22,-1.36),V(s*2.08,13.42,-.87),.32,lit,.27)
  ball(b,"RaShoulder"..s,s*2.5,12.87,.18,1.67,1.8,2.0,shell)
  box(b,"RaHipArmor"..s,s*1.54,7.79,-.24,1.51,1.45,2.00,shell,R(0,0,-s*.20))
  for stripe=0,2 do box(b,"RaHipEdge"..s..stripe,s*1.54,8.27-stripe*.35,-1.30,1.40,.10,.13,lit,R(0,0,-s*.20)) end
 end
 for row=0,5 do
  local w=3.42-row*.30
  box(b,"RaAbdominalScale"..row,0,11.08-row*.54,-1.34,w,.51,.45,row%2==0 and shell or gold)
  box(b,"RaAbdominalLip"..row,0,11.29-row*.54,-1.59,w*.94,.075,.10,lit)
 end
 gem(b,"RaHeart",0,12.28,-1.87,.59,.33,ruby)
 b:ring("RaHeartGoldSocket",C(0,12.28,-1.85),.66,.12,lit,12,METAL)
 -- Long segmented neck, hawk face and actual hooked beak.
 line(b,"RaNeckCore",V(0,13.10,.20),V(0,16.76,-.54),1.56,shade,1.45)
 for row=0,5 do
  local y=13.48+row*.53; local z=.1-row*.11
  box(b,"RaNeckCollar"..row,0,y,z,1.78-row*.045,.35,1.63,shell,R(-.17,0,0))
  box(b,"RaNeckFrontScale"..row,0,y,z-.92,1.55-row*.045,.25,.14,lit,R(-.17,0,0))
 end
 box(b,"RaHeadCore",0,17.35,-.65,2.08,1.72,2.28,shell,R(-.10,0,0))
 box(b,"RaCrownCenter",0,18.54,-.63,.49,1.18,1.85,lit,R(-.12,0,0))
 for _,s in ipairs({-1,1}) do
  box(b,"RaHeadCheek"..s,s*.97,17.12,-1.05,.43,1.04,1.58,shade,R(0,s*.13,s*.09))
  box(b,"RaEyeShadow"..s,s*.73,17.64,-1.83,.63,.34,.14,black,R(0,0,-s*.16))
  box(b,"RaRubyEye"..s,s*.74,17.66,-1.92,.42,.12,.07,ruby,R(0,0,-s*.16),NEON)
  box(b,"RaEyeBrow"..s,s*.73,17.93,-1.94,.81,.17,.19,lit,R(0,0,-s*.16))
  tri(b,"RaCheekBlade"..s,V(s*.96,17.43,-1.63),V(s*1.69,16.43,-.74),V(s*.80,16.42,-1.57),gold,.20)
  horn(b,"RaRoyalHorn"..s,{V(s*.75,18.08,-.12),V(s*1.36,18.95,.06),V(s*1.64,20.27,.20),V(s*1.30,21.30,.22)},.57,lit)
 end
 box(b,"RaBeakRoot",0,17.20,-2.07,.93,.69,.81,lit)
 tri(b,"RaUpperBeak",V(-.48,17.47,-2.20),V(.48,17.47,-2.20),V(0,17.08,-3.28),lit,.43)
 tri(b,"RaHookedBeak",V(-.25,17.17,-3.07),V(.25,17.17,-3.07),V(0,16.40,-2.97),gold,.27)
 line(b,"RaBeakMouth",V(-.33,16.94,-2.58),V(.33,16.94,-2.58),.075,black)
 box(b,"RaLowerBeak",0,16.73,-2.24,.75,.26,1.07,shade,R(.09,0,0))
 gem(b,"RaCrownRuby",0,18.25,-1.83,.29,.17,ruby)
 -- Engraved royal face armor and a sun disc sit behind the horned head.
 -- Separate plate edges keep the silhouette clear from the arena floor.
 for _,s in ipairs({-1,1}) do
  box(b,"RaLayeredJawPlate"..s,s*.66,16.52,-1.49,.69,.30,.55,shell,R(0,s*.18,s*.12))
  box(b,"RaNostrilInset"..s,s*.27,17.34,-2.52,.12,.09,.07,black)
  line(b,"RaFacialEngraving"..s,V(s*.31,17.96,-1.98),V(s*.75,18.25,-1.94),.075,shade,.055)
  line(b,"RaBeakRidge"..s,V(s*.16,17.51,-2.30),V(0,17.10,-3.20),.075,paleGold,.065)
 end
 b:ring("RaSolarHalo",C(0,17.85,2.12),3.15,.12,lit,24,METAL)
 for ray=0,7 do
  local angle=ray*PI/4
  local outward=V(math.cos(angle),math.sin(angle),0)
  local tangent=V(-math.sin(angle),math.cos(angle),0)
  local start=V(0,17.85,2.12)+outward*3.12
  tri(b,"RaSolarRay"..ray,start-tangent*.18,start+outward*.64,start+tangent*.18,gold,.10)
 end
 for row=0,4 do
  local y=10.94-row*.54
  line(b,"RaRoyalInscriptionStem"..row,V(-.18,y-.11,-1.60),V(-.18,y+.12,-1.60),.055,shade,.045)
  line(b,"RaRoyalInscriptionCrown"..row,V(-.18,y+.12,-1.60),V(.18,y+.12,-1.60),.055,shade,.045)
  line(b,"RaRoyalInscriptionFoot"..row,V(-.18,y-.11,-1.60),V(.10,y-.11,-1.60),.055,shade,.045)
 end
 for _,s in ipairs({-1,1}) do
  -- Each wing has an arched structural arm and separate overlapping blades.
  local root=V(s*2.35,13.10,.68); local joint=V(s*6.6,16.48,.90)
  line(b,"RaWingUpperBone"..s,root,joint,.68,lit,.76)
  line(b,"RaWingLeadingEdge"..s,joint,V(s*13.45,20.45,1.17),.50,lit,.60)
  tri(b,"RaWingInnerArmor"..s,V(s*2.85,13.31,1.54),V(s*6.6,16.20,1.54),V(s*6.45,10.35,1.77),shade,.12)
  tri(b,"RaWingOuterArmor"..s,V(s*6.6,16.20,1.54),V(s*12.9,19.52,1.54),V(s*6.45,10.35,1.77),gold,.12)
  for i=0,10 do
   local t=i/10
   local a=V(s*(3.10+t*8.80),13.7+t*5.91,.77+t*.30)
   local tip=V(s*(6.0+t*10.20),8.0+t*12.0,1.7+math.sin(t*PI)*.36)
   local perp=V(s*.64,.36,0)
   local center=a:Lerp(tip,.50)-V(0,0,.11)
   tri(b,"RaPrimaryFeather"..s.."_"..i,a-perp,tip,center,i%2==0 and shell or gold,.13)
   tri(b,"RaPrimaryFeatherRidge"..s.."_"..i,center,tip,a+perp,lit,.12)
   line(b,"RaPrimaryFeatherShaft"..s.."_"..i,a,tip,.09,shade,.11)
  end
  for i=0,6 do
   local t=i/6
   local a=V(s*(2.8+t*5.8),13.18+t*3.45,.37)
   local tip=V(s*(5.3+t*5.65),10.8+t*4.0,.37)
   tri(b,"RaUpperCoverFeather"..s.."_"..i,a-V(s*.36,0,0),tip,a+V(s*.36,.24,0),lit,.16)
   line(b,"RaUpperCoverRidge"..s.."_"..i,a,tip,.09,goldShade,.07)
  end
  for i=0,4 do
   local a=V(s*(3.15+i*.91),13.34+i*.54,.04)
   local c=V(s*(4.35+i*.91),12.20+i*.60,.04)
   tri(b,"RaRaisedWingCover"..s..i,a-V(s*.38,0,0),c,a+V(s*.38,.28,0),shell,.17)
  end
  -- Gold-inlaid vane lines and individual rivets follow each wing's sweep.
  for i=0,7 do
   local x=s*(3.25+i*1.19);local y=13.76+i*.66
   ball(b,"RaWingGoldRivet"..s..i,x,y,.32,.14,.14,.10,paleGold)
  end
  for i=0,5 do
   local a=V(s*(3.40+i*1.05),13.52+i*.60,.10)
   line(b,"RaWingInlaidChevron"..s..i,a,a+V(s*.27,-.27,-.025),.065,shade,.055)
   line(b,"RaWingInlaidChevronReturn"..s..i,a+V(s*.27,-.27,-.025),a+V(s*.56,-.10,-.025),.065,shade,.055)
  end
  -- Open talons and armored legs rather than generic pedestals.
  line(b,"RaThigh"..s,V(s*1.24,7.26,.40),V(s*1.91,5.00,.26),1.15,shell,1.18)
  ball(b,"RaKnee"..s,s*1.91,5.00,.19,1.35,1.23,1.44,gold)
  line(b,"RaShin"..s,V(s*1.91,4.83,.27),V(s*2.10,2.20,-.30),.83,shell,.98)
  for row=0,4 do box(b,"RaShinScale"..s..row,s*(1.97+row*.035),4.50-row*.44,-.43-row*.08,.94,.22,.22,lit) end
  box(b,"RaAnkle"..s,s*2.11,1.93,-.32,1.12,.53,1.13,shade)
  for toe=0,2 do
   local tx=s*2.1+(toe-1)*.52
   line(b,"RaToe"..s..toe,V(tx,1.83,-.53),V(tx,1.20,-2.10),.35,shell,.40)
   tri(b,"RaTalon"..s..toe,V(tx-.17,1.37,-2.00),V(tx+.17,1.37,-2.00),V(tx,.81,-2.83),lit,.20)
  end
  line(b,"RaRearToe"..s,V(s*2.14,1.87,-.04),V(s*2.30,1.13,1.38),.32,gold,.34)
 end
 -- A sweeping armored tail is visible behind and below the body.
 local tail={V(0,7.57,1.21),V(0,6.08,3.19),V(0,4.81,5.76),V(0,3.35,7.20),V(0,2.28,8.41)}
 for i=1,#tail-1 do
  line(b,"RaTailSegment"..i,tail[i],tail[i+1],1.10-i*.17,gold,1.24-i*.19)
  local p=tail[i]:Lerp(tail[i+1],.5)
  box(b,"RaTailRidge"..i,p.X,p.Y+.34,p.Z,.58,.32,.60,lit,R(-.31,0,0))
  for _,s in ipairs({-1,1}) do box(b,"RaTailSidePlate"..i..s,p.X+s*(.44-i*.045),p.Y,p.Z,.12,.33,.43,shell,R(-.31,0,0)) end
 end
 for _,s in ipairs({-1,1}) do
  tri(b,"RaTailFin"..s,V(0,2.59,7.88),V(s*2.23,1.52,9.63),V(0,1.64,9.42),shell,.18)
 end
end

local function obelisk(b)
 local blue=COL(42,92,159)
 local mid=COL(66,128,196)
 local light=COL(112,177,227)
 local shade=COL(24,54,108)
 -- Broad tapered torso assembled as four sculpted armor courses.
 box(b,"ObeliskTorsoShadow",0,11.57,.40,5.72,7.15,3.04,shade)
 for _,s in ipairs({-1,1}) do
  box(b,"ObeliskPectoralCore"..s,s*1.77,13.55,-1.14,3.41,2.52,1.61,blue,R(0,s*.15,-s*.10))
  local pectoralRim={V(s*.28,14.57,-1.78),V(s*2.56,14.71,-1.69),V(s*3.34,13.76,-1.58),
   V(s*3.06,12.78,-1.73),V(s*1.38,12.37,-1.93),V(s*.28,12.79,-1.88)}
  local peak=V(s*1.63,13.55,-2.32)
  for i=1,#pectoralRim do
   tri(b,"ObeliskSculptedPectoral"..s.."_"..i,peak,pectoralRim[i],pectoralRim[i%#pectoralRim+1],
    i%2==0 and blue or blue:Lerp(mid,.34),.07)
  end
  box(b,"ObeliskPectoralUpperBevel"..s,s*1.77,14.58,-1.81,3.26,.42,.29,mid,R(0,0,-s*.10))
  box(b,"ObeliskPectoralOuterBevel"..s,s*3.04,13.40,-1.56,.55,2.14,.47,mid,R(0,s*.31,-s*.10))
  box(b,"ObeliskPectoralLowerRidge"..s,s*1.79,12.54,-1.85,2.85,.20,.24,light,R(0,0,s*.09))
  line(b,"ObeliskCollarBone"..s,V(s*.15,14.98,-1.04),V(s*3.43,15.18,-.67),.55,mid,.56)
  box(b,"ObeliskSideRib"..s,s*2.54,11.07,-.39,.97,2.81,1.57,blue,R(0,0,-s*.12))
  for row=0,3 do box(b,"ObeliskSerratus"..s..row,s*(2.36-row*.11),11.98-row*.57,-1.31,.84,.36,.26,mid,R(0,0,s*.20)) end
 end
 for row=0,3 do
  local w=1.38-row*.13
  for _,s in ipairs({-1,1}) do
   box(b,"ObeliskAbdominalMuscle"..s..row,s*(w*.52+.09),11.85-row*.76,-1.49,w,.64,.51,blue,R(0,s*.07,0))
   box(b,"ObeliskAbdominalEdge"..s..row,s*(w*.52+.09),12.10-row*.76,-1.77,w*.87,.095,.11,mid)
  end
 end
 box(b,"ObeliskPelvis",0,8.70,.27,4.32,1.40,2.90,shade)
 box(b,"ObeliskBelt",0,9.06,-.21,4.67,.47,3.08,blue)
 tri(b,"ObeliskBeltPoint",V(-1.10,9.22,-1.85),V(1.10,9.22,-1.85),V(0,7.57,-1.72),mid,.30)
 for _,s in ipairs({-1,1}) do
  -- Heavy plated thighs and strong clawed feet.
  local x=s*1.45
  box(b,"ObeliskHipBlade"..s,s*2.15,8.43,.15,1.24,1.65,3.13,blue,R(0,0,-s*.15))
  platedSegment(b,"ObeliskThigh"..s,x,6.94,.31,1.92,2.65,2.16,blue,mid)
  box(b,"ObeliskThighRidge"..s,x,7.06,-1.07,.31,2.20,.19,light,R(0,0,s*.08))
  ball(b,"ObeliskKneeJoint"..s,x,5.23,.20,1.56,1.56,1.71,shade)
  box(b,"ObeliskKneeShield"..s,x,5.29,-1.00,2.01,1.00,.49,mid,R(-.09,0,0))
  tri(b,"ObeliskKneePoint"..s,V(x-.86,5.34,-1.31),V(x+.86,5.34,-1.31),V(x,4.51,-1.39),blue,.23)
  platedSegment(b,"ObeliskShin"..s,x,3.43,.31,1.80,2.67,2.18,blue,mid)
  box(b,"ObeliskShinSpine"..s,x,3.48,-1.10,.31,2.41,.18,light)
  for row=0,2 do box(b,"ObeliskShinCourse"..s..row,x,4.21-row*.64,-1.16,1.56,.12,.10,mid) end
  box(b,"ObeliskFoot"..s,x,1.35,-.29,2.17,1.25,3.30,blue)
  box(b,"ObeliskHeel"..s,x,1.08,1.13,1.79,.89,.63,shade)
  for toe=0,2 do
   local tx=x+(toe-1)*.61
   box(b,"ObeliskToe"..s..toe,tx,1.30,-1.94,.54,.75,.63,mid)
   tri(b,"ObeliskToeClaw"..s..toe,V(tx-.24,1.52,-2.10),V(tx+.24,1.52,-2.10),V(tx,.89,-2.70),light,.20)
  end
  -- Oversized shoulder volumes, pointed pauldron and layered upper arms.
  ball(b,"ObeliskShoulder"..s,s*4.10,14.20,.11,3.32,3.47,3.26,blue)
  box(b,"ObeliskShoulderCap"..s,s*4.11,15.38,.01,3.39,.74,3.31,mid,R(0,0,-s*.14))
  box(b,"ObeliskShoulderFrontPlate"..s,s*4.12,14.49,-1.61,2.65,1.49,.32,blue,R(0,0,-s*.12))
  for plate=0,2 do
   local px=s*(3.40+plate*.67)
   tri(b,"ObeliskShoulderBevelFacet"..s..plate,V(px-s*.35,15.15,-1.70),V(px+s*.35,15.05,-1.70),V(px,14.07,-1.91),mid,.08)
  end
  tri(b,"ObeliskShoulderSpike"..s,V(s*3.40,15.52,-.05),V(s*4.91,15.31,-.05),V(s*5.01,17.57,-.05),mid,.65)
  box(b,"ObeliskBicepCore"..s,s*4.72,12.17,.12,2.12,3.04,2.27,shade,R(0,0,s*.07))
  ball(b,"ObeliskBicepMuscle"..s,s*4.73,12.40,-.73,2.07,2.66,1.71,blue)
  box(b,"ObeliskUpperArmOuterPlate"..s,s*5.53,12.30,.16,.35,2.48,1.88,mid,R(0,0,s*.07))
  ball(b,"ObeliskElbow"..s,s*4.90,10.61,.17,1.63,1.53,1.73,shade)
  box(b,"ObeliskElbowShield"..s,s*5.47,10.62,-.05,1.38,1.09,1.57,blue,R(0,0,-s*.28))
  box(b,"ObeliskForearmCore"..s,s*5.06,9.40,-.13,2.10,2.05,2.37,blue,R(-.09,0,0))
  box(b,"ObeliskForearmFace"..s,s*5.06,9.52,-1.38,1.95,1.79,.31,mid,R(-.09,0,0))
  for rib=0,2 do box(b,"ObeliskForearmRib"..s..rib,s*5.06,10.16-rib*.55,-1.61,1.74,.13,.16,light) end
  box(b,"ObeliskWristCuff"..s,s*5.06,8.28,-.28,2.27,.43,2.50,shade)
  box(b,"ObeliskFistCore"..s,s*5.04,7.23,-.45,2.55,1.88,2.56,blue)
  box(b,"ObeliskFistBackPlate"..s,s*5.04,7.58,-1.84,2.39,1.12,.37,mid)
  for finger=0,3 do
   local fx=s*5.04+(finger-1.5)*.56
   box(b,"ObeliskFinger"..s..finger,fx,6.94,-1.79,.49,1.17,.49,blue)
   box(b,"ObeliskKnuckle"..s..finger,fx,7.77,-1.99,.50,.51,.38,light)
   box(b,"ObeliskFingerJoint"..s..finger,fx,6.99,-2.05,.46,.095,.065,shade)
  end
  box(b,"ObeliskThumb"..s,s*3.55,7.25,-.70,.71,1.32,.95,mid,R(0,0,s*.27))
 end
 -- Detailed demonic face with separate teeth, brows and long curved horns.
 box(b,"ObeliskNeck",0,15.67,.31,2.24,1.37,2.18,shade)
 box(b,"ObeliskHeadCore",0,17.34,-.02,3.40,2.84,2.52,blue)
 box(b,"ObeliskCrown",0,18.64,.08,2.91,.62,2.44,mid)
 box(b,"ObeliskFaceVoid",0,17.22,-1.33,2.64,1.64,.21,shade)
 for _,s in ipairs({-1,1}) do
  box(b,"ObeliskCheekBone"..s,s*1.23,17.12,-1.34,.80,1.56,.65,mid,R(0,s*.18,s*.16))
  box(b,"ObeliskBrow"..s,s*.73,18.03,-1.61,1.41,.44,.43,mid,R(0,0,-s*.16))
  box(b,"ObeliskEyeSocket"..s,s*.72,17.75,-1.61,1.01,.34,.20,black,R(0,0,-s*.13))
  box(b,"ObeliskRedEye"..s,s*.72,17.77,-1.76,.69,.14,.07,ruby,R(0,0,-s*.13),NEON)
  box(b,"ObeliskJawSide"..s,s*.93,16.25,-1.30,.71,.79,.79,blue,R(0,0,s*.18))
  line(b,"ObeliskCheekScar"..s,V(s*1.36,17.51,-1.74),V(s*1.05,16.87,-1.78),.12,light,.08)
  horn(b,"ObeliskTempleHorn"..s,{V(s*1.35,18.16,.09),V(s*2.15,18.92,.23),V(s*2.74,20.42,.39),V(s*2.65,22.11,.36),V(s*2.19,23.23,.12)},.81,mid,light)
  horn(b,"ObeliskRearHorn"..s,{V(s*1.12,18.40,1.02),V(s*1.57,19.44,1.37),V(s*1.43,20.55,1.55)},.51,blue,mid)
 end
 tri(b,"ObeliskNoseBridge",V(-.31,18.20,-1.69),V(.31,18.20,-1.69),V(0,17.12,-2.08),light,.25)
 box(b,"ObeliskMouthVoid",0,16.72,-1.74,1.73,.47,.20,black)
 for tooth=0,5 do
  local x=(tooth-2.5)*.25
  tri(b,"ObeliskUpperTooth"..tooth,V(x-.095,16.94,-1.89),V(x+.095,16.94,-1.89),V(x,16.65,-1.91),COL(201,224,235),.11)
 end
 for tooth=0,4 do
  local x=(tooth-2)*.25
  tri(b,"ObeliskLowerTooth"..tooth,V(x-.09,16.50,-1.89),V(x+.09,16.50,-1.89),V(x,16.71,-1.91),COL(167,197,218),.10)
 end
 box(b,"ObeliskChin",0,16.03,-1.50,1.46,.43,.64,mid)
 tri(b,"ObeliskChinPoint",V(-.48,16.01,-1.86),V(.48,16.01,-1.86),V(0,15.46,-1.85),light,.21)
 for rib=0,4 do
  box(b,"ObeliskBackSpine"..rib,0,14.66-rib*1.12,2.18,.63,.65,.46,mid,R(.11,0,0))
  for _,s in ipairs({-1,1}) do
   box(b,"ObeliskBackRib"..s..rib,s*(1.61-rib*.13),14.56-rib*1.12,2.00,2.39-rib*.19,.28,.33,blue,R(0,0,s*.17))
  end
 end
end

function M.build(b,key)
 if key=="pekka" then armoredKnight(b,false)
 elseif key=="mega_knight" then armoredKnight(b,true)
 elseif key=="winged_dragon_ra" then ra(b)
 elseif key=="obelisk_tormentor" then obelisk(b)
 else return false end
 return true
end
return M
