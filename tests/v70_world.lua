-- Execute both uploaded v69 and staged v70 World builders and compare scenery.
-- Offline geometry contracts only; Studio rendering/physics require a playtest.
local Mock=dofile('tools/roblox_mock.lua')
local create=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class] then return create(class,parent) end
 local instance=create('Folder',parent);instance._class=class;instance.Name=class;return instance
end
UDim2={fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end,new=function(...)return {...}end}
UDim={new=function(...)return {...}end}
Vector2={new=function(x,y)return {X=x,Y=y}end}
-- Roblox Model:ScaleTo is used by the existing v69 Mirror Force sculpture.
-- This local adapter scales recorded geometry and nested pivots uniformly.
local instanceMeta=getmetatable(create('Model'))
local previousIndex=instanceMeta.__index
instanceMeta.__index=function(self,key)
 if key=='GetScale' then return function(model)return model._props._testScale or 1 end end
 if key=='ScaleTo' then return function(model,scale)
  assert(type(scale)=='number' and scale>0 and scale<math.huge,'Invalid test scale')
  local ratio=scale/(model._props._testScale or 1)
  local pivot=model:GetPivot();local inverse=pivot:Inverse()
  local function scaled(cf)
   local localFrame=inverse*cf
   return pivot*CFrame.new(localFrame.Position*ratio)*(localFrame-localFrame.Position)
  end
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA('BasePart') then part.CFrame=scaled(part.CFrame);part.Size=part.Size*ratio
   elseif part:IsA('Model') and part._props._pivot then part._props._pivot=scaled(part._props._pivot) end
  end
  model._props._testScale=scale
 end end
 return previousIndex(self,key)
