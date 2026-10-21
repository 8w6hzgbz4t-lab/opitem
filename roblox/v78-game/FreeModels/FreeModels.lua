-- Complete native Roblox geometry. No generated asset IDs or paid API required.
local P=require(script.Parent.Primitives)
local Assets=require(script.Parent.Assets)
local Labels=require(script.Parent.Labels)
local families={
 DragonCollectibles=require(script.Parent.DragonCollectibles),
 PopCultureItems=require(script.Parent.PopCultureItems),
 AllSpark=require(script.Parent.AllSpark),
 MatrixLeadership=require(script.Parent.MatrixLeadership),
 EnergonAxe=require(script.Parent.EnergonAxe),
 NintendoItems=require(script.Parent.NintendoItems),
 RelicItems=require(script.Parent.RelicItems),
 WarriorModels=require(script.Parent.WarriorModels),
 WorkshopBuildings=require(script.Parent.WorkshopBuildings),
 CardDecor=require(script.Parent.CardDecor),
 HoOhModel=require(script.Parent.HoOhModel),
 ExtraItems=require(script.Parent.ExtraItems),
 SecretFormula=require(script.Parent.SecretFormula),
}
local F={Assets=Assets}
function F.supports(key) return Assets[key]~=nil end
function F.create(parent,options)
 options=options or {}
 local key=options.model or options.key
 local entry=assert(Assets[key],"Unknown free model: "..tostring(key))
 local copy={}
 for k,v in pairs(options) do copy[k]=v end
 copy.name=copy.name or entry.Name
 copy.itemId=copy.itemId or entry.ItemId or key
 copy.partBudget=copy.partBudget or entry.PartBudget
 if copy.alignBase==nil then copy.alignBase=entry.AlignBase end
 local b=P.new(parent,copy)
 local buildKey=key=='dragon_balls' and 'dragonballs' or key
 assert(families[entry.Family].build(b,buildKey),"Free model builder missing: "..key)
 b.model:SetAttribute("ArtSource","NativeRobloxParts")
 b.model:SetAttribute("FreeModelKey",key)
 b.model:SetAttribute("ReferenceRequired",entry.ReferenceRequired)
 local model=b:finish()
 Labels.apply(model,key)
 return model
end
return F
