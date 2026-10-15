-- Structural art checks; visual likeness still needs an in-person Studio review.
return function(package)
 local catalog=require(package.Catalog);local factory=require(package.ModelFactory);local counts={}
 local details={
  krabby_patty={'SingleDomedSesameBun','GrilledPattyCore','SurfaceFittedSesameSeed32','TomatoSkin','PickleRind1','OnionOuterRing0'},
  black_lotus={'LotusStemLower','DarkLotusHeart','GoldenAnther8','OuterPetal0FoldLeftLower_A'},
  death_note={'BlackLeatherRearCover','LeatherBindingSpine','SpineStitch22','RightPageLeaf11','BookmarkRibbon','TitlePlaque'},
 }
 local function finite(value) return value==value and math.abs(value)<math.huge end
 for index,d in ipairs(catalog.Items) do
  local model=factory.create(d,nil);assert(model.PrimaryPart,'Missing pivot: '..d.id)
  assert(model:GetAttribute('Kind')==d.id and model.Name==d.name,'Collectible identity mismatch: '..d.id)
  local count=0
  for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
   count=count+1;assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,'Unsafe collectible physics: '..d.id)
   for _,value in ipairs({p.CFrame:GetComponents()}) do assert(finite(value),'Invalid collectible transform: '..d.id) end
   for _,value in ipairs({p.Size.X,p.Size.Y,p.Size.Z}) do assert(finite(value) and value>0,'Invalid collectible dimensions: '..d.id) end
  end end
  assert(count>=21 and count<=240,'Incomplete or excessive collectible geometry: '..d.id)
  for _,name in ipairs(details[d.id] or {}) do assert(model:FindFirstChild(name,true),'Missing collectible detail: '..d.id..' / '..name) end
  if d.id=='item08' then assert(count==137 and model:FindFirstChild('EyePupil') and model:FindFirstChild('PendantLoop_24'),'Millennium Puzzle changed') end
  if d.model=='shell' then assert(model:GetAttribute('FreeModelKey')=='blue_shell' and model:FindFirstChild('SapphireShellBody') and model:FindFirstChild('ThickIvoryRim0') and model:FindFirstChild('LongFlightFeather1_5'),'Supplied Blue Shell details missing') end
  if d.infinityStone then assert(d.tier==5 and model:FindFirstChild('CrystalFacet1_1A_A') and model:FindFirstChild('TerminalFacet1_1_A') and model:FindFirstChild('IlluminatedGirdle3'),'Supplied stone facets/glow missing') end
  counts[d.id]=count;model:Destroy();if index%8==0 then task.wait() end
 end
 return {models=#catalog.Items,counts=counts}
end
