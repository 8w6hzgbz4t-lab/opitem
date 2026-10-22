-- Hand-built collectible art. All surfaces, lettering and gems are native parts.
local M={}
local V,C,A,RGB=Vector3.new,CFrame.new,CFrame.Angles,Color3.fromRGB
local PI=math.pi
local METAL,WOOD,NEON,PLASTIC=Enum.Material.Metal,Enum.Material.Wood,Enum.Material.Neon,Enum.Material.SmoothPlastic
local silver,ivory,dark=RGB(211,225,237),RGB(246,248,244),RGB(20,28,43)
local gold,paleGold,bronze=RGB(229,170,37),RGB(255,225,118),RGB(133,83,27)
local blue,cyan,red=RGB(22,82,180),RGB(81,222,248),RGB(192,32,43)

local letters={
 M={{-.4,-.5,-.4,.5},{-.4,.5,0,-.05},{0,-.05,.4,.5},{.4,.5,.4,-.5}},
 O={{-.35,-.5,-.35,.5},{-.35,.5,.35,.5},{.35,.5,.35,-.5},{.35,-.5,-.35,-.5}},
 S={{.35,.5,-.35,.5},{-.35,.5,-.35,0},{-.35,0,.35,0},{.35,0,.35,-.5},{.35,-.5,-.35,-.5}},
 T={{-.4,.5,.4,.5},{0,.5,0,-.5}},
 U={{-.35,.5,-.35,-.5},{-.35,-.5,.35,-.5},{.35,-.5,.35,.5}},
 N={{-.35,-.5,-.35,.5},{-.35,.5,.35,-.5},{.35,-.5,.35,.5}},
 G={{.35,.5,-.35,.5},{-.35,.5,-.35,-.5},{-.35,-.5,.35,-.5},{.35,-.5,.35,0},{.35,0,.02,0}},
}
local function lettering(b,name,word,frame,size,color,width)
 local advance=size*.9
 for index=1,#word do
  local glyph=letters[word:sub(index,index)]
  if glyph then for stroke,line in ipairs(glyph) do
   local x=(index-(#word+1)/2)*advance
   b:line(name..index..'_'..stroke,frame*V(x+line[1]*size,line[2]*size,0),frame*V(x+line[3]*size,line[4]*size,0),width or .035,.026,color,METAL)
  end end
 end
end
local function disc(b,name,frame,diameter,depth,color,material)
 return b:cylinder(name,V(depth,diameter,diameter),frame*A(0,PI/2,0),color,material or METAL)
end
local function gem(b,name,position,size,color)
 local p=b:box(name,V(size,size,.055),C(position)*A(0,0,PI/4),color or ivory,METAL)
 p.Reflectance=.22
 return p
end

local function glove(b)
 local cool=RGB(169,188,211)
 b:ball('TailoredGlovePalm',V(1.85,2.12,.64),C(0,1.9,.02),ivory,Enum.Material.Fabric)
 b:ball('PaddedGloveBack',V(1.64,1.95,.31),C(0,1.94,-.25),silver,Enum.Material.Fabric)
 b:box('FittedWristCuff',V(1.42,.53,.68),C(0,.69,.04),cool,Enum.Material.Fabric)
 for _,side in ipairs({-1,1}) do
  b:line('CuffPiping'..side,V(-.68,.69+side*.22,-.32),V(.68,.69+side*.22,-.32),.052,.05,silver,METAL)
 end
 for i=1,3 do disc(b,'CuffPearlButton'..i,C(.54,.55+i*.095,-.343),.075,.035,ivory) end
 local fingers={
  {name='Index',x=-.65,start=2.67,length=1.51,lean=-.075,width=.34},
  {name='Middle',x=-.21,start=2.82,length=1.79,lean=-.01,width=.36},
  {name='Ring',x=.24,start=2.77,length=1.61,lean=.055,width=.35},
  {name='Pinky',x=.66,start=2.59,length=1.26,lean=.14,width=.31},
 }
 local gems=0
 for _,finger in ipairs(fingers) do
  local a=V(finger.x,finger.start,.015)
  for segment=1,3 do
   local t=segment/3
   local tip=V(finger.x+finger.lean*t,finger.start+finger.length*t,.015+(.06*t*t))
   b:line(finger.name..'FingerSegment'..segment,a,tip,finger.width,.40,ivory,Enum.Material.Fabric)
   b:ball(finger.name..'RoundedJoint'..segment,V(finger.width,.30,.40),C(tip),silver,Enum.Material.Fabric)
   if segment<3 then b:line(finger.name..'TailoringJoint'..segment,tip+V(-finger.width*.38,0,-.205),tip+V(finger.width*.38,0,-.205),.018,.018,cool,Enum.Material.Fabric) end
   for j=0,2 do
    local center=a:Lerp(tip,.2+j*.3)
    gem(b,finger.name..'FingerRhinestone'..segment..'_'..j,center+V((j%2==0 and -.055 or .055),0,-.228),.105,j%2==0 and ivory or cool)
    gems=gems+1
   end
   a=tip
  end
  b:ball(finger.name..'TailoredFingertip',V(finger.width*.93,.27,.39),C(a+V(0,.04,0)),ivory,Enum.Material.Fabric)
 end
 local thumb={V(-.64,1.6,.03),V(-1.15,1.98,.02),V(-1.46,2.51,.025),V(-1.54,2.9,.03)}
 for i=1,3 do
  b:line('ThumbTailoredSegment'..i,thumb[i],thumb[i+1],.40,.44,ivory,Enum.Material.Fabric)
  b:ball('ThumbRoundedJoint'..i,V(.41,.36,.45),C(thumb[i+1]),silver,Enum.Material.Fabric)
  for j=0,2 do gem(b,'ThumbRhinestone'..i..'_'..j,thumb[i]:Lerp(thumb[i+1],.2+j*.3)+V(0,0,-.25),.11,ivory);gems=gems+1 end
 end
 b:line('ThumbSeam',V(-.77,1.55,-.27),V(-1.2,2.09,-.24),.027,.02,cool,Enum.Material.Fabric)
 for row=0,5 do for col=0,4 do
  local x=(col-2)*.255+(row%2)*.04
  local y=1.14+row*.255
  if math.abs(x)<.77 then gem(b,'PalmRhinestone'..row..'_'..col,V(x,y,-.403),.118,(row+col)%3==0 and cool or ivory);gems=gems+1 end
 end end
 for _,side in ipairs({-1,1}) do
  b:line('PalmContourStitch'..side,V(side*.72,1.11,-.22),V(side*.82,2.47,-.20),.025,.025,cool,Enum.Material.Fabric)
 end
 for i=0,9 do gem(b,'CuffRhinestone'..i,V(-.59+i*.13,.7,-.36),.078,ivory);gems=gems+1 end
 for i,p in ipairs({V(-.35,2.2,-.455),V(.4,1.35,-.455),V(-.18,3.8,-.25)}) do
  b:line('StoneGlintVertical'..i,p-V(0,.115,0),p+V(0,.115,0),.024,.02,ivory,NEON)
  b:line('StoneGlintCross'..i,p-V(.09,0,0),p+V(.09,0,0),.024,.02,ivory,NEON)
 end
 b.model:SetAttribute('FingerCount',5)
 b.model:SetAttribute('RhinestoneCount',gems)
 b.model:SetAttribute('RecognizableFeature','Five-finger silver rhinestone performance glove')
 b.model:SetAttribute('Franchise','Michael Jackson')
end

local function frustumY(b,name,y0,y1,r0,r1,color,segments)
 segments=segments or 10
 for i=0,segments-1 do
  local a,c=i*2*PI/segments,(i+1)*2*PI/segments
  local p=V(math.cos(a)*r0,y0,math.sin(a)*r0)
  local q=V(math.cos(c)*r0,y0,math.sin(c)*r0)
  local r=V(math.cos(c)*r1,y1,math.sin(c)*r1)
  local s=V(math.cos(a)*r1,y1,math.sin(a)*r1)
  b:triangle(name..i..'A',p,q,r,color,.025,WOOD)
  b:triangle(name..i..'B',p,r,s,color,.025,WOOD)
 end
end
local function bat(b)
 local honey,grain,light=RGB(145,91,47),RGB(92,53,31),RGB(190,137,76)
 b:cylinder('TurnedAshBarrel',V(2.5,.98,.98),C(0,3.87,0)*A(0,0,PI/2),honey,WOOD)
 b:ball('RoundedWoodBarrelCap',V(.98,.52,.98),C(0,5.12,0),honey,WOOD)
 frustumY(b,'TaperedWoodShoulder',1.65,2.64,.19,.49,honey,10)
 b:cylinder('LongWoodHandle',V(1.40,.38,.38),C(0,1.03,0)*A(0,0,PI/2),light,WOOD)
 b:cylinder('TurnedBatKnob',V(.16,.62,.62),C(0,.28,0)*A(0,0,PI/2),honey,WOOD)
 b:ball('SmoothKnobEdge',V(.62,.13,.62),C(0,.21,0),honey,WOOD)
 for i=0,11 do
  local y=.49+i*.083
  b:cylinder('DarkLeatherGripBand'..i,V(.07,.405,.405),C(0,y,0)*A(0,0,PI/2),RGB(51,40,34),Enum.Material.Fabric)
  b:line('DiagonalGripSeam'..i,V(-.15,y-.02,-.15),V(.15,y+.065,-.15),.025,.023,RGB(114,84,57),Enum.Material.Fabric)
 end
 for i=0,15 do
  local angle=i*2*PI/16
  local x,z=math.sin(angle)*.493,math.cos(angle)*.493
  local offset=(i%3)*.10
  b:line('BarrelWoodGrain'..i,V(x,2.82+offset,z),V(x*.97,4.87-offset,z*.97),.017+(i%2)*.009,.017,i%2==0 and grain or light,WOOD)
 end
 b:ring('TopEndGrainOuter',C(0,5.365,0)*A(PI/2,0,0),.27,.018,grain,12,WOOD)
 b:ring('TopEndGrainInner',C(.025,5.372,0)*A(PI/2,0,0),.14,.014,light,10,WOOD)
 b:box('TungsBrandInset',V(.79,.47,.028),C(0,4.21,-.493),RGB(113,65,34),WOOD)
 lettering(b,'TungsBarrelBrand','TUNGS',C(0,4.21,-.519),.16,RGB(235,189,116),.020)
 for i=0,3 do
  local x=-.3+i*.2
  b:line('WornBarrelScuff'..i,V(x,3.01+i*.10,-.495),V(x+.08,3.20+i*.1,-.492),.015,.014,RGB(203,157,94),WOOD)
 end
 b.model:SetAttribute('RealTaperedShoulder',true)
 b.model:SetAttribute('WrappedGripBands',12)
 b.model:SetAttribute('NativeRaisedName','TUNGS')
 b.model:SetAttribute('RecognizableFeature','Rounded wooden bat with tapered shoulder and worn wrapped grip')
 b.model:SetAttribute('Franchise','Tung Tung Tung Sahur')
end

local function roundedCard(b,name,frame,width,height,depth,radius,color,material)
 b:box(name..'HorizontalCore',V(width,height-2*radius,depth),frame,color,material)
 b:box(name..'VerticalCore',V(width-2*radius,height,depth),frame,color,material)
 for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do
  disc(b,name..'RoundCorner'..x..y,frame*C(x*(width/2-radius),y*(height/2-radius),0),radius*2,depth,color,material)
 end end
end
local function creditCard(b)
 local body=RGB(26,25,43)
 roundedCard(b,'PlatinumCardBody',C(0,1.65,0),4.6,2.88,.16,.19,silver,METAL)
 roundedCard(b,'BlackCeramicCardFace',C(0,1.65,-.096),4.42,2.70,.035,.16,body,METAL)
 roundedCard(b,'BlackCeramicCardBack',C(0,1.65,.096),4.42,2.70,.035,.16,RGB(37,36,49),METAL)
 for _,side in ipairs({-1,1}) do
  b:box('EngravedGoldTopBottom'..side,V(3.90,.025,.025),C(0,1.65+side*1.275,-.124),paleGold,METAL)
  b:box('EngravedGoldSide'..side,V(.025,2.14,.025),C(side*2.11,1.65,-.124),gold,METAL)
 end
 lettering(b,'MomsCardEmbossedTitle','MOMS',C(-.36,2.58,-.151),.36,paleGold,.041)
 -- A fictional icon replaces card numbers, expiry dates and payment-network marks.
 b:box('GoldMicrochipBody',V(.91,.67,.045),C(-1.34,1.78,-.14),gold,METAL)
 b:box('MicrochipCenter',V(.37,.45,.015),C(-1.34,1.78,-.173),RGB(208,150,47),METAL)
 for side=-1,1,2 do
  for row=-1,1 do
   b:box('ContactPad'..side..'_'..row,V(.20,.13,.024),C(-1.34+side*.31,1.78+row*.195,-.178),paleGold,METAL)
  end
  b:box('ContactSplit'..side,V(.018,.56,.012),C(-1.34+side*.20,1.78,-.197),bronze,METAL)
 end
 for row=-1,1,2 do b:box('MicrochipRowSplit'..row,V(.86,.018,.012),C(-1.34,1.78+row*.10,-.195),bronze,METAL) end
 for wave=1,3 do
  local radius=.18+wave*.105
  for i=0,5 do
   local a=-PI/3+i*PI/9;local z=-PI/3+(i+1)*PI/9
   b:line('ContactlessArc'..wave..'_'..i,V(-.45+math.cos(a)*radius,1.78+math.sin(a)*radius,-.158),V(-.45+math.cos(z)*radius,1.78+math.sin(z)*radius,-.158),.025,.02,silver,METAL)
  end
 end
 local center=V(1.22,1.72,-.156)
 for i=0,7 do
  local a=i*PI/4
  local c=RGB(112+(i%3)*46,128+(i%4)*28,209+(i%2)*28)
  b:triangle('EtherealHologramFacet'..i,center+V(0,.57,0),center+V(math.cos(a)*.48,-.35,math.sin(a)*.07),center+V(math.cos(a+PI/4)*.48,-.35,math.sin(a+PI/4)*.07),c,.025,METAL)
 end
 for i=0,7 do
  local a=i*PI/4
  b:line('HologramSecurityRay'..i,center+V(math.cos(a)*.65,math.sin(a)*.65,0),center+V(math.cos(a)*.83,math.sin(a)*.83,0),.022,.018,paleGold,METAL)
 end
 -- Four embossed decorative dashes are explicitly not a real account number.
 for group=0,3 do
  for mark=0,2 do
   local x=-1.75+group*.88+mark*.18
   b:box('FictionalSecurityDash'..group..'_'..mark,V(.115,.043,.025),C(x,.77,-.152),silver,METAL)
  end
 end
 b:box('RearMagneticStripe',V(4.2,.47,.023),C(0,2.19,.126),RGB(8,10,18),PLASTIC)
 b:box('RearSignaturePanel',V(2.6,.41,.02),C(-.5,1.47,.127),RGB(193,192,208),PLASTIC)
 for i=0,6 do b:line('SignatureDecorativeWave'..i,V(-1.5+i*.25,1.46+.08*math.sin(i),.145),V(-1.25+i*.25,1.46+.08*math.sin(i+1),.145),.022,.016,RGB(57,59,84),METAL) end
 for i=0,7 do
  b:box('RearMicroprint'..i,V(.23+(i%3)*.06,.025,.014),C(-1.6+i*.45,.88,.143),silver,METAL)
 end
 b.model:SetAttribute('FictionalCard',true)
 b.model:SetAttribute('NoPersonalPaymentData',true)
 b.model:SetAttribute('RoundedMetalCard',true)
 b.model:SetAttribute('RaisedMomsLettering',true)
 b.model:SetAttribute('ContactlessArcCount',3)
 b.model:SetAttribute('RecognizableFeature','Black platinum credit card with gold chip and ethereal hologram')
end

local function ring(b)
 local ringCenter=V(0,2.67,0)
 local radius=1.55
 for i=0,23 do
  local a,c=i*2*PI/24,(i+1)*2*PI/24
  local p,q=ringCenter+V(math.cos(a)*radius,math.sin(a)*radius,0),ringCenter+V(math.cos(c)*radius,math.sin(c)*radius,0)
  local tangent=(q-p).Unit;local radial=V(math.cos((a+c)*.5),math.sin((a+c)*.5),0)
  local cf=CFrame.fromMatrix((p+q)*.5,tangent,radial,tangent:Cross(radial))
  local part=b:cylinder('RoundedGoldenRingSegment'..i,V((q-p).Magnitude+.015,.45,.45),cf,i%4==0 and paleGold or gold,METAL)
  part.Reflectance=.12
  b:ball('RoundedRingJoint'..i,.44,C(p),gold,METAL)
 end
 for _,side in ipairs({-1,1}) do
  b:ring('PolishedRingBevel'..side,C(ringCenter+V(0,0,side*.177)),radius,.067,paleGold,24,METAL)
 end
 -- A compact blue-and-gold energy base supports the open ring without filling it.
 b:box('BlueSpeedPlinth',V(2.38,.20,1.44),C(0,.34,.12),blue,METAL)
 b:box('GoldPlinthInset',V(2.13,.045,1.20),C(0,.462,.12),gold,METAL)
 b:box('LowSonicBlueSupport',V(.31,.53,.30),C(0,.72,.10),blue,METAL)
 b:ball('RingCradle',V(.62,.28,.44),C(0,.99,.04),paleGold,METAL)
 for _,side in ipairs({-1,1}) do
  for i=0,2 do
   local y=.68+i*.16
   b:line('BlueSpeedTrail'..side..'_'..i,V(side*.75,y,.35),V(side*(1.25+i*.24),y+.23,.5),.065,.07,cyan,NEON)
  end
 end
 for i=0,7 do
  local a=i*PI/4
  local p=ringCenter+V(math.cos(a)*1.56,math.sin(a)*1.56,-.245)
  b:box('RingInsetHighlight'..i,V(.13,.038,.025),C(p)*A(0,0,a+PI/2),ivory,METAL)
 end
 for i,p in ipairs({V(-1.12,3.76,-.30),V(1.4,2.1,-.3)}) do
  b:line('RingSparkleLong'..i,p-V(0,.16,0),p+V(0,.16,0),.032,.02,paleGold,NEON)
  b:line('RingSparkleShort'..i,p-V(.12,0,0),p+V(.12,0,0),.032,.02,paleGold,NEON)
 end
 b.model:SetAttribute('TrueOpenRing',true)
 b.model:SetAttribute('RoundedRingSegments',24)
 b.model:SetAttribute('RecognizableFeature','Open golden ring with polished rounded tube and Sonic blue cradle')
 b.model:SetAttribute('Franchise','Sonic the Hedgehog')
end

local function star(b,name,center,radius,depth,color)
 local vertices={}
 for i=0,9 do
  local a=PI/2+i*PI/5;local r=i%2==0 and radius or radius*.43
  vertices[#vertices+1]=center+V(math.cos(a)*r,math.sin(a)*r,0)
 end
 for i=1,10 do
  b:triangle(name..i,center+V(0,0,-depth),vertices[i],vertices[i%10+1],color,.025,METAL)
 end
end
local function shield(b)
 local center=V(0,2.43,0)
 disc(b,'ConvexShieldBacking',C(center),4.62,.34,RGB(142,27,39))
 disc(b,'BrushedMetalOuterRim',C(center+V(0,0,-.17)),4.65,.11,silver)
 disc(b,'OuterRedShieldFace',C(center+V(0,0,-.24)),4.48,.10,red)
 disc(b,'SilverConcentricBand',C(center+V(0,0,-.31)),3.62,.10,silver)
 disc(b,'InnerRedConcentricBand',C(center+V(0,0,-.38)),2.87,.10,red)
 disc(b,'BlueStarMedallion',C(center+V(0,0,-.45)),2.09,.10,blue)
 star(b,'RaisedFivePointStar',center+V(0,0,-.69),.90,0,ivory)
 b:ring('MachinedOuterRimLine',C(center+V(0,0,-.238)),2.28,.036,RGB(235,241,247),32,METAL)
 b:ring('OuterBandFineSeam',C(center+V(0,0,-.30)),1.83,.026,RGB(126,35,47),24,METAL)
 for i=0,15 do
  local a=i*2*PI/16
  b:line('RadialBrushedMetalDetail'..i,center+V(math.cos(a)*1.64,math.sin(a)*1.64,-.366),center+V(math.cos(a+.016)*1.73,math.sin(a+.016)*1.73,-.367),.013,.012,RGB(173,191,210),METAL)
 end
 for i=0,5 do
  local a=.35+i*.93
  b:line('ShieldPaintWear'..i,center+V(math.cos(a)*2.02,math.sin(a)*2.02,-.302),center+V(math.cos(a+.04)*2.08,math.sin(a+.04)*2.08,-.303),.024,.016,RGB(221,211,204),METAL)
 end
 -- Two raised rear leather loops are hollow and visibly stand off the shell.
 disc(b,'RearArmorInset',C(center+V(0,0,.19)),3.95,.08,RGB(91,109,128))
 local leather=RGB(92,56,33)
 for _,side in ipairs({-1,1}) do
  local x=side*.79
  b:line('LeatherStrapUpper'..side,V(x,2.98,.28),V(x,2.89,.68),.24,.20,leather,Enum.Material.Fabric)
  b:line('LeatherStrapMiddle'..side,V(x,2.89,.68),V(x,1.98,.68),.24,.20,leather,Enum.Material.Fabric)
  b:line('LeatherStrapLower'..side,V(x,1.98,.68),V(x,1.89,.28),.24,.20,leather,Enum.Material.Fabric)
  for _,y in ipairs({1.89,2.98}) do
   b:box('StrapMount'..side..y,V(.45,.27,.09),C(x,y,.29),dark,METAL)
   for _,screw in ipairs({-.13,.13}) do disc(b,'RearStrapRivet'..side..y..screw,C(x+screw,y,.35),.075,.035,silver) end
  end
  b:box('StrapBuckle'..side,V(.35,.20,.07),C(x,2.5,.81),silver,METAL)
 end
 b.model:SetAttribute('ConcentricShieldBands',4)
 b.model:SetAttribute('StarPointCount',5)
 b.model:SetAttribute('RearOpenStrapCount',2)
 b.model:SetAttribute('RecognizableFeature','Convex red white blue concentric shield with raised five-point star')
 b.model:SetAttribute('Franchise','Captain America')
end

local builders={michael_jackson_glove=glove,tungs_bat=bat,moms_credit_card=creditCard,sonic_gold_ring=ring,captain_america_shield=shield}
function M.build(b,key)
 local builder=builders[key]
 if not builder then return false end
 builder(b)
 b.model:SetAttribute('ArtVersion',75)
 b.model:SetAttribute('ArtSource','NativeRobloxParts')
 return true
end
return M
