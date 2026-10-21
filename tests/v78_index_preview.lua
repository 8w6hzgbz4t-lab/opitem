-- Execute the real Client preview builder against all 76 real factory templates.
local Mock=dofile('tools/roblox_mock.lua')
local root=arg[1]or'roblox/v78-game'
local output=arg[2]or'/tmp/opitem-v78-index-preview.json'
local create=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 local item=create(geometry[class]and class or'Folder',parent)
 if not geometry[class]then item._class=class;item.Name=class end
 if class=='ViewportFrame'then item.AbsoluteSize={X=400,Y=150}end
 return item
end
local meta=getmetatable(create('Model'));local oldIndex=meta.__index
local function clone(source)
 local copies={}
 local function copyTree(item)
  local result=Instance.new(item._class);copies[item]=result
  for key,value in pairs(item._props)do if key~='Parent'then result[key]=value end end
  for key,value in pairs(item._attrs)do result:SetAttribute(key,value)end
  for _,child in ipairs(item:GetChildren())do copyTree(child).Parent=result end
  return result
 end
 local result=copyTree(source)
 for _,copy in pairs(copies)do for key,value in pairs(copy._props)do if copies[value]then copy[key]=copies[value]end end end
 return result
end
meta.__index=function(item,key)
 if key=='Clone'then return clone end
 if key=='GetBoundingBox'then return function(model)local lo,hi=Mock.bounds(model);return CFrame.new((lo+hi)*.5),hi-lo end end
 if key=='GetPropertyChangedSignal'then return function(object,name)
  object._props.signals=object._props.signals or{}
  local signal=object._props.signals[name]
  if not signal then
   signal={};function signal:Connect(callback)self.callback=callback;return{Disconnect=function()end}end
   object._props.signals[name]=signal
  end
  return signal
 end end
 return oldIndex(item,key)
end
UDim2={new=function(...)return{...}end,fromScale=function(...)return{...}end,fromOffset=function(...)return{...}end}
UDim={new=function(...)return{...}end}
Vector2={new=function(x,y)return{X=x,Y=y}end}
local Factory=Mock.loadModule(root..'/ModelFactory.lua')
local Catalog=Mock.loadModule(root..'/Catalog.lua')
local templates=Instance.new('Folder');templates.Name='Models'
local function read(path)local file=assert(io.open(path));local value=file:read('*a');file:close();return value end
local source=read(root..'/Client.lua')
local start=assert(source:find('local function preview(',1,true))
local stop=assert(source:find('local function setSlider(',start,true))
local builder=source:sub(start,stop-1)..'\nreturn preview\n'
local env=setmetatable({templates=templates,colors={bg=Color3.fromRGB(14,20,34),muted=Color3.fromRGB(159,178,202)},corner=function()end,text=function()error('Actual catalog must have no missing preview templates')end},{__index=_G})
local preview=assert(load(builder,'ActualClientPreview','t',env))()
local checks=0
local function check(value,msg)checks=checks+1;assert(value,msg)end
local function partCount(model)local count=0;for _,part in ipairs(model:GetDescendants())do if part:IsA('BasePart')then count=count+1 end end;return count end
local widths={180,280,400,600}
for _,definition in ipairs(Catalog.Items)do
 local template=Factory.create(definition,templates);template.Name=definition.id
 local before=Mock.json(Mock.record(template));local count=partCount(template)
 local parent=Instance.new('Folder');parent.AbsoluteSize={X=400,Y=500}
 preview(definition,parent)
 local viewport=assert(parent:FindFirstChild('ItemPreview'))
 check(viewport:GetAttribute('ItemId')==definition.id,'Preview names correct catalog template: '..definition.id)
 local model
 for _,child in ipairs(viewport:GetChildren())do if child:IsA('Model')then model=child end end
 check(model~=template and partCount(model)==count,'Index clones complete exact factory model: '..definition.id)
 local camera=viewport.CurrentCamera;check(camera.FieldOfView==32,'Predictable bounded preview FOV')
 for _,width in ipairs(widths)do
  viewport.AbsoluteSize={X=width,Y=150};viewport._props.signals.AbsoluteSize.callback()
  local cf,size=model:GetBoundingBox();local tangent=math.tan(math.rad(camera.FieldOfView*.5));local aspect=width/150
  for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
   local point=cf*Vector3.new(x*size.X*.5,y*size.Y*.5,z*size.Z*.5)
   local view=camera.CFrame:PointToObjectSpace(point)
   check(-view.Z>0,'Every preview corner stays in front of camera: '..definition.id)
   check(math.abs(view.X)/(-view.Z*tangent*aspect)<=1+1e-7,'Wide preview geometry fits horizontally: '..definition.id)
   check(math.abs(view.Y)/(-view.Z*tangent)<=1+1e-7,'Tall preview geometry fits vertically: '..definition.id)
  end end end
 end
 check(Mock.json(Mock.record(template))==before,'Index preview never edits conveyor source model: '..definition.id)
 parent:Destroy()
end
check(#Catalog.Items==76,'Catalog item count preserved')
local report={passed=true,assertions=checks,actual_factory_items=76,viewport_widths=widths,all_bounding_corners_fit=true,complete_template_clones=true,original_templates_unchanged=true,limitations='Actual Client preview builder and recorded geometry; Studio lighting and device rendering require Play tests.'}
local file=assert(io.open(output,'w'));file:write(Mock.json(report),'\n');file:close()
print('INDEX PREVIEW PASS '..checks..' assertions; 76 exact templates; four viewport widths; every corner fits')
