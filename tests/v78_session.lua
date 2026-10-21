-- Real Core + Codec + ProfileStore + PersistentSession; storage is the only double.
return function(package,require,setGlobals)
 local checks,groups=0,{}
 local function check(v,message)checks+=1;assert(v,message)end
 local function close(a,b,message)check(math.abs(a-b)<.001,(message or'Values differ')..': '..tostring(a)..' / '..tostring(b))end
 local function group(name)groups[#groups+1]=name end
 local function clone(v)
  if type(v)~='table'then return v end
  local out={};for k,x in pairs(v)do out[k]=clone(x)end;return out
 end
 local Core=require(package.Core)
 local Catalog=require(package.Catalog)
 local Config=require(package.Config)
 local Codec=require(package.ProfileCodec)
 local ProfileStore=require(package.ProfileStore)
 local Session=require(package.PersistentSession)
 local PersistenceConfig=require(package.PersistenceConfig)
 local function fixture()
  local f={clock=10,wall=1000,wallExact=1000,calls=0,guidSeq=0,failures={},fault=nil}
  local function adapter(name)
   local a={records={}}
   function a:UpdateAsync(key,callback)
    f.calls+=1;local event={n=f.calls,adapter=name,key=key,phase='before'}
    if f.fault then f.fault(event)end
    local result=callback(clone(self.records[key]))
    if result~=nil then self.records[key]=clone(result)end
    event.phase='after';if f.fault then f.fault(event)end
    return clone(result)
   end
   return a
  end
  f.profiles=adapter('profiles');f.journal=adapter('journal')
  function f.advance(seconds)f.clock+=seconds;f.wallExact+=seconds;f.wall=math.floor(f.wallExact)end
  function f.record(id)return f.profiles.records['u:'..id].Data end
  function f.open(owner)
   local config=clone(PersistenceConfig);config.Retries=1
   local store=ProfileStore.new(config,{profiles=f.profiles,journal=f.journal,sessionId=owner,
    clock=function()return f.wall end,wait=function()end,validate=function(data)return Codec.validate(data,Catalog)end})
   local core=Core.new(Catalog,Config)
   local session=Session.new(core,store,{clock=function()return f.clock end,wall=function()return f.wall end,
    wait=function(seconds)f.advance(seconds)end,guid=function()f.guidSeq+=1;return'guid-'..f.guidSeq..'-'..owner end,
    onFailure=function(why)f.failures[#f.failures+1]=why end})
   return core,session,store
  end
  function f.purchase(core,id,kind,index)
   local offer=core:setOffer(index or'offer',kind or'item05',f.clock,90)
   check(core:purchaseAttempt(id,offer.id,offer.token,f.clock),'Reservation rejected')
   local p=core.players[id];local tx=core.transactions[p.pending]
   f.advance(1.6)
   return offer,tx
  end
  return f
 end
 do
  local f=fixture();local core,s=f.open('initial')
  check(s:load(77),'Fresh durable session load')
  local p=core.players[77];local uid=p.slots[1]
  check(p.cash==650 and core.items[uid].kind==Config.StarterItem,'Fresh profile values changed')
  check(uid:find('guid-',1,true)and #f.record(77).items==1,'Persistent starter UID not unique')
  check(s:settings(77,{musicMuted=true,musicVolume=.4,reducedEffects=true,tutorialCompleted=true}),'Saved settings rejected')
  core:tick(12);f.advance(12)
  check(s:flushAll(),'Bank autosave rejected')
  close(f.record(77).bank,36,'Bank income not checkpointed')
  check(s:leave(77),'Normal durable leave failed')
  check(not core.players[77]and f.profiles.records['u:77'].Lock==nil,'Leave did not release profile/remove runtime')
  f.advance(10)
  local next,again=f.open('rejoined');check(again:load(77),'Rejoin failed')
  local q=next.players[77]
  check(q.slots[1]==uid and q.cash==650,'Rejoin reset item UID or cash')
  close(q.bank,66,'Bounded bank catchup did not recover checkpoint interval')
  check(q.settings.musicMuted and q.settings.musicVolume==.4 and q.tutorialCompleted,'Settings/tutorial did not survive rejoin')
  check(next.items[uid].owner==77 and q.capacity==8,'Rejoin ownership/capacity invalid')
  group('Unique starter, stored inventory, bank checkpoint recovery, settings, tutorial, release and rejoin')
 end
 do
  local f=fixture();local core,s=f.open('delivery');check(s:load(77),'Delivery load')
  local offer,tx=f.purchase(core,77)
  check(core.players[77].cash==50 and core.players[77].held==600,'Reservation escrow invalid')
  check(f.record(77).cash==650,'Unfinished reservation should remain recoverable/refundable')
  local picked,pickReason=core:pickup(offer,tx,f.clock)
  check(picked,'Paid pickup rejected: '..tostring(pickReason)..' / '..table.concat(f.failures,';'))
  check(f.record(77).cash==50 and f.record(77).carryReturnRecovery.uid==offer.uid,'Paid pickup not durably charged before acknowledgement')
  local uid=offer.uid;check(core:finish(77,true,f.clock),'Delivery rejected')
  check(f.record(77).carryReturnRecovery==nil and #f.record(77).items==2,'Delivered item not stored exactly once')
  check(core.items[uid].owner==77 and core.players[77].held==0,'Delivery ownership/escrow invalid')
  check(not core:finish(77,true,f.clock),'Duplicate delivery accepted')
  check(core:characterReset(77,f.clock),'Character reset failed')
  check(core.items[uid].owner==77,'Death removed deposited item')
  check(s:leave(77),'Delivery leave')
  local next,again=f.open('delivery-rejoin');check(again:load(77),'Delivery rejoin')
  check(next.items[uid].state=='Stored'and next.players[77].cash==50,'Delivered ownership/cash failed to persist')
  group('Paid pickup commits price; delivery persists UID once and stored items survive death/rejoin')
 end
 do
  local f=fixture();local core,s=f.open('lost');s:load(77)
  local offer,tx=f.purchase(core,77);check(core:pickup(offer,tx,f.clock),'Loss pickup')
  local uid,x=offer.uid,tx.pickupX
  check(core:finish(77,false,f.clock),'Carrier loss failed')
  check(core.players[77].cash==50 and f.record(77).cash==50,'Lost paid item refunded in durable profile')
  check(offer.uid==uid and offer.x==x and core.items[uid].state=='Conveyor','Lost item did not return same UID/position')
  check(f.record(77).carryReturnRecovery==nil and #f.record(77).items==1,'Lost item became stored/replayed recovery')
  check(s:leave(77),'Loss leave')
  local next,again=f.open('lost-rejoin');check(again:load(77),'Loss rejoin')
  check(next.players[77].cash==50 and #f.record(77).items==1,'Rejoin restored forfeited price')
  group('Combat loss returns original conveyor UID/position without refund, including after rejoin')
 end
 for _,phase in ipairs({'before','after'})do
  local f=fixture();local core,s=f.open('pickup-failure-'..phase);s:load(77)
  local offer,tx=f.purchase(core,77);local at=f.calls+1
  f.fault=function(e)if e.n>=at and(e.n>at or e.phase==phase or phase=='before')then error('storage partition')end end
  local ok=core:pickup(offer,tx,f.clock)
  check(not ok and s.failed and core.persistenceBusy,'Failed save acknowledged pickup or kept play enabled')
  check(#f.failures==1,'Storage failure callback missing')
  f.fault=nil;f.advance(121)
  local next,again=f.open('pickup-recovery-'..phase);check(again:load(77),'Pickup crash rejoin')
  local expected=phase=='before'and 650 or 50
  check(next.players[77].cash==expected,'Pickup crash used in-memory rollback instead of durable result')
  if phase=='after'then
   check(next.items[offer.uid]and next.items[offer.uid].state=='Conveyor','Paid carry crash did not recover original item to conveyor')
  else check(next.items[offer.uid]==nil,'Uncommitted purchase was recovered as paid carry')end
  check(f.record(77).carryReturnRecovery==nil,'Recovery marker not consumed durably')
 end
 group('Before/after pickup-write failures never acknowledge unsaved ownership or refund an applied paid pickup')
 do
  local f=fixture();local core,s=f.open('delivery-ambiguous');s:load(77)
  local offer,tx=f.purchase(core,77);core:pickup(offer,tx,f.clock)
  local at=f.calls+1
  f.fault=function(e)if e.n>=at and(e.n>at or e.phase=='after')then error('delivery reply lost')end end
  check(not core:finish(77,true,f.clock)and s.failed,'Ambiguous delivery should freeze play without acknowledgement')
  f.fault=nil;f.advance(121)
  local next,again=f.open('delivery-authoritative');check(again:load(77),'Ambiguous delivery rejoin')
  check(next.items[offer.uid].owner==77 and next.items[offer.uid].state=='Stored','Durably applied delivery disappeared after memory rollback')
  check(next.players[77].cash==50 and #f.record(77).items==2,'Delivery crash refunded price or duplicated item')
  group('Applied delivery survives a lost save acknowledgement and subsequent in-memory rollback')
 end
 do
  local f=fixture();local core,s=f.open('theft');s:load(77);s:load(88);f.advance(31)
  local uid=core.players[77].slots[1]
  check(core:beginSteal(88,uid,f.clock),'Theft start failed')
  check(core.items[uid].owner==77,'Theft changed owner before deposit')
  check(core:finish(88,true,f.clock),'Theft delivery failed')
  check(core.items[uid].owner==88 and #f.record(77).items==0 and #f.record(88).items==2,'Theft did not durably transfer ownership')
  check(core.players[88].steals==1 and f.record(88).steals==1,'Theft counter not durable')
  check(s:leave(77)and s:leave(88),'Theft participants leave failed')
  local next,again=f.open('theft-rejoin');check(again:load(77)and again:load(88),'Theft rejoin')
  check(next.items[uid].owner==88 and next.players[77].slots[1]==nil,'Rejoin duplicated old-owner copy')
  group('Cross-profile theft commits durable ownership and steal count exactly once')
 end
 for _,phase in ipairs({'before','after'})do
  local f=fixture();local core,s=f.open('theft-crash-'..phase);s:load(77);s:load(88);f.advance(31)
  local uid=core.players[77].slots[1];check(core:beginSteal(88,uid,f.clock),'Theft crash start')
  local at=f.calls+4 -- journal prepare, two profile preparations, then decision
  f.fault=function(e)if e.n>=at and(e.n>at or e.phase==phase or phase=='before')then error('theft decision response lost')end end
  check(not core:finish(88,true,f.clock)and s.failed,'In-doubt theft acknowledged/continued')
  f.fault=nil;f.advance(121)
  local next,again=f.open('theft-resolve-'..phase);check(again:load(77)and again:load(88),'Theft crash recovery load')
  local expected=phase=='before'and 77 or 88
  check(next.items[uid].owner==expected,'Theft crash recovered wrong journal decision')
  local count=0;for _,p in pairs(next.players)do for _,itemUid in pairs(p.slots)do if itemUid==uid then count+=1 end end end
  check(count==1,'Theft crash duplicated or lost ownership')
 end
 group('Both sides of a theft decision crash recover one authoritative owner despite memory rollback')
 do
  local f=fixture();local core,s=f.open('receipt');s:load(77)
  local player={UserId=77};local receipt={PurchaseId='purchase-1',ProductId=1234}
  check(s:grantReceipt(player,receipt,{id='pocket',cash=5000},200),'Cash receipt grant failed')
  check(core.players[77].cash==5650 and f.record(77).receipts['purchase-1'].productId==1234,'Receipt/reward not atomically saved')
  local calls=f.calls
  check(s:grantReceipt(player,receipt,{id='pocket',cash=5000},200),'Receipt retry not acknowledged')
  check(core.players[77].cash==5650 and f.calls==calls,'Duplicate receipt granted again')
  check(not s:grantReceipt(player,{PurchaseId='purchase-1',ProductId=9999},{id='pocket',cash=5000},200),'Receipt product mismatch accepted')
  check(s:leave(77),'Receipt leave')
  local next,again=f.open('receipt-rejoin');check(again:load(77),'Receipt rejoin')
  check(again:grantReceipt(player,receipt,{id='pocket',cash=5000},200),'Saved receipt retry failed')
  check(next.players[77].cash==5650,'Receipt granted twice across servers')
  group('Receipt retries/product mismatches and cross-server rejoin cannot double-grant paid cash')
 end
 do
  local f=fixture();local core,s=f.open('receipt-failure');s:load(77)
  local player={UserId=77};local receipt={PurchaseId='ambiguous-receipt',ProductId=1234}
  local at=f.calls+1;local nested
  f.fault=function(e)
   if e.n==at and e.phase=='before'then nested=s:grantReceipt(player,receipt,{id='pocket',cash=5000},200)end
   if e.n>=at and(e.n>at or e.phase=='after')then error('paid grant reply lost')end
  end
  check(not s:grantReceipt(player,receipt,{id='pocket',cash=5000},200),'Ambiguous receipt grant acknowledged')
  check(nested==false,'Concurrent receipt callback acknowledged an uncommitted in-memory receipt')
  f.fault=nil;f.advance(121)
  local next,again=f.open('receipt-failure-rejoin');check(again:load(77),'Failed receipt recovery')
  check(again:grantReceipt(player,receipt,{id='pocket',cash=5000},200),'Durably applied receipt retry failed')
  check(next.players[77].cash==5650 and next.players[77].receipts[receipt.PurchaseId]~=nil,'Paid grant lost or duplicated after lost acknowledgement')
  group('Concurrent duplicate receipt callbacks cannot acknowledge uncommitted rewards; ambiguous grants recover once')
 end
 do
  local f=fixture();local core,s=f.open('fallback');s:load(77)
  local player={UserId=77};local owned={id='unlock_dash',power='dash',robux=2}
  check(s:grantReceipt(player,{PurchaseId='dash-first',ProductId=200},owned,200),'Power receipt failed')
  check(core.players[77].powerOwned.dash,'Power not unlocked')
  check(s:grantReceipt(player,{PurchaseId='dash-again',ProductId=200},owned,200),'Already-owned power fallback failed')
  check(core.players[77].cash==900 and f.record(77).receipts['dash-again'].result=='CashFallback','Owned power did not receive durable fallback')
  f.advance(25)
  check(s:_change('test',{77},function()local p=core.players[77];p.progression=998;p.level=998;p.capacity=16;return true end),'Level-cap setup')
  check(s:grantReceipt(player,{PurchaseId='level-cap',ProductId=201},{id='level_five',levels=5,robux=100},200),'Partial level cap grant failed')
  check(core.players[77].progression==1000 and core.players[77].cash==12900,'Partial capped levels lost level or fallback value')
  f.advance(20)
  check(s:_change('test',{77},function()core.players[77].cash=2000000000;return true end),'Cash cap setup')
  check(s:grantReceipt(player,{PurchaseId='cash-cap',ProductId=202},{id='pocket',cash=5000},200),'Cash cap grant failed')
  check(core.players[77].cash==2000000000 and core.players[77].paidCashCredit==5000,'Cash cap discarded paid value')
  check(f.record(77).paidCashCredit==5000,'Deferred paid cash was not durable')
  group('Owned powers, partial level caps and cash caps preserve paid value through saved fallback/credit')
 end
 do
  local f=fixture();local core,s=f.open('direct-admin');s:load(77);s:load(88)
  check(s:runFor(77,function()core.players[77].cash+=100;return true,'Direct grant saved.'end),'Direct mutation wrapper failed')
  check(f.record(77).cash==750,'Direct studio grant was acknowledged before durable save')
  local reply=s:adminCommand(function()
   core.players[77].cash-=50;core.players[88].cash+=50
   local ok=core:gainLevel(88,5);return{ok=ok,message='Gift complete.'}
  end)
  check(type(reply)=='table'and reply.ok,'Admin wrapper lost structured reply')
  check(f.record(77).cash==700 and f.record(88).cash==700,'Multi-user admin gift was not committed together')
  check(f.record(88).level==5 and core.players[88].capacity==16,'Gifted fifth level not persisted/unlocked')
  f.advance(16)
  check(s:runFor(77,function()
   local p=core.players[77];p.powerSlots=3;p.powerOwned.dash=true;p.loadout[3]='dash';return true
  end),'Sparse loadout setup failed')
  check(f.record(77).loadout['1']=='tag'and f.record(77).loadout['3']=='dash'and f.record(77).loadout[1]==nil,'Saved loadout is not JSON-stable string-keyed map')
  check(s:leave(77)and s:leave(88),'Direct admin leave')
  local next,again=f.open('direct-admin-rejoin');check(again:load(77)and again:load(88),'Direct admin rejoin')
  check(next.players[77].loadout[1]=='tag'and next.players[77].loadout[3]=='dash'and next.players[77].loadout[2]==nil,'Sparse optional loadout changed on rejoin')
  check(next.players[88].progression==5 and next.players[88].capacity==16,'Admin level gift lost on rejoin')
  group('Direct grants and multi-user admin gifts are durable; JSON-stable sparse loadouts restore normal three slots')
 end
 for _,phase in ipairs({'before','after'})do
  local f=fixture();local core,s=f.open('admin-write-'..phase);s:load(77)
  local p=core.players[77];local slots=p.slots;local uid=p.slots[1];local item=core.items[uid]
  local at=f.calls+1
  f.fault=function(e)if e.n>=at and(e.n>at or e.phase==phase or phase=='before')then error('gift storage failure')end end
  local ok=s:runFor(77,function()p.cash+=100;return true,'Gift complete.'end)
  check(not ok and s.failed,'Failed direct gift was acknowledged')
  check(core.players[77]==p and p.slots==slots and core.items[uid]==item,'Rollback replaced live player/item/table identity')
  check(p.cash==650,'Rollback failed to restore memory cash')
  f.fault=nil;f.advance(121)
  local next,again=f.open('admin-write-recovery-'..phase);check(again:load(77),'Direct gift recovery failed')
  check(next.players[77].cash==(phase=='before'and 650 or 750),'Direct gift rejoin ignored authoritative durable state')
 end
 group('Unconfirmed direct/admin mutations freeze play and preserve table identity while durable recovery decides outcome')
 do
  local f=fixture();local core,s=f.open('exodia');s:load(77)
  check(s:runFor(77,function()
   for _,kind in ipairs(require(package.PhaseConfig).ExodiaKinds)do local uid=core:grant(77,kind);core.items[uid].deposited=true end
   return true
  end),'Exodia test deposits setup failed')
  check(core:checkExodia(77,f.clock)~=false,'Exodia set check failed')
  local token=core.players[77].pendingReward
  check(type(token)=='string'and f.record(77).pendingReward==token,'Exodia reward token not persisted')
  local marked=0;for _,item in ipairs(f.record(77).items)do if item.exodiaUsed then marked+=1 end end
  check(marked==5,'Exodia consumed-piece markers not persisted per item')
  local offer,tx=f.purchase(core,77);check(core:pickup(offer,tx,f.clock),'Safe respawn paid pickup')
  check(core:claimExodia(77,token,'respawn',f.clock),'Safe Exodia reward failed')
  check(core.players[77].cash==650 and f.record(77).cash==650,'Explicit safe event failed to restore paid carry price')
  check(core.items[offer.uid].state=='Conveyor'and f.record(77).pendingReward==nil,'Safe event lost item or retained reward token')
  check(s:leave(77),'Exodia leave');f.advance(121)
  local next,again=f.open('exodia-rejoin');check(again:load(77),'Exodia rejoin')
  next:checkExodia(77,f.clock)
  check(next.players[77].pendingReward==nil,'Already consumed Exodia pieces farmed a new reward after rejoin')
  local used=0;for _,item in ipairs(f.record(77).items)do if item.exodiaUsed then used+=1 end end
  check(used==5,'Exodia marker lost after safe respawn/rejoin')
  group('Exodia tokens and consumed UIDs survive rejoin; its trusted safe-respawn refund exception stays durable')
 end
 do
  local f=fixture();local core,s=f.open('infinity');s:load(77)
  check(s:runFor(77,function()
   local count=0
   for _,definition in ipairs(Catalog.Items)do if definition.infinityStone and count<5 then
    local uid=core:grant(77,definition.id);core.items[uid].deposited=true;count+=1
   end end
   return count==5
  end),'Infinity stone test deposits failed')
  check(core:checkInfinity(77,f.clock),'Infinity level reward failed')
  check(core.players[77].progression==1 and f.record(77).infinityAwarded,'Infinity awarded flag/level not durable')
  check(s:leave(77),'Infinity leave')
  local next,again=f.open('infinity-rejoin');check(again:load(77),'Infinity rejoin')
  check(not next:checkInfinity(77,f.clock)and next.players[77].progression==1,'Infinity level farmed again after rejoin')
  group('Infinity reward eligibility is saved and cannot grant another level on reconnect')
 end
 do
  local f=fixture();local core,session=f.open('thread-owner')
  check(session:load(1)and session:load(2),'Yielding admin fixture loads both profiles')
  local cash=core.players[1].cash;local reply
  local worker=coroutine.create(function()
   reply=session:adminCommand(function()
    core.players[1].cash+=25
    coroutine.yield('announcement-filter')
    check(core:gainLevel(2),'Same transaction thread may use nested core methods')
    return{ok=true}
   end)
  end)
  local ok,where=coroutine.resume(worker)
  check(ok and where=='announcement-filter'and core.persistenceBusy,'Yielding callback retains global economy gate')
  check(not core:grant(2,'item08'),'Another coroutine cannot bypass nested-method depth')
  check(f.record(1).cash==cash and f.record(2).level==0,'Uncommitted changes remain invisible to storage')
  check(coroutine.resume(worker)and reply.ok,'Yielding owner can finish its transaction')
  check(f.record(1).cash==cash+25 and f.record(2).level==1,'Both yielded admin changes commit together')
  group('Nested economy permission belongs to its coroutine; other work cannot bypass a yielding admin save')
 end
 do
  local f=fixture();local core,session=f.open('queued-settings');check(session:load(1),'Settings queue fixture loads')
  core.persistenceBusy=true
  check(session:queueSettings(1,{musicVolume=.2,sfxMuted=true}),'Settings edits queue while an economy save is busy')
  check(session:queueSettings(1,{musicVolume=.7}),'New slider value merges over an older pending value')
  check(not session:flushSettings()and f.record(1).settings.musicVolume==.18,'Busy queue does not overwrite confirmed settings')
  core.persistenceBusy=false
  check(session:flushSettings()and f.record(1).settings.musicVolume==.7 and f.record(1).settings.sfxMuted,'Latest merged values persist when storage is available')
  check(not session.pendingSettings[1],'Confirmed settings queue clears')
  check(not session:queueSettings(1,{developerMode=true}),'Settings queue rejects privilege fields')
  check(session:queueSettings(1,{sfxVolume=.1,tutorialCompleted=true}),'Last preference edits queue before disconnect')
  check(session:leave(1),'Disconnect saves final queued settings in release')
  check(f.record(1).settings.sfxVolume==.1 and f.record(1).tutorialCompleted,'Disconnect cannot silently drop the final slider choice')
  group('Volume/settings edits merge while busy and save on flush or disconnect without accepting privilege fields')
 end
 do
  local f=fixture();local core,session=f.open('slow-departure');check(session:load(77),'Slow departure fixture load')
  local started=f.clock;local waited=0;core.persistenceBusy=true
  session.wait=function(seconds)
   waited+=1;f.advance(seconds)
   if f.clock-started>=25 then core.persistenceBusy=false end
  end
  check(session:leave(77),'Departure returned before a write lasting over two wait windows finished')
  check(f.clock-started>=25 and waited>240,'Departure test did not cross the12-second wait window')
  check(not session.loaded[77]and not core.players[77]and f.profiles.records['u:77'].Lock==nil,'Delayed departure orphaned a loaded/locked profile')
  local next,again=f.open('slow-departure-rejoin');check(again:load(77),'Completed delayed departure prevented rejoin')
  check(next.players[77].cash==650,'Delayed departure damaged saved cash')
  group('Departures wait across multiple slow-save windows, then release profiles and allow another server to join')
 end
 do
  local f=fixture();local core,session=f.open('failed-departure');check(session:load(77),'Failed departure fixture load')
  local started=f.clock;core.persistenceBusy=true
  session.wait=function(seconds)
   f.advance(seconds)
   if f.clock-started>=2 then session.failed=true end
  end
  local ok= session:leave(77)
  check(not ok and session.failed,'Departure ignored a fatal storage state while waiting')
  check(not session.loaded[77]and f.profiles.records['u:77'].Lock==nil,'Fail-closed departure left a healthy confirmed profile locked')
  local next,again=f.open('failed-departure-rejoin');check(again:load(77),'Fail-closed departure blocked rejoin after release')
  check(next.players[77].cash==650,'Fail-closed departure saved unconfirmed memory')
  group('Fatal storage state during a departure wait uses the confirmed-data release path')
 end
 do
  local f=fixture();local core,session=f.open('duplicate-departure');check(session:load(77),'Duplicate departure fixture load')
  core.persistenceBusy=true;local completed=false
  session.wait=function(seconds)
   f.advance(seconds)
   if not completed then
    completed=true;check(session.store:release(77),'Competing departure release failed')
    session.loaded[77]=nil;core.players[77]=nil;core.persistenceBusy=false
   end
  end
  check(session:leave(77)and not session.failed,'Second departure tried to capture an already-removed profile')
  check(f.profiles.records['u:77'].Lock==nil,'Duplicate departure reacquired a released lock')
  group('Concurrent shutdown/removal waits recognize an already-completed departure without failing the server')
 end
 return{assertions=checks,groups=groups}
end
