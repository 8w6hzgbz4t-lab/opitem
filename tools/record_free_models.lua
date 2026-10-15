-- Record the actual native builders; no downloaded meshes or asset IDs.
local Mock=dofile('tools/roblox_mock.lua')
local Models=Mock.loadModule('roblox/free_models/FreeModels.lua')
local Labels=Mock.loadModule('roblox/free_models/Labels.lua')
local additions=Mock.loadModule('roblox/free_models/CatalogAdditions.lua')
local byModel={}
for _,d in ipairs(additions) do byModel[d.model]=d.id end
local folder=assert(arg[1],'Output folder is required')
local count,total=0,0
for key,entry in pairs(Models.Assets) do
 local model=Models.create(nil,{model=key,itemId=entry.ItemId or byModel[key] or key})
 local spec=Mock.record(model)
 spec.textOverlays=Labels.Definitions[key] or {}
 local file=assert(io.open(folder..'/'..key..'.json','w'))
 file:write(Mock.json(spec));file:close()
 count=count+1;total=total+#spec.parts
end
-- The complete bird is also provided as a single easy-to-import static model.
local P=Mock.loadModule('roblox/free_models/Primitives.lua')
local Bird=Mock.loadModule('roblox/free_models/HoOhModel.lua')
local b=P.new(nil,{name='Ho-Oh Complete Bird',model='hooh_complete',partBudget=700,alignBase=false})
assert(Bird.build(b,'hooh_complete'))
local model=b:finish();model:SetAttribute('ArtSource','NativeRobloxParts')
local file=assert(io.open(folder..'/hooh_complete.json','w'));file:write(Mock.json(Mock.record(model)));file:close()
print('Recorded '..count..' requested native assets ('..total..' parts) and the complete Ho-Oh bird')
