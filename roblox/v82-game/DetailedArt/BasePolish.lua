-- A coherent relic-vault finish around the original eight functional displays.
-- This module owns only cosmetic geometry. It never changes gameplay anchors.
local P=require(script.Parent.Primitives)
local M={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local rgb=Color3.fromRGB
local navy=rgb(26,34,52)
local slate=rgb(68,78,94)
local shadow=rgb(31,40,57)
local bronze=rgb(157,121,65)
local gold=rgb(219,180,100)
local ivory=rgb(229,221,199)
local stone,metal=Enum.Material.Slate,Enum.Material.Metal

local function inscription(part,value,textColor)
 local gui=Instance.new('SurfaceGui');gui.Name='VaultInscription'
 gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(560,160)
 gui.LightInfluence=.3;gui.AlwaysOnTop=false;gui.Parent=part
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1
 t.Size=UDim2.fromScale(.94,.86);t.Position=UDim2.fromScale(.03,.07)
 t.Text=value;t.TextColor3=textColor or ivory;t.TextSize=66
 t.Font=Enum.Font.GothamBold;t.TextWrapped=false;t.Parent=gui
 return gui
end

local function finishBase(parent,base,index,total)
 local accent=Color3.fromHSV((index-1)/total,.56,.92)
 local b=P.new(parent,{name='RelicVault'..index,alignBase=false,cframe=base.cf,partBudget=140})
 local function box(name,size,cf,color,material)
  return b:box(name,size,cf,color,material or metal)
 end
 -- Flush inlays sit just above the retained solid floor. The complete green
 -- entrance strip, delivery pad and upgrade workstation remain uncovered.
 for _,side in ipairs({-1,1}) do
  box('FloorPerimeterInlayX'..side,V(.12,.022,39),C(side*22.4,1.018,1.5),bronze)
  box('AisleInlay'..side,V(.07,.022,27),C(side*1.2,1.018,5.5),bronze)
  for _,z in ipairs({-18,21}) do
   box('FloorCorner'..side..'_'..z,V(.5,.024,.5),C(side*22.4,1.02,z)*A(0,math.pi/4,0),gold)
  end
 end
 for _,z in ipairs({-18,21}) do
  box('FloorPerimeterInlayZ'..z,V(44.8,.022,.12),C(0,1.018,z),bronze)
 end
 for _,z in ipairs({-8.7,1.8,12}) do
  box('FloorCourse'..z,V(43.7,.018,.055),C(0,1.013,z),slate,stone)
 end
 -- Six tightly fitted parts per existing pedestal, all below its item pivot.
 -- The original plinth, neon ownership band and stored item stay untouched.
 local numerals={'I','II','III','IV','V','VI','VII','VIII'}
 for slot,slotCF in ipairs(base.slots) do
  local pos=base.cf:PointToObjectSpace(slotCF.Position)
  for _,side in ipairs({-1,1}) do
   box('DisplaySideFrame'..slot..'_'..side,V(.12,.7,7.24),C(pos.X+side*3.55,1.63,pos.Z),slate,stone)
   box('DisplayEndFrame'..slot..'_'..side,V(7.12,.7,.12),C(pos.X,1.63,pos.Z+side*3.55),slate,stone)
  end
  local plate=box('DisplayNumberPlate'..slot,V(1.42,.5,.08),C(pos.X,1.7,pos.Z-3.64),bronze)
  inscription(plate,numerals[slot] or tostring(slot),ivory)
  box('DisplayCrest'..slot,V(.24,.24,.09),C(pos.X-1.1,1.7,pos.Z-3.65)*A(0,0,math.pi/4),gold)
 end
 -- Interior wall piers carry one shared architectural language: dark stone,
 -- restrained bronze capitals and a single owner-colored inset per pier.
 for _,side in ipairs({-1,1}) do
  for j,z in ipairs({-12,2,16}) do
   box('InteriorPier'..side..'_'..j,V(.28,10.8,1.05),C(side*23.34,7.3,z),slate,stone)
   box('PierFoot'..side..'_'..j,V(.38,.22,1.35),C(side*23.28,1.94,z),bronze)
   box('PierCapital'..side..'_'..j,V(.38,.22,1.35),C(side*23.28,12.62,z),gold)
   box('PierOwnerInset'..side..'_'..j,V(.025,.9,.19),C(side*23.13,9.8,z),accent,Enum.Material.SmoothPlastic)
  end
  for j,z in ipairs({-5,9}) do
   box('InteriorWallPanel'..side..'_'..j,V(.055,5.7,10),C(side*23.46,7.5,z),shadow)
   box('InteriorPanelCrown'..side..'_'..j,V(.075,.1,9.5),C(side*23.42,10.42,z),bronze)
  end
 end
 -- Five embossed rear panels use shallow geometry rather than bright posters.
 for j=-2,2 do
  local x=j*8.6
  box('RearRecess'..j,V(6.8,6.1,.075),C(x,7.6,23.46),shadow)
  box('RearPanelCrown'..j,V(6.35,.12,.1),C(x,10.72,23.4),bronze)
  box('RearPanelGlyph'..j,V(.72,.72,.11),C(x,8,23.36)*A(0,0,math.pi/4),bronze)
 end
 -- Narrow front-jamb highlights stop above the entrance/protection line.
 -- No new lintel, sign in the ownership label, roof slab or blocking collider.
 for _,side in ipairs({-1,1}) do
  for _,offset in ipairs({-1.55,1.55}) do
   box('EntryJambInlay'..side..'_'..offset,V(.12,8.5,.09),C(side*20+offset,8.3,-25.13),bronze)
  end
  local plate=box('VaultIndexPlate'..side,V(2.6,1.18,.14),C(side*20,10.6,-25.22),navy)
  inscription(plate,string.format('VAULT %02d',index),gold)
  box('VaultIndexUnderline'..side,V(2.35,.09,.07),C(side*20,9.95,-25.31),accent,Enum.Material.SmoothPlastic)
 end
 local model=b:finish()
 model:SetAttribute('Kind',nil);model:SetAttribute('DecorativeOnly',true)
 model:SetAttribute('BaseIndex',index);model:SetAttribute('ArtVersion',72)
 model:SetAttribute('PresentationTheme','Relic Vault')
 return model
end

function M.build(world)
 local previous=world.folder:FindFirstChild('BasePresentation')
 if previous then previous:Destroy() end
 local root=Instance.new('Folder');root.Name='BasePresentation';root.Parent=world.folder
 root:SetAttribute('ArtVersion',72);root:SetAttribute('DecorativeOnly',true)
 for index,base in ipairs(world.bases) do finishBase(root,base,index,#world.bases) end
 return root
end
return M
