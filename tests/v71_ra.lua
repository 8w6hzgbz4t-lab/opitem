-- Actual v70/v71 World builders: only the requested Ra monument may change.
-- Offline geometry contracts; Studio lighting and physics need a live playtest.
local Mock=dofile('tools/roblox_mock.lua')
local create=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class]then return create(class,parent)end
 local instance=create('Folder',parent);instance._class=class;instance.Name=class;return instance
end
UDim2={fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end,new=function(...)return {...}end}
UDim={new=function(...)return {...}end}
Vector2={new=function(x,y)return {X=x,Y=y}end}
local meta=getmetatable(create('Model'));local previousIndex=meta.__index
meta.__index=function(self,key)
 if key=='GetScale'then return function(model)return model._props._testScale or 1 end end
 if key=='ScaleTo'then return function(model,scale)
  local ratio=scale/(model._props._testScale or 1);local pivot=model:GetPivot();local inverse=pivot:Inverse()
  local function scaled(cf)local frame=inverse*cf;return pivot*CFrame.new(frame.Position*ratio)*(frame-frame.Position)end
  for _,part in ipairs(model:GetDescendants())do
   if part:IsA('BasePart')then part.CFrame=scaled(part.CFrame);part.Size=part.Size*ratio
   elseif part:IsA('Model')and part._props._pivot then part._props._pivot=scaled(part._props._pivot)end
  end
  model._props._testScale=scale
 end end
 return previousIndex(self,key)
end
workspace=create('Folder');workspace.Name='Workspace'
local factory={part=function(parent,name,size,cf,color,material)
 local p=create('Part',parent);p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanTouch=false;return p
end}
local baselineRoot=arg[1]or'roblox/v70-game';local stagedRoot=arg[2]or'roblox/v71-game'
local out=arg[3]or'/tmp/opitem-v71-ra'
local function build(root)return Mock.loadModule(root..'/World.lua').build(factory,Mock.loadModule(root..'/Config.lua'))end
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local excluded={WingedDragonOfRaStatue=true,WingedDragonOfRaPedestal=true}
local function protected(world)
 local rows={}
 for _,part in ipairs(world.folder:GetDescendants())do
  if part:IsA('BasePart')then
   local ancestor=part;local skip=false;local path={}
   while ancestor and ancestor~=world.folder do if excluded[ancestor.Name]then skip=true end;table.insert(path,1,ancestor.Name);ancestor=ancestor.Parent end
   if not skip then rows[#rows+1]=Mock.json({path=table.concat(path,'/'),class=part._class,size={part.Size.X,part.Size.Y,part.Size.Z},
    cf={part.CFrame:GetComponents()},color={part.Color.R,part.Color.G,part.Color.B},material=part.Material,shape=part.Shape,
    transparency=part.Transparency,collide=part.CanCollide,touch=part.CanTouch,query=part.CanQuery})end
  end
 end
 table.sort(rows);return table.concat(rows,'\n'),#rows
end
local baseline=build(baselineRoot);local old,oldCount=protected(baseline)
local final=build(stagedRoot);local current,currentCount=protected(final)
check(old==current and oldCount==currentCount,'Unrequested scenery changed outside the new Ra monument')
local function named(parent,name)local result={};for _,v in ipairs(parent:GetDescendants())do if v.Name==name then result[#result+1]=v end end;return result end
local function raContracts(world)
 local statues=named(world.folder,'WingedDragonOfRaStatue');check(#statues==1,'Exactly one Ra statue is required')
 check(#named(world.folder,'WingedDragonOfRaPedestal')==1,'Exactly one Ra pedestal is required')
 local ra=statues[1];check(ra:GetAttribute('DecorativeOnly')and ra:GetAttribute('Kind')==nil,'Ra must not register as a carryable item')
 check(ra:GetAttribute('CharacterName')=='The Winged Dragon of Ra','Ra needs a recognizable identity')
 check(ra:GetAttribute('PartCount')>=400 and ra:GetAttribute('PartCount')<=500,'Detailed Ra must fit its geometry budget')
 check(ra:GetPivot().Position.X==75 and ra:GetPivot().Position.Z==155,'Ra moved into the arena or gallery')
 local lo,hi=Mock.bounds(ra)
 check(lo.Y>=34 and hi.Y<65 and hi.Y>60,'Ra must rise above the 24-stud walls and remain below the dome')
 for _,name in ipairs({'RaRubyEye-1','RaRubyEye1','RaHookedBeak_A','RaRoyalHorn-1Segment1','RaSolarHalo_0','RaWingInlaidChevron-10','RaTalon-10_A'})do
  check(ra:FindFirstChild(name)~=nil,'Ra is missing a required detail: '..name)
 end
 for _,name in ipairs({'WingedDragonOfRaStatue','WingedDragonOfRaPedestal'})do
  for _,part in ipairs(named(world.folder,name)[1]:GetDescendants())do
   if part:IsA('BasePart')then check(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,'Ra art may not block gameplay')end
  end
 end
 local slifer=named(world.folder,'SliferAnimatedLandmark');check(#slifer==1,'Animated Slifer must remain present')
 local origin=slifer[1]:GetAttribute('OrbitOrigin');check(origin.X==-105 and origin.Y==63 and origin.Z==155,'Animated Slifer moved')
 return ra
end
local ra=raContracts(final)
local function write(path,model)local f=assert(io.open(path,'w'));f:write(Mock.json(Mock.record(model)));f:close()end
write(out..'-statue.json',ra)
local complete=create('Model');complete.Name='The Winged Dragon of Ra Monument'
local root=create('Part',complete);root.Name='Root';root.Transparency=1;root.Size=Vector3.new(.1,.1,.1);root.CFrame=CFrame.new();root.Anchored=true
root.CanCollide=false;root.CanTouch=false;root.CanQuery=false;complete.PrimaryPart=root
ra.Parent=complete;final.folder.EnhancedScene.WingedDragonOfRaPedestal.Parent=complete
write(out..'-monument.json',complete)
-- Restore these models before verifying a repeated scene build.
ra.Parent=final.folder.EnhancedScene;complete.WingedDragonOfRaPedestal.Parent=final.folder.EnhancedScene
local scene=Mock.loadModule(stagedRoot..'/DetailedArt/EnhancedScene.lua');scene.build(final);raContracts(final)
check(protected(final)==old,'Repeated scene build moved existing protected geometry')
print(string.format('PASS: %d Ra checks; %d protected parts unchanged; exactly one detailed, noninteractive Ra; Slifer preserved; rebuild stable',checks,oldCount))
print('Recorded '..out..'-statue.json and '..out..'-monument.json')
