-- Actual stored-item transitions plus durable session/storage adapters.
return function(package,require,setGlobals)
 local checks,groups=0,{}
 local function check(value,message)checks+=1;assert(value,message)end
 local function group(name)groups[#groups+1]=name end
 local function clone(value)
  if type(value)~='table'then return value end
  local out={};for key,item in pairs(value)do out[key]=clone(item)end;return out
 end
 local Core=require(package.Core)
 local Catalog=require(package.Catalog)
 local Config=require(package.Config)
 local Codec=require(package.ProfileCodec)
 local ProfileStore=require(package.ProfileStore)
 local Session=require(package.PersistentSession)
 local PersistenceConfig=require(package.PersistenceConfig)
 setGlobals({game={GetService=function()return{}end}})
 local AdminService=require(package.AdminService)
 local function fixture()
  local f={clock=10,wall=1000,calls=0,guidSeq=0,failures={}}
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
  function f.advance(seconds)f.clock+=seconds;f.wall+=seconds;if f.core then f.core.now=f.clock end end
  function f.record(id)return f.profiles.records['u:'..id].Data end
  function f.open(owner)
   local config=clone(PersistenceConfig);config.Retries=1
   local store=ProfileStore.new(config,{profiles=f.profiles,journal=f.journal,sessionId=owner,
    clock=function()return f.wall end,wait=function()end,validate=function(data)return Codec.validate(data,Catalog)end})
   local core=Core.new(Catalog,Config);core.now=f.clock;f.core=core
   local session=Session.new(core,store,{clock=function()return f.clock end,wall=function()return f.wall end,
    wait=function(seconds)f.advance(seconds)end,guid=function()f.guidSeq+=1;return'vault-'..f.guidSeq..'-'..owner end,
    onFailure=function(why)f.failures[#f.failures+1]=why end})
   return core,session,store
  end
  return f
 end
 local function adminRemove(core,id,uid,clock)
  return AdminService.execute({ctx={core=core,refresh=function()end},clock=clock},{UserId=id},{name='remove',target=id,uid=uid})
 end
 do
  local f=fixture();local core,s=f.open('move');check(s:load(77),'Load movement profile')
  local p=core.players[77];local uid=p.slots[1];local cash=p.cash;local stored=f.calls
  check(core:beginItemMove(77,uid,f.clock),'Move selection rejected')
  local move=core:itemMove(77,f.clock)
  check(move and move.uid==uid and move.remaining==20 and type(move.token)=='string','Move selection metadata invalid')
  check(f.calls==stored and p.slots[1]==uid and not p.carry,'Selecting Move must not save, reserve an empty slot or carry the item')
  local snapshot=core:snapshot(77,f.clock)
  check(snapshot.itemMove.token==move.token and snapshot.inventory[1].moving and snapshot.occupiedSlots[1]and not snapshot.occupiedSlots[2],'Snapshot omits selected/occupied slots')
  check(not core:sell(77,uid)and core.items[uid],'Moving item was sold')
  check(not adminRemove(core,77,uid,function()return f.clock end)and core.items[uid],'Developer removal bypassed the move lock')
  check(core:moveItem(77,uid,8,move.token,f.clock),'Valid empty base slot rejected')
  check(p.slots[1]==nil and p.slots[8]==uid and core.items[uid].slot==8 and p.cash==cash,'Move changed UID, cash or slot ownership')
  check(f.record(77).items[1].slot==8 and f.record(77).items[1].uid==uid,'Move acknowledged before durable slot update')
  check(not core:itemMove(77,f.clock)and not core:moveItem(77,uid,7,move.token,f.clock),'Move token replay succeeded')
  check(s:leave(77),'Move leave failed')
  local again,rejoin=f.open('move-rejoin');check(rejoin:load(77),'Move rejoin failed')
  check(again.players[77].slots[8]==uid and again.items[uid].slot==8 and not again.players[77].itemMove,'Move did not survive reconnect cleanly')
  group('Move selection stays on its pedestal; atomic slot commit persists existing UID without cash or carry changes')
 end
 do
  local f=fixture();local core,s=f.open('cancel');s:load(77)
  local p=core.players[77];local uid=p.slots[1]
  check(core:beginItemMove(77,uid,f.clock),'Cancel setup')
  local token=core:itemMove(77,f.clock).token
  check(core:cancelItemMove(77)and not core:itemMove(77,f.clock)and p.slots[1]==uid,'Cancel changed the stored item')
  check(not core:moveItem(77,uid,2,token,f.clock),'Cancelled token still moves items')
  check(core:beginItemMove(77,uid,f.clock),'Expiration setup')
  token=core:itemMove(77,f.clock).token;f.advance(20)
  check(not core:itemMove(77,f.clock)and not core:moveItem(77,uid,2,token,f.clock),'Expired selection still active')
  check(core:beginItemMove(77,uid,f.clock),'Expired selection blocked a new selection')
  check(core:characterReset(77,f.clock)and not core:itemMove(77,f.clock)and core.items[uid].state=='Stored','Death kept a move selection or lost the item')
  check(core:beginItemMove(77,uid,f.clock),'Safe respawn setup')
  check(core:cancelAll(f.clock)~=false and not core:itemMove(77,f.clock)and core.items[uid],'Safe respawn kept a selection or lost stored loot')
  check(core:sell(77,uid),'Expired/cancelled movement lock still blocked selling')
  group('Cancel, timeout, death and safe respawn clear only transient selection')
 end
 do
  local f=fixture();local core,s=f.open('limits');s:load(77);s:load(88)
  local p=core.players[77];local uid=p.slots[1]
  check(not core:beginItemMove(88,uid,f.clock),'Nonowner can select somebody else\'s item')
  check(not core:beginItemMove(77,uid,0/0),'NaN selection clock accepted')
  check(core:beginItemMove(77,uid,f.clock),'Limits selection setup')
  local token=core:itemMove(77,f.clock).token
  for _,slot in ipairs({0,1,9,17,-1,1.5,math.huge,0/0})do
   check(not core:moveItem(77,uid,slot,token,f.clock),'Invalid, occupied or locked-floor slot accepted')
  end
  check(not core:moveItem(77,uid,2,'wrong-token',f.clock),'Wrong move token accepted')
  check(not core:moveItem(88,uid,2,token,f.clock),'Another owner can replay a move token')
  check(not core:moveItem(77,uid,2,token,math.huge),'Infinite clock accepted')
  p.slots[2]='@reserved'
  check(core:snapshot(77,f.clock).occupiedSlots[2],'Reserved transaction slot absent from snapshot')
  check(not core:moveItem(77,uid,2,token,f.clock),'Move overwrote a transaction reservation')
  p.slots[2]=nil
  check(core:moveItem(77,uid,2,token,f.clock),'Valid lower-floor target rejected')
  f.advance(8);check(core:gainLevel(77,5),'Level-five setup')
  check(core:beginItemMove(77,uid,f.clock),'Upstairs selection setup')
  token=core:itemMove(77,f.clock).token
  check(core:moveItem(77,uid,16,token,f.clock)and p.slots[16]==uid,'Unlocked upstairs slot16 rejected')
  group('Only owners can move into empty unlocked integer slots, including upstairs at level5')
 end
 do
  local f=fixture();local core,s=f.open('sale');s:load(77);s:load(88)
  local p=core.players[77];local uid=p.slots[1];local item=core.items[uid]
  local cash=p.cash;local proceeds=math.floor(Catalog.ById[item.kind].price*.5)
  check(core:sell(77,uid),'Sale rejected')
  check(not core.items[uid]and not p.slots[1]and p.equipped==nil and p.cash==cash+proceeds,'Sale did not atomically clear the real item for50%')
  check(#f.record(77).items==0 and f.record(77).cash==cash+proceeds,'Sale reward and removal did not persist together')
  check(not core:sell(77,uid)and p.cash==cash+proceeds,'Repeated sale paid twice')
  check(not core:equip(77,uid),'Sold UID equipped')
  check(not core:beginSteal(88,uid,f.clock),'Sold UID could be held through stealing')
  check(not core:beginItemMove(77,uid,f.clock),'Sold UID selected for moving')
  check(not adminRemove(core,77,uid,function()return f.clock end),'Sold UID remained removable by developer')
  check(s:leave(77),'Sale leave failed')
  local next,again=f.open('sale-rejoin');check(again:load(77),'Sale rejoin failed')
  check(not next.items[uid]and next.players[77].cash==cash+proceeds and not next.players[77].slots[1],'Sale recreated the item or lost proceeds on reconnect')
  group('Sold UID cannot be sold, equipped, stolen, moved or resurrected on reconnect')
 end
 do
  local f=fixture();local core,s=f.open('theft');s:load(77);s:load(88)
  local p=core.players[77];local uid=p.slots[1];p.lockUntil=0
  check(core:beginItemMove(77,uid,f.clock),'Theft race selection setup')
  local token=core:itemMove(77,f.clock).token
  check(core:beginSteal(88,uid,f.clock),'Movement selection incorrectly shields an item from theft')
  check(not core:itemMove(77,f.clock)and not core:moveItem(77,uid,2,token,f.clock),'Move moved a thief\'s carry')
  check(not core:sell(77,uid),'Owner sold an active theft carry')
  check(not adminRemove(core,77,uid,function()return f.clock end),'Developer deleted an active theft carry')
  check(core:finish(88,false,f.clock)and core.items[uid].state=='Stored','Dropped theft did not return to storage')
  check(not core:moveItem(77,uid,2,token,f.clock),'Old move token revived after stolen item returned')
  check(core:beginItemMove(77,uid,f.clock),'Returned item cannot be selected afresh')
  core:cancelItemMove(77)
  check(core:beginSteal(88,uid,f.clock)and core:finish(88,true,f.clock),'Completed theft setup')
  check(not core:sell(77,uid)and not core:beginItemMove(77,uid,f.clock),'Old owner can manipulate completed stolen UID')
  check(core.items[uid].owner==88 and core.players[88].slots[core.items[uid].slot]==uid,'Theft transfer ownership invalid')
  group('Theft invalidates movement; owners and developers cannot delete or relocate an active carry')
 end
 do
  local core=Core.new(Catalog,Config);core:addPlayer(77,0);core:addPlayer(88,0);core.now=10
  local p=core.players[77];local uid=p.slots[1]
  core.items[uid].carrier=88
  check(not core:sell(77,uid)and not core:beginItemMove(77,uid,10),'Stored-state carrier bypassed guards')
  core.items[uid].carrier=nil;core.players[88].carry=uid
  check(not core:sell(77,uid),'Other player\'s carry reference bypassed removal guard')
  core.players[88].carry=nil;core.transactions.test={uid=uid,resolved=false}
  check(not core:sell(77,uid)and not core:beginItemMove(77,uid,10),'Unresolved transaction bypassed guards')
  core.transactions.test.resolved=true;p.slots[2]=uid
  check(not core:sell(77,uid)and not core:beginItemMove(77,uid,10),'Duplicate slot UID could be removed or moved')
  p.slots[2]=nil;core.players[88].slots[2]=uid
  check(not core:sell(77,uid),'Other owner\'s duplicate reference bypassed removal guard')
  core.players[88].slots[2]=nil;p.pending='bid'
  check(not core:sell(77,uid)and not core:beginItemMove(77,uid,10),'Bidding player managed stored items')
  p.pending=nil
  check(core:sell(77,uid),'Resolved transaction history incorrectly blocks a clean sale')
  group('Defensive guards reject carrier, reservation, inconsistent UID and bidder states')
 end
 for _,operation in ipairs({'move','sell'})do for _,phase in ipairs({'before','after'})do
  local f=fixture();local core,s=f.open('failure-'..operation..'-'..phase);s:load(77)
  local p=core.players[77];local uid=p.slots[1];local item=core.items[uid];local slots=p.slots;local token
  if operation=='move'then core:beginItemMove(77,uid,f.clock);token=core:itemMove(77,f.clock).token end
  local initialCash=p.cash;local proceeds=math.floor(Catalog.ById[item.kind].price*.5)
  local at=f.calls+1
  f.fault=function(e)if e.n>=at and(e.n>at or e.phase==phase or phase=='before')then error('storage unavailable')end end
  local ok
  if operation=='move'then ok=core:moveItem(77,uid,8,token,f.clock)else ok=core:sell(77,uid)end
  check(not ok and s.failed and core.persistenceBusy,'Failed save acknowledged '..operation)
  check(core.players[77]==p and p.slots==slots and core.items[uid]==item and p.slots[1]==uid and item.slot==1,'Rollback lost table identity or original slot: '..operation)
  check(p.cash==initialCash,'Failed operation changed memory cash')
  check(not core:beginSteal(88,uid,f.clock),'Failed session allowed mutation while frozen')
  f.fault=nil;f.advance(121)
  local next,again=f.open('recovery-'..operation..'-'..phase);check(again:load(77),'Recovery load failed')
  local committed=phase=='after'
  if operation=='move'then
   local slot=committed and 8 or 1
   check(next.items[uid]and next.items[uid].slot==slot and next.players[77].slots[slot]==uid,'Crash recovery ignored authoritative move state')
   check(#f.record(77).items==1 and next.players[77].cash==initialCash,'Move crash duplicated item or changed money')
  else
   check((next.items[uid]~=nil)==not committed,'Sale crash resurrected a committed deletion or lost an uncommitted item')
   check(next.players[77].cash==initialCash+(committed and proceeds or 0),'Sale crash reward/removal split')
  end
  check(not next.players[77].itemMove,'Transient move token survived a server crash')
 end end
 group('Failed and ambiguous move/sale writes freeze play, roll back memory and recover exactly the durable state')
 return{assertions=checks,groups=groups}
end
