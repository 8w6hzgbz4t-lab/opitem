-- Structural art checks; visual likeness still needs an in-person Studio review.
return function(package)
 local catalog=require(package.Catalog);local factory=require(package.ModelFactory);local counts={}
 for index,d in ipairs(catalog.Items) do
  local model=factory.create(d,nil);assert(model.PrimaryPart,'Missing pivot: '..d.id)
  local count=0
  for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') then
   count+=1;assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,'Unsafe collectible physics: '..d.id)
  end end
  assert(count>=15,'Incomplete collectible geometry: '..d.id)
  if d.id=='item08' then assert(count==137 and model:FindFirstChild('EyePupil') and model:FindFirstChild('PendantLoop_24'),'Millennium Puzzle changed') end
  if d.model=='shell' then assert(model:GetAttribute('FreeModelKey')=='blue_shell' and model:FindFirstChild('SapphireShellBody') and model:FindFirstChild('ThickIvoryRim0') and model:FindFirstChild('LongFlightFeather1_5'),'Supplied Blue Shell details missing') end
  if d.infinityStone then assert(d.tier==5 and model:FindFirstChild('CrystalFacet1_1A_A') and model:FindFirstChild('TerminalFacet1_1_A') and model:FindFirstChild('IlluminatedGirdle3'),'Supplied stone facets/glow missing') end
  counts[d.id]=count;model:Destroy();if index%8==0 then task.wait() end
 end
 return {models=#catalog.Items,counts=counts}
end
