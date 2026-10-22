-- The server owns product mappings, price checks, prompts and receipt grants.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local GS=game:GetService('GuiService')
local Tween=game:GetService('TweenService')
local playerGui=Players.LocalPlayer:WaitForChild('PlayerGui')
local remote=RS:WaitForChild('OPItemNet'):WaitForChild('CashShop')
local gui=script.Parent;assert(gui:IsA('ScreenGui'),'Shop requires a ScreenGui')
gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local dark=Color3.fromRGB(20,29,45);local gold=Color3.fromRGB(235,193,104);local ink=Color3.fromRGB(238,244,248)
local muted=Color3.fromRGB(158,181,197);local green=Color3.fromRGB(115,218,170)
local function rounded(object,radius)local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,radius or 9);c.Parent=object end
local function label(parent,value,pos,size,fontSize,color)
 local t=Instance.new('TextLabel');t.Position=pos;t.Size=size;t.BackgroundTransparency=1;t.Text=value;t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize;t.TextColor3=color or ink;t.TextWrapped=true;t.Parent=parent;return t
end
local safe=Instance.new('Frame');safe.Name='CashShopSafeBounds';safe.Size=UDim2.fromScale(1,1);safe.BackgroundTransparency=1;safe.Parent=gui
local panel=Instance.new('Frame');panel.Name='CashShopPanel';panel.Size=UDim2.fromOffset(480,500);panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.BackgroundColor3=dark;panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=safe;rounded(panel)
local stroke=Instance.new('UIStroke');stroke.Color=gold;stroke.Transparency=.25;stroke.Parent=panel
label(panel,'ROBUX SHOP',UDim2.fromOffset(14,8),UDim2.new(1,-72,0,32),20,gold)
local close=Instance.new('TextButton');close.Name='CloseCashShop';close.Position=UDim2.new(1,-46,0,8);close.Size=UDim2.fromOffset(34,34);close.Text='×';close.TextSize=24;close.Font=Enum.Font.GothamBold;close.TextColor3=ink;close.BackgroundColor3=Color3.fromRGB(46,56,74);close.BorderSizePixel=0;close.Parent=panel;rounded(close)
local status=label(panel,'Loading offers…',UDim2.fromOffset(14,46),UDim2.new(1,-28,0,30),12,muted);status.Name='ShopStatus'
local list=Instance.new('ScrollingFrame');list.Name='ShopOffers';list.Position=UDim2.fromOffset(12,122);list.Size=UDim2.new(1,-24,1,-236);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=4;list.CanvasSize=UDim2.fromOffset(0,0);list.Parent=panel
local summary=label(panel,'Choose an offer.',UDim2.new(0,14,1,-106),UDim2.new(1,-28,0,42),12,muted);summary.Name='ShopSummary'
local buy=Instance.new('TextButton');buy.Name='ShopBuyButton';buy.Position=UDim2.new(0,14,1,-61);buy.Size=UDim2.new(1,-28,0,38);buy.Text='COMING SOON';buy.Font=Enum.Font.GothamBold;buy.TextSize=14;buy.TextColor3=muted;buy.BackgroundColor3=Color3.fromRGB(39,49,63);buy.BorderSizePixel=0;buy.Active=false;buy.AutoButtonColor=false;buy.Selectable=false;buy.Parent=panel;rounded(buy)
label(panel,'Roblox confirms the final price.',UDim2.new(0,14,1,-22),UDim2.new(1,-28,0,16),10,muted)
local offers,cards,tweens={},{},{}
local selectedCategory,selectedId='cash',nil
local available,configured,submitting=false,false,false
local categoryButtons={}
local categoryNames={cash='Cash',levels='Levels',powers='Powers'}
local regularPowers={dash=true,gravity=true,slow=true,slam=true,repulse=true,shield=true,lightning=true,kiblast=true,spinjitzu=true}
local renderOffers
local function cancelPreviews()for _,tween in ipairs(tweens)do tween:Cancel()end;table.clear(tweens)end
local function hide()
 panel.Visible=false;GS.SelectedObject=nil;cancelPreviews()
 if playerGui:GetAttribute('OPActiveMenu')=='cashshop'then playerGui:SetAttribute('OPActiveMenu',nil)end
end
close.Activated:Connect(hide)
local function layout()
 local size=safe.AbsoluteSize;if size.X<=0 or size.Y<=0 then return end
 panel.Size=UDim2.fromOffset(math.min(520,size.X-16),math.min(560,size.Y-24))
