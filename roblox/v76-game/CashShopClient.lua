-- Server-opened preview only: no purchase prompt and no client purchase request.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local GS=game:GetService('GuiService')
local playerGui=Players.LocalPlayer:WaitForChild('PlayerGui')
local remote=RS:WaitForChild('OPItemNet'):WaitForChild('CashShop')
local gui=script.Parent;assert(gui:IsA('ScreenGui'),'Cash shop requires a ScreenGui')
gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local dark=Color3.fromRGB(20,29,45);local gold=Color3.fromRGB(235,193,104);local ink=Color3.fromRGB(238,244,248)
local function rounded(object) local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,9);c.Parent=object end
local function label(parent,value,pos,size,fontSize,color)
 local t=Instance.new('TextLabel');t.Position=pos;t.Size=size;t.BackgroundTransparency=1;t.Text=value;t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize;t.TextColor3=color or ink;t.TextWrapped=true;t.Parent=parent;return t
end
local safe=Instance.new('Frame');safe.Name='CashShopSafeBounds';safe.Size=UDim2.fromScale(1,1);safe.BackgroundTransparency=1;safe.Parent=gui
local panel=Instance.new('Frame');panel.Name='CashShopPanel';panel.Size=UDim2.fromOffset(420,420);panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.BackgroundColor3=dark;panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=safe;rounded(panel)
local stroke=Instance.new('UIStroke');stroke.Color=gold;stroke.Transparency=.25;stroke.Parent=panel
label(panel,'CASH SHOP',UDim2.fromOffset(14,8),UDim2.new(1,-72,0,32),20,gold)
local close=Instance.new('TextButton');close.Name='CloseCashShop';close.Position=UDim2.new(1,-46,0,8);close.Size=UDim2.fromOffset(34,34);close.Text='×';close.TextSize=24;close.Font=Enum.Font.GothamBold;close.TextColor3=ink;close.BackgroundColor3=Color3.fromRGB(46,56,74);close.BorderSizePixel=0;close.Parent=panel;rounded(close)
label(panel,'Cash packs are not on sale yet.',UDim2.fromOffset(14,47),UDim2.new(1,-28,0,22),13,Color3.fromRGB(159,181,194))
local list=Instance.new('ScrollingFrame');list.Name='CashPacks';list.Position=UDim2.fromOffset(12,80);list.Size=UDim2.new(1,-24,1,-177);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=4;list.CanvasSize=UDim2.fromOffset(0,312);list.Parent=panel
local summary=label(panel,'200 game cash per Robux • proposed prices',UDim2.new(0,14,1,-88),UDim2.new(1,-28,0,26),11,Color3.fromRGB(159,181,194))
local unavailable=Instance.new('TextButton');unavailable.Name='PurchasesUnavailable';unavailable.Position=UDim2.new(0,14,1,-53);unavailable.Size=UDim2.new(1,-28,0,38);unavailable.Text='COMING SOON';unavailable.Font=Enum.Font.GothamBold;unavailable.TextSize=14;unavailable.TextColor3=Color3.fromRGB(145,158,173);unavailable.BackgroundColor3=Color3.fromRGB(39,49,63);unavailable.BorderSizePixel=0;unavailable.Active=false;unavailable.AutoButtonColor=false;unavailable.Selectable=false;unavailable.Parent=panel;rounded(unavailable)
local cards={}
local function hide()
 panel.Visible=false;GS.SelectedObject=nil
 if playerGui:GetAttribute('OPActiveMenu')=='cashshop' then playerGui:SetAttribute('OPActiveMenu',nil) end
end
close.Activated:Connect(hide)
local function layout()
 local available=safe.AbsoluteSize
 if available.X<=0 or available.Y<=0 then return end
 panel.Size=UDim2.fromOffset(math.min(440,available.X-16),math.min(440,math.max(190,available.Y-108)))
end
safe:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
playerGui:GetAttributeChangedSignal('OPActiveMenu'):Connect(function()
 if playerGui:GetAttribute('OPActiveMenu')~='cashshop' and panel.Visible then panel.Visible=false;GS.SelectedObject=nil end
end)
UIS.InputBegan:Connect(function(input,processed)
 if panel.Visible and not processed and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then hide() end
end)
remote.OnClientEvent:Connect(function(data)
 if type(data)~='table' or data.kind~='preview' or data.available~=false or type(data.packs)~='table' then return end
 for _,card in ipairs(cards) do card:Destroy() end;cards={}
 for index,pack in ipairs(data.packs) do
  if index>4 then break end
  if type(pack)=='table' and type(pack.name)=='string' and type(pack.cash)=='number' and type(pack.robux)=='number' then
   local b=Instance.new('TextButton');b.Name='CashPack_'..tostring(pack.id);b.Position=UDim2.fromOffset(0,(index-1)*78);b.Size=UDim2.new(1,-8,0,70);b.Text='';b.BorderSizePixel=0;b.BackgroundColor3=Color3.fromRGB(34,48,65);b.Selectable=true;b.Parent=list;rounded(b)
   label(b,pack.name,UDim2.fromOffset(12,5),UDim2.new(.64,-12,0,24),14,gold)
   label(b,string.format('$%d game cash',pack.cash),UDim2.fromOffset(12,32),UDim2.new(.64,-12,0,26),13)
   local cost=label(b,string.format('%d Robux\nPROPOSED',pack.robux),UDim2.new(.64,0,0,10),UDim2.new(.36,-8,0,48),12,Color3.fromRGB(115,218,170));cost.TextXAlignment=Enum.TextXAlignment.Right
   b.Activated:Connect(function()
    for _,card in ipairs(cards) do card.BackgroundColor3=Color3.fromRGB(34,48,65) end
    b.BackgroundColor3=Color3.fromRGB(42,76,72)
    summary.Text=string.format('%s • $%d cash for %d Robux\nPreview only; purchases are unavailable.',pack.name,pack.cash,pack.robux)
   end)
   cards[#cards+1]=b
  end
 end
 summary.Text='200 game cash per Robux • proposed prices'
 layout();playerGui:SetAttribute('OPActiveMenu','cashshop');panel.Visible=true
 if UIS.GamepadEnabled then GS.SelectedObject=close end
end)
layout()
