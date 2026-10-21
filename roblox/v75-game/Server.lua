-- Place the OPItemV2 folder in ServerScriptService. Disable the old prototype.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local Config=require(script.Parent.Config)
assert(not workspace:FindFirstChild('OPPrototype'),'Disable your old StealAnOPItem script, stop, then press Play again.')
assert(not RS:FindFirstChild('OPItemNet'),'Only one OPItemV2 package may run.')
local Catalog=require(script.Parent.Catalog)
local Factory=require(script.Parent.ModelFactory)
local Core=require(script.Parent.Core)
assert(Config.MaxPlayers>=1 and Config.MaxPlayers<=8 and Config.MaxPlayers%1==0,'MaxPlayers must be 1..8')
assert(Config.BaseSlots==8,'Phase 1 requires eight pedestals per base')
assert(Config.ConveyorInterval>=3 and Config.ConveyorSpeed>0 and Config.ConveyorMaxOffers>0,'Invalid conveyor configuration')
local core=Core.new(Catalog,Config)
local net=Instance.new('Folder'); net.Name='OPItemNet'; net.Parent=RS
local action=Instance.new('RemoteEvent'); action.Name='Action'; action.Parent=net
local update=Instance.new('RemoteEvent'); update.Name='Update'; update.Parent=net
local fx=Instance.new('RemoteEvent'); fx.Name='FX'; fx.Parent=net
local phaseEvent=Instance.new('RemoteEvent');phaseEvent.Name='Phase';phaseEvent.Parent=net
script.Parent.PowerCatalog:Clone().Parent=net
script.Parent.DeveloperEffects:Clone().Parent=net
script.Parent.ExpandedCatalog:Clone().Parent=net
script.Parent.Catalog:Clone().Parent=net
script.Parent.PaintingRenderer:Clone().Parent=net
for _,prefix in ipairs({'PaintingData','ExodiaPaintingData','GodsPaintingData'}) do
 for i=1,8 do local data=script.Parent:FindFirstChild(prefix..i);if data then data:Clone().Parent=net end end
end
local templates=Instance.new('Folder'); templates.Name='Models'; templates.Parent=net
for _,d in ipairs(Catalog.Items) do local m=Factory.create(d,templates); m.Name=d.id end
local world=require(script.Parent.World).build(Factory,Config)
Lighting.ClockTime=16; Lighting.Brightness=2
Lighting.Ambient=Color3.fromRGB(105,117,149); Lighting.OutdoorAmbient=Color3.fromRGB(130,140,167)
require(script.Parent.Aesthetics).applyLighting()
local runtime,visuals,offers={}, {}, {}
local admin
local phase
local rng=Random.new()
local function body(p)
 local c=p.Character; local h=c and c:FindFirstChildOfClass('Humanoid'); local r=c and c:FindFirstChild('HumanoidRootPart')
 if h and h.Health>0 and r then return r,h end
