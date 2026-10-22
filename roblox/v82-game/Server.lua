-- Place the OPItemV2 folder in ServerScriptService. Disable the old prototype.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local DataStoreService=game:GetService('DataStoreService')
local HttpService=game:GetService('HttpService')
local MarketplaceService=game:GetService('MarketplaceService')
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
local persistenceConfig=require(script.Parent.PersistenceConfig)
assert(persistenceConfig.Enabled==true,'Saved profiles must remain enabled for this economy.')
local profileCodec=require(script.Parent.ProfileCodec)
local function storage(name)
 local cached
 return{UpdateAsync=function(_,key,transform)
  cached=cached or DataStoreService:GetDataStore(name)
  return cached:UpdateAsync(key,transform)
 end}
end
local profileStore=require(script.Parent.ProfileStore).new(persistenceConfig,{
 profiles=storage(Run:IsStudio()and persistenceConfig.StudioProfileStoreName or persistenceConfig.ProfileStoreName),
 journal=storage(Run:IsStudio()and persistenceConfig.StudioJournalStoreName or persistenceConfig.JournalStoreName),
 sessionId=HttpService:GenerateGUID(false),
 validate=function(data)
  local valid=profileCodec.validate(data,Catalog)
  if not valid then return false end
  local ok,json=pcall(function()return HttpService:JSONEncode(data)end)
  return ok and #json<=1500000
 end,
 allowRequest=function()return DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)>0 end,
})
local persistence=require(script.Parent.PersistentSession).new(core,profileStore,{
 guid=function()return HttpService:GenerateGUID(false)end,
 canStore=function(data,reserve)
  local ok,json=pcall(function()return HttpService:JSONEncode(data)end)
  return ok and #json+(reserve or 0)<=1500000
 end,
 onFailure=function(reason)
  warn('OPItem progress stopped safely: '..reason)
  task.defer(function()for _,p in ipairs(Players:GetPlayers())do p:Kick('Saving is temporarily unavailable. Your saved profile is protected. Please rejoin shortly.')end end)
 end,
})
local net=Instance.new('Folder'); net.Name='OPItemNet'; net.Parent=RS
local action=Instance.new('RemoteEvent'); action.Name='Action'; action.Parent=net
local update=Instance.new('RemoteEvent'); update.Name='Update'; update.Parent=net
local fx=Instance.new('RemoteEvent'); fx.Name='FX'; fx.Parent=net
local phaseEvent=Instance.new('RemoteEvent');phaseEvent.Name='Phase';phaseEvent.Parent=net
local audioEvent=Instance.new('RemoteEvent');audioEvent.Name='Audio';audioEvent.Parent=net
local shopEvent=Instance.new('RemoteEvent');shopEvent.Name='CashShop';shopEvent.Parent=net
script.Parent.PowerCatalog:Clone().Parent=net
script.Parent.DeveloperEffects:Clone().Parent=net
script.Parent.PowerEffects:Clone().Parent=net
script.Parent.FlightPoseClient:Clone().Parent=net
script.Parent.AudioConfig:Clone().Parent=net
script.Parent.AudioClient:Clone().Parent=net
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
local cashShop
local rng=Random.new()
local function body(p)
 local c=p.Character; local h=c and c:FindFirstChildOfClass('Humanoid'); local r=c and c:FindFirstChild('HumanoidRootPart')
 if h and h.Health>0 and r then return r,h end
end
local function near(p,pos,dist) local r=body(p); return r and (r.Position-pos).Magnitude<=dist end
local function say(p,msg) if p and p.Parent then update:FireClient(p,{message=msg}) end end
local function ownerAlert(p,kind,item,thief)
 if p and p.Parent then update:FireClient(p,{theftAlert={kind=kind,item=item,thief=thief}})end
end
local function sound(p,kind,power,position)
 if not p or not p.Parent then return end
 local payload={kind=kind,power=power,position=position}
 if position then audioEvent:FireAllClients(payload)else audioEvent:FireClient(p,payload)end
