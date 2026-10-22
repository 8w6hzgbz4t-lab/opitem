-- Optimus Prime's orange Energon axe, built entirely from native Roblox parts.
-- The crescent has two tapered, sloping faces and a genuinely thin cutting edge.
local M={}
local V,C,A,RGB=Vector3.new,CFrame.new,CFrame.Angles,Color3.fromRGB
local METAL,NEON=Enum.Material.Metal,Enum.Material.Neon
local function point(theta,width,z)
 return V(-.55+width*math.cos(theta),4.95+1.75*math.sin(theta),z)
end

function M.build(b,key)
 if key~="optimus_energon_axe" then return false end
 local blue,blueLight,red=RGB(25,56,119),RGB(48,95,171),RGB(172,33,34)
 local dark,silver,steel=RGB(32,38,47),RGB(190,207,219),RGB(90,107,121)
 local orange,amber,edge=RGB(255,106,12),RGB(255,146,30),RGB(255,220,110)
 local vertical=A(0,0,math.pi/2)
 -- The handle is a compact red/blue mechanical forearm emitter, not a wooden axe.
 b:cylinder("SteelGripCore",V(3.25,.34,.34),C(-.85,1.99,0)*vertical,steel,METAL)
 b:cylinder("BlueGripSleeve",V(2.12,.48,.48),C(-.85,1.75,0)*vertical,blue,METAL)
 for i=0,7 do
  b:cylinder("RecessedGripBand"..i,V(.070,.505,.505),C(-.85,.83+i*.25,0)*vertical,dark,METAL)
 end
 b:cylinder("BevelledPommel",V(.23,.66,.66),C(-.85,.48,0)*vertical,silver,METAL)
 b:cylinder("PommelBlueInset",V(.075,.48,.48),C(-.85,.329,0)*vertical,blueLight,METAL)
 b:box("FrontGripEnergyStripe",V(.080,1.84,.035),C(-.85,1.78,-.264),amber,NEON)
 b:box("RearGripEnergyStripe",V(.080,1.84,.035),C(-.85,1.78,.264),amber,NEON)
 b:cylinder("LowerEmitterCollar",V(.25,.76,.76),C(-.85,3.00,0)*vertical,silver,METAL)
 b:box("RedForearmEmitter",V(.78,1.35,.70),C(-.85,3.70,0),red,METAL)
 for _,s in ipairs({-1,1}) do
  b:wedge("BlueEmitterShoulder"..s,V(.19,.97,.76),C(-.85+s*.48,3.83,0),blue,METAL)
  b:box("SilverArmourRail"..s,V(.10,1.02,.10),C(-.85+s*.32,3.70,-.40),silver,METAL)
  b:box("RearArmourRail"..s,V(.10,1.02,.10),C(-.85+s*.32,3.70,.40),silver,METAL)
  for j=0,3 do
   b:box("EmitterCoolingVent"..s.."_"..j,V(.28,.055,.025),C(-.85+s*.20,3.37+j*.18,-.365)*A(0,0,s*.20),dark,METAL)
  end
 end
 b:box("UpperBluePowerBlock",V(.89,.50,.82),C(-.85,4.46,0),blue,METAL)
 b:box("SilverBridgeCasing",V(1.34,.43,.67),C(-.34,4.91,0),silver,METAL)
 b:box("BridgeDarkRecess",V(1.18,.24,.71),C(-.25,4.91,0),dark,METAL)
 b:box("OrangeEmitterBeam",V(1.17,.14,.74),C(-.20,4.91,0),orange,NEON)
 -- Layered round energy hub and recessed bolts on both sides of the emitter.
 local hub=C(-.85,4.91,0)*A(0,math.pi/2,0)
 b:cylinder("CircularArmourHub",V(.85,1.10,1.10),hub,blue,METAL)
 for _,s in ipairs({-1,1}) do
  local z=s*.46
  b:cylinder("SilverHubRim"..s,V(.09,.90,.90),C(-.85,4.91,z)*A(0,math.pi/2,0),silver,METAL)
  b:cylinder("InsetRedHub"..s,V(.10,.70,.70),C(-.85,4.91,z+s*.06)*A(0,math.pi/2,0),red,METAL)
  b:cylinder("EnergonHubCore"..s,V(.12,.39,.39),C(-.85,4.91,z+s*.12)*A(0,math.pi/2,0),orange,NEON)
  b:cylinder("HotCentralPin"..s,V(.13,.15,.15),C(-.85,4.91,z+s*.17)*A(0,math.pi/2,0),edge,NEON)
  for j=0,3 do
   local a=j*math.pi/2+math.pi/4
   b:cylinder("HubBolt"..s.."_"..j,V(.06,.084,.084),C(-.85+math.cos(a)*.46,4.91+math.sin(a)*.46,z+s*.065)*A(0,math.pi/2,0),steel,METAL)
  end
 end
 -- Continuous half-moon silhouette. The outer edge is only .05 studs thick;
 -- the inner spine is .48 thick, so each broad face slopes toward a sharp edge.
 local segments=12
 for i=0,segments-1 do
  local a=-math.pi/2+i*math.pi/segments
  local c=-math.pi/2+(i+1)*math.pi/segments
  for _,s in ipairs({-1,1}) do
   local innerA,innerC=point(a,1.10,s*.24),point(c,1.10,s*.24)
   local outerA,outerC=point(a,2.45,s*.025),point(c,2.45,s*.025)
   b:triangle("SlopingCrescentFace"..s.."_"..i.."a",innerA,outerA,outerC,orange,.035,NEON)
   b:triangle("SlopingCrescentFace"..s.."_"..i.."b",innerA,outerC,innerC,i%3==0 and amber or orange,.035,NEON)
  end
  b:line("SharpLuminousEdge"..i,point(a,2.45,0),point(c,2.45,0),.048,.055,edge,NEON)
  b:line("CurvedOrangeBladeSpine"..i,point(a,1.10,0),point(c,1.10,0),.065,.48,amber,NEON)
  -- A fine inset line follows the broad face rather than floating around it.
  if i>0 and i<segments-1 then
   b:line("InsetEnergonContour"..i,point(a,1.94,-.145),point(c,1.94,-.145),.024,.024,edge,NEON)
  end
 end
 -- A tiny Optimus-coloured armour badge distinguishes the mechanical grip.
 b:box("OptimusBlueBadge",V(.31,.37,.037),C(-.85,3.78,-.379),blueLight,METAL)
 b:box("OptimusSilverFaceplate",V(.23,.16,.046),C(-.85,3.71,-.407),silver,METAL)
 b:box("OptimusEyeStrip",V(.22,.038,.044),C(-.85,3.85,-.408),RGB(110,231,255),NEON)
 for _,s in ipairs({-1,1}) do
  b:box("BlueBadgeAntenna"..s,V(.043,.27,.047),C(-.85+s*.17,3.88,-.405),blueLight,METAL)
 end
 b.model:SetAttribute("ArtVersion",72)
 b.model:SetAttribute("ArtSource","NativeRobloxParts")
 b.model:SetAttribute("BladeProfile","Double-bevel Energon crescent with thin cutting edge")
 b.model:SetAttribute("Franchise","Transformers")
 return true
end

return M
