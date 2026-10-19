local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local CAS=game:GetService('ContextActionService')
local UIS=game:GetService('UserInputService')
local GS=game:GetService('GuiService')
local Tween=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local player=Players.LocalPlayer
local net=RS:WaitForChild('OPItemNet')
local action=net:WaitForChild('Action'); local update=net:WaitForChild('Update')
local catalog=require(net:WaitForChild('Catalog')); local templates=net:WaitForChild('Models')
local gui=script.Parent; assert(gui:IsA('ScreenGui'),'Client must live inside persistent HUD')
gui.ResetOnSpawn=false; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local colors={bg=Color3.fromRGB(14,20,34),panel=Color3.fromRGB(25,34,53),ink=Color3.fromRGB(235,243,255),muted=Color3.fromRGB(153,172,198),cyan=Color3.fromRGB(77,224,230),gold=Color3.fromRGB(245,192,67)}
local function corner(x) Instance.new('UICorner',x).CornerRadius=UDim.new(0,9) end
local function frame(parent,name,pos,size)
 local f=Instance.new('Frame'); f.Name=name; f.Position=pos; f.Size=size; f.BackgroundColor3=colors.panel; f.BorderSizePixel=0; f.Parent=parent; corner(f); return f
end
local function text(parent,str,pos,size,fontSize,color)
 local t=Instance.new('TextLabel'); t.Position=pos; t.Size=size; t.Text=str; t.TextColor3=color or colors.ink
 t.Font=Enum.Font.GothamMedium; t.TextSize=fontSize or 15; t.BackgroundTransparency=1; t.TextWrapped=true
 t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=parent; return t
end
local function button(parent,str,pos,size,cb)
 local b=Instance.new('TextButton'); b.Position=pos; b.Size=size; b.Text=str; b.Font=Enum.Font.GothamBold; b.TextSize=14
 b.TextColor3=colors.ink; b.BackgroundColor3=Color3.fromRGB(42,59,83); b.BorderSizePixel=0; b.Selectable=true; b.Parent=parent; corner(b)
 b.Activated:Connect(cb); return b
end
local screen=frame(gui,'Canvas',UDim2.new(),UDim2.fromScale(1,1)); screen.BackgroundTransparency=1
local top=frame(screen,'Status',UDim2.fromOffset(10,6),UDim2.new(1,-20,0,70))
text(top,'STEAL AN OP ITEM  /  '..#catalog.Items..' RELICS',UDim2.fromOffset(10,2),UDim2.new(1,-20,0,19),14,colors.gold)
text(top,'SESSION ALPHA • PROGRESS RESETS ON LEAVE',UDim2.fromOffset(10,21),UDim2.new(1,-20,0,13),10,colors.muted)
local cash=text(top,'Loading vault…',UDim2.fromOffset(10,35),UDim2.new(.5,-10,0,18),12,colors.cyan)
local protect=text(top,'',UDim2.new(.5,0,0,35),UDim2.new(.5,-10,0,18),12)
local income=text(top,'',UDim2.fromOffset(10,53),UDim2.new(1,-20,0,15),11,colors.muted)
local notice=frame(screen,'Notice',UDim2.new(.5,0,0,77),UDim2.new(.92,0,0,56)); notice.AnchorPoint=Vector2.new(.5,0); notice.Visible=false; notice.ZIndex=20
local noticeText=text(notice,'',UDim2.fromOffset(10,2),UDim2.new(1,-20,1,-4),15); noticeText.ZIndex=21
local noticeId=0
local function message(msg)
 noticeId=noticeId+1; local id=noticeId; noticeText.Text=msg; notice.Visible=true
 task.delay(4,function() if noticeId==id then notice.Visible=false end end)
end
local panel=frame(screen,'Menu',UDim2.new(.5,0,.5,20),UDim2.new(1,-20,1,-195)); panel.AnchorPoint=Vector2.new(.5,.5); panel.Visible=false
local sizeLimit=Instance.new('UISizeConstraint'); sizeLimit.MaxSize=Vector2.new(820,510); sizeLimit.Parent=panel
local title=text(panel,'',UDim2.fromOffset(12,6),UDim2.new(1,-70,0,32),21,colors.gold)
local close=button(panel,'X',UDim2.new(1,-49,0,5),UDim2.fromOffset(44,36),function() panel.Visible=false; GS.SelectedObject=nil; local touch=player.PlayerGui:FindFirstChild('TouchGui'); if touch then touch.Enabled=true end end)
local content=frame(panel,'Content',UDim2.fromOffset(10,48),UDim2.new(1,-20,1,-58)); content.BackgroundTransparency=1
local bottom=frame(screen,'Navigation',UDim2.new(0,10,1,-49),UDim2.new(1,-20,0,41))
task.spawn(function()
 local touch=player.PlayerGui:WaitForChild('TouchGui',10)
 if not touch then return end
 local function syncTouch() local enabled=not panel.Visible; if touch.Enabled~=enabled then touch.Enabled=enabled end end
 touch:GetPropertyChangedSignal('Enabled'):Connect(syncTouch)
 panel:GetPropertyChangedSignal('Visible'):Connect(syncTouch)
 syncTouch()
end)

-- Keep touch navigation clear of Roblox's movement and jump controls.
local function layout()
 local camera=workspace.CurrentCamera; if not camera then return end
 local compact=UIS.TouchEnabled or camera.ViewportSize.Y<480
 if compact then
  notice.Position=UDim2.new(1,-10,0,178);notice.AnchorPoint=Vector2.new(1,0);notice.Size=UDim2.fromOffset(math.min(310,math.max(140,camera.ViewportSize.X*.32)),42)
  bottom.Position=UDim2.fromOffset(10,77)
  bottom.Size=UDim2.new(1,-20,0,46)
  panel.AnchorPoint=Vector2.new(.5,0); panel.Position=UDim2.new(.5,0,0,124)
  panel.Size=UDim2.new(1,-20,1,-134)
 else
  notice.Position=UDim2.new(1,-10,0,77);notice.AnchorPoint=Vector2.new(1,0);notice.Size=UDim2.fromOffset(math.min(310,math.max(140,camera.ViewportSize.X*.32)),52)
  bottom.Position=UDim2.new(0,10,1,-49); bottom.Size=UDim2.new(1,-20,0,41)
  panel.AnchorPoint=Vector2.new(.5,.5); panel.Position=UDim2.new(.5,0,.5,20)
  panel.Size=UDim2.new(1,-20,1,-195)
 end
end
layout()
workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout)
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
 layout(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout) end
