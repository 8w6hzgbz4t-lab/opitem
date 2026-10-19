-- Detailed collectible weapons. Visual parts only; gameplay stays in the catalog.
-- Front is local -Z. Primitives.finish aligns the completed model to its base.
local M = {}
local V, CF = Vector3.new, CFrame.new
local RGB = Color3.fromRGB
local METAL, NEON, PLASTIC = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.SmoothPlastic
local steel, silver, shadow = RGB(147,166,186), RGB(229,240,248), RGB(36,44,58)
local gold, goldDark = RGB(231,183,67), RGB(129,86,32)
local cyan, teal, tealDark = RGB(81,246,234), RGB(29,176,181), RGB(12,70,80)
local purple, leather = RGB(81,45,161), RGB(77,42,31)

local function box(b,n,x,y,z,sx,sy,sz,c,mat,rot)
 return b:box(n,V(sx,sy,sz),CF(x,y,z)*(rot or CF()),c,mat or METAL)
end
local function ball(b,n,x,y,z,sx,sy,sz,c,mat)
 return b:ball(n,V(sx,sy,sz),CF(x,y,z),c,mat or METAL)
end
local function line(b,n,a,c,w,col,mat,depth)
 return b:line(n,a,c,w,depth or w,col,mat or METAL)
end
local function ring(b,n,x,y,z,r,w,col,segments,mat)
 b:ring(n,CF(x,y,z),r,w,col,segments or 14,mat or METAL)
end
local function quad(b,n,a,c,d,e,col,thick,mat)
 b:triangle(n.."1",a,c,d,col,thick or .022,mat or METAL)
 b:triangle(n.."2",a,d,e,col,thick or .022,mat or METAL)
end
local function grip(b,n,y0,length,color,turns,wrapColor)
 box(b,n.."Core",0,y0+length*.5,0,.23,length,.24,color or leather,PLASTIC)
 for i=0,(turns or 10)-1 do
  local y=y0+(i+.5)*length/(turns or 10)
  for _,z in ipairs({-.132,.132}) do
   line(b,n.."Wrap"..i.."_"..z,V(-.125,y-.035,z),V(.125,y+.035,z),.038,wrapColor or RGB(151,105,67),PLASTIC,.026)
  end
 end
 box(b,n.."CollarLower",0,y0,0,.31,.11,.31,shadow)
 box(b,n.."CollarUpper",0,y0+length,0,.31,.12,.31,silver)
end
local function blade(b,n,y0,y1,halfWidth,tipHeight,color)
 -- A flat central face and sloping side facets meet at thin cutting edges.
 box(b,n.."Core",0,(y0+y1)*.5,0,halfWidth*1.42,y1-y0,.18,color or steel)
 for _,side in ipairs({-1,1}) do
  local inner=side*halfWidth*.70
  local edge=side*halfWidth
  for _,front in ipairs({-1,1}) do
   quad(b,n.."Bevel"..side.."_"..front,
    V(inner,y0,front*.095),V(inner,y1,front*.095),V(edge,y1,0),V(edge,y0,0),
    side==1 and silver or RGB(116,138,159),.025)
   b:triangle(n.."Tip"..side.."_"..front,V(inner,y1,front*.095),V(edge,y1,0),V(0,y1+tipHeight,0),silver,.025,METAL)
  end
 end
 for _,front in ipairs({-1,1}) do
  b:triangle(n.."TipFace"..front,V(-halfWidth*.70,y1,front*.095),V(halfWidth*.70,y1,front*.095),V(0,y1+tipHeight,0),color or steel,.024,METAL)
 end
end
local function rune(b,n,x,y,z,s,col)
 line(b,n.."Stem",V(x,y-s*.5,z),V(x,y+s*.5,z),.018,col)
 line(b,n.."Upper",V(x,y+s*.25,z),V(x+s*.32,y+s*.06,z),.018,col)
 line(b,n.."Lower",V(x,y-s*.12,z),V(x-s*.30,y-s*.32,z),.018,col)
