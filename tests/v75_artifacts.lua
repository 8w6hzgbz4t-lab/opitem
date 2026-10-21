-- Execute the actual factory and cosmetic service with geometry/Instance doubles.
-- Weld following here is a controlled API simulation, not a Studio physics test.
local Mock=dofile('tools/roblox_mock.lua')
local root=arg[1] or 'roblox/v75-game'
local output=arg[2] or '/tmp/opitem-v75-artifacts.json'
local create=Instance.new
local all={}
Instance.new=function(class,parent)
 local instance=create(class=='WeldConstraint' and 'Folder' or class,parent)
 if class=='WeldConstraint' then instance._class=class;instance.Name=class end
 all[#all+1]=instance
 return instance
end
local meta=getmetatable(create('Model'))
local originalIndex,originalNewIndex=meta.__index,meta.__newindex
local function descendant(instance,parent)
 local node=instance.Parent
 while node do if node==parent then return true end;node=node.Parent end
 return false
end
local function children(instance)
 local result={};for _,child in ipairs(instance._children) do result[#result+1]=child end;return result
end
local function clone(original)
 local copies={}
 local function copyTree(source)
  local copy=Instance.new(source._class);copies[source]=copy
  for name,value in pairs(source._props) do if name~='Parent' then copy[name]=value end end
  for name,value in pairs(source._attrs) do copy:SetAttribute(name,value) end
  for _,child in ipairs(source:GetChildren()) do copyTree(child).Parent=copy end
  return copy
 end
 local result=copyTree(original)
 for _,copy in pairs(copies) do for name,value in pairs(copy._props) do if copies[value] then copy[name]=copies[value] end end end
 return result
end
local function scaleTo(model,scale)
 local previous=model._props._modelScale or 1;local ratio=scale/previous
 local pivot=model:GetPivot()
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA('BasePart') then
   local localFrame=pivot:ToObjectSpace(part.CFrame)
   part.Size=part.Size*ratio
   part.CFrame=pivot*CFrame.new(localFrame.Position*ratio)*localFrame.Rotation
  end
 end
 model._props._modelScale=scale
end
meta.__index=function(instance,key)
 if key=='Clone' then return clone end
 if key=='GetScale' then return function(model)return model._props._modelScale or 1 end end
 if key=='ScaleTo' then return scaleTo end
 if key=='IsDescendantOf' then return descendant end
 if key=='GetChildren' then return children end
 if key=='Destroy' then return function(object)
  for _,child in ipairs(children(object)) do child:Destroy() end
  object.Parent=nil;object._props._destroyed=true
 end end
 return originalIndex(instance,key)
end
meta.__newindex=function(instance,key,value)
 local old=key=='CFrame' and instance._props.CFrame
 originalNewIndex(instance,key,value)
 if old then
  local transform=value*old:Inverse()
  for _,joint in ipairs(all) do
   if joint._class=='WeldConstraint' and joint.Parent and joint.Part0==instance and joint.Part1 and joint.Part1.Parent then
    local part=joint.Part1
    originalNewIndex(part,'CFrame',transform*part.CFrame)
   end
  end
 end
end
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function near(a,b,message,tolerance)
 check(math.abs(a-b)<(tolerance or 1e-8),message)
end
local function sameFrame(a,b,message)
 local ac,bc={a:GetComponents()},{b:GetComponents()}
 for index=1,12 do near(ac[index],bc[index],message..' component '..index) end
end
local function parts(model)
 local result={};for _,part in ipairs(model:GetDescendants()) do if part:IsA('BasePart') then result[#result+1]=part end end
 return result
end
local function frames(model,reference)
 local out={};for _,part in ipairs(parts(model)) do out[part]=reference:ToObjectSpace(part.CFrame) end;return out
end
local Factory=Mock.loadModule(root..'/ModelFactory.lua')
local Catalog=Mock.loadModule(root..'/Catalog.lua')
local Artifacts=Mock.loadModule(root..'/DeveloperArtifacts.lua')
local world=Instance.new('Folder');world.Name='Workspace'
local templates=Instance.new('Folder');templates.Name='Models';templates.Parent=world
local puzzle=Factory.create(Catalog.ById.item08,templates);puzzle.Name='item08'
local rod=Factory.create(Catalog.ById.item23,templates);rod.Name='item23'
local originalPuzzle=Mock.json(Mock.record(puzzle));local originalRod=Mock.json(Mock.record(rod))
check(#parts(puzzle)==137,'Exact 137-part Millennium Puzzle must be used')
check(rod:FindFirstChild('RodEyePupil',true)~=nil,'Original detailed rod eye required')
local now=100
local service=Artifacts.new(templates,function()return now end)
local function actor(rig,id)
 local character=Instance.new('Model');character.Name=rig..'Character';character.Parent=world
 local torso=Instance.new('Part',character);torso.Name=rig=='R15' and 'UpperTorso' or 'Torso'
 torso.CFrame=CFrame.new(id*.1,5,7)*CFrame.Angles(.07,.6,-.09);torso.Size=Vector3.new(2,2,1)
 local hand=Instance.new('Part',character);hand.Name=rig=='R15' and 'RightHand' or 'Right Arm'
 hand.CFrame=torso.CFrame*CFrame.new(1.5,-.2,0)*CFrame.Angles(.2,0,.14)
 local rootPart=Instance.new('Part',character);rootPart.Name='HumanoidRootPart';rootPart.CFrame=torso.CFrame
 return {UserId=id,Character=character},torso,hand,rootPart
end
local function assertCosmetic(model,body,source,ratio,extraParts)
 check(model and model.Parent==body.Parent,'Cosmetic must attach inside current character')
 check(model:GetAttribute('Kind')==nil and model:GetAttribute('ItemId')==nil,'Cosmetic must not register as collectible')
 check(model:GetAttribute('DeveloperCosmetic') and model:GetAttribute('DecorativeOnly'),'Cosmetic identity flags missing')
 check(#parts(model)==#parts(source)+(extraParts or 0),'Unexpected cosmetic geometry count')
 for _,part in ipairs(parts(model)) do
  check(not part.Anchored and part.Massless==true,'Cosmetic part must be unanchored and massless')
  check(not part.CanCollide and not part.CanTouch and not part.CanQuery,'Cosmetic part must not affect interaction')
  local joints={};for _,child in ipairs(part:GetChildren()) do if child:IsA('WeldConstraint') then joints[#joints+1]=child end end
  check(#joints==1 and joints[1].Part0==body and joints[1].Part1==part,'Each cosmetic part must have one correct body weld')
  check(part:GetAttribute('Kind')==nil and part:GetAttribute('ItemId')==nil,'Cosmetic descendant leaked item identity')
 end
 for _,sourcePart in ipairs(parts(source)) do
  local actual=assert(model:FindFirstChild(sourcePart.Name,true),'Missing exact source part '..sourcePart.Name)
  near(actual.Size.X,sourcePart.Size.X*ratio,'Exact scaled source X');near(actual.Size.Y,sourcePart.Size.Y*ratio,'Exact scaled source Y');near(actual.Size.Z,sourcePart.Size.Z*ratio,'Exact scaled source Z')
  local expected=source:GetPivot():ToObjectSpace(sourcePart.CFrame)
  sameFrame(model:GetPivot():ToObjectSpace(actual.CFrame),CFrame.new(expected.Position*ratio)*expected.Rotation,'Exact source geometry retained')
 end
end
local function activeWelds(character)
 local n=0;for _,joint in ipairs(all) do if joint._class=='WeldConstraint' and joint.Parent and descendant(joint,character) then n=n+1 end end;return n
end
local rigs={}
for index,rig in ipairs({'R6','R15'}) do
 local player,torso,hand,rootPart=actor(rig,700+index)
 service:setProtected(player,true)
 local pendant=service.records[player.UserId].puzzle
 assertCosmetic(pendant,torso,puzzle,.25,16)
 check(pendant:GetAttribute('ProtectionEmblem')==true,'Protected marker missing')
 check(pendant:GetAttribute('PartCount')==153,'Pendant part count should include fitted chains')
 local expectedPivot=torso.CFrame*CFrame.new(0,-.58,-.72)
 sameFrame(pendant:GetPivot(),expectedPivot,'Puzzle anchored to chest')
 local localParts=frames(pendant,torso.CFrame)
 torso.CFrame=torso.CFrame*CFrame.new(2,1,-3)*CFrame.Angles(.2,-.3,.1)
 for part,frame in pairs(localParts) do sameFrame(torso.CFrame:ToObjectSpace(part.CFrame),frame,'Puzzle follows torso weld') end
 service:setProtected(player,true)
 check(service.records[player.UserId].puzzle==pendant,'Repeated protection must not recreate pendant')
 check(activeWelds(player.Character)==153,'Repeated protection must not leak duplicate welds')
 local origin=service:pulseRod(player)
 local casting=service.records[player.UserId].rod
 assertCosmetic(casting,hand,rod,.46,0)
 check(casting:GetAttribute('CastingArtifact')==true,'Casting marker missing')
 check((origin-casting:FindFirstChild('RodEyePupil',true).Position).Magnitude<1e-8,'Cast must begin at exact original rod eye')
 local before=frames(casting,hand.CFrame)
 hand.CFrame=hand.CFrame*CFrame.new(-1,.4,.3)*CFrame.Angles(-.1,.4,.2)
 for part,frame in pairs(before) do sameFrame(hand.CFrame:ToObjectSpace(part.CFrame),frame,'Rod follows hand weld') end
 now=now+.5;origin=service:pulseRod(player)
 check(service.records[player.UserId].rod==casting,'Repeated cast must reuse held rod')
 check((origin-casting:FindFirstChild('RodEyePupil',true).Position).Magnitude<1e-8,'Repeated cast eye origin must follow moved hand')
 now=now+1.0;service:tick();check(casting.Parent==player.Character,'Recast must extend rod lifetime')
 now=now+.26;service:tick();check(casting.Parent==nil and service.records[player.UserId].rod==nil,'Rod must expire after final cast')
 check(pendant.Parent==player.Character,'Rod expiry must not remove active protection')
 service:setProtected(player,false);check(pendant.Parent==nil and service.records[player.UserId].puzzle==nil,'Protection off must remove worn puzzle')
 check(activeWelds(player.Character)==0,'Expired cosmetics must leave no character welds')
 service:setProtected(player,true);service:pulseRod(player)
 local oldPuzzle,oldRod=service.records[player.UserId].puzzle,service.records[player.UserId].rod
 service:clear(player)
 check(service.records[player.UserId]==nil and oldPuzzle.Parent==nil and oldRod.Parent==nil,'Reset/carry cleanup must remove every artifact')
 check(activeWelds(player.Character)==0,'Full cleanup must leave no constraints')
 for repeatIndex=1,8 do service:setProtected(player,true);service:setProtected(player,false) end
 check(activeWelds(player.Character)==0,'Repeated on/off must remain leak-free')
 service:setProtected(player,true);service:pulseRod(player)
 oldPuzzle,oldRod=service.records[player.UserId].puzzle,service.records[player.UserId].rod
 local replacement=actor(rig,900+index);player.Character=replacement.Character
 service:setProtected(player,true)
 check(oldPuzzle.Parent==nil and oldRod.Parent==nil,'Character replacement must destroy prior cosmetics')
 check(service.records[player.UserId].character==replacement.Character,'Character record must bind current rig')
 replacement.Character.Parent=nil;service:tick()
 check(service.records[player.UserId]==nil,'Character removal must release artifact record')
 check(not torso.Anchored and not hand.Anchored and not rootPart.Anchored,'Cosmetics must never anchor character body')
 rigs[#rigs+1]={rig=rig,puzzle_parts=153,rod_parts=#parts(rod),following_verified=true,cleanup_verified=true}
end
local missing=Artifacts.new(Instance.new('Folder'),function()return now end)
local player,torso,hand=actor('R15',804)
missing:setProtected(player,true)
check(not missing.records[player.UserId].puzzle,'Missing puzzle template must fail safely')
check((missing:pulseRod(player)-hand.Position).Magnitude<1e-8,'Missing rod template must fall back to hand')
player.Character=nil
check(missing:pulseRod(player)==nil,'Absent character must not create rod')
service:clear(player);missing:clear(player)
check(Mock.json(Mock.record(puzzle))==originalPuzzle,'Original item08 template changed')
check(Mock.json(Mock.record(rod))==originalRod,'Original item23 template changed')
local report={passed=true,assertions=checks,source_root=root,rigs=rigs,exact_puzzle_geometry_preserved=true,
 exact_rod_geometry_preserved=true,original_factory_templates_unchanged=true,all_cosmetic_parts_noninteractive_massless_unanchored=true,
 body_and_hand_weld_contracts_verified=true,rod_eye_origin_verified=true,repeated_cast_lifetime_cleanup_verified=true,
 repeated_protection_and_character_cleanup_verified=true,missing_templates_and_characters_fail_safely=true,
 studio_physics_rendering_multiplayer_tested=false,scope='Actual factory item08/item23 and DeveloperArtifacts executed; controlled Instance, ScaleTo, Clone and weld-following adapter'}
local file=assert(io.open(output,'w'));file:write(Mock.json(report));file:close()
print('ARTIFACT PASS '..checks..' assertions; exact 137-part puzzle; R6/R15 torso and hand welds; exact rod eye origin; lifecycle cleanup; source templates preserved')