end
workspace=create('Folder');workspace.Name='Workspace'
local factory={part=function(parent,name,size,cf,color,material)
 local part=create('Part',parent);part.Name=name;part.Size=size;part.CFrame=cf
 part.Color=color;part.Material=material or Enum.Material.SmoothPlastic
 part.Anchored=true;part.CanTouch=false;return part
end}
local baselineRoot=arg[1] or 'roblox/v69-original/OPItemV2'
local stagedRoot=arg[2] or 'roblox/v70-game'
local outputPrefix=arg[3] or '/tmp/opitem'
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function descendantsNamed(parent,name)
 local found={};for _,value in ipairs(parent:GetDescendants())do if value.Name==name then found[#found+1]=value end end;return found
end
local function worldContracts(world)
 check(#world.bases==8,'Eight bases must remain')
 for _,base in ipairs(world.bases) do
  check(#base.slots==8,'Each base must retain eight item slots')
  check(base.lock.Size.X==46 and base.lock.Size.Y<.2,'Entrance line must stay flat/full width')
  local pos=base.cf:PointToObjectSpace(base.lock.Position)
  check(math.abs(pos.X)<1e-5 and math.abs(pos.Z+22)<1e-5,'Entrance delivery/protection line moved')
  check(not base.lock.CanCollide and not base.lock.CanQuery,'Entrance line blocks movement')
  check(base.upgrade.Parent and base.upgrade.Transparency==1,'Original functional upgrade anchor lost')
 end
 local bounds=assert(world.folder:FindFirstChild('ArenaBounds'))
 for _,name in ipairs({'NorthBarrier','SouthBarrier','WestBarrier','EastBarrier'})do
  local part=assert(bounds:FindFirstChild(name))
  check(part.CanCollide and part.CanQuery and part.Size.Y==24,'Solid arena perimeter changed: '..name)
 end
 check(bounds.NorthBarrier.Position.Z==-93,'Perimeter wall moved')
 local aesthetics=assert(world.folder:FindFirstChild('Aesthetics'))
 local roofs=assert(aesthetics:FindFirstChild('VaultRoofs'))
 check(#roofs:GetChildren()==8,'Each base must retain a fitted roof')
 for _,roof in ipairs(roofs:GetChildren())do
  local solidRoof,solidWall=false,false
  for _,part in ipairs(roof:GetDescendants())do
   if part:IsA('BasePart') and part.CanCollide then
    if part.Name:lower():find('roof')then solidRoof=true end
    if part.Name:lower():find('wall')then solidWall=true end
   end
  end
  check(solidRoof and solidWall,'A fitted roof or upper wall lost solidity: '..roof.Name)
 end
 local disposal=assert(world.folder:FindFirstChild('PhaseDecor'))
 check(disposal.DisposalFacade.CanCollide,'Item-only conveyor disposal lost its facade')
 check(disposal.DisposalRoof.CanCollide,'Item-only conveyor disposal lost its roof')
 check(world.powerShop and world.powerShop.Parent and world.powerShop.Transparency==1,'Functional power shop anchor missing')
 local scene=assert(world.folder:FindFirstChild('EnhancedScene'))
 for _,name in ipairs({'KaibaCorpTower','MirrorForceTrapCard','ForceOfDespairPainting','ExodiaPainting','EgyptianGodsPainting','BellTowerGarden','HoOhFlight'})do
  check(scene:FindFirstChild(name)~=nil,'Version 69 landmark removed: '..name)
 end
 check(#descendantsNamed(world.folder,'DetailedWorkstationCentral')==1,'Central workstation duplicated')
 check(#descendantsNamed(world.folder,'MidnightLotus')==1,'Black Lotus landmark missing or duplicated')
 return scene
end
local sliferNames={SliferAnimatedLandmark=true,SliferAroundKaibaTower=true,godSlifer=true,SliferStatue=true,SliferTablet=true}
local function protectedGeometry(world)
 local rows={}
 for _,part in ipairs(world.folder:GetDescendants())do
  if part:IsA('BasePart') then
   local ancestor=part;local excluded=false;local path={}
   while ancestor and ancestor~=world.folder do
    if sliferNames[ancestor.Name]then excluded=true end
    table.insert(path,1,ancestor.Name);ancestor=ancestor.Parent
   end
   if not excluded then
    rows[#rows+1]=Mock.json({path=table.concat(path,'/'),class=part._class,size={part.Size.X,part.Size.Y,part.Size.Z},
     frame={part.CFrame:GetComponents()},color={part.Color.R,part.Color.G,part.Color.B},material=part.Material,
     shape=part.Shape,transparency=part.Transparency,collide=part.CanCollide,query=part.CanQuery,touch=part.CanTouch})
   end
  end
 end
 table.sort(rows);return table.concat(rows,'\n'),#rows
end
local function recordWorld(world,suffix)
 local preview=create('Model');preview.Name='GeneratedWorldPreview'
 local root=create('Part',preview);root.Name='PreviewRoot';root.Anchored=true;root.Transparency=1
 root.CanCollide=false;root.CanTouch=false;root.CanQuery=false;preview.PrimaryPart=root
 world.folder.Parent=preview
 local record=Mock.record(preview)
 local file=assert(io.open(outputPrefix..'-'..suffix..'-world.json','w'));file:write(Mock.json(record));file:close()
 return #record.parts
end
local baseline=Mock.loadModule(baselineRoot..'/World.lua').build(factory,Mock.loadModule(baselineRoot..'/Config.lua'))
worldContracts(baseline)
local oldGeometry,protectedParts=protectedGeometry(baseline)
check(#descendantsNamed(baseline.folder,'SliferAroundKaibaTower')==1,'Baseline v69 animated serpent was not found')
local baselineParts=recordWorld(baseline,'v69')
local final=Mock.loadModule(stagedRoot..'/World.lua').build(factory,Mock.loadModule(stagedRoot..'/Config.lua'))
local scene=worldContracts(final)
local newGeometry,newProtectedParts=protectedGeometry(final)
check(newProtectedParts==protectedParts and oldGeometry==newGeometry,'Scenery outside Slifer changed from uploaded v69')
local slifers=descendantsNamed(final.folder,'SliferAnimatedLandmark')
check(#slifers==1,'Exactly one replacement Slifer must exist')
check(#descendantsNamed(final.folder,'SliferAroundKaibaTower')==0,'Old tower serpent is still present')
for _,name in ipairs({'godSlifer','SliferStatue','SliferTablet'})do check(#descendantsNamed(final.folder,name)==0,'Legacy Slifer statue remains: '..name)end
local slifer=slifers[1]
local former=slifer:GetAttribute('FormerStatueOrigin');local origin=slifer:GetAttribute('OrbitOrigin')
check(former.X==-105 and former.Y==34 and former.Z==155,'Former statue site metadata changed')
check(origin.X==former.X and origin.Z==former.Z and origin.Y>former.Y,'Animated Slifer must occupy the former statue site above the walls')
check(slifer:GetAttribute('DecorativeOnly') and slifer:GetAttribute('SliferArtVersion')==2,'Replacement must opt into decorative animation')
local low,high=Mock.bounds(slifer)
check(low.Y>33 and high.Y<110,'Slifer silhouette must clear the base/perimeter walls and stay in the dome')
for _,part in ipairs(slifer:GetDescendants())do
 if part:IsA('BasePart') then check(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,'New Slifer decoration affects gameplay geometry')end
end
-- Rebuilding scenery must not duplicate landmarks or move functional anchors.
local sceneBefore={};for _,child in ipairs(scene:GetChildren())do sceneBefore[child.Name]=#child:GetDescendants()end
local sceneChildCount=#scene:GetChildren()
local anchors={};for i,base in ipairs(final.bases)do anchors[i]=base.upgrade end
Mock.loadModule(stagedRoot..'/DetailedArt/EnhancedScene.lua').build(final)
local rebuilt=worldContracts(final)
for name,count in pairs(sceneBefore)do local model=assert(rebuilt:FindFirstChild(name));check(#model:GetDescendants()==count,'Repeated scenery build changed/duplicated '..name)end
check(#rebuilt:GetChildren()==sceneChildCount,'Repeated scenery build changed direct landmark count')
check(#descendantsNamed(final.folder,'SliferAnimatedLandmark')==1,'Repeated build duplicated Slifer')
for i,base in ipairs(final.bases)do check(base.upgrade==anchors[i],'Repeated scenery build replaced the functional interaction anchor')end
check(protectedGeometry(final)==oldGeometry,'Repeated scenery build drifted protected scenery')
local finalParts=recordWorld(final,'v70')
print(string.format('PASS: %d checks; both actual World builders; 8 bases/64 slots; solid roofs/walls; shop/disposal; %d protected parts unchanged; one noninteractive animated Slifer; repeated build stable',checks,protectedParts))
print(string.format('Recorded v69 %d parts and v70 %d parts to %s-v69-world.json and %s-v70-world.json',baselineParts,finalParts,outputPrefix,outputPrefix))