end)
local state,selected,confirmSale=nil,nil,nil
local mode='Inventory'; local reduced=false; local render; local inventoryKey=''
local function show(which)
 mode=which; selected=nil; confirmSale=nil; panel.Visible=true; render()
 local touch=player.PlayerGui:FindFirstChild('TouchGui'); if touch then touch.Enabled=false end
 if UIS.GamepadEnabled then GS.SelectedObject=close end
end
local labels={'Inventory','Index / '..#catalog.Items,'Help','Settings'}
for i,label in ipairs(labels) do button(bottom,label,UDim2.new((i-1)*.2,4,0,1),UDim2.new(.2,-8,1,-2),function() show(i==2 and 'Index' or (i==3 and 'Help' or label)) end) end
local ability=button(bottom,'POWER',UDim2.new(.8,4,0,1),UDim2.new(.2,-8,1,-2),function() action:FireServer('power') end)
local function scrolling(parent)
 local f=Instance.new('ScrollingFrame'); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.ScrollBarThickness=5
 f.AutomaticCanvasSize=Enum.AutomaticSize.Y; f.CanvasSize=UDim2.new(); f.Parent=parent
 return f
end
local function preview(d,parent)
 local vp=Instance.new('ViewportFrame'); vp.Size=UDim2.new(1,0,0,130); vp.BackgroundColor3=colors.bg; vp.BorderSizePixel=0; vp.Ambient=Color3.fromRGB(205,205,225); vp.LightColor=Color3.new(1,1,1); vp.Parent=parent; corner(vp)
 local camera=Instance.new('Camera'); camera.Parent=vp; vp.CurrentCamera=camera
 local template=templates:FindFirstChild(d.id)
 if template then
  local model=template:Clone(); model.Parent=vp; model:PivotTo(CFrame.Angles(0,.35,0))
  local cf,size=model:GetBoundingBox(); local center=cf.Position
  local radius=math.max(size.X,size.Y,size.Z)*.5
  local aspect=math.max(.45,parent.AbsoluteSize.X/130)
  local distance=radius/math.tan(math.rad(16))*math.max(1,1/aspect)+1
  camera.FieldOfView=32; camera.CFrame=CFrame.lookAt(center+Vector3.new(.5,.25,1).Unit*distance,center)
 end
end
render=function()
 if not state then return end
 local hadFocus=GS.SelectedObject and GS.SelectedObject:IsDescendantOf(content)
 for _,c in ipairs(content:GetChildren()) do c:Destroy() end
 if hadFocus then GS.SelectedObject=close end
 title.Text=mode
 if mode=='Help' then
  local list=scrolling(content); list.Size=UDim2.fromScale(1,1)
  local t=text(list,'1  HOLD E / controller X / touch for 0.35 seconds to buy or steal. Follow the conveyor item while holding.\n\n2  CARRY the item across the wide green line at your base entrance to complete delivery. Funds and a slot are reserved until delivery. Crossing also activates 30 seconds of base protection when its recharge is ready.\n\n3  TAG carriers to knock loot loose. Interrupted purchases return to their pickup position and refund escrow. Stolen loot returns to its owner.\n\n4  Buy Battles reserve bids and space. Stay near the offer. Leaving, dying or being hit removes your bid.\n\n5  POWERS: permanent Tag plus a free starter. Open POWERS for five ranks and your loadout. Keys 1/2/3 use slots; Q/controller R2 uses slot 2; controller L2 uses Tag. All powers are disabled while carrying or bidding.\n\n6  Eight total slots include incoming deliveries. Deposit five distinct Exodia pieces for one tracked completion reward.\n\nSession alpha: progress resets on leaving.',UDim2.fromOffset(4,0),UDim2.new(1,-15,0,0),16)
  t.AutomaticSize=Enum.AutomaticSize.Y
 elseif mode=='Settings' then
  local list=scrolling(content); list.Size=UDim2.fromScale(1,1)
  button(list,reduced and 'Reduced effects: ON' or 'Reduced effects: OFF',UDim2.fromOffset(0,4),UDim2.new(1,-8,0,48),function()
   reduced=not reduced
   if reduced then
    local world=workspace:FindFirstChild('OPItemWorld')
    if world then for _,m in ipairs(world:GetChildren()) do
     if m:IsA('Model') and m:GetAttribute('DisplayCF') and not m:GetAttribute('Carried') then m:PivotTo(m:GetAttribute('DisplayCF')) end
    end end
   end
   render()
  end)
  text(list,'Stops idle motion and decorative flashes. Ability warning fields remain visible for fair counterplay. No audio is included.',UDim2.fromOffset(0,65),UDim2.new(1,-10,0,110),16,colors.muted)
  if state.studio then button(list,'STUDIO: $2.5M session test cash',UDim2.fromOffset(0,190),UDim2.new(1,-8,0,48),function() action:FireServer('testCash') end) end
 elseif mode=='Inventory' or mode=='Index' then
  local list=scrolling(content); list.Size=UDim2.new(.45,-6,1,0)
  local layout=Instance.new('UIListLayout'); layout.Padding=UDim.new(0,6); layout.Parent=list
  local entries={}
  if mode=='Index' then for _,d in ipairs(catalog.Items) do entries[#entries+1]={kind=d.id} end else entries=state.inventory end
  local chosen
  for _,entry in ipairs(entries) do
   local d=catalog.ById[entry.kind]; local key=entry.uid or entry.kind
   if selected==key then chosen=entry end
   local label=(entry.uid and state.equipped==entry.uid and '★ ' or '')..d.name..'\n'..d.rarity
   if entry.carried then label=label..' / IN TRANSIT' end
   if mode=='Index' then label=label..(state.seen[d.id] and ' / FOUND' or ' / NEW') end
   local b=button(list,label,UDim2.new(),UDim2.new(1,-8,0,82),function() selected=key; confirmSale=nil; render() end)
   b.TextSize=13
   local tc=catalog.Colors[d.tier]; local stroke=Instance.new('UIStroke'); stroke.Color=Color3.fromRGB(tc[1],tc[2],tc[3]); stroke.Thickness=selected==key and 2 or .6; stroke.Parent=b
  end
  chosen=chosen or entries[1]
  local detail=scrolling(content); detail.Position=UDim2.new(.45,6,0,0); detail.Size=UDim2.new(.55,-6,1,0)
  if chosen then
   local d=catalog.ById[chosen.kind]; selected=chosen.uid or chosen.kind; preview(d,detail)
   text(detail,d.name,UDim2.fromOffset(0,137),UDim2.new(1,-8,0,56),17,colors.gold)
   text(detail,d.rarity..' • $'..d.price..'\n+$'..d.income..'/s\n'..'Active powers: use Power Shop / Loadout',UDim2.fromOffset(0,195),UDim2.new(1,-8,0,100),14)
   if mode=='Inventory' then
    button(detail,'EQUIP',UDim2.fromOffset(0,302),UDim2.new(1,-8,0,44),function() action:FireServer('equip',chosen.uid) end)
    button(detail,confirmSale==chosen.uid and 'CONFIRM $'..math.floor(d.price*.5) or 'SELL FOR 50%',UDim2.fromOffset(0,353),UDim2.new(1,-8,0,44),function()
     if confirmSale==chosen.uid then action:FireServer('sell',chosen.uid); confirmSale=nil else confirmSale=chosen.uid; render() end
    end)
   elseif state.studio then button(detail,'STUDIO: spawn conveyor offer',UDim2.fromOffset(0,302),UDim2.new(1,-8,0,50),function() action:FireServer('testMarket',d.id) end) end
  else text(detail,'Vault empty. Buy a collectible at the market.',UDim2.new(),UDim2.new(1,-8,0,120),16) end
 end
end
CAS:BindAction('OPItemPower',function(_,input)
 if input==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then action:FireServer('power') end
 return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonR2)
CAS:BindAction('OPItemInventory',function(_,input)
 if input==Enum.UserInputState.Begin then show('Inventory') end
 return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.I,Enum.KeyCode.ButtonY)
local first=true
update.OnClientEvent:Connect(function(s)
 if s.message then message(s.message); return end
 state=s; cash.Text='$'..s.cash..' • '..s.steals..' steals'
 income.Text='+$'..s.income..'/s • $'..s.bank..' to collect • '..(s.occupied or #s.inventory)..'/'..s.capacity..' slots • $'..(s.held or 0)..' reserved'
 protect.Text=s.lock>0 and 'PROTECTED '..s.lock..'s' or 'OPEN • lock '..s.lockReady..'s'
 ability.Text=s.carry and 'CARRYING' or (s.cooldown>0 and s.cooldown..'s' or 'POWER')
 local keys={tostring(s.equipped),tostring(s.capacity)}
 for _,it in ipairs(s.inventory) do keys[#keys+1]=it.uid..tostring(it.carried) end
 local key=table.concat(keys,':'); if panel.Visible and key~=inventoryKey then render() end; inventoryKey=key
 if first then first=false; message('Choose a free Dash in POWERS. Hold E / touch for 0.35 seconds to buy; deliver across your green entrance line.') end
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
-- Eight cached roof groups; check occlusion at 10 Hz, independent of reduced FX.
local roofGroups={}
local aesthetics=world:WaitForChild('Aesthetics')
for _,roof in ipairs(aesthetics:WaitForChild('VaultRoofs'):GetChildren()) do
 local parts={}
 for _,v in ipairs(roof:GetDescendants()) do if v:IsA('BasePart') then table.insert(parts,v) end end
 roofGroups[#roofGroups+1]={cf=roof:GetAttribute('BaseCF'),parts=parts,faded=false}
end
local roofAcc=0
local function updateRoofs(dt)
 roofAcc=roofAcc+dt; if roofAcc<.1 then return end; roofAcc=0
 local camera=workspace.CurrentCamera; local character=player.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 if not camera or not root then return end
 for _,roof in ipairs(roofGroups) do
  local target=roof.cf:PointToObjectSpace(root.Position)
  local eye=roof.cf:PointToObjectSpace(camera.CFrame.Position)
  local inside=math.abs(target.X)<=25 and math.abs(target.Z)<=25 and target.Y<19
  local occluded=false; local dy=target.Y-eye.Y
  if math.abs(dy)>.001 then
   local t=(18-eye.Y)/dy
   if t>=0 and t<=1 then
    local crossing=eye:Lerp(target,t)
    occluded=math.abs(crossing.X)<=25 and math.abs(crossing.Z)<=25
   end
  end
  local fade=inside or occluded
  if fade~=roof.faded then
   roof.faded=fade
   for _,part in ipairs(roof.parts) do part.LocalTransparencyModifier=fade and .9 or 0 end
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
