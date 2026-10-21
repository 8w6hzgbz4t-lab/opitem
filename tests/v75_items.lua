-- Execute every active collectible factory route and record real generated geometry.
-- This is an offline contract check; it does not simulate Studio rendering or physics.
local Mock=dofile('tools/roblox_mock.lua')
local make=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 local instance=make(geometry[class] and class or 'Folder',parent)
 if not geometry[class] then instance._class=class;instance.Name=class end
 function instance:FindFirstChildOfClass(className)
  for _,child in ipairs(self:GetChildren())do if child:IsA(className)then return child end end
 end
 return instance
end
UDim2={fromOffset=function(x,y)return {x,y} end,fromScale=function(x,y)return {x,y} end,new=function(...)return {...} end}
UDim={new=function(...)return {...} end}
Vector2={new=function(x,y)return {X=x,Y=y} end}
local colors=getmetatable(Color3.new(0,0,0)).__index
function colors:ToHSV()
 local maximum=math.max(self.R,self.G,self.B);local minimum=math.min(self.R,self.G,self.B)
 local delta=maximum-minimum;local hue=0
 if delta>0 then
  if maximum==self.R then hue=((self.G-self.B)/delta)%6
  elseif maximum==self.G then hue=(self.B-self.R)/delta+2
  else hue=(self.R-self.G)/delta+4 end
 end
 return hue/6,maximum==0 and 0 or delta/maximum,maximum
end

local root=arg[1] or 'roblox/v75-game'
local out=assert(arg[2],'Output folder required')
local baselineRoot=arg[3] or 'roblox/v74-game'
local Factory=Mock.loadModule(root..'/ModelFactory.lua')
local Catalog=Mock.loadModule(root..'/Catalog.lua')
local Baseline=Mock.loadModule(baselineRoot..'/Catalog.lua')
local BaselineFactory=Mock.loadModule(baselineRoot..'/ModelFactory.lua')
local checks=0
local function check(value,message)
 checks=checks+1;assert(value,message)
end
local function finite(value)return type(value)=='number' and value==value and math.abs(value)<math.huge end
local function fieldsEqual(a,b,path)
 check(type(a)==type(b),'Catalog type changed: '..path)
 if type(a)=='table' then
  for key,value in pairs(a)do check(b[key]~=nil,'Catalog field removed: '..path..'.'..key);fieldsEqual(value,b[key],path..'.'..key)end
  for key in pairs(b)do check(a[key]~=nil,'Catalog field added: '..path..'.'..key)end
 else check(a==b,'Catalog field changed: '..path)end
