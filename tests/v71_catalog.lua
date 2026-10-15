-- Run the real version 71 catalog and transactions with the official Luau CLI.
-- Geometry and the approved display-name manifest are checked independently.
return function(package,requireModule,baselinePackage)
 assert(baselinePackage,'Version 70 baseline is required')
 local original=requireModule(baselinePackage.Catalog)
 local current=requireModule(package.Catalog)
 local Core=requireModule(package.Core)
 local Config=requireModule(package.Config)
 local Rules=requireModule(package.PhaseConfig)
 local checks=0
 local function check(value,message)checks+=1;assert(value,message)end
 local function same(a,b,path)
  check(type(a)==type(b),'Changed value type: '..path)
  if type(a)~='table' then check(a==b,'Changed value: '..path);return end
  for key,value in pairs(a)do same(value,b[key],path..'.'..tostring(key))end
  for key in pairs(b)do check(a[key]~=nil,'Unexpected value added: '..path..'.'..tostring(key))end
 end
 check(#original.Items==65 and #current.Items==66,'Expected 65 preserved items and one Formula addition')
 for index,old in ipairs(original.Items)do
  local item=current.Items[index]
  check(item.id==old.id,'Existing item order/ID changed: '..old.id)
  for key,value in pairs(old)do if key~='name' then same(value,item[key],old.id..'.'..key)end end
  for key in pairs(item)do check(old[key]~=nil,'Existing item field added: '..old.id..'.'..key)end
  check(type(item.name)=='string' and #item.name>0 and #item.name<=64,'Display name is empty or excessively long: '..old.id)
 end
 same(original.Weights,current.Weights,'Weights')
 same(original.SpawnSettings,current.SpawnSettings,'SpawnSettings')
 same(original.Tiers,current.Tiers,'Tiers')
 same(original.Colors,current.Colors,'Colors')
 local added=assert(current.ById.krabby_patty_formula,'Formula is absent from actual catalog')
 check(current.Items[66]==added and original.ById[added.id]==nil,'Formula must append with a stable new ID')
 check(added.name=='Krabby Patty Secret Formula','Formula name must identify the requested object')
 check(added.tier==5 and added.rarity=='Legendary','Formula rarity must be Legendary')
 check(added.price==65000 and added.income==700 and added.spawnWeight==.65,'Formula economy must match requested native item defaults')
 check(added.power=='tag' and added.itemType=='collectible','Formula uses existing collectible ability routing')
 local ids,names={},{}
 for _,item in ipairs(current.Items)do
  check(not ids[item.id] and current.ById[item.id]==item,'Duplicate/missing ById entry: '..item.id);ids[item.id]=true
  check(not names[item.name],'Duplicate display name: '..item.name);names[item.name]=true
  local occurrences=0
  for _,entry in ipairs(current.ByTier[item.tier])do if entry==item then occurrences+=1 end end
  check(occurrences==1,'Collectible absent from or duplicated in rarity pool: '..item.id)
 end
 -- Cover every selection interval using real Catalog.roll, including the new
 -- Formula's interval rather than relying on a probabilistic spawn sample.
 local totalTier=0
 for tier,w in ipairs(current.Weights)do
  check(type(w)=='number' and w==w and w>0 and w<math.huge,'Rarity weight must be positive and finite')
  if tier>1 then check(current.Weights[tier-1]>w,'Rarity probabilities must strictly decrease as rarity increases')end
  check(#current.ByTier[tier]>0,'Every configured rarity needs an actual collectible pool')
  totalTier+=w
 end
 check(totalTier==107,'Seven rarity settings are relative weights with total 107, not raw percentages')
 local oldTotal=0;for _,w in ipairs(original.Weights)do oldTotal+=w end
 local totalProbability=0
 for tier,w in ipairs(current.Weights)do
  local poolWeight=0
  for _,item in ipairs(current.ByTier[tier])do
   check(type(item.spawnWeight)=='number' and item.spawnWeight==item.spawnWeight and item.spawnWeight>0 and item.spawnWeight<math.huge,'Item weight must be positive and finite: '..item.id)
   poolWeight+=item.spawnWeight
  end
  local tierProbability=0
  for _,item in ipairs(current.ByTier[tier])do
   local probability=(w/totalTier)*(item.spawnWeight/poolWeight)
   check(probability>0 and probability<=1,'Invalid global item probability: '..item.id)
   totalProbability+=probability;tierProbability+=probability
  end
  check(math.abs(tierProbability-w/totalTier)<1e-12,'Item probabilities must sum to their rarity probability')
  check(math.abs(tierProbability-original.Weights[tier]/oldTotal)<1e-12,'Appending Formula must not alter rarity frequency')
 end
 check(math.abs(totalProbability-1)<1e-12,'Global item spawn probabilities must sum to one')
 local tierStart=0
 for tier,w in ipairs(current.Weights)do
  local pool=current.ByTier[tier]
  if #pool>0 then
   local totalItem=0;for _,item in ipairs(pool)do totalItem+=item.spawnWeight end
   local itemStart=0
   for _,item in ipairs(pool)do
    for _,fraction in ipairs({.000001,.5,.999999})do
     for _,tierFraction in ipairs({.000001,.5,.999999})do
      local draws={(tierStart+w*tierFraction)/totalTier,(itemStart+item.spawnWeight*fraction)/totalItem};local i=0
      local selected=current.roll({NextNumber=function()i+=1;return assert(draws[i],'Unexpected RNG draw')end})
      check(selected==item.id and i==2,'Actual weighted roll does not reach '..item.id)
     end
    end
    itemStart+=item.spawnWeight
   end
   tierStart+=w
  end
 end
 local function fresh()
  local c=Core.new(current,Config)
  for id=1,2 do c:addPlayer(id,0);c.players[id].cash=10000000 end
  return c
 end
 local function invariant(c)
  for id,p in pairs(c.players)do
   local escrow=0
   for _,tx in pairs(c.transactions)do if tx.player==id and not tx.resolved then
    escrow+=tx.amount;check(p.slots[tx.slot]=='@'..tx.id,'Transaction reservation lost')
   end end
   check(p.cash>=0 and p.held==escrow,'Funds and outstanding escrow disagree')
   if p.carry then
    local it=c.items[p.carry];check(it and it.carrier==id and c.transactions[it.tx].status=='Carrying','Carry owner/transaction disagree')
   end
  end
  for uid,it in pairs(c.items)do if it.state=='Stored' then check(c.players[it.owner].slots[it.slot]==uid,'Stored slot ownership mismatch')end end
 end
 local c=fresh();local income1,income2=c:income(1),c:income(2)
 local offer=c:setOffer('formula-deliver',added.id,100,55)
 local uid=offer.uid
 check(c:purchaseAttempt(1,offer.id,offer.token,100),'Formula purchase cannot reserve funds and a slot')
 check(c.players[1].cash==10000000-added.price and c.players[1].held==added.price,'Formula purchase must hold exact price')
 check(c.items[uid].owner==nil and c:income(1)==income1 and not c.players[1].seen[added.id],'Uncollected Formula must not count as owned or indexed')
 invariant(c)
 local pickup=100+Rules.ContestWindow+.01
 c:advance(pickup)
 check(c.players[1].carry==uid and c.items[uid].state=='PurchaseCarry','Formula must enter purchase carry')
 check(not c:power(1,pickup,'tag'),'Formula buyer must not use powers while carrying')
 check(c:finish(1,true,pickup+1),'Formula delivery failed')
 check(c.items[uid].state=='Stored' and c.items[uid].owner==1 and c.items[uid].deposited,'Formula deposit did not establish ownership')
 check(c.players[1].held==0 and c:income(1)==income1+added.income and c.players[1].seen[added.id],'Formula deposit must commit income/index once')
 check(not c.offers[offer.id] and not c:finish(1,true,pickup+2),'Delivered Formula offer must clear and reject duplicate deposit')
 local snap=c:snapshot(1,pickup+3);local found=0
 for _,entry in ipairs(snap.inventory)do if entry.uid==uid then found+=1;check(entry.kind==added.id,'Formula index uses wrong kind')end end
 check(found==1 and snap.seen[added.id],'Formula missing or duplicated in actual inventory/index snapshot')
 c:characterReset(1,108);c:characterReset(1,109)
 check(c.items[uid].owner==1 and c.items[uid].state=='Stored' and c:income(1)==income1+added.income,'Stored Formula must survive repeated owner resets')
 invariant(c)
 check(c:beginSteal(2,uid,110),'Stored Formula cannot be stolen')
 check(c.items[uid].owner==1 and c.items[uid].state=='TheftCarry' and c:income(1)==income1,'Theft must pause Formula income without prematurely transferring ownership')
 check(not c:power(2,110.1,'tag'),'Formula thief must not use powers while carrying')
 check(c:finish(2,false,111),'Interrupted Formula theft must recover')
 check(c.items[uid].owner==1 and c.items[uid].state=='Stored' and c:income(1)==income1+added.income,'Interrupted theft failed to restore Formula')
 check(c:beginSteal(2,uid,112) and c:finish(2,true,113),'Completed Formula theft failed')
 check(c.items[uid].owner==2 and c:income(1)==income1 and c:income(2)==income2+added.income,'Completed theft must transfer Formula income exactly once')
 check(c.players[2].steals==1 and c.players[2].seen[added.id] and not c:finish(2,true,114),'Stolen Formula index/counter/duplicate completion incorrect')
 c:characterReset(1,115);c:characterReset(2,116)
 check(c.items[uid].owner==2 and c.items[uid].state=='Stored','Completed theft must remain permanent after both owners reset')
 invariant(c)
 local retry=c:setOffer('formula-refund',added.id,120,42)
 local before=c.players[1].cash;local token=retry.token
 check(c:purchaseAttempt(1,retry.id,token,120),'Second Formula purchase failed')
 c:advance(120+Rules.ContestWindow+.01)
 check(c:finish(1,false,123),'Interrupted Formula purchase must return to conveyor')
 check(c.players[1].cash==before and c.players[1].held==0,'Interrupted Formula purchase must refund exact escrow')
 check(c.items[retry.uid].state=='Conveyor' and retry.x==42 and retry.token~=token,'Formula must return at its pickup location with a new token')
 check(not c:finish(1,false,124) and not c:purchaseAttempt(1,retry.id,token,124),'Duplicate refund/stale Formula purchase token must reject')
 invariant(c)
 local pending=fresh();local cancellation=pending:setOffer('formula-reset',added.id,100,55)
 check(pending:purchaseAttempt(1,cancellation.id,cancellation.token,100),'Pending Formula purchase setup failed')
 pending:characterReset(1,100.3);pending:characterReset(1,100.4)
 check(pending.players[1].cash==10000000 and pending.players[1].held==0 and pending.items[cancellation.uid].owner==nil,'Death before pickup must refund Formula exactly once')
 invariant(pending)
 local full=fresh()
 while full:free(1)do check(full:grant(1,added.id)~=nil,'Could not fill Formula test base')end
 local rejected=full:setOffer('formula-full',added.id,100,55)
 check(not full:purchaseAttempt(1,rejected.id,rejected.token,100),'Formula purchase must reject a full base')
 check(full.players[1].cash==10000000 and full.players[1].held==0,'Rejected full-base purchase must not charge')
 local regression=requireModule(package.RegressionTests)(package)
 check(regression.passed==13 and #regression.names==13,'All 13 existing regression groups must execute')
 return string.format('%d checks; all 65 existing IDs/stats/types/weights preserved; 66 reachable catalog items; Formula purchase/carry/deposit/index/refund/theft/reset/full-base checks; 13 existing regression groups',checks)
end
