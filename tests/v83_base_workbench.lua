-- Execute actual BaseWorkbench geometry; no Roblox rendering/physics is simulated.
local Mock=dofile('tools/roblox_mock.lua')
local geometryNew=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class]then return geometryNew(class,parent)end
 local item=geometryNew('Folder',parent);item._class=class;item.Name=class;return item
end
Vector2={new=function(x,y)return{X=x,Y=y}end}
UDim2={fromScale=function(...)return{...}end}
local root=arg[1]or'roblox/v83-game'
local Bench=Mock.loadModule(root..'/BaseWorkbench.lua')
local checks,models,partsTotal,collisionParts=0,{},0,0
local function check(value,message)checks=checks+1;assert(value,message)end
local world={folder=geometryNew('Folder')};world.folder.Name='OPItemWorld'
local untouched=geometryNew('Model',world.folder);untouched.Name='ExistingPowerWorkbench'
local benchBounds={}
local function crosses(part,a,b)
 local start=part.CFrame:PointToObjectSpace(a)
 local finish=part.CFrame:PointToObjectSpace(b)
 local low,high=0,1
 for _,axis in ipairs({'X','Y','Z'})do
  local delta=finish[axis]-start[axis];local half=part.Size[axis]/2
  if math.abs(delta)<1e-9 then
   if math.abs(start[axis])>half then return false end
  else
   local enter=(-half-start[axis])/delta;local leave=(half-start[axis])/delta
   if enter>leave then enter,leave=leave,enter end
   low=math.max(low,enter);high=math.min(high,leave)
   if low>high then return false end
  end
 end
 return true
