-- Execute the actual world builder: cosmetic additions must preserve gameplay.
-- This offline mock checks geometry/instances, not Studio rendering or physics.
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
local baselineRoot=arg[1]or'roblox/v72-pre-polish'
local stagedRoot=arg[2]or'roblox/v72-game'
local out=arg[3]or'/tmp/opitem-v72-world.json'
local reportPath=arg[4]or'/tmp/opitem-v72-presentation.json'
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function named(parent,name)
 local result={};for _,v in ipairs(parent:GetDescendants())do if v.Name==name then result[#result+1]=v end end;return result
end
local function encode(value)
 if typeof(value)=='Instance'then return value:GetFullName()
 elseif typeof(value)=='Vector3' then return {value.X,value.Y,value.Z}
 elseif typeof(value)=='CFrame'then return {value:GetComponents()}
 elseif type(value)=='table'then local result={};for key,v in pairs(value)do if type(v)~='function'then result[key]=encode(v)end end;return result end
 return value
end
local additions={BasePresentation=true,PlazaPresentation=true}
local function tree(instance,excludeNew)
 local props={};for key,value in pairs(instance._props)do
  if key~='Parent'and type(value)~='function'then props[key]=encode(value)end
 end
 local children={};for _,child in ipairs(instance:GetChildren())do
  if not(excludeNew and instance.Name=='OPItemWorld'and additions[child.Name])then children[#children+1]=tree(child,excludeNew)end
 end
 return {class=instance._class,properties=props,attributes=encode(instance._attrs),children=children}
end
local function protected(world)return Mock.json(tree(world.folder,true))end
local function anchorSnapshot(world)
 local rows={}
 for i,base in ipairs(world.bases)do
  local row={cf=encode(base.cf),spawn=encode(base.spawn),slots={},anchors={}}
  for _,cf in ipairs(base.slots)do row.slots[#row.slots+1]=encode(cf)end
  for _,key in ipairs({'gate','home','lock','upgrade','sign','bank'})do row.anchors[key]=tree(base[key],false)end
  rows[i]=row
 end
 return Mock.json(rows)
end
local function contracts(world)
 check(#world.bases==8,'Eight original bases must remain')
 for _,base in ipairs(world.bases)do
  check(#base.slots==8,'Eight original item slots must remain per base')
  check(base.lock.Size.X==46 and base.lock.Size.Y<.2,'Full-width flat green entrance line changed')
  local p=base.cf:PointToObjectSpace(base.lock.Position)
  check(math.abs(p.X)<1e-5 and math.abs(p.Z+22)<1e-5,'Green entrance line moved')
  check(not base.lock.CanCollide and not base.lock.CanQuery,'Green entrance line blocks movement')
  check(base.upgrade.Parent and base.upgrade.Transparency==1,'Functional upgrade anchor changed')
 end
 local perimeter=assert(world.folder:FindFirstChild('ArenaBounds'))
 for _,name in ipairs({'NorthBarrier','SouthBarrier','WestBarrier','EastBarrier'})do
  local part=assert(perimeter:FindFirstChild(name));check(part.CanCollide and part.CanQuery and part.Size.Y==24,'Solid perimeter changed: '..name)
 end
 local roofs=assert(world.folder.Aesthetics:FindFirstChild('VaultRoofs'))
 check(#roofs:GetChildren()==8,'Eight fitted roofs must remain')
 for _,roof in ipairs(roofs:GetChildren())do
  local solidRoof,solidWall=false,false
  for _,part in ipairs(roof:GetDescendants())do if part:IsA('BasePart')and part.CanCollide then
   if part.Name:lower():find('roof')then solidRoof=true end
   if part.Name:lower():find('wall')then solidWall=true end
  end end
  check(solidRoof and solidWall,'A fitted roof/upper wall lost solidity')
 end
 check(world.folder.PhaseDecor.DisposalFacade.CanCollide and world.folder.PhaseDecor.DisposalRoof.CanCollide,'Item-only disposal geometry changed')
 check(world.powerShop and world.powerShop.Parent and world.powerShop.Transparency==1,'Functional power-shop anchor changed')
 check(#named(world.folder,'WingedDragonOfRaStatue')==1,'Detailed Ra statue missing or duplicated')
 check(#named(world.folder,'SliferAnimatedLandmark')==1,'Animated Slifer missing or duplicated')
 check(#named(world.folder,'MidnightLotus')==1,'Black Lotus landmark missing or duplicated')
end
local function extents(part,reference)
 local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,x in ipairs({-.5,.5})do for _,y in ipairs({-.5,.5})do for _,z in ipairs({-.5,.5})do
  local p=part.CFrame*Vector3.new(part.Size.X*x,part.Size.Y*y,part.Size.Z*z)
  if reference then p=reference:PointToObjectSpace(p)end
  low=Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z))
  high=Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
 end end end
 return low,high
end
local function overlaps(lo,hi,a,b)
 return hi.X>a.X+1e-5 and lo.X<b.X-1e-5 and hi.Y>a.Y+1e-5 and lo.Y<b.Y-1e-5 and hi.Z>a.Z+1e-5 and lo.Z<b.Z-1e-5
end
local function geometryContracts(parent)
 local count=0
 for _,part in ipairs(parent:GetDescendants())do if part:IsA('BasePart')then
  count=count+1
  check(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,'Cosmetic art blocks interaction: '..part:GetFullName())
  for _,n in ipairs({part.Size.X,part.Size.Y,part.Size.Z})do check(finite(n)and n>0,'Invalid cosmetic size')end
  for _,n in ipairs({part.CFrame:GetComponents()})do check(finite(n),'Nonfinite cosmetic transform')end
 end end
 return count
end
local function presentation(world)
 local bases=assert(world.folder:FindFirstChild('BasePresentation'),'Base polish is not integrated into World.build')
 local plaza=assert(world.folder:FindFirstChild('PlazaPresentation'),'Plaza polish is not integrated into World.build')
 check(#named(world.folder,'BasePresentation')==1 and #named(world.folder,'PlazaPresentation')==1,'Presentation root duplicated')
 check(#bases:GetChildren()==8,'Exactly one presentation model is required per base')
 local baseParts=geometryContracts(bases);local plazaParts=geometryContracts(plaza)
 for i,base in ipairs(world.bases)do
  local models=named(bases,'RelicVault'..i);check(#models==1,'Base presentation duplicated/missing: '..i)
  local model=models[1]
  check(model:GetAttribute('DecorativeOnly')and model:GetAttribute('Kind')==nil,'Base art must not register as an item')
  check(model:GetAttribute('BaseIndex')==i and model:GetAttribute('ArtVersion')==72,'Base art identity mismatch')
  check(model:GetAttribute('PresentationTheme')=='Relic Vault','Cohesive vault theme missing')
  check(model:GetAttribute('PartCount')<=140,'Per-base art exceeds geometry budget')
  for _,part in ipairs(model:GetDescendants())do if part:IsA('BasePart')and part.Transparency<1 then
   local lo,hi=extents(part,base.cf)
   check(lo.X>=-24 and hi.X<=24 and lo.Z>=-25.5 and hi.Z<=24 and lo.Y>=1 and hi.Y<13,'Base decoration exceeds fitted architectural envelope: '..part.Name)
   check(not overlaps(lo,hi,Vector3.new(-23,1,-25),Vector3.new(23,3,-20)),'Base art covers the delivery/protection line: '..part.Name)
   check(not overlaps(lo,hi,Vector3.new(-17,1.2,-25),Vector3.new(17,9,-18)),'Base art intrudes into the open doorway: '..part.Name)
   for _,slot in ipairs(base.slots)do
    local p=base.cf:PointToObjectSpace(slot.Position)
    check(not overlaps(lo,hi,p-Vector3.new(2.75,0,2.75),p+Vector3.new(2.75,8,2.75)),'Base art enters a stored item display envelope: '..part.Name)
   end
  end end
 end
 check(baseParts<=8*140 and plazaParts<=350,'Presentation geometry exceeds budget')
 for _,part in ipairs(plaza:GetDescendants())do if part:IsA('BasePart')and part.Transparency<1 then
  local lo,hi=extents(part)
  check(not overlaps(lo,hi,Vector3.new(-110,.95,-6),Vector3.new(110,12,6)),'Plaza art intrudes into belt/item carrying clearance: '..part.Name)
  check(lo.Z>=-32.9 and hi.Z<=32.9,'Plaza art overlaps base entrances: '..part.Name)
 end end
 return bases,plaza,baseParts,plazaParts
end
local function build(root)return Mock.loadModule(root..'/World.lua').build(factory,Mock.loadModule(root..'/Config.lua'))end
local baseline=build(baselineRoot);contracts(baseline)
local previous,anchors=protected(baseline),anchorSnapshot(baseline)
local final=build(stagedRoot);contracts(final)
check(protected(final)==previous,'An original world instance/property changed outside additive presentation roots')
check(anchorSnapshot(final)==anchors,'Original base interaction anchors, slots or spawn positions changed')
local bases,plaza,baseParts,plazaParts=presentation(final)
local first=Mock.json({bases=tree(bases,false),plaza=tree(plaza,false)})
local anchorRefs={};for i,b in ipairs(final.bases)do anchorRefs[i]={b.home,b.lock,b.upgrade,b.gate,b.sign,b.bank}end
Mock.loadModule(stagedRoot..'/DetailedArt/BasePolish.lua').build(final)
Mock.loadModule(stagedRoot..'/DetailedArt/PlazaPolish.lua').build(final)
local rebuiltBases,rebuiltPlaza=presentation(final)
check(first==Mock.json({bases=tree(rebuiltBases,false),plaza=tree(rebuiltPlaza,false)}),'Repeated presentation build changes or duplicates art')
check(protected(final)==previous and anchorSnapshot(final)==anchors,'Repeated presentation build changes original functional geometry')
for i,b in ipairs(final.bases)do for j,key in ipairs({'home','lock','upgrade','gate','sign','bank'})do
 check(b[key]==anchorRefs[i][j],'Repeated presentation build replaces a functional anchor: '..key)
end end
-- Record actual world geometry for separate previews and Studio review.
local preview=create('Model');preview.Name='Version72World'
local root=create('Part',preview);root.Name='PreviewRoot';root.Anchored=true;root.Transparency=1
root.CanCollide=false;root.CanQuery=false;root.CanTouch=false;preview.PrimaryPart=root;final.folder.Parent=preview
local spec=Mock.record(preview)
local file=assert(io.open(out,'w'));file:write(Mock.json(spec));file:close()
local report={checks=checks,world_parts=#spec.parts,base_presentation_parts=baseParts,plaza_presentation_parts=plazaParts,
 original_world_instance_properties_preserved=true,base_anchors_slots_and_spawn_positions_preserved=true,
 eight_bases_eight_slots_each=true,solid_roofs_perimeter_and_disposal_preserved=true,
 cosmetic_geometry_noninteractive=true,entrances_green_lines_belt_and_display_envelopes_clear=true,rebuild_idempotent=true,
 studio_rendering_physics_multiplayer_performance_tested=false}
file=assert(io.open(reportPath,'w'));file:write(Mock.json(report));file:close()
print(string.format('PASS: %d presentation checks; original world preserved; 8 bases/64 slots; %d base + %d plaza cosmetic parts; clear entrances/belt/displays; rebuild stable',checks,baseParts,plazaParts))
print('Recorded '..out..' and '..reportPath)
