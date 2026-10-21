-- Run the actual save wrapper, conveyor transactions and server visual cleanup.
return function(package,require,setGlobals)
 local assertions,groups=0,{}
 local function check(value,message)assertions+=1;assert(value,message)end
 local function group(name)groups[#groups+1]=name end
 local function clone(v)
  if type(v)~='table'then return v end
  local out={};for key,value in pairs(v)do out[key]=clone(value)end;return out
 end
 local Core=require(package.Core);local Catalog=require(package.Catalog);local Config=require(package.Config)
 local Codec=require(package.ProfileCodec);local Store=require(package.ProfileStore)
 local Session=require(package.PersistentSession);local PersistenceConfig=require(package.PersistenceConfig)
 local active
 local osMock=table.clone(os);osMock.clock=function()return active.clock end
 setGlobals({os=osMock,game={GetService=function()return{}end}})
 local Phase=require(package.PhaseService)
 local function fixture()
  local f={clock=10,wall=1000,calls=0,guid=0};active=f
  local function adapter()
   return{records={},UpdateAsync=function(self,key,transform)
    f.calls+=1;local value=transform(clone(self.records[key]))
    if value~=nil then self.records[key]=clone(value)end
    return clone(value)
   end}
  end
  f.profiles=adapter();f.journal=adapter()
  f.store=Store.new(PersistenceConfig,{profiles=f.profiles,journal=f.journal,sessionId='conveyor-test',
   clock=function()return f.wall end,wait=function()end,validate=function(data)return Codec.validate(data,Catalog)end})
  f.core=Core.new(Catalog,Config)
  f.session=Session.new(f.core,f.store,{clock=function()return f.clock end,wall=function()return f.wall end,
   wait=function(dt)f.clock+=dt end,guid=function()f.guid+=1;return'conveyor-guid-'..f.guid end})
  function f:advance(dt)self.clock+=dt;self.wall+=math.floor(dt);self.core:advance(self.clock)end
  function f:offer(id,x)return self.core:setOffer(id,'item05',self.clock,x)end
  function f:record(id)return self.profiles.records['u:'..id].Data end
  return f
 end
 do
  local f=fixture();local o=f:offer('empty-server',Config.ConveyorEndX+.1)
  local uid=o.uid;f:advance(1)
  check(f.core.offers[o.id]==nil,'Unbought conveyor offer never expires when no player owns it')
  check(f.core.items[uid]==nil,'Unbought item remains after conveyor disposal')
  check(f.calls==0 and not f.session.failed and not f.core.persistenceBusy,'Ownerless disposal accessed storage or stopped play')
  check(not f.core:expireOffer(o.id,f.clock),'Expired item could be removed twice')
  group('Unowned end-of-conveyor items expire with no players and no profile writes')
 end
 do
  local f=fixture();check(f.session:load(77),'Saved player load failed')
  local p=f.core.players[77];local stored=p.slots[1];local cash=p.cash;local calls=f.calls
  local o=f:offer('clock-expiry',90);o.expires=f.clock+.1
  f:advance(.2)
  check(not f.core.items[o.uid]and not f.core.offers[o.id],'Lifetime expiry left an unbought offer')
  check(f.calls==calls,'Unbought expiry unnecessarily wrote a player profile')
  check(p.cash==cash and p.slots[1]==stored and f.core.items[stored].state=='Stored','Conveyor expiry removed stored inventory/cash')
  check(f:record(77).items[1].uid==stored,'Conveyor expiry modified durable inventory')
  group('Clock expiry leaves stored items, cash, profiles and mutation budgets untouched')
 end
 do
  local f=fixture();local phase=setmetatable({core=f.core,offerSeq=0,ctx={core=f.core,config=Config,catalog=Catalog}},Phase)
  phase.syncVisuals=function()end
  for wave=1,12 do
   for index=1,Config.ConveyorMaxOffers do check(phase:spawn('item05'),'Conveyor stopped replenishing after disposal')end
   check(not phase:spawn('item05'),'Conveyor exceeded its configured active offer limit')
   local travel=(Config.ConveyorStartX-Config.ConveyorEndX)/Config.ConveyorSpeed
   f:advance(travel+.1)
   check(next(f.core.items)==nil and next(f.core.offers)==nil,'Conveyor accumulated expired world entries')
  end
  check(f.calls==0,'An empty conveyor server attempted player saves')
  group('Twelve full conveyor waves replenish after disposal without piling up or exceeding capacity')
 end
 do
  local f=fixture();check(f.session:load(77),'Paid carry load failed')
  local o=f:offer('paid-drop',70);local before=f.core.players[77].cash
  check(f.core:purchaseAttempt(77,o.id,o.token,f.clock),'Paid carry reserve failed')
  local tx=f.core.transactions[f.core.players[77].pending]
  check(f.core:pickup(o,tx,f.clock),'Paid carry pickup failed')
  f:advance(60)
  check(f.core.items[o.uid].state=='PurchaseCarry'and f.core.players[77].carry==o.uid,'Item despawned in carrier hands')
  check(f.core.offers[o.id]==o and not tx.resolved,'Held item lost its reserved offer when hologram expired')
  check(not f.core:expireOffer(o.id,f.clock),'Ownerless expiry bypass removed an InTransit offer')
  check(f.core:finish(77,false,f.clock),'Power/death carry loss could not return item')
  check(o.x==tx.pickupX and f.core.items[o.uid].state=='Conveyor','Lost carry returned to wrong pickup point')
  check(f.core.players[77].cash==before-Catalog.ById[o.kind].price,'Lost purchase was refunded')
  local calls=f.calls;f:advance(40)
  check(not f.core.items[o.uid]and not f.core.offers[o.id],'Returned purchase cannot expire because its resolved transaction remains')
  check(f.calls==calls and f:record(77).cash==before-Catalog.ById[o.kind].price,'Disposal refunded or rewrote a paid loss')
  group('Carried items survive hologram lifetime; returned paid losses expire later without refunds')
 end
 do
  local f=fixture();check(f.session:load(77)and f.session:load(88),'Bid test player loads failed')
  local o=f:offer('bid-refund',70)
  check(f.core:purchaseAttempt(77,o.id,o.token,f.clock),'First bidder reservation failed')
  check(f.core:purchaseAttempt(88,o.id,o.token,f.clock),'Second bidder reservation failed')
  local calls=f.calls
  check(f.core:expireOffer(o.id,f.clock),'Bid expiry rejected')
  check(f.core.players[77].cash==650 and f.core.players[88].cash==650,'Expired unfinished bids did not refund')
  check(f.core.players[77].held==0 and f.core.players[88].held==0,'Bid escrow remained after expiry')
  check(f:record(77).cash==650 and f:record(88).cash==650,'Bid refund was not durably represented')
  check(f.calls>=calls,'Bid expiry skipped normal persistence validation')
  group('Offers with bidders retain the existing durable refund path')
 end
 do
  local f=fixture();local o=f:offer('guarded',Config.ConveyorEndX-.1)
  f.core.persistenceBusy=true
  check(not f.core:expireOffer(o.id,f.clock)and f.core.items[o.uid]~=nil,'Saving guard was bypassed')
  f.core.persistenceBusy=false;f.session.failed=true
  check(not f.core:expireOffer(o.id,f.clock)and f.core.items[o.uid]~=nil,'Fatal storage guard was bypassed')
  f.session.failed=false
  check(not f.core:collect(999),'Unloaded player mutation bypassed persistence')
  f.core.transactions.orphan={uid=o.uid,offer=o.id,status='Carrying'}
  check(not f.core:expireOffer(o.id,f.clock)and f.core.items[o.uid]~=nil,'Unresolved transaction lost its world item')
  f.core.transactions.orphan.resolved=true
  check(f.core:expireOffer(o.id,f.clock),'Resolved transaction unnecessarily blocked ownerless cleanup')
  check(f.calls==0,'Guard cases accessed storage')
  group('Busy/fatal, unknown players and unresolved transactions never bypass persistence safety')
 end
 do
  local f=fixture();local o=f:offer('not-due',90)
  check(not f.core:expireOffer(o.id,f.clock),'Premature ownerless expiry accepted')
  o.x=Config.ConveyorEndX-.1
  local it=f.core.items[o.uid]
  for _,key in ipairs({'owner','carrier','tx'})do
   it[key]='unexpected'
   check(not f.core:expireOffer(o.id,f.clock),'Owned/carried/transaction item entered ownerless expiry')
   it[key]=nil
  end
  o.bids[999]='missing-profile-bid'
  check(not f.core:expireOffer(o.id,f.clock),'Unloaded bidder entered ownerless expiry')
  o.bids[999]=nil;it.offer='wrong-offer'
  check(not f.core:expireOffer(o.id,f.clock),'Mismatched item entered ownerless expiry')
  it.offer=o.id;check(f.core:expireOffer(o.id,f.clock),'Safe due ownerless item did not expire')
  group('The zero-profile exception requires a due, matching, unowned and unbid Conveyor item')
 end
 do
  local f=fixture();local o=f:offer('visual-cleanup',Config.ConveyorEndX+.1)
  local destroyed=0;local model={Destroy=function()destroyed+=1 end}
  local phase=setmetatable({core=f.core,models={[o.uid]={model=model}},markers={},ctx={}},Phase)
  f:advance(1);phase:syncVisuals()
  check(destroyed==1 and phase.models[o.uid]==nil,'Server left the expired visual in the world')
  phase:syncVisuals();check(destroyed==1,'Expired visual was destroyed more than once')
  group('Actual server visual sync destroys disposed conveyor models once, including empty servers')
 end
 return{assertions=assertions,groups=groups}
end