end
for index=1,8 do
 local x=-84+((index-1)%4)*56
 local z=index<=4 and -57 or 57
 local base=CFrame.new(x,0,z)*CFrame.Angles(0,z<0 and math.pi or 0,0)
 local anchor=geometryNew('Part',world.folder);anchor.Name='Vault Manager'
 anchor.CFrame=base*CFrame.new(-16,2.2,-17);anchor.Size=Vector3.new(3,2.5,3)
 anchor:SetAttribute('OwnerUserId',index*11)
 local trigger=Instance.new('ProximityPrompt',anchor);trigger.ActionText='Manage base items'
 local fired=0;trigger.Triggered=function()fired=fired+1 end
 local originalCF=Mock.json({anchor.CFrame:GetComponents()})
 local originalParent=anchor.Parent;local originalTrigger=trigger.Triggered
 local model=Bench.create(world,anchor,index,base)
 check(model.Parent==world.folder and model.Name=='VaultWorkbench'..index,'Workbench belongs to the existing world/base')
 check(model:GetAttribute('BaseIndex')==index and model:GetAttribute('CosmeticWorkbench')==true,'Workbench has only presentation metadata')
 check(anchor.Name=='Vault Manager'and anchor.Parent==originalParent,'Existing manager name/ancestry changed')
 check(Mock.json({anchor.CFrame:GetComponents()})==originalCF,'Existing prompt anchor moved or rotated')
 check(anchor.Transparency==1 and not anchor.CanCollide and not anchor.CanQuery,'Original block was not hidden')
 check(anchor:GetAttribute('OwnerUserId')==index*11,'Owner metadata changed')
 check(trigger.Parent==anchor and trigger.ActionText=='Manage base items'and trigger.Triggered==originalTrigger,'Existing prompt/function was replaced')
 trigger.Triggered();check(fired==1,'Existing interaction callback no longer works')
 local partCount=0;local min,max=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,part in ipairs(model:GetDescendants())do
  if part:IsA('BasePart')then
   partCount=partCount+1
   check(part.Anchored and part.CanTouch==false,'Bench part is unstable or adds touch listeners')
   check(part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0,'Bench part has invalid size')
   if part.CanCollide then
    collisionParts=collisionParts+1
    check(part.Name=='WorkbenchTop'or part.Name:match('^Leg'),'An unnecessary decoration gained collision')
    -- Server places the retained prompt on a forward Attachment so the desk
    -- never obstructs its own native/server line of sight from the entrance.
    local target=anchor.CFrame*Vector3.new(0,1.2,-1.65)
    for _,point in ipairs({Vector3.new(-16,3.4,-21.4),Vector3.new(-19,3.4,-20),Vector3.new(-13,3.4,-20)})do
     check(not crosses(part,base*point,target),'Solid desk blocks the front prompt approach')
    end
   else check(not part.CanQuery,'Decorative detail can block interaction raycasts')end
   for _,sx in ipairs({-1,1})do for _,sy in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
    local point=base:PointToObjectSpace(part.CFrame*Vector3.new(sx*part.Size.X/2,sy*part.Size.Y/2,sz*part.Size.Z/2))
    check(point.X>=-19-1e-6 and point.X<=-13+1e-6 and point.Z>=-19-1e-6 and point.Z<=-15+1e-6,'Part protrudes from its allocated footprint')
    check(point.Y>=1.02-1e-6 and point.Y<=5,'Bench geometry penetrates the floor or reaches the ceiling')
    check(point.Z>-20,'Bench blocks the entrance/protection line')
    check(point.X<-6 and point.Z<-6.5,'Bench encroaches on collection or display areas')
    min=Vector3.new(math.min(min.X,point.X),math.min(min.Y,point.Y),math.min(min.Z,point.Z))
    max=Vector3.new(math.max(max.X,point.X),math.max(max.Y,point.Y),math.max(max.Z,point.Z))
   end end end
  end
 end
 check(partCount>=45 and partCount<=85,'Desk is too plain or exceeds its mobile geometry budget')
 check(model:GetAttribute('PartCount')==partCount,'Recorded part count does not match actual geometry')
 check(model.PrimaryPart==model:FindFirstChild('WorkbenchTop'),'Workbench model has no stable primary part')
 local display=assert(model:FindFirstChild('VaultDisplay'))
 local surface=assert(display:FindFirstChild('VaultWorkbenchDisplay'))
 local label=assert(surface:FindFirstChild('WorkbenchTitle'))
 check(label.Text=='MY VAULT\nMOVE • SELL\nBASE LEVELS','Display does not describe the retained functions')
 check(surface.Face==Enum.NormalId.Front and not surface.AlwaysOnTop,'Display faces incorrectly or obscures gameplay')
 check(display.CFrame.LookVector:Dot(base.LookVector)>.97,'Screen does not face the entrance in both base orientations')
 for _,name in ipairs({'SupplyDrawer1','DrawerPull1','KeyboardBase','ControlDial','LedgerPages','ItemTray','TrayRelic'})do
  check(model:FindFirstChild(name)~=nil,'Missing workbench detail '..name)
 end
 local rebuilt=Bench.create(world,anchor,index,base)
 check(rebuilt~=model and not model.Parent,'Rebuild did not replace only this base workbench')
 check(untouched.Parent==world.folder,'Rebuild removed another workstation')
 check(trigger.Parent==anchor and trigger.Triggered==originalTrigger,'Rebuild broke retained input')
 local matching=0
 for _,candidate in ipairs(world.folder:GetChildren())do if candidate.Name=='VaultWorkbench'..index then matching=matching+1 end end
 check(matching==1,'Rebuild duplicated the desk')
 benchBounds[#benchBounds+1]={base=index,parts=partCount,min={min.X,min.Y,min.Z},max={max.X,max.Y,max.Z},rotation=z<0 and'math.pi'or'0'}
 partsTotal=partsTotal+partCount;models[index]=rebuilt
end
check(partsTotal<=8*85 and #models==8,'Full server exceeds desk budget')
check(collisionParts==8*9,'Desk collision is not restricted to worktop, legs and feet')
local report={passed=true,assertions=checks,bases=8,parts_per_base=partsTotal/8,total_parts=partsTotal,
 collision_parts_per_base=collisionParts/8,allocated_footprint={x={-19,-13},z={-19,-15}},
 native_geometry_recorded=true,anchor_cframe_parent_and_prompt_preserved=true,idempotent=true,
 entrance_collection_and_display_clearance=true,forward_prompt_attachment_approach_clear=true,
 forward_prompt_attachment_offset={0,1.2,-1.65},bounds=benchBounds,
 runtime='Actual BaseWorkbench module through texlua Roblox geometry recorder',
 limitations='No Studio rendering, real raycasts, native player collision or multiplayer input was tested.'}
local output=assert(io.open(arg[2]or'/tmp/opitem-v83-base-workbench.json','w'));output:write(Mock.json(report));output:close()
print('BASE WORKBENCH PASS '..checks..' assertions; '..partsTotal..' actual parts across eight bases')
