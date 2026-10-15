-- Actual v70 native geometry and extracted client animation, exercised offline.
local Mock=dofile('tools/roblox_mock.lua')
local root=arg[1] or 'roblox/v70-game'
local Slifer=Mock.loadModule(root..'/DetailedArt/SliferArt.lua')
local world=Instance.new('Folder');world.Name='OPItemWorld'
local scene=Instance.new('Folder');scene.Name='EnhancedScene';scene.Parent=world
local serpent=Slifer.create(scene)
assert(serpent.Name=='SliferAnimatedLandmark' and serpent:GetAttribute('DecorativeOnly'))
local origin=serpent:GetAttribute('OrbitOrigin')
assert(origin.X==-105 and origin.Z==155 and origin.Y==63,'Former statue site changed')
assert(serpent:FindFirstChild('SliferCranium') and not serpent:FindFirstChild('SerpentHead2'),'Slifer must have one head')
assert(serpent:FindFirstChild('UpperMouthCavity') and serpent:FindFirstChild('LowerMouthCavity'),'Two mouths missing')
assert(serpent:FindFirstChild('CrownHornTip_-1_A') and serpent:FindFirstChild('WingUpperMembrane_1_A'),'Crown/wings missing')
local parts=serpent:GetDescendants();assert(#parts<=480,'Decorative part budget exceeded')
local counts={}
for _,part in ipairs(parts) do
 assert(part:IsA('BasePart') and part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,'Decorative geometry affects play')
 local group=part:GetAttribute('SliferMotionGroup')
 if group then counts[group]=(counts[group] or 0)+1 end
 for _,number in ipairs({part.CFrame:GetComponents()}) do assert(number==number and math.abs(number)<1000,'Nonfinite geometry') end
end
assert(counts.Head>=60 and counts.Wing1>=10 and counts['Wing-1']>=10,'Articulated groups incomplete')
for i=1,38 do assert(counts['Body'..i] and counts['Body'..i]>=2,'Coil gap '..i) end
local lo,hi=Mock.bounds(serpent)
assert(lo.Y>33 and hi.Y<110,'Slifer should clear perimeter without leaving the dome')
assert(lo.Z>130 and hi.Z<184 and lo.X>-144 and hi.X<-71,'Slifer escaped former statue area')

local function signal()
 local s={connections={}}
 function s:Connect(callback)
  local connection={Connected=true,callback=callback}
  function connection:Disconnect()self.Connected=false end
  self.connections[#self.connections+1]=connection
  return connection
 end
 function s:Fire(...)
  for _,connection in ipairs(self.connections) do if connection.Connected then connection.callback(...) end end
 end
 return s
end
serpent.AncestryChanged=signal()
function serpent:IsDescendantOf(ancestor)
 local node=self.Parent
 while node do if node==ancestor then return true end;node=node.Parent end
 return false
end
world.Parent=Instance.new('Folder')
local run={RenderStepped=signal()}
local now=0
local workspace={CurrentCamera={CFrame=CFrame.new(-105,63,50)},GetServerTimeNow=function()return now end}
local env=setmetatable({world=world,workspace=workspace,Run=run,task={spawn=function(callback)callback()end},reduced=false},{__index=_G})
local file=assert(io.open(root..'/Client.lua'));local source=file:read('*a');file:close()
local start=assert(source:find('-- Slifer occupies its former statue site',1,true),'Client Slifer animation missing')
local chunk=assert(load(source:sub(start),'actual-client-slifer','t',env));chunk()
local callback=run.RenderStepped.connections[1];assert(callback and callback.Connected)
local original={};for _,part in ipairs(parts) do original[part]=part.CFrame end
run.RenderStepped:Fire(.001)
for _,part in ipairs(parts) do assert((part.Position-original[part].Position).Magnitude<1e-9,'Frame cap not respected') end
local function close(a,b,tolerance)
 local ac,bc={a:GetComponents()},{b:GetComponents()}
 for i=1,#ac do assert(math.abs(ac[i]-bc[i])<tolerance,'Pose mismatch component '..i) end
end
now=0;run.RenderStepped:Fire(1/30)
local first={};for _,part in ipairs(parts) do first[part]=part.CFrame end
for frame=1,360 do
 now=frame/10;run.RenderStepped:Fire(.1)
 for _,part in ipairs(parts) do
  for _,number in ipairs({part.CFrame:GetComponents()}) do assert(number==number and math.abs(number)<1000,'Animation produced invalid transform') end
  assert((part.Position-original[part].Position).Magnitude<8,'Animation drift escaped authored geometry')
 end
end
for _,part in ipairs(parts) do close(part.CFrame,first[part],1e-8) end
env.reduced=true;run.RenderStepped:Fire(1/30)
for _,part in ipairs(parts) do close(part.CFrame,original[part],1e-9) end
now=7;run.RenderStepped:Fire(.5)
for _,part in ipairs(parts) do close(part.CFrame,original[part],1e-9) end
env.reduced=false;workspace.CurrentCamera.CFrame=CFrame.new(2000,2000,2000);run.RenderStepped:Fire(.1)
for _,part in ipairs(parts) do close(part.CFrame,original[part],1e-9) end
workspace.CurrentCamera.CFrame=CFrame.new(-105,63,50);run.RenderStepped:Fire(.1)
assert((serpent.SliferCranium.Position-original[serpent.SliferCranium].Position).Magnitude>.01,'Near-camera animation did not resume')
serpent.Parent=nil;serpent.AncestryChanged:Fire()
assert(not callback.Connected and not serpent.AncestryChanged.connections[1].Connected,'Removed decoration retained render connections')
for _,part in ipairs(parts) do part.CFrame=original[part] end
local record=Mock.record(serpent)
local output=assert(io.open('/tmp/opitem-v70-slifer.json','w'));output:write(Mock.json(record));output:close()
print('PASS: '..#parts..' noninteractive parts; single two-mouth head; 38 connected coils; animated wings/head/body; 36-second loop closes; reduced effects rests; distant culling; cleanup disconnects')
print('Geometry recorded to /tmp/opitem-v70-slifer.json')
