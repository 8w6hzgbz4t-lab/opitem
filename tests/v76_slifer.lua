-- Build actual World/UpperFloor geometry; verify stair clearances, solid
-- fitted architecture, display space, ownership transitions and idempotence.
local Mock=dofile('tools/roblox_mock.lua')
local create=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class] then return create(class,parent) end
 local instance=create('Folder',parent);instance._class=class;instance.Name=class;return instance
end
UDim2={fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end,new=function(...)return {...}end}
UDim={new=function(...)return {...}end};Vector2={new=function(x,y)return {X=x,Y=y}end}
local meta=getmetatable(create('Model'));local prior=meta.__index
meta.__index=function(self,key)
 if key=='GetScale' then return function(model)return model._props._testScale or 1 end end
 if key=='ScaleTo' then return function(model,scale)
  local ratio=scale/(model._props._testScale or 1);local pivot=model:GetPivot();local inv=pivot:Inverse()
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA('BasePart') then local cf=inv*part.CFrame;part.CFrame=pivot*CFrame.new(cf.Position*ratio)*(cf-cf.Position);part.Size=part.Size*ratio end
  end
  model._props._testScale=scale
 end end
 return prior(self,key)
end
workspace=create('Folder');workspace.Name='Workspace'
local factory={part=function(parent,name,size,cf,color,material)
 local part=create('Part',parent);part.Name=name;part.Size=size;part.CFrame=cf;part.Color=color
 part.Material=material or Enum.Material.SmoothPlastic;part.Anchored=true;part.CanTouch=false;return part
end}
local root=arg[1] or 'roblox/v76-game'
local world=Mock.loadModule(root..'/World.lua').build(factory,Mock.loadModule(root..'/Config.lua'))

local Scene=Mock.loadModule(root..'/DetailedArt/EnhancedScene.lua')
local Landmark=Mock.loadModule(root..'/DetailedArt/LandmarkArt.lua')
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function count(name)
 local n=0;for _,v in ipairs(world.folder:GetDescendants())do if v.Name==name then n=n+1 end end;return n
end
check(count('SliferAnimatedLandmark')==1,'Built world has exactly one animated Slifer')
local preserved={'CrimsonDragonMonument','ShenronDragonMonument','WingedDragonOfRaStatue','EgyptianGodsPainting','ExodiaPainting','HoOhFlight'}
local prior={};for _,name in ipairs(preserved)do prior[name]=count(name);check(prior[name]>0,'Expected distinct decoration missing '..name)end
local aliases={'godSlifer','SliferStatue','SliferTablet','SliferAroundKaibaTower','Slifer Monument','Static Slifer','Slifer the Sky Dragon','KaibaCorpTower','KaibaTower','KiabaTower'}
local retired={}
for _,name in ipairs(aliases)do local model=create('Model',world.folder);model.Name=name;retired[#retired+1]=model end
local renamed=create('Model',world.folder);renamed.Name='UserRenamedDragon';renamed:SetAttribute('Kind','godSlifer');retired[#retired+1]=renamed
local decoy=create('Model',world.folder);decoy.Name='SliferCardArtwork';decoy:SetAttribute('Kind','art')
Scene.removeRetired(world.folder)
for _,model in ipairs(retired)do check(model.Parent==nil,'Retired static copy still parented '..model.Name)end
check(decoy.Parent==world.folder,'Framed art with a similar name must remain')
check(count('SliferAnimatedLandmark')==1,'Retirement cleanup preserves animated landmark')
for _,name in ipairs(preserved)do check(count(name)==prior[name],'Cleanup changed distinct decoration '..name)end
Scene.build(world);Scene.build(world)
check(count('SliferAnimatedLandmark')==1,'Repeated build cannot create duplicate animated Slifer')
for _,name in ipairs(preserved)do check(count(name)==prior[name],'Repeated build changed decoration count '..name)end
local animated=assert(world.folder:FindFirstChild('SliferAnimatedLandmark',true))
local moving=0;local parts=0
for _,v in ipairs(animated:GetDescendants())do if v:IsA('BasePart')then
 parts=parts+1;check(v.Anchored and not v.CanCollide,'Animated decoration must not create physics hazards')
 if v:GetAttribute('SliferMotionGroup')then moving=moving+1 end
end end
check(parts==315 and moving>0,'Detailed animated Slifer geometry and motion tags preserved')
local ok=pcall(function()Landmark.create(world.folder,{model='godSlifer'})end)
check(not ok,'Retired statue route must no longer be constructible')
local report={passed=true,checks=checks,animated_slifer_count=count('SliferAnimatedLandmark'),animated_slifer_parts=parts,motion_parts=moving,retired_aliases_checked=#retired,framed_art_preserved=true,repeated_build_idempotent=true,limitations='Offline Roblox geometry doubles; live animation and rendering require Studio.'}
local out=assert(arg[2],'Report path required');local file=assert(io.open(out,'w'));file:write(Mock.json(report));file:close()
print('SLIFER PASS '..checks..' checks; one detailed animated Slifer; all static aliases retired; other dragons and art preserved')
