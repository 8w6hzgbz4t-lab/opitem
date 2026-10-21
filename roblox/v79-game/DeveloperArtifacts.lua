-- Server-created cosmetic replicas. They never enter the collectible ledger.
-- All parts are massless and welded to a live character before parenting.
local A={};A.__index=A
local V,C=Vector3.new,CFrame.new
local gold=Color3.fromRGB(229,181,65)

local function clear(model)
 if model then model:Destroy() end
end
local function host(player,rod)
 local character=player.Character
 if not character or not character.Parent then return nil end
 if rod then return character:FindFirstChild('RightHand') or character:FindFirstChild('Right Arm') or character:FindFirstChild('HumanoidRootPart') end
 return character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso') or character:FindFirstChild('HumanoidRootPart')
end
local function weld(model,body)
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA('BasePart') then
   part.Anchored=false;part.Massless=true
   part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
   local joint=Instance.new('WeldConstraint');joint.Name='DeveloperCosmeticWeld'
   joint.Part0=body;joint.Part1=part;joint.Parent=part
  end
 end
 model:SetAttribute('Kind',nil);model:SetAttribute('ItemId',nil)
 model:SetAttribute('DecorativeOnly',true);model:SetAttribute('DeveloperCosmetic',true)
 model.Parent=body.Parent
end
local function chain(model,torso,from,to,name)
 local direction=to-from
 local up=direction.Unit
 local reference=math.abs(up.Z)>.95 and V(1,0,0) or V(0,0,1)
 local right=up:Cross(reference).Unit;local back=right:Cross(up).Unit
 local part=Instance.new('Part');part.Name=name;part.Size=V(.042,direction.Magnitude+.018,.048)
 part.CFrame=torso.CFrame*CFrame.fromMatrix((from+to)*.5,right,up,back)
 part.Color=gold;part.Material=Enum.Material.Metal;part.Anchored=false
 part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth;part.Parent=model
 return part
end
function A.new(templates,clock)
 return setmetatable({templates=templates,clock=clock or os.clock,records={}},A)
end
function A:record(player)
 local record=self.records[player.UserId]
 if record and record.character~=player.Character then self:clear(player);record=nil end
 if not record then record={character=player.Character};self.records[player.UserId]=record end
 return record
end
function A:setProtected(player,enabled)
 local record=self:record(player)
 if not enabled then clear(record.puzzle);record.puzzle=nil;return end
 local torso=host(player,false)
 if not torso or record.puzzle and record.puzzle.Parent==player.Character then return end
 local template=self.templates and self.templates:FindFirstChild('item08')
 if not template then return end
 clear(record.puzzle)
 local model=template:Clone();model.Name='DeveloperMillenniumPuzzle'
 model:ScaleTo(template:GetScale()*.25)
 model:PivotTo(torso.CFrame*C(0,-.58,-.72))
 -- Two shallow chains connect the detailed pendant loop to the collar.
 for _,side in ipairs({-1,1}) do
  local previous=V(side*.40,.65,-.55)
  for index=1,8 do
   local t=index/8
   local nextPoint=V(side*.40*(1-t),.65-t*.08-math.sin(t*math.pi)*.035,-.55-t*.20)
   chain(model,torso,previous,nextPoint,'PendantChain_'..side..'_'..index)
   previous=nextPoint
  end
 end
 model:SetAttribute('ProtectionEmblem',true);model:SetAttribute('DeveloperUserId',player.UserId)
 model:SetAttribute('PartCount',(template:GetAttribute('PartCount') or 137)+16)
 weld(model,torso);record.puzzle=model
end
function A:pulseRod(player)
 local record=self:record(player);local hand=host(player,true)
 if not hand then return nil end
 if not record.rod or not record.rod.Parent then
  local template=self.templates and self.templates:FindFirstChild('item23')
  if not template then return hand.Position end
  local model=template:Clone();model.Name='DeveloperMillenniumRod'
  model:ScaleTo(template:GetScale()*.46)
  model:PivotTo(hand.CFrame*C(0,-.54,-.32)*CFrame.Angles(math.rad(-12),0,0))
  model:SetAttribute('CastingArtifact',true);model:SetAttribute('DeveloperUserId',player.UserId)
  weld(model,hand);record.rod=model
 end
 record.rodUntil=self.clock()+1.25
 local tip=record.rod:FindFirstChild('RodEyePupil',true) or record.rod:FindFirstChild('RodEyeHead',true) or record.rod.PrimaryPart
 return tip and tip.Position or hand.Position
end
function A:clearRod(player)
 local record=self.records[player.UserId]
 if record then clear(record.rod);record.rod=nil;record.rodUntil=nil end
end
function A:tick()
 for id,record in pairs(self.records) do
  if not record.character or not record.character.Parent then
   clear(record.puzzle);clear(record.rod);self.records[id]=nil
  elseif record.rod and self.clock()>=(record.rodUntil or 0) then
   clear(record.rod);record.rod=nil;record.rodUntil=nil
  end
 end
end
function A:clear(player)
 local record=self.records[player.UserId]
 if record then clear(record.puzzle);clear(record.rod);self.records[player.UserId]=nil end
end
return A