end

local function pixel(b)
 local u=.245
 -- An intentionally stepped voxel outline, with individual face highlights.
 for row=0,3 do
  box(b,"HandlePixel"..row,0,.12+row*u,0,u,u,.25,leather,PLASTIC)
  box(b,"HandleHighlight"..row,-.055,.12+row*u,-.135,.065,.18,.026,RGB(168,114,60),PLASTIC)
 end
 box(b,"PommelPixel",0,-.07,0,.36,.19,.29,RGB(93,54,26),PLASTIC)
 for x=-3,3 do
  local y=1.02-math.abs(x)*.06
  box(b,"GuardPixel"..x,x*u,y,0,u,u,.30,tealDark)
  box(b,"GuardPixelInset"..x,x*u,y,-.164,u*.70,u*.70,.027,x==0 and cyan or teal)
 end
 for row=0,11 do
  local radius=row>=10 and 0 or 1
  for col=-radius,radius do
   local y=1.28+row*u
   box(b,"DiamondPixel"..row.."_"..col,col*u,y,0,u,u,.23,col==0 and cyan or teal)
   box(b,"DiamondFace"..row.."_"..col,col*u-.025,y+.025,-.13,u*.68,u*.68,.025,
    col==0 and RGB(161,255,248) or RGB(46,220,208))
  end
  if row<10 then
   for _,side in ipairs({-1,1}) do
    box(b,"OutlinePixel"..row.."_"..side,side*u*1.73,1.28+row*u,0,u*.46,u,.22,tealDark)
   end
  end
 end
 for _,side in ipairs({-1,1}) do
  box(b,"TipStep"..side,side*u,3.73,0,u,u,.22,teal)
 end
 box(b,"TipDiamond",0,4.04,0,u,u,.22,RGB(148,255,248))
end

local function buster(b)
 grip(b,"LeatherGrip",.12,.94,leather,11)
 box(b,"Pommel",0,.035,0,.38,.18,.36,goldDark)
 box(b,"Guard",0,1.13,0,1.48,.17,.45,shadow)
 box(b,"GuardRail",0,1.23,-.24,1.33,.07,.07,silver)
 for _,x in ipairs({-.59,.59}) do
  box(b,"GuardCap"..x,x,1.13,0,.20,.27,.48,steel)
  ball(b,"GuardRivet"..x,x,1.13,-.26,.085,.085,.045,gold)
 end
 box(b,"BroadBladeCore",0,2.68,0,1.33,2.80,.23,steel)
 box(b,"BladeSpine",-.66,2.76,0,.12,2.96,.28,shadow)
 -- The broad right cutting edge is beveled on both faces, not a bright box.
 for _,front in ipairs({-1,1}) do
  quad(b,"SharpEdge"..front,V(.48,1.30,front*.12),V(.48,3.76,front*.12),V(.82,3.76,0),V(.82,1.30,0),silver,.021)
  quad(b,"AngularTipBevel"..front,V(.48,3.76,front*.12),V(.15,4.31,0),V(.82,3.76,0),V(.82,3.73,0),RGB(238,246,253),.025)
  b:triangle("BroadTipFace"..front,V(-.71,4.15,front*.12),V(.15,4.31,0),V(.48,3.76,front*.12),steel,.025,METAL)
  b:triangle("BroadTipFill"..front,V(-.71,3.75,front*.12),V(-.71,4.15,front*.12),V(.48,3.76,front*.12),steel,.025,METAL)
  line(b,"SpineEtching"..front,V(-.53,1.82,front*.135),V(-.53,3.76,front*.135),.025,RGB(98,118,138))
 end
 for i,y in ipairs({1.51,1.88}) do
  for _,front in ipairs({-1,1}) do
   local z=front*.16
   ring(b,"MateriaSocket"..i..front,-.29,y,z,.13,.034,shadow,12)
   ball(b,"MateriaRecess"..i..front,-.29,y,z,.20,.20,.038,RGB(17,25,34))
   ball(b,"MateriaCenter"..i..front,-.29,y,z+front*.028,.075,.075,.036,i==1 and RGB(74,177,134) or RGB(110,100,154))
  end
 end
 for i=0,5 do
  line(b,"BladeMachining"..i,V(.03,2.03+i*.27,-.13),V(.31,2.06+i*.27,-.13),.012,RGB(178,197,211))
 end
