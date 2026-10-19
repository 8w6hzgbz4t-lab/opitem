-- Transformers' Matrix of Leadership, sculpted from native Roblox geometry.
-- The two silver finger handles are actual open loops; no dark inset fakes them.
local M={}
local V,C,A,RGB=Vector3.new,CFrame.new,CFrame.Angles,Color3.fromRGB
local METAL,NEON=Enum.Material.Metal,Enum.Material.Neon
local TAU=math.pi*2

function M.build(b,key)
 if key~="transformers_matrix" then return false end
 local silver,bright,steel=RGB(162,179,190),RGB(221,232,236),RGB(74,92,106)
 local gold,bronze,warm=RGB(222,151,50),RGB(123,77,35),RGB(248,190,80)
 local blue,cyan,darkBlue=RGB(31,124,222),RGB(99,226,255),RGB(20,73,145)
 local cy=1.82
 local frontCylinder=A(0,math.pi/2,0)
 -- Orange-bronze housing with separate silver rear casting and a raised lip.
 -- Discs occupy only the central chassis and never close either finger handle.
 b:cylinder("SilverRearHousing",V(.28,2.09,2.09),C(0,cy,.17)*frontCylinder,steel,METAL)
 b:cylinder("BronzeCircularChassis",V(.38,1.96,1.96),C(0,cy,-.08)*frontCylinder,bronze,METAL)
 b:ring("BackSilverCastingLip",C(0,cy,.34),1.0,.13,silver,16,METAL)
 b:ring("GoldenOuterEnergyRing",C(0,cy,-.32),.94,.17,gold,16,METAL)
 b:ring("InnerDarkSocket",C(0,cy,-.415),.778,.075,bronze,16,METAL)
 -- Two eight-sided, cast-metal hand grips. The empty middle stays see-through
 -- from both sides; thin bright edges articulate the bevel on their front face.
 local loop={{.94,2.14},{1.37,2.64},{2.08,2.56},{2.48,2.14},
             {2.39,1.35},{1.97,1.00},{1.35,1.10},{.94,1.48}}
 for _,s in ipairs({-1,1}) do
  local prefix=s<0 and "Left" or "Right"
  for i,p in ipairs(loop) do
   local q=loop[i%#loop+1]
   b:line(prefix.."OpenHandleCast_"..i,V(s*p[1],p[2],.04),V(s*q[1],q[2],.04),.255,.39,silver,METAL)
   b:line(prefix.."HandleFrontBevel_"..i,V(s*p[1],p[2],-.166),V(s*q[1],q[2],-.166),.068,.046,bright,METAL)
  end
  -- Grip ribs sit on the outside edge rather than filling the finger void.
  for j=0,3 do
   local t=.22+j*.16
   local x=2.48+(2.39-2.48)*t
   local y=2.14+(1.35-2.14)*t
   b:box(prefix.."GripRidge_"..j,V(.30,.065,.46),C(s*x,y,.04)*A(0,0,s*.114),steel,METAL)
  end
  b:box(prefix.."UpperHandleShoulder",V(.45,.19,.49),C(s*1.26,2.39,.05)*A(0,0,s*.68),silver,METAL)
  b:box(prefix.."LowerHandleShoulder",V(.40,.18,.48),C(s*1.19,1.31,.05)*A(0,0,-s*.51),silver,METAL)
  for _,y in ipairs({2.40,1.27}) do
   b:cylinder(prefix.."HandleShoulderBolt_"..y,V(.055,.14,.14),C(s*1.24,y,-.227)*frontCylinder,bronze,METAL)
   b:box(prefix.."HandleBoltSlot_"..y,V(.068,.018,.012),C(s*1.24,y,-.260),steel,METAL)
  end
 end
 -- Chassis ribs, screw heads and fine radial gold highlights surround the orb.
 for i=0,11 do
  local angle=i*TAU/12
  local sin,cos=math.sin(angle),math.cos(angle)
  b:box("ChassisRadialRib_"..i,V(.19,.22,.35),C(sin*.97,cy+cos*.97,-.045)*A(0,0,-angle),gold,METAL)
  b:box("RadialBrightEdge_"..i,V(.055,.17,.035),C(sin*.99,cy+cos*.99,-.247)*A(0,0,-angle),warm,METAL)
 end
 for i=0,7 do
  local angle=(i+.5)*TAU/8
  local x,y=math.sin(angle)*.94,cy+math.cos(angle)*.94
  b:cylinder("SocketFastener_"..i,V(.055,.10,.10),C(x,y,-.436)*frontCylinder,silver,METAL)
  b:box("SocketFastenerSlot_"..i,V(.052,.012,.012),C(x,y,-.469)*A(0,0,-angle),steel,METAL)
 end
 -- A true, closed, faceted blue crystal lens. Eight crown facets lead into
 -- sixteen shoulder facets, so the blue core has a sculpted mineral silhouette.
 local facetColors={RGB(79,204,250),RGB(48,159,237),RGB(28,116,208),RGB(31,139,224),
                    RGB(55,188,241),RGB(101,224,251),RGB(57,169,239),RGB(39,145,223)}
 b:ball("BlueEnergyCore",V(1.37,1.37,.66),C(0,cy,-.385),blue,NEON)
 for i=0,7 do
  local a=i*TAU/8;local nextAngle=(i+1)*TAU/8
  local outerA=V(math.cos(a)*.72,cy+math.sin(a)*.72,-.493)
  local outerB=V(math.cos(nextAngle)*.72,cy+math.sin(nextAngle)*.72,-.493)
  local innerA=V(math.cos(a)*.35,cy+math.sin(a)*.35,-.785)
  local innerB=V(math.cos(nextAngle)*.35,cy+math.sin(nextAngle)*.35,-.785)
  b:triangle("CrystalShoulderA_"..i,outerA,outerB,innerB,facetColors[i+1],.018,METAL)
  b:triangle("CrystalShoulderB_"..i,outerA,innerB,innerA,facetColors[i+1],.018,METAL)
  b:triangle("CrystalCrown_"..i,innerA,innerB,V(0,cy,-.884),facetColors[(i+2)%8+1],.018,NEON)
 end
 -- A restrained luminous glint preserves the jewel silhouette instead of
 -- surrounding this compact relic in spikes or unrelated floating effects.
 b:line("CrystalLongGlint",V(-.27,cy+.43,-.738),V(-.12,cy+.17,-.846),.035,.018,cyan,NEON)
 b:line("CrystalShortGlint",V(-.22,cy+.33,-.791),V(-.08,cy+.34,-.825),.025,.018,RGB(200,250,255),NEON)
 -- The silver chevron crown, sternum and pointed crest are mechanical relief,
 -- with physical layered plates rather than an uploaded emblem decal.
 for _,s in ipairs({-1,1}) do
  b:line("CrownWing_"..s,V(s*.18,2.80,-.23),V(s*.70,3.10,-.08),.16,.30,silver,METAL)
  b:line("CrownWingBevel_"..s,V(s*.21,2.85,-.398),V(s*.67,3.105,-.235),.045,.035,bright,METAL)
  b:line("LowerSilverJaw_"..s,V(s*.18,.72,-.22),V(s*.59,.87,-.15),.15,.29,silver,METAL)
  b:triangle("CrestCheek_"..s,V(s*.12,2.88,-.455),V(s*.32,3.08,-.455),V(s*.28,2.82,-.455),silver,.06,METAL)
 end
 b:box("CrownCentralKeystone",V(.22,.32,.31),C(0,2.94,-.22),silver,METAL)
 b:triangle("CrownKeystoneTip",V(-.11,3.10,-.39),V(.11,3.10,-.39),V(0,3.26,-.39),bright,.08,METAL)
 b:box("LowerCastHeel",V(.37,.16,.40),C(0,.71,.02),steel,METAL)
 b:box("HeelGoldPlate",V(.21,.075,.04),C(0,.70,-.205),gold,METAL)
 b.model.Name="Transformers Matrix of Leadership"
 b.model:SetAttribute("ArtVersion",72)
 b.model:SetAttribute("Kind","transformers_matrix")
 b.model:SetAttribute("OpenFingerHandles",true)
 b.model:SetAttribute("NativeFacetedEnergyCrystal",true)
 return true
end

return M
