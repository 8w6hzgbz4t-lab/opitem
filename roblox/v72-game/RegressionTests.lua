-- Real transaction and hit-gate contracts, isolated from Instances and live players.
return function(package)
 local Core=require(package.Core);local C=require(package.Catalog);local cfg=require(package.Config)
 local Powers=require(package.PowerCatalog);local Hits=require(package.PowerRules)
 local count=0;local names={}
 local function test(name,fn) fn();count+=1;table.insert(names,name) end
 local function fresh(n)
  local c=Core.new(C,cfg);for i=1,n or 2 do c:addPlayer(i,0);c.players[i].cash=10000000 end;return c
 end
 local function deposit(c,id,kind,time)
  local key='test'..c.seq;local o=c:setOffer(key,kind,time,70)
  assert(c:purchaseAttempt(id,key,o.token,time));c:advance(time+1.6);assert(c:finish(id,true,time+2));return o.uid
 end
 local stones={'space_stone','mind_stone','reality_stone','power_stone','time_stone','soul_stone'}
 -- Death and character reset preserve stored UID, occupied slot, ownership and income.
 test('Deposited items survive death and repeated resets',function()
  local c=fresh();local uid=deposit(c,1,'item05',100);local slot=c.items[uid].slot
  c:tick(4);local income,bank=c:income(1),c.players[1].bank
  for i=1,3 do assert(c:characterReset(1,110+i)) end
  assert(c.items[uid].owner==1 and c.items[uid].state=='Stored' and c.players[1].slots[slot]==uid)
  assert(c:income(1)==income and c.players[1].bank==bank)
 end)
 -- A thief's delivered transfer remains authoritative across both players' respawns.
 test('Completed theft remains permanent after both owners respawn',function()
  local c=fresh();local uid=deposit(c,1,'item05',100);local oldSlot=c.items[uid].slot
  assert(c:beginSteal(2,uid,200));assert(c:finish(2,true,202));local slot=c.items[uid].slot
  c:characterReset(1,203);c:characterReset(2,204)
  assert(c.items[uid].owner==2 and c.players[2].slots[slot]==uid and c.players[1].slots[oldSlot]==nil)
  local found=0;for _,p in pairs(c.players) do for _,v in pairs(p.slots) do if v==uid then found+=1 end end end
  assert(found==1 and c:income(1)==3 and c:income(2)==17)
 end)
 -- A cancelled purchase refunds once and never creates a stored copy.
 test('Death refunds pending and carried purchases exactly once',function()
  local c=fresh();local cash=c.players[1].cash;local o=c:setOffer('a','krabby_patty',100)
  assert(c:purchaseAttempt(1,'a',o.token,100));c:characterReset(1,100.3);c:characterReset(1,100.4)
  assert(c.players[1].cash==cash and c.players[1].held==0 and c:free(1)==2)
  c:advance(102);assert(c:purchaseAttempt(1,'a',o.token,102));c:advance(104)
  assert(c.players[1].carry);c:characterReset(1,105);c:characterReset(1,106)
  assert(c.players[1].cash==cash and c.items[o.uid].state=='Conveyor' and not c.items[o.uid].owner)
 end)
 -- Undelivered theft recovers to the original owner without changing its occupied slot.
 test('Death recovers an unfinished theft',function()
  local c=fresh();local uid=deposit(c,1,'hylian_shield',100);local slot=c.items[uid].slot
  assert(c:beginSteal(2,uid,200));c:characterReset(2,201)
  assert(c.items[uid].owner==1 and c.items[uid].state=='Stored' and c.players[1].slots[slot]==uid and c:free(2)==2)
 end)
 -- Grant/admin, escrow and duplicate copies cannot substitute for five distinct deposits.
 test('Only five distinct deposited stone kinds grant a level',function()
  local c=fresh();deposit(c,1,stones[1],100);deposit(c,1,stones[1],105)
  for i=2,4 do deposit(c,1,stones[i],110+i*5) end
  local grant=c:grant(1,stones[5]);assert(grant);assert(not c:checkInfinity(1,150));assert(c.players[1].progression==0)
  assert(c:sell(1,grant));local o=c:setOffer('fifth',stones[5],160)
  assert(c:purchaseAttempt(1,'fifth',o.token,160));assert(not c:checkInfinity(1,160));c:advance(162)
  assert(not c:checkInfinity(1,162));assert(c:finish(1,true,163));assert(c.players[1].progression==1)
  assert(c.infinityAwarded[1] and c.items[o.uid].state=='Stored')
 end)
 -- Sixth stones, death, sale, completed theft, and reacquisition never repeat a player's reward.
 test('Infinity reward stays once-only after transfers resets and sixth stone',function()
  local c=fresh();local ids={};for i=1,5 do ids[i]=deposit(c,1,stones[i],100+i*5) end
  assert(c.players[1].progression==1);deposit(c,1,stones[6],150)
  c:characterReset(1,160);assert(not c:checkInfinity(1,161));assert(c.players[1].progression==1)
  for i,uid in ipairs(ids) do assert(c:beginSteal(2,uid,200+i*5));assert(c:finish(2,true,202+i*5)) end
  assert(c.players[2].progression==1)
  for i,uid in ipairs(ids) do assert(c:beginSteal(1,uid,250+i*5));assert(c:finish(1,true,252+i*5)) end
  assert(c.players[1].progression==1);assert(c:sell(1,ids[1]));deposit(c,1,stones[1],300)
  assert(c.players[1].progression==1)
 end)
 -- Session reward memory survives a leave/rejoin; collection still resets on leave.
 test('Infinity reward cannot be farmed by rejoining the same session',function()
  local c=fresh();for i=1,5 do deposit(c,1,stones[i],100+i*5) end
  c:removePlayer(1);c:addPlayer(1,200);c.players[1].cash=10000000
  for i=1,5 do deposit(c,1,stones[i],220+i*5) end
  assert(c.players[1].progression==0 and c.infinityAwarded[1])
 end)
 -- No shared token or cooldown can suppress Exodia after the independent stone reward.
 test('Exodia remains independent from Infinity collection',function()
  local c=fresh();local ids={};for i=1,5 do ids[i]=deposit(c,1,stones[i],100+i*5) end
  for _,uid in ipairs(ids) do assert(c:sell(1,uid)) end
  for i,kind in ipairs({'item25','item26','item27','item28','item29'}) do deposit(c,1,kind,200+i*5) end
  local token=c.players[1].pendingReward;assert(token);assert(c:claimExodia(1,token,'level',250));assert(c.players[1].progression==2)
 end)
 -- The server consumes one shield hit; time and immunity cannot create a permanent shield.
 test('Shield consumes one incoming hit and expires',function()
  local target={shield=103,shieldHits=1};assert(Hits.hit(target,'tag',100,4)=='shield')
  assert(target.shield==0 and target.shieldHits==0);assert(Hits.hit(target,'tag',100.1,4)=='hit')
  assert(Hits.hit({shield=99,shieldHits=1},'lightning',100,4)=='hit')
 end)
 -- Repeated lightning cannot bypass immunity, including different casters.
 test('Repeated stuns respect the shared immunity window',function()
  local target={};assert(Hits.hit(target,'lightning',100,4)=='hit')
  assert(Hits.hit(target,'lightning',101,4)=='immune');assert(Hits.hit(target,'lightning',104,4)=='hit')
 end)
 -- Migration retains purchase ownership and cooldowns, and never duplicates Tag or slots.
 test('Removed powers migrate without cooldown bypass',function()
  local c=fresh();local p=c.players[1];p.powerOwned={tag=true,push=true,gust=true,storm=true};p.loadout={'tag','push','gust'};p.powerSlots=3;p.powerReady={push=150,gust=160}
  c:snapshot(1,120);assert(p.loadout[1]=='tag' and p.loadout[2]=='dash' and p.loadout[3]==nil)
  assert(p.powerReady.dash==160 and not c:power(1,120,'dash'));assert(c:power(1,161,'dash'))
  assert(not c:power(1,161.1,'tag'));assert(not c:power(1,162,'dash'))
  assert(#Powers.Items==8)
 end)
 -- Every new kind uses the generic escrow, delivery and permanent theft routes.
 test('All new collectibles purchase deliver steal and enter the index',function()
  for _,d in ipairs(C.Items) do if d.id:sub(1,4)~='item' then
   local c=fresh();local uid=deposit(c,1,d.id,100)
   assert(c.players[1].seen[d.id] and c.items[uid].kind==d.id)
   assert(c:beginSteal(2,uid,200));assert(c:finish(2,true,202));c:characterReset(1,203)
   assert(c.items[uid].owner==2 and c.players[2].seen[d.id])
  end end
 end)
 -- Item-type weighting does not accidentally reduce unrelated Minecraft collectibles.
 test('Weights speed and existing gameplay contracts remain correct',function()
  assert(C.ById.item01.spawnWeight==.5 and C.ById.item30.spawnWeight==.5 and C.ById.item31.spawnWeight==.5)
  assert(C.ById.item32.spawnWeight==.85 and C.ById.item33.spawnWeight==.55)
  assert(C.ById.item20.spawnWeight==1.3*.2 and C.Weights[3]==22.5 and C.Weights[4]==12.5)
  assert(C.ById.death_note and C.ById.death_note.rarity=='Legendary')
  local total=0;local cumulative=0
  for i,name in ipairs(C.Tiers) do
   local weight=C.RarityWeights[name];assert(weight and weight>0 and #C.ByTier[i]>0);total+=weight
  end
  for tier,name in ipairs(C.Tiers) do
   local weight=C.RarityWeights[name]
   local fake={values={(cumulative+weight*.5)/total,.5}}
   function fake:NextNumber() return table.remove(self.values,1) end
   local id=C.roll(fake);assert(C.ById[id].tier==tier,'Relative spawn weight did not select '..name)
   cumulative+=weight
  end
  assert(cfg.ConveyorSpeed==8.8 and cfg.ConveyorInterval==3 and cfg.BaseSlots==8 and cfg.ProtectionDuration==30)
  assert(require(package.PhaseConfig).HoldSeconds==.35)
  for _,id in ipairs(stones) do assert(C.ById[id].tier==5 and C.ById[id].infinityStone) end
  assert(C.ById.pekka and C.ById.mega_knight and C.ById.item43.name=='Dragon Balls')
 end)
 return {passed=count,names=names}
end
