local P=require(script.Parent.Primitives)
local Architecture=require(script.Parent.Architecture)
local ItemArt=require(script.Parent.ItemArt)
local L={}
L.Keys={"baseBuilding","riftPortal","bellTower","squidHouse","godSlifer","godObelisk","godRa","blackLotus","pancakes","tournamentPillar","mtgCard","clashTower","skyFlower","guardian"}
local aliases={}
for _,key in ipairs(L.Keys) do aliases[string.lower(key)]=key end
function L.create(parent,options)
 options=options or {};local copy={}
 for k,v in pairs(options) do copy[k]=v end
 local key=assert(aliases[string.lower(tostring(copy.model or ""))],"Unknown landmark")
 copy.partBudget=copy.partBudget or 1000
 copy.alignBase=false
 local b=P.new(parent,copy)
 if key=="guardian" then
  local gold=Color3.fromRGB(199,149,52)
  local stone=Color3.fromRGB(45,39,58)
  b:box("GuardianPlinth",Vector3.new(8,1.2,5),CFrame.new(0,.6,0),stone,Enum.Material.Slate,true)
  b:box("GuardianPlinthLip",Vector3.new(8.2,.15,5.2),CFrame.new(0,1.25,0),gold)
  local scale=copy.scale or 1
  local function figure(id,name,cf)
   return ItemArt.create(b.model,{itemId=id,name=name,scale=scale,cframe=cf,partBudget=240})
  end
  figure("item25","DetailedHeadTorso",CFrame.new(0,4.6*scale,0))
  for _,side in ipairs({-1,1}) do
   figure(side<0 and "item28" or "item29",side<0 and "LeftLeg" or "RightLeg",CFrame.new(side*.68*scale,1.25*scale,0))
   figure(side<0 and "item26" or "item27",side<0 and "LeftArm" or "RightArm",
    CFrame.new(side*1.65*scale,6.15*scale,0)*CFrame.Angles(0,0,side*2.3)*CFrame.new(0,-3.45*scale,0))
  end
  local model=b:finish();local count=0
  for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then count=count+1 end end
  model:SetAttribute("PartCount",count)
  return model
 end
 assert(Architecture.build(b,key),"Landmark did not build")
 return b:finish()
end
return L
