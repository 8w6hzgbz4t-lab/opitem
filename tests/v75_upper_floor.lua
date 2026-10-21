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
local root=arg[1] or 'roblox/v75-game'
local world=Mock.loadModule(root..'/World.lua').build(factory,Mock.loadModule(root..'/Config.lua'))
local Floors=Mock.loadModule(root..'/DetailedArt/UpperFloor.lua')
local Entrance=Mock.loadModule(root..'/BaseEntrance.lua')
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
-- Roblox replicates parented models immediately; camera metadata must exist then.
local priorParent=meta.__newindex
meta.__newindex=function(instance,key,value)
 if key=='Parent' and value and instance.Name=='UpperFloorShell' then
  check(instance:GetAttribute('BaseCF')~=nil and instance:GetAttribute('OcclusionShell')==true,'Upper shell camera metadata must exist before parenting into the world')
 end
 return priorParent(instance,key,value)
end
local function encode(value)
 if typeof(value)=='Instance' then return value:GetFullName()
 elseif typeof(value)=='Vector3' then return {value.X,value.Y,value.Z}
 elseif typeof(value)=='CFrame' then return {value:GetComponents()}
 elseif type(value)=='table' then local result={};for key,v in pairs(value)do if type(v)~='function'then result[key]=encode(v)end end;return result end
 return value
