-- Execute actual PhaseService/Core/PowerRules with controlled Roblox API doubles.
-- These checks verify server control flow, not live rendering or engine physics.
return function(package,require,setGlobals)
 local assertions=0;local groups={}
 local function check(value,message) assertions+=1;assert(value,message or 'Power check failed') end
 local function near(a,b,message) check(math.abs(a-b)<.00001,(message or 'Values differ')..': '..tostring(a)..' / '..tostring(b)) end
 local function group(name) groups[#groups+1]=name end
 local Vector={};local vectorMeta={}
 function Vector.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,__vector=true},vectorMeta) end
 function vectorMeta.__index(a,key)
  if key=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
  if key=='Unit' then return a/a.Magnitude end
  if key=='Dot' then return function(v,b)return v.X*b.X+v.Y*b.Y+v.Z*b.Z end end
 end
 function vectorMeta.__add(a,b)return Vector.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
 function vectorMeta.__sub(a,b)return Vector.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
 function vectorMeta.__unm(a)return Vector.new(-a.X,-a.Y,-a.Z) end
 function vectorMeta.__mul(a,b) if type(a)=='number' then a,b=b,a end;return Vector.new(a.X*b,a.Y*b,a.Z*b) end
 function vectorMeta.__div(a,b)return Vector.new(a.X/b,a.Y/b,a.Z/b) end
 Vector.zero=Vector.new();Vector.xAxis=Vector.new(1,0,0)
 local Frame={};local frameMeta={}
 function Frame.new(x,y,z)
  local pos=type(x)=='table' and x or Vector.new(x,y,z)
  return setmetatable({Position=pos,LookVector=Vector.new(0,0,-1)},frameMeta)
 end
 function frameMeta.__add(a,b)local cf=Frame.new(a.Position+b);cf.LookVector=a.LookVector;return cf end
 function frameMeta.__index(a,key)
  if key=='PointToObjectSpace' then return function(cf,pos)return pos-cf.Position end end
 end
 local clock=100;local scheduled={};local active
 local function queue(delay,fn) scheduled[#scheduled+1]={time=clock+delay,fn=fn} end
 local function advance(seconds)
  local endAt=clock+seconds
  while true do
   table.sort(scheduled,function(a,b)return a.time<b.time end)
   if not scheduled[1] or scheduled[1].time>endAt then break end
   local event=table.remove(scheduled,1);clock=math.max(clock,event.time);event.fn()
  end
  clock=math.max(clock,endAt)
 end
 local heartbeat={}
 function heartbeat:Connect(fn)return {Disconnect=function()end} end
 function heartbeat:Wait() clock+=.05;return .05 end
 local players={}
 function players:GetPlayers()return active and {active.p1,active.p2} or {} end
 local run={Heartbeat=heartbeat};local space={}
 function space:GetServerTimeNow()return clock+1000 end
 function space:Blockcast(cf,size,delta,params)
  active.casts[#active.casts+1]={cf=cf,size=size,delta=delta,params=params}
  local wall=active.wall;if not wall then return nil end
  -- Controlled AABB sweep double: production code determines dimensions,
  -- directions, collision filtering, clearance and repeated sweep timing.
  local start=cf.Position;local enter,leave=0,1
  for _,axis in ipairs({'X','Y','Z'}) do
   local lo=wall.center[axis]-(wall.size[axis]+size[axis])/2
   local hi=wall.center[axis]+(wall.size[axis]+size[axis])/2
   if math.abs(delta[axis])<.000001 then
    if start[axis]<lo or start[axis]>hi then return nil end
   else
    local t1=(lo-start[axis])/delta[axis];local t2=(hi-start[axis])/delta[axis]
    enter=math.max(enter,math.min(t1,t2));leave=math.min(leave,math.max(t1,t2))
   end
  end
  if enter<=leave and enter>=0 and enter<=1 then return {Distance=delta.Magnitude*enter} end
  return nil
 end
 local osMock=table.clone(os);osMock.clock=function()return clock end
 setGlobals({
  Vector3=Vector,CFrame=Frame,workspace=space,os=osMock,
  typeof=function(v)return type(v)=='table' and v.__vector and 'Vector3' or type(v) end,
  Color3={fromRGB=function(...)return {...} end},
  Enum={RaycastFilterType={Exclude='Exclude'},CreatorType={User='User',Group='Group'}},RaycastParams={new=function()return {} end},
  task={delay=queue,spawn=function(fn)queue(0,fn)end},
  game={CreatorType='User',CreatorId=101,GetService=function(_,name)
   if name=='Players' then return players elseif name=='RunService' then return run end
   return {}
  end},
 })
 local S=require(package.PhaseService);local Core=require(package.Core);local Catalog=require(package.Catalog)
 local Powers=require(package.PowerCatalog);local Rules=require(package.PhaseConfig);local Config=require(package.Config)
 local keys={'tag','dash','gravity','slow','slam','repulse','shield','lightning'}
 local offensive={'tag','gravity','slow','slam','repulse','lightning'}
 check(#Powers.Items==8,'Exactly eight powers remain')
 for _,key in ipairs(keys)do check(Powers.ById[key]~=nil,'Missing power '..key)end
 local function rootAt(pos)
  local properties={cf=Frame.new(pos),Parent=true,Anchored=false,AssemblyLinearVelocity=Vector.new()}
  return setmetatable({}, {
   __index=function(_,key)
    if key=='CFrame' then return properties.cf elseif key=='Position' then return properties.cf.Position end
    if key=='IsDescendantOf' then return function()return true end end
    return properties[key]
   end,
   __newindex=function(_,key,value)
    if key=='CFrame' then properties.cf=value elseif key=='Position' then properties.cf=Frame.new(value) else properties[key]=value end
   end,
  })
 end
 local function fixture(key)
  clock=100;scheduled={}
  local f={effects={},messages={},casts={},bodies={},runtime={},config=table.clone(Config),safe=true,visible=true,god={},bodyCalls=0}
  active=f;f.core=Core.new(Catalog,f.config)
  local function participant(id,pos)
   local p={UserId=id,DisplayName='Tester'..id,Parent=true,Character={},attributes={}}
   function p:SetAttribute(name,value)self.attributes[name]=value end
   local root=rootAt(pos);local hum={WalkSpeed=16,Health=100}
   local base={owner=id,cf=Frame.new(0,0,100),slots={},upgrade=Frame.new(0,0,100)}
   for i=1,8 do base.slots[i]=Frame.new(i*2,3,100) end
   f.runtime[id]={player=p,base=base,shield=0,slow=0,immune=0,tagImmune=0}
   f.bodies[p]={root,hum};local state=f.core:addPlayer(id,clock)
   state.cash=10000000;state.powerSlots=3;state.powerOwned={tag=true}
   for _,idKey in ipairs(keys)do state.powerOwned[idKey]=true end
   state.loadout={'tag',key or 'shield'}
   return p,root,hum
  end
  f.p1,f.r1,f.h1=participant(101,Vector.new(0,4,0));f.p2,f.r2,f.h2=participant(102,Vector.new(0,4,-5))
  f.ctx={core=f.core,config=f.config,runtime=f.runtime,catalog=Catalog,world={bases={}},
   body=function(p) f.bodyCalls+=1;local b=f.bodies[p];if b then return b[1],b[2] end end,
   movementSafe=function()return f.safe end,los=function()return f.visible end,
   refresh=function()f.refreshes=(f.refreshes or 0)+1 end,
   say=function(_,msg)f.messages[#f.messages+1]=msg end,
   isDeveloperInvulnerable=function(p)return f.god[p.UserId] or false end,
   fx={FireAllClients=function(_,...)f.effects[#f.effects+1]={...}end},
  }
  f.service=S.new(f.ctx);f.service.nextSpawn=math.huge
  -- Rendering is outside these checks. All cast/hit/step gameplay remains real.
  f.service.syncVisuals=function()end
  function f:advance(dt)advance(dt)end
  function f:step(dt)advance(dt);self.service:step(dt)end
  function f:effectCount(kind)local n=0;for _,event in ipairs(self.effects)do if event[1]==kind then n+=1 end end;return n end
  function f:preparePurchase(p,carry,immediatePickup)
   local before=self.core.players[p.UserId].cash
   local offer=self.core:setOffer('purchase'..p.UserId,'item05',clock,70)
   check(self.core:purchaseAttempt(p.UserId,offer.id,offer.token,clock),'Real reservation succeeds')
   if carry then
    if immediatePickup then self.core:pickup(offer,self.core.transactions[self.core.players[p.UserId].pending],clock)
    else self:advance(1.6);self.core:advance(clock) end
    check(self.core.players[p.UserId].carry==offer.uid,'Real pickup succeeds')
   end
   return offer,before
  end
  function f:cast(idKey)return self.service:cast(self.p1,{id=idKey,aim=Vector.new(0,0,-1)})end
  return f
 end
 local function targetPosition(f,key)
  if key=='slow' then f.r2.Position=Vector.new(0,4,-Powers.ById.slow.range*.65)
  elseif key=='lightning' then f.r2.Position=Vector.new(0,4,-Powers.ById.lightning.range*.65) end
 end
 for _,key in ipairs(keys)do
  local f=fixture(key);local d=Powers.ById[key];targetPosition(f,key)
  local offer,before
  if key~='dash' and key~='shield' then offer,before=f:preparePurchase(f.p2,true) end
  local castAt=clock;local accepted,returnedKey=f:cast(key)
  check(accepted==true and returnedKey==key,key..' reports accepted server cast to developer tool')
  near(f.core.players[101].powerReady[key],castAt+d.cooldown,key..' server cooldown')
  check(f:effectCount(key)>0,key..' visible cast signal emitted')
  local fx=#f.effects;local repeated,message=f:cast(key)
  check(repeated==false and type(message)=='string',key..' rejected cast returns explanation')
  check(#f.effects==fx,key..' repeated cast blocked')
  if d.windup>0 then
   check(not f.runtime[102].castSerial,key..' effect waits for warning')
   f:advance(d.windup+.01)
  else f:advance(.3) end
  if key=='dash' then
   check(f.r1.Position.Z<0 and f.r1.Position.Z>=-10.001,'Dash moves bounded distance')
   check(#f.casts>1,'Dash checks swept character repeatedly')
   for _,cast in ipairs(f.casts)do
    check(cast.params.RespectCanCollide==true,'Dash respects solid geometry')
    check(cast.params.FilterType=='Exclude' and #cast.params.FilterDescendantsInstances==2,'Dash excludes character bodies')
   end
  elseif key=='shield' then
   check(f.runtime[101].shieldHits==1,'Shield has one hit')
   near(f.runtime[101].shield,castAt+d.duration,'Shield duration')
   near(f.p1.attributes.OPShieldUntil,1000+castAt+d.duration,'Shield replication timestamp')
  else
   if key=='slow' then f:step(.01) end
   check(f.runtime[102].castSerial==1,key..' interrupts current action')
   if d.dislodge then
    check(not f.core.players[102].carry,key..' drops purchased loot')
    check(f.core.players[102].cash==before and f.core.players[102].held==0,key..' refunds escrow once')
    check(f.core.items[offer.uid].state=='Conveyor' and f.core.offers[offer.id].uid==offer.uid,key..' returns same collectible')
    near(f.core.offers[offer.id].x,70,key..' returns to original pickup position')
   else check(f.core.players[102].carry==offer.uid,key..' preserves carried loot') end
   if d.slow then check(f.runtime[102].slow>clock,'Slow applies bounded timer') end
   if d.stun then
    check(f.r2.Anchored and f.runtime[102].shockRoot==f.r2,'Lightning anchors correct body temporarily')
    check(f.runtime[102].shockUntil<=clock+Rules.MaxStun,'Lightning bounded by MaxStun')
    near(f.r2.AssemblyLinearVelocity.Magnitude,0,'Lightning stops momentum')
   end
   if d.force>0 then
    near(math.abs(f.r2.AssemblyLinearVelocity.Z),d.force,key..' horizontal impulse')
    near(f.r2.AssemblyLinearVelocity.Y,7,key..' vertical impulse')
    check((f.r2.AssemblyLinearVelocity.Z>0)==(d.pull==true),key..' pull/push direction')
   end
  end
 end
 group('All eight real casts: warnings, effects, bounded timings, cooldowns, escrow and knockback')
 for _,key in ipairs(keys)do
  for _,mode in ipairs({'carry','pending'})do
   local f=fixture(key);f:preparePurchase(f.p1,mode=='carry');local before=f.core.revision
   local accepted,message=f:cast(key);f:advance(2)
   check(accepted==false and type(message)=='string',key..' blocked '..mode..' reports reason')
   check(#f.effects==0 and (f.core.players[101].powerReady[key] or 0)==0,key..' disabled while '..mode)
   check(f.core.revision==before,key..' blocked cast changes no session state')
  end
  local f=fixture(key);f.core.players[101].powerOwned[key]=nil
  if key~='tag' then f:cast(key);check(#f.effects==0,key..' unowned rejected') end
  f=fixture(key);if key~='tag' then f.core.players[101].loadout={'tag'};f:cast(key);check(#f.effects==0,key..' unequipped rejected') end
  f=fixture(key);f.core.players[101].powerReady[key]=clock+10;f:cast(key);check(#f.effects==0,key..' cooldown rejected')
 end
 group('Every power enforces carrying, bidding, ownership, loadout and server cooldown gates')
 local invalid={string.rep('x',25),{},27,{id='tag',aim=Vector.new(0,0,0)},{id='tag',aim=Vector.new(2,0,0)},
  {id='tag',aim=Vector.new(math.huge,0,0)},{id='tag',aim=Vector.new(0/0,0,0)},{id='tag',aim={X=0,Y=0,Z=-1}},
  {id=11,aim=Vector.new(0,0,-1)}}
 for index,arg in ipairs(invalid)do
  local f=fixture('tag');local accepted,message=f.service:cast(f.p1,arg);f:advance(2)
  -- Omitted/unknown top-level argument selects the equipped default by design.
  if index==1 or index>=4 then
   check(#f.effects==0 and accepted==false and type(message)=='string','Malformed aim/id rejected '..index)
  else check(accepted==true and message=='tag','Omitted ID keeps existing default behavior '..index) end
 end
 for _,reason in ipairs({'movement','disabled','shock','interrupt','body','runtime'})do
  local f=fixture('tag')
  if reason=='movement' then f.safe=false elseif reason=='disabled' then f.config.EnablePowers=false
  elseif reason=='shock' then f.runtime[101].shockUntil=clock+1 elseif reason=='interrupt' then f.runtime[101].interruptedUntil=clock+1
  elseif reason=='body' then f.bodies[f.p1]=nil else f.runtime[101]=nil end
  f:cast('tag');check(#f.effects==0,'Cast gate '..reason)
 end
 group('Malformed remote aim/id and unavailable-character, movement, shock and interruption gates')
 for _,key in ipairs(keys)do
  local f=fixture(key);local d=Powers.ById[key];check(f:cast(key)==true,key..' first cast accepted')
  f:advance(d.cooldown-.001);local effects=#f.effects
  check(f:cast(key)==false and #f.effects==effects,key..' cooldown last millisecond rejected')
  f:advance(.002)
  check(f:cast(key)==true,key..' cooldown boundary permits next cast')
 end
 group('Every cooldown rejects just before expiry and accepts just after expiry')
 for _,key in ipairs(offensive)do
  for _,reason in ipairs({'serial','moved','carry','pending','shock','body','runtime'})do
   local f=fixture(key);targetPosition(f,key);f:cast(key)
   if reason=='serial' then f.service:interrupt(f.p1,false)
   elseif reason=='moved' then f.r1.Position=Vector.new(8,4,0)
   elseif reason=='carry' then f:preparePurchase(f.p1,true,true)
   elseif reason=='pending' then f:preparePurchase(f.p1,false)
   elseif reason=='shock' then f.runtime[101].shockUntil=clock+5
   elseif reason=='body' then f.bodies[f.p1]=nil
   else f.runtime[101]=table.clone(f.runtime[101]) end
   f:advance(2)
   check(not f.runtime[102].castSerial,key..' windup cancelled by '..reason)
   check(#f.service.fields==0,key..' no delayed field after '..reason)
  end
 end
 group('All offensive windups cancel on interruption, movement, carry/bid, stun, lost body and runtime replacement')
 for _,key in ipairs(offensive)do
  for _,reason in ipairs({'range','occluded'})do
   local f=fixture(key);targetPosition(f,key)
   if reason=='range' then f.r2.Position=Vector.new(0,4,-100) else f.visible=false end
   f:cast(key);f:advance(2);if key=='slow' then f:step(.01) end
   check(not f.runtime[102].castSerial,key..' rejects '..reason..' target')
  end
 end
 for _,pos in ipairs({Vector.new(0,4,5),Vector.new(5,4,0)})do
  local f=fixture('tag');f.r2.Position=pos;f:cast('tag');f:advance(.2)
  check(not f.runtime[102].castSerial,'Tag cone excludes behind/side targets')
 end
 for _,key in ipairs({'lightning','slow'})do
  local f=fixture(key);f.r2.Position=Vector.new(0,4,-1);f:cast(key);f:advance(2);if key=='slow'then f:step(.01)end
  check(not f.runtime[102].castSerial,key..' requires marked field occupancy')
 end
 group('Actual targeting respects ranges, Tag cone, marked fields and line of sight')
 for _,key in ipairs(offensive)do
  local f=fixture(key);targetPosition(f,key);local rt=f.runtime[102]
  rt.shield=clock+3;rt.shieldHits=1
  f:cast(key);f:advance(Powers.ById[key].windup+.01);if key=='slow'then f:step(.01)end
  check(rt.shield==0 and rt.shieldHits==0,key..' consumes exactly one shield hit')
  check(not rt.castSerial and rt.immune==0 and rt.tagImmune==0,key..' blocked before interrupt/immunity')
  check(f:effectCount('shieldBreak')==1,key..' shield break visible once')
  f.service:hitPower(101,rt,key,f.r1.Position,clock)
  check(rt.castSerial==1,key..' second hit reaches unshielded target')
  local serial=rt.castSerial;local timer=key=='tag' and rt.tagImmune or rt.immune
  f.service:hitPower(101,rt,key,f.r1.Position,clock+.1)
  check(rt.castSerial==serial,key..' repeated hit blocked by immunity')
  near(timer,clock+(key=='tag' and 2 or Rules.PowerImmunity),key..' immunity duration')
 end
 local f=fixture('lightning');local rt=f.runtime[102]
 f.service:hitPower(101,rt,'lightning',f.r1.Position,clock)
 local untilTime=rt.shockUntil
 f.service:hitPower(101,rt,'repulse',f.r1.Position,clock+.1)
 check(rt.castSerial==1 and rt.shockUntil==untilTime,'Non-Tag powers share immunity')
 f.service:hitPower(101,rt,'tag',f.r1.Position,clock+.1)
 check(rt.castSerial==2,'Tag has separate immunity window')
 f:step(1);check(not f.r2.Anchored and not rt.shockRoot,'Step restores temporarily anchored body')
 f=fixture('lightning');rt=f.runtime[102];f.r2.Anchored=true
 f.service:hitPower(101,rt,'lightning',f.r1.Position,clock);f:step(1)
 check(f.r2.Anchored and not rt.shockRoot,'Step preserves prior anchored state')
 f=fixture('lightning');rt=f.runtime[102];f.service:hitPower(101,rt,'lightning',f.r1.Position,clock)
 f.service:cancelPlayer(f.p2);check(not f.r2.Anchored and not rt.shockRoot and rt.shockUntil==0,'Reset cancels active stun safely')
 f=fixture('shield');f:cast('shield');f:advance(Powers.ById.shield.duration+.001)
 f.service:hitPower(102,f.runtime[101],'tag',f.r2.Position,clock)
 check(f.runtime[101].castSerial==2 and f:effectCount('shieldBreak')==0,'Expired shield no longer blocks hits')
 group('Every incoming power consumes one shield; shared/Tag immunity and stun cleanup are enforced')
 f=fixture('slow');targetPosition(f,'slow');f:cast('slow');f:advance(.7);check(#f.service.fields==1,'Slow field created once')
 local field=f.service.fields[1];f:step(.1);local slowUntil=f.runtime[102].slow
 near(slowUntil,field.expires,'Field slow cannot extend beyond field expiry')
 f:step(.2);near(f.runtime[102].slow,slowUntil,'Remaining in field cannot refresh slow')
 f:step(3);check(#f.service.fields==0,'Expired field removed')
 f=fixture('slow');f.r2.Position=Vector.new(0,4,30);f:cast('slow');f:advance(.7);f:step(.1)
 check(not f.runtime[102].castSerial,'Outside field initially unharmed')
 targetPosition(f,'slow');f:step(.1);check(f.runtime[102].castSerial==1,'Entering existing field applies effect once')
 group('Slow fields affect later entrants once and expire without indefinitely extending slow')
 f=fixture('dash');f.wall={center=Vector.new(0,4,-4),size=Vector.new(12,10,1)};f:cast('dash');f:advance(.4)
 check(#f.casts==1,'Dash stops first time sweep reports obstruction')
 near(f.r1.Position.Z,-1.95,'Dash leaves clearance before expanded wall')
 check(f.r1.Position.Z>f.wall.center.Z+1.7,'Dash character does not cross mock solid wall')
 group('Dash uses swept volume and stops with wall clearance in controlled collision test')
 f=fixture('tag');local owner=f.core.players[101];owner.lockUntil=0
 local uid=owner.slots[1];check(f.core:beginSteal(102,uid,clock),'Actual theft begins')
 f.service:hitPower(101,f.runtime[102],'tag',f.r1.Position,clock)
 check(not f.core.players[102].carry and f.core.items[uid].owner==101 and f.core.items[uid].state=='Stored','Tag restores stolen item to original owner')
 check(owner.slots[1]==uid and f.core.players[102].held==0,'Theft cancellation preserves slot and escrow')
 group('Actual theft interruption restores stored ownership and releases reservation')
 for _,key in ipairs(offensive)do
  f=fixture(key);targetPosition(f,key);rt=f.runtime[102]
  rt.shield=clock+10;rt.shieldHits=1;f.god[102]=true
  f.service.holds[102]={sentinel=true};local serial=rt.castSerial;local before=f.core.revision;local effects=#f.effects;local bodyCalls=f.bodyCalls
  f.service:hitPower(101,rt,key,f.r1.Position,clock)
  check(rt.castSerial==serial and f.service.holds[102].sentinel,key..' developer guard preserves hold/cast')
  check(f.core.revision==before and #f.effects==effects,key..' developer guard has no state/FX side effects')
  check(rt.shieldHits==1 and rt.shield>clock and rt.immune==0 and rt.tagImmune==0,key..' developer guard precedes shield/immunity')
  check(f.bodyCalls==bodyCalls,key..' developer guard runs before body lookup')
  check(not rt.shockRoot and (not rt.slow or rt.slow==0),key..' developer guard blocks control effects')
  f.god[102]=false;f.service:hitPower(101,rt,key,f.r1.Position,clock)
  check(rt.shieldHits==0 and f:effectCount('shieldBreak')==1,key..' normal hit gate restored after developer immunity off')
 end
 group('Developer invulnerability precedes all body lookup, shield, immunity, interrupt, drop and FX logic')
 local Admin=require(package.AdminService);local AdminConfig=require(package.AdminConfig);local Royal=require(package.DeveloperPowers)
 local function attachAdmin(f)
  local config=table.clone(AdminConfig)
  config.DeveloperUserId=101;config.DeveloperUsername='';config.CommandBurst=100;config.CommandsPerSecond=100
  local context=table.clone(f.ctx);context.clock=function()return clock end;context.nonce=function()return 'power-test-confirmation' end
  context.castPower=function(p,kind,rodOrigin)return f.service:cast(p,kind,rodOrigin)end
  context.castDeveloperPower=function(p,rodOrigin)return Royal.cast(f.service,f.admin,p,rodOrigin)end
  f.admin=Admin.new(config,context)
  f.ctx.isDeveloperInvulnerable=function(p)return f.admin:isInvulnerable(p)end
  function f:command(text,actor)return self.admin:dispatch(actor or self.p1,{mode='command',text=text})end
 end
 for _,key in ipairs(keys)do
  f=fixture(key);attachAdmin(f);targetPosition(f,key)
  local state=f.core.players[101];state.powerOwned={tag=true};state.powerSlots=2;state.loadout={'tag'}
  local unlocked=f:command('powers')
  check(unlocked.ok==true and state.powerSlots==3 and state.loadout[1]=='tag','Actual developer unlock retains Tag and three slots')
  for _,powerKey in ipairs(keys)do check(state.powerOwned[powerKey]==true,'Actual developer unlock owns '..powerKey)end
  local returned=f:command('cast '..key)
  check(returned.ok==true and f:effectCount(key)==1,'Developer command routes to real '..key..' cast')
  check(state.powerReady[key]>clock,'Developer real cast consumes ordinary '..key..' cooldown')
  returned=f:command('cast '..key)
  check(returned.ok==false and type(returned.message)=='string','Developer receives real '..key..' recovery rejection')
  f:advance(math.max(.35,Powers.ById[key].windup+.01))
  returned=f:command('cooldowns')
  check(returned.ok==true and next(state.powerReady)==nil and state.castReady==0,'Actual developer cooldown reset clears session gates')
  returned=f:command('cast '..key)
  check(returned.ok==true,'Developer reset permits actual '..key..' cast again')
 end
 group('Actual developer dispatch unlocks, equips and casts all eight real powers; cooldown reset and return values integrate')
 f=fixture('tag');attachAdmin(f);rt=f.runtime[101]
 check(f:command('god on').ok==true and f.admin:isInvulnerable(f.p1),'Actual developer god command enables server guard')
 f.service:hitPower(102,rt,'lightning',f.r2.Position,clock)
 check(not rt.shockRoot and not rt.castSerial and #f.effects==0,'Actual developer immunity blocks real lightning path')
 check(f:command('god off').ok==true and not f.admin:isInvulnerable(f.p1),'Actual god off removes server guard')
 f.service:hitPower(102,rt,'lightning',f.r2.Position,clock)
 check(rt.shockRoot==f.r1 and rt.castSerial==1,'Real lightning applies after god disabled')
 for _,mode in ipairs({'carry','pending'})do
  f=fixture('tag');attachAdmin(f);check(f:command('god on').ok==true,'Developer god setup succeeds')
  f:preparePurchase(f.p1,mode=='carry');check(not f.admin:isInvulnerable(f.p1),'Actual god suppressed during '..mode)
  local reply=f:command('cast tag');check(reply.ok==false and #f.effects==0,'Actual developer cast disabled during '..mode)
  reply=f:command('cooldowns');check(reply.ok==false,'Actual developer cooldown reset disabled during '..mode)
 end
 for _,command in ipairs({'powers','cooldowns','cast lightning','god on','speed 64','jump 120'})do
  f=fixture('tag');attachAdmin(f);local before=f.core.revision
  local reply=f:command(command,f.p2)
  check(reply and reply.authorized==false and reply.ok==false,'Non-developer cannot dispatch '..command)
  check(f.core.revision==before and #f.effects==0 and next(f.admin.mobility)==nil,'Denied '..command..' has no gameplay effects')
 end
 group('Actual developer immunity integrates with PhaseService and suppresses itself during carries/bids; other accounts denied')
 -- Unique Royal Seal executes the real administrative callback and transaction interruption.
 f=fixture('tag');attachAdmin(f)
 local royalOffer,royalCash=f:preparePurchase(f.p2,true)
 local royalReply=f:command('royalseal')
 check(royalReply.ok and f:effectCount('developerRoyalSeal')==1,'Royal Seal begins with a visible server warning')
 check(f.core.players[102].carry==royalOffer.uid,'Royal Seal warning does not instantly drop carried loot')
 f:advance(.64);check(f.core.players[102].carry==royalOffer.uid,'Royal Seal respects its warning window')
 f:advance(.02)
 check(f.runtime[102].shockRoot==f.r2 and f.runtime[102].shockUntil>clock,'Royal Seal applies a bounded real stun')
 check(not f.core.players[102].carry and f.core.players[102].held==0,'Royal Seal releases the real carrying reservation')
 near(f.core.players[102].cash,royalCash,'Royal Seal refunds the original reservation exactly')
 check(f.core.items[royalOffer.uid].state=='Conveyor' and f:effectCount('developerRoyalSeal')==2,'Same real item returns and impact effect is emitted')
 check(not f:command('royalseal').ok,'Developer unique power enforces separate server cooldown')
 check(f:command('cooldowns').ok and not f:command('royalseal').ok,'Normal cooldown reset cannot bypass unique cooldown')
 f:advance(14.35);check(f:command('royalseal').ok,'Royal Seal is available after its full cooldown')
 group('Unique Royal Seal warns, stuns, dislodges and refunds the actual item; its cooldown remains separate')
 for _,gate in ipairs({'shield','immunity','developer','wall','range'})do
  f=fixture('tag');attachAdmin(f);local o,cash=f:preparePurchase(f.p2,true)
  local target=f.runtime[102]
  if gate=='shield' then target.shield=clock+10;target.shieldHits=1
  elseif gate=='immunity' then target.immune=clock+10
  elseif gate=='developer' then f.ctx.isDeveloperInvulnerable=function(p)return p.UserId==102 end
  elseif gate=='wall' then f.visible=false
  elseif gate=='range' then f.r2.Position=Vector.new(18.001,4,0)end
  check(f:command('royalseal').ok,'Royal Seal is cast before '..gate..' target gating')
  f:advance(.66)
  check(f.core.players[102].carry==o.uid and not target.shockRoot,gate..' prevents Royal Seal drop and stun')
  check(f.core.players[102].held==Catalog.ById.item05.price,gate..' preserves actual escrow while carrying')
  if gate=='shield' then check(target.shieldHits==0 and f:effectCount('shieldBreak')==1,'Royal Seal consumes exactly one normal shield hit')end
 end
 f=fixture('tag');attachAdmin(f);f.r2.Position=Vector.new(18,4,0)
 check(f:command('royalseal').ok,'Royal Seal boundary fixture casts');f:advance(.66)
 check(f.runtime[102].shockRoot==f.r2,'Royal Seal includes its exact radius boundary')
 group('Royal Seal respects shields, immunity, protected developers, solid walls and exact range')
 for _,cancel in ipairs({'moved','carrying','bidding','stunned','interrupted','lostBody','runtime','authorization'})do
  f=fixture('tag');attachAdmin(f);check(f:command('royalseal').ok,'Royal Seal cancellation setup: '..cancel)
  if cancel=='moved' then f.r1.Position=Vector.new(8,4,0)
  elseif cancel=='carrying' then f.core.players[101].carry='intercepted'
  elseif cancel=='bidding' then f.core.players[101].pending='bid'
  elseif cancel=='stunned' then f.runtime[101].shockUntil=clock+5
  elseif cancel=='interrupted' then f.runtime[101].interruptedUntil=clock+5
  elseif cancel=='lostBody' then f.bodies[f.p1]=nil
  elseif cancel=='runtime' then f.runtime[101]=table.clone(f.runtime[101])
  elseif cancel=='authorization' then f.admin.config.Enabled=false end
  f:advance(.66)
  check(not f.runtime[102].shockRoot and f:effectCount('developerRoyalSeal')==1,'Royal Seal windup cancels safely: '..cancel)
 end
 for _,mode in ipairs({'carry','pending'})do
  f=fixture('tag');attachAdmin(f);f:preparePurchase(f.p1,mode=='carry')
  check(not f:command('royalseal').ok and #f.effects==0,'Unique power cannot bypass '..mode..' restriction')
 end
 f=fixture('tag');attachAdmin(f)
 check(not f:command('royalseal',f.p2).ok and #f.effects==0,'Other accounts cannot use Royal Seal')
 check(not Royal.cast(f.service,f.admin,f.p2,nil),'Unique module itself rejects unauthorized actors')
 group('Unique developer power cancels on state changes and denies all outsider/carry/bid shortcuts')
 f=fixture('shield');local cosmeticOrigin=Vector.new(1,5,-1)
 check(f.service:cast(f.p1,{id='shield',visualOrigin=cosmeticOrigin}),'Normal shield cast with untrusted visual metadata succeeds normally')
 check(f.effects[1][10]==nil,'Client-provided rod origin is ignored')
 f=fixture('shield');check(f.service:cast(f.p1,'shield',cosmeticOrigin),'Server may provide a real rod origin')
 check(f.effects[1][10]==cosmeticOrigin,'Server-trusted rod origin reaches the visual event')
 f=fixture('shield');check(f.service:cast(f.p1,'shield',Vector.new(1000,4,0)),'Invalid cosmetic origin never prevents legitimate gameplay cast')
 check(f.effects[1][10]==nil,'Far or malformed trusted origin is discarded')
 group('Rod origin is server-only cosmetic data and never modifies normal power rules')
 return {assertions=assertions,groups=groups}
end
