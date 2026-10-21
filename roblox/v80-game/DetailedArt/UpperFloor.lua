-- Server-built level-five extension. Slots and stairs are part of the same
-- vault; only ownership/level transitions build or remove geometry.
local P=require(script.Parent.Primitives)
local M={UnlockLevel=5,FloorHeight=20,RoofHeight=36.5}
local V,C=Vector3.new,CFrame.new
local rgb=Color3.fromRGB
local navy,slate,shadow=rgb(26,34,52),rgb(68,78,94),rgb(31,40,57)
local bronze,gold,ivory=rgb(157,121,65),rgb(219,180,100),rgb(229,221,199)
local stone,metal=Enum.Material.Slate,Enum.Material.Metal
local function plate(part,value)
 local gui=Instance.new('SurfaceGui');gui.Name='UpperVaultInscription'
 gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(600,180)
 gui.LightInfluence=.3;gui.AlwaysOnTop=false;gui.Parent=part
 local text=Instance.new('TextLabel');text.BackgroundTransparency=1
 text.Size=UDim2.fromScale(.94,.86);text.Position=UDim2.fromScale(.03,.07)
 text.Text=value;text.TextColor3=ivory;text.TextSize=65;text.Font=Enum.Font.GothamBold
 text.TextWrapped=false;text.Parent=gui
end
local function roofPart(name)
 return name=='SolidFittedRoof' or name=='SolidRaisedRoof' or name:match('^Roof')
  or name:match('^SideRoofGlow') or name:match('^VentGem') or name:match('^EntranceRune')
end
local function findRoof(world,index)
 local aesthetics=world.folder:FindFirstChild('Aesthetics')
 local roofs=aesthetics and aesthetics:FindFirstChild('VaultRoofs')
 return roofs and roofs:FindFirstChild('BaseRoof'..index)
end
local function moveRoof(roof,record,up)
 if not roof then return end
 if up then
  record.roof=roof;record.roofParts={}
  record.oldHeight=roof:GetAttribute('RoofHeight');record.oldUnlocked=roof:GetAttribute('UpperFloorUnlocked')
  for _,part in ipairs(roof:GetDescendants()) do
   if part:IsA('BasePart') and roofPart(part.Name) then
    record.roofParts[part]=part.CFrame;part.CFrame=part.CFrame+V(0,19,0)
   end
  end
  roof:SetAttribute('RoofHeight',M.RoofHeight);roof:SetAttribute('UpperFloorUnlocked',true)
 else
  for part,cf in pairs(record.roofParts or {}) do if part.Parent then part.CFrame=cf end end
  roof:SetAttribute('RoofHeight',record.oldHeight);roof:SetAttribute('UpperFloorUnlocked',record.oldUnlocked)
 end
