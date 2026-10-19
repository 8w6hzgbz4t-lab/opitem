local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local CAS=game:GetService('ContextActionService');local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer;local net=RS:WaitForChild('OPItemNet');local action=net:WaitForChild('Action');local powers=require(net:WaitForChild('PowerCatalog'))
local gui=script.Parent;local state;local mode='powers';local lastRevision=-1;local received=0
local function text(parent,value,size)
 local t=Instance.new('TextLabel');t.Size=size;t.BackgroundTransparency=1;t.TextColor3=Color3.fromRGB(236,242,255);t.Font=Enum.Font.Gotham;t.TextSize=13;t.TextWrapped=true;t.Text=value;t.Parent=parent;return t
end
local function button(parent,value,size,cb)
 local b=Instance.new('TextButton');b.Size=size;b.Text=value;b.TextSize=13;b.Font=Enum.Font.GothamBold;b.TextColor3=Color3.new(1,1,1);b.BackgroundColor3=Color3.fromRGB(43,58,85);b.Parent=parent;b.Activated:Connect(cb);return b
end
local panel=Instance.new('Frame');panel.Size=UDim2.fromScale(.88,.72);panel.Position=UDim2.fromScale(.06,.17);panel.BackgroundColor3=Color3.fromRGB(20,28,46);panel.Visible=false;panel.Parent=gui
local title=text(panel,'POWER SHOP / LOADOUT',UDim2.new(1,-50,0,35));button(panel,'X',UDim2.fromOffset(40,30),function()panel.Visible=false end).Position=UDim2.new(1,-44,0,3)
local list=Instance.new('ScrollingFrame');list.Position=UDim2.fromOffset(8,40);list.Size=UDim2.new(1,-16,1,-48);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.CanvasSize=UDim2.new();list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.ScrollBarThickness=5;list.Parent=panel
local function cast(slot)
 local key=state and state.loadout[slot];local camera=workspace.CurrentCamera
 if key then action:FireServer('power',{id=key,aim=camera and camera.CFrame.LookVector or Vector3.zAxis}) end
end
local bar=Instance.new('Frame');bar.Size=UDim2.fromOffset(112,158);bar.Position=UDim2.new(1,-122,0,235);bar.BackgroundTransparency=1;bar.Parent=gui
local shop=button(bar,'POWERS',UDim2.fromOffset(112,32),function()panel.Visible=not panel.Visible end)
local powerButtons={}
for slot=1,3 do
 local s=slot;local b=button(bar,tostring(slot),UDim2.fromOffset(112,36),function()cast(s)end);b.TextWrapped=true;b.Position=UDim2.fromOffset(0,36+(slot-1)*40);powerButtons[slot]=b
end
for slot,key in ipairs({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three}) do local s=slot
 CAS:BindAction('OPPowerSlot'..slot,function(_,input)if input==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then cast(s) end;return Enum.ContextActionResult.Pass end,false,key)
end
CAS:BindAction('OPTagController',function(_,input)if input==Enum.UserInputState.Begin then cast(1)end;return Enum.ContextActionResult.Pass end,false,Enum.KeyCode.ButtonL2)
local function render()
 if not state then return end
 for _,v in list:GetChildren() do v:Destroy() end
 local layout=Instance.new('UIListLayout');layout.Padding=UDim.new(0,7);layout.Parent=list
 title.Text='POWER SHOP / LOADOUT • LEVEL '..state.level
 text(list,'Tag permanently occupies slot 1. Choose one free starter, then buy powers at a cyan console. You can equip two selectable powers after unlocking slot 3. Every power is disabled while carrying or bidding.',UDim2.new(1,-8,0,85))
 if state.powerSlots<3 then button(list,'UNLOCK SLOT 3 • $'..state.thirdSlotPrice..' or one progression level',UDim2.new(1,-8,0,40),function()action:FireServer('powerSlot')end) end
 for _,d in ipairs(powers.Items) do
  local row=Instance.new('Frame');row.Size=UDim2.new(1,-8,0,154);row.BackgroundColor3=Color3.fromRGB(30,40,61);row.Parent=list
  local owned=state.powerOwned[d.id];local starter=state.starterPending and d.starter
  text(row,'RANK '..d.rank..' • '..d.name..' • $'..d.price..' • '..d.cooldown..'s cooldown\n'..d.description,UDim2.new(1,-12,0,95)).Position=UDim2.fromOffset(6,3)
  if starter then button(row,'CHOOSE FREE STARTER',UDim2.new(1,-12,0,42),function()action:FireServer('starter',d.id)end).Position=UDim2.fromOffset(6,105)
  elseif not owned then button(row,'BUY POWER',UDim2.new(1,-12,0,42),function()action:FireServer('buyPower',d.id)end).Position=UDim2.fromOffset(6,105)
  elseif d.id~='tag' then
   for slot=2,3 do local s=slot;button(row,'EQUIP '..slot,UDim2.new(.5,-9,0,42),function()action:FireServer('loadPower',{id=d.id,slot=s})end).Position=UDim2.new((slot-2)*.5,6,0,105) end
  else text(row,'PERMANENT SLOT 1',UDim2.new(1,-12,0,42)).Position=UDim2.fromOffset(6,105) end
 end