end
check(#Baseline.Items==69,'Expected complete Version 74 baseline')
for index,old in ipairs(Baseline.Items)do
 local current=assert(Catalog.Items[index],'Existing item missing: '..old.id)
 check(current.id==old.id,'Existing item ID/order changed: '..old.id)
 fieldsEqual(old,current,'Items.'..old.id)
end
for _,key in ipairs({'Weights','RarityWeights','SpawnSettings','Tiers','Colors'})do fieldsEqual(Baseline[key],Catalog[key],key)end
check(#Catalog.Items==76,'Expected 69 preserved items plus seven new collectibles')
local added={stardust_dragon=true,blue_eyes_white_dragon=true,michael_jackson_glove=true,tungs_bat=true,moms_credit_card=true,sonic_gold_ring=true,captain_america_shield=true}
for index=70,76 do check(added[Catalog.Items[index].id],'Unexpected appended collectible')end
local report={source=root,baseline=baselineRoot,items={},failures={},warnings={},changedGeometry={},catalog={},baselineCatalog=Baseline.Items,tiers=Catalog.Tiers,weights=Catalog.Weights}
local function signature(spec)
 return Mock.json({name=spec.name,attributes=spec.attributes,parts=spec.parts,bounds=spec.bounds})
end
local function completeTreeSignature(model)
 -- Compare every generated instance property and attribute, including complete
 -- SurfaceGui/TextLabel styling. Exclude only Python/Lua mock helper functions.
 local function value(v)
  if typeof(v)=='Instance' then
   local names={};while v and v~=model do table.insert(names,1,v.Name);v=v.Parent end
   return {instance=table.concat(names,'/')}
  elseif typeof(v)=='Vector3' then return {vector3={v.X,v.Y,v.Z}}
  elseif typeof(v)=='CFrame' then return {cframe={v:GetComponents()}}
  elseif type(v)=='table' then
   local result={};for key,entry in pairs(v)do if type(entry)~='function' then result[key]=value(entry)end end;return result
  end
  return v
 end
 local function tree(instance)
  local props={}
  for key,entry in pairs(instance._props)do if key~='Parent' and type(entry)~='function' then props[key]=value(entry)end end
  local children={};for _,child in ipairs(instance:GetChildren())do children[#children+1]=tree(child)end
  return {class=instance._class,properties=props,attributes=value(instance._attrs),children=children}
 end
 return Mock.json(tree(model))
end
local function recordOverlays(model)
 local overlays={}
 for _,gui in ipairs(model:GetDescendants())do
  if gui:IsA('SurfaceGui') then
   for _,label in ipairs(gui:GetDescendants())do
    if label:IsA('TextLabel') and type(label.Text)=='string' then
     local p=gui.Parent
     overlays[#overlays+1]={part=p.Name,text=label.Text,color={label.TextColor3.R,label.TextColor3.G,label.TextColor3.B}}
    end
   end
  end
 end
 return overlays
end
for index,d in ipairs(Catalog.Items)do
 report.catalog[#report.catalog+1]=d
 local ok,result=pcall(function()
  local parent=make('Folder');parent.Name='AuditItems'
  local model=Factory.create(d,parent)
  check(model.Parent==parent,d.id..': returned model has wrong parent')
  check(model.Name==d.name,d.id..': model name does not match catalog')
  check(model:GetAttribute('Kind')==d.id,d.id..': wrong Kind attribute')
  check(model.PrimaryPart~=nil,d.id..': missing pivot root')
  local spec=Mock.record(model)
  local baselineModel=Baseline.ById[d.id] and BaselineFactory.create(Baseline.ById[d.id],nil)
  local baselineSpec=baselineModel and Mock.record(baselineModel)
  local changed=baselineSpec and signature(baselineSpec)~=signature(spec) or false
  if changed then
   report.changedGeometry[#report.changedGeometry+1]=d.id
   check(false,d.id..': existing item geometry changed')
  end
  spec.id=d.id;spec.catalogModel=d.model;spec.tier=d.tier;spec.textOverlays=recordOverlays(model)
  if baselineModel then
   check(Mock.json(spec.textOverlays)==Mock.json(recordOverlays(baselineModel)),d.id..': existing surface text changed')
   check(completeTreeSignature(model)==completeTreeSignature(baselineModel),d.id..': existing instance hierarchy, GUI styling or attributes changed')
  end
  local visible,materialSet,colorsSet,nameSet=0,{},{},{}
  for _,part in ipairs(spec.parts)do
   check(not part.canCollide and not part.canQuery and not part.canTouch,d.id..': interactive geometry '..part.name)
   for _,value in ipairs(part.cf)do check(finite(value),d.id..': nonfinite frame '..part.name)end
   for _,value in ipairs(part.size)do check(finite(value) and value>0,d.id..': invalid size '..part.name)end
   for _,value in ipairs(part.color)do check(finite(value) and value>=0 and value<=1,d.id..': invalid color '..part.name)end
   local r=part.cf
   for a=0,2 do for b=0,2 do
    local dot=r[4+a]*r[4+b]+r[7+a]*r[7+b]+r[10+a]*r[10+b]
    check(math.abs(dot-(a==b and 1 or 0))<1e-6,d.id..': non-orthogonal frame '..part.name)
   end end
   if part.transparency<1 then
    visible=visible+1;materialSet[part.material]=true
    colorsSet[string.format('%.3f %.3f %.3f',table.unpack(part.color))]=true
    nameSet[part.name:gsub('%d+','')]=true
   end
  end
  check(visible>=20,d.id..': placeholder/simple geometry with only '..visible..' visible parts')
  check(#spec.parts<=240,d.id..': collectible part budget exceeded')
  for _,value in ipairs(spec.bounds.size)do check(finite(value) and value>0 and value<=8,d.id..': item exceeds display envelope')end
  check(math.max(spec.bounds.size[1],spec.bounds.size[3])<=5.5,d.id..': horizontal footprint exceeds display/carry envelope')
  if index>46 then
   check(math.abs(spec.bounds.min[2]-.04)<1e-5,d.id..': new item is not aligned above its display/carry pivot')
  end
  if d.id=='item43'then
   for number=1,7 do
    check(model:FindFirstChild('DragonBall_'..number)~=nil,'Dragon Balls missing orb '..number)
    local strokes=0
    for _,part in ipairs(spec.parts)do
     if part.name:match('^Ball'..number..'Star%d+Stroke%d+$')then strokes=strokes+1 end
    end
    check(strokes==number*5,'Dragon Ball '..number..' has wrong number of star strokes')
   end
  elseif d.id=='item45' or d.id=='item46'then
   check(model:GetAttribute('EmptyCostume')==true,d.id..': empty suit marker missing')
   check(model:GetAttribute('ContainsCharacter')==false,d.id..': suit must remain empty')
   for _,child in ipairs(model:GetDescendants())do
    check(not child:IsA('Humanoid') and not child:IsA('AnimationController'),d.id..': empty suit contains character machinery')
   end
  end
  if d.id=='krabby_patty_formula' then
   for _,name in ipairs({'GreenGlassBottleBody','LongNarrowBottleNeck','FittedCorkStopper','RolledSecretRecipe','FormulaLabel','FormulaBrand','RedWaxSeal','NeckTwineTurn0_0','RecipeInkStroke0'})do
    check(model:FindFirstChild(name,true)~=nil,'Secret Formula missing visible detail: '..name)
   end
   check(model:GetAttribute('SealedRecipeBottle')==true,'Formula must be a sealed recipe bottle')
   local glass=model:FindFirstChild('GreenGlassBottleBody',true)
   local recipe=model:FindFirstChild('RolledSecretRecipe',true)
   check(glass.Material==Enum.Material.Glass and glass.Transparency>=.5 and glass.Transparency<.9,'Bottle body must expose the recipe through glass')
   check((recipe.Transparency or 0)==0 and math.abs(recipe.Position.X-glass.Position.X)<.5,'Real recipe must remain opaque inside the bottle')
   check(recipe.Position.Y>glass.Position.Y and recipe.Position.Y<glass.Position.Y+1,'Recipe top must be visible above the label')
   local texts={};for _,overlay in ipairs(spec.textOverlays)do texts[overlay.text]=true end
   check(texts['SECRET\nFORMULA'] and texts['THE KRUSTY KRAB'],'Formula needs real readable identifying surface labels')
  end
  if added[d.id] then
   check(model:GetAttribute('ArtVersion')==75,d.id..': missing native version 75 art marker')
   check(model:GetAttribute('ArtSource')=='NativeRobloxParts' and model:GetAttribute('FreeModelKey')==d.id,d.id..': requested native model is not routed into the real factory')
   local function feature(prefix)
    for _,part in ipairs(spec.parts)do if part.name:sub(1,#prefix)==prefix then return true end end
    return false
   end
   if d.id=='stardust_dragon' or d.id=='blue_eyes_white_dragon' then
    for _,key in ipairs({'SculptedDragonHead','OpenDragonMouth','ConnectedTaperedTail'})do check(model:GetAttribute(key)==true,d.id..': missing dragon feature '..key)end
    check(model:GetAttribute('NativePolygonWings')==2 and model:GetAttribute('RecessedSeparateEyes')==2 and model:GetAttribute('ArticulatedClawedLimbs')==4,d.id..': incomplete dragon anatomy')
    for _,prefix in ipairs({'SculptedDragonCranium','LongUpperMuzzle','SeparateLowerJaw','OpenMouthRecess','SignatureDragonEye','UpperJawFang','LeftWingUpperMembrane','RightWingUpperMembrane','LeftWingLongWingFinger','RightWingLongWingFinger','ConnectedTailSegment8','SharpTailTip','SharpFootTalon','HandTalon'})do check(feature(prefix),d.id..': missing visible dragon feature '..prefix)end
    local crown=d.id=='stardust_dragon' and 'StardustLongCrownHorn' or 'BlueEyesRearSweptHorn'
    check(feature(crown),d.id..': missing signature crown')
    check(d.id~='stardust_dragon' or feature('LeftWingSilverRayFeather2'), 'Stardust must have distinct layered silver ray feathers')
   elseif d.id=='michael_jackson_glove' then
    check(model:GetAttribute('FingerCount')==5 and model:GetAttribute('RhinestoneCount')>=80,'Michael Jackson glove must have five tailored fingers and dense rhinestones')
    for _,prefix in ipairs({'TailoredGlovePalm','FittedWristCuff','IndexFingerSegment','MiddleFingerSegment','RingFingerSegment','PinkyFingerSegment','ThumbTailoredSegment','PalmRhinestone','StoneGlintVertical'})do check(feature(prefix),'Glove missing detail '..prefix)end
   elseif d.id=='tungs_bat' then
    check(model:GetAttribute('RealTaperedShoulder')==true and model:GetAttribute('WrappedGripBands')==12 and model:GetAttribute('NativeRaisedName')=='TUNGS','Tungs Bat needs tapered wood, wrapped grip and physical brand')
    for _,prefix in ipairs({'TurnedAshBarrel','RoundedWoodBarrelCap','TaperedWoodShoulder','LongWoodHandle','TurnedBatKnob','BarrelWoodGrain','TungsBarrelBrand','DarkLeatherGripBand11'})do check(feature(prefix),'Bat missing detail '..prefix)end
   elseif d.id=='moms_credit_card' then
    check(d.tier==7 and d.rarity=='Ethereal','Moms Credit Card must be Ethereal')
    for _,key in ipairs({'RoundedMetalCard','RaisedMomsLettering','FictionalCard','NoPersonalPaymentData'})do check(model:GetAttribute(key)==true,'Credit card missing detail '..key)end
    check(model:GetAttribute('ContactlessArcCount')==3,'Credit card needs three contactless arcs')
    for _,prefix in ipairs({'PlatinumCardBody','BlackCeramicCardFace','MomsCardEmbossedTitle','GoldMicrochipBody','ContactPad','ContactlessArc3','EtherealHologramFacet','RearMagneticStripe','RearSignaturePanel'})do check(feature(prefix),'Credit card missing visible detail '..prefix)end
   elseif d.id=='sonic_gold_ring' then
    check(model:GetAttribute('TrueOpenRing')==true and model:GetAttribute('RoundedRingSegments')==24,'Sonic Ring needs a genuine open rounded ring')
    for _,prefix in ipairs({'RoundedGoldenRingSegment23','RoundedRingJoint','PolishedRingBevel','BlueSpeedPlinth','GoldPlinthInset','BlueSpeedTrail','RingSparkleLong'})do check(feature(prefix),'Sonic Ring missing detail '..prefix)end
   elseif d.id=='captain_america_shield' then
    check(model:GetAttribute('ConcentricShieldBands')==4 and model:GetAttribute('StarPointCount')==5 and model:GetAttribute('RearOpenStrapCount')==2,'Captain America shield needs four bands, five-point star and two real rear straps')
    for _,prefix in ipairs({'ConvexShieldBacking','BrushedMetalOuterRim','OuterRedShieldFace','SilverConcentricBand','BlueStarMedallion','RaisedFivePointStar','MachinedOuterRimLine','LeatherStrapMiddle','RearStrapRivet'})do check(feature(prefix),'Captain America shield missing detail '..prefix)end
   end
  end
  local moved=CFrame.new(12,21,-8)*CFrame.Angles(.17,.81,-.22)
  local original={}
  for _,part in ipairs(model:GetDescendants())do if part:IsA('BasePart')then original[#original+1]={part,part.CFrame}end end
  model:PivotTo(moved)
  check((model:GetPivot().Position-moved.Position).Magnitude<1e-6,d.id..': pivot did not follow carry transform')
  for _,entry in ipairs(original)do
   local expected=moved*entry[2]
   check((entry[1].Position-expected.Position).Magnitude<1e-6,d.id..': part detached when carried '..entry[1].Name)
  end
  if d.id=='item08'then
   local compare={name=spec.name,attributes=spec.attributes,parts=spec.parts,bounds=spec.bounds}
   check(signature(baselineSpec)==signature(compare),'Millennium Puzzle geometry changed')
   check(#spec.parts==137,'Original Millennium Puzzle must remain exactly 137 parts')
   report.puzzleUnchanged=true
  end
  local function count(values)local n=0;for _ in pairs(values)do n=n+1 end;return n end
  local row={id=d.id,name=d.name,catalog_model=d.model,new=index>69,parts=#spec.parts,visible_parts=visible,
   bounds=spec.bounds,colors=count(colorsSet),materials=count(materialSet),distinct_details=count(nameSet),
   supplied_key=model:GetAttribute('FreeModelKey'),text_overlays=#spec.textOverlays,changed=changed}
  if math.max(spec.bounds.size[1],spec.bounds.size[3])>5.5 then
   report.warnings[#report.warnings+1]=d.id..': horizontal footprint exceeds 5.5 studs ('..string.format('%.2f',math.max(spec.bounds.size[1],spec.bounds.size[3]))..')'
  end
  local f=assert(io.open(out..'/'..d.id..'.json','w'));f:write(Mock.json(spec));f:close()
  return row
 end)
 if ok then report.items[#report.items+1]=result
 else report.failures[#report.failures+1]={id=d.id,name=d.name,error=tostring(result)}end
end
-- Exercise the exact Studio-side art utility as well, with only a scheduler stub.
local artChecksFile=io.open(root..'/ArtChecks.lua','r')
if artChecksFile then
 artChecksFile:close()
 task={wait=function()end}
 local runArtChecks=Mock.loadModule(root..'/ArtChecks.lua')
 local studioReport=runArtChecks({Catalog=root..'/Catalog.lua',ModelFactory=root..'/ModelFactory.lua'})
 check(studioReport.models==#Catalog.Items,'Studio art utility did not audit every catalog entry')
 for _,row in ipairs(report.items)do check(studioReport.counts[row.id]==row.parts,'Studio art utility count mismatch: '..row.id)end
 report.studioArtUtilityPassed=true
end
report.checks=checks
local f=assert(io.open(out..'/audit.json','w'));f:write(Mock.json(report));f:close()
for _,failure in ipairs(report.failures)do print('FAIL '..failure.id..' '..failure.error)end
for _,warning in ipairs(report.warnings)do print('WARNING '..warning)end
print(string.format('AUDIT %d/%d items; %d checks; %d warnings; puzzle unchanged: %s',#report.items,#Catalog.Items,checks,#report.warnings,tostring(report.puzzleUnchanged)))
assert(#report.failures==0,'Actual collectible factory audit failed')