end
local function near(p,pos,dist) local r=body(p); return r and (r.Position-pos).Magnitude<=dist end
local function say(p,msg) if p and p.Parent then update:FireClient(p,{message=msg}) end end
local function los(a,b,ignore)
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 local exclude={}
 for _,p in ipairs(Players:GetPlayers()) do if p.Character then exclude[#exclude+1]=p.Character end end
 if ignore then exclude[#exclude+1]=ignore end
 params.FilterDescendantsInstances=exclude
 return workspace:Raycast(a,b-a,params)==nil
end
-- A token bucket checks all travel, including the approach to a relic.
-- Short, bounded allowances account for server-authorized dashes/knockback.
local function movementSafe(p)
 local rt=runtime[p.UserId]; local r=body(p)
 if not rt or not r then return false end
 local now=os.clock()
 if admin and admin:allowsMovement(p) then
  rt.travelPosition=r.Position;rt.travelTime=now;rt.travelCredit=5;rt.safeCF=r.CFrame;rt.blockedUntil=0
  return true
 end
 if not rt.travelPosition then
  rt.travelPosition=r.Position; rt.travelTime=now; rt.travelCredit=5; rt.safeCF=r.CFrame
 end
 local dt=math.max(0,now-rt.travelTime)
 local state=core.players[p.UserId]
 local allowedSpeed=state and state.carry and Config.CarrySpeed+5 or (admin and admin:getWalkSpeed(p,Config.WalkSpeed) or Config.WalkSpeed)+8
 local speed=now<(rt.impulseUntil or 0) and 60 or allowedSpeed
 local credit=math.min(7,(rt.travelCredit or 5)+speed*dt)
 local delta=r.Position-rt.travelPosition
 local horizontal=Vector3.new(delta.X,0,delta.Z).Magnitude
 local verticalSpeed=math.max(90,(admin and admin:getJumpPower(p,60) or 60)+30)
 local invalid=horizontal>credit or math.abs(delta.Y)>verticalSpeed*dt+10 or r.Position.Y < -5
 rt.travelTime=now
 if invalid then
  rt.blockedUntil=now+2; r.AssemblyLinearVelocity=Vector3.zero
  if rt.safeCF then r.CFrame=rt.safeCF end
  rt.travelPosition=r.Position; rt.travelCredit=0
  return false
 end
 rt.travelCredit=credit-horizontal; rt.travelPosition=r.Position; rt.safeCF=r.CFrame
 return now>=(rt.blockedUntil or 0)
end
local function allowed(p,pos,anchor)
 local rt=runtime[p.UserId]
 if not rt or not movementSafe(p) or not near(p,pos,11) or os.clock()<rt.nextAction then return false end
 local r=body(p); if not r or not los(r.Position,pos,anchor) then return false end
 rt.nextAction=os.clock()+.22; return true
end
local function prompt(anchor,title,cb)
 local q=Instance.new('ProximityPrompt'); q.ActionText=title; q.ObjectText=anchor.Name
 q.MaxActivationDistance=9; q.RequiresLineOfSight=true; q.HoldDuration=require(script.Parent.PhaseConfig).HoldSeconds; q.Parent=anchor
 q.Triggered:Connect(function(p) if q.Enabled and anchor.Parent and allowed(p,anchor.Position,anchor) then cb(p) end end)
 return q
end
local function send(p)
 local snap=core:snapshot(p.UserId,os.clock())
 if snap then snap.battles=phase and phase:battles(p) or {};snap.studio=Run:IsStudio() and admin and admin:authorized(p) or false; snap.mode='SESSION ALPHA - progress resets on leave'; update:FireClient(p,snap) end
end
local function clone(kind)
 local m=templates[kind]:Clone(); m.Parent=world.folder; return m
end
local function setDisplay(m,cf)
 m:SetAttribute('DisplayCF',cf); m:PivotTo(cf)
end
local function refresh()
 require(script.Parent.DetailedArt.UpperFloor).sync(world,core.players)
 if phase then phase:syncVisuals() end
 for id,rt in pairs(runtime) do
  local p=core.players[id]
  if p then
   if rt.base.protectionPrompt then rt.base.protectionPrompt.ActionText='Protect ('..core:protectionDuration(id)..'s)' end
   rt.cash.Value=p.cash;rt.steals.Value=p.steals;send(rt.player)
  end
 end
end
local function finish(p,success,reason)
 if phase then return phase:finish(p,success,reason) end
end
local function spawnOffer(kind) return phase:spawn(kind) end
for _,b in ipairs(world.bases) do
 prompt(b.home,'Collect earnings',function(p) if b.owner==p.UserId then local _,msg=core:collect(p.UserId); say(p,msg); refresh() end end)
 b.protectionPrompt=prompt(b.lock,'Protect ('..Config.ProtectionDuration..'s)',function(p) if b.owner==p.UserId then local _,msg=core:protect(p.UserId,os.clock()); say(p,msg); refresh() end end)
 prompt(b.upgrade,'Power shop / loadout',function(p) if b.owner==p.UserId then phaseEvent:FireClient(p,{open='powers'}) end end)
end
prompt(world.powerShop,'Power shop',function(p)phaseEvent:FireClient(p,{open='powers'})end)
local function power(p,arg) phase:cast(p,arg) end
local function join(p)
 if admin and not admin:admit(p) then return end
 local id=p.UserId; if runtime[id] then return end
 local b
 for _,candidate in ipairs(world.bases) do if not candidate.owner then b=candidate; break end end
 if not b then p:Kick('All '..Config.MaxPlayers..' vaults are occupied. Join another server.'); return end
 b.owner=id
 local stats=Instance.new('Folder'); stats.Name='leaderstats'; stats.Parent=p
 local cash=Instance.new('IntValue'); cash.Name='Cash'; cash.Parent=stats
 local steals=Instance.new('IntValue'); steals.Name='Steals'; steals.Parent=stats
 local rt={player=p,base=b,cash=cash,steals=steals,nextAction=0,nextRemote=0,shield=0,slow=0,immune=0}
 runtime[id]=rt; core:addPlayer(id,os.clock())
 if admin then admin:onJoin(p) end
 local function char(c)
  local r=c:WaitForChild('HumanoidRootPart',10); local h=c:WaitForChild('Humanoid',10)
  if not r or not h or not runtime[id] or p.Character~=c then return end
  phase:cancelPlayer(p);core:characterReset(id,os.clock());finish(p,false); rt.slow=0; rt.shield=0; c:PivotTo(b.spawn)
  rt.travelPosition=r.Position; rt.travelTime=os.clock(); rt.travelCredit=5; rt.safeCF=r.CFrame; rt.blockedUntil=0; rt.impulseUntil=0
  if admin then admin:resetCharacter(p) end
  local previousHealth=h.Health
  h.HealthChanged:Connect(function(health)
   if p.Character==c and health<previousHealth then phase:interrupt(p,false) end
   previousHealth=health
  end)
  h.Died:Connect(function() if p.Character==c then phase:cancelPlayer(p);core:characterReset(id,os.clock());if admin then admin:resetCharacter(p) end;finish(p,false,'Heist ended on respawn.') end end)
 end
 p.CharacterAdded:Connect(char); if p.Character then task.spawn(char,p.Character) end
 task.spawn(function()
  local pg=p:WaitForChild('PlayerGui',10); if not pg or not runtime[id] then return end
  if not pg:FindFirstChild('OPItemHUD') then
   local gui=Instance.new('ScreenGui'); gui.Name='OPItemHUD'; gui.ResetOnSpawn=false; gui.Parent=pg
   local client=script.Parent.Client:Clone(); client.Name='OPItemClient'; client.Enabled=false; client.Parent=gui; client.Enabled=true
  end
  if not pg:FindFirstChild('OPPhaseHUD') then
   local gui=Instance.new('ScreenGui');gui.Name='OPPhaseHUD';gui.ResetOnSpawn=false;gui.DisplayOrder=15;gui.Parent=pg
   local client=script.Parent.PhaseClient:Clone();client.Enabled=false;client.Parent=gui;client.Enabled=true
  end
 end)
 refresh()
end
phase=require(script.Parent.PhaseService).new({core=core,world=world,net=net,config=Config,catalog=Catalog,templates=templates,runtime=runtime,rng=rng,body=body,los=los,movementSafe=movementSafe,refresh=refresh,say=say,fx=fx,
 isDeveloperInvulnerable=function(p) return admin and admin:isInvulnerable(p) or false end,
})
admin=require(script.Parent.AdminService).attach(require(script.Parent.AdminConfig),{
 core=core,runtime=runtime,world=world,net=net,catalog=Catalog,body=body,templates=templates,
 refresh=refresh,spawnOffer=spawnOffer,finish=finish,say=say,
 castPower=function(p,kind,rodOrigin) return phase:cast(p,kind,rodOrigin) end,
 castDeveloperPower=function(p,rodOrigin) return require(script.Parent.DeveloperPowers).cast(phase,admin,p,rodOrigin) end,
})
Players.PlayerAdded:Connect(join)
for _,p in ipairs(Players:GetPlayers()) do join(p) end
Players.PlayerRemoving:Connect(function(p)
 if phase then phase:cancelPlayer(p) end
 if admin then admin:removePlayer(p) end
 local rt=runtime[p.UserId]; if not rt then return end
 core:removePlayer(p.UserId); rt.base.owner=nil; runtime[p.UserId]=nil; refresh()
end)
action.OnServerEvent:Connect(function(p,verb,arg)
 local rt=runtime[p.UserId]; if not rt or type(verb)~='string' or #verb>20 then return end
 if os.clock()<rt.nextRemote then return end; rt.nextRemote=os.clock()+.15
 if verb=='ready' then send(p); return end
 if not body(p) or not movementSafe(p) then return end
 if phase:handle(p,verb,arg) then return end
 if verb=='power' then power(p,arg); return end
 local ok,msg
 if verb=='equip' and type(arg)=='string' and #arg<30 then ok,msg=core:equip(p.UserId,arg)
 elseif verb=='sell' and type(arg)=='string' and #arg<30 then
  if not near(p,rt.base.home.Position,40) then say(p,'Return to your vault to sell.'); return end
  ok,msg=core:sell(p.UserId,arg)
 elseif verb=='upgrade' then
  if not near(p,rt.base.upgrade.Position,12) then say(p,'Use your vault upgrade console.'); return end
  ok,msg=core:upgrade(p.UserId)
 elseif verb=='testCash' and Run:IsStudio() and admin:authorized(p) then
  core.players[p.UserId].cash=Config.StudioTestGrant; core:changed(); ok=true; msg='STUDIO TEST CASH - session only.'
 elseif verb=='testMarket' and Run:IsStudio() and admin:authorized(p) and type(arg)=='string' and Catalog.ById[arg] then
  ok=spawnOffer(arg); msg=ok and 'Selected collectible spawned on the conveyor.' or 'Conveyor is full.'
 else return end
 if msg then say(p,msg) end; refresh()
end)
local tickAcc,moveAcc=0,0
Run.Heartbeat:Connect(function(dt)
 tickAcc=tickAcc+dt; moveAcc=moveAcc+dt
 if moveAcc>=.1 then
  moveAcc=0
  for id,rt in pairs(runtime) do
   local state=core.players[id]; local r,h=body(rt.player)
   local safe=r and movementSafe(rt.player)
   if h then h.WalkSpeed=os.clock()<rt.slow and Config.SlowSpeed or (state.carry and Config.CarrySpeed or Config.WalkSpeed) end
   if h then
    if os.clock()<(rt.shockUntil or 0) then
     rt.originalJump=rt.originalJump or h.JumpPower;h.JumpPower=0;h.Jump=false;h.WalkSpeed=0
     if r then r.AssemblyLinearVelocity=Vector3.zero end
    elseif rt.originalJump then h.JumpPower=rt.originalJump;rt.originalJump=nil end
    if admin then admin:applyMovement(rt.player,h) end
   end
  end
 end
 if tickAcc>=1 then
  local seconds=math.floor(tickAcc); tickAcc=tickAcc-seconds; core:tick(seconds)
  for _,b in ipairs(world.bases) do
   local state=b.owner and core.players[b.owner]; local rt=b.owner and runtime[b.owner]
   if state and rt then
    local locked=state.lockUntil>os.clock()
    b.gate.Transparency=locked and .55 or 1
    b.sign.Text=rt.player.DisplayName..'\n'..(locked and 'THEFT PROTECTED '..math.ceil(state.lockUntil-os.clock())..'s' or 'OPEN TO RAID')
    b.bank.Text='$'..state.bank..' READY\nCOLLECT / DELIVER'
    send(rt.player)
   else b.sign.Text='UNCLAIMED VAULT'; b.bank.Text='COLLECT / DELIVER'; b.gate.Transparency=1 end
  end
 end
end)
print('OPItemV2: '..#Catalog.Items..' collectibles ready. SESSION ALPHA: no persistent saves.')