end
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
 if core.persistenceBusy then return end
 local snap=core:snapshot(p.UserId,os.clock())
 if snap then
  snap.battles=phase and phase:battles(p) or {}
  snap.studio=Run:IsStudio() and admin and admin:authorized(p) or false
  -- This private metadata is never sent to another account or sold by the shop.
  if admin and admin:isDeveloperMode(p) then
   snap.developerAbility={id='royalseal',mode=true,enabled=true,remaining=admin:getState(p).royalSealRemaining or 0}
  end
  local rt=runtime[p.UserId]
  if rt then
   if rt.audioLevel and snap.level>rt.audioLevel then sound(p,'levelup') end
   if snap.carry and snap.carry~=rt.audioCarry then sound(p,'purchase') end
   if rt.audioLocked==true and snap.lock<=0 then sound(p,'unlock') end
   rt.audioLevel=snap.level;rt.audioCarry=snap.carry
   rt.audioLocked=snap.lock>0
  end
  local state=core.players[p.UserId]
  snap.settings=table.clone(state.settings or{});snap.settings.tutorialCompleted=state.tutorialCompleted==true
  for key,value in pairs(persistence.pendingSettings[p.UserId]or{})do snap.settings[key]=value end
  snap.paidCashCredit=state.paidCashCredit or 0
  snap.persistenceStatus=persistence:isReady(p.UserId)and(Run:IsStudio()and'Studio test saves'or'Saved progress')or'Saving unavailable'
  snap.mode=Run:IsStudio()and'STUDIO TEST SAVES'or'SAVED PROGRESS';update:FireClient(p,snap)
 end
end
local function clone(kind)
 local m=templates[kind]:Clone(); m.Parent=world.folder; return m
end
local function setDisplay(m,cf)
 m:SetAttribute('DisplayCF',cf); m:PivotTo(cf)
end
local function refresh()
 if core.persistenceBusy then return end
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
local vault=require(script.Parent.VaultService).new({core=core,runtime=runtime,body=body,movementSafe=movementSafe,
 persistence=persistence,update=update,say=say,refresh=refresh})
for _,b in ipairs(world.bases) do
 prompt(b.home,'Collect earnings',function(p) if b.owner==p.UserId then local _,msg=core:collect(p.UserId); say(p,msg); refresh() end end)
 b.protectionPrompt=prompt(b.lock,'Protect ('..Config.ProtectionDuration..'s)',function(p) if b.owner==p.UserId then local ok,msg=core:protect(p.UserId,os.clock());if ok then sound(p,'lock') end;say(p,msg); refresh() end end)
 prompt(b.upgrade,'Power shop / loadout',function(p) if b.owner==p.UserId then phaseEvent:FireClient(p,{open='powers'}) end end)
 local manager=Factory.part(world.folder,'Vault Manager',Vector3.new(3,2.5,3),b.cf*CFrame.new(-16,2.2,-17),Color3.fromRGB(70,152,143),Enum.Material.Metal)
 manager.CanCollide=true;manager.CanQuery=true;world.label(manager,'MOVE / SELL ITEMS')
 prompt(manager,'Manage base items',function(p)if b.owner==p.UserId then vault:open(p)end end)
