-- Builds the articulated native-parts Ho-Oh. Animation is owned by the caller.
local FreeModels=require(script.Parent.FreeModels)
local Flight=require(script.Parent.HoOhFlight)
local Assembler={}

function Assembler.create(parent,originCFrame,scale)
 originCFrame=originCFrame or CFrame.new()
 scale=scale or 1.25
 assert(typeof(originCFrame)=="CFrame","Ho-Oh origin must be a CFrame")
 assert(type(scale)=="number" and scale>0 and scale<math.huge,"Ho-Oh scale must be finite and positive")
 local model=Instance.new("Model")
 model.Name="HoOh"
 local root=Instance.new("Part")
 root.Name="Root"
 root.Size=Vector3.new(.1,.1,.1)
 root.CFrame=originCFrame
 root.Transparency=1
 root.Anchored=true
 root.CanCollide=false
 root.CanQuery=false
 root.CanTouch=false
 root.CastShadow=false
 root.Material=Enum.Material.SmoothPlastic
 root.Parent=model
 model.PrimaryPart=root
 model:SetAttribute("FlightScale",scale)
 model:SetAttribute("FlightOrigin",originCFrame)
 model:SetAttribute("ArtSource","NativeRobloxParts")
 local epoch=0
 local ok,now=pcall(function() return workspace:GetServerTimeNow() end)
 if ok and type(now)=="number" then epoch=now end
 model:SetAttribute("FlightEpoch",epoch)
 -- Deliberately no Kind attribute: item animation caches must ignore this model.
 for _,component in ipairs({
  {"Body","hooh_body"},
  {"LeftWing","hooh_wing_left"},
  {"RightWing","hooh_wing_right"},
  {"Tail","hooh_tail"},
 }) do
  FreeModels.create(model,{
   name=component[1],model=component[2],scale=scale,alignBase=false,
  })
 end
 local count=0
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   count=count+1
   assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch,
    "Ho-Oh decoration must remain anchored and noncolliding")
  end
 end
 model:SetAttribute("PartCount",count)
 Flight.pose(model,originCFrame,0)
 model.Parent=parent
 return model
end
return Assembler
