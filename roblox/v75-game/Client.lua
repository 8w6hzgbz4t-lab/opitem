local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local CAS=game:GetService('ContextActionService')
local UIS=game:GetService('UserInputService')
local GS=game:GetService('GuiService')
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local net=RS:WaitForChild('OPItemNet')
local action=net:WaitForChild('Action');local update=net:WaitForChild('Update')
local catalog=require(net:WaitForChild('Catalog'));local templates=net:WaitForChild('Models')
local gui=script.Parent;assert(gui:IsA('ScreenGui'),'Client must live inside persistent HUD')
gui.ResetOnSpawn=false;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local colors={bg=Color3.fromRGB(14,20,34),panel=Color3.fromRGB(24,33,51),ink=Color3.fromRGB(238,242,249),muted=Color3.fromRGB(159,178,202),cyan=Color3.fromRGB(91,224,214),gold=Color3.fromRGB(232,195,115)}
local function compact(value)
 value=tonumber(value)or 0
 local n=math.abs(value)
 if n>=1000000000 then return string.format('%.1fB',value/1000000000)
 elseif n>=1000000 then return string.format('%.1fM',value/1000000)
 elseif n>=10000 then return string.format('%.1fK',value/1000)
 else return tostring(math.floor(value))end
end
local function corner(x,radius)Instance.new('UICorner',x).CornerRadius=UDim.new(0,radius or 8)end
local function frame(parent,name,pos,size)
 local f=Instance.new('Frame');f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=colors.panel;f.BorderSizePixel=0;f.Parent=parent;corner(f);return f
end
local function text(parent,str,pos,size,fontSize,color)
 local t=Instance.new('TextLabel');t.Position=pos;t.Size=size;t.Text=str;t.TextColor3=color or colors.ink
 t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize or 14;t.BackgroundTransparency=1;t.TextWrapped=true;t.RichText=false
 t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent;return t
end
local function button(parent,str,pos,size,cb)
 local b=Instance.new('TextButton');b.Position=pos;b.Size=size;b.Text=str;b.Font=Enum.Font.GothamBold;b.TextSize=12
 b.TextColor3=colors.ink;b.BackgroundColor3=Color3.fromRGB(39,53,74);b.BorderSizePixel=0;b.Selectable=true;b.Parent=parent;corner(b)
 b.Activated:Connect(cb);return b
end
local screen=frame(gui,'Canvas',UDim2.new(),UDim2.fromScale(1,1));screen.BackgroundTransparency=1
local top=frame(screen,'Status',UDim2.fromOffset(8,6),UDim2.fromOffset(600,52))
local edge=Instance.new('UIStroke');edge.Color=colors.gold;edge.Transparency=.74;edge.Parent=top
local cash=text(top,'Loading vault…',UDim2.fromOffset(9,3),UDim2.new(.6,-10,0,19),13,colors.cyan)
local protect=text(top,'',UDim2.new(.6,0,0,3),UDim2.new(.4,-8,0,29),10,colors.gold);protect.TextXAlignment=Enum.TextXAlignment.Right
local income=text(top,'',UDim2.fromOffset(9,23),UDim2.new(1,-18,0,13),10,colors.muted)
local bank=text(top,'',UDim2.fromOffset(9,37),UDim2.new(1,-18,0,12),10,colors.muted)
local notice=frame(screen,'Notice',UDim2.fromOffset(0,64),UDim2.fromOffset(300,44));notice.AnchorPoint=Vector2.new(1,0);notice.Visible=false;notice.ZIndex=20
local noticeText=text(notice,'',UDim2.fromOffset(9,3),UDim2.new(1,-18,1,-6),12);noticeText.ZIndex=21
local noticeId=0
local function message(msg)
 noticeId+=1;local id=noticeId;noticeText.Text=tostring(msg);notice.Visible=true
 task.delay(4,function()if noticeId==id then notice.Visible=false end end)
end
local state,selected,confirmSale=nil,nil,nil
local mode='Inventory';local reduced=false;local render;local inventoryKey='';local searchQuery=''
local panel=frame(screen,'Menu',UDim2.fromScale(.5,.5),UDim2.fromOffset(760,490));panel.AnchorPoint=Vector2.new(.5,.5);panel.Visible=false
local panelBorder=Instance.new('UIStroke');panelBorder.Color=colors.gold;panelBorder.Transparency=.5;panelBorder.Parent=panel
local title=text(panel,'Inventory',UDim2.fromOffset(94,7),UDim2.new(1,-150,0,32),18,colors.gold)
local function closeMenu()
 panel.Visible=false;GS.SelectedObject=nil
 local active=playerGui:GetAttribute('OPActiveMenu')
 if active=='inventory'or active=='index'or active=='help'or active=='settings'then playerGui:SetAttribute('OPActiveMenu',nil)end
