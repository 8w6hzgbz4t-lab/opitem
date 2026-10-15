-- Native, anchored scenery. These sculptures never add NPCs, race controls or collision.
local P=require(script.Parent.Primitives)
local E={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local NEON,METAL,SMOOTH=Enum.Material.Neon,Enum.Material.Metal,Enum.Material.SmoothPlastic
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local red,scarlet,gold=rgb(174,17,43),rgb(251,48,77),rgb(225,178,67)
local dark,white,cyan=rgb(17,23,37),rgb(227,226,218),rgb(85,225,255)

local function deck(b,name,a,c,width,height,color,material)
 local delta=c-a
 return b:box(name,V(width,height,delta.Magnitude+.08),CFrame.lookAt((a+c)*.5,c),color,material)
end

function E.racetrack(parent)
 local b=P.new(parent,{model="DuelCircuit",name="FiveDsDuelCircuit",alignBase=false,partBudget=300})
 local points={}
 local corners={{127,95,0},{-127,95,math.pi/2},{-127,-95,math.pi},{127,-95,math.pi*1.5}}
 for _,corner in ipairs(corners) do
  for step=0,8 do
   local angle=corner[3]+step/8*math.pi*.5
   points[#points+1]=V(corner[1]+math.cos(angle)*24,32.22,corner[2]+math.sin(angle)*24)
  end
 end
 for i,a in ipairs(points) do
  local c=points[i%#points+1]
  deck(b,"CircuitAsphalt_"..i,a,c,16,.4,dark,METAL)
  local right=(c-a).Unit:Cross(V(0,1,0))
  for _,side in ipairs({-1,1}) do
   local curb=right*(side*7.25)+V(0,.26,0)
   deck(b,"CircuitCurb_"..i.."_"..side,a+curb,c+curb,1.1,.25,i%2==0 and red or white,SMOOTH)
   local rail=right*(side*8.05)+V(0,1.2,0)
   deck(b,"CircuitEnergyRail_"..i.."_"..side,a+rail,c+rail,.18,.32,cyan,NEON)
  end
 end
 -- Angular double chevrons evoke a futuristic duel-runner circuit.
 for _,z in ipairs({-119,119}) do
  for _,x in ipairs({-80,-30,30,80}) do
   local sign=z<0 and 1 or -1
   for tip=0,1 do
    local p=V(x+tip*3,32.46,z)
    b:line("CircuitChevronL_"..x.."_"..z.."_"..tip,p+V(-sign*2.3,0,-2),p,.22,.12,gold,NEON)
    b:line("CircuitChevronR_"..x.."_"..z.."_"..tip,p+V(-sign*2.3,0,2),p,.22,.12,gold,NEON)
   end
  end
 end
 -- The elevated ring stays visible above the perimeter wall. A few pylons support the silhouette.
 local supports={V(-151,0,-57),V(-151,0,57),V(151,0,-57),V(151,0,57),V(-80,0,-119),V(80,0,-119),V(-80,0,119),V(80,0,119)}
 for i,p in ipairs(supports) do
  b:box("CircuitSupportColumn_"..i,V(2.8,31.6,2.8),C(p+V(0,16,0)),dark,METAL)
  b:box("CircuitSupportBeacon_"..i,V(.22,24,.22),C(p+V(-1.5,17,0)),cyan,NEON)
 end
 -- This road lies below the existing belt; original item positions and collision stay authoritative.
 b:box("PortalRoadDeck",V(302,.22,12),C(0,.25,0),dark,METAL)
 for _,side in ipairs({-1,1}) do
  b:box("PortalRoadEnergyStrip_"..side,V(302,.1,.18),C(0,.42,side*5.6),cyan,NEON)
  b:box("PortalRoadShoulder_"..side,V(302,.12,.65),C(0,.34,side*6.2),red,METAL)
  for i=0,14 do
   b:box("PortalRoadDashedGold_"..side.."_"..i,V(7,.06,.18),C(-144+i*20,.43,side*4.8),gold,NEON)
  end
 end
 -- The ornamental climbing spur joins the low portal road to the visible high circuit east of the wall.
 local spurStart,spurEnd=V(125,.25,0),V(151,32.22,0)
 deck(b,"PortalClimbingSpur",spurStart,spurEnd,12,.35,dark,METAL)
 for _,side in ipairs({-1,1}) do
  local offset=V(0,.25,side*5.6)
  deck(b,"SpurEnergyStrip_"..side,spurStart+offset,spurEnd+offset,.24,.16,cyan,NEON)
  local shoulder=V(0,.16,side*6.2)
  deck(b,"SpurRedShoulder_"..side,spurStart+shoulder,spurEnd+shoulder,.6,.22,red,METAL)
 end
 -- Four trackside pylons frame the portal spur without closing the item opening.
 for _,x in ipairs({134,144}) do
  for _,z in ipairs({-9,9}) do
   b:box("DuelPylon_"..x.."_"..z,V(1.4,5,1.4),C(x,2.5,z),dark,METAL)
   b:box("DuelPylonLight_"..x.."_"..z,V(.22,3,.24),C(x-.75,3,z),scarlet,NEON)
   b:ball("DuelPylonCap_"..x.."_"..z,1,C(x,5.2,z),gold,METAL)
  end
 end
 local model=b:finish()
 model:SetAttribute("DecorativeOnly",true)
 model:SetAttribute("ConveyorGeometryUnchanged",true)
 return model
end

local function samplePath(points,count)
 local samples={}
 for i=0,count do
  local u=i/count*(#points-1)
  local segment=math.min(#points-1,math.floor(u)+1)
  local t=u-(segment-1)
  local p0,p1,p2,p3=points[math.max(1,segment-1)],points[segment],points[segment+1],points[math.min(#points,segment+2)]
  samples[#samples+1]=(p1*2+(p2-p0)*t+(p0*2-p1*5+p2*4-p3)*t*t+(-p0+p1*3-p2*3+p3)*t*t*t)*.5
 end
 return samples
end

local function serpentineBody(b,points,color,belly,spine,crimson)
 local path=samplePath(points,44)
 for i=1,#path-1 do
  local a,c=path[i],path[i+1]
  local t=i/(#path-1)
  local diameter=(1.3+math.sin(t*math.pi*.65)*3.3)
  local cf=CFrame.lookAt((a+c)*.5,c)
  b:ball("CoiledScaleSegment_"..i,V(diameter,diameter,(c-a).Magnitude+diameter*.55),cf,color,SMOOTH)
  b:ball("SegmentBelly_"..i,V(diameter*.74,diameter*.84,(c-a).Magnitude+diameter*.38),cf+V(0,0,-diameter*.37),belly,SMOOTH)
  if i%2==0 then
   local p=(a+c)*.5
   b:triangle("DorsalSpine_"..i,p+V(-.7,diameter*.4,.6),p+V(.2,diameter*(crimson and 1.35 or .95),.8),p+V(.9,diameter*.38,.6),spine,.3,METAL)
  end
  if i%3==0 then
   local p=(a+c)*.5
   b:line("ScaleHighlight_"..i,p+V(-diameter*.32,diameter*.27,-diameter*.55),p+V(diameter*.32,diameter*.27,-diameter*.55),.12,.12,crimson and scarlet or gold,crimson and NEON or METAL)
  end
 end
 return path[#path]
end

local function dragonHead(b,head,color,belly,crimson)
 local face=C(head)
 local function ball(name,size,offset,tint,material) return b:ball(name,size,face*C(offset),tint,material or SMOOTH) end
 local function box(name,size,offset,tint,material) return b:box(name,size,face*C(offset),tint,material or SMOOTH) end
 ball("DragonSkull",V(7.7,6.5,8),V(0,1,-1),color)
 ball("LongDragonMuzzle",V(5.7,3.4,8),V(0,-.2,-6),color)
 box("OpenMouthShadow",V(5.2,1.05,7.2),V(0,-1.1,-6.3),rgb(30,9,16))
 ball("LowerDragonJaw",V(5.5,1.2,7.2),V(0,-2,-5.8),belly)
 for _,side in ipairs({-1,1}) do
  ball("EyeSocket_"..side,V(1.4,1.9,2.5),V(side*3.25,1.7,-3.3),rgb(29,17,23))
  ball("DragonEye_"..side,V(.5,1.1,1.8),V(side*3.87,1.9,-3.55),crimson and rgb(255,230,102) or rgb(255,61,55),NEON)
  b:line("HeavyBrow_"..side,face*V(side*2.1,3,-5),face*V(side*4,2.8,-2.5),.75,.75,color,METAL)
  ball("Nostril_"..side,V(.7,.45,1.1),V(side*1.5,.7,-9.5),rgb(27,15,19))
  for tooth=1,3 do
   b:wedge("Fang_"..side.."_"..tooth,V(.55,1.15,.7),face*C(side*2.4,-1,-8.4+tooth*1.5)*A(0,side*math.pi*.5,math.pi),white,SMOOTH)
  end
  local hornColor=crimson and rgb(223,153,155) or rgb(151,106,61)
  local h0,h1,h2=face*V(side*2.6,3,.8),face*V(side*4.2,7,2),face*V(side*5.2,11,3.2)
  b:line("AntlerRoot_"..side,h0,h1,1.1,1.1,hornColor,METAL)
  b:line("AntlerTip_"..side,h1,h2,.65,.65,hornColor,METAL)
  b:triangle("PointedAntler_"..side,h2+V(-.4,0,0),h2+V(.4,0,0),h2+V(side*.5,2,1),hornColor,.6,METAL)
  if not crimson then
   b:line("AntlerBranch_"..side,h1,face*V(side*7,8,.1),.55,.55,hornColor,METAL)
   b:line("AntlerFork_"..side,face*V(side*6,7.7,.6),face*V(side*7.4,10,1.3),.35,.35,hornColor,METAL)
   local w0,w1,w2=face*V(side*2.6,-.2,-8.6),face*V(side*8,-1.2,-9.6),face*V(side*14,2,-9.3)
   b:line("WhiskerInner_"..side,w0,w1,.22,.22,gold,METAL)
   b:line("WhiskerOuter_"..side,w1,w2,.13,.13,gold,METAL)
  end
  b:triangle("FlaredCheek_"..side,face*V(side*2.7,.2,0),face*V(side*7,4.3,1),face*V(side*3.6,4.6,2.4),color,.6,METAL)
 end
 b:triangle("ForeheadCrest",face*V(-1,3.5,-.2),face*V(0,8,-.6),face*V(1,3.5,-.2),crimson and scarlet or gold,.6,METAL)
 if not crimson then
  ball("DragonBeard",V(3.8,2.2,2.4),V(0,-3,-5.5),white)
  for strand=-1,1 do
   b:line("BeardStrand_"..strand,face*V(strand*1,-3.4,-5),face*V(strand*1.5,-7,-3.5),.5,.5,white,SMOOTH)
  end
 end
end

local function limbs(b,anchor,color,claw,label)
 for _,side in ipairs({-1,1}) do
  local shoulder=anchor+V(side*1.5,0,0)
  local elbow=anchor+V(side*7,-5,-1)
  local wrist=anchor+V(side*10,-3,-5)
  b:line(label.."UpperArm_"..side,shoulder,elbow,1.8,1.8,color,SMOOTH)
  b:ball(label.."Elbow_"..side,2.1,C(elbow),color,SMOOTH)
  b:line(label.."Forearm_"..side,elbow,wrist,1.3,1.3,color,SMOOTH)
  b:ball(label.."Palm_"..side,V(3.6,1.3,2.2),C(wrist),color,SMOOTH)
  for finger=-1,1 do
   local a=wrist+V(finger*1.15,0,-.5)
   local c=a+V(finger*.4,-.7,-2)
   b:line(label.."Finger_"..side.."_"..finger,a,c,.45,.45,color,SMOOTH)
   b:triangle(label.."Claw_"..side.."_"..finger,c+V(-.27,0,0),c+V(.27,0,0),c+V(0,-.8,-1.3),claw,.25,METAL)
  end
 end
end

function E.crimsonDragon(parent,cf)
 local b=P.new(parent,{model="CrimsonDragon",name="CrimsonDragonMonument",alignBase=false,cframe=cf,partBudget=400})
 local points={V(27,-25,4),V(14,-17,5),V(-8,-18,1),V(-24,-6,2),V(-23,16,4),V(-7,27,3),V(12,19,1),V(14,3,2),V(1,1,2),V(-6,15,3),V(0,29,0)}
 local head=serpentineBody(b,points,red,rgb(255,126,133),scarlet,true)
 -- Broad jagged membranes make the crimson sculpture distinct from Shenron's long body.
 for _,side in ipairs({-1,1}) do
  local shoulder=V(side*4,23,3)
  local elbow=V(side*23,43,5)
  local tips={V(side*47,40,5),V(side*44,27,4),V(side*40,14,3),V(side*29,6,2)}
  b:line("WingUpperBone_"..side,shoulder,elbow,1.2,1.2,scarlet,METAL)
  for i,tip in ipairs(tips) do
   b:line("WingFinger_"..side.."_"..i,elbow,tip,.65,.65,scarlet,METAL)
   local nextTip=tips[i+1] or shoulder
   local membrane=b.count
   b:triangle("ScarletWingMembrane_"..side.."_"..i,elbow,tip,nextTip,i%2==0 and rgb(174,22,65) or rgb(222,37,76),.25,NEON)
   assert(b.count>membrane,"Missing dragon wing")
  end
 end
 limbs(b,V(0,22,0),red,white,"Fore")
 limbs(b,V(-18,-1,1),red,white,"Hind")
 dragonHead(b,head,red,rgb(250,140,148),true)
 local model=b:finish();model:SetAttribute("DecorativeOnly",true);return model
end

function E.shenron(parent,cf)
 local b=P.new(parent,{model="Shenron",name="ShenronDragonMonument",alignBase=false,cframe=cf,partBudget=400})
 local green,belly=rgb(37,130,64),rgb(220,199,129)
 local points={}
 for i=0,13 do
  local t=i/13;local angle=-math.pi*.7+t*math.pi*3.1;local radius=26-t*11
  points[#points+1]=V(math.cos(angle)*radius,math.sin(angle)*radius+t*13,math.sin(angle*1.8)*4)
 end
 local head=serpentineBody(b,points,green,belly,rgb(45,75,43),false)
 limbs(b,points[7],green,white,"Hind")
 limbs(b,head+V(0,-7,2),green,white,"Fore")
 dragonHead(b,head,green,belly,false)
 local model=b:finish();model:SetAttribute("DecorativeOnly",true);return model
end

function E.mirrorForcePlanet(parent,cf)
 local b=P.new(parent,{model="MirrorForcePlanet",name="MirrorForceReflectionPlanet",alignBase=false,cframe=cf,partBudget=220})
 local blue,ice,violet=rgb(33,72,166),rgb(158,238,255),rgb(73,111,193)
 -- Flat face-on composition: luminous blue planet, reflected light and angular shards.
 b:cylinder("DeepBluePlanetDisc",V(.3,48,48),C()*A(0,math.pi*.5,0),blue,NEON)
 b:cylinder("ReflectivePlanetFace",V(.18,42,42),C(0,1,-.22)*A(0,math.pi*.5,0),violet,NEON)
 for i=1,5 do
  local radius=5+i*3.2
  local arcSegments=13
  for step=0,arcSegments-1 do
   local a=-math.pi*.08+step/arcSegments*math.pi*1.3
   local c=-math.pi*.08+(step+1)/arcSegments*math.pi*1.3
   b:line("ReflectedShieldArc_"..i.."_"..step,V(math.cos(a)*radius,math.sin(a)*radius,-2.6-i*.025),V(math.cos(c)*radius,math.sin(c)*radius,-2.6-i*.025),.19+i*.025,.15,i%2==0 and ice or rgb(94,168,255),NEON)
  end
 end
 local burst=V(-7,-6,-3)
 for i=0,17 do
  local angle=i/18*math.pi*2
  local ray=V(math.cos(angle),math.sin(angle),0)
  local start=burst+ray*(i%3==0 and 3 or 7)
  local finish=burst+ray*(i%3==0 and 31 or 22)
  b:line("MirrorReboundRay_"..i,start,finish,i%3==0 and .6 or .23,.14,ice,NEON)
  if i%2==0 then
   local perpendicular=V(-ray.Y,ray.X,0)
   local center=burst+ray*(17+i%4)
   b:triangle("FloatingMirrorShard_"..i,center+ray*5,center-ray*3+perpendicular*1.7,center-ray*1.2-perpendicular*2.6,i%4==0 and white or rgb(110,202,255),.14,NEON)
  end
 end
 b:ring("MirrorForceOuterHalo",C(0,0,-.75),26,.22,ice,32,NEON)
 b:ball("ReflectionBurstCore",V(6,6,.8),C(burst),white,NEON)
 b:line("ReflectionHorizontalFlare",burst-V(13,0,0),burst+V(13,0,0),.6,.18,white,NEON)
 b:line("ReflectionVerticalFlare",burst-V(0,13,0),burst+V(0,13,0),.6,.18,white,NEON)
 local model=b:finish();model:SetAttribute("DecorativeOnly",true);model:SetAttribute("FlatBackdrop",true);return model
end
return E
