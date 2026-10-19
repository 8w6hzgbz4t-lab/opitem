-- Record the exact PlazaPolish builder for the shared-area review image.
local Mock=dofile('tools/roblox_mock.lua')
local create=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class]then return create(class,parent)end
 local object=create('Folder',parent);object._class=class;object.Name=class;return object
end
UDim2={fromScale=function(...)return {...}end}
Vector2={new=function(x,y)return {X=x,Y=y}end}
local folder=create('Folder');folder.Name='World'
local preview=create('Model');preview.Name='PlazaPresentationPreview'
local root=create('Part',preview);root.Name='PreviewRoot';root.Size=Vector3.new(.1,.1,.1)
root.Anchored=true;root.Transparency=1;root.CanCollide=false;root.CanQuery=false;root.CanTouch=false
preview.PrimaryPart=root
local presentation=Mock.loadModule('roblox/v72-game/DetailedArt/PlazaPolish.lua').build({folder=folder})
presentation.Parent=preview
local record=Mock.record(preview)
local output=arg[1]or'/tmp/opitem-v72-plaza.json'
local file=assert(io.open(output,'w'));file:write(Mock.json(record));file:close()
print('Recorded '..presentation:GetAttribute('PartCount')..' noninteractive plaza parts to '..output)
