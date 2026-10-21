-- Small, local Millennium Rod effects. Server events decide all gameplay outcomes.
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local M={}
local V,C=Vector3.new,CFrame.new
local GOLD=Color3.fromRGB(255,210,98)
local function vector(v)
 return typeof(v)=='Vector3' and v.X==v.X and v.Y==v.Y and v.Z==v.Z
  and math.abs(v.X)<100000 and math.abs(v.Y)<100000 and math.abs(v.Z)<100000
end
function M.start(net,player)
 local folder=Instance.new('Folder');folder.Name='DeveloperSpellEffects';folder.Parent=workspace
 local function part(name,size,cf,color,life)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or GOLD
  p.Material=Enum.Material.Neon;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
  p.CastShadow=false;p.Transparency=.22;p.Parent=folder
  Tween:Create(p,TweenInfo.new(life or .7),{Transparency=1}):Play();Debris:AddItem(p,(life or .7)+.05)
  return p
 end
 local function line(a,b,width,color,life)
  local delta=b-a;if delta.Magnitude<.001 then return end
  return part('MillenniumRodLight',V(width,width,delta.Magnitude),CFrame.lookAt((a+b)*.5,b),color,life)
 end
 local function ring(center,radius,count,life)
  for i=0,count-1 do
   local a,b=i*math.pi*2/count,(i+1)*math.pi*2/count
   line(center+V(math.cos(a)*radius,0,math.sin(a)*radius),center+V(math.cos(b)*radius,0,math.sin(b)*radius),.12,GOLD,life)
  end
 end
 local connection=net.FX.OnClientEvent:Connect(function(kind,origin,radius,name,windup,color,userId,duration,direction,rodOrigin)
  if not vector(origin) then return end
  local camera=workspace.CurrentCamera
  if camera and (camera.CFrame.Position-origin).Magnitude>240 then return end
  local playerGui=player:FindFirstChild('PlayerGui')
  local reduced=playerGui and playerGui:GetAttribute('OPReducedEffects')==true or false
  if vector(rodOrigin) then
   line(rodOrigin,origin,.16,reduced and GOLD or color or GOLD,.4)
   if not reduced then ring(rodOrigin,.4,8,.35) end
  end
  if kind~='developerRoyalSeal' then return end
  radius=type(radius)=='number' and math.clamp(radius,1,18) or 18
  local center=origin-V(0,2.6,0)
  ring(center,radius,reduced and 16 or 28,windup or .75)
  if windup then return end
  ring(center+V(0,.08,0),radius*.68,reduced and 12 or 20,.8)
  -- Eye of the Millennium: almond outline and central diamond on the seal floor.
  local left,right=center+V(-5,.2,0),center+V(5,.2,0)
  for _,side in ipairs({-1,1}) do
   local tip=center+V(0,.2,side*2.4)
   line(left,tip,.23,GOLD,.8);line(tip,right,.23,GOLD,.8)
  end
  local diamond={V(0,.2,-1.2),V(1.2,.2,0),V(0,.2,1.2),V(-1.2,.2,0)}
  for i=1,4 do line(center+diamond[i],center+diamond[i%4+1],.24,GOLD,.8) end
  if not reduced then
   for i=0,7 do
    local a=i*math.pi/4;local p=center+V(math.cos(a)*radius,.15,math.sin(a)*radius)
    line(p,p+V(0,2.2,0),.16,GOLD,.6)
   end
  end
 end)
 return {destroy=function()connection:Disconnect();folder:Destroy()end}
end
return M