end
local function build(parent,base,index,total)
 local accent=Color3.fromHSV((index-1)/total,.56,.92)
 local b=P.new(parent,{name='UpperFloor'..index,alignBase=false,cframe=base.cf,partBudget=420})
 local function box(name,size,cf,color,material,solid)
  return b:box(name,size,cf,color,material or metal,solid)
 end
 -- Two slabs leave a real rear-left stairwell; no invisible collider spans it.
 box('UpperFloorFrontSlab',V(48,1,36),C(0,19.5,-6),navy,stone,true)
 box('UpperFloorRearRightSlab',V(20.5,1,12),C(13.75,19.5,18),navy,stone,true)
 for _,x in ipairs({-22.5,22.5}) do box('GalleryFloorBorderX'..x,V(.12,.025,34),C(x,20.02,-6),bronze) end
 for _,z in ipairs({-22.5,11.4}) do box('GalleryFloorBorderZ'..z,V(45,.025,.12),C(0,20.02,z),bronze) end
 for _,x in ipairs({-1.1,1.1}) do box('GalleryAisleInlay'..x,V(.07,.025,30),C(x,20.02,-5),gold) end
 local numerals={'IX','X','XI','XII','XIII','XIV','XV','XVI'}
 for n=1,8 do
  local x=-16.5+((n-1)%4)*11;local z=-3+math.floor((n-1)/4)*10
  base.slots[8+n]=base.cf*C(x,21.9,z)
  box('UpperDisplayPedestal'..n,V(7,1.2,7),C(x,20.6,z),shadow,stone,true)
  box('UpperDisplayOwnershipTrim'..n,V(7.12,.12,7.12),C(x,21.25,z),accent,Enum.Material.Neon)
  for _,side in ipairs({-1,1}) do
   box('UpperDisplaySideFrame'..n..'_'..side,V(.12,.7,7.24),C(x+side*3.55,20.63,z),slate,stone)
   box('UpperDisplayEndFrame'..n..'_'..side,V(7.12,.7,.12),C(x,20.63,z+side*3.55),slate,stone)
  end
  local plaque=box('UpperDisplayNumber'..n,V(1.6,.5,.08),C(x,20.7,z-3.64),bronze)
  plate(plaque,numerals[n])
 end
 -- Comfortable 0.475-stud rises, 1.15-stud treads and a 4.5-stud turn landing.
 -- Both flights occupy the clear strip behind the ground floor's displays.
 local run,rise,count=23,.475,20
 local tread=run/count
 for flight=1,2 do
  local z=flight==1 and 14.5 or 20.5
  local bottom=flight==1 and 1 or 10.5
  for step=1,count do
   local x=flight==1 and 3.5-(step-.5)*tread or -19.5+(step-.5)*tread
   local top=bottom+step*rise
   box('StairTread'..flight..'_'..step,V(tread+.04,rise,4),C(x,top-rise*.5,z),slate,stone,true)
   local edge=flight==1 and x-tread*.5 or x+tread*.5
   box('StairBronzeNosing'..flight..'_'..step,V(.065,.035,4.03),C(edge,top+.018,z),gold)
  end
  local start=flight==1 and V(3.5,1,0) or V(-19.5,10.5,0)
  local finish=flight==1 and V(-19.5,10.5,0) or V(3.5,20,0)
  for _,side in ipairs({-1,1}) do
   local railZ=z+side*2.12
   b:line('StairHandrail'..flight..'_'..side,V(start.X,start.Y+3.1,railZ),V(finish.X,finish.Y+3.1,railZ),.16,.16,gold,metal,true)
   b:line('StairStringer'..flight..'_'..side,V(start.X,start.Y-.15,z+side*1.65),V(finish.X,finish.Y-.15,z+side*1.65),.22,.34,shadow,metal)
   for post=0,4 do
    local t=post/4;local x=start.X+(finish.X-start.X)*t;local y=start.Y+(finish.Y-start.Y)*t
    box('StairBaluster'..flight..'_'..side..'_'..post,V(.13,2.85,.13),C(x,y+1.65,railZ),bronze,metal,true)
   end
  end
 end
 box('StairTurnLanding',V(4.5,.6,10),C(-21.25,10.2,17.5),slate,stone,true)
 box('StairLandingGoldEdge',V(.1,.04,9.6),C(-23.3,10.52,17.5),gold)
 -- Upstairs has the same accessible full-width arrival/protection line.
 local line=box('UpperDeliveryProtectionLine',V(3,.16,4.6),C(4.2,20.09,20.5),rgb(63,221,154),Enum.Material.Neon)
 line:SetAttribute('ProtectionLine',true);line:SetAttribute('BaseIndex',index)
 local galleryPlaque=box('UpperGalleryNameplate',V(13,1.8,.18),C(13.6,23,-23.32),bronze)
 plate(galleryPlaque,'RELIC GALLERY  •  II')
 local model=b:finish()
 model:SetAttribute('Kind',nil);model:SetAttribute('DecorativeOnly',true);model:SetAttribute('ArtVersion',75)
 model:SetAttribute('BaseCF',base.cf);model:SetAttribute('BaseIndex',index)
 model:SetAttribute('UpperFloorUnlocked',true);model:SetAttribute('FloorHeight',M.FloorHeight);model:SetAttribute('RoofHeight',M.RoofHeight)
 model:SetAttribute('StairRise',rise);model:SetAttribute('StairTreadDepth',tread);model:SetAttribute('StairWidth',4)
 local shell=P.new(model,{name='UpperFloorShell',alignBase=false,cframe=base.cf,partBudget=150})
 local function wall(name,size,cf,color,mat,solid) return shell:box(name,size,cf,color,mat or stone,solid) end
 -- Side/rear walls overlap the retained lower walls; the upper facade has
 -- fitted solid glass windows, framed in the same restrained bronze palette.
 wall('UpperSolidBackWall',V(48,19,1),C(0,27,24),navy,stone,true)
 for _,side in ipairs({-1,1}) do
  wall('UpperSolidSideWall'..side,V(1,19,48),C(side*24,27,0),navy,stone,true)
  for z=-16,16,8 do
   wall('UpperWallPier'..side..'_'..z,V(.45,16,1),C(side*23.3,28,z),slate)
   wall('UpperWallCapital'..side..'_'..z,V(.6,.2,1.25),C(side*23.2,35.7,z),gold,metal)
   wall('UpperWallRecess'..side..'_'..z,V(.06,8,5.3),C(side*23.45,28,z+3.2),shadow,metal)
  end
 end
 wall('UpperFrontKneeWall',V(48,3,1),C(0,21.5,-24),navy,stone,true)
 wall('UpperFrontCrownBeam',V(48,4,1),C(0,34.5,-24),navy,stone,true)
 for n=-2,2 do
  local x=n*9
  local glass=wall('UpperSolidWindow'..n,V(8,9.5,.3),C(x,27.75,-24),rgb(98,139,156),Enum.Material.Glass,true)
  glass.Transparency=.32
  for _,side in ipairs({-1,1}) do wall('UpperWindowJamb'..n..'_'..side,V(.22,9.7,.5),C(x+side*4.1,27.75,-24.05),bronze,metal,true) end
  for _,y in ipairs({23,32.5}) do wall('UpperWindowSill'..n..'_'..y,V(8.45,.22,.6),C(x,y,-24.05),gold,metal,true) end
 end
 for _,x in ipairs({-13.5,-4.5,4.5,13.5}) do wall('UpperFacadePier'..x,V(1,9.5,1),C(x,27.75,-24),slate,stone,true) end
 for _,x in ipairs({-23,23}) do wall('UpperFacadeEndPier'..x,V(2,9.5,1),C(x,27.75,-24),slate,stone,true) end
 -- Guard the stairwell without closing the four-stud stair arrival opening.
 wall('StairwellFrontGuard',V(26.5,3,.18),C(-10.25,21.5,11.85),shadow,metal,true)
 wall('StairwellFrontHandrail',V(26.7,.18,.35),C(-10.25,23.05,11.85),gold,metal,true)
 wall('StairwellEntryGuard',V(.18,3,6),C(3.42,21.5,15),shadow,metal,true)
 wall('StairwellEntryHandrail',V(.35,.18,6.1),C(3.42,23.05,15),gold,metal,true)
 local shellModel=shell.model
 shellModel:SetAttribute('Kind',nil);shellModel:SetAttribute('DecorativeOnly',true)
 shellModel:SetAttribute('BaseCF',base.cf);shellModel:SetAttribute('RoofHeight',M.RoofHeight);shellModel:SetAttribute('FloorHeight',M.FloorHeight)
 shellModel:SetAttribute('OcclusionShell',true);shellModel:SetAttribute('UpperFloorUnlocked',true)
 shell:finish()
 local parts=0;for _,v in ipairs(model:GetDescendants()) do if v:IsA('BasePart') then parts=parts+1 end end
 model:SetAttribute('PartCount',parts)
 return model
end
function M.sync(world,states)
 if not world or not world.folder or not states then return end
 local cache=world._upperFloorState
 if not cache then
  local folder=Instance.new('Folder');folder.Name='UpperFloorUpgrades';folder.Parent=world.folder
  folder:SetAttribute('ArtVersion',75)
  cache={folder=folder,records={}};world._upperFloorState=cache
 end
 for index,base in ipairs(world.bases) do
  local state=base.owner and states[base.owner]
  local enabled=state and (state.progression or 0)>=M.UnlockLevel and state.capacity>=16
  local key=enabled and base.owner or nil
  local record=cache.records[index]
  if (record and record.owner or nil)~=key then
   if record then
    if record.model then record.model:Destroy() end
    moveRoof(record.roof,record,false)
    for slot=9,16 do base.slots[slot]=nil end
    cache.records[index]=nil
   end
   if key then
    record={owner=key}
    moveRoof(findRoof(world,index),record,true)
    record.model=build(cache.folder,base,index,#world.bases)
    cache.records[index]=record
   end
  end
 end
 return cache.folder
end
return M
