-- Cosmetic-only Ki Blast / Spinjitzu effects. Server spherecasts own every hit.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local M={}
local sessions=setmetatable({},{__mode='k'})
local SUPPORTED={lightning=true,slam=true,kiblast=true,spinjitzu=true,kiProjectile=true,kiImpact=true,spinjitzuActive=true,spinjitzuEnd=true}
local MAX_PARTS,MAX_DISTANCE=120,180
local function vector(v)return typeof(v)=='Vector3'and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<10000 and math.abs(v.Y)<10000 and math.abs(v.Z)<10000 end
local function bounded(value,fallback,lo,hi)
 local n=tonumber(value);if not n or n~=n or math.abs(n)==math.huge then n=fallback end
 return math.clamp(n,lo,hi)
end
function M.start(net,gui)
 if sessions[gui]then return sessions[gui]end
 local entries={};local count=0;local dead=false
 local function reduced()return gui:GetAttribute('OPReducedEffects')==true end
 local function drop(entry)
  if not entry or entry.dead then return end;entry.dead=true
  for _,part in ipairs(entry.parts)do part:Destroy();count=count-1 end
 end
 local function clear(kind,userId)
  for _,entry in ipairs(entries)do if entry.kind==kind and entry.userId==userId then drop(entry)end end
 end
 local function part(entry,name,color,ball)
  local p=Instance.new('Part');p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Material=Enum.Material.Neon;p.Color=color;p.Transparency=.15
  if ball then p.Shape=Enum.PartType.Ball end
  p.Size=Vector3.new(.2,.2,.2);p.Parent=workspace;entry.parts[#entry.parts+1]=p;count=count+1;return p
 end
 local function line(p,a,b,width)
  local length=(b-a).Magnitude
  if length<.001 then p.Transparency=1;return end
  p.Size=Vector3.new(width,width,length);p.CFrame=CFrame.lookAt((a+b)*.5,b)
 end
 local function near(origin)
  local camera=workspace.CurrentCamera
  return camera and(camera.CFrame.Position-origin).Magnitude<=MAX_DISTANCE
 end
 local function receive(kind,origin,radius,name,windup,color,userId,duration,direction,visualOrigin,targetId)
  if not SUPPORTED[kind]or not vector(origin)or type(userId)~='number'then return end
  if kind=='spinjitzuEnd'then clear('spinjitzuActive',userId);return end
  if kind=='kiImpact'then clear('kiProjectile',userId)end
  if kind=='lightning'then
   if type(windup)~='number'or type(targetId)~='number'then return end
   kind='lightningLock'
  end
  if kind=='slam'then
   if type(windup)=='number'then kind='slamWarning'
   else clear('slamWarning',userId);kind='slamRubble'end
  end
  if dead or not near(origin)then return end
  if kind=='kiProjectile'or kind=='spinjitzuActive'then clear(kind,userId)end
  local small=reduced();local n=kind=='kiProjectile'and 3 or(kind=='kiImpact'and(small and 4 or 8)or(kind=='spinjitzuActive'and(small and 6 or 12)or(small and 8 or 16)))
  local warning=kind=='kiblast'or kind=='spinjitzu'or kind=='slamWarning'or kind=='lightningLock'
  if warning and count+n>MAX_PARTS then
   -- Preserve readable warnings by retiring decorative effects first.
   for _,entry in ipairs(entries)do
    if entry.kind~='kiblast'and entry.kind~='spinjitzu'and entry.kind~='slamWarning'and entry.kind~='lightningLock'then drop(entry)end
    if count+n<=MAX_PARTS then break end
   end
   n=math.min(n,MAX_PARTS-count)
   if n<4 then return end
  end
  if count+n>MAX_PARTS then return end
  local life=kind=='slamRubble'and 1.5 or kind=='kiImpact'and .26 or warning and bounded(windup,.6,.1,1.5)or bounded(duration,1,.1,2)
  local entry={kind=kind,userId=userId,targetId=targetId,origin=origin,started=os.clock(),life=life,parts={},direction=vector(direction)and direction.Magnitude>.1 and direction.Magnitude<1.01 and direction.Unit or Vector3.new(0,0,-1),radius=bounded(radius,3,1,40)}
  local tint=typeof(color)=='Color3'and color or Color3.fromRGB(103,234,236)
  for i=1,n do
   local p=part(entry,'OPPower_'..kind..'_'..i,tint,kind=='kiProjectile'and i<3)
   if kind=='slamRubble'and i%2==0 then p.Material=Enum.Material.Slate;p.Color=Color3.fromRGB(97,84,68)end
  end
  entries[#entries+1]=entry
 end
 local fxConnection=net:WaitForChild('FX').OnClientEvent:Connect(receive)
 local renderConnection=Run.RenderStepped:Connect(function()
  local now=os.clock()
  for i=#entries,1,-1 do
   local e=entries[i];local age=now-e.started
   if e.dead or age>=e.life or not near(e.origin)then drop(e);table.remove(entries,i)
   elseif e.kind=='slamRubble'then
    local fade=math.clamp((age-.65)/.85,0,1);local rise=math.min(1,age/.16)
    for j,p in ipairs(e.parts)do
     local angle=j/#e.parts*math.pi*2;local radius=2+(j%4)*1.45
     local floor=e.origin-Vector3.new(0,2.65,0)
     if j%2==0 then
      local size=.65+(j%3)*.28;p.Size=Vector3.new(size,size*(.7+(j%2)*.3),size)
      p.CFrame=CFrame.new(floor+Vector3.new(math.cos(angle)*radius,(.3+(j%3)*.35)*rise-fade*.55,math.sin(angle)*radius))*CFrame.Angles(j*.31,angle,j*.17)
     else
      local a=floor+Vector3.new(math.cos(angle)*.7,.08,math.sin(angle)*.7)
      local b=floor+Vector3.new(math.cos(angle+.12)*radius,.08,math.sin(angle+.12)*radius)
      line(p,a,b,.12*(1-fade)+.02)
     end
     p.Transparency=fade
    end
   elseif e.kind=='kiProjectile'then
    local center=e.origin+e.direction*math.min(e.radius,70*age)
    for j,p in ipairs(e.parts)do
     if j==3 then line(p,center-e.direction*.5,center-e.direction*5,.35);p.Transparency=.4
     else local r=j==1 and 1.5 or 2.1;p.Size=Vector3.new(r,r,r);p.CFrame=CFrame.new(center);p.Transparency=j==2 and .65 or .12 end
    end
   elseif e.kind=='spinjitzuActive'then
    local player=Players:GetPlayerByUserId(e.userId)
    local root=player and player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if not root then drop(e)
    else
     local origin=root.Position-Vector3.new(0,2.7,0);local n=#e.parts
     for j,p in ipairs(e.parts)do
      local t=(j-1)/n;local angle=t*math.pi*4+age*12
      local nextT=t+1/n;local radiusA=1.5+t*3.8;local radiusB=1.5+nextT*3.8
      local a=origin+Vector3.new(math.cos(angle)*radiusA,t*6,math.sin(angle)*radiusA)
      local b=origin+Vector3.new(math.cos(angle+math.pi*4/n)*radiusB,nextT*6,math.sin(angle+math.pi*4/n)*radiusB)
      line(p,a,b,.18);p.Transparency=.18+math.min(.5,age/e.life*.35)
     end
    end
   elseif e.kind=='kiImpact'then
    local t=age/e.life
    for j,p in ipairs(e.parts)do
     local angle=j/#e.parts*math.pi*2;local direction=Vector3.new(math.cos(angle),.2+((j%3)/3),math.sin(angle))
     line(p,e.origin+direction*(.5+t*e.radius*.35),e.origin+direction*(1+t*e.radius*.85),.15*(1-t)+.03);p.Transparency=t
    end
   else
    local radius=e.kind=='kiblast'and(1.1+age*.4)or e.radius
    local center=e.origin
    if e.kind=='lightningLock'then
     local target=Players:GetPlayerByUserId(e.targetId)
     local targetRoot=target and target.Character and target.Character:FindFirstChild('HumanoidRootPart')
     if not targetRoot then drop(e);center=nil
     else center=targetRoot.Position end
    end
    if center then
     local origin=center-Vector3.new(0,2.7,0);local n=#e.parts
     for j,p in ipairs(e.parts)do
      local a=(j-1)/n*math.pi*2;local b=j/n*math.pi*2
      line(p,origin+Vector3.new(math.cos(a)*radius,.12,math.sin(a)*radius),origin+Vector3.new(math.cos(b)*radius,.12,math.sin(b)*radius),.13)
      p.Transparency=.2
     end
    end
   end
  end
 end)
 local session={}
 function session.destroy()
  if dead then return end;dead=true;fxConnection:Disconnect();renderConnection:Disconnect()
  for _,entry in ipairs(entries)do drop(entry)end;table.clear(entries);sessions[gui]=nil
 end
 sessions[gui]=session;return session
end
return M
