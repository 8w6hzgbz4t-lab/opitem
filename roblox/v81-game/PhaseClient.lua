local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local CAS=game:GetService('ContextActionService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local net=RS:WaitForChild('OPItemNet')
local action=net:WaitForChild('Action')
local adminRequest=net:WaitForChild('AdminRequest')
local powers=require(net:WaitForChild('PowerCatalog'))
local gui=script.Parent;gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local safeBounds=Instance.new('Frame');safeBounds.Name='PowerSafeBounds';safeBounds.Size=UDim2.fromScale(1,1);safeBounds.BackgroundTransparency=1;safeBounds.Visible=false;safeBounds.Parent=gui
local state,received,lastKey=nil,0,''
local developerReadyAt=0
local selectedSlot,lastUse=1,-math.huge
local useButton
local updateSelection
local names={tag='TAG',dash='DASH',gravity='PULL',slow='SLOW',slam='SLAM',repulse='PULSE',shield='SHIELD',lightning='BOLT',kiblast='KI BLAST',spinjitzu='TORNADO'}
local function developerAbility()
 local d=state and state.developerAbility
 return type(d)=='table'and d.id=='royalseal'and d.mode==true and d.enabled==true and d or nil
end
local colors={panel=Color3.fromRGB(24,33,51),button=Color3.fromRGB(39,53,74),gold=Color3.fromRGB(232,195,115),ink=Color3.fromRGB(238,242,249),muted=Color3.fromRGB(159,178,202),ready=Color3.fromRGB(47,82,81)}
local function round(object)Instance.new('UICorner',object).CornerRadius=UDim.new(0,8)end
local function text(parent,value,size)
 local t=Instance.new('TextLabel');t.Size=size;t.BackgroundTransparency=1;t.TextColor3=colors.ink;t.Font=Enum.Font.Gotham;t.TextSize=13;t.TextWrapped=true;t.RichText=false;t.Text=value;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent;return t
end
local function button(parent,value,size,callback)
 local b=Instance.new('TextButton');b.Size=size;b.Text=value;b.TextSize=11;b.Font=Enum.Font.GothamMedium;b.TextColor3=colors.ink;b.BackgroundColor3=colors.button;b.BorderSizePixel=0;b.Selectable=true;b.Parent=parent;round(b);b.Activated:Connect(callback);return b
end
local function frame(parent,name,size)
 local f=Instance.new('Frame');f.Name=name;f.Size=size;f.BackgroundColor3=colors.panel;f.BorderSizePixel=0;f.Parent=parent;round(f);return f
end
local function clearMenu(key)if playerGui:GetAttribute('OPActiveMenu')==key then playerGui:SetAttribute('OPActiveMenu',nil)end end
local panel=frame(gui,'PowerMenu',UDim2.fromOffset(680,480));panel.AnchorPoint=Vector2.new(.5,.5);panel.Visible=false
local stroke=Instance.new('UIStroke');stroke.Color=colors.gold;stroke.Transparency=.5;stroke.Parent=panel
local title=text(panel,'POWERS & LOADOUT',UDim2.new(1,-150,0,34));title.Name='PowerMenuTitle';title.Position=UDim2.fromOffset(94,6);title.Font=Enum.Font.GothamMedium;title.TextSize=16;title.TextColor3=colors.gold
button(panel,'‹ Back',UDim2.fromOffset(78,36),function()clearMenu('powers')end).Position=UDim2.fromOffset(8,6)
local close=button(panel,'×',UDim2.fromOffset(36,36),function()clearMenu('powers')end);close.Position=UDim2.new(1,-44,0,6);close.TextSize=23
local list=Instance.new('ScrollingFrame');list.Name='PowerList';list.Position=UDim2.fromOffset(10,49);list.Size=UDim2.new(1,-20,1,-59);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.CanvasSize=UDim2.new();list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.ScrollBarThickness=4;list.ScrollBarImageColor3=colors.gold;list.Parent=panel
local function canCast()
 return state and not state.carry and not state.pending and not playerGui:GetAttribute('OPActiveMenu')and not UIS:GetFocusedTextBox()
end
local function validSlot(slot)
 if not state then return false end
 if slot==4 then return developerAbility()~=nil end
 local key=state.loadout[slot]
 return slot>=1 and slot<=3 and slot<=state.powerSlots and key~=nil and powers.ById[key]~=nil and state.powerOwned[key]==true
end
local function remaining(slot)
 if slot==4 then return math.max(0,developerReadyAt-os.clock())end
 local key=state and state.loadout[slot]
 return key and math.max(0,((state.powerReady or{})[key]or 0)-(os.clock()-received))or 0
end
local function selectSlot(slot)
 if not state or playerGui:GetAttribute('OPActiveMenu')or UIS:GetFocusedTextBox()or not validSlot(slot)then return false end
 selectedSlot=slot;playerGui:SetAttribute('OPSelectedPowerSlot',slot)
 if updateSelection then updateSelection()end
 return true
end
local function cast(slot)
 if not canCast()or not validSlot(slot)or remaining(slot)>0 or os.clock()-lastUse<.2 then return end
 lastUse=os.clock()
 if slot==4 then
  if not developerAbility() or os.clock()<developerReadyAt then return end
  developerReadyAt=os.clock()+.5
  adminRequest:FireServer({mode='command',text='royalseal'})
  return
 end
 local key=state.loadout[slot];local camera=workspace.CurrentCamera
 if key then
  local payload={id=key,aim=camera and camera.CFrame.LookVector or Vector3.zAxis}
  if(key=='slow'or key=='kiblast')and camera and camera.ViewportPointToRay and workspace.Raycast then
   local ray=camera:ViewportPointToRay(camera.ViewportSize.X*.5,camera.ViewportSize.Y*.5)
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
   params.FilterDescendantsInstances=player.Character and{player.Character}or{}
   local hit=workspace:Raycast(ray.Origin,ray.Direction*256,params)
   local point=hit and hit.Position or(ray.Origin+ray.Direction*80)
   if key=='slow'then payload.point=point
   else
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if root and(point-root.Position).Magnitude>.1 then payload.aim=(point-root.Position).Unit end
   end
  end
  action:FireServer('power',payload)
 end
end
local bar=frame(gui,'PowerHotbar',UDim2.fromOffset(330,36));bar.AnchorPoint=Vector2.new(.5,0);bar.BackgroundTransparency=1
local powerButtons={}
for slot=1,4 do
 local s=slot;local b=button(bar,tostring(slot),UDim2.new(1/3,-4,1,0),function()selectSlot(s)end)
 b.Name='PowerSlot'..slot;b.Position=UDim2.new((slot-1)/3,2,0,0);b.Visible=slot<=3;b.TextWrapped=true;b.TextSize=11;powerButtons[slot]=b
 local border=Instance.new('UIStroke');border.Name='Selection';border.Thickness=.6;border.Color=colors.muted;border.Transparency=.65;border.Parent=b
end
useButton=button(gui,'USE POWER',UDim2.fromOffset(180,36),function()cast(selectedSlot)end);useButton.Name='UseSelectedPower';useButton.AnchorPoint=Vector2.new(.5,0);useButton.TextWrapped=true;useButton.Visible=false
local activationHint=text(gui,'Select 1–3 · Use F / R2',UDim2.fromOffset(330,16));activationHint.Name='PowerActivationHint';activationHint.AnchorPoint=Vector2.new(.5,0);activationHint.TextSize=10;activationHint.TextColor3=colors.muted;activationHint.TextXAlignment=Enum.TextXAlignment.Center
local aimGui=Instance.new('ScreenGui');aimGui.Name='OPPowerAim';aimGui.ResetOnSpawn=false;aimGui.IgnoreGuiInset=true;aimGui.ScreenInsets=Enum.ScreenInsets.None;aimGui.DisplayOrder=14;aimGui.Parent=playerGui
local reticle=text(aimGui,'+',UDim2.fromOffset(24,24));reticle.Name='AimReticle';reticle.AnchorPoint=Vector2.new(.5,.5);reticle.Position=UDim2.fromScale(.5,.5);reticle.TextSize=24;reticle.TextXAlignment=Enum.TextXAlignment.Center;reticle.TextStrokeTransparency=.4;reticle.Visible=false
updateSelection=function()
 if state and not validSlot(selectedSlot)then selectedSlot=1 end
 playerGui:SetAttribute('OPSelectedPowerSlot',selectedSlot)
 for slot,b in ipairs(powerButtons)do
  local selected=slot==selectedSlot and validSlot(slot)
  b:SetAttribute('Selected',selected);b.TextColor3=selected and colors.gold or colors.ink
  local outline=b:FindFirstChild('Selection');outline.Thickness=selected and 2.2 or .6;outline.Transparency=selected and 0 or .65;outline.Color=selected and colors.gold or colors.muted
 end
 local wait=remaining(selectedSlot);local key=state and state.loadout[selectedSlot]
 reticle.Visible=canCast()and(key=='kiblast'or key=='slow')or false
 local name=selectedSlot==4 and'ROYAL SEAL'or(names[key]or'POWER')
 useButton.Text='USE · '..name..(wait>0 and(' · '..math.ceil(wait)..'s')or'')
 useButton.Active=canCast()and validSlot(selectedSlot)and wait<=0
 useButton.BackgroundColor3=useButton.Active and colors.ready or colors.button
end
for slot,key in ipairs({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four})do
 local s=slot;CAS:BindAction('OPPowerSlot'..slot,function(_,input)
  if input==Enum.UserInputState.Begin and selectSlot(s)then return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end,false,key)
end
CAS:BindAction('OPTagController',function(_,input)
 if input==Enum.UserInputState.Begin and selectSlot(1)then return Enum.ContextActionResult.Sink end
 return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.ButtonL2)
CAS:BindAction('OPUseSelectedPower',function(_,input)
 if input==Enum.UserInputState.Begin and canCast()then cast(selectedSlot);return Enum.ContextActionResult.Sink end
 return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.F,Enum.KeyCode.ButtonR2)
CAS:BindAction('OPClosePowerMenu',function(_,input)
 if input==Enum.UserInputState.Begin and playerGui:GetAttribute('OPActiveMenu')=='powers'and not UIS:GetFocusedTextBox()then clearMenu('powers');return Enum.ContextActionResult.Sink end
 return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.ButtonB)
local function render()
 if not state then return end
 local oldPosition=list.CanvasPosition
 for _,child in ipairs(list:GetChildren())do child:Destroy()end
 local layout=Instance.new('UIListLayout');layout.Padding=UDim.new(0,8);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=list
 title.Text='POWERS · LEVEL '..state.level
 text(list,'Tag stays in slot 1. Equip up to two optional powers. Click a slot or press 1/2/3 to SELECT it; press F, controller R2 or touch USE to activate. Carrying and bidding disable every power.',UDim2.new(1,-8,0,78)).TextColor3=colors.muted
 if state.powerSlots<3 then
  button(list,state.level>=1 and'UNLOCK OPTIONAL SLOT 3 · LEVEL REWARD'or('UNLOCK OPTIONAL SLOT 3 · $'..state.thirdSlotPrice),UDim2.new(1,-8,0,42),function()action:FireServer('powerSlot')end).Name='UnlockPowerSlot'
 end
 for index,d in ipairs(powers.Items)do
  local row=frame(list,'PowerCard_'..d.id,UDim2.new(1,-8,0,144));row.BackgroundColor3=Color3.fromRGB(29,41,61);row.LayoutOrder=index
  local name=text(row,d.name..'  ·  RANK '..d.rank..'  ·  '..d.cooldown..'s',UDim2.new(1,-16,0,24));name.Name='PowerName';name.Position=UDim2.fromOffset(8,5);name.Font=Enum.Font.GothamMedium;name.TextSize=12;name.TextColor3=colors.gold
  local detail=text(row,d.description,UDim2.new(1,-16,0,60));detail.Name='PowerDescription';detail.Position=UDim2.fromOffset(8,31);detail.TextSize=11;detail.TextColor3=colors.muted
  local owned=state.powerOwned[d.id];local starter=state.starterPending and d.starter
  if starter then button(row,'CHOOSE FREE STARTER',UDim2.new(1,-16,0,40),function()action:FireServer('starter',d.id)end).Position=UDim2.fromOffset(8,97)
  elseif not owned then button(row,'BUY · $'..d.price,UDim2.new(1,-16,0,40),function()action:FireServer('buyPower',d.id)end).Position=UDim2.fromOffset(8,97)
  elseif d.id~='tag'then
   for slot=2,3 do
    local s=slot;local locked=slot>state.powerSlots;local equipped=state.loadout[slot]==d.id
    local b=button(row,locked and'SLOT 3 LOCKED'or(equipped and('EQUIPPED · '..slot)or('EQUIP SLOT '..slot)),UDim2.new(.5,-12,0,40),function()if not locked then action:FireServer('loadPower',{id=d.id,slot=s})end end)
    b.Position=UDim2.new((slot-2)*.5,8,0,97);b.BackgroundColor3=equipped and colors.ready or colors.button;b.TextTransparency=locked and .45 or 0
   end
  else local fixed=text(row,'PERMANENT · SLOT 1',UDim2.new(1,-16,0,40));fixed.Position=UDim2.fromOffset(8,97);fixed.TextColor3=colors.gold end
 end
 task.defer(function()if list.Parent then list.CanvasPosition=oldPosition end end)
end
-- Auctions and collection rewards start as small opt-in banners, never forced windows.
local currentBattle
local battle=frame(gui,'BuyBattle',UDim2.fromOffset(280,36));battle.Visible=false
local battleToggle=button(battle,'BUY BATTLE',UDim2.new(1,0,0,36),function()
 if currentBattle then playerGui:SetAttribute('OPActiveMenu',playerGui:GetAttribute('OPActiveMenu')=='battle'and nil or'battle')end
end);battleToggle.Name='OpenBuyBattle';battleToggle.TextColor3=colors.gold
local battleBody=frame(battle,'BattleDetails',UDim2.new(1,0,0,134));battleBody.Position=UDim2.fromOffset(0,40);battleBody.Visible=false
local battleText=text(battleBody,'',UDim2.new(1,-16,0,49));battleText.Position=UDim2.fromOffset(8,4);battleText.TextSize=12
local amount=Instance.new('TextBox');amount.Name='BidAmount';amount.Size=UDim2.new(.5,-12,0,36);amount.Position=UDim2.fromOffset(8,57);amount.Text='';amount.PlaceholderText='Bid amount';amount.ClearTextOnFocus=false;amount.TextSize=14;amount.TextColor3=colors.ink;amount.BackgroundColor3=colors.button;amount.BorderSizePixel=0;amount.Parent=battleBody;round(amount)
local function bid()
 local value=tonumber(amount.Text)
 if currentBattle and value and value==value and value%1==0 and value>0 and value<math.huge then action:FireServer('bid',{offer=currentBattle.id,amount=value})end
end
button(battleBody,'PLACE BID',UDim2.new(.5,-12,0,36),bid).Position=UDim2.new(.5,4,0,57)
button(battleBody,'WITHDRAW & RELEASE FUNDS',UDim2.new(1,-16,0,32),function()action:FireServer('withdraw')end).Position=UDim2.fromOffset(8,99)
local rewardBanner=button(gui,'EXODIA REWARD READY · OPEN',UDim2.fromOffset(280,36),function()
 if state and state.exodia then playerGui:SetAttribute('OPActiveMenu',playerGui:GetAttribute('OPActiveMenu')=='exodia'and nil or'exodia')end
end);rewardBanner.Name='OpenExodiaReward';rewardBanner.Visible=false;rewardBanner.TextColor3=colors.gold
local reward=frame(gui,'ExodiaReward',UDim2.fromOffset(440,237));reward.AnchorPoint=Vector2.new(.5,.5);reward.Position=UDim2.fromScale(.5,.5);reward.Visible=false
local rewardTitle=text(reward,'EXODIA COLLECTION COMPLETE',UDim2.new(1,-60,0,34));rewardTitle.Position=UDim2.fromOffset(12,6);rewardTitle.Font=Enum.Font.GothamBold;rewardTitle.TextColor3=colors.gold
button(reward,'×',UDim2.fromOffset(36,36),function()clearMenu('exodia')end).Position=UDim2.new(1,-44,0,6)
local rewardHelp=text(reward,'Choose one reward. Your collected pieces remain in your base. This same completed set cannot grant another reward.',UDim2.new(1,-24,0,74));rewardHelp.Position=UDim2.fromOffset(12,47);rewardHelp.TextColor3=colors.muted
button(reward,'SAFELY RESPAWN EVERYONE',UDim2.new(1,-24,0,42),function()
 if state and state.exodia then action:FireServer('exodia',{token=state.exodia,choice='respawn'});clearMenu('exodia')end
end).Position=UDim2.fromOffset(12,131)
button(reward,'GAIN ONE BASE LEVEL',UDim2.new(1,-24,0,42),function()
 if state and state.exodia then action:FireServer('exodia',{token=state.exodia,choice='level'});clearMenu('exodia')end
end).Position=UDim2.fromOffset(12,181)
local function syncMenus()
 local active=playerGui:GetAttribute('OPActiveMenu');local wasVisible=panel.Visible
 panel.Visible=active=='powers';bar.Visible=active==nil or active==''
 useButton.Visible=UIS.TouchEnabled and bar.Visible
 activationHint.Visible=not UIS.TouchEnabled and bar.Visible
 battleBody.Visible=currentBattle~=nil and active=='battle'
 battle.Visible=currentBattle~=nil and(active==nil or active==''or active=='battle')
 reward.Visible=state~=nil and state.exodia~=nil and active=='exodia'
 rewardBanner.Visible=state~=nil and state.exodia~=nil and(active==nil or active==''or active=='exodia')and not reward.Visible
 if panel.Visible and not wasVisible then render()end
end
playerGui:GetAttributeChangedSignal('OPActiveMenu'):Connect(syncMenus)
local function layout()
 local camera=workspace.CurrentCamera;if not camera then return end
 local available=safeBounds.AbsoluteSize
 local width,height=(available.X>0 and available.X or camera.ViewportSize.X),(available.Y>0 and available.Y or camera.ViewportSize.Y)
 local narrow=width<640
 local count=developerAbility()and 4 or 3
 if state and not validSlot(selectedSlot)then selectedSlot=1 end
 for slot,b in ipairs(powerButtons)do b.Visible=slot<=count;b.Size=UDim2.new(1/count,-4,1,0);b.Position=UDim2.new((slot-1)/count,2,0,0)end
 bar.Size=UDim2.fromOffset(math.min(count==4 and 440 or 330,width-16),36);bar.Position=narrow and UDim2.new(.5,0,0,104)or UDim2.new(.5,0,1,-90)
 useButton.Position=narrow and UDim2.new(.5,0,0,148)or UDim2.new(.5,0,1,-134)
 activationHint.Position=narrow and UDim2.new(.5,0,0,148)or UDim2.new(.5,0,1,-110)
 activationHint.Text='Select 1–'..count..' · Use F / R2'
 if narrow then panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,146);panel.Size=UDim2.fromOffset(width-16,math.max(180,height-154))
 else panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.new(.5,0,.5,2);panel.Size=UDim2.fromOffset(math.min(720,width-24),math.min(510,math.max(190,height-176)))end
 battle.Size=UDim2.fromOffset(math.min(280,width-16),36);battle.Position=UDim2.fromOffset(8,narrow and 244 or 64)
 rewardBanner.Size=UDim2.fromOffset(math.min(280,width-16),36);rewardBanner.Position=narrow and UDim2.fromOffset(8,286)or UDim2.new(.5,-140,0,108)
 reward.Size=UDim2.fromOffset(math.min(440,width-16),237)
 updateSelection()
