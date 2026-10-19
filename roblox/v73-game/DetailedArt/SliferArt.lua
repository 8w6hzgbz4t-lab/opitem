-- Native, decorative Slifer geometry. Its original statue site stays outside play.
-- Motion metadata is consumed by the client; no physics or server animation runs.
local P=require(script.Parent.Primitives)
local M={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local rgb=Color3.fromRGB
local crimson,scarlet,shadow=rgb(171,29,43),rgb(228,52,58),rgb(79,15,31)
local belly,gold,ivory=rgb(213,148,102),rgb(255,211,72),rgb(246,229,192)
local metal,plastic,neon=Enum.Material.Metal,Enum.Material.SmoothPlastic,Enum.Material.Neon
local function tagged(part,group)
 if part then part:SetAttribute('SliferMotionGroup',group) end
 return part
end
local function frameAlong(mid,direction,radial)
 local up=direction.Unit
 local back=radial-up*radial:Dot(up)
 if back.Magnitude<.001 then back=V(0,0,1)-up*up.Z end
 back=back.Unit
 local right=up:Cross(back).Unit
 return CFrame.fromMatrix(mid,right,up,right:Cross(up).Unit)
end
function M.create(parent)
 -- Former godSlifer statue was rooted at (-105,34,155). Lift the coils so the
 -- entire animated silhouette clears the perimeter, and face the arena (-Z).
 local origin=V(-105,63,155)
 local b=P.new(parent,{name='SliferAnimatedLandmark',alignBase=false,cframe=C(origin),partBudget=480})
 local points,segments={},38
 for i=0,segments do
  local t=i/segments;local angle=t*math.pi*3.1
  local radius=8.8+math.sin(t*math.pi)*3.1+t*1.8
  points[i+1]=V(math.cos(angle)*radius,-27+t*54,math.sin(angle)*radius)
 end
 for i=1,segments do
  local t=i/segments;local first,last=points[i],points[i+1]
  local mid=(first+last)*.5;local along=last-first
  local radius=.23+2.05*math.min(1,t*4)
  local cf=frameAlong(mid,along,V(mid.X,0,mid.Z))
  local group='Body'..i
  tagged(b:ball('CoilScale_'..i,V(radius*2,along.Magnitude+1.2,radius*2.12),cf,i%3==0 and scarlet or crimson,plastic),group)
  tagged(b:ball('BellyPlate_'..i,V(radius*1.5,along.Magnitude+.5,.22),cf*C(0,0,-radius*.99),belly,metal),group)
  if i>3 then
   tagged(b:wedge('BackSpine_'..i,V(.7,1.7+radius*.45,.8),cf*C(0,0,radius+.6)*A(math.pi/2,0,0),scarlet,metal),group)
   for _,side in ipairs({-1,1}) do
    tagged(b:line('ScaleEdge_'..i..'_'..side,cf*V(side*radius*.72,-along.Magnitude*.24,-radius*.75),cf*V(side*radius*.72,along.Magnitude*.24,-radius*.75),.1,.12,shadow,metal),group)
   end
  end
 end
 -- A single head with Slifer's two stacked mouths, rather than a head on each end.
 local head=C(points[#points]+V(0,2,-1))
 local function hbox(name,size,cf,color,mat)
  return tagged(b:box(name,size,head*cf,color,mat or plastic),'Head')
 end
 local function hball(name,size,cf,color,mat)
  return tagged(b:ball(name,size,head*cf,color,mat or plastic),'Head')
 end
 local function hline(name,a,c,width,color,mat)
  return tagged(b:line(name,head*a,head*c,width,width,color,mat or metal),'Head')
 end
 local function htriangle(name,a,c,d,color,thickness)
  local before=#b.model:GetChildren()
  b:triangle(name,head*a,head*c,head*d,color,thickness or .22,metal)
  local children=b.model:GetChildren()
  for i=before+1,#children do tagged(children[i],'Head') end
 end
 hball('SliferCranium',V(7.2,5.1,8),C(0,1.6,.6),crimson)
 hbox('UpperMouthCavity',V(5.3,1.25,3.6),C(0,1.5,-4),shadow)
 hbox('UpperSnoutBridge',V(6.3,1.1,4.2),C(0,2.75,-3.5),scarlet)
 hbox('UpperMouthLowerJaw',V(5.6,.65,4),C(0,.48,-3.9),crimson)
 hbox('LowerMouthCavity',V(6.1,1.9,5.3),C(0,-1.1,-3.35),shadow)
 hball('LowerJawMandible',V(6.3,.8,5.4),C(0,-2.45,-3.4),crimson)
 hball('LowerJawChin',V(4.9,1.2,3.2),C(0,-2.7,-2),scarlet)
 for _,side in ipairs({-1,1}) do
  hball('ArmoredCheek_'..side,V(1.8,4.4,5.6),C(side*2.9,.1,-.65),crimson)
  hbox('CheekRidge_'..side,V(.62,.7,5.8),C(side*3.65,1,-.8)*A(0,side*.12,side*.16),scarlet,metal)
  hball('GoldenEye_'..side,V(.65,.72,1.3),C(side*3.38,2.7,-1.9),gold,neon)
  hball('SlitPupil_'..side,V(.13,.59,.56),C(side*3.68,2.69,-2.05),shadow)
  hbox('EyeBrow_'..side,V(.7,.35,2.6),C(side*3.35,3.24,-1.8)*A(0,0,side*-.18),scarlet,metal)
  -- Curved crimson crown horns and smaller cheek horns.
  hline('CrownHornRoot_'..side,V(side*2.35,3.6,1),V(side*3.05,6.8,2.4),1.1,scarlet)
  hline('CrownHornBlade_'..side,V(side*3.05,6.8,2.4),V(side*3.65,9.4,4.3),.7,crimson)
  htriangle('CrownHornTip_'..side,V(side*3.2,8.5,3.7),V(side*4.05,8.5,3.7),V(side*4.15,11,5.4),scarlet,.65)
  hline('CheekHorn_'..side,V(side*3.5,.5,1),V(side*5.8,2.6,4.8),.65,scarlet)
  hline('JawWhisker_'..side,V(side*2.75,-2,-1.4),V(side*5.1,-1.8,.5),.22,belly)
  for row=1,2 do
   local y=row==1 and 1.82 or -.25
   local width=row==1 and 1.7 or 2.2
   for tooth=0,3 do
    local x=side*(.45+tooth*width/3)
    htriangle('Mouth'..row..'UpperFang_'..side..'_'..tooth,V(x-.16,y+.38,-5.6),V(x+.16,y+.38,-5.6),V(x,y-.5,-5.6),ivory)
    htriangle('Mouth'..row..'LowerFang_'..side..'_'..tooth,V(x-.14,y-1.6,-5.6),V(x+.14,y-1.6,-5.6),V(x,y-1.08,-5.6),ivory)
   end
  end
  hball('Nostril_'..side,V(.6,.2,.45),C(side*1.45,3.32,-4.6),shadow)
 end
 for i=0,3 do
  hbox('ForeheadArmor_'..i,V(3.6-i*.5,.35,1.1),C(0,4.1+i*.17,.2+i*1.1),scarlet,metal)
 end
 -- Red membranous wings hinge at the upper torso, with clearly visible bones.
 local shoulder=head* C(0,-5.5,2)
 for _,side in ipairs({-1,1}) do
  local group='Wing'..side
  local hinge=shoulder*C(side*2.2,0,0)
  local wingStart=#b.model:GetChildren()
  local root=V(side*2.2,0,0)
  local elbow=V(side*10.5,5.8,1.3)
  local tip=V(side*21,7.1,6)
  local lower=V(side*14,-6.2,8)
  b:triangle('WingUpperMembrane_'..side,shoulder*root,shoulder*elbow,shoulder*lower,crimson,.25,plastic)
  b:triangle('WingOuterMembrane_'..side,shoulder*elbow,shoulder*tip,shoulder*lower,scarlet,.25,plastic)
  b:triangle('WingLowerMembrane_'..side,shoulder*root,shoulder*lower,shoulder*V(side*6,-8.5,4),crimson,.25,plastic)
  tagged(b:line('WingShoulderBone_'..side,shoulder*root,shoulder*elbow,.65,.65,scarlet,metal),group)
  tagged(b:line('WingLeadingBone_'..side,shoulder*elbow,shoulder*tip,.48,.48,belly,metal),group)
  for rib=0,3 do
   local endPoint=elbow:Lerp(tip,rib/3):Lerp(lower,.84)
   tagged(b:line('WingFinger_'..side..'_'..rib,shoulder*elbow,shoulder*endPoint,.24,.24,scarlet,metal),group)
  end
  local children=b.model:GetChildren()
  for i=wingStart+1,#children do
   tagged(children[i],group)
   children[i]:SetAttribute('SliferHinge',hinge)
  end
  -- Small clawed forelimbs distinguish the winged dragon from an ordinary snake.
  local armA=head*V(side*2.1,-5.7,.6)
  local armB=head*V(side*5.4,-8.6,-.1)
  local armC=head*V(side*4.8,-10.1,-2)
  tagged(b:line('Forearm_'..side,armA,armB,.9,.9,crimson,plastic),'Head')
  tagged(b:line('ClawedWrist_'..side,armB,armC,.68,.68,scarlet,plastic),'Head')
  for claw=0,2 do
   tagged(b:line('IvoryClaw_'..side..'_'..claw,armC+V((claw-1)*.5,0,0),armC+V((claw-1)*.7,-1.2,-.8),.22,.22,ivory,metal),'Head')
  end
 end
 -- Hinges are stored in the original model-local frame, before its world pivot.
 for _,part in ipairs(b.model:GetChildren()) do
  if part:GetAttribute('SliferMotionGroup')=='Head' then part:SetAttribute('SliferHinge',head) end
 end
 local model=b:finish()
 model:SetAttribute('OrbitOrigin',origin)
 model:SetAttribute('OrbitPeriod',36)
 model:SetAttribute('FormerStatueOrigin',V(-105,34,155))
 model:SetAttribute('DecorativeOnly',true)
 model:SetAttribute('SliferArtVersion',2)
 return model
end
return M
