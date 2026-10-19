-- Structural art checks; visual likeness still needs an in-person Studio review.
return function(package)
 local catalog=require(package.Catalog);local factory=require(package.ModelFactory);local counts={}
 local details={
  krabby_patty={'SingleDomedSesameBun','GrilledPattyCore','SurfaceFittedSesameSeed32','TomatoSkin','PickleRind1','OnionOuterRing0'},
  black_lotus={'LotusStemLower','DarkLotusHeart','GoldenAnther8','OuterPetal0FoldLeftLower_A'},
  death_note={'BlackLeatherRearCover','LeatherBindingSpine','SpineStitch22','RightPageLeaf11','BookmarkRibbon','TitlePlaque'},
  krabby_patty_formula={'GreenGlassBottleBody','FittedCorkStopper','RolledSecretRecipe','FormulaLabel','RedWaxSeal','SealAnchorStem'},
  gary_shell={'SmoothPinkSpiralShell','FrontSurfaceRedSpiral72','BackSurfaceRedSpiral54','FrontFittedVioletSpot5','RoundedOpeningLip23','RecessedOpeningWall23','DeepOpeningBowl'},
  transformers_allspark={'AllSparkClosedMetalCore','ChamferedXEdge1','AllSparkFrontCybertronianGlyph1Stroke1','AllSparkBackCybertronianGlyph6Stroke4','AllSparkTopRecessedFacePanel','AllSparkBottomRecessedFacePanel'},
  transformers_matrix={'BlueEnergyCore','LeftOpenHandleCast_1','RightOpenHandleCast_8','GoldenOuterEnergyRing_0','ChassisRadialRib_11','CrownCentralKeystone'},
  optimus_energon_axe={'RedForearmEmitter','SharpLuminousEdge11','OptimusSilverFaceplate','CurvedOrangeBladeSpine11','EnergonHubCore1','RecessedGripBand7'},
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
  if d.id=='transformers_allspark' then
   assert(model:GetAttribute('AllSparkFaceCount')==6 and model:GetAttribute('GlyphStrokeCount')==144,'AllSpark needs six complete engraved faces')
  end
  if d.id=='transformers_matrix' then
   assert(model:GetAttribute('OpenFingerHandles') and model:GetAttribute('NativeFacetedEnergyCrystal'),'Matrix handles or crystal missing')
  end
  if d.id=='krabby_patty_formula' then
   local glass=model:FindFirstChild('GreenGlassBottleBody')
   assert(glass.Material==Enum.Material.Glass and glass.Transparency>.5 and glass.Transparency<.9,'Formula recipe must be visible through glass')
   local label=model:FindFirstChild('FormulaLabel');local brand=model:FindFirstChild('FormulaBrand')
   assert(label:FindFirstChildOfClass('SurfaceGui') and brand:FindFirstChildOfClass('SurfaceGui'),'Formula surface labels missing')
  end
  if d.id=='item08' then assert(count==137 and model:FindFirstChild('EyePupil') and model:FindFirstChild('PendantLoop_24'),'Millennium Puzzle changed') end
  if d.model=='shell' then assert(model:GetAttribute('FreeModelKey')=='blue_shell' and model:FindFirstChild('SapphireShellBody') and model:FindFirstChild('ThickIvoryRim0') and model:FindFirstChild('LongFlightFeather1_5'),'Supplied Blue Shell details missing') end
  if d.infinityStone then assert(d.tier==5 and model:FindFirstChild('CrystalFacet1_1A_A') and model:FindFirstChild('TerminalFacet1_1_A') and model:FindFirstChild('IlluminatedGirdle3'),'Supplied stone facets/glow missing') end
  counts[d.id]=count;model:Destroy();if index%8==0 then task.wait() end
 end
 return {models=#catalog.Items,counts=counts}
end