end

local function master(b)
 grip(b,"PurpleGrip",.10,.88,purple,9,RGB(72,152,139))
 box(b,"GoldPommel",0,.02,0,.35,.17,.34,gold)
 box(b,"PurpleGuard",0,1.08,0,1.17,.18,.32,purple)
 for _,side in ipairs({-1,1}) do
  for _,front in ipairs({-1,1}) do
   local z=front*.12
   b:triangle("WingMain"..side..front,V(side*.18,1.08,z),V(side*.92,1.31,z),V(side*.84,1.68,z),purple,.08,METAL)
   b:triangle("WingLower"..side..front,V(side*.18,1.08,z),V(side*.84,1.68,z),V(side*.52,1.14,z),RGB(119,76,205),.065,METAL)
  end
  line(b,"WingGoldEdge"..side,V(side*.19,1.09,-.19),V(side*.91,1.32,-.19),.044,gold)
  line(b,"WingGoldTip"..side,V(side*.91,1.32,-.19),V(side*.84,1.68,-.19),.044,gold)
  for i=1,3 do
   line(b,"WingFeather"..side..i,V(side*(.23+i*.13),1.18,-.19),V(side*(.43+i*.12),1.29+i*.06,-.19),.028,RGB(45,27,102))
  end
 end
 blade(b,"SacredBlade",1.26,3.77,.28,.54,RGB(195,211,222))
 box(b,"BladeFuller",0,2.67,-.106,.085,2.15,.015,RGB(135,164,184))
 for _,front in ipairs({-1,1}) do
  for i=1,3 do
   local x=i==1 and 0 or (i==2 and -.085 or .085)
   local y=i==1 and 1.82 or 1.66
   b:triangle("GoldenTriangle"..front..i,V(x-.082,y-.063,front*.13),V(x+.082,y-.063,front*.13),V(x,y+.089,front*.13),gold,.018,METAL)
  end
 end
 for i=1,3 do rune(b,"BladeRune"..i,0,2.06+i*.27,-.12,.17,RGB(171,194,209)) end
end

local function energy(b)
 box(b,"PlasmaHandle",0,.32,0,.37,.62,.32,shadow)
 box(b,"AlienGripPlate",0,.32,-.18,.29,.43,.055,steel)
 for i=1,6 do box(b,"GripRib"..i,0,.06+i*.08,-.213,.24,.027,.026,RGB(97,110,132)) end
 box(b,"HiltBridge",0,.71,0,1.10,.27,.42,RGB(58,66,92))
 for _,side in ipairs({-1,1}) do
  ball(b,"Emitter"..side,side*.45,.83,0,.42,.36,.40,steel)
  ring(b,"EmitterTrim"..side,side*.45,.83,-.22,.15,.026,cyan,12,NEON)
  local a=V(side*.40,.93,0)
  local c=V(side*.70,2.36,0)
  local d=V(side*.45,3.39,0)
  local e=V(side*.16,4.12,0)
  for _,front in ipairs({-1,1}) do
   local z=front*.04
   quad(b,"PlasmaLower"..side..front,a+V(0,0,z),c+V(0,0,z),V(side*.94,2.46,z),V(side*.62,.98,z),RGB(25,146,203),.055,NEON)
   b:triangle("PlasmaUpper"..side..front,c+V(0,0,z),V(side*.94,2.46,z),e+V(0,0,z),RGB(47,218,246),.065,NEON)
  end
  line(b,"PlasmaWhiteCoreLow"..side,a,c,.09,RGB(172,255,255),NEON,.11)
  line(b,"PlasmaWhiteCoreHigh"..side,c,d,.075,RGB(172,255,255),NEON,.10)
  line(b,"PlasmaTip"..side,d,e,.055,RGB(210,255,255),NEON,.08)
  for i=0,8 do
   local t=i/8
   local p=a:Lerp(c,t)
   line(b,"PlasmaArc"..side..i,p+V(0,.025,-.09),p+V(side*.18,.06,-.09),.017,RGB(182,255,255),NEON)
  end
 end
