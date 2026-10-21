-- Actual new power renderer with controlled camera, characters and frame clock.
local Mock=dofile('tools/roblox_mock.lua')
local now=100
os.clock=function()return now end
local function signal()
 local object={listeners={}}
 function object:Connect(callback)
  local c={Connected=true,callback=callback};function c:Disconnect()self.Connected=false end
  self.listeners[#self.listeners+1]=c;return c
 end
 function object:Fire(...)for _,c in ipairs(self.listeners)do if c.Connected then c.callback(...)end end end
 return object
end
local fxSignal,render=signal(),signal()
workspace=Instance.new('Folder');workspace.Name='Workspace';workspace.CurrentCamera={CFrame=CFrame.new(0,8,0)}
local player=Instance.new('Folder');player.UserId=77;player.Character=Instance.new('Model');player.Character.Name='Character'
local root=Instance.new('Part',player.Character);root.Name='HumanoidRootPart';root.CFrame=CFrame.new(0,4,0)
local gui=Instance.new('Folder');gui.Name='PlayerGui'
game={GetService=function(_,name)
 if name=='Players'then return{GetPlayerByUserId=function(_,id)return id==77 and player or nil end}end
 if name=='RunService'then return{RenderStepped=render}end
 error('Unexpected renderer service '..name)
end}
local Effects=Mock.loadModule((arg[1]or'roblox/v78-game')..'/PowerEffects.lua')
local net={FX={OnClientEvent=fxSignal}}
function net:WaitForChild(name)return assert(self[name],name)end
local session=Effects.start(net,gui)
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function parts()
 local result={};for _,p in ipairs(workspace:GetDescendants())do if p:IsA('BasePart')then result[#result+1]=p end end;return result
end
local function safe()
 local all=parts();check(#all>0 and #all<=120,'Native power parts bounded')
 for _,p in ipairs(all)do
  check(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and p.CastShadow==false,'Power particles never affect physics')
  for _,n in ipairs({p.CFrame:GetComponents()})do check(n==n and math.abs(n)<10000,'Power transforms stay finite')end
  check(p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0,'Power parts retain positive size')
 end
 return #all
end
local origin=Vector3.new(0,4,-10);local direction=Vector3.new(0,0,-1)
local function event(kind,id,duration,dir,radius)
 fxSignal:Fire(kind,origin,radius or 8,kind,.6,nil,id or 77,duration or 1.5,dir or direction)
end
local function tick(dt)now=now+dt;render:Fire()end
local function clear()tick(3);check(#parts()==0,'Expired particle casts clean themselves')end
check(Effects.start(net,gui)==session and #fxSignal.listeners==1,'Repeated start installs one listener')
event('tag');check(#parts()==0,'Old powers are not duplicated by new module')
fxSignal:Fire('lightning',origin,4,'Lightning',1.2,nil,77,.85,direction,nil,77)
tick(.1);check(safe()==16,'Auto-lock has a visible target warning')
local first=parts()[1].Position;root.CFrame=CFrame.new(20,4,0);tick(.1)
check((parts()[1].Position-first).Magnitude>10,'Lightning lock warning follows its target character')
clear();root.CFrame=CFrame.new(0,4,0)
event('kiblast');tick(.1);local warning=safe();check(warning==16,'Normal charge warning has bounded ring');clear()
event('kiProjectile',77,.6,direction,40);tick(.1);check(safe()==3,'Ki projectile uses two glows and a trail')
local projectile=parts();check(projectile[1].Position.Z<origin.Z-6,'Ki projectile moves at synchronized speed')
event('kiImpact');tick(.01);check(safe()==8,'Impact replaces projectile particles');clear()
event('slam');tick(.1);check(safe()==16,'Ground Slam gives a clear bounded warning');clear()
fxSignal:Fire('slam',origin,8,'Ground Slam',nil,nil,77,0,direction)
tick(.2);check(safe()==16,'Ground Slam creates cosmetic rubble and crack spokes')
local rocks=0
for _,p in ipairs(parts())do if p.Material==Enum.Material.Slate then rocks=rocks+1;check(p.Position.Y>origin.Y-2.7,'Rubble rises visibly above the ground')end end
check(rocks==8,'Ground Slam uses eight distinct stone chunks')
tick(.8);for _,p in ipairs(parts())do check(p.Transparency>0,'Rubble and cracks fade after impact')end
clear()
event('spinjitzuActive');tick(.1);local tornado=safe();check(tornado==12,'Normal tornado uses twelve helix segments')
local old=parts()[1].CFrame
root.CFrame=CFrame.new(20,4,0);tick(.1);check((parts()[1].Position-old.Position).Magnitude>10,'Tornado follows actual character position')
event('spinjitzuEnd');check(#parts()==0,'Server cancellation immediately clears tornado');clear()
root.CFrame=CFrame.new(0,4,0)
gui:SetAttribute('OPReducedEffects',true)
event('kiblast');tick(.1);check(safe()==8,'Reduced mode keeps a simpler visible charge warning');clear()
event('spinjitzuActive');tick(.1);check(safe()==6,'Reduced mode halves tornado geometry');clear()
event('kiImpact');tick(.01);check(safe()==4,'Reduced mode halves impact geometry');clear()
gui:SetAttribute('OPReducedEffects',false)
for id=77,90 do event('kiblast',id)end
tick(.01);check(safe()<=120,'Whole renderer obeys shared part budget under bursts');clear()
workspace.CurrentCamera.CFrame=CFrame.new(1000,8,0);event('kiblast');check(#parts()==0,'Distant casts allocate no parts')
workspace.CurrentCamera.CFrame=CFrame.new(0,8,0)
fxSignal:Fire('kiblast',{X=0,Y=4,Z=-10},8,'bad',.6,nil,77,1,direction)
check(#parts()==0,'Non-vector origin rejected')
event('kiProjectile',77,.5,Vector3.zero,0/0);tick(.1);safe();clear()
event('spinjitzuActive');tick(.1);safe();player.Character=nil;tick(.1)
check(#parts()==0,'Lost character removes tornado particles')
event('kiblast');tick(.1);safe();session.destroy()
check(#parts()==0 and not fxSignal.listeners[1].Connected and not render.listeners[1].Connected,'Destroy clears every particle and listener')
event('kiblast');check(#parts()==0,'Destroyed renderer cannot allocate effects')
local report={passed=true,assertions=checks,normal_warning_parts=warning,normal_tornado_parts=tornado,
 global_part_budget=120,reduced_effects_verified=true,cleanup_verified=true,finite_noninteractive_geometry=true,
 actual_module='PowerEffects.lua',studio_rendering_tested=false}
local f=assert(io.open(arg[2]or'/tmp/opitem-v78-power-effects.json','w'));f:write(Mock.json(report));f:close()
print('PASS '..checks..' new power visual assertions; actual projectile/tornado renderer, reduction, bounds and cleanup')