end
local back=button(panel,'‹ Back',UDim2.fromOffset(8,6),UDim2.fromOffset(78,36),function()
 if (mode=='Inventory'or mode=='Index')and panel.AbsoluteSize.X<520 and selected then selected=nil;confirmSale=nil;render()else closeMenu()end
end);back.Name='MenuBack'
local close=button(panel,'×',UDim2.new(1,-44,0,6),UDim2.fromOffset(36,36),closeMenu);close.Name='MenuClose';close.TextSize=23
local content=frame(panel,'Content',UDim2.fromOffset(10,49),UDim2.new(1,-20,1,-59));content.BackgroundTransparency=1
local bottom=frame(screen,'Navigation',UDim2.new(.5,0,1,-48),UDim2.fromOffset(520,40));bottom.AnchorPoint=Vector2.new(.5,0)
local navButtons={}
local function markNavigation()
 local active=playerGui:GetAttribute('OPActiveMenu')
 for key,b in pairs(navButtons)do b.BackgroundColor3=active==key and Color3.fromRGB(47,82,81)or Color3.fromRGB(39,53,74);b.TextColor3=active==key and colors.gold or colors.ink end
end
local function layout()
 local camera=workspace.CurrentCamera;if not camera then return end
 local available=screen.AbsoluteSize
 local width,height=(available.X>0 and available.X or camera.ViewportSize.X),(available.Y>0 and available.Y or camera.ViewportSize.Y)
 local portrait=width<640
 top.Size=UDim2.fromOffset(math.min(600,math.max(146,width-184)),52)
 bottom.Size=UDim2.fromOffset(math.min(520,width-16),40)
 if portrait then
  bottom.Position=UDim2.new(.5,0,0,60)
  panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,146);panel.Size=UDim2.fromOffset(width-16,math.max(180,height-154))
  notice.Position=UDim2.new(1,-8,0,196);notice.Size=UDim2.fromOffset(math.min(300,width-16),44)
 else
  bottom.Position=UDim2.new(.5,0,1,-48)
  panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.new(.5,0,.5,2);panel.Size=UDim2.fromOffset(math.min(800,width-24),math.min(510,math.max(190,height-176)))
  notice.Position=UDim2.new(1,-8,0,96);notice.Size=UDim2.fromOffset(300,44)
 end
 if panel.Visible and render then render()end
end
local cameraConnection
local function bindCamera()
 if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
 layout()
 if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout)end
end
bindCamera();workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(bindCamera)
screen:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
local menuKeys={inventory='Inventory',index='Index',help='Help',settings='Settings'}
local function show(which)
 if not state then message('Your vault is loading. Try again in a moment.');return end
 local key=string.lower(which)
 if panel.Visible and mode==which and playerGui:GetAttribute('OPActiveMenu')==key then closeMenu();return end
 mode=which;selected=nil;confirmSale=nil;searchQuery='';playerGui:SetAttribute('OPActiveMenu',key);panel.Visible=true;render();markNavigation()
 if UIS.GamepadEnabled then GS.SelectedObject=close end
end
playerGui:GetAttributeChangedSignal('OPActiveMenu'):Connect(function()
 local active=playerGui:GetAttribute('OPActiveMenu');local wanted=menuKeys[active]
 if not wanted then panel.Visible=false;GS.SelectedObject=nil
 elseif state and(not panel.Visible or mode~=wanted)then mode=wanted;selected=nil;confirmSale=nil;searchQuery='';panel.Visible=true;render()end
 markNavigation()
end)
local labels={{'inventory','Inventory'},{'index','Index'},{'powers','Powers'},{'help','Help'},{'settings','Settings'}}
for i,entry in ipairs(labels)do
 local key,label=entry[1],entry[2]
 local b=button(bottom,label,UDim2.new((i-1)*.2,3,0,2),UDim2.new(.2,-6,1,-4),function()
  if key=='powers'then playerGui:SetAttribute('OPActiveMenu',playerGui:GetAttribute('OPActiveMenu')=='powers'and nil or'powers')else show(menuKeys[key])end
 end)
 b.Name='Navigate'..label;navButtons[key]=b
end
markNavigation()
local function scrolling(parent)
 local f=Instance.new('ScrollingFrame');f.BackgroundTransparency=1;f.BorderSizePixel=0;f.ScrollBarThickness=4;f.ScrollBarImageColor3=colors.gold
 f.AutomaticCanvasSize=Enum.AutomaticSize.Y;f.CanvasSize=UDim2.new();f.Parent=parent;return f
