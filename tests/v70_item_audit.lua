-- Execute every active collectible factory route and record real generated geometry.
-- This is an offline contract check; it does not simulate Studio rendering or physics.
local Mock=dofile('tools/roblox_mock.lua')
local make=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class] then return make(class,parent) end
 local instance=make('Folder',parent);instance._class=class;instance.Name=class;return instance
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

local root=arg[1] or 'roblox/v70-game'
local out=assert(arg[2],'Output folder required')
local baselineRoot=arg[3] or 'roblox/v69-original/OPItemV2'
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
fieldsEqual(Baseline.Items,Catalog.Items,'Items')
fieldsEqual(Baseline.Weights,Catalog.Weights,'Weights')
fieldsEqual(Baseline.SpawnSettings,Catalog.SpawnSettings,'SpawnSettings')
check(#Catalog.Items==65,'Expected actual Version 69 catalog count of 65')
local report={source=root,baseline=baselineRoot,items={},failures={},warnings={},changedGeometry={}}
local approvedModelChanges={black_lotus=true,death_note=true,krabby_patty=true}
local function signature(spec)
 -- Model attributes and all recorded geometry stay stable for the protected puzzle.
 return Mock.json(spec)
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
 local ok,result=pcall(function()
  local parent=make('Folder');parent.Name='AuditItems'
  local model=Factory.create(d,parent)
  check(model.Parent==parent,d.id..': returned model has wrong parent')
  check(model.Name==d.name,d.id..': model name does not match catalog')
  check(model:GetAttribute('Kind')==d.id,d.id..': wrong Kind attribute')
  check(model.PrimaryPart~=nil,d.id..': missing pivot root')
  local spec=Mock.record(model)
  local baselineSpec=Mock.record(BaselineFactory.create(Baseline.ById[d.id],nil))
  local changed=signature(baselineSpec)~=signature(spec)
  if changed then
   report.changedGeometry[#report.changedGeometry+1]=d.id
   check(approvedModelChanges[d.id],d.id..': unrelated model changed')
  end
  spec.id=d.id;spec.catalogModel=d.model;spec.tier=d.tier;spec.textOverlays=recordOverlays(model)
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
  check(#spec.parts<=700,d.id..': collectible part budget exceeded')
  for _,value in ipairs(spec.bounds.size)do check(finite(value) and value>0 and value<=8,d.id..': item exceeds display envelope')end
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
   report.puzzleUnchanged=true
  end
  local function count(values)local n=0;for _ in pairs(values)do n=n+1 end;return n end
  local row={id=d.id,name=d.name,catalog_model=d.model,new=index>46,parts=#spec.parts,visible_parts=visible,
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
