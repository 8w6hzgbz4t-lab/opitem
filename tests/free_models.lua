-- Exercise the real native model router, geometry families, catalog additions,
-- and decorative Ho-Oh flight. This is offline geometry validation, not physics.
local Mock=dofile("tools/roblox_mock.lua")
local F=Mock.loadModule("roblox/free_models/FreeModels.lua")
local Flight=Mock.loadModule("roblox/free_models/HoOhFlight.lua")
local checks,models,parts=0,0,0
local function check(value,message)
 assert(value,message)
 checks=checks+1
end
local function near(a,b) return math.abs(a-b)<1e-5 end
local function finite(value)
 return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function frameNear(a,b)
 local aa,bb={a:GetComponents()},{b:GetComponents()}
 for i=1,12 do if not near(aa[i],bb[i]) then return false end end
 return true
end
local function frameFinite(cf)
 local components={cf:GetComponents()}
 for _,value in ipairs(components) do if not finite(value) then return false end end
 local r,u,z=cf:VectorToWorldSpace(Vector3.xAxis),cf:VectorToWorldSpace(Vector3.yAxis),cf:VectorToWorldSpace(Vector3.zAxis)
 return near(r.Magnitude,1) and near(u.Magnitude,1) and near(z.Magnitude,1)
  and near(r:Dot(u),0) and near(u:Dot(z),0) and near(z:Dot(r),0)
end
local function rejects(callback,message)
 local ok=pcall(callback)
 check(not ok,message)
end
local function options(key,scale,cf)
 return {model=key,scale=scale or 1,cframe=cf,includeLabels=false}
