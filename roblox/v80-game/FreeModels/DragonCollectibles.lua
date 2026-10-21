-- Native, display-sized Yu-Gi-Oh! dragons. No meshes, decals or runtime animation.
-- Both sculptures face -Z and keep their complete wings and tails over a plinth.
local M={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local RGB=Color3.fromRGB
local METAL,SMOOTH,NEON=Enum.Material.Metal,Enum.Material.SmoothPlastic,Enum.Material.Neon
local PI=math.pi

local function box(b,n,p,size,color,rotation,material)
 return b:box(n,size,C(p)*(rotation or C()),color,material or METAL)
end
local function ball(b,n,p,size,color)
 return b:ball(n,size,C(p),color,METAL)
end
local function line(b,n,a,c,width,color,depth)
 return b:line(n,a,c,width,depth or width,color,METAL)
end
local function fin(b,n,a,c,d,color,thickness)
 return b:triangle(n,a,c,d,color,thickness or .06,METAL)
end
local function blade(b,n,a,tip,width,color)
 local delta=tip-a
 local side=delta:Cross(V(0,0,1))
 if side.Magnitude<.01 then side=delta:Cross(V(0,1,0)) end
 side=side.Unit*width*.5
 fin(b,n,a-side,a+side,tip,color,.075)
end

local function torso(b,stardust,palette)
 local white,bright,shade,deep=palette.white,palette.bright,palette.shade,palette.deep
 ball(b,'ArmoredPelvis',V(0,1.53,.46),V(1.02,1.19,1.08),shade)
 ball(b,'TaperedDragonTorso',V(0,2.58,.23),V(1.20,1.91,1.07),white)
 ball(b,'HighShoulderMantle',V(0,3.27,.30),V(1.46,.83,1.00),shade)
 for _,s in ipairs({-1,1}) do
  box(b,'PectoralArmor'..s,V(s*.30,3.07,-.32),V(.63,.66,.25),white,A(-.11,0,-s*.17))
  box(b,'PectoralBevel'..s,V(s*.31,3.28,-.47),V(.63,.11,.085),bright,A(0,0,-s*.17))
  line(b,'CollarArc'..s,V(s*.12,3.50,-.17),V(s*.69,3.38,-.08),.13,bright,.15)
  for rib=0,2 do
   box(b,'FlankPlate'..s..'_'..rib,V(s*(.52-rib*.055),2.74-rib*.31,.31),V(.26,.36,.83),
    rib%2==0 and white or shade,A(.10,0,-s*.18))
  end
 end
 for row=0,5 do
  local y=2.91-row*.25
  local width=.78-row*.055
  local z=-.37+row*.035
  box(b,'BellyArmorCourse'..row,V(0,y,z),V(width,.23,.20),row%2==0 and bright or white,A(-.10,0,0))
  if not stardust or row%2==0 then box(b,'BellyScaleLowerLip'..row,V(0,y-.085,z-.105),V(width*.94,.032,.035),shade) end
 end
 if stardust then
  local center=V(0,3.12,-.50)
  fin(b,'StardustBreastCrystalUpper',center+V(-.14,0,0),center+V(.14,0,0),center+V(0,.27,-.06),palette.accent,.04)
  fin(b,'StardustBreastCrystalLower',center+V(-.14,0,0),center+V(0,-.26,-.06),center+V(.14,0,0),palette.lit,.04)
 else
  box(b,'BlueEyesBreastKeel',V(0,3.03,-.52),V(.13,.65,.12),bright,A(-.09,0,0))
 end
end

local function limbs(b,stardust,palette)
 for _,s in ipairs({-1,1}) do
  local white,shade,bright=palette.white,palette.shade,palette.bright
  -- Reverse-jointed haunches with broad three-taloned feet support the sculpture.
  ball(b,'HipJoint'..s,V(s*.57,1.62,.41),V(.61,.70,.67),shade)
  line(b,'PowerfulThigh'..s,V(s*.57,1.69,.40),V(s*.83,1.05,-.06),.46,white,.56)
  b:wedge('ArmoredKnee'..s,V(.48,.43,.48),C(s*.83,1.00,-.08)*A(-.22,0,0),bright,METAL)
  line(b,'SweptShin'..s,V(s*.82,1.04,-.02),V(s*.68,.43,.13),.30,shade,.34)
  box(b,'ShinFaceArmor'..s,V(s*.74,.70,-.07),V(.31,.52,.19),white,A(.24,0,-s*.20))
  ball(b,'LowAnkle'..s,V(s*.68,.37,.03),V(.36,.39,.42),shade)
  box(b,'DragonFoot'..s,V(s*.70,.22,-.24),V(.64,.27,.81),white,A(0,s*.08,0))
  for toe=-1,1 do
   local x=s*.70+toe*.19
   box(b,'SegmentedToe'..s..'_'..toe,V(x,.19,-.64),V(.16,.17,.35),shade,A(-.12,0,0))
   blade(b,'SharpFootTalon'..s..'_'..toe,V(x,.20,-.73),V(x,.12,-1.00),.17,bright)
  end
  blade(b,'HeelSpur'..s,V(s*.69,.43,.30),V(s*.73,.59,.69),.15,white)
  -- Forearms are separate from the wings and end in visible curled fingers.
  ball(b,'ShoulderJoint'..s,V(s*.69,3.28,.02),V(.44,.49,.49),shade)
  line(b,'UpperForelimb'..s,V(s*.72,3.21,.02),V(s*.94,2.76,-.22),.25,white,.29)
  ball(b,'ElbowJoint'..s,V(s*.95,2.72,-.24),V(.31,.32,.34),shade)
  line(b,'ForearmPlate'..s,V(s*.95,2.75,-.22),V(s*1.07,2.55,-.65),.23,white,.28)
  box(b,'ClawedPalm'..s,V(s*1.08,2.50,-.76),V(.34,.18,.30),shade,A(.16,0,-s*.20))
  for _,finger in ipairs(stardust and {-1,1} or {-1,0,1}) do
   local x=s*1.08+finger*.105
   line(b,'ClawFinger'..s..'_'..finger,V(x,2.52,-.84),V(x,2.36,-1.00),.075,white,.095)
   blade(b,'HandTalon'..s..'_'..finger,V(x,2.37,-.99),V(x,2.33,-1.15),.09,bright)
  end
  blade(b,'ForearmBackSpur'..s,V(s*.98,2.74,-.30),V(s*1.22,3.08,-.10),.20,stardust and palette.accent or bright)
 end
end

local function head(b,stardust,palette)
 local white,bright,shade,deep=palette.white,palette.bright,palette.shade,palette.deep
 local neck={V(0,3.29,.23),V(0,3.72,.02),V(0,4.12,-.25),V(0,4.45,-.62)}
 for i=1,#neck-1 do
  line(b,'SegmentedNeck'..i,neck[i],neck[i+1],.58-i*.045,shade,.61-i*.035)
  local p=(neck[i]+neck[i+1])*.5
  box(b,'NeckThroatScale'..i,p+V(0,0,-.27),V(.48-i*.035,.32,.17),bright,A(-.50,0,0))
 end
 -- A long cheek/upper-jaw assembly, dark recessed mouth and two separate eyes.
 ball(b,'SculptedDragonCranium',V(0,4.52,-.82),V(.88,.70,.94),shade)
 box(b,'BrowArmoredSkull',V(0,4.69,-.86),V(.70,.35,.88),white,A(.10,0,0))
 b:wedge('LongUpperMuzzle',V(.61,.34,.94),C(0,4.49,-1.35)*A(.13,0,0),white,METAL)
 if not stardust then box(b,'MuzzleTopRidge',V(0,4.61,-1.29),V(.25,.08,.65),bright,A(.32,0,0)) end
 box(b,'NoseTerminalPlate',V(0,4.42,-1.81),V(.45,.13,.13),bright,A(.13,0,0))
 box(b,'OpenMouthRecess',V(0,4.29,-1.35),V(.54,.12,.88),deep,A(.05,0,0),SMOOTH)
 b:wedge('SeparateLowerJaw',V(.52,.16,.84),C(0,4.17,-1.30)*A(-.12,0,0),shade,METAL)
 box(b,'LowerJawChinPlate',V(0,4.15,-1.68),V(.43,.14,.17),white,A(-.12,0,0))
 for _,s in ipairs({-1,1}) do
  -- Eye facets face forward and outward; bright iris remains readable overhead.
  local eye=C(s*.34,4.62,-1.14)*A(0,-s*.38,0)
  b:box('RecessedEyeSocket'..s,V(.25,.20,.10),eye,deep,SMOOTH)
  b:box('SignatureDragonEye'..s,V(.16,.095,.046),eye*C(0,0,-.068),palette.eye,NEON)
  b:box('DragonEyePupil'..s,V(.027,.087,.015),eye*C(0,0,-.097),deep,SMOOTH)
  b:box('RaisedEyeBrow'..s,V(.32,.075,.12),eye*C(0,.115,-.06)*A(0,0,-s*.16),bright,METAL)
  box(b,'MuzzleNostril'..s,V(s*.15,4.46,-1.876),V(.075,.045,.025),deep,A(0,0,-s*.10),SMOOTH)
  fin(b,'SculptedCheekPlate'..s,V(s*.30,4.74,-.97),V(s*.62,4.43,-.57),V(s*.28,4.26,-1.20),white,.09)
  for tooth=0,(stardust and 1 or 2) do
   blade(b,'UpperJawFang'..s..'_'..tooth,V(s*.25,4.36,-1.07-tooth*.27),V(s*.24,4.23,-1.10-tooth*.27),.075,bright)
  end
  blade(b,'LowerJawRearHorn'..s,V(s*.30,4.25,-.77),V(s*.50,4.10,-.41),.19,shade)
  if stardust then
   blade(b,'StardustLongCrownHorn'..s,V(s*.24,4.84,-.63),V(s*.57,5.77,.04),.32,bright)
   blade(b,'StardustEarBlade'..s,V(s*.42,4.65,-.59),V(s*.83,5.12,.38),.27,white)
   blade(b,'StardustEmeraldCrownInlay'..s,V(s*.26,4.95,-.55),V(s*.51,5.59,-.04),.085,palette.accent)
  else
   blade(b,'BlueEyesRearSweptHorn'..s,V(s*.32,4.82,-.59),V(s*.67,5.20,.48),.31,bright)
   blade(b,'BlueEyesTempleSpur'..s,V(s*.43,4.46,-.53),V(s*.72,4.64,.15),.27,white)
  end
 end
 if stardust then
  blade(b,'StardustForeheadSpear',V(0,4.87,-1.02),V(0,5.60,-1.32),.22,white)
  fin(b,'StardustForeheadCrystal',V(-.11,4.85,-1.23),V(.11,4.85,-1.23),V(0,5.14,-1.19),palette.accent,.035)
 else
  blade(b,'BlueEyesOccipitalBlade',V(0,4.84,-.49),V(0,5.28,.29),.25,white)
 end
end

local function wings(b,stardust,palette)
 for _,s in ipairs({-1,1}) do
  local prefix=s<0 and 'LeftWing' or 'RightWing'
  local root=V(s*.51,3.39,.49)
  local elbow=V(s*.92,4.14,.72)
  local crest=V(s*1.52,stardust and 5.30 or 5.10,.70)
  local outer=V(s*2.43,stardust and 4.68 or 4.38,1.02)
  local low=V(s*2.10,2.78,1.27)
  local inner=V(s*.79,2.49,.58)
  local middle=V(s*1.65,3.63,.89)
  local membrane=stardust and palette.accent or palette.membrane
  -- Actual double-wedge triangles make broad membranes with sculpted valleys.
  fin(b,prefix..'UpperMembrane',elbow,crest,outer,membrane,.055)
  fin(b,prefix..'MiddleMembrane',elbow,outer,middle,stardust and palette.lit or palette.shade,.055)
  fin(b,prefix..'OuterMembrane',middle,outer,low,membrane,.055)
  fin(b,prefix..'LowerMembrane',middle,low,V(s*1.32,2.93,.83),stardust and palette.accent or palette.membrane,.055)
  fin(b,prefix..'RootMembrane',root,middle,inner,membrane,.055)
  line(b,prefix..'Humerus',root,elbow,.20,palette.white,.23)
  line(b,prefix..'LeadingEdge',elbow,crest,.15,palette.bright,.19)
  line(b,prefix..'CrestEdge',crest,outer,.11,palette.white,.14)
  line(b,prefix..'LongWingFinger',elbow,outer,.11,palette.bright,.15)
  line(b,prefix..'LowerWingFinger',elbow,low,.105,palette.white,.14)
  line(b,prefix..'InteriorWingFinger',elbow,V(s*1.32,2.93,.83),.09,palette.bright,.12)
  line(b,prefix..'RootStrut',root,inner,.12,palette.shade,.14)
  ball(b,prefix..'ElbowJoint',elbow,V(.26,.26,.28),palette.shade)
  blade(b,prefix..'ThumbTalon',crest,crest+V(s*.03,.35,-.13),.18,palette.bright)
  blade(b,prefix..'OuterTalon',outer,outer+V(s*.12,-.30,.04),.14,palette.bright)
  blade(b,prefix..'LowerTalon',low,low+V(-s*.05,-.28,.05),.15,palette.white)
  if stardust then
   -- Stardust's layered white ray feathers contrast with Blue-Eyes' bat wings.
   for ray=0,2 do
    local start=elbow:Lerp(crest,.35+ray*.20)
    local tip=V(s*(2.15+ray*.14),4.06+ray*.24,1.02)
    blade(b,prefix..'SilverRayFeather'..ray,start,tip,.16,palette.bright)
   end
  else
   line(b,prefix..'RecessedMembraneVein',V(s*1.29,3.87,.84),V(s*2.30,3.39,1.19),.043,palette.shade,.045)
  end
 end
end

local function tailAndSpines(b,stardust,palette)
 local points={V(0,1.58,.71),V(.17,1.40,1.16),V(.50,1.16,1.63),V(.94,.95,1.95),
  V(1.45,.77,2.06),V(1.86,.67,1.90),V(2.08,.65,1.53),V(2.06,.75,1.06),V(1.82,.96,.68)}
 for i=1,#points-1 do
  local width=.48-(i-1)*.047
  line(b,'ConnectedTailSegment'..i,points[i],points[i+1],width,i%2==0 and palette.shade or palette.white,width*.90)
  if i<#points-1 then ball(b,'TailArmoredJoint'..i,points[i+1],V(width*.91,width*.91,width*.91),palette.white) end
 end
 blade(b,'SharpTailTip',points[#points],V(1.42,1.31,.41),.18,palette.bright)
 for i=1,4 do
  local p=points[i+1]
  blade(b,'TailSpine'..i,p+V(0,.13,0),p+V(-.03,.40-i*.025,.13),.15,stardust and palette.accent or palette.bright)
 end
 local back={V(0,3.38,.78),V(0,3.04,.84),V(0,2.65,.82),V(0,2.27,.84)}
 for i,p in ipairs(back) do
  blade(b,'DorsalArmorSpine'..i,p,p+V(0,.21,.40-i*.025),.21,stardust and palette.accent or palette.bright)
 end
end

function M.build(b,key)
 if key~='stardust_dragon' and key~='blue_eyes_white_dragon' then return false end
 local stardust=key=='stardust_dragon'
 local palette=stardust and {
  white=RGB(215,239,235),bright=RGB(250,255,250),shade=RGB(115,167,164),
  deep=RGB(18,53,62),accent=RGB(45,153,137),lit=RGB(111,219,188),eye=RGB(126,255,203),
 } or {
  white=RGB(214,228,242),bright=RGB(251,253,255),shade=RGB(131,156,185),
  deep=RGB(16,31,55),membrane=RGB(160,190,219),eye=RGB(60,181,255),
 }
 torso(b,stardust,palette)
 limbs(b,stardust,palette)
 head(b,stardust,palette)
 wings(b,stardust,palette)
 tailAndSpines(b,stardust,palette)
 b.model:SetAttribute('ArtVersion',75)
 b.model:SetAttribute('Franchise','Yu-Gi-Oh!')
 b.model:SetAttribute('CharacterName',stardust and 'Stardust Dragon' or 'Blue-Eyes White Dragon')
 b.model:SetAttribute('SculptedDragonHead',true)
 b.model:SetAttribute('RecessedSeparateEyes',2)
 b.model:SetAttribute('OpenDragonMouth',true)
 b.model:SetAttribute('NativePolygonWings',2)
 b.model:SetAttribute('ConnectedTaperedTail',true)
 b.model:SetAttribute('ArticulatedClawedLimbs',4)
 return true
end
return M
