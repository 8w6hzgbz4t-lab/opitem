-- Exercise the actual v76 catalog, weighted roll and server transaction ledger.
-- Run through tools/run_game_checks.py with the immutable v74 baseline.
return function(package,requireModule,baselinePackage)
 assert(baselinePackage,'Version 74 baseline is required')
 local function clone(value)
  if type(value)~='table' then return value end
  local result={};for key,entry in pairs(value)do result[key]=clone(entry)end;return result
 end
 -- The real session suite runs before this extension and Catalog enriches the
 -- expanded entries in place. Compare both baselines after that same pass.
 local original=requireModule(baselinePackage.Catalog)
 local current=requireModule(package.Catalog)
 local rawOriginal=requireModule(baselinePackage.ExpandedCatalog)
 local rawCurrent=requireModule(package.ExpandedCatalog)
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
 local expected={
 {id='stardust_dragon',name='Stardust Dragon',model='stardust_dragon',tier=5,price=85000,income=900,spawnWeight=0.65,category='Relic',power='tag',ability='Collectible',radius=7,windup=.15,cooldown=4},
 {id='blue_eyes_white_dragon',name='Blue-Eyes White Dragon',model='blue_eyes_white_dragon',tier=6,price=330000,income=3100,spawnWeight=0.5,category='Relic',power='tag',ability='Collectible',radius=7,windup=.15,cooldown=4},
 {id='michael_jackson_glove',name="Michael Jackson's Glove",model='michael_jackson_glove',tier=4,price=17500,income=240,spawnWeight=0.8,category='Relic',power='tag',ability='Collectible',radius=7,windup=.15,cooldown=4},
 {id='tungs_bat',name='Tungs Bat',model='tungs_bat',tier=3,price=5500,income=95,spawnWeight=0.7,category='Relic',power='tag',ability='Collectible',radius=7,windup=.15,cooldown=4},
 {id='moms_credit_card',name='Moms Credit Card',model='moms_credit_card',tier=7,price=1500000,income=11000,spawnWeight=0.5,category='Relic',power='tag',ability='Collectible',radius=7,windup=.15,cooldown=4},
 {id='sonic_gold_ring',name="Sonic's Golden Ring",model='sonic_gold_ring',tier=2,price=1800,income=38,spawnWeight=0.6,category='Relic',power='tag',ability='Collectible',radius=7,windup=.15,cooldown=4},
 {id='captain_america_shield',name="Captain America's Shield",model='captain_america_shield',tier=5,price=95000,income=1000,spawnWeight=0.6,category='Relic',power='tag',ability='Collectible',radius=7,windup=.15,cooldown=4},
 }
 check(#original.Items==69 and #current.Items==76,'Expected 69 preserved items and seven additions')
 check(#rawCurrent==#rawOriginal+7,'ExpandedCatalog must append exactly seven items')
 for index,old in ipairs(rawOriginal)do same(old,rawCurrent[index],'ExpandedCatalog.'..old.id)end
 for index,old in ipairs(original.Items)do same(old,current.Items[index],'Catalog.'..old.id)end
 for _,key in ipairs({'Weights','RarityWeights','SpawnSettings','Tiers','Colors'})do same(original[key],current[key],key)end

 local added={}
 for index,definition in ipairs(expected)do
  local item=assert(current.ById[definition.id],'Missing new item: '..definition.id)
  local enriched=clone(definition)
  enriched.itemType='collectible'
  enriched.rarity=current.Tiers[definition.tier]
  same(enriched,rawCurrent[#rawOriginal+index],'New enriched definition.'..definition.id)
  check(current.Items[69+index]==item and original.ById[item.id]==nil,'New item must append with a stable new ID')
  for key,value in pairs(definition)do
   local expectedValue=value
   same(expectedValue,item[key],item.id..'.'..key)
  end
  check(item.rarity==current.Tiers[item.tier],'New item rarity does not match its tier')
  check(item.itemType=='collectible','New collectible type must not silently receive a sword/axe spawn modifier')
  for key in pairs(item)do check(definition[key]~=nil or key=='itemType' or key=='rarity','Unexpected new item field: '..item.id..'.'..key)end
  added[#added+1]=item
 end
 local ids,names={},{}
 for _,item in ipairs(current.Items)do
  check(not ids[item.id] and current.ById[item.id]==item,'Duplicate/missing ById entry: '..item.id);ids[item.id]=true
  check(type(item.name)=='string' and #item.name>0 and #item.name<=64,'Invalid display name: '..item.id)
  check(not names[item.name],'Duplicate display name: '..item.name);names[item.name]=true
  local occurrences=0
  for _,entry in ipairs(current.ByTier[item.tier])do if entry==item then occurrences+=1 end end
  check(occurrences==1,'Collectible absent from or duplicated in rarity pool: '..item.id)
 end
 -- The two-stage distribution preserves rarity frequency while adding entries
 -- within their rarity pools. Verify every item interval, not a lucky sample.
 local totalTier=0
 for tier,w in ipairs(current.Weights)do
  check(type(w)=='number' and w==w and w>0 and w<math.huge,'Rarity weight must be positive and finite')
  if tier>1 then check(current.Weights[tier-1]>w,'Rarity probability must strictly decrease as rarity increases')end
  check(#current.ByTier[tier]>0,'Every configured rarity needs an actual collectible pool')
  totalTier+=w
 end
 check(#current.Weights==7 and totalTier==107,'Seven rarity settings are relative weights with total 107')
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
  check(math.abs(tierProbability-original.Weights[tier]/oldTotal)<1e-12,'Appending items must not alter rarity frequency')
 end
 check(math.abs(totalProbability-1)<1e-12,'Global item spawn probabilities must sum to one')
 local tierStart=0
 for tier,w in ipairs(current.Weights)do
  local pool=current.ByTier[tier]
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
 for _,item in ipairs(added)do
  local id=item.id
  local c=fresh();local income1,income2=c:income(1),c:income(2)
  local offer=c:setOffer(id..'-deliver',id,100,55);local uid=offer.uid
  check(c:purchaseAttempt(1,offer.id,offer.token,100),id..': purchase cannot reserve funds and a slot')
  check(c.players[1].cash==10000000-item.price and c.players[1].held==item.price,id..': purchase must hold exact price')
  check(c.items[uid].owner==nil and c:income(1)==income1 and not c.players[1].seen[id],id..': uncollected item must not count as owned or indexed')
  invariant(c)
  local pickup=100+Rules.ContestWindow+.01;c:advance(pickup)
  check(c.players[1].carry==uid and c.items[uid].state=='PurchaseCarry',id..': item must enter purchase carry')
  check(not c:power(1,pickup,'tag'),id..': buyer must not use powers while carrying')
  check(c:finish(1,true,pickup+1),id..': delivery failed')
  check(c.items[uid].state=='Stored' and c.items[uid].owner==1 and c.items[uid].deposited,id..': deposit did not establish ownership')
  check(c.players[1].held==0 and c:income(1)==income1+item.income and c.players[1].seen[id],id..': deposit must commit income/index once')
  check(not c.offers[offer.id] and not c:finish(1,true,pickup+2),id..': offer must clear and duplicate deposit must reject')
  local snapshot=c:snapshot(1,pickup+3);local found=0
  for _,entry in ipairs(snapshot.inventory)do if entry.uid==uid then found+=1;check(entry.kind==id,id..': inventory uses wrong kind')end end
  check(found==1 and snapshot.seen[id],id..': missing/duplicated in actual inventory/index snapshot')
  c:characterReset(1,108);c:characterReset(1,109)
  check(c.items[uid].owner==1 and c.items[uid].state=='Stored' and c:income(1)==income1+item.income,id..': stored item must survive repeated owner resets')
  invariant(c)
  check(c:beginSteal(2,uid,110),id..': stored item cannot be stolen')
  check(c.items[uid].owner==1 and c.items[uid].state=='TheftCarry' and c:income(1)==income1,id..': theft must pause income without premature transfer')
  check(not c:power(2,110.1,'tag'),id..': thief must not use powers while carrying')
  check(c:finish(2,false,111),id..': interrupted theft must recover')
  check(c.items[uid].owner==1 and c.items[uid].state=='Stored' and c:income(1)==income1+item.income,id..': interrupted theft failed to restore item')
  check(c:beginSteal(2,uid,112) and c:finish(2,true,113),id..': completed theft failed')
  check(c.items[uid].owner==2 and c:income(1)==income1 and c:income(2)==income2+item.income,id..': completed theft must transfer income exactly once')
  check(c.players[2].steals==1 and c.players[2].seen[id] and not c:finish(2,true,114),id..': stolen index/counter/duplicate completion incorrect')
  c:characterReset(1,115);c:characterReset(2,116)
  check(c.items[uid].owner==2 and c.items[uid].state=='Stored',id..': completed theft must remain permanent after both owners reset')
  invariant(c)
  local retry=c:setOffer(id..'-refund',id,120,42);local before=c.players[1].cash;local token=retry.token
  check(c:purchaseAttempt(1,retry.id,token,120),id..': second purchase failed')
  c:advance(120+Rules.ContestWindow+.01)
  check(c:finish(1,false,123),id..': interrupted purchase must return to conveyor')
  check(c.players[1].cash==before-item.price and c.players[1].held==0,id..': interrupted paid purchase must forfeit its price')
  check(c.items[retry.uid].state=='Conveyor' and retry.x==42 and retry.token~=token,id..': item must return at pickup location with new token')
  check(not c:finish(1,false,124) and not c:purchaseAttempt(1,retry.id,token,124),id..': duplicate refund/stale purchase token must reject')
  invariant(c)
  for _,resetDuringCarry in ipairs({false,true})do
   local pending=fresh();local cancellation=pending:setOffer(id..'-reset',id,100,55)
   check(pending:purchaseAttempt(1,cancellation.id,cancellation.token,100),id..': reset purchase setup failed')
   if resetDuringCarry then pending:advance(100+Rules.ContestWindow+.01)end
   pending:characterReset(1,103);pending:characterReset(1,103.1)
   check(pending.players[1].cash==10000000-(resetDuringCarry and item.price or 0) and pending.players[1].held==0 and pending.items[cancellation.uid].owner==nil,id..': death refunds bids but forfeits paid carries exactly once')
   -- Reserved bids are cancelled immediately; an empty contest returns to
   -- the moving market on its next server tick, just as in PhaseService.
   pending:advance(103.2)
   check(pending.items[cancellation.uid].state=='Conveyor',id..': death must return uncollected item to conveyor')
   invariant(pending)
  end
  local death=fresh();local starterIncome=death:income(1);local stored=assert(death:grant(1,id))
  check(death:beginSteal(2,stored,110),id..': theft-death setup failed')
  death:characterReset(2,111);death:characterReset(2,112)
  check(death.items[stored].owner==1 and death.items[stored].state=='Stored' and death:income(1)==starterIncome+item.income,id..': thief death must restore existing ownership and retain starter income')
  invariant(death)
  local full=fresh()
  while full:free(1)do check(full:grant(1,id)~=nil,id..': could not fill test base')end
  local rejected=full:setOffer(id..'-full',id,100,55)
  check(not full:purchaseAttempt(1,rejected.id,rejected.token,100),id..': purchase must reject a full base')
  check(full.players[1].cash==10000000 and full.players[1].held==0,id..': rejected full-base purchase must not charge')
 end
 -- Every new collectible uses the same reservation and ownership ledger on
 -- the unlocked upper floor; level bonuses remain local to the current owner.
 for _,item in ipairs(added)do
  local c=fresh()
  local downstairs={}
  for player=1,2 do
   while c:free(player)do check(c:grant(player,'item01')~=nil,'Could not fill original eight downstairs slots')end
   downstairs[player]={};for slot=1,8 do downstairs[player][slot]=c.players[player].slots[slot]end
   local baseIncome=c:income(player)
   for level=1,5 do
    check(c:gainLevel(player),'Could not gain progression level')
    check(c.players[player].capacity==(level<5 and 8 or 16),'Only level five should unlock eight additional slots')
    check(math.abs(c:income(player)-baseIncome*(1+.05*level))<1e-8,'Income must increase in owner-only five-percent level intervals')
    for slot=1,8 do check(c.players[player].slots[slot]==downstairs[player][slot],'Upper floor unlock moved an original item')end
   end
   check(c:free(player)==9,'A full downstairs base should reserve its first new upper-floor slot')
  end
  local sourceIncome,targetIncome=c:income(1),c:income(2)
  local offer=c:setOffer(item.id..'-upper',item.id,100,55)
  check(c:purchaseAttempt(1,offer.id,offer.token,100),item.id..': upper-floor purchase failed')
  local tx=c.transactions[c.players[1].pending]
  check(tx and tx.slot==9 and c.players[1].slots[9]=='@'..tx.id,item.id..': upper-floor escrow reserved the wrong slot')
  c:advance(100+Rules.ContestWindow+.01)
  check(c:finish(1,true,103),item.id..': upper-floor deposit failed')
  check(c.items[offer.uid].slot==9 and c.players[1].slots[9]==offer.uid,item.id..': upper-floor slot was not committed')
  check(c:income(1)==sourceIncome+item.income*1.25,item.id..": upper-floor income missed the owner's level bonus")
  local snapshot=c:snapshot(1,104);local found=0
  for _,entry in ipairs(snapshot.inventory)do if entry.uid==offer.uid then found+=1;check(entry.slot==9,item.id..': snapshot dropped upper slot identity')end end
  check(found==1 and snapshot.capacity==16 and snapshot.secondFloor==true,item.id..': upper-floor inventory/snapshot missing')
  c:characterReset(1,105)
  check(c.items[offer.uid].owner==1 and c.items[offer.uid].slot==9,item.id..': owner death lost upper-floor item')
  check(c:beginSteal(2,offer.uid,110),item.id..': upper-floor theft could not start')
  check(c:income(1)==sourceIncome,item.id..': upper-floor theft must pause source income')
  check(c:finish(2,false,111) and c.items[offer.uid].owner==1 and c.items[offer.uid].slot==9,item.id..': interrupted upper-floor theft must restore original slot')
  check(c:beginSteal(2,offer.uid,112) and c:finish(2,true,113),item.id..': upper-floor theft transfer failed')
  check(c.items[offer.uid].owner==2 and c.items[offer.uid].slot==9 and c.players[1].slots[9]==nil,item.id..': upper-floor theft retained duplicate ownership')
  check(c:income(1)==sourceIncome and c:income(2)==targetIncome+item.income*1.25,item.id..": stolen upper-floor item must use only its new owner's bonus")
  c:characterReset(2,114);invariant(c)
  for player=1,2 do
   while c:free(player)do check(c:grant(player,'item01')~=nil,'Could not fill all sixteen slots')end
   check(c.players[player].capacity==16 and c:grant(player,item.id)==nil,'Sixteen-slot base must reject seventeenth item')
  end
  local rejected=c:setOffer(item.id..'-seventeenth',item.id,120,55);local cash=c.players[1].cash
  check(not c:purchaseAttempt(1,rejected.id,rejected.token,120) and c.players[1].cash==cash and c.players[1].held==0,item.id..': full upper floor must reject purchase without escrow')
  invariant(c)
 end
 local regression=requireModule(package.RegressionTests)(package)
 check(regression.passed==13 and #regression.names==13,'All 13 existing regression groups must execute')
 return string.format('%d checks; all 69 previous definitions preserved exactly; 76 weighted items reachable; all seven new purchase/escrow/carry/deposit/index/income/refund/theft/death/full-base paths; upper-floor slot transactions; 13 existing regression groups',checks)
end
