-- Execute the staged World module with real scenery builders and a geometry/UI recorder.
-- This checks generation contracts, not Roblox physics or rendering.
local Mock=dofile('tools/roblox_mock.lua')
local create=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class] then return create(class,parent) end
 local ui=create('Folder',parent);ui._class=class;ui.Name=class;return ui
end
UDim2={fromOffset=function(x,y)return {x,y} end,fromScale=function(x,y)return {x,y} end,new=function(...)return {...} end}
UDim={new=function(a,b)return {a,b} end}
Vector2={new=function(x,y)return {X=x,Y=y} end}
workspace=create('Folder');workspace.Name='Workspace'
local factory={part=function(parent,name,size,cf,color,material)
 local p=create('Part',parent);p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true
 p.CanTouch=false;return p
end}
local sourceRoot=arg and arg[1] or 'roblox/game'
local Config=Mock.loadModule(sourceRoot..'/Config.lua')
local World=Mock.loadModule(sourceRoot..'/World.lua')
local world=World.build(factory,Config)
assert(#world.bases==8,'Base count changed')
for _,base in ipairs(world.bases) do
 assert(#base.slots==8,'A base lost its eight item slots')
 assert(base.lock.Size.X==46 and base.lock.Size.Y<.2,'Entrance line is not flat/full width')
 local pos=base.cf:PointToObjectSpace(base.lock.Position)
 assert(math.abs(pos.X)<1e-5 and math.abs(pos.Z+22)<1e-5,'Entrance line misplaced')
 assert(not base.lock.CanCollide and not base.lock.CanQuery,'Entrance line blocks players')
end
local bounds=world.folder:FindFirstChild('ArenaBounds')
assert(bounds and bounds.NorthBarrier.CanCollide and bounds.EastBarrier.CanCollide,'Perimeter walls not solid')
assert(bounds.NorthBarrier.Position.Z==-93,'Perimeter wall position changed')
assert(world.folder:FindFirstChild('PhaseDecor').DisposalFacade.CanCollide,'Item-only disposal facade removed')
assert(world.powerShop and world.powerShop.Parent,'Power shop missing')
if sourceRoot:find('v64') then
 local native=assert(world.folder:FindFirstChild('NativeFreeArt'),'Native free scenery missing')
 assert(native:FindFirstChild('HoOh') and native.HoOh:GetAttribute('FlightOrigin'),'Ho-Oh missing flight metadata')
 assert(native.HoOh:FindFirstChild('LeftWing') and native.HoOh:FindFirstChild('RightWing'),'Ho-Oh wings missing')
 assert(not world.folder.BackgroundArt:FindFirstChild('MirrorForceReflectionPlanet'),'Old planet still covers card')
 for _,part in ipairs(world.folder.Aesthetics.PrismaticSky:GetChildren()) do assert(part.Name~='SoftCloud','Cloud blobs not removed') end
 for _,base in ipairs(world.bases) do assert(base.upgrade.Transparency==1,'Blank console block visible') end
 assert(world.powerShop.Transparency==1,'Blank power shop block visible')
end
local preview=create('Model');preview.Name='GeneratedWorldPreview'
local root=create('Part',preview);root.Name='PreviewRoot';root.Anchored=true;root.Transparency=1
root.CanCollide=false;root.CanQuery=false;root.CanTouch=false;preview.PrimaryPart=root
world.folder.Parent=preview
local record=Mock.record(preview)
local output=arg and arg[2] or '/tmp/opitem-full-world.json'
local f=assert(io.open(output,'w'));f:write(Mock.json(record));f:close()
print('PASS: actual World.build generates eight bases/64 slots, full entrance lines, solid perimeter, scenery, disposal and shop')
print('Recorded '..#record.parts..' total world parts to '..output)