end
local cameraConnection
local function bindCamera()
 if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
 layout();if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout)end
end
bindCamera();workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(bindCamera)
safeBounds:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
net.Update.OnClientEvent:Connect(function(snapshot)
 if snapshot.cash==nil then return end
 state=snapshot;received=os.clock()
 local developer=developerAbility();developerReadyAt=developer and(os.clock()+math.max(0,tonumber(developer.remaining)or 0))or 0
 layout()
 local keys={tostring(snapshot.powerSlots),tostring(snapshot.level),tostring(snapshot.starterPending)}
 for _,d in ipairs(powers.Items)do keys[#keys+1]=tostring(snapshot.powerOwned[d.id])end
 for slot=1,3 do keys[#keys+1]=tostring(snapshot.loadout[slot])end
 local key=table.concat(keys,':');if panel.Visible and key~=lastKey then render()end;lastKey=key
 local previous=currentBattle;local nextBattle=snapshot.battles and snapshot.battles[1]
 if nextBattle and(not previous or nextBattle.id~=previous.id or nextBattle.price~=previous.price)and not amount:IsFocused()then amount.Text=tostring(nextBattle.minimum)end
 currentBattle=nextBattle
 if not currentBattle then clearMenu('battle')end
 if not snapshot.exodia then clearMenu('exodia')end
 syncMenus()
end)
net:WaitForChild('Phase').OnClientEvent:Connect(function(payload)
 if payload.open=='powers'then playerGui:SetAttribute('OPActiveMenu','powers')end
end)
-- Replies refresh the countdown immediately; only the owner-only snapshot enables slot 4.
net:WaitForChild('AdminResponse').OnClientEvent:Connect(function(reply)
 if not developerAbility()or type(reply)~='table'then return end
 if reply.authorized==false then
  state.developerAbility=nil;developerReadyAt=0;layout();return
 end
 local mods=reply.mods
 if type(mods)=='table'then
  if mods.developerMode==false then state.developerAbility=nil;developerReadyAt=0;layout()
  elseif type(mods.royalSealRemaining)=='number'then developerReadyAt=os.clock()+math.max(0,mods.royalSealRemaining)end
 end
end)
local accumulator=0
Run.Heartbeat:Connect(function(dt)
 accumulator+=dt;if accumulator<.1 then return end;accumulator=0
 if state then
  for slot,b in ipairs(powerButtons)do
   if slot==4 then
    local d=developerAbility();local remaining=math.max(0,developerReadyAt-os.clock())
    b.Visible=d~=nil
    b.Text=state.carry and'CARRYING'or(state.pending and'BIDDING'or('4 ROYAL SEAL'..(remaining>0 and(' · '..math.ceil(remaining)..'s')or'')))
    b.BackgroundColor3=d and remaining<=0 and not state.carry and not state.pending and colors.ready or colors.button
    b.TextColor3=colors.gold
   else
   local key=state.loadout[slot];local definition=key and powers.ById[key]
   local remaining=key and math.max(0,(state.powerReady[key]or 0)-(os.clock()-received))or 0
   b.Text=state.carry and'CARRYING'or(state.pending and'BIDDING'or(definition and(slot..' '..(names[key]or definition.name)..(remaining>0 and(' · '..math.ceil(remaining)..'s')or''))or(slot..(slot>state.powerSlots and' LOCKED'or' EMPTY'))))
   b.BackgroundColor3=remaining<=0 and not state.carry and not state.pending and definition and colors.ready or colors.button
   end
  end
  updateSelection()
 end
 if currentBattle then
  local seconds=math.max(0,math.ceil(currentBattle.ends-workspace:GetServerTimeNow()))
  battleToggle.Text='BUY BATTLE · '..seconds..'s · '..(battleBody.Visible and'CLOSE'or'OPEN')
  battleText.Text=currentBattle.name..'\n$'..currentBattle.price..' · minimum $'..currentBattle.minimum
 end
end)
syncMenus();action:FireServer('ready')