end
prompt(world.powerShop,'Power shop',function(p)phaseEvent:FireClient(p,{open='powers'})end)
local cashBench=require(script.Parent.CashShopBench).create(world)
local shopConfig=require(script.Parent.CashShopConfig)
cashShop=require(script.Parent.CashShopService).new(shopConfig,{core=core,body=body,remote=shopEvent,anchor=cashBench,
 marketplace=MarketplaceService,players=Players,persistence=persistence,refresh=refresh,
 purchaseGrant=function(p,receipt,offer)
  local ok,msg=persistence:grantReceipt(p,receipt,offer,shopConfig.CashPerRobux)
  if ok then refresh()end;return ok,msg
 end,
})
local attached,attachReason=cashShop:attach();assert(attached,attachReason)
prompt(cashBench,'Robux shop',function(p)cashShop:open(p)end)
shopEvent.OnServerEvent:Connect(function(p,payload)cashShop:request(p,payload)end)
local function power(p,arg) phase:cast(p,arg) end
local function join(p)
 if admin and not admin:admit(p) then return end
 local id=p.UserId; if runtime[id]or persistence.loading[id]then return end
 local b
 for _,candidate in ipairs(world.bases) do if not candidate.owner then b=candidate; break end end
 if not b then p:Kick('All '..Config.MaxPlayers..' vaults are occupied. Join another server.'); return end
 b.owner=id
 local loaded,loadReason=persistence:load(id)
 if not loaded then
  b.owner=nil;warn('OPItem profile load rejected for '..id..': '..tostring(loadReason))
  if p.Parent then p:Kick('Your saved profile could not be loaded safely. Please rejoin shortly. No fresh profile was substituted.')end
  return
 end
 if not p.Parent then persistence:leave(id);b.owner=nil;return end
 local stats=Instance.new('Folder'); stats.Name='leaderstats'; stats.Parent=p
 local cash=Instance.new('IntValue'); cash.Name='Cash'; cash.Parent=stats
 local steals=Instance.new('IntValue'); steals.Name='Steals'; steals.Parent=stats
 local rt={player=p,base=b,cash=cash,steals=steals,nextAction=0,nextRemote=0,shield=0,slow=0,immune=0}
 runtime[id]=rt
 if admin then admin:onJoin(p) end
 local function char(c)
  local r=c:WaitForChild('HumanoidRootPart',10); local h=c:WaitForChild('Humanoid',10)
  if not r or not h or not runtime[id] or p.Character~=c then return end
  rt.pendingReset=true;phase:cancelPlayer(p)
  if core:characterReset(id,os.clock())then rt.pendingReset=nil end
  finish(p,false);rt.slow=0;rt.shield=0;c:PivotTo(b.spawn)
  rt.travelPosition=r.Position; rt.travelTime=os.clock(); rt.travelCredit=5; rt.safeCF=r.CFrame; rt.blockedUntil=0; rt.impulseUntil=0
  if admin then admin:resetCharacter(p) end
  local previousHealth=h.Health
  h.HealthChanged:Connect(function(health)
   if p.Character==c and health<previousHealth then phase:interrupt(p,false) end
   previousHealth=health
  end)
  h.Died:Connect(function()if p.Character==c then
   rt.pendingReset=true;phase:cancelPlayer(p)
   if core:characterReset(id,os.clock())then rt.pendingReset=nil end
   if admin then admin:resetCharacter(p)end;finish(p,false,'Heist ended on respawn.')
  end end)
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
  if not pg:FindFirstChild('OPItemCashShop') then
   local gui=Instance.new('ScreenGui');gui.Name='OPItemCashShop';gui.ResetOnSpawn=false;gui.DisplayOrder=16;gui.Parent=pg
   local client=script.Parent.CashShopClient:Clone();client.Enabled=false;client.Parent=gui;client.Enabled=true
  end
 end)
 refresh()
end
phase=require(script.Parent.PhaseService).new({core=core,world=world,net=net,config=Config,catalog=Catalog,templates=templates,runtime=runtime,rng=rng,body=body,los=los,movementSafe=movementSafe,refresh=refresh,say=say,fx=fx,audio=sound,ownerAlert=ownerAlert,
 isDeveloperInvulnerable=function(p) return admin and admin:isInvulnerable(p) or false end,
})
admin=require(script.Parent.AdminService).attach(require(script.Parent.AdminConfig),{
 core=core,runtime=runtime,world=world,net=net,catalog=Catalog,body=body,templates=templates,
 refresh=refresh,spawnOffer=spawnOffer,finish=finish,say=say,
 castPower=function(p,kind,rodOrigin) return phase:cast(p,kind,rodOrigin) end,
 castDeveloperPower=function(p,rodOrigin)
  local ok,msg=require(script.Parent.DeveloperPowers).cast(phase,admin,p,rodOrigin)
  if ok then local r=body(p);sound(p,'powerCast','royalseal',r and r.Position)end
  return ok,msg
 end,
})
local dispatch=admin.dispatch
local persistentAdmin={giftcash=true,giftlevels=true,cash=true,grant=true,remove=true,protect=true,powers=true,cooldowns=true}
local function copyValue(value)
 if type(value)~='table'then return value end
 local result={};for k,v in pairs(value)do result[k]=copyValue(v)end;return result
