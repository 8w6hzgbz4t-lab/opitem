-- Reusable pure session tests. Does not touch live game state or Instances.
return function(package)
 local temp=package
 local results={}
 local C=require(temp.Catalog);local config=require(temp.Config);local Core=require(temp.Core);local Powers=require(temp.PowerCatalog)
 local function fresh(n)
  local c=Core.new(C,config);for id=1,n do c:addPlayer(id,0);c.players[id].cash=10000000 end;return c
 end
 local function invariants(c)
  for id,p in pairs(c.players) do
   assert(p.capacity==8 and p.cash>=0 and p.held>=0 and p.cash+p.held<=2000000000)
   local count=0;for slot in pairs(p.slots) do assert(slot>=1 and slot<=8);count+=1 end;assert(count<=8)
   local held=0;for _,tx in pairs(c.transactions) do if tx.player==id and not tx.resolved then held+=tx.amount;assert(p.slots[tx.slot]=='@'..tx.id) end end
   assert(held==p.held,'Escrow invariant')
   if p.carry then local it=c.items[p.carry];assert(it and it.carrier==id and c.transactions[it.tx].status=='Carrying') end
  end
  for uid,it in pairs(c.items) do if it.state=='Stored' then assert(c.players[it.owner].slots[it.slot]==uid) end end
 end
 local c=fresh(2);local o=c:setOffer('a','item01',100,55);local uid=o.uid;local token=o.token
 assert(c:purchaseAttempt(1,'a',token,100));assert(c.players[1].held==100 and c.players[1].cash==9999900)
 assert(c:income(1)==3 and c.items[uid].owner==nil);invariants(c)
 c:advance(101.6);assert(c.players[1].carry==uid and c.items[uid].state=='PurchaseCarry')
 assert(not c:power(1,102,'tag'));assert(c:finish(1,true,102));assert(c.items[uid].owner==1 and c:income(1)==6)
 assert(c.players[1].held==0 and not c:finish(1,true,103));invariants(c)
 results.delivery='Purchase escrow, delayed ownership/income, overhead carry state, successful commit, duplicate completion rejection passed'
 c=fresh(2);o=c:setOffer('a','item17',100,55);token=o.token;uid=o.uid
 assert(c:purchaseAttempt(1,'a',token,100));c:advance(101.6);assert(c:finish(1,false,103))
 assert(o.x==55 and o.expires>103 and o.token~=token and c.items[uid].state=='Conveyor')
 assert(c.players[1].cash==10000000-C.ById.item17.price and c.players[1].held==0 and c:free(1)==2)
 assert(not c:finish(1,false,104));assert(not c:purchaseAttempt(1,'a',token,104));invariants(c)
 assert(c:purchaseAttempt(1,'a',o.token,104));c:advance(106);c.now=107;c:removePlayer(1)
 assert(c.offers.a and c.items[uid].state=='Conveyor');invariants(c)
 results.refunds='Paid carries lost to interruption or disconnect forfeit their purchase price once, retain item UID, restore recorded X, refresh expiry/token and reject stale/replayed actions'
 c=fresh(3);o=c:setOffer('a','item01',100)
 assert(c:purchaseAttempt(1,'a',o.token,100));assert(c:purchaseAttempt(2,'a',o.token,100.5));c:advance(101.6)
 assert(o.state=='Auction' and o.hardEnd==113.5)
 assert(not c:bid(1,'a',0/0,102));assert(not c:bid(1,'a',math.huge,102));assert(not c:bid(1,'a',-1,102))
 assert(c:bid(1,'a',125,102));assert(not c:bid(2,'a',149,102));assert(c:bid(2,'a',175,102.1))
 for i=1,7 do c:grant(3,'item01') end
 assert(not c:bid(3,'a',200,103));assert(c:withdraw(2,103));assert(c.players[2].cash==10000000)
 c:advance(110);assert(c.players[1].carry==o.uid);assert(c:finish(1,true,111))
 assert(c.players[1].cash==10000000-125 and c.players[1].held==0);invariants(c)
 local tie=fresh(2);o=tie:setOffer('t','item01',100);tie:purchaseAttempt(2,'t',o.token,100);tie:purchaseAttempt(1,'t',o.token,100);tie:advance(101.6);tie:advance(110)
 assert(tie.players[2].carry==o.uid and tie.players[1].held==0);invariants(tie)
 local stalled=fresh(2);o=stalled:setOffer('t','item01',100);stalled:purchaseAttempt(1,'t',o.token,100);stalled:purchaseAttempt(2,'t',o.token,100);stalled:advance(1000)
 assert(o.state=='InTransit' and o.hardEnd==113.5);invariants(stalled)
 results.auctions='Simultaneous completion, deterministic ties, invalid/insufficient bids, incremental escrow, full-base rejection, withdrawal, losing refunds, one winner and fixed deadlines after stalls passed'
 c=fresh(2);uid=c.players[1].slots[1]
 for i=1,6 do c:grant(2,'item01') end
 assert(c:beginSteal(2,uid,100));assert(c:income(1)==0 and c.items[uid].owner==1 and c:free(2)==nil)
 assert(c:grant(2,'item17')==nil);assert(not c:power(2,101,'tag'));invariants(c)
 assert(c:finish(2,false,102));assert(c:income(1)==3 and c:free(2)==8)
 assert(c:beginSteal(2,uid,103));assert(c:finish(2,true,104));assert(c.items[uid].owner==2 and c.players[2].steals==1)
 assert(not c:finish(2,true,104));invariants(c)
 results.theft='Income pause, original ownership until deposit, reserved eighth slot, recovery and single transfer passed'
 c=fresh(1);assert(c:chooseStarter(1,'dash'));assert(not c:chooseStarter(1,'dash'))
 assert(c.players[1].loadout[1]=='tag' and not c:loadPower(1,'dash',1))
 assert(c:shopPower(1,'lightning'));assert(c:loadPower(1,'lightning',2));assert(c:power(1,100,'lightning'));assert(not c:power(1,101,'lightning'));assert(c:power(1,129,'lightning'))
 assert(c:unlockPowerSlot(1) and c.players[1].capacity==8);assert(not c:loadPower(1,'tag',3))
 local ranks={};for _,d in ipairs(Powers.Items) do ranks[d.rank]=true end;for i=1,5 do assert(ranks[i]) end
 results.powers='Free starter once, permanent Tag, five ranks, loadout/price validation, third slot without capacity increase and cooldown enforcement passed'
 local function deposit(c,id,kind,t)
  local key='ex'..c.seq;local offer=c:setOffer(key,kind,t);assert(c:purchaseAttempt(id,key,offer.token,t));c:advance(t+1.6);assert(c:finish(id,true,t+2));return offer.uid
 end
 c=fresh(3);local ids={};for i,kind in ipairs({'item25','item26','item27','item28','item29'}) do ids[i]=deposit(c,1,kind,100+i*5) end
 local reward=c.players[1].pendingReward;assert(reward);c:checkExodia(1,200);assert(c.players[1].pendingReward==reward)
 assert(c:claimExodia(1,reward,'level',200));assert(c.players[1].progression==1 and c.players[1].capacity==8);assert(not c:claimExodia(1,reward,'level',201))
 c:checkExodia(1,1000);assert(not c.players[1].pendingReward)
 for i,uid2 in ipairs(ids) do assert(c:beginSteal(2,uid2,1000+i*3));assert(c:finish(2,true,1001+i*3)) end
 assert(not c.players[2].pendingReward);invariants(c)
 c=fresh(3);c:chooseStarter(1,'dash');for i,kind in ipairs({'item25','item26','item27','item28','item29'}) do deposit(c,1,kind,100+i*5) end
 reward=c.players[1].pendingReward
 o=c:setOffer('pending','item17',200);assert(c:purchaseAttempt(2,'pending',o.token,200));c:advance(202)
 local piece=c.players[1].slots[2];assert(c:beginSteal(3,piece,203));assert(c:claimExodia(1,reward,'respawn',204))
 assert(not c.players[2].carry and not c.players[3].carry and c.players[2].cash==10000000)
 assert(c.items[piece].owner==1 and c.items[piece].state=='Stored' and c.players[1].loadout[2]=='dash')
 assert(c.players[1].capacity==8 and c.players[1].powerOwned.dash);invariants(c)
 results.exodia='Distinct deposited pieces, one reward, retained collection/levels, repeated trigger and transfer farming prevention, safe-respawn refund/recovery and power preservation passed'

 results.regressions=require(package.RegressionTests)(package)
 return results
end


