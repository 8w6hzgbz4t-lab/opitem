-- Shared server presentation for every live collectible state. No ownership logic.
local P={}
function P.update(model,label,definition,catalog)
 local gui=label.Parent
 local rarity=gui:FindFirstChild('ItemRarity')
 if not rarity then
  -- Pixel-sized billboards stay compact when the camera approaches an item.
  gui.Name='ItemNameplate';gui.Size=UDim2.fromOffset(176,62);gui.MaxDistance=75
  -- Depth-tested labels avoid revealing collectibles through solid base walls.
  gui.AlwaysOnTop=false
  label.Position=UDim2.fromOffset(0,18);label.Size=UDim2.new(1,0,1,-18)
  label.TextSize=12;label.TextScaled=false;label.TextWrapped=true
  rarity=Instance.new('TextLabel');rarity.Name='ItemRarity'
  rarity.Size=UDim2.new(1,0,0,18);rarity.BackgroundColor3=Color3.fromRGB(12,16,29)
  rarity.BackgroundTransparency=.12;rarity.Font=Enum.Font.GothamBold;rarity.TextSize=12;rarity.TextScaled=false
  rarity.TextStrokeTransparency=.6;rarity.Parent=gui
  local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,8);corner.Parent=rarity
 end
 rarity.Text=string.upper(definition.rarity)
 local color=catalog.Colors[definition.tier];rarity.TextColor3=Color3.fromRGB(color[1],color[2],color[3])
 model:SetAttribute('Rarity',definition.rarity);model:SetAttribute('CatalogId',definition.id)
 -- A collectible's geometry is static in every state. Cache the height once
 -- instead of recalculating hundreds of parts on each server heartbeat.
 local height=model:GetAttribute('LabelHeightOffset')
 if not height then
  local cf,size=model:GetBoundingBox();local root=model.PrimaryPart
  if root then
   height=math.max(1.5,cf.Position.Y+size.Y/2-root.Position.Y+.8)
   model:SetAttribute('LabelHeightOffset',height)
  end
 end
 if height then gui.StudsOffset=Vector3.new(0,height,0) end
end
return P