end
shop.Activated:Connect(render)
local battle=Instance.new('Frame');battle.Size=UDim2.fromOffset(280,145);battle.Position=UDim2.fromOffset(10,180);battle.BackgroundColor3=Color3.fromRGB(27,36,56);battle.Visible=false;battle.Parent=gui
local battleText=text(battle,'',UDim2.new(1,-12,0,60));battleText.Position=UDim2.fromOffset(6,3)
local amount=Instance.new('TextBox');amount.Size=UDim2.new(.48,-8,0,32);amount.Position=UDim2.fromOffset(6,66);amount.Text='';amount.ClearTextOnFocus=false;amount.TextSize=15;amount.Parent=battle
local currentBattle
button(battle,'BID',UDim2.new(.48,-8,0,32),function()if currentBattle then action:FireServer('bid',{offer=currentBattle.id,amount=tonumber(amount.Text)})end end).Position=UDim2.new(.52,0,0,66)
button(battle,'WITHDRAW / RELEASE FUNDS',UDim2.new(1,-12,0,32),function()action:FireServer('withdraw')end).Position=UDim2.fromOffset(6,105)
local function layout()
 local camera=workspace.CurrentCamera;if not camera then return end
 local short=camera.ViewportSize.Y<550
 if short then
  bar.Size=UDim2.fromOffset(328,44);bar.Position=UDim2.new(1,-338,0,129)
  shop.Size=UDim2.fromOffset(80,44);shop.Position=UDim2.fromOffset(0,0);shop.TextSize=11
  for slot,b in ipairs(powerButtons) do b.Size=UDim2.fromOffset(80,44);b.Position=UDim2.fromOffset(82*slot,0);b.TextSize=12 end
 else
  bar.Size=UDim2.fromOffset(112,158);bar.Position=UDim2.new(1,-122,0,235)
  shop.Size=UDim2.fromOffset(112,32);shop.Position=UDim2.fromOffset(0,0);shop.TextSize=13
  for slot,b in ipairs(powerButtons) do b.Size=UDim2.fromOffset(112,36);b.Position=UDim2.fromOffset(0,36+(slot-1)*40);b.TextSize=12 end
 end
 battle.Size=UDim2.fromOffset(math.min(280,camera.ViewportSize.X*.4),145)
 battle.Position=UDim2.fromOffset(10,short and 129 or 180)
 battleText.TextSize=camera.ViewportSize.X<500 and 11 or 13
end
layout()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout) end
local reward=Instance.new('Frame');reward.Size=UDim2.new(.8,0,0,190);reward.Position=UDim2.new(.1,0,.35,0);reward.BackgroundColor3=Color3.fromRGB(42,35,66);reward.Visible=false;reward.Parent=gui
text(reward,'FIVE-PIECE GUARDIAN COMPLETE\nChoose one reward. Your pieces remain in your collection. Reusing this same set cannot grant another reward.',UDim2.new(1,-16,0,88)).Position=UDim2.fromOffset(8,5)
button(reward,'SAFELY RESPAWN EVERYONE',UDim2.new(1,-16,0,38),function()if state and state.exodia then action:FireServer('exodia',{token=state.exodia,choice='respawn'})end end).Position=UDim2.fromOffset(8,98)
button(reward,'GAIN ONE LEVEL • KEEP EIGHT SLOTS',UDim2.new(1,-16,0,38),function()if state and state.exodia then action:FireServer('exodia',{token=state.exodia,choice='level'})end end).Position=UDim2.fromOffset(8,142)
net.Update.OnClientEvent:Connect(function(s)
 if s.cash==nil then return end
 state=s;received=os.clock()
 if s.revision~=lastRevision then lastRevision=s.revision;if panel.Visible then render() end end
 if s.starterPending and not gui:GetAttribute('StarterShown') then gui:SetAttribute('StarterShown',true);shop.Text='FREE STARTER' end
 if not s.starterPending then shop.Text='POWERS' end
 reward.Visible=s.exodia~=nil
 local b=s.battles and s.battles[1]
 if b and (not currentBattle or b.id~=currentBattle.id or b.price~=currentBattle.price) and not amount:IsFocused() then amount.Text=tostring(b.minimum) end
 currentBattle=b;battle.Visible=b~=nil
end)
net:WaitForChild('Phase').OnClientEvent:Connect(function(s)if s.open=='powers' then panel.Visible=true;render()end end)
local acc=0
Run.Heartbeat:Connect(function(dt)
 acc+=dt;if acc<.1 then return end;acc=0
 if state then
  for slot,b in ipairs(powerButtons) do
   local key=state.loadout[slot];local d=key and powers.ById[key]
   local remaining=key and math.max(0,(state.powerReady[key] or 0)-(os.clock()-received)) or 0
   local names={tag='Tag',dash='Dash',gravity='Pull',slow='Slow Field',slam='Slam',repulse='Pulse',shield='Shield',lightning='Lightning'}
   b.Text=state.carry and 'CARRYING' or (state.pending and 'BIDDING' or (d and (slot..' • '..(names[key] or d.name)..(remaining>0 and '\n'..math.ceil(remaining)..'s' or '')) or (slot..' • EMPTY')))
  end
 end
 if currentBattle then battleText.Text='BUY BATTLE • '..currentBattle.name..'\n$'..currentBattle.price..' • '..math.max(0,math.ceil(currentBattle.ends-workspace:GetServerTimeNow()))..'s remaining' end
end)
action:FireServer('ready')