end

local function hammer(b)
 grip(b,"HammerLeather",.35,1.58,leather,13)
 box(b,"HandleFoot",0,.31,0,.34,.17,.34,steel)
 ring(b,"WristStrap",0,.03,0,.27,.057,leather,16,PLASTIC)
 box(b,"HammerHead",0,2.40,0,2.06,1.10,.85,steel)
 box(b,"TopInset",0,2.98,0,1.78,.07,.66,RGB(196,208,221))
 for _,side in ipairs({-1,1}) do
  box(b,"EndCap"..side,side*1.06,2.40,0,.14,.91,.69,shadow)
  box(b,"EndFace"..side,side*1.14,2.40,0,.025,.70,.50,silver)
 end
 for _,front in ipairs({-1,1}) do
  local z=front*.45
  line(b,"HeadTopRim"..front,V(-.91,2.92,front*.435),V(.91,2.92,front*.435),.045,silver)
  line(b,"HeadBottomRim"..front,V(-.91,1.89,front*.435),V(.91,1.89,front*.435),.045,RGB(114,135,151))
  for i=1,5 do rune(b,"AsgardRune"..front..i,(i-3)*.30,2.40,z,.39,shadow) end
  for i=0,7 do
   local x=-.83+i*.238
   line(b,"UpperKnot"..front..i,V(x,2.74,z),V(x+.115,2.83,z),.022,goldDark)
   line(b,"LowerKnot"..front..i,V(x,2.02,z),V(x+.115,2.10,z),.022,goldDark)
  end
 end
end

local function sting(b)
 grip(b,"ElvenGrip",.09,.69,RGB(52,73,64),8)
 ball(b,"ElvenPommel",0,.03,0,.32,.24,.26,silver)
 box(b,"GuardCenter",0,.88,0,.46,.16,.28,steel)
 for _,side in ipairs({-1,1}) do
  line(b,"ElvenGuardLow"..side,V(side*.11,.88,0),V(side*.46,.98,0),.105,silver,METAL,.17)
  line(b,"ElvenGuardLeaf"..side,V(side*.46,.98,0),V(side*.70,1.18,0),.083,silver,METAL,.13)
  for i=1,3 do line(b,"GuardLeafVein"..side..i,V(side*(.24+i*.10),.92+i*.055,-.10),V(side*(.31+i*.10),1.02+i*.055,-.10),.02,shadow) end
 end
 -- Leaf blade widens through the middle and narrows to a pointed tip.
 local points={{.16,1.00},{.23,1.49},{.33,2.18},{.26,2.91},{0,3.75}}
 for i=1,#points-1 do
  local p,c=points[i],points[i+1]
  for _,side in ipairs({-1,1}) do
   for _,front in ipairs({-1,1}) do
    quad(b,"LeafFacet"..i..side..front,V(0,p[2],front*.10),V(0,c[2],front*.10),V(side*c[1],c[2],0),V(side*p[1],p[2],0),
     side==front and RGB(193,218,230) or RGB(120,155,177),.022)
   end
  end
 end
 line(b,"BladeBlueFuller",V(0,1.34,-.12),V(0,3.16,-.12),.034,RGB(91,184,225),NEON)
 for i=1,6 do rune(b,"ElvenInscription"..i,.075,1.24+i*.23,-.118,.13,RGB(41,84,113)) end
end