end
safe:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
playerGui:GetAttributeChangedSignal('OPActiveMenu'):Connect(function()
 if playerGui:GetAttribute('OPActiveMenu')~='cashshop'and panel.Visible then panel.Visible=false;GS.SelectedObject=nil;cancelPreviews()end
end)
UIS.InputBegan:Connect(function(input,processed)
 if panel.Visible and not processed and(input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB)then hide()end
end)
local function selectedOffer()
 for _,offer in ipairs(offers)do if offer.id==selectedId and offer.category==selectedCategory then return offer end end
end
local function updateAction()
 local offer=selectedOffer()
 local canBuy=offer~=nil and available and configured and offer.available==true and not offer.owned and not submitting
 buy.Active=canBuy;buy.Selectable=canBuy;buy.AutoButtonColor=canBuy
 buy.BackgroundColor3=canBuy and Color3.fromRGB(43,98,77)or Color3.fromRGB(39,49,63)
 buy.TextColor3=canBuy and ink or muted
 if submitting then buy.Text='CHECKING PURCHASE…'
 elseif not configured then buy.Text='COMING SOON'
 elseif not offer then buy.Text='CHOOSE AN OFFER'
 elseif offer.owned then buy.Text='ALREADY OWNED'
 elseif canBuy then buy.Text='BUY · '..offer.robux..' ROBUX'
 else buy.Text=offer.reason or'UNAVAILABLE'end
 if offer then summary.Text=offer.name..' · '..offer.robux..' Robux\n'..(offer.owned and'Already unlocked for your loadout.'or(offer.reason or'Roblox will ask you to confirm.'))
 else summary.Text='Choose an offer. Conveyor items and developer perks are never sold here.'end