end
admin.dispatch=function(self,p,payload)
 if type(payload)~='table'or payload.mode~='command'or not self:authorized(p)then return dispatch(self,p,payload)end
 local name=type(payload.text)=='string'and payload.text:match('^%s*(%S+)')
 name=name and string.lower(name)
 if not persistentAdmin[name]then return dispatch(self,p,payload)end
 local giftCache=(name=='giftcash'or name=='giftlevels')and copyValue(self.giftReceipts)or nil
 local result,why=persistence:adminCommand(function()return dispatch(self,p,payload)end)
 if type(result)~='table'then
  if giftCache then self.giftReceipts=giftCache end
  return self:reply(p,{ok=false,message=why or'Progress is saving. Try again.'})
 end
 refresh();return result
end
Players.PlayerAdded:Connect(join)
for _,p in ipairs(Players:GetPlayers()) do join(p) end
Players.PlayerRemoving:Connect(function(p)
 vault:removePlayer(p)
 if phase then phase:cancelPlayer(p) end
 if admin then admin:removePlayer(p) end
 if cashShop then cashShop:removePlayer(p) end
 local rt=runtime[p.UserId]; if not rt then return end
 persistence:leave(p.UserId);rt.base.owner=nil;runtime[p.UserId]=nil;refresh()
end)
action.OnServerEvent:Connect(function(p,verb,arg)
 local rt=runtime[p.UserId]; if not rt or type(verb)~='string' or #verb>20 then return end
 if core.closing then return end
 if verb=='settings'then
  if os.clock()<(rt.nextSettings or 0)then return end;rt.nextSettings=os.clock()+.2
  local ok,msg=persistence:queueSettings(p.UserId,arg)
  if not ok then say(p,msg)else persistence:flushSettings(p.UserId)end
  send(p);return
 end
 if core.persistenceBusy then return end
 -- A quick close immediately after Move must cancel its token even while the
 -- general action throttle is cooling down. VaultService separately limits it.
 if verb=='cancelItemMove'then vault:handle(p,verb,arg);return end
 if os.clock()<rt.nextRemote then return end; rt.nextRemote=os.clock()+.15
 if verb=='ready' then send(p); return end
 if rt.pendingReset then return end
 if not body(p) or not movementSafe(p) then return end
 if vault:handle(p,verb,arg)then return end
 if phase:handle(p,verb,arg) then return end
 if verb=='power' then power(p,arg); return end
 local ok,msg
 if verb=='equip' and type(arg)=='string' and #arg<=96 then ok,msg=core:equip(p.UserId,arg)
 elseif verb=='sell' and type(arg)=='string' and #arg<=96 then
  if not near(p,rt.base.home.Position,40) then say(p,'Return to your vault to sell.'); return end
  ok,msg=core:sell(p.UserId,arg)
 elseif verb=='upgrade' then
  if not near(p,rt.base.upgrade.Position,12) then say(p,'Use your vault upgrade console.'); return end
  ok,msg=core:upgrade(p.UserId)
 elseif verb=='testCash' and Run:IsStudio() and admin:authorized(p) then
  ok,msg=persistence:runFor(p.UserId,function()
   core.players[p.UserId].cash=Config.StudioTestGrant;core:changed();return true,'STUDIO TEST CASH - saved only in this test data store.'
  end)
 elseif verb=='testMarket' and Run:IsStudio() and admin:authorized(p) and type(arg)=='string' and Catalog.ById[arg] then
  ok=spawnOffer(arg); msg=ok and 'Selected collectible spawned on the conveyor.' or 'Conveyor is full.'
 else return end
 if msg then say(p,msg) end; refresh()
end)
local tickAcc,moveAcc,saveAcc=0,0,0
Run.Heartbeat:Connect(function(dt)
 if core.closing then return end
 tickAcc+=dt;moveAcc+=dt;saveAcc+=dt
 if core.persistenceBusy then
  for _,rt in pairs(runtime)do if body(rt.player)then movementSafe(rt.player)end end
  return
 end
 if persistence:flushSettings()or core.persistenceBusy then return end
 if saveAcc>=persistenceConfig.AutosaveSeconds then
  saveAcc=0;task.spawn(function()persistence:flushAll()end);return
 end
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
game:BindToClose(function()
 core.closing=true
 persistence:flushAll()
 local ids={};for id in pairs(persistence.loaded)do ids[#ids+1]=id end
 for _,id in ipairs(ids)do persistence:leave(id)end
end)
print('OPItemV2: '..#Catalog.Items..' collectibles ready; saved profiles required. Product IDs configured; checkout stays off pending private purchase tests.')