local function pickaxe(b)
 -- Distinct Minecraft block silhouette with cyan front inlays.
 local u=.24
 for i=0,10 do
  local x=-.63+i*.10
  local y=.18+i*.24
  box(b,"WoodHandlePixel"..i,x,y,0,u,u,.26,RGB(91,57,30),PLASTIC)
  box(b,"HandlePixelGrain"..i,x-.033,y,-.145,.067,.18,.025,RGB(179,120,53),PLASTIC)
 end
 for col=-5,5 do
  local y=2.88-(math.abs(col)>3 and .24 or 0)
  box(b,"PickTopPixel"..col,col*u,y,0,u,u,.31,tealDark)
  box(b,"PickTopInset"..col,col*u,y,-.174,u*.73,u*.73,.03,cyan)
 end
 for _,side in ipairs({-1,1}) do
  for row=1,4 do
   local x=side*(1.20-(row-1)*.055)
   local y=2.64-row*u
   box(b,"PickPointPixel"..side..row,x,y,0,u,u,.31,teal)
   box(b,"PickPointFace"..side..row,x-.025,y+.025,-.17,u*.66,u*.66,.026,RGB(116,255,235))
   box(b,"PickPointOutline"..side..row,x+side*.14,y,0,.08,u,.29,tealDark)
  end
 end
 for i=-3,3 do box(b,"PickUnderside"..i,i*u,2.61,0,u,.10,.29,RGB(19,110,119)) end
end

local function diamondaxe(b)
 local u=.24
 for i=0,10 do
  box(b,"AxeHandlePixel"..i,-.26,.15+i*u,0,u,u,.25,RGB(97,61,32),PLASTIC)
  box(b,"AxeWoodGrain"..i,-.30,.15+i*u,-.14,.058,.18,.025,RGB(178,119,58),PLASTIC)
 end
 -- Block axe: broad outer cutting head and a narrow rear socket.
 local rows={{-2,2},{-3,2},{-3,1},{-3,0},{-2,0}}
 for row,bounds in ipairs(rows) do
  for col=bounds[1],bounds[2] do
   local x=col*u+.10
   local y=3.27-(row-1)*u
   local edge=col==bounds[1] or row==1 or row==#rows
   box(b,"AxeDiamondPixel"..row.."_"..col,x,y,0,u,u,.31,edge and tealDark or teal)
   box(b,"AxeDiamondFace"..row.."_"..col,x-.027,y+.025,-.174,u*.69,u*.68,.027,edge and RGB(44,202,202) or cyan)
  end
 end
 box(b,"AxeSocket",-.26,2.80,.03,.39,.51,.37,RGB(19,112,121))
 for _,front in ipairs({-1,1}) do ball(b,"AxeSocketStud"..front,-.26,2.80,front*.23,.10,.10,.05,silver) end
end

local function lightsaber(b)
 local turn=CFrame.Angles(0,0,math.pi*.5)
 b:cylinder("SaberHilt",V(.94,.32,.32),CF(0,.55,0)*turn,steel,METAL)
 b:cylinder("Pommel",V(.19,.43,.43),CF(0,.035,0)*turn,shadow,METAL)
 for i=0,7 do
  local y=.17+i*.095
  b:cylinder("GripBand"..i,V(.035,.365,.365),CF(0,y,0)*turn,shadow,METAL)
 end
 for _,side in ipairs({-1,1}) do
  box(b,"HiltGripRail"..side,side*.115,.49,-.125,.06,.55,.045,RGB(32,34,39),PLASTIC)
 end
 box(b,"ControlBox",0,.88,-.19,.26,.22,.12,shadow)
 box(b,"ControlInset",0,.88,-.261,.18,.14,.025,gold)
 for i=0,2 do ball(b,"ControlLight"..i,-.056+i*.056,.88,-.283,.026,.05,.018,i==2 and RGB(230,58,43) or RGB(74,202,137),NEON) end
 b:cylinder("EmitterNeck",V(.21,.26,.26),CF(0,1.10,0)*turn,shadow,METAL)
 b:cylinder("EmitterShroud",V(.29,.46,.46),CF(0,1.26,0)*turn,silver,METAL)
 for i=0,5 do
  local a=i*math.pi/3
  line(b,"EmitterSlit"..i,V(math.cos(a)*.234,1.16,math.sin(a)*.234),V(math.cos(a)*.234,1.32,math.sin(a)*.234),.025,shadow)
 end
 b:cylinder("EnergyBlade",V(2.70,.145,.145),CF(0,2.72,0)*turn,RGB(116,235,255),NEON)
 b:cylinder("BladeCore",V(2.70,.070,.070),CF(0,2.72,-.045)*turn,RGB(222,255,255),NEON)
 ball(b,"BladeTip",0,4.07,0,.145,.145,.145,RGB(116,235,255),NEON)
 ring(b,"EmitterHalo",0,1.39,-.04,.19,.024,cyan,16,NEON)
 for i=0,7 do
  local a=i*math.pi/4
  line(b,"PommelDetail"..i,V(math.cos(a)*.216,-.025,math.sin(a)*.216),V(math.cos(a)*.216,.07,math.sin(a)*.216),.023,silver)
 end
