-- Actual server-only developer service execution; Roblox APIs are test fixtures.
return function(package,requireModule,f)
 local Service=requireModule(package.AdminService)
 local Policy=requireModule(package.AdminPolicy)
 local AdminConfig=requireModule(package.AdminConfig)
 local Core=requireModule(package.Core)
 local Catalog=requireModule(package.Catalog)
 local Config=requireModule(package.Config)
 local Powers=requireModule(package.PowerCatalog)
 local Rules=requireModule(package.PhaseConfig)
 local checks,commands=0,0
 local groups={}
 local function check(value,message)checks+=1;assert(value,message)end
 local function near(a,b,message)check(math.abs(a-b)<1e-8,message)end
 local function clone(t)local out={};for k,v in pairs(t)do out[k]=type(v)=='table'and clone(v)or v end;return out end
 local function config(overrides)
  local c=clone(AdminConfig);c.Enabled=true;c.DeveloperUserId=77;c.DeveloperUsername='';c.AutoAuthorizePlaceOwner=false
  for k,v in pairs(overrides or{})do c[k]=v end
  return c
 end
 local function fresh(overrides)
  f.setTime(100);f.workspace.blocked=false;f.text.fail=false
  local core=Core.new(Catalog,Config)
  local actor,root,h=f.newPlayer(77);local outsider,otherRoot,otherH=f.newPlayer(88)
  local nonceSequence=0
  local ctx={core=core,catalog=Catalog,runtime={},clock=f.now,nonce=function()nonceSequence+=1;return 'test-'..nonceSequence end,says={},refreshes=0,casts={},homes=0}
  for _,p in ipairs({actor,outsider})do
   core:addPlayer(p.UserId,0);core.players[p.UserId].cash=1000000
   ctx.runtime[p.UserId]={player=p,base={cf=f.CFrame.new(15,0,35),spawn={Position=f.Vector3.new(15,5,35)}}}
  end
  function ctx.body(p)
   if p.noBody then return nil end
   return p.Character:FindFirstChild('HumanoidRootPart'),p.Character:FindFirstChildOfClass('Humanoid')
  end
  function ctx.refresh()ctx.refreshes+=1 end
  function ctx.say(p,message)table.insert(ctx.says,{player=p,message=message})end
  function ctx.finish(p,success)ctx.finishCalls=(ctx.finishCalls or 0)+1;return core:finish(p.UserId,success,f.now())end
  function ctx.spawnOffer(kind)
   if ctx.conveyorFull then return false end
   ctx.offers=(ctx.offers or 0)+1;core:setOffer('admin-offer'..ctx.offers,kind,f.now(),55);return true
  end
  function ctx.castPower(p,id)table.insert(ctx.casts,{player=p,id=id});return core:power(p.UserId,f.now(),id)end
  function ctx.home(p)
   ctx.homes+=1;p.Character:PivotTo(f.CFrame.new(15,5,35));return true,'Returned to your base.'
  end
  local service=Service.new(config(overrides),ctx)
  local function command(text,confirmation,noAdvance)
   if not noAdvance then f.advance(1)end
   commands+=1
   return service:dispatch(actor,{mode='command',text=text,confirmation=confirmation})
  end
  return service,ctx,actor,outsider,root,h,command,otherRoot,otherH
 end
 do
  local now=100;local c=config();local seq=0
  local function policy(overrides,owner)
   return Policy.new(config(overrides),function()return now end,function()seq+=1;return 'p-'..seq end,owner)
  end
  check(policy():authorized(77),'Explicit numeric developer ID must authorize')
  for _,id in ipairs({0,-1,77.5,math.huge,0/0,'77',false,{UserId=77}})do
   local p=policy({DeveloperUserId=id,DeveloperUsername='',AutoAuthorizePlaceOwner=false})
   check(not p:authorized(77),'Invalid developer ID must fail closed: '..tostring(id))
  end
  check(not policy({Enabled=false}):authorized(77),'Disabled administration must deny configured developer')
  check(not policy():authorized(88),'Different numeric ID must be denied')
  check(policy({DeveloperUserId=0,DeveloperUsername='',AutoAuthorizePlaceOwner=true},77):authorized(77),'Explicitly enabled personal-owner fallback must authorize numeric owner')
  check(not policy({DeveloperUserId=77,AutoAuthorizePlaceOwner=true},88):authorized(88),'Explicit developer ID takes priority over creator')
  check(not policy({DeveloperUserId=0,DeveloperUsername='Goverment_cheesee',AutoAuthorizePlaceOwner=true},77):authorized(77),'Unresolved configured username must not fall back to creator')
  local p=policy()
  for _=1,c.CommandBurst do check(p:prepare(77,'state',false),'Rate bucket must allow configured burst')end
  local ok,message=p:prepare(77,'state',false);check(not ok and message=='Rate limited.','Burst overflow must be denied')
  now+=.5;check(p:prepare(77,'state',false),'Bucket must refill at configured rate')
  now+=10
  local allowed,_,token=p:prepare(77,'cash self set 1',true)
  check(not allowed and type(token)=='string','Destructive action must require confirmation')
  check(not p:prepare(77,'cash self set 2',true,token),'Confirmation must bind exact normalized command')
  check(not p:prepare(77,'cash self set 1',true,token),'Invalid confirmation must be consumed')
  now+=1;local _,_,valid=p:prepare(77,'cash self set 1',true)
  check(p:prepare(77,'cash self set 1',true,valid),'Valid confirmation must execute once')
  now+=1;check(not p:prepare(77,'cash self set 1',true,valid),'Successful confirmation must not replay')
  local _,_,expired=p:prepare(77,'remove self relic1',true);now+=c.ConfirmationSeconds+1
  check(not p:prepare(77,'remove self relic1',true,expired),'Expired confirmation must fail')
  check(not p:prepare(77,'state',false,'unexpected'),'Non-destructive action must reject extra token')
  for i=1,c.MaxLogs+10 do p:record(77,string.rep('x',600),string.rep('y',300))end
  check(#p.logs==c.MaxLogs and #p.logs[1].command==512 and #p.logs[1].status==240,'Audit log must remain bounded')
  p:forget(77);check(not p.buckets[77]and not p.pending[77],'Player removal clears confirmations and rate bucket')
  groups.identityPolicy=true
 end
 do
  local before=#f.players.lookupCalls
  f.players.lookupIds.Goverment_cheesee=77
  local s,_,actor,outsider=fresh({DeveloperUserId=0,DeveloperUsername='Goverment_cheesee'})
  check(#f.players.lookupCalls==before+1 and f.players.lookupCalls[#f.players.lookupCalls]=='Goverment_cheesee','Server must resolve exactly the configured username once')
  check(s:authorized(actor)and not s:authorized(outsider),'Resolved account authorization must compare numeric UserIds')
  check(actor.Name==outsider.Name and actor.DisplayName==outsider.DisplayName,'Fixture must exercise duplicated names')
  s:authorized(actor);s:authorized(outsider);check(#f.players.lookupCalls==before+1,'Authorization must not repeatedly yield for identity lookup')
  before=#f.players.lookupCalls
  local explicit,_,e=fresh({DeveloperUserId=77,DeveloperUsername='WrongAccount'})
  check(explicit:authorized(e)and #f.players.lookupCalls==before,'Explicit numeric developer ID must skip username lookup')
  local disabled,_,d=fresh({Enabled=false,DeveloperUserId=0,DeveloperUsername='Goverment_cheesee'})
  check(not disabled:authorized(d)and #f.players.lookupCalls==before,'Disabled developer menu must skip identity lookup entirely')
  local invalid,_,i=fresh({DeveloperUserId=-1,DeveloperUsername='Goverment_cheesee',AutoAuthorizePlaceOwner=true})
  check(not invalid:authorized(i)and #f.players.lookupCalls==before,'Invalid nonzero numeric config must fail closed without lookup or fallback')
  for _,badId in ipairs({false,{UserId=77},'77',math.huge,0/0,77.5,9007199254740992})do
   local malformed,_,m=fresh({DeveloperUserId=badId,DeveloperUsername='Goverment_cheesee',AutoAuthorizePlaceOwner=true})
   check(not malformed:authorized(m)and #f.players.lookupCalls==before,'Malformed explicit developer ID must not crash, lookup username, or fall back to owner')
  end
  f.players.lookupFailure=true
  local failed,_,a=fresh({DeveloperUserId=0,DeveloperUsername='Goverment_cheesee',AutoAuthorizePlaceOwner=true})
  check(not failed:authorized(a),'Failed username lookup must deny all access including place creator')
  f.players.lookupFailure=false
  for _,badId in ipairs({'77',0,-1,77.5,math.huge,0/0,{UserId=77}})do
   f.players.lookupIds.Goverment_cheesee=badId
   local rejected,_,b=fresh({DeveloperUserId=0,DeveloperUsername='Goverment_cheesee'})
   check(not rejected:authorized(b),'Identity resolver must return an actual finite positive integer: '..tostring(badId))
  end
  f.players.lookupIds.Goverment_cheesee=77
  f.game.CreatorType=f.Enum.CreatorType.Group
  local grouped,_,g=fresh({DeveloperUserId=0,DeveloperUsername='',AutoAuthorizePlaceOwner=true})
  check(not grouped:authorized(g),'Group CreatorId must never be interpreted as owner UserId')
  f.game.CreatorType=f.Enum.CreatorType.User
  local personal,_,p=fresh({DeveloperUserId=0,DeveloperUsername='',AutoAuthorizePlaceOwner=true})
  check(personal:authorized(p),'Opt-in personal creator fallback must use server game identity')
  groups.identityResolution=true
 end
 do
  local s,ctx,actor,outsider,root,h,command=fresh()
  local help=command('help');check(help.ok and type(help.data.commands)=='table','Authorized help must expose supported commands')
  local revision=ctx.core.revision
  for name in pairs(help.data.commands)do
   f.advance(2.1)
   local response=s:dispatch(outsider,{mode='command',text=name..' self on',UserId=77,actor=actor,authorized=true})
   check(response and response.ok==false,'Every command verb must reject outsider before parsing: '..name)
   check(ctx.core.revision==revision,'Outsider command changed real session state: '..name)
  end
  for _,payload in ipairs({{mode='hello'},{mode='move',direction=f.Vector3.new(1,0,0)}, {mode='command',text='cash 77 add 999999',developerUserId=77}})do
   f.advance(2.1);local response=s:dispatch(outsider,payload)
   check(response and response.ok==false and not response.authorized,'Outsider cannot bypass with hello/move/spoofed identity')
  end
  s:onJoin(outsider)
  check(not outsider.PlayerGui:FindFirstChild('OPDeveloperConsole')and not s.chat[88],'Outsider must receive neither private console nor command chat listener')
  s:onJoin(actor);s:onJoin(actor)
  local count=0;for _,child in ipairs(actor.PlayerGui:GetChildren())do if child.Name=='OPDeveloperConsole'then count+=1 end end
  check(count==1 and s.chat[77]~=nil,'Developer UI injection must be private and idempotent')
  local hello=s:dispatch(actor,{mode='hello'});check(hello and hello.ok and hello.authorized,'Authorized hello must succeed')
  check(#hello.data.catalog==#Catalog.Items and #hello.data.powers==8 and hello.mods.god==false,'Developer hello must supply actual catalog, exactly eight powers, and server mod state')
  local flight=command('flight on');check(flight.ok,'Authorized developer flight must enable')
  s.config.Enabled=false;s:tick()
  check(not s:authorized(actor)and not s:allowsMovement(actor)and not s.mobility[77],'Revoking admin must restore movement and remove existing bypass')
  check(h.PlatformStand==false and h.AutoRotate==true and root.ownershipRestored,'Revocation restores physical character and network ownership')
  groups.serverBoundary=true
 end
 do
  local s,ctx,actor,_,_,_,command=fresh()
  for _,raw in ipairs({'',string.rep('x',513),'state extra','cash self add nan','cash self add inf','cash self add -1','cash self add 1.5','cash self add 2000000001','grant self item08 9','grant self item08 0','grant self absent 1','teleport self 123 5 0','teleport self 0 2 0','teleport self 0 5 91','speed 65','speed 15','jump 49','jump 121','cast absent','god maybe','state\0','inventory SameDisplayName','cash 0 add 5','cash 77.5 add 5','cash 9007199254740992 add 5'})do
   local before=ctx.core.revision;local result=command(raw)
   check(result and not result.ok,'Malformed/out-of-range command unexpectedly accepted: '..raw)
   check(ctx.core.revision==before,'Rejected input mutated actual state: '..raw)
  end
  for _,payload in ipairs({false,42,'help',{mode='not-a-mode'},{mode='command',text={}}})do
   f.advance(1);local result=s:dispatch(actor,payload);check(result and not result.ok,'Malformed remote payload must safely reject')
  end
  local p=ctx.core.players[77];local before=p.cash
  local confirm=command('cash self set 9');check(not confirm.ok and confirm.confirmation and p.cash==before,'Destructive dispatch must not mutate before confirmation')
  local wrong=command('cash self set 10',confirm.confirmation);check(not wrong.ok and p.cash==before,'Dispatch confirmation must bind exact command')
  local nextConfirm=command('cash self set 9');local done=command('cash self set 9',nextConfirm.confirmation)
  check(done.ok and p.cash==9,'Confirmed command must mutate exactly once')
  check(not command('cash self set 9',nextConfirm.confirmation).ok,'Confirmed dispatch cannot be replayed')
  local q=Service.new(config(),ctx)
  for _=1,AdminConfig.CommandBurst do check(q:dispatch(actor,{mode='hello'}).ok,'Hello allows configured burst')end
  check(not q:dispatch(actor,{mode='command',text='cash self add 1'}).ok and p.cash==9,'Remote rate limit must precede mutation')
  s.busy[77]=true;check(not command('state').ok,'Simultaneous yielding command must be rejected');s.busy[77]=nil
  groups.validation=true
 end
 do
  local s,ctx,actor,outsider,root,h,command=fresh()
  local p=ctx.core.players[77]
  check(command('cash self add 500').ok and p.cash==1000500,'Developer add cash uses actual wallet')
  p.held=100;check(command('cash self add 2000000000').ok and p.cash==AdminConfig.MaxCurrency-100,'Cash cap must include held escrow');p.held=0
  local originalItems=0;for _ in pairs(ctx.core.items)do originalItems+=1 end
  local result=command('grant self item08 7')
  check(result.ok and #result.data.granted==7 and p.capacity==8,'Grant must use actual eight-slot inventory')
  local seen=0;for _,uid in pairs(p.slots)do check(ctx.core.items[uid].owner==77,'Granted item lost owner');seen+=1 end
  check(seen==8 and p.seen.item08,'Grant must fill real slots and index collectible')
  local before=ctx.core.revision;local full=command('grant self item08 1')
  check(not full.ok and ctx.core.revision==before and #command('inventory self').data.inventory==8,'Full-base grant must reject without partial mutation')
  local uid=result.data.granted[1];local beforeCash=p.cash
  local remove=command('remove self '..uid);check(remove.confirmation and ctx.core.items[uid],'Item removal must confirm before deletion')
  check(command(remove.command,remove.confirmation).ok and not ctx.core.items[uid]and p.cash==beforeCash,'Confirmed removal deletes real item without sell proceeds')
  check(not command('remove 88 '..result.data.granted[2]).ok,'Wrong-owner item removal must fail')
  check(command('offer item08').ok and ctx.offers==1,'Offer command must use real conveyor callback')
  ctx.conveyorFull=true;check(not command('offer item08').ok and ctx.offers==1,'Full conveyor callback must reject extra offers')
  local state=command('state');check(state.ok and state.data.catalogItems==#Catalog.Items,'State response must report current real session')
  local protects=command('protect self 120');check(protects.ok and p.lockUntil==f.now()+120,'Protection applies actual timer')
  local clear=command('protect self 0');check(clear.confirmation,'Clearing protection must require confirmation')
  check(command(clear.command,clear.confirmation).ok and p.lockUntil==f.now(),'Confirmed clearing protection must update real timer')
  f.workspace.blocked=true;check(not command('teleport self 0 5 0').ok,'Teleport must reject solid destination')
  f.workspace.blocked=false;check(command('teleport self 12 6 13').ok and root.Position.X==12 and root.Position.Z==13,'Safe teleport must pivot actual character')
  check(command('announce hello game').ok and #ctx.says==2 and f.text.lastActor==77,'Announcement must use server filtering and broadcast once per player')
  check(ctx.says[1].message=='DEVELOPER: [filtered] hello game','Raw unfiltered announcement must not be sent')
  f.text.fail=true;local beforeSays=#ctx.says;check(not command('announce failure').ok and #ctx.says==beforeSays,'Failed text filtering must not leak announcement');f.text.fail=false
  local ban=command('ban 88 test');check(ban.confirmation and not outsider.kicked,'Moderation must confirm before affecting player')
  check(command(ban.command,ban.confirmation).ok and outsider.kicked and s.bans[88],'Confirmed session ban must kick and record restriction')
  check(not s:admit(outsider),'Banned player must not be readmitted during session')
  check(command('unban 88').ok and not s.bans[88]and s:admit(outsider),'Unban must remove session-only restriction')
  local selfBan=command('ban 77');check(selfBan.confirmation and not command(selfBan.command,selfBan.confirmation).ok and not actor.kicked,'Developer must not ban self')
  check(command('logs 20').ok and #s.policy.logs>0,'Commands must be audited and logs readable')
  outsider.kicked=nil
  local kick=command('kick 88');check(kick.confirmation and command(kick.command,kick.confirmation).ok and outsider.kicked and not s.bans[88],'Confirmed kick must not create a session ban')
  groups.existingCommands=true
 end
 do
  local s,ctx,actor,_,root,h,command=fresh()
  check(command('flight on').ok,'Flight must enable')
  local m=s.mobility[77]
  check(m.flight and m.attachment.Parent==root and m.velocity.Parent==root,'Flight must create real attachment and velocity objects')
  check(h.PlatformStand and not h.AutoRotate and root.serverOwned,'Flight must take temporary server movement ownership')
  s:dispatch(actor,{mode='move',direction=f.Vector3.new(1,0,0)})
  s:tick();near(m.velocity.VectorVelocity.X,AdminConfig.FlightSpeed,'Flight must use server-limited speed')
  f.advance(AdminConfig.InputInterval+.01)
  s:dispatch(actor,{mode='move',direction=f.Vector3.new(2,0,0)})
  s:tick();near(m.velocity.VectorVelocity.X,AdminConfig.FlightSpeed,'Oversized vector must not replace safe input')
  f.advance(.4);s:tick();near(m.velocity.VectorVelocity.Magnitude,0,'Missing movement packets must stop flight after timeout')
  for _,d in ipairs({f.Vector3.new(0/0,0,0),f.Vector3.new(math.huge,0,0),f.Vector3.new(1,1,0),{X=1,Y=0,Z=0}})do
   f.advance(.1);s:dispatch(actor,{mode='move',direction=d});s:tick();near(m.velocity.VectorVelocity.Magnitude,0,'Malformed movement input must not drive flight')
  end
  root.CFrame=f.CFrame.new(130,125,100);s:tick()
  check(root.Position.X==122 and root.Position.Y==120 and root.Position.Z==90 and m.velocity.VectorVelocity.Magnitude==0,'Flight must stay inside server map bounds')
  local velocity,attachment=m.velocity,m.attachment
  check(command('flight off').ok and velocity._destroyed and attachment._destroyed,'Turning flight off destroys control instances')
  check(not h.PlatformStand and h.AutoRotate and root.ownershipRestored,'Turning flight off restores humanoid/network behavior')
  local foot=actor.Character.Foot;local initiallyFalse=actor.Character.InitiallyNonColliding
  check(command('noclip on').ok,'Noclip must enable');s:applyNoclip()
  check(not root.CanCollide and not foot.CanCollide and not initiallyFalse.CanCollide,'Noclip must disable collision on character parts')
  local late=f.newInstance('Part');late.Parent=actor.Character;s:applyNoclip();check(not late.CanCollide,'Noclip must cover newly added character parts')
  check(command('noclip off').ok and root.CanCollide and foot.CanCollide and late.CanCollide and not initiallyFalse.CanCollide,'Noclip must restore each original collision value')
  check(command('flight on').ok and command('noclip on').ok,'Combined mobility mods must enable');s:applyNoclip()
  s:resetCharacter(actor)
  check(not s.mobility[77]and not s.input[77]and not h.PlatformStand and h.AutoRotate and root.CanCollide and not initiallyFalse.CanCollide,'Character reset must clear and restore all mobility state')
  h.WalkSpeed=19;h.UseJumpPower=false;h.JumpHeight=8.1;h.JumpPower=51
  check(command('speed 64').ok and command('jump 120').ok and h.UseJumpPower,'Override may temporarily switch a height-based humanoid to jump power')
  check(command('resetmods').ok and h.WalkSpeed==19 and h.JumpPower==51 and h.JumpHeight==8.1 and not h.UseJumpPower,'Reset restores actual pre-mod movement properties and original jump mode')
  groups.mobility=true
 end
 do
  local s,ctx,actor,outsider,root,h,command=fresh()
  local p=ctx.core.players[77]
  check(command('god on').ok and s:isInvulnerable(actor)and not s:isInvulnerable(outsider),'God mode must be server-owned and restricted to developer')
  check(command('god off').ok and not s:isInvulnerable(actor),'God mode must disable')
  h.Health=35;check(command('heal').ok and h.Health==h.MaxHealth,'Heal restores own humanoid without changing maximum')
  check(command('speed 48').ok and command('jump 95').ok,'Bounded speed/jump commands must enable')
  s:applyMovement(actor,h)
  check(h.WalkSpeed==48 and h.JumpPower==95,'Developer movement applies configured speed and jump')
  check(command('powers').ok,'Unlock all current eight powers must succeed')
  local count=0;for id,owned in pairs(p.powerOwned)do if owned then count+=1;check(Powers.ById[id]~=nil,'Developer unlock must not invent unknown powers')end end
  check(count==8 and p.loadout[1]=='tag'and #p.loadout<=3 and p.capacity==8,'Power unlock must preserve fixed Tag, three equipped powers and eight item slots')
  check(ctx.core:loadPower(77,'shield',2),'Unlocked developer power must load through normal Core')
  local cast=command('cast shield');check(cast.ok and #ctx.casts==1 and ctx.casts[1].player==actor and ctx.casts[1].id=='shield','Developer cast must delegate to real power callback')
  check((p.powerReady.shield or 0)>f.now(),'Delegated cast must use regular power cooldown')
  check(command('cooldowns').ok and not next(p.powerReady)and(p.castReady or 0)<=f.now(),'Cooldown reset clears only cooldown state')
  for _,definition in ipairs(Powers.Items)do
   check(command('cooldowns').ok,'Each developer test may reset cooldowns')
   local before=#ctx.casts;local result=command('cast '..definition.id)
   check(result.ok and #ctx.casts==before+1 and ctx.casts[#ctx.casts].id==definition.id,'Every developer power must delegate through the regular cast callback: '..definition.id)
   check(p.loadout[1]=='tag'and #p.loadout<=3 and p.powerSlots==3,'Automatic cast equipment must preserve fixed Tag and three slots')
  end
  check(not ctx.core.players[88].powerOwned.lightning and ctx.core.players[88].powerSlots==2,'Developer unlock and casts must not change another player powers')
  check(command('home').ok and root.Position.X==15 and root.Position.Y==5 and root.Position.Z==35,'Home must use own base spawn through safe teleport')
  local beforeCash=p.cash;local beforeCapacity=p.capacity;local starter=p.slots[1]
  check(command('resetmods').ok,'Reset mods must succeed')
  check(not s:isInvulnerable(actor)and not s:allowsMovement(actor)and h.WalkSpeed==16 and h.JumpPower==50 and h.UseJumpPower==true,'Reset mods restores original movement and immunity')
  check(p.cash==beforeCash and p.capacity==beforeCapacity and p.slots[1]==starter,'Reset mods must not delete money or collectibles')
  groups.developerCommands=true
 end
 do
  local s,ctx,actor,_,root,h,command=fresh()
  local p=ctx.core.players[77];local beforeCash=p.cash
  local o=ctx.core:setOffer('carry-check','item08',f.now(),55)
  check(ctx.core:purchaseAttempt(77,o.id,o.token,f.now()),'Fixture must create actual held purchase reservation')
  for _,raw in ipairs({'flight on','noclip on','god on','speed 32','jump 75','heal','powers','cooldowns','cast tag','home'})do
   local before=ctx.core.revision;local response=command(raw)
   check(not response.ok,'Developer must not bypass pending reservation restriction: '..raw)
   check(ctx.core.revision==before,'Blocked developer action mutated reservation state: '..raw)
  end
  check(command('flight off').ok and command('noclip off').ok and command('god off').ok and command('resetmods').ok,'Disable/reset actions remain available while bidding')
  check(ctx.core:withdraw(77,f.now())and p.cash==beforeCash and p.held==0,'Cancelled admin test reservation must refund exactly')
  ctx.core:advance(f.now()+.1)
  local carry=ctx.core:setOffer('carry-real','item08',f.now(),55)
  check(ctx.core:purchaseAttempt(77,carry.id,carry.token,f.now()),'Carry fixture must reserve')
  ctx.core:advance(f.now()+Rules.ContestWindow+.01)
  check(p.carry~=nil,'Carry fixture must reach actual purchase carry')
  for _,raw in ipairs({'flight on','noclip on','god on','speed 32','jump 75','heal','powers','cooldowns','cast tag','home'})do check(not command(raw).ok,'Developer carrying must obey mod restriction: '..raw)end
  local paid=ctx.core.transactions[ctx.core.items[p.carry].tx].amount
  local teleport=command('teleport self 0 5 0');check(teleport.confirmation,'Teleport while carrying must require explicit return confirmation')
  check(command(teleport.command,teleport.confirmation).ok and not p.carry and p.held==0 and p.cash==beforeCash-paid,'Confirmed carrier teleport must return loot without refunding a completed pickup')
  check(command('god on').ok and command('speed 32').ok and command('jump 75').ok,'Mods may resume after delivery/return')
  s:removePlayer(actor)
  check(not s.mobility[77]and not s.chat[77]and not s.policy.buckets[77]and not s.policy.pending[77]and not s:isInvulnerable(actor),'Disconnect clears all developer mod and command state')
  check(h.WalkSpeed==16 and h.JumpPower==50,'Disconnect restores humanoid movement')
  groups.carrySafety=true
 end
 do
  local _,ctx,actor,outsider,root,h=fresh()
  ctx.net=f.newInstance('Folder')
  local s=Service.attach(config(),ctx)
  check(ctx.net.AdminRequest==s.request and ctx.net.AdminResponse==s.response,'Attach must bind the actual two developer RemoteEvents')
  local before=ctx.core.players[77].cash
  s.request.OnServerEvent:Fire(outsider,{mode='command',text='cash 77 add 100000',UserId=77,authorized=true})
  check(ctx.core.players[77].cash==before and #s.response.calls==1 and s.response.calls[1].player==outsider and s.response.calls[1].payload.authorized==false,'Actual remote event uses authenticated sender and sends denial only to requester')
  s.request.OnServerEvent:Fire(actor,{mode='hello'})
  check(#s.response.calls==2 and s.response.calls[2].player==actor and s.response.calls[2].payload.authorized==true,'Actual developer remote handshake must reply only to developer')
  f.advance(1);s.request.OnServerEvent:Fire(actor,{mode='command',text='flight on'})
  check(s.mobility[77].flight and s.response.calls[#s.response.calls].payload.mods.flight,'Remote command must enable and replicate developer movement state')
  f.advance(.1);s.request.OnServerEvent:Fire(actor,{mode='move',direction=f.Vector3.new(0,1,0)})
  f.run.Heartbeat:Fire(.06);near(s.mobility[77].velocity.VectorVelocity.Y,AdminConfig.FlightSpeed,'Attached heartbeat drives flight with server speed limit')
  f.advance(1);s.request.OnServerEvent:Fire(actor,{mode='command',text='noclip on'})
  f.run.PreSimulation:Fire();check(not root.CanCollide,'Attached simulation callback applies noclip')
  s:onJoin(actor);f.advance(1);actor.Chatted:Fire('!op god on')
  check(s:isInvulnerable(actor),'Developer chat fallback must share authorized command dispatcher')
  actor.Chatted:Fire('ordinary chat');check(s:isInvulnerable(actor),'Ordinary chat must not execute commands')
  f.advance(1);actor.Chatted:Fire('!op cash self set 21')
  local pending=s.policy.pending[77];check(pending and ctx.core.players[77].cash==before,'Chat destructive command must require exact confirmation')
  f.advance(1);actor.Chatted:Fire('!op confirm '..pending.token)
  check(ctx.core.players[77].cash==21 and not s.policy.pending[77],'Chat confirmation must execute same protected command once')
  local o=ctx.core:setOffer('mod-auto-clear','item08',f.now(),55);ctx.core.players[77].cash=1000000
  check(ctx.core:purchaseAttempt(77,o.id,o.token,f.now()),'Auto-clear fixture must create real bid reservation')
  check(not s:isInvulnerable(actor)and not s:allowsMovement(actor),'Active mods become ineffective immediately when developer starts bidding')
  f.run.Heartbeat:Fire(.06)
  check(not s.mobility[77]and root.CanCollide and not h.PlatformStand and h.AutoRotate,'Next attached heartbeat must clear active flight, noclip and god mode on bidding')
  local last=s.response.calls[#s.response.calls]
  check(last.player==actor and last.payload.authorized and not last.payload.mods.flight and not last.payload.mods.god,'Automatic mod clear must synchronize private menu state')
  s:removePlayer(actor)
  groups.remoteIntegration=true
 end
 do
  local s,ctx,actor,_,root,h,command=fresh()
  check(command('speed 48').ok and command('jump 90').ok,'Physiology fixture must enable movement overrides')
  local rt=ctx.runtime[77]
  rt.slow=f.now()+10;h.WalkSpeed=8;h.JumpPower=40;s:applyMovement(actor,h)
  check(h.WalkSpeed==8 and h.JumpPower==90,'Existing slow effect must retain its movement speed while developer jump applies')
  rt.shockUntil=f.now()+10;h.WalkSpeed=0;h.JumpPower=0;s:applyMovement(actor,h)
  check(h.WalkSpeed==0 and h.JumpPower==0,'Developer movement update must not override a live stun')
  for _,raw in ipairs({'speed 64','jump 120','flight on','noclip on','god on'})do check(not command(raw).ok,'Stunned character must not capture invalid movement originals: '..raw)end
  rt.slow=0;rt.shockUntil=0;s:applyMovement(actor,h)
  check(h.WalkSpeed==48 and h.JumpPower==90,'Developer movement resumes after normal slow/stun state expires')
  check(command('resetmods').ok and h.WalkSpeed==16 and h.JumpPower==50,'Movement reset must restore pre-stun originals')
  check(command('flight on').ok and command('noclip on').ok and command('god on').ok,'Death fixture must enable combined mods');s:applyNoclip()
  h.Health=0
  check(not s:isInvulnerable(actor)and not s:allowsMovement(actor),'Dead character must lose developer immunity and movement bypass immediately')
  for _,raw in ipairs({'speed 32','jump 75','flight on','noclip on','god on','heal','powers','cooldowns','cast tag','home'})do check(not command(raw).ok,'Dead character must respawn before enabling mods: '..raw)end
  s:tick()
  check(not s.mobility[77]and root.CanCollide and not h.PlatformStand and h.AutoRotate and h.WalkSpeed==16 and h.JumpPower==50,'Tick must restore and clean mods when humanoid dies')
  h.Health=100;check(command('flight on').ok,'Missing-character fixture must enable flight')
  local velocity=s.mobility[77].velocity;local attachment=s.mobility[77].attachment
  actor.noBody=true;s:tick()
  check(not s.mobility[77]and velocity._destroyed and attachment._destroyed and root.ownershipRestored and not root.serverOwned and not h.PlatformStand and h.AutoRotate,'Flight cleanup must restore old root and humanoid even after body lookup becomes unavailable')
  groups.characterSafety=true
 end
 do
  local s,ctx,actor,_,_,h,command=fresh()
  local rt=ctx.runtime[77]
  check(command('jump 100').ok and h.JumpPower==100,'Stun-reset fixture must enable enhanced jump')
  rt.originalJump=h.JumpPower;rt.shockUntil=f.now()+10;h.JumpPower=0
  check(command('resetmods').ok,'Reset remains available during stun')
  check(h.JumpPower==0 and rt.originalJump==50,'Reset during stun must preserve zero jump and replace deferred developer jump with original normal value')
  f.advance(11)
  -- Match the production Server heartbeat's deferred jump restore exactly.
  if rt.originalJump then h.JumpPower=rt.originalJump;rt.originalJump=nil end
  check(h.JumpPower==50 and not s.mobility[77],'Stun expiry after reset must restore normal jump without reapplying old developer override')
  rt.originalJump=50;rt.shockUntil=f.now()-.01;h.JumpPower=0
  check(not command('speed 32').ok and not s.mobility[77],'Fresh mod must wait for deferred stun restore instead of capturing temporary zero jump')
  if rt.originalJump then h.JumpPower=rt.originalJump;rt.originalJump=nil end
  check(command('speed 32').ok and s.mobility[77].originalMovement.JumpPower==50,'Capture after server stun restore must retain actual original jump')
  check(command('resetmods').ok and h.JumpPower==50,'Reset after expired-stun capture must restore nonzero original jump')
  check(command('jump 100').ok,'New-character fixture must enable enhanced jump on old humanoid')
  rt.originalJump=100;rt.shockUntil=f.now()+10;h.JumpPower=0
  local temporary,_,newH=f.newPlayer(999);newH.JumpPower=61;newH.UseJumpPower=false
  actor.Character=temporary.Character;s:resetCharacter(actor)
  check(rt.originalJump==nil and newH.JumpPower==61 and newH.UseJumpPower==false,'Replacing character during stun must discard old deferred jump without overwriting new humanoid')
  local other,otherCtx,otherActor,_,_,oldHumanoid,otherCommand=fresh()
  check(otherCommand('jump 110').ok,'Destroyed-humanoid fixture must enable developer jump')
  local otherRt=otherCtx.runtime[77];otherRt.originalJump=110;otherRt.shockUntil=f.now()+10;oldHumanoid.JumpPower=0;oldHumanoid:Destroy()
  local replacement,_,replacementHumanoid=f.newPlayer(998);replacementHumanoid.JumpPower=62;otherActor.Character=replacement.Character
  other:resetCharacter(otherActor)
  check(otherRt.originalJump==nil and replacementHumanoid.JumpPower==62,'Destroyed saved humanoid must still clear stale deferred jump before a new rig appears')
  groups.stunRestoration=true
 end

 -- Version 75: gifts mutate the authoritative ledger only once per request.
 do
  local s,ctx,actor,outsider,root,h,command=fresh()
  local function gift(text,id,who)
   f.advance(1);commands+=1
   return s:dispatch(who or actor,{mode='command',text=text,requestId=id})
  end
  local originalCash=ctx.core.players[88].cash
  local r=gift('giftcash 88 2500','gift-cash-0001')
  check(r.ok and r.requestId=='gift-cash-0001' and ctx.core.players[88].cash==originalCash+2500,'Money gift must reach the exact online UserId and echo request ID')
  check(ctx.core.players[77].cash==1000000,'Developer gifts are created by the authorized tool, not deducted from developer cash')
  local replay=gift('giftcash 88 2500','gift-cash-0001')
  check(replay.ok and replay.duplicate and ctx.core.players[88].cash==originalCash+2500,'Repeated gift request must return its receipt without granting twice')
  check(not gift('giftcash self 2500','gift-cash-0001').ok and ctx.core.players[77].cash==1000000,'A receipt cannot be reused for a different target or command')
  check(gift('giftcash self 100','gift-self-0002').ok and ctx.core.players[77].cash==1000100,'Developer can gift themselves')
  check(not s:dispatch(actor,{mode='command',text='giftcash self 100'}).ok,'Gift without request ID must be rejected')
  for i,value in ipairs({'0','-1','0.5','nan','inf','2000000001'}) do
   local before=ctx.core.players[88].cash
   local bad=gift('giftcash 88 '..value,'bad-cash-'..i)
   check(not bad.ok and bad.requestId=='bad-cash-'..i and ctx.core.players[88].cash==before,'Malformed money gift must not mutate and must echo its request ID')
  end
  check(not gift('giftcash 999 10','gift-offline-01').ok,'Unknown online target must be rejected')
  ctx.runtime[88]=nil
  check(not gift('giftcash 88 10','gift-departed-01').ok and ctx.core.players[88].cash==originalCash+2500,'Player leaving the server must not receive a later gift')
  ctx.runtime[88]={player=outsider,base={}}
  local p=ctx.core.players[88]
  local offer=ctx.core:setOffer('gift-escrow','item01',f.now(),55)
  check(ctx.core:purchaseAttempt(88,'gift-escrow',offer.token,f.now()),'Escrow fixture must reserve a purchase')
  local held,uid,slot=p.held,p.pending,p.slots[2]
  check(gift('giftcash 88 321','gift-escrow-01').ok,'Gifting money while the target has escrow must be supported safely')
  check(p.held==held and p.pending==uid and p.slots[2]==slot,'Gift cannot overwrite target escrow, pending transaction or reserved inventory slot')
  p.cash=s.config.MaxCurrency-p.held-50
  check(not gift('giftcash 88 51','gift-cap-0001').ok and p.cash+p.held==s.config.MaxCurrency-50,'Gift beyond available currency headroom must reject atomically')
  check(gift('giftcash 88 50','gift-cap-0002').ok and p.cash+p.held==s.config.MaxCurrency,'Exact money cap must include reserved escrow')
  check(not gift('giftcash 88 1','gift-cap-0003').ok and p.cash+p.held==s.config.MaxCurrency,'Currency cap cannot overflow')
  local beforeLevels=ctx.core.players[77].progression
  check(gift('giftlevels self 5','gift-level-0001').ok,'Developer can gift themselves levels')
  check(ctx.core.players[77].progression==beforeLevels+5 and ctx.core.players[77].capacity==16,'Level gift must use the real core transition and unlock the second floor at five')
  check(gift('giftlevels self 5','gift-level-0001').duplicate and ctx.core.players[77].progression==5,'Duplicate level receipt must not add another five levels')
  check(gift('giftlevels 88 5','gift-level-0002').ok and p.progression==5 and p.capacity==16,'Other players can receive levels through the same authoritative transition')
  check(p.held==held and p.pending==uid and p.slots[2]==slot,'Capacity expansion must preserve in-flight purchase reservations')
  for i,value in ipairs({'0','-1','0.5','101','nan','inf'}) do
   local before=p.progression
   check(not gift('giftlevels 88 '..value,'bad-level-'..i).ok and p.progression==before,'Level amounts must be positive whole numbers at most one hundred')
  end
  p.progression=999;p.level=999
  check(not gift('giftlevels 88 2','gift-maxlevel-01').ok and p.progression==999,'A grant crossing the total level cap must reject completely')
  check(gift('giftlevels 88 1','gift-maxlevel-02').ok and p.progression==1000,'A grant exactly reaching the level cap must succeed')
  check(not gift('giftlevels 88 1','gift-maxlevel-03').ok and p.progression==1000,'No levels can be granted beyond one thousand')
  for i,text in ipairs({'giftcash self 1','giftlevels self 1','royalseal'}) do
   local beforeCash,beforeLevel=ctx.core.players[88].cash,p.progression
   f.advance(2.1);local denied=gift(text,'outsider-new-'..i,outsider)
   check(denied and denied.authorized==false and not denied.ok,'Non-developers must be denied every new command')
   check(ctx.core.players[88].cash==beforeCash and p.progression==beforeLevel,'Denied new commands must have no ledger effects')
  end
  local menu=s:menuData(actor)
  check(#menu.players==2 and menu.players[1].userId~=nil and menu.players[1].name~=nil and menu.players[1].displayName~=nil,'Menu player choices must use actual online identity metadata')
  check(menu.uniquePower.id=='royalseal' and menu.uniquePower.cooldown==15,'Unique power metadata must expose the correct developer ability and cooldown')
  groups.gifts=true
 end
 do
  local s,ctx,actor,_,root,_,command=fresh()
  ctx.uniqueCasts={}
  ctx.castDeveloperPower=function(player,origin)
   table.insert(ctx.uniqueCasts,{player=player,origin=origin})
   return not ctx.rejectRoyal,'Royal Seal routed.'
  end
  local first=command('royalseal')
  check(first.ok and #ctx.uniqueCasts==1 and ctx.uniqueCasts[1].player==actor,'Royal Seal command must call the trusted server context only for the developer')
  check(first.mods.royalSealRemaining==15 and s:menuData(actor).uniquePower.remaining==15,'Server response must expose the authoritative fifteen-second cooldown')
  check(not command('royalseal',nil,true).ok and #ctx.uniqueCasts==1,'Royal Seal cannot be spammed during cooldown')
  check(command('cooldowns').ok and not command('royalseal',nil,true).ok,'Normal power cooldown reset must not bypass the unique developer cooldown')
  f.advance(15)
  check(command('royalseal',nil,true).ok and #ctx.uniqueCasts==2,'Royal Seal must recharge after the complete server interval')
  f.advance(16);ctx.rejectRoyal=true
  check(not command('royalseal',nil,true).ok and s.royalReady[77]==nil,'Rejected unique cast must release its provisional cooldown')
  ctx.rejectRoyal=false
  local state=ctx.core.players[77]
  for _,key in ipairs({'carry','pending'}) do
   state[key]='reserved'
   check(not command('royalseal').ok,'Unique power must reject carrying and bidding')
   state[key]=nil
  end
  local rt=ctx.runtime[77];rt.shockUntil=f.now()+5
  check(not command('royalseal',nil,true).ok,'Unique power must reject a stunned developer')
  rt.shockUntil=0;rt.interruptedUntil=f.now()+5
  check(not command('royalseal',nil,true).ok,'Unique power must reject an interrupted developer')
  rt.interruptedUntil=0
  check(command('royalseal',nil,true).ok,'Unique power remains usable after restrictions clear')
  groups.royalSeal=true
 end
 do
  local s,ctx,actor,_,root,_,command=fresh()
  local events={protected={},clears=0,rods=0,failedRods=0,ticks=0}
  s.artifacts={
   setProtected=function(_,player,enabled)check(player==actor,'Cosmetic protection must target authorized character');table.insert(events.protected,enabled)end,
   clear=function(_,player)events.clears+=1 end,
   pulseRod=function(_,player)events.rods+=1;return f.Vector3.new(7,9,11)end,
   clearRod=function()events.failedRods+=1 end,
   tick=function()events.ticks+=1 end,
  }
  check(command('god on').ok and events.protected[#events.protected]==true,'Enabling immunity must immediately equip the protection emblem')
  check(command('god off').ok and events.protected[#events.protected]==false,'Disabling immunity must immediately remove its protection emblem')
  check(command('powers').ok,'Artifact fixture must unlock normal powers')
  ctx.castPower=function(player,id,origin)
   check(origin.X==7 and origin.Y==9 and origin.Z==11,'Developer power visual origin must come from the server-created Rod tip')
   if id=='shield' then local rt=ctx.runtime[player.UserId];rt.shield=f.now()+3;rt.shieldHits=1 end
   return not ctx.rejectPower,'Routed from Rod.'
  end
  check(command('cast shield').ok and events.rods==1 and events.protected[#events.protected]==true,'Developer shield must cast from Rod and show protected Puzzle')
  f.advance(3.1);s:tick()
  check(events.protected[#events.protected]==false and not s.developerShields[77],'Shield expiry must remove protection emblem')
  check(command('cast shield').ok,'Shield can be cast again in artifact adapter fixture')
  ctx.runtime[77].shieldHits=0;s:tick()
  check(events.protected[#events.protected]==false,'Consumed shield must remove protection emblem before its expiry')
  ctx.rejectPower=true
  check(not command('cast tag').ok and events.failedRods==1,'Failed normal cast must clear the temporary Rod')
  ctx.rejectPower=false
  ctx.castDeveloperPower=function(player,origin)check(origin.Z==11,'Unique power must share the server Rod origin');return true end
  check(command('royalseal').ok and events.rods>=4,'Unique developer cast must display the Rod')
  check(command('god on').ok,'Carry cleanup fixture must enable protection')
  ctx.core.players[77].carry='reserved';local before=events.clears;s:tick()
  check(events.clears>before and not s.mobility[77],'Entering a carry must clear developer cosmetics and movement')
  ctx.core.players[77].carry=nil
  check(command('god on').ok,'Reset cleanup fixture must enable protection')
  before=events.clears;check(command('resetmods').ok and events.clears>before,'Reset mods must remove protection and casting cosmetics')
  check(command('god on').ok,'Revocation cleanup fixture must enable protection')
  s.config.Enabled=false;before=events.clears;s:tick()
  check(events.clears>before and not s.mobility[77],'Authorization revocation must clear developer artifacts')
  s.config.Enabled=true
  for _,restriction in ipairs({'carry','pending'}) do
   check(command('cast shield').ok and s.mobility[77]==nil,'Shield-only cleanup fixture must avoid creating a mobility record')
   ctx.core.players[77][restriction]='reserved'
   before=events.clears;s:tick()
   check(events.clears>before and not s.developerShields[77] and ctx.runtime[77].shield==0 and ctx.runtime[77].shieldHits==0,'Shield-only carry or bid transition must remove protection and its emblem together')
   ctx.core.players[77][restriction]=nil
  end
  check(command('cast shield').ok,'Shield-only authorization fixture must activate protection')
  s.config.Enabled=false;before=events.clears;s:tick()
  check(events.clears>before and not s.developerShields[77] and ctx.runtime[77].shield==0,'Revocation must remove shield-only protection without needing a mobility record')
  groups.artifactLifecycle=true
 end

 do
  local s,ctx,actor,outsider,root,h,command=fresh()
  check(not s:getState(actor).developerMode and not s:isDeveloperMode(actor),'Developer mode must start disabled even for the account owner')
  check(not command('triplejump').ok and not s.mobility[77],'Triple-jump shortcut must not activate before developer mode')
  for _,bad in ipairs({'devmode','devmode true','devmode ON','devmode on extra','triplejump on'}) do
   check(not command(bad).ok,'Developer mode shortcuts require exact validated syntax: '..bad)
  end
  local enabled=command('devmode on')
  check(enabled.ok and enabled.mods.developerMode and s:isDeveloperMode(actor),'Only a trusted enabled mode may expose the fourth ability')
  check(not s:isDeveloperMode(outsider) and not s:getState(outsider).developerMode,'Mode state must not be shared to other accounts')
  local heading=f.Vector3.new(3,2,-4)
  root.CFrame=f.CFrame.lookAt(root.Position,root.Position+heading)
  root.AssemblyAngularVelocity=f.Vector3.new(25,17,-8)
  check(command('triplejump').ok and s.mobility[77].flight,'Trusted jump shortcut must enable flight')
  near(root.AssemblyAngularVelocity.Magnitude,0,'Flight activation removes angular inertia')
  near(root.CFrame.LookVector.Y,0,'Flight remains upright despite pitched starting look direction')
  near(root.CFrame.LookVector.X,.6,'Fixed upright flight preserves starting horizontal facing X')
  near(root.CFrame.LookVector.Z,-.8,'Fixed upright flight preserves starting horizontal facing Z')
  for _,child in ipairs(root:GetChildren()) do
   check(child.ClassName~='BodyGyro' and child.ClassName~='AlignOrientation' and child.ClassName~='AngularVelocity','Flight must not add rotational actuators')
  end
  local captured=s.mobility[77].flightFacing
  root.CFrame=f.CFrame.lookAt(root.Position,root.Position+f.Vector3.new(-1,5,1))
  root.AssemblyAngularVelocity=f.Vector3.new(5,8,2)
  s:applyNoclip()
  near(root.AssemblyAngularVelocity.Magnitude,0,'Every pre-physics pass removes new spin')
  near((root.CFrame.LookVector-captured).Magnitude,0,'Every pre-physics pass restores the fixed upright heading')
  root.AssemblyAngularVelocity=f.Vector3.new(6,3,9);s:tick()
  near(root.AssemblyAngularVelocity.Magnitude,0,'Movement tick also removes new spin')
  check(command('flight off').ok and s:getState(actor).developerMode,'Landing should preserve deliberate developer mode')
  check(command('devmode off').ok and not s:isDeveloperMode(actor) and not s.mobility[77],'Turning mode off must clear shortcuts and movement mods')
  for _,blocked in ipairs({'carry','pending'}) do
   check(command('devmode on').ok,'Mode should enable before a gameplay transition')
   ctx.core.players[77][blocked]='reserved'
   check(not s:isDeveloperMode(actor) and not s:getState(actor).developerMode,'Carry/bid restrictions immediately hide fourth ability without trusting a client')
   check(not command('triplejump').ok and not command('devmode on').ok,'Carry/bid restrictions must block both shortcut and reactivation')
   s:tick();check(not s.developerModes[77],'Tick must discard mode state after a carry or bid')
   ctx.core.players[77][blocked]=nil
   check(not s:isDeveloperMode(actor),'A completed carry must not silently restore developer mode')
  end
  check(command('devmode on').ok,'Death cleanup fixture enables mode')
  h.Health=0;s:tick();check(not s.developerModes[77] and not s:getState(actor).developerMode,'Death clears developer mode')
  h.Health=100;check(command('devmode on').ok,'Revocation cleanup fixture enables mode')
  s.config.Enabled=false;s:tick()
  check(not s.developerModes[77] and not s:isDeveloperMode(actor),'Identity revocation must clear developer mode')
  s.config.Enabled=true;check(command('devmode on').ok,'Player removal fixture enables mode')
  s:removePlayer(actor);check(not s.developerModes[77],'Leaving clears private developer mode')
  groups.developerModeAndStableFlight=true
 end

 local names={};for name in pairs(groups)do table.insert(names,name)end;table.sort(names)
 for _,name in ipairs(names)do print('ADMIN GROUP PASS '..name)end
 return tostring(checks)..' assertions; '..commands..' actual remote commands; '..#names..' groups'
end