end
local function preview(d,parent)
 local vp=Instance.new('ViewportFrame');vp.Name='ItemPreview';vp.Size=UDim2.new(1,0,0,150);vp.BackgroundColor3=colors.bg;vp.BorderSizePixel=0;vp.Ambient=Color3.fromRGB(205,205,225);vp.LightColor=Color3.new(1,1,1);vp.Parent=parent;corner(vp)
 local camera=Instance.new('Camera');camera.Parent=vp;vp.CurrentCamera=camera
 local template=templates:FindFirstChild(d.id)
 if template then
  local model=template:Clone();model.Parent=vp;model:PivotTo(CFrame.Angles(0,.35,0))
  local cf,size=model:GetBoundingBox();local center=cf.Position;local radius=math.max(size.X,size.Y,size.Z)*.5
  local aspect=math.max(.45,parent.AbsoluteSize.X/150);local distance=radius/math.tan(math.rad(16))*math.max(1,1/aspect)+1
  camera.FieldOfView=32;camera.CFrame=CFrame.lookAt(center+Vector3.new(.5,.25,1).Unit*distance,center)
 end
end
render=function()
 if not state then return end
 local hadFocus=GS.SelectedObject and GS.SelectedObject:IsDescendantOf(content)
 for _,c in ipairs(content:GetChildren())do c:Destroy()end
 if hadFocus then GS.SelectedObject=close end
 title.Text=mode=='Inventory'and'MY VAULT'or(mode=='Index'and('RELIC INDEX · '..#catalog.Items)or string.upper(mode))
 if mode=='Help'then
  local list=scrolling(content);list.Size=UDim2.fromScale(1,1)
  local help='BUY & STEAL\nHold E, controller X or touch for 0.35 seconds. Follow the item while holding, then carry it across your base’s wide green entrance line. That completes delivery and recharges ready protection.\n\nSTOP A CARRIER\nTag knocks carried loot loose. Interrupted purchases return to the belt and refund reserved money. Interrupted stolen items return to their owner. Buy Battles reserve bids and space; leaving, dying or taking a hit releases your bid.\n\nPOWERS\nTag stays in slot 1. Choose a free starter in Powers, then buy upgrades at a Power Lab console. Use keys 1/2/3 or the three slot buttons. Q or controller R2 uses slot 2; controller L2 uses Tag. Carrying and bidding disable powers.\n\nBASE LEVELS\nUpgrade at your base console. Each level raises your own item income by 5% and increases base protection. Level 5 unlocks a fitted second floor with eight extra slots, solid walls, a roof and matching protection.\n\nCOLLECTION EVENTS\nFive distinct deposited Exodia pieces unlock a reward. Five distinct Infinity Stones grant a level. Your stored items survive character resets and can still be stolen from an unprotected base.\n\nSession alpha: this server’s progress resets when you leave.'
  local t=text(list,help,UDim2.fromOffset(3,0),UDim2.new(1,-12,0,0),14);t.AutomaticSize=Enum.AutomaticSize.Y
 elseif mode=='Settings'then
  local list=scrolling(content);list.Size=UDim2.fromScale(1,1)
  local reducedButton=button(list,reduced and'Reduced effects: ON'or'Reduced effects: OFF',UDim2.fromOffset(0,4),UDim2.new(1,-8,0,44),function()
   reduced=not reduced;playerGui:SetAttribute('OPReducedEffects',reduced)
   if reduced then local world=workspace:FindFirstChild('OPItemWorld');if world then for _,m in ipairs(world:GetChildren())do
    if m:IsA('Model')and m:GetAttribute('DisplayCF')and not m:GetAttribute('Carried')then m:PivotTo(m:GetAttribute('DisplayCF'))end
   end end end
   render()
  end);reducedButton.Name='ReducedEffects'
  text(list,'Reduces idle animation and decorative flashes. Important ability warnings stay visible. Changes apply immediately on this device.',UDim2.fromOffset(2,60),UDim2.new(1,-12,0,75),14,colors.muted)
  button(list,'OPEN CONTROLS & HELP',UDim2.fromOffset(0,145),UDim2.new(1,-8,0,42),function()show('Help')end)
  text(list,'Menus share one active window. Use Back, × or controller B to return to play. Movement and jump controls remain available on touch devices.',UDim2.fromOffset(2,200),UDim2.new(1,-12,0,90),13,colors.muted)
  if state.studio then button(list,'STUDIO: $2.5M test cash',UDim2.fromOffset(0,300),UDim2.new(1,-8,0,44),function()action:FireServer('testCash')end)end
 elseif mode=='Inventory'or mode=='Index'then
  local narrow=panel.AbsoluteSize.X<520
  local topSpace=mode=='Inventory'and 76 or 0
  if mode=='Inventory'then
   local multiplier=state.incomeMultiplier or(1+(state.level or 0)*.05)
   local cost=state.upgradeCost or state.upgrade
   text(content,'LEVEL '..state.level..' · '..state.capacity..' SLOTS\n'..math.floor(multiplier*100+.5)..'% income · '..(state.protectionDuration or 30)..'s protection',UDim2.fromOffset(0,1),UDim2.new(1,-153,0,47),11,colors.gold)
   local canUpgrade=type(cost)=='number'and cost<math.huge and state.cash>=cost and not state.carry and not state.pending
   local b=button(content,type(cost)=='number'and('UPGRADE · $'..compact(cost))or'UPGRADE AT BASE',UDim2.new(1,-148,0,1),UDim2.fromOffset(148,42),function()if canUpgrade then action:FireServer('upgrade')else message('Use your base upgrade console with enough money and no item in transit.')end end)
   b.Name='UpgradeBase';b.TextSize=11;b.TextTransparency=canUpgrade and 0 or .35
   text(content,state.secondFloor and'Second floor unlocked · 8 slots per floor'or'Level 5 unlocks your second floor · upgrade at your base console',UDim2.fromOffset(0,49),UDim2.new(1,-8,0,23),10,colors.muted)
  end
  local entries={};if mode=='Index'then for _,d in ipairs(catalog.Items)do entries[#entries+1]={kind=d.id}end else entries=state.inventory end
  local showList=not narrow or selected==nil
  local chosen
  for _,entry in ipairs(entries)do if selected==(entry.uid or entry.kind)then chosen=entry;break end end
  if narrow and selected and not chosen then selected=nil;confirmSale=nil;showList=true end
  if not narrow then chosen=chosen or entries[1]end
  if showList then
   local listWidth=narrow and 1 or .45
   local search=Instance.new('TextBox');search.Name='RelicSearch';search.PlaceholderText='Search name, rarity or ID';search.Text=searchQuery;search.ClearTextOnFocus=false;search.TextSize=12;search.Font=Enum.Font.Gotham;search.TextColor3=colors.ink;search.PlaceholderColor3=colors.muted;search.BackgroundColor3=colors.bg;search.BorderSizePixel=0;search.Position=UDim2.fromOffset(0,topSpace);search.Size=UDim2.new(listWidth,narrow and 0 or-6,0,36);search.Parent=content;corner(search)
   local list=scrolling(content);list.Name='RelicList';list.Position=UDim2.fromOffset(0,topSpace+43);list.Size=UDim2.new(listWidth,narrow and 0 or-6,1,-topSpace-43)
   local listLayout=Instance.new('UIListLayout');listLayout.Padding=UDim.new(0,6);listLayout.SortOrder=Enum.SortOrder.LayoutOrder;listLayout.Parent=list
   local rows={}
   for index,entry in ipairs(entries)do
    local d=catalog.ById[entry.kind];local key=entry.uid or entry.kind
    local rowText=(entry.uid and state.equipped==entry.uid and'★ 'or'')..d.name..'\n'..d.rarity
    if entry.carried then rowText..=' · IN TRANSIT'end
    if mode=='Index'then rowText..=state.seen[d.id]and' · FOUND'or' · NEW'end
    local b=button(list,rowText,UDim2.new(),UDim2.new(1,-7,0,62),function()selected=key;confirmSale=nil;render()end);b.Name='Select_'..key;b.LayoutOrder=index;b.TextSize=12;b.TextWrapped=true
    local tc=catalog.Colors[d.tier];local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(tc[1],tc[2],tc[3]);stroke.Transparency=.25;stroke.Thickness=selected==key and 2 or .7;stroke.Parent=b
    rows[#rows+1]={button=b,search=string.lower(d.name..' '..d.id..' '..d.rarity)}
   end
   local empty=text(list,mode=='Index'and'No matching relics.'or'Your vault is empty. Buy an item on the conveyor.',UDim2.new(),UDim2.new(1,-10,0,62),13,colors.muted)
   local function filter()
    searchQuery=search.Text;local query=string.lower(searchQuery);local matches=0
    for _,row in ipairs(rows)do row.button.Visible=query==''or string.find(row.search,query,1,true)~=nil;if row.button.Visible then matches+=1 end end
    empty.Visible=matches==0
   end
   search:GetPropertyChangedSignal('Text'):Connect(filter);filter()
  end
  if chosen then
   local detail=scrolling(content);detail.Name='RelicDetails';detail.Position=narrow and UDim2.fromOffset(0,topSpace)or UDim2.new(.45,6,0,topSpace);detail.Size=narrow and UDim2.new(1,0,1,-topSpace)or UDim2.new(.55,-6,1,-topSpace)
   local d=catalog.ById[chosen.kind];preview(d,detail)
   text(detail,d.name,UDim2.fromOffset(1,158),UDim2.new(1,-8,0,44),16,colors.gold)
   text(detail,d.rarity..' · $'..compact(d.price)..'\nBase income +$'..compact(d.income)..'/s',UDim2.fromOffset(1,205),UDim2.new(1,-8,0,52),13)
   if mode=='Inventory'then
    local disabled=chosen.carried==true
    button(detail,disabled and'IN TRANSIT'or'EQUIP',UDim2.fromOffset(0,266),UDim2.new(1,-8,0,42),function()if not disabled then action:FireServer('equip',chosen.uid)end end)
    local sell=button(detail,confirmSale==chosen.uid and('CONFIRM SELL · $'..compact(math.floor(d.price*.5)))or'SELL FOR 50%',UDim2.fromOffset(0,315),UDim2.new(1,-8,0,42),function()
     if disabled then return end
     if confirmSale==chosen.uid then action:FireServer('sell',chosen.uid);confirmSale=nil else confirmSale=chosen.uid;render()end
    end);sell.Name='SellRelic';sell.TextTransparency=disabled and .5 or 0
   elseif state.studio then button(detail,'STUDIO: spawn conveyor offer',UDim2.fromOffset(0,266),UDim2.new(1,-8,0,42),function()action:FireServer('testMarket',d.id)end)end
  end
 end
end
CAS:BindAction('OPItemPower',function(_,input)
 if input==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox()and not playerGui:GetAttribute('OPDeveloperFlight')and not playerGui:GetAttribute('OPActiveMenu')then action:FireServer('power')end
 return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonR2)
CAS:BindAction('OPItemInventory',function(_,input)
 if input==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox()then show('Inventory')end
 return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.I,Enum.KeyCode.ButtonY)
CAS:BindAction('OPItemCloseMenu',function(_,input)
 if input==Enum.UserInputState.Begin and panel.Visible and not UIS:GetFocusedTextBox()then closeMenu();return Enum.ContextActionResult.Sink end
 return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.ButtonB)
local first=true
update.OnClientEvent:Connect(function(s)
 if s.message then message(s.message);return end
 if s.cash==nil then return end
 state=s;cash.Text='$'..compact(s.cash)..'  LV '..s.level
 income.Text='+$'..compact(s.income)..'/s  ·  '..(s.occupied or #s.inventory)..'/'..s.capacity..' slots'
 bank.Text='$'..compact(s.bank)..' ready'..((s.held or 0)>0 and(' · $'..compact(s.held)..' held')or'')
 protect.Text=s.lock>0 and('PROTECTED\n'..s.lock..'s')or('OPEN\nLock '..s.lockReady..'s')
 protect.TextColor3=s.lock>0 and colors.cyan or colors.gold
 local cost=s.upgradeCost or s.upgrade or math.huge
 local keys={tostring(s.equipped),tostring(s.capacity),tostring(s.level),tostring(s.cash>=cost),tostring(s.carry),tostring(s.pending)}
 for _,it in ipairs(s.inventory)do keys[#keys+1]=it.uid..tostring(it.carried)end
 local key=table.concat(keys,':');if panel.Visible and key~=inventoryKey then render()end;inventoryKey=key
 if first then first=false;message('Hold E for 0.35s to buy. Carry your item across your base’s green line. Powers opens your starter choice.')end
end)
-- Developer visuals are a separate bounded cosmetic module; the server owns every hit.
task.spawn(function()
 local developerEffects=net:WaitForChild('DeveloperEffects',30)
 if developerEffects then require(developerEffects).start(net,player)end
end)
-- Compact local presentation; hit validation and shield consumption remain server-owned.
local function fxPart(name,color)
 local p=Instance.new('Part');p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p.Material=Enum.Material.Neon;p.Color=color;p.CastShadow=false;return p
end
local function fxLine(name,a,b,width,color,life)
 local delta=b-a;if delta.Magnitude<.01 then return end
 local p=fxPart(name,color);p.Size=Vector3.new(width,width,delta.Magnitude);p.CFrame=CFrame.lookAt((a+b)*.5,b);p.Parent=workspace
 Tween:Create(p,TweenInfo.new(life),{Transparency=1}):Play();Debris:AddItem(p,life)
end
net.FX.OnClientEvent:Connect(function(kind,origin,radius,itemName,windup,warningColor,userId,duration,direction)
 if kind=='developerRoyalSeal' then return end
 local color=typeof(warningColor)=='Color3' and warningColor or Color3.fromRGB(71,219,241)
 local floor=origin-Vector3.new(0,2.7,0)
 local function ring(r,life)
  local segments=reduced and 16 or 28
  for i=0,segments-1 do
   local a=i*math.pi*2/segments;local b=(i+1)*math.pi*2/segments
   fxLine('PowerArea',floor+Vector3.new(math.cos(a)*r,.08,math.sin(a)*r),floor+Vector3.new(math.cos(b)*r,.08,math.sin(b)*r),.12,color,life)
  end
 end
 if kind=='shield' then
  local owner=Players:GetPlayerByUserId(userId);local character=owner and owner.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
  if not root then return end
  local shield=fxPart('OneHitForceField',color);shield.Shape=Enum.PartType.Ball;shield.Size=Vector3.new(6,7,6);shield.Material=Enum.Material.ForceField;shield.Transparency=.62;shield.CFrame=root.CFrame;shield.Parent=workspace
  local endTime=os.clock()+(duration or 3);local connection
  connection=Run.RenderStepped:Connect(function()
   if not root.Parent or os.clock()>=endTime or not owner:GetAttribute('OPShieldUntil') then connection:Disconnect();shield:Destroy();return end
   shield.CFrame=root.CFrame
  end)
  Debris:AddItem(shield,(duration or 3)+.1);return
 end
 if kind=='dash' then
  local dir=direction or Vector3.zAxis
  for i=-1,1 do fxLine('DashStreak',origin+Vector3.new(0,i*.6,0),origin+dir*7+Vector3.new(0,i*.6,0),.1,color,.3) end
  return
 end
 if windup and windup>0 then
  ring(radius,windup+.1)
  if kind=='lightning' then
   fxLine('TargetCrossX',floor+Vector3.new(-radius,0,0),floor+Vector3.new(radius,0,0),.16,color,windup)
   fxLine('TargetCrossZ',floor+Vector3.new(0,0,-radius),floor+Vector3.new(0,0,radius),.16,color,windup)
  elseif kind=='tag' and direction then
   fxLine('TagDirection',floor,floor+direction*7,.22,color,windup+.15)
  end
  return
 end
 if kind=='lightning' then
  local prev=origin+Vector3.new(0,22,0)
  for i=1,7 do local nextPoint=origin+Vector3.new(i%2==0 and .7 or -.7,22-i*22/7,0);fxLine('LightningSegment',prev,nextPoint,.23,color,.24);prev=nextPoint end
  ring(radius,.45)
 elseif kind=='slow' then ring(radius,duration or 2.5)
 elseif kind=='repulse' or kind=='gravity' or kind=='slam' then
  ring(radius,.5);for i=0,7 do local a=i*math.pi/4;local dir=Vector3.new(math.cos(a),0,math.sin(a))
   local inside=floor+dir*1.4;local outside=floor+dir*radius
   fxLine(kind=='gravity' and 'PullRay' or 'BlastRay',inside,outside,.12,color,.4)
  end
 elseif kind=='shieldBreak' or kind=='hit' or kind=='tag' then
  for i=0,5 do local a=i*math.pi/3;fxLine('HitSpark',origin,origin+Vector3.new(math.cos(a),math.sin(a),0)*1.6,.09,color,.22) end
 end
end)
local world=workspace:WaitForChild('OPItemWorld'); local animated={}
task.spawn(function()
 local scene=world:WaitForChild('EnhancedScene',30)
 local renderer=require(net:WaitForChild('PaintingRenderer'))
 for _,name in ipairs({'ForceOfDespairPainting','ExodiaPainting','EgyptianGodsPainting'}) do
  local painting=scene and scene:WaitForChild(name,30)
  local board=painting and painting:WaitForChild('ArtworkCanvas',30)
  if board then renderer.mount(board,name) end
 end
end)
local function add(m) if m:IsA('Model') and m:GetAttribute('Kind') then animated[m]=true end end
for _,m in ipairs(world:GetChildren()) do add(m) end
world.ChildAdded:Connect(add); world.ChildRemoved:Connect(function(m) animated[m]=nil end)
-- Cache fitted shells once, including new upper-storey walls. Floors and stairs stay solid and visible.
local roofGroups,registeredRoofs={},{}
local function registerRoof(roof)
 if registeredRoofs[roof]then return end
 if not roof:IsA('Model')or not roof:GetAttribute('BaseCF')then return end
 local parts={}
 for _,part in ipairs(roof:GetDescendants())do if part:IsA('BasePart')then parts[#parts+1]=part end end
 local record={model=roof,parts=parts,faded=false};registeredRoofs[roof]=record;roofGroups[#roofGroups+1]=record
 roof.DescendantAdded:Connect(function(part)
  if part:IsA('BasePart')then parts[#parts+1]=part;part.LocalTransparencyModifier=record.faded and .9 or 0 end
 end)
end
local aesthetics=world:WaitForChild('Aesthetics')
for _,roof in ipairs(aesthetics:WaitForChild('VaultRoofs'):GetChildren())do registerRoof(roof)end
for _,object in ipairs(world:GetDescendants())do if object:IsA('Model')and(object.Name=='UpperFloorShell'or object:GetAttribute('OcclusionShell'))then registerRoof(object)end end
world.DescendantAdded:Connect(function(object)
 if object:IsA('Model')and(object.Name=='UpperFloorShell'or object:GetAttribute('OcclusionShell'))then registerRoof(object)end
end)
local roofAcc=0
local function updateRoofs(dt)
 roofAcc+=dt;if roofAcc<.1 then return end;roofAcc=0
 local camera=workspace.CurrentCamera;local character=player.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 if not camera or not root then return end
 for index=#roofGroups,1,-1 do
  local roof=roofGroups[index]
  if not roof.model.Parent then registeredRoofs[roof.model]=nil;table.remove(roofGroups,index)
  else
   local cf=roof.model:GetAttribute('BaseCF');local height=roof.model:GetAttribute('RoofHeight')or 17.5
   local target=cf:PointToObjectSpace(root.Position);local eye=cf:PointToObjectSpace(camera.CFrame.Position)
   local inside=math.abs(target.X)<=25 and math.abs(target.Z)<=25 and target.Y>=-2 and target.Y<height+1.5
   local occluded=false;local dy=target.Y-eye.Y
   if math.abs(dy)>.001 then
    local t=(height-eye.Y)/dy
    if t>=0 and t<=1 then local crossing=eye:Lerp(target,t);occluded=math.abs(crossing.X)<=25 and math.abs(crossing.Z)<=25 end
   end
   local fade=inside or occluded
   if fade~=roof.faded then
    roof.faded=fade
    for _,part in ipairs(roof.parts)do if part.Parent then part.LocalTransparencyModifier=fade and .9 or 0 end end
   end
  end
 end
end
local elapsed=0
Run.RenderStepped:Connect(function(dt)
 updateRoofs(dt)
 -- Follow replicated characters directly at the render rate. Item snapshots
 -- provide a server fallback, rather than driving the overhead animation.
 for m in pairs(animated) do
  if m:GetAttribute('Carried') then
   local id=m:GetAttribute('CarrierUserId')
   local carrier=type(id)=='number' and Players:GetPlayerByUserId(id)
   local character=carrier and carrier.Character
   local root=character and character:FindFirstChild('HumanoidRootPart')
   if root then m:PivotTo(CFrame.new(root.Position+Vector3.new(0,m:GetAttribute('CarryVisualOffset') or 3.2,0))) end
  end
 end
 elapsed=elapsed+dt; if elapsed<1/30 then return end; elapsed=0
 local now=os.clock(); local camera=workspace.CurrentCamera
 local serverNow=workspace:GetServerTimeNow()
 for m in pairs(animated) do
  local cf=m:GetAttribute('DisplayCF')
  local born=m:GetAttribute('ConveyorBorn')
  if born and not m:GetAttribute('Carried') then
   local x=math.max(m:GetAttribute('ConveyorEndX'),m:GetAttribute('ConveyorStartX')-m:GetAttribute('ConveyorSpeed')*(serverNow-born))
   m:PivotTo(CFrame.new(x,m:GetAttribute('ConveyorY'),0))
  elseif not reduced and cf and not m:GetAttribute('Carried') and camera and (camera.CFrame.Position-cf.Position).Magnitude<110 then
   m:PivotTo(cf*CFrame.new(0,math.sin(now*1.5)*.1,0)*CFrame.Angles(0,now*.3,0))
  end
 end
end)
action:FireServer('ready')

-- Deterministic decorative Ho-Oh flight. Never moves characters or gameplay items.
task.spawn(function()
 local scene=world:WaitForChild('EnhancedScene',30);local bird=scene and scene:WaitForChild('HoOhFlight',30)
 if not bird or not bird:IsA('Model') then return end
 local base=bird:GetPivot();local localFrames={};local wingParts={}
 for _,p in ipairs(bird:GetDescendants()) do if p:IsA('BasePart') and p~=bird.PrimaryPart then
  localFrames[p]=base:ToObjectSpace(p.CFrame)
  local side=p.Name:match('^Wing%w+_(-?1)_');if side then wingParts[p]=tonumber(side) end
 end end
 local flightOrigin=bird:GetAttribute('FlightOrigin');local period=bird:GetAttribute('FlightPeriod') or 28
 Run.RenderStepped:Connect(function()
  if not bird.Parent then return end
  local t=(workspace:GetServerTimeNow()%period)/period
  local envelope=math.sin(math.pi*t)^2
  local angle=t*math.pi*4
  local pos=flightOrigin+Vector3.new(math.sin(angle)*24*envelope,math.sin(math.pi*t)*12,math.cos(angle)*20*envelope)
  local nextT=t+.001;local e=math.sin(math.pi*nextT)^2
  local nextPos=flightOrigin+Vector3.new(math.sin(nextT*math.pi*4)*24*e,math.sin(math.pi*nextT)*12,math.cos(nextT*math.pi*4)*20*e)
  local pose=CFrame.lookAt(pos,nextPos);bird:PivotTo(pose)
  local flap=math.sin(workspace:GetServerTimeNow()*7)*.42
  for p,side in pairs(wingParts) do if p.Parent then
   local hinge=CFrame.new(side*1.4,.6,0);p.CFrame=pose*hinge*CFrame.Angles(0,0,side*flap)*hinge:Inverse()*localFrames[p]
  end end
 end)
end)


-- Slifer occupies its former statue site; cached native parts move on this client.
-- Reduced effects restores the original pose. No server replication/physics changes.
task.spawn(function()
 local scene=world:WaitForChild('EnhancedScene',30)
 local serpent=scene and scene:WaitForChild('SliferAnimatedLandmark',30)
 if not serpent or not serpent:IsA('Model') then return end
 local origin=serpent:GetAttribute('OrbitOrigin');local period=serpent:GetAttribute('OrbitPeriod') or 36
 if typeof(origin)~='Vector3' or type(period)~='number' or period<=0 then return end
 local rest=CFrame.new(origin);local records={}
 for _,part in ipairs(serpent:GetDescendants()) do if part:IsA('BasePart') then
  records[#records+1]={part=part,cf=rest:ToObjectSpace(part.CFrame),group=part:GetAttribute('SliferMotionGroup'),hinge=part:GetAttribute('SliferHinge')}
 end end
 local elapsed=0;local resting=false;local connection;local ancestry
 local function disconnect()
  if connection then connection:Disconnect();connection=nil end
  if ancestry then ancestry:Disconnect();ancestry=nil end
 end
 local function restore()
  for _,r in ipairs(records) do if r.part.Parent then r.part.CFrame=rest*r.cf end end
 end
 connection=Run.RenderStepped:Connect(function(dt)
  if not serpent.Parent or not scene.Parent then disconnect();return end
  elapsed=elapsed+dt;if elapsed<1/30 then return end;elapsed=0
  if reduced then
   if not resting then restore();resting=true end
   return
  end
  resting=false
  local camera=workspace.CurrentCamera
  if not camera or (camera.CFrame.Position-origin).Magnitude>460 then return end
  local phase=(workspace:GetServerTimeNow()%period)/period*math.pi*2
  local pose=rest*CFrame.new(0,math.sin(phase*2)*.55,0)*CFrame.Angles(0,math.sin(phase)*.055,0)
  local motions={}
  for _,r in ipairs(records) do if r.part.Parent then
   local group=r.group;local motion=group and motions[group]
   if group and not motion then
    local segment=tonumber(group:match('^Body(%d+)$'))
    local wing=tonumber(group:match('^Wing(-?1)$'))
    if segment then
     motion=CFrame.new(math.sin(phase*3-segment*.22)*.07,math.sin(phase*2-segment*.2)*.08,0)
    elseif wing and r.hinge then
     motion=r.hinge*CFrame.Angles(0,0,wing*math.sin(phase*6)*.13)*r.hinge:Inverse()
    elseif group=='Head' and r.hinge then
     motion=r.hinge*CFrame.Angles(math.sin(phase*2)*.016,math.sin(phase)*.018,0)*r.hinge:Inverse()
    else motion=CFrame.new() end
    motions[group]=motion
   end
   r.part.CFrame=pose*(motion or CFrame.new())*r.cf
  end end
 end)
 ancestry=serpent.AncestryChanged:Connect(function()
  if not serpent:IsDescendantOf(world) then disconnect() end
 end)
end)