end
local function tree(instance)
 local props={};for key,value in pairs(instance._props)do if key~='Parent'and type(value)~='function'then props[key]=encode(value)end end
 local children={};for _,child in ipairs(instance:GetChildren())do children[#children+1]=tree(child)end
 return {class=instance._class,properties=props,attributes=encode(instance._attrs),children=children}
end
local roofs=world.folder.Aesthetics.VaultRoofs
local oldRoofs,oldSlots,oldAnchors={},{},{}
for index,base in ipairs(world.bases) do
 oldSlots[index]={};for slot,cf in ipairs(base.slots)do oldSlots[index][slot]=Mock.json(encode(cf))end
 oldAnchors[index]=Mock.json({tree(base.home),tree(base.lock),tree(base.upgrade),encode(base.spawn)})
 oldRoofs[index]=Mock.json(tree(roofs:FindFirstChild('BaseRoof'..index)))
end
local states={}
for index,base in ipairs(world.bases)do base.owner=index;states[index]={progression=4,capacity=8}end
local folder=Floors.sync(world,states)
check(folder.Name=='UpperFloorUpgrades' and #folder:GetChildren()==0,'No upper floor before level five')
for index,base in ipairs(world.bases)do
 check(#base.slots==8 and oldRoofs[index]==Mock.json(tree(roofs:FindFirstChild('BaseRoof'..index))),'Level four preserves roof and eight slots')
end
local function inside(part,point,inset)
 local p=part.CFrame:PointToObjectSpace(point);inset=inset or 0
 return math.abs(p.X)<part.Size.X/2-inset and math.abs(p.Y)<part.Size.Y/2-inset and math.abs(p.Z)<part.Size.Z/2-inset
end
local function countParts(parent)
 local count=0;for _,v in ipairs(parent:GetDescendants())do if v:IsA('BasePart')then count=count+1 end end;return count
end
local geometryParts=0
for index,base in ipairs(world.bases)do states[index]={progression=5,capacity=16}end
Floors.sync(world,states)
check(#folder:GetChildren()==8,'Each eligible base has exactly one upper floor')
for index,base in ipairs(world.bases)do
 local model=assert(folder:FindFirstChild('UpperFloor'..index));local roof=assert(roofs:FindFirstChild('BaseRoof'..index))
 local shell=assert(model:FindFirstChild('UpperFloorShell'))
 check(roof:GetAttribute('UpperFloorUnlocked') and roof:GetAttribute('RoofHeight')==36.5,'Original roof carries dynamic occlusion height')
 check(shell:GetAttribute('OcclusionShell') and shell:GetAttribute('BaseCF'),'New upper walls have dynamic roof-occlusion registration')
 check(model:GetAttribute('FloorHeight')==20 and model:GetAttribute('RoofHeight')==36.5,'Upper floor has adequate ceiling height')
 check(#base.slots==16,'Sixteen actual world pivots required')
 check(model:GetAttribute('StairWidth')>=4 and model:GetAttribute('StairRise')<=.5 and model:GetAttribute('StairTreadDepth')>=1.1,'Walkable stairs use comfortable dimensions')
 check(oldAnchors[index]==Mock.json({tree(base.home),tree(base.lock),tree(base.upgrade),encode(base.spawn)}),'Ground interaction anchors and spawn preserved')
 for slot=1,8 do check(oldSlots[index][slot]==Mock.json(encode(base.slots[slot])),'Original display pivot preserved')end
 for slot=9,16 do
  local point=base.cf:PointToObjectSpace(base.slots[slot].Position)
  check(math.abs(point.X)<=16.500001 and (math.abs(point.Z+3)<1e-6 or math.abs(point.Z-7)<1e-6) and math.abs(point.Y-21.9)<1e-6,'Upper item pivot fits gallery')
  check(model:FindFirstChild('UpperDisplayPedestal'..(slot-8)).CanCollide,'Every upper display has a physical plinth')
 end
 local moved=roof:FindFirstChild('SolidFittedRoof',true)
 local roofCF=base.cf:ToObjectSpace(moved.CFrame)
 check(math.abs(roofCF.Position.Y-moved.Size.Y/2-36.5)<1e-6 and moved.CanCollide,'Fitted solid roof is lifted rather than blocking stairs')
 for _,name in ipairs({'UpperSolidBackWall','UpperSolidSideWall-1','UpperSolidSideWall1','UpperFrontKneeWall','UpperFrontCrownBeam'})do
  check(shell:FindFirstChild(name).CanCollide,'Upper perimeter is solid: '..name)
 end
 local solids={}
 for _,part in ipairs(world.folder:GetDescendants())do
  if part:IsA('BasePart') and part.CanCollide then
   local cf=base.cf:ToObjectSpace(part.CFrame);local center=cf.Position
   local _,_,_,r00,r01,r02,r10,r11,r12,r20,r21,r22=cf:GetComponents()
   local h=part.Size*.5
   local extent=Vector3.new(math.abs(r00)*h.X+math.abs(r01)*h.Y+math.abs(r02)*h.Z,math.abs(r10)*h.X+math.abs(r11)*h.Y+math.abs(r12)*h.Z,math.abs(r20)*h.X+math.abs(r21)*h.Y+math.abs(r22)*h.Z)
   if center.X-extent.X<26 and center.X+extent.X>-26 and center.Z-extent.Z<26 and center.Z+extent.Z>-26 and center.Y+extent.Y>2 and center.Y-extent.Y<42 then solids[#solids+1]=part end
  end
 end
 -- Chest/head sampling excludes the lower foot volume that legitimately
 -- intersects the next low riser. It catches roof slabs/guardrails in the path.
 local function walkable(localPosition)
  for _,x in ipairs({-1.25,0,1.25})do for _,z in ipairs({-1.25,0,1.25})do for _,y in ipairs({1.8,3.2,5.2})do
   local point=base.cf*(localPosition+Vector3.new(x,y,z))
   for _,part in ipairs(solids)do
    check(not inside(part,point,.01),'Stair head/torso clearance intersects '..part:GetFullName()..' at '..tostring(localPosition.X)..','..tostring(localPosition.Y)..','..tostring(localPosition.Z))
   end
  end end end
 end
 for flight=1,2 do for step=1,20 do
  local tread=model:FindFirstChild('StairTread'..flight..'_'..step)
  check(tread.CanCollide and tread.CanQuery,'Stair treads are solid/queryable')
  local point=base.cf:PointToObjectSpace(tread.Position)+Vector3.new(0,tread.Size.Y/2,0)
  walkable(point)
 end end
 for _,z in ipairs({14.5,16,17.5,19,20.5})do walkable(Vector3.new(-21.75,10.5,z))end
 local marker=model:FindFirstChild('UpperDeliveryProtectionLine')
 check(marker and not marker.CanCollide and not marker.CanQuery and marker:GetAttribute('ProtectionLine'),'Upstairs green protection line is easy to cross')
 check(Entrance.contains(base.cf,base.cf*Vector3.new(4.2,23,20.5),true),'Upper arrival/protection zone detects a character above line')
 check(not Entrance.contains(base.cf,base.cf*Vector3.new(4.2,23,20.5),false),'No phantom upper protection pad at a locked base')
 check(Entrance.contains(base.cf,base.cf*Vector3.new(0,5,-22),true),'Original full-width green entrance remains active')
 local count=countParts(model);geometryParts=geometryParts+count
 check(count==model:GetAttribute('PartCount') and count<=570,'Geometry remains bounded and part metadata is honest')
 for _,part in ipairs(model:GetDescendants())do if part:IsA('BasePart')then
  check(part.Anchored and not part.CanTouch,'All added geometry anchored and has no touch callbacks')
  check(part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0,'All added dimensions positive')
 end end
end
local before=Mock.json(tree(folder));local refs={}
for index,base in ipairs(world.bases)do refs[index]=base.slots[16]end
Floors.sync(world,states)
check(before==Mock.json(tree(folder)),'Repeated sync does not rebuild geometry or change properties')
for index,base in ipairs(world.bases)do check(base.slots[16]==refs[index],'Repeated sync retains live upper pivots')end
-- Leaving removes expansion before another level-zero owner uses the base.
for index,base in ipairs(world.bases)do base.owner=nil end
Floors.sync(world,states)
check(#folder:GetChildren()==0,'Empty bases remove upper expansions')
for index,base in ipairs(world.bases)do
 check(#base.slots==8,'Leaving restores eight original pivots')
 check(oldRoofs[index]==Mock.json(tree(roofs:FindFirstChild('BaseRoof'..index))),'Leaving restores all original roof properties and positions exactly')
end
world.bases[1].owner=101;states[101]={progression=5,capacity=16};Floors.sync(world,states)
check(#folder:GetChildren()==1 and #world.bases[1].slots==16,'New eligible owner gets one correct extension after reuse')
local preview=create('Model');preview.Name='Version75UpperFloorWorld'
local previewRoot=create('Part',preview);previewRoot.Name='PreviewRoot';previewRoot.Anchored=true;previewRoot.Transparency=1
previewRoot.CanCollide=false;previewRoot.CanQuery=false;previewRoot.CanTouch=false;preview.PrimaryPart=previewRoot
world.folder.Parent=preview
local file=assert(io.open(arg[2] or '/tmp/opitem-v75-upper-world.json','w'));file:write(Mock.json(Mock.record(preview)));file:close()
local report={checks=checks,expanded_bases_checked=8,upper_pivots_checked=64,upper_geometry_parts_all_bases=geometryParts,
 paid_and_gifted_level_unlock=5,floor_height=20,roof_underside_height=36.5,stair_rise=.475,stair_tread_depth=1.15,stair_width=4,
 ground_anchors_and_slots_preserved=true,stair_torso_head_clearance_checked=true,upper_roof_and_walls_solid=true,shell_camera_attributes_ready_before_parenting=true,
 two_full_width_protection_zones=true,repeated_sync_idempotent=true,owner_leave_and_reuse_restores_original_roof=true,
 studio_rendering_physics_and_multiplayer_tested=false}
file=assert(io.open(arg[3] or '/tmp/opitem-v75-upper-floor-checks.json','w'));file:write(Mock.json(report));file:close()
print('PASS '..checks..' upper-floor geometry checks; 8 expanded bases/64 upper slots; walkable stairs; solid roofs/walls; original anchors and repeat/reuse preserved')