end
local keys={}
for key in pairs(F.Assets) do keys[#keys+1]=key end
table.sort(keys)
check(#keys==33,"The requested pack has exactly 33 model components")
check(F.Assets.blue_shell.ItemId=="item05","Blue Shell keeps item05")
check(F.Assets.dragon_balls.ItemId=="item43","Dragon Balls keep item43")
local destination=Instance.new("Folder")
local transform=CFrame.new(10,20,-30)*CFrame.Angles(.17,.74,-.22)
local itemFamilies={NintendoItems=true,RelicItems=true,ExtraItems=true}
local itemWarriors={pekka=true,mega_knight=true}
for _,key in ipairs(keys) do
 local meta=F.Assets[key]
 check(F.supports(key),"Router supports canonical key: "..key)
 check(type(meta.Name)=="string" and #meta.Name>0,"Readable name: "..key)
 local request=options(key)
 local model=F.create(destination,request)
 check(request.name==nil and request.itemId==nil and request.parent==nil,"Create leaves caller options unchanged: "..key)
 check(model.Parent==destination and model.Name==meta.Name,"Final parent and name: "..key)
 check(model.PrimaryPart and model.PrimaryPart.Name=="Root","Pivot marker exists: "..key)
 check(model.PrimaryPart.Transparency==1,"Pivot marker is invisible: "..key)
 check(model:GetAttribute("Kind")== (meta.ItemId or key),"Canonical kind metadata: "..key)
 check(model:GetAttribute("FreeModelKey")==key,"Free model key metadata: "..key)
 check(model:GetAttribute("ArtSource")=="NativeRobloxParts","Native geometry provenance: "..key)
 check(model:GetAttribute("ReferenceRequired")==meta.ReferenceRequired,"Reference metadata matches: "..key)
 local recorded=Mock.record(model)
 check(#recorded.parts>10 and #recorded.parts<=meta.PartBudget,"Complete model fits declared part budget: "..key)
 models=models+1;parts=parts+#recorded.parts
 local low,high=Mock.bounds(model)
 if meta.AlignBase then check(near(low.Y,.04),"Display bottom clears its pivot: "..key) end
 if itemFamilies[meta.Family] or itemWarriors[key] then
  check(math.max(high.X-low.X,high.Y-low.Y,high.Z-low.Z)<=5.5+1e-5,"Collectible fits conveyor/carry display envelope: "..key)
 end
 local oldParts=model:GetDescendants()
 for _,part in ipairs(oldParts) do
  check(part:IsA("BasePart"),"Offline model contains geometry only: "..key)
  check(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,"Decorative geometry is anchored and noninteractive: "..key.."/"..part.Name)
  check(frameFinite(part.CFrame),"Finite orthogonal geometry transform: "..key.."/"..part.Name)
  check(part.Material~=nil,"Every part has a material: "..key)
 end
 -- Uniform scaling must affect geometry once and retain the caller's rotated pivot.
 local scaled=F.create(nil,options(key,2,transform))
 local newParts=scaled:GetDescendants()
 check(#oldParts==#newParts,"Scaling retains topology: "..key)
 check(frameNear(scaled:GetPivot(),transform),"Requested pivot retained: "..key)
 local clearance=meta.AlignBase and Vector3.new(0,-.04,0) or Vector3.zero
 for i,p in ipairs(oldParts) do
  local q=newParts[i]
  check(p.Name==q.Name,"Stable part ordering: "..key)
  local primary=p==model.PrimaryPart
  check((q.Size-p.Size*(primary and 1 or 2)).Magnitude<1e-5,"Uniform dimensions: "..key.."/"..p.Name)
  local wanted=transform*(p.CFrame.Position*2+(primary and Vector3.zero or clearance))
  check((q.CFrame.Position-wanted).Magnitude<1e-5,"Scaled and rotated placement: "..key.."/"..p.Name)
  check(frameNear(q.CFrame-q.CFrame.Position,transform*(p.CFrame-p.CFrame.Position)-transform.Position),"Rotated orientation: "..key.."/"..p.Name)
 end
end
check(not F.supports("unknown_model") and not F.supports("dragonballs"),"Unknown keys and noncanonical aliases reject")
rejects(function() F.create(nil,options("unknown_model")) end,"Unknown model creation rejects")
for _,scale in ipairs({0,-1,math.huge,0/0}) do
 rejects(function() F.create(nil,options("blue_shell",scale)) end,"Invalid scales reject")
end

-- Metadata additions must integrate with the known 46-item baseline without IDs
-- colliding. The actual catalog's rarity names determine Legendary, not a label
-- invented by this test.
local original=Mock.loadModule("roblox/game/Catalog.lua")
local additions=Mock.loadModule("roblox/free_models/CatalogAdditions.lua")
check(#original.Items==46,"Known baseline contains the existing 46 collectibles")
check(#additions==17,"Native pack contains 17 new collectible catalog entries")
local byId,byModel={},{}
for _,item in ipairs(original.Items) do
 check(not byId[item.id],"Original IDs are unique")
 byId[item.id]=item
end
local stoneCount=0
for index,item in ipairs(additions) do
 check(item.id==string.format("item%02d",46+index),"Additions use contiguous new IDs")
 check(not byId[item.id] and not byModel[item.model],"No duplicate added ID or visual key")
 check(F.supports(item.model),"Every new catalog entry has a complete native model")
 check(item.price>0 and item.income>0 and item.spawnWeight>0,"New item has positive economic/spawn settings")
 check(original.Tiers[item.tier]~=nil,"New item has a valid rarity")
 byId[item.id]=item;byModel[item.model]=item
 if item.model:match("^infinity_") then
  stoneCount=stoneCount+1
  check(original.Tiers[item.tier]=="Legendary","Each Infinity Stone is Legendary")
 end
end
check(stoneCount==6,"All six distinct Infinity Stones are cataloged")
check(byId.item08==original.ById.item08 and byId.item08.model=="puzzle","The beloved Millennium Puzzle catalog entry is retained")
check(byId.item43.model=="dragonballs","Existing Dragon Balls catalog entry retained")
check(byModel.pekka and byModel.mega_knight and byModel.kirby_sword,"P.E.K.K.A, Mega Knight and Kirby Sword are cataloged")

-- The flight route closes at 32 seconds with continuous direction. Component
-- articulation must preserve scaled shoulder hinges and avoid cumulative drift.
local origin=CFrame.new(30,62,-90)*CFrame.Angles(0,.7,0)
for step=0,256 do
 local time=step*.125
 local cf=Flight.position(origin,time)
 check(frameFinite(cf),"Flight position and orientation remain finite")
 check(frameNear(cf,Flight.position(origin,time+32)),"Flight route repeats smoothly every 32 seconds")
 local localPos=origin:PointToObjectSpace(cf.Position)
 check(localPos.Y>=5-1e-5 and localPos.Y<=11+1e-5,"Flight stays above the tower origin")
 if step>0 then
  local prior=Flight.position(origin,time-.125)
  check((cf.Position-prior.Position).Magnitude<1,"Flight has no discontinuous jumps")
 end
end
for _,scale in ipairs({.5,2}) do
 local bird=Instance.new("Model")
 bird:SetAttribute("FlightScale",scale)
 for name,key in pairs({Body="hooh_body",LeftWing="hooh_wing_left",RightWing="hooh_wing_right",Tail="hooh_tail"}) do
  local component=F.create(bird,options(key,scale))
  component.Name=name
 end
 for _,time in ipairs({0,.45,4.1,15,31.999}) do
  local flight=Flight.pose(bird,origin,time)
  check(frameNear(bird:FindFirstChild("Body"):GetPivot(),flight),"Body follows the returned flight frame")
  for name,shoulder in pairs({LeftWing=Vector3.new(-1.08,.61,.02),RightWing=Vector3.new(1.08,.61,.02)}) do
   local wing=bird:FindFirstChild(name)
   check(((wing:GetPivot()*(shoulder*scale))-(flight*(shoulder*scale))).Magnitude<1e-5,"Scaled wing shoulder stays attached: "..name)
  end
  local before={}
  for i,p in ipairs(bird:GetDescendants()) do if p:IsA("BasePart") then before[i]=p.CFrame end end
  for _=1,5 do Flight.pose(bird,origin,time) end
  for i,p in ipairs(bird:GetDescendants()) do
   if p:IsA("BasePart") then
    check(frameNear(p.CFrame,before[i]),"Repeated poses do not accumulate movement drift")
    check(frameFinite(p.CFrame) and p.Anchored and not p.CanCollide,"Animated geometry remains finite and noninteractive")
   end
  end
 end
end
print(string.format("PASS: %d checks; %d native models / %d parts; 17 unique catalog additions, six Legendary stones, scaling/pivots/collision contracts and 32-second Ho-Oh flight",checks,models,parts))