end

local function keyblade(b)
 box(b,"KeyGrip",0,.52,0,.23,.69,.27,RGB(30,31,39),PLASTIC)
 for i=0,6 do box(b,"KeyGripBand"..i,0,.24+i*.09,-.149,.22,.028,.021,RGB(119,106,84),PLASTIC) end
 -- Rectangular gold loop guard remains visibly open around the grip.
 line(b,"GuardLeft",V(-.48,.06,0),V(-.48,1.05,0),.15,gold,.22)
 line(b,"GuardRight",V(.48,.06,0),V(.48,1.05,0),.15,gold,.22)
 line(b,"GuardBottom",V(-.48,.06,0),V(.48,.06,0),.15,gold,.22)
 line(b,"GuardTop",V(-.48,1.05,0),V(.48,1.05,0),.15,gold,.22)
 for _,x in ipairs({-.48,.48}) do
  for _,y in ipairs({.06,1.05}) do ball(b,"GuardCorner"..x..y,x,y,0,.22,.22,.22,gold) end
 end
 box(b,"BladeCollar",0,1.16,0,.39,.18,.31,RGB(27,133,194))
 box(b,"KeyShaft",0,2.61,0,.29,2.74,.23,silver)
 box(b,"KeyShaftInset",-.072,2.63,-.126,.06,2.54,.019,RGB(135,172,194))
 box(b,"KeyToothRoot",.32,3.83,0,.77,.24,.25,silver)
 for i=0,2 do
  box(b,"KeyTooth"..i,.22+i*.25,3.62,0,.16,.43,.25,silver)
  box(b,"KeyToothBevel"..i,.22+i*.25,3.62,-.135,.09,.32,.022,RGB(179,207,221))
 end
 box(b,"KeyEndCap",0,4.02,0,.35,.14,.29,steel)
 for i=1,4 do
  local x=-.09-i*.13
  local y=.01-i*.12
  ring(b,"KeyChain"..i,x,y,i%2*.03,.095,.035,silver,10)
 end
 -- A three-circle charm gives the familiar silhouette without any texture.
 ball(b,"CharmCenter",-.73,-.70,0,.33,.33,.12,silver)
 ball(b,"CharmEarLeft",-.91,-.49,0,.22,.22,.12,silver)
 ball(b,"CharmEarRight",-.57,-.48,0,.22,.22,.12,silver)
end