end
local function preview(parent,offer)
 local area=Instance.new('Frame');area.Name='PowerPreview';area.Position=UDim2.fromOffset(10,126);area.Size=UDim2.new(1,-20,0,44);area.BackgroundColor3=Color3.fromRGB(15,27,44);area.BorderSizePixel=0;area.ClipsDescendants=true;area.Parent=parent;rounded(area)
 local function shape(name,pos,size,color)
  local p=Instance.new('Frame');p.Name=name;p.Position=pos;p.Size=size;p.AnchorPoint=Vector2.new(.5,.5);p.BorderSizePixel=0;p.BackgroundColor3=color;p.Parent=area;rounded(p,20);return p
 end
 local function animate(object,seconds,properties)
  if playerGui:GetAttribute('OPReducedEffects')==true then return end
  local tween=Tween:Create(object,TweenInfo.new(seconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
  tweens[#tweens+1]=tween;tween:Play()
 end
 if offer.power=='kiblast'then
  local trail=shape('KiPreviewTrail',UDim2.fromScale(.38,.5),UDim2.fromScale(.55,.08),Color3.fromRGB(102,218,255));trail.BackgroundTransparency=.5
  local orb=shape('KiPreviewOrb',UDim2.fromScale(.14,.5),UDim2.fromOffset(26,26),Color3.fromRGB(170,241,255))
  animate(orb,.7,{Position=UDim2.fromScale(.87,.5),BackgroundTransparency=.2})
 elseif offer.power=='spinjitzu'then
  for index=1,4 do
   local ring=shape('TornadoPreviewRing'..index,UDim2.fromScale(.5,.18+index*.14),UDim2.fromScale(.12+index*.075,.1),Color3.fromRGB(115,239,210));ring.Rotation=index*17
   animate(ring,1.1,{Rotation=ring.Rotation+300,BackgroundTransparency=.35})
  end
 else
  local icon=label(area,offer.icon or'POWER',UDim2.fromScale(.1,.15),UDim2.fromScale(.8,.7),18,gold);icon.TextXAlignment=Enum.TextXAlignment.Center
  animate(icon,.7,{TextTransparency=.25})
 end
end
local function details(offer)
 if offer.category=='cash'then return string.format('$%d game cash',offer.cash)end
 if offer.category=='levels'then return string.format('+%d base level%s',offer.levels,offer.levels==1 and''or's')end
 return 'RANK '..tostring(offer.rank or'?')..' · '..tostring(offer.cooldown or'?')..'s COOLDOWN'
end
renderOffers=function()
 cancelPreviews();for _,card in ipairs(cards)do card:Destroy()end;cards={}
 for key,button in pairs(categoryButtons)do button.BackgroundColor3=key==selectedCategory and Color3.fromRGB(42,76,72)or Color3.fromRGB(39,49,63)end
 local offset=0;local selectedCard
 for _,offer in ipairs(offers)do if offer.category==selectedCategory then
  local selected=offer.id==selectedId
  local height=selected and offer.category=='powers'and 180 or(selected and 134 or 84)
  local card=Instance.new('TextButton');card.Name='ShopOffer_'..offer.id;card.Position=UDim2.fromOffset(0,offset);card.Size=UDim2.new(1,-8,0,height);card.Text='';card.BorderSizePixel=0;card.BackgroundColor3=selected and Color3.fromRGB(37,66,76)or Color3.fromRGB(31,45,64);card.Selectable=true;card.Parent=list;rounded(card)
  if selected then selectedCard=card end
  local badge=label(card,offer.icon or(offer.category=='cash'and'$'or offer.category=='levels'and'LV'or'P'),UDim2.fromOffset(8,12),UDim2.fromOffset(40,44),15,green);badge.TextXAlignment=Enum.TextXAlignment.Center;badge.Name='OfferIcon'
  label(card,offer.name,UDim2.fromOffset(55,7),UDim2.new(.67,-55,0,30),13,gold)
  label(card,details(offer),UDim2.fromOffset(55,38),UDim2.new(.67,-55,0,32),10,muted)
  local cost=label(card,offer.robux..' Robux\n'..(offer.priceVerified==true and'PRICE'or'PROPOSED'),UDim2.new(.67,0,0,13),UDim2.new(.33,-10,0,48),12,green);cost.Name='OfferPrice';cost.TextXAlignment=Enum.TextXAlignment.Right
  if selected then
   local description=offer.description or'Adds this reward to your saved progress after a confirmed purchase.'
   label(card,description,UDim2.fromOffset(12,81),UDim2.new(1,-24,0,42),11,ink).Name='OfferDescription'
   if offer.category=='powers'then preview(card,offer)end
  end
  card.Activated:Connect(function()selectedId=offer.id;renderOffers()end)
  cards[#cards+1]=card;offset+=height+8
 end end
 list.CanvasSize=UDim2.fromOffset(0,offset);updateAction()
 if UIS.GamepadEnabled and panel.Visible then GS.SelectedObject=selectedCard or categoryButtons[selectedCategory]end
end
for index,key in ipairs({'cash','levels','powers'})do
 local category=key
 local button=Instance.new('TextButton');button.Name='ShopCategory_'..key;button.Position=UDim2.new((index-1)/3,14-(index-1)*4,0,80);button.Size=UDim2.new(1/3,-16,0,34);button.Text=categoryNames[key];button.TextSize=13;button.Font=Enum.Font.GothamBold;button.TextColor3=ink;button.BorderSizePixel=0;button.Parent=panel;rounded(button);categoryButtons[key]=button
 button.Activated:Connect(function()selectedCategory=category;selectedId=nil;list.CanvasPosition=Vector2.new(0,0);renderOffers()end)
end
buy.Activated:Connect(function()
 local offer=selectedOffer()
 if submitting or not available or not configured or not offer or offer.available~=true or offer.owned then return end
 submitting=true;updateAction();remote:FireServer({kind='buy',id=offer.id})
end)
local function positive(n)return type(n)=='number'and n==n and n>0 and n<math.huge and n%1==0 end
remote.OnClientEvent:Connect(function(data)
 if type(data)~='table'then return end
 if data.kind=='result'then
  submitting=false;updateAction();if type(data.message)=='string'then status.Text=data.message end;return
 end
 if data.kind~='catalog'or type(data.available)~='boolean'or type(data.configured)~='boolean'or type(data.offers)~='table'then return end
 offers={};available=data.available;configured=data.configured;submitting=false
 for index,offer in ipairs(data.offers)do
  if index>15 then break end
  if type(offer)=='table'and type(offer.id)=='string'and type(offer.name)=='string'and positive(offer.robux)and categoryNames[offer.category]
   and((offer.category=='cash'and positive(offer.cash))or(offer.category=='levels'and positive(offer.levels))or(offer.category=='powers'and regularPowers[offer.power]))then offers[#offers+1]=offer end
 end
 status.Text=type(data.message)=='string'and data.message or(configured and'Choose an offer. Purchases need Roblox confirmation.'or'Preview offers · Purchases are not available yet.')
 renderOffers();layout()
 if data.open~=false then
  playerGui:SetAttribute('OPActiveMenu','cashshop');panel.Visible=true
  if UIS.GamepadEnabled then GS.SelectedObject=close end
 end
end)
layout()
