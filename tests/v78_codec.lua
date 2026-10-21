-- Real Core snapshots and restores; storage/network behavior belongs to ProfileStore checks.
return function(package,requireModule)
 local Core=requireModule(package.Core);local Catalog=requireModule(package.Catalog)
 local Config=requireModule(package.Config);local Powers=requireModule(package.PowerCatalog)
 local Codec=requireModule(package.ProfileCodec)
 local checks,groups=0,{}
 local function check(value,message)checks+=1;assert(value,message)end
 local function clone(value)if type(value)~='table'then return value end;local copy={};for k,v in pairs(value)do copy[k]=clone(v)end;return copy end
 local function equal(a,b)
  if type(a)~=type(b)then return false end
  if type(a)~='table'then return a==b end
  for k,v in pairs(a)do if not equal(v,b[k])then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end
  return true
 end
 local function fresh(count)
  local core=Core.new(Catalog,Config)
  for id=1,count or 1 do core:addPlayer(id,0)end
  return core
 end
 local function capture(core,id,now,wall)
  local data,why=Codec.capture(core,id or 1,now or 100,wall or 1000)
  check(data~=nil,'Capture failed: '..tostring(why));return data
 end
 local core=fresh();local data=capture(core)
 check(Codec.validate(data,Catalog),'Fresh starter snapshot validates')
 check(data.schemaVersion==1 and data.userId==1 and #data.items==1,'Profile identity/version and starter retained')
 check(data.cash==650 and data.bank==0 and data.level==0 and data.items[1].kind=='item01','Starting economy unchanged')
 check(data.powerOwned.tag and data.loadout['1']=='tag'and data.powerSlots==2,'Normal fixed Tag/loadout retained')
 check(data.receipts and not next(data.receipts)and data.paidCashCredit==0,'Receipt ledger and credit initialize empty')
 check(data.settings.musicMuted==false and data.settings.sfxMuted==false and data.settings.musicVolume==.18,'Saved device defaults initialize')
 local restored=fresh();local ok,normalized=Codec.restore(restored,1,data,10,1010)
 check(ok,'Fresh snapshot restores')
 check(restored.players[1].bank==30 and normalized.bank==30 and normalized.checkpointAt==1010,'Bank catches up ten seconds and rebases next checkpoint')
 check(restored.players[1].cash==650 and restored.players[1].held==0 and not restored.players[1].pending,'No held escrow survives loading')
 check(Codec.restore(restored,1,data,10,1010),'Repeated deterministic restore succeeds')
 check(restored.players[1].bank==30,'Repeated restore does not compound catch-up earnings')
 local rebased=capture(restored,1,10,1010);local again=fresh()
 check(Codec.restore(again,1,rebased,20,1010)and again.players[1].bank==30,'Saved normalized checkpoint prevents duplicate catch-up')
 local capped=fresh();check(Codec.restore(capped,1,data,20,2000),'Long absence restores')
 check(capped.players[1].bank==180,'Offline bank catch-up bounded to sixty seconds')
 local backward=fresh();check(Codec.restore(backward,1,data,0,900),'Clock rollback handled')
 check(backward.players[1].bank==0,'Clock rollback never subtracts or invents earnings')
 groups[#groups+1]='Versioned first profiles, starter defaults, deterministic restore and bounded bank checkpoint recovery'

 for _,definition in ipairs(Catalog.Items)do
  local c=fresh();local uid=c:grant(1,definition.id)
  c.items[uid].deposited=true;c.players[1].equipped=uid;c.exodiaUsed[uid]=true
  local snapshot=capture(c)
  local other=fresh();check(Codec.restore(other,1,snapshot,50,1000),'Collectible profile restores '..definition.id)
  check(other.items[uid].kind==definition.id and other.items[uid].owner==1 and other.items[uid].deposited,'Collectible metadata persists '..definition.id)
  check(other.exodiaUsed[uid]and other.players[1].equipped==uid and other.players[1].seen[definition.id],'Collectible reward/equipped/discovery persists '..definition.id)
 end
 local upper=fresh();check(upper:gainLevel(1,5),'Level five unlock')
 for i=1,15 do check(upper:grant(1,Catalog.Items[(i%#Catalog.Items)+1].id)~=nil,'Fill upstairs/downstairs slot')end
 local p=upper.players[1];p.cash=12345;p.bank=123.45;p.steals=7;p.paidCashCredit=9000
 p.settings={musicMuted=true,sfxMuted=true,reducedEffects=true,musicVolume=.4,sfxVolume=.2};p.tutorialCompleted=true
 p.starterChosen=true;p.powerSlots=3;p.loadout={'tag','shield','lightning'}
 for _,power in ipairs(Powers.Items)do p.powerOwned[power.id]=true;p.powerReady[power.id]=110 end
 p.castReady=105;p.lockUntil=180;p.lockReady=200
 p.receipts={['purchase-one']={productId=123,grantedAt=999,offerId='fortune',result='Granted'},
  ['purchase-two']={productId=124,grantedAt=999,offerId='unlock_dash',result='CashFallback'}}
 local full=capture(upper);local loaded=fresh();check(Codec.restore(loaded,1,full,20,1004),'Full sixteen-slot profile restores')
 local lp=loaded.players[1]
 check(lp.capacity==16 and lp.level==5 and lp.progression==5,'Both floors and five-percent progression restored')
 check(#full.items==16 and loaded:free(1)==nil,'All sixteen inventory slots preserved')
 check(lp.cash==12345 and lp.steals==7 and lp.paidCashCredit==9000,'Economy and overflow credits preserved')
 check(equal(lp.settings,p.settings)and lp.tutorialCompleted,'All five settings and tutorial completion preserved')
 check(equal(lp.receipts,p.receipts)and lp.receipts~=p.receipts,'Receipt ledger cloned exactly')
 check(lp.powerSlots==3 and lp.loadout[1]=='tag'and lp.loadout[3]=='lightning'and lp.starterChosen,'Three-slot normal loadout survives')
 for _,power in ipairs(Powers.Items)do check(lp.powerOwned[power.id]and lp.powerReady[power.id]==26,'Power ownership and wall-time cooldown '..power.id)end
 check(lp.castReady==21 and lp.lockUntil==96 and lp.lockReady==116,'Cast and protection deadlines convert to new server clock')
 lp.settings.musicVolume=.8;lp.receipts['purchase-one'].productId=900
 check(full.settings.musicVolume==.4 and full.receipts['purchase-one'].productId==123,'Runtime edits do not mutate loaded snapshot')
 local overflow=clone(data);overflow.bank=1999999999;overflow.checkpointIncome=1000000
 local oc=fresh();check(Codec.restore(oc,1,overflow,10,2000)and oc.players[1].bank==2000000000,'Catch-up respects bank cap')
 groups[#groups+1]='All 76 collectible designs and UIDs, sixteen slots, income levels, powers, settings, receipts and credits round-trip'

 local bid=fresh();bid.players[1].cash=10000
 local offer=bid:setOffer('codec-bid','item05',100,54);check(bid:purchaseAttempt(1,'codec-bid',offer.token,100),'Reserve ordinary bid')
 local bidData=capture(bid,1,100,1000)
 check(bidData.cash==10000 and not bidData.carryReturnRecovery,'Unfinished bid escrow refunds in durable recovery snapshot')
 check(bid.players[1].cash==9400 and bid.players[1].held==600,'Capture does not alter active bid economics')
 bid:advance(102);local carried=capture(bid,1,102,1002)
 check(carried.cash==9400 and carried.carryReturnRecovery.uid==offer.uid and carried.carryReturnRecovery.kind=='item05','Paid pickup recovery keeps price forfeited')
 check(carried.carryReturnRecovery.pickupX==54,'Paid carry records original conveyor pickup position')
 local carryLoad=fresh();check(Codec.restore(carryLoad,1,carried,5,1003),'Paid carry profile restores')
 check(carryLoad.players[1].cash==9400 and not carryLoad.players[1].carry and carryLoad.players[1].carryReturnRecovery.uid==offer.uid,'Recovering player gets no refund or duplicate owned carry')
 check(carryLoad.items[offer.uid]==nil,'Paid carry recovery waits for root to return item to belt')
 local retry=capture(carryLoad,1,5,1003)
 check(equal(retry.carryReturnRecovery,carried.carryReturnRecovery),'Recovery survives another checkpoint until root clears it durably')
 local theft=fresh(2);local stolen=theft:grant(1,'item08');theft.items[stolen].deposited=true;theft.exodiaUsed[stolen]=true
 check(theft:beginSteal(2,stolen,100),'Begin theft')
 local ownerData=capture(theft,1,101,1001);local thiefData=capture(theft,2,101,1001)
 check(#ownerData.items==2 and #thiefData.items==1 and thiefData.carryReturnRecovery==nil,'Unfinished theft stays in original owner profile only')
 local ownerLoad=fresh();check(Codec.restore(ownerLoad,1,ownerData,1,1001),'Original owner restores while theft incomplete')
 check(ownerLoad.items[stolen].state=='Stored'and ownerLoad.exodiaUsed[stolen],'Theft crash recovery preserves original owner and consumed marker')
 check(theft:finish(2,true,102),'Complete theft')
 local afterOld=capture(theft,1,102,1002);local afterNew=capture(theft,2,102,1002)
 check(#afterOld.items==1 and #afterNew.items==2 and afterNew.items[2].uid==stolen and afterNew.items[2].exodiaUsed,'Atomic theft after-snapshots preserve single owner and reward marker')
 groups[#groups+1]='Pending bid refunds, paid-carry forfeiture/return metadata and original-owner theft crash recovery'

 local exodia=fresh()
 for _,kind in ipairs({'item25','item26','item27','item28','item29'})do local uid=exodia:grant(1,kind);exodia.items[uid].deposited=true end
 exodia:checkExodia(1,100);local reward=capture(exodia)
 check(reward.pendingReward~=nil,'Pending Exodia choice captured')
 local exodiaLoaded=fresh();check(Codec.restore(exodiaLoaded,1,reward,10,1200),'Exodia collection restores')
 check(exodiaLoaded:claimExodia(1,reward.pendingReward,'level',11),'Saved Exodia choice grants once')
 exodiaLoaded:checkExodia(1,1000)
 check(exodiaLoaded.players[1].pendingReward==nil and exodiaLoaded.players[1].progression==1,'Consumed set cannot reward again after rejoin')
 local infinity=fresh()
 for _,d in ipairs(Catalog.Items)do if d.infinityStone then local uid=infinity:grant(1,d.id);infinity.items[uid].deposited=true end end
 check(infinity:checkInfinity(1,100),'Infinity event awards first time')
 local inf=capture(infinity);local ic=fresh();check(Codec.restore(ic,1,inf,1,1000),'Infinity profile restores')
 check(ic.infinityAwarded[1]and not ic:checkInfinity(1,1000)and ic.players[1].progression==1,'Infinity account reward never farms through rejoin')
 groups[#groups+1]='Exodia per-item consumption, pending choice and Infinity per-account eligibility persist across reconnects'

 for label,mutate in pairs({
  schema=function(d)d.schemaVersion=2 end,unknown=function(d)d.admin=true end,
  cashNaN=function(d)d.cash=0/0 end,cashNegative=function(d)d.cash=-1 end,cashFraction=function(d)d.cash=.1 end,
  bankInfinity=function(d)d.bank=math.huge end,creditLimit=function(d)d.paidCashCredit=1000000000001 end,
  wrongUser=function(d)d.userId=2 end,level=function(d)d.level=1001 end,
  duplicateUid=function(d)d.items[2]=clone(d.items[1]);d.items[2].slot=2 end,
  duplicateSlot=function(d)d.items[2]=clone(d.items[1]);d.items[2].uid='different' end,
  unknownItem=function(d)d.items[1].kind='not_a_collectible'end,
  illegalUid=function(d)d.items[1].uid='uid\nline'end,
  wrongSlot=function(d)d.items[1].slot=9 end,
  badItemField=function(d)d.items[1].owner=2 end,
  badDeposited=function(d)d.items[1].deposited='yes'end,
  missingSettings=function(d)d.settings=nil end,
  settingNaN=function(d)d.settings.musicVolume=0/0 end,
  settingType=function(d)d.settings.sfxMuted=1 end,
  settingDev=function(d)d.settings.developerMode=true end,
  unknownPower=function(d)d.powerOwned.royalseal=true end,
  tagMissing=function(d)d.powerOwned.tag=nil end,
  fourthSlot=function(d)d.powerSlots=4 end,
  tagMoved=function(d)d.loadout['1']='dash'end,
  duplicatePower=function(d)d.loadout['2']='tag'end,
  lockedSlot=function(d)d.powerOwned.dash=true;d.loadout['3']='dash'end,
  discovery=function(d)d.seen.fake=true end,
  cooldown=function(d)d.powerReadyAt.royalseal=1000 end,
  missingCooldown=function(d)d.powerReadyAt=nil end,
  futureDeadline=function(d)d.rewardReadyAt=1000000000 end,
  badReceipt=function(d)d.receipts.x={productId=0,grantedAt=100,offerId='pocket',result='Granted'}end,
  badReceiptResult=function(d)d.receipts.x={productId=1,grantedAt=100,offerId='pocket',result='DevGranted'}end,
  receiptExtra=function(d)d.receipts.x={productId=1,grantedAt=100,offerId='pocket',result='Granted',flight=true}end,
  receiptCapacity=function(d)for i=1,10001 do d.receipts['receipt'..i]={productId=1,grantedAt=100,offerId='pocket',result='Granted'}end end,
  recoveryDuplicate=function(d)d.carryReturnRecovery={uid=d.items[1].uid,kind='item01',pickupX=20}end,
  recoveryUnknown=function(d)d.carryReturnRecovery={uid='lost',kind='missing',pickupX=20}end,
  recoveryPosition=function(d)d.carryReturnRecovery={uid='lost',kind='item01',pickupX=math.huge}end,
  sparseItems=function(d)d.items[10]=clone(d.items[1])end,
 })do
  local corrupted=clone(data);mutate(corrupted);local target=fresh();local before=target.players[1];local revision=target.revision
  local status=Codec.restore(target,1,corrupted,10,1000)
  check(not status,'Corrupt profile rejected: '..label)
  check(target.players[1]==before and target.revision==revision and target.items[before.slots[1]]~=nil,'Corruption never deletes/replaces temporary state: '..label)
 end
 local active=fresh();local own=active:grant(1,'item08');active.items[own].carrier=2
 local conflict=clone(data);conflict.items[1].uid=own;conflict.equipped=own
 check(not Codec.restore(active,1,conflict,1,1000),'Active carried UID cannot be overwritten')
 local outsider=fresh(2);local collision=clone(data);collision.items[1].uid=outsider.players[2].slots[1];collision.equipped=collision.items[1].uid
 check(not Codec.restore(outsider,1,collision,1,1000),'Another player UID cannot be overwritten')
 local reservation=fresh();local ro=reservation:setOffer('pending','item01',100,50);reservation:purchaseAttempt(1,'pending',ro.token,100)
 check(not Codec.restore(reservation,1,data,1,1000),'Join restore cannot overwrite active bid')
 check(Codec.capture(fresh(),99,1,1000)==nil,'Missing player cannot be saved')
 check(Codec.capture(fresh(),1,math.huge,1000)==nil,'Invalid capture clock rejected')
 local broken=fresh();broken.players[1].pending='missing'
 check(Codec.capture(broken,1,100,1000)==nil,'Broken reservation cannot create silently refunded snapshot')
 groups[#groups+1]='Corrupt/newer/wrong-owner data, duplicate UIDs, invalid receipts, developer fields and active-state conflicts fail before mutation'
 return{assertions=checks,groups=groups}
end