local function gunblade(b)
 -- A sword with a complete revolver action, not a sword with a gun painted on.
 local gripAngle=CFrame.Angles(0,0,-.23)
 box(b,"PistolGrip",-.31,.49,0,.36,.86,.32,RGB(27,29,36),PLASTIC,gripAngle)
 for i=0,7 do
  local y=.16+i*.092
  local x=-.31+(y-.49)*.23
  line(b,"PistolGripCheckering"..i,V(x-.12,y-.025,-.18),V(x+.12,y+.025,-.18),.023,RGB(97,99,107),METAL)
 end
 box(b,"GripHeel",-.40,.07,0,.39,.13,.36,steel,METAL,gripAngle)
 box(b,"RevolverFrame",-.06,1.14,0,.66,.32,.36,steel)
 box(b,"RearAction",-.39,1.44,0,.24,.52,.32,shadow)
 line(b,"CockHammer",V(-.39,1.65,0),V(-.61,1.87,0),.115,steel,METAL,.16)
 box(b,"HammerThumb",-.64,1.91,0,.21,.08,.18,shadow)
 box(b,"TriggerBridge",.35,1.20,0,.60,.14,.26,steel)
 -- The open guard leaves an obvious space for the trigger.
 ring(b,"TriggerGuard",.34,.92,0,.28,.055,silver,16)
 line(b,"Trigger",V(.23,1.13,0),V(.31,.90,0),.055,shadow,METAL,.10)
 box(b,"SwordReceiver",.08,1.80,0,.66,.55,.32,steel)
 box(b,"ReceiverSpine",-.28,1.93,0,.16,.77,.38,shadow)
 blade(b,"GunbladeEdge",2.00,3.95,.42,.53,RGB(181,197,208))
 for _,front in ipairs({-1,1}) do
  box(b,"BladeFuller"..front,-.16,2.87,front*.109,.047,1.66,.021,RGB(98,118,137))
  line(b,"ReceiverEngraving"..front,V(-.18,1.89,front*.18),V(.18,1.89,front*.18),.025,shadow)
  ball(b,"ReceiverScrew"..front,.19,1.72,front*.19,.078,.078,.04,goldDark)
 end
 -- Cylinder axis is local Z so six chamber mouths are visible on both sides.
 b:cylinder("RevolverCylinder",V(.47,.76,.76),CF(-.03,1.47,0)*CFrame.Angles(0,math.pi*.5,0),RGB(123,138,155),METAL)
 for _,front in ipairs({-1,1}) do
  local z=front*.25
  ring(b,"CylinderRim"..front,-.03,1.47,z,.37,.026,silver,14)
  ball(b,"CylinderAxle"..front,-.03,1.47,z+front*.017,.125,.125,.07,shadow)
  ball(b,"CylinderAxleScrew"..front,-.03,1.47,z+front*.061,.062,.062,.02,silver)
  for i=0,5 do
   local a=i*math.pi/3
   local x=-.03+math.cos(a)*.24
   local y=1.47+math.sin(a)*.24
   ball(b,"ChamberMouth"..front..i,x,y,z+front*.012,.117,.117,.032,RGB(22,26,33))
   if front==-1 then
    ring(b,"ChamberLip"..front..i,x,y,z+front*.029,.063,.015,silver,6)
   end
  end
 end
 -- Small geometric lion crest and a pendant distinguish the original design.
 ball(b,"LionMedallion",-.30,.45,-.196,.22,.26,.032,steel)
 for _,side in ipairs({-1,1}) do
  b:triangle("LionEar"..side,V(-.30+side*.11,.54,-.218),V(-.30+side*.08,.64,-.218),V(-.30+side*.035,.54,-.218),silver,.018,METAL)
  ball(b,"LionEye"..side,-.30+side*.047,.46,-.225,.025,.025,.022,shadow)
 end
 line(b,"LionNose",V(-.30,.45,-.225),V(-.30,.40,-.225),.03,shadow)
 ring(b,"GripLanyard",-.42,-.09,0,.10,.025,silver,10)
end

local builders={pixel=pixel,buster=buster,master=master,energy=energy,hammer=hammer,
 sting=sting,pickaxe=pickaxe,diamondaxe=diamondaxe,lightsaber=lightsaber,keyblade=keyblade,gunblade=gunblade}
function M.build(b,key)
 local builder=builders[key]
 if not builder then return false end
 builder(b)
 return true
end
M.Keys={"pixel","buster","master","energy","hammer","sting","pickaxe","diamondaxe","lightsaber","keyblade","gunblade"}
return M

