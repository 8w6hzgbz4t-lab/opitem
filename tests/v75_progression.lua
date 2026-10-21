-- Real pure session paths: money upgrades, gifted levels, owner income and
-- sixteen-slot reservation/ownership semantics after the second floor unlock.
return function(package,require)
 local Core=require(package.Core);local Catalog=require(package.Catalog);local Config=require(package.Config)
 local checks=0
 local function check(value,message) checks+=1;assert(value,message) end
 local function close(a,b,message) check(math.abs(a-b)<1e-7,message) end
 local function fresh(n)
  local c=Core.new(Catalog,Config)
  for id=1,n do c:addPlayer(id,0);c.players[id].cash=2000000 end
  return c
 end
 local c=fresh(2);local p=c.players[1]
 check(p.capacity==8 and p.progression==0 and p.level==0,'New base starts at level zero with eight slots')
 check(c:upgradeCost(1)==1500 and c:protectionDuration(1)==30,'Initial upgrade and protection costs')
 local cash=p.cash;check(c:upgrade(1),'Cash upgrade must be available with all eight initial pedestals')
 check(p.cash==cash-1500 and p.progression==1 and p.level==1 and p.capacity==8,'Upgrade charges once and synchronizes level')
 check(c:upgradeCost(1)==2400,'Upgrade cost grows by 1.6 each level')
 close(c:incomeMultiplier(1),1.05,'First level adds five percent')
 close(c:income(1),Catalog.ById[Config.StarterItem].income*1.05,'Owner gets exact five percent of starter income')
 close(c:income(2),Catalog.ById[Config.StarterItem].income,'Another base receives no bonus from owner level')
 check(c:gainLevel(1,3) and p.progression==4 and p.capacity==8,'Levels below five preserve eight slots')
 check(c:gainLevel(1) and p.progression==5 and p.capacity==16,'Level five unlocks exactly eight more slots')
 close(c:incomeMultiplier(1),1.25,'Five levels produce a linear twenty-five percent multiplier')
 check(c:protectionDuration(1)==55,'Each level extends protection by five seconds')
 local snap=c:snapshot(1,100)
 check(snap.capacity==16 and snap.secondFloor and snap.secondFloorLevel==5 and snap.level==5,'Snapshot reports upper floor unlock')
 check(snap.protectionDuration==55 and snap.upgradeCost==15729 and snap.canUpgrade,'Snapshot gives precise upgrade/protection data')
 close(snap.incomeMultiplier,1.25,'Snapshot reports current multiplier')
 local before=p.progression
 for _,amount in ipairs({false,true,'5',0,-1,1.5,101,math.huge,-math.huge,0/0,{}}) do
  check(not c:gainLevel(1,amount),'Malformed, out-of-bounds or noninteger level amount rejected')
  check(p.progression==before and p.capacity==16,'Invalid grant has no partial transition')
 end
 check(not c:gainLevel(999,1),'Missing player cannot receive levels')
 for slot=2,16 do check(c:grant(1,'item01')~=nil,'Every upper/lower slot can receive a grant') end
 check(not c:grant(1,'item01') and c:free(1)==nil,'Seventeenth grant is denied')
 snap=c:snapshot(1,100)
 check(snap.occupied==16 and #snap.inventory==16,'Snapshot includes all sixteen occupied displays')
 for index,row in ipairs(snap.inventory) do check(row.slot==index,'Inventory preserves ordered unique slot identity') end
 local stolen=p.slots[16];p.lockUntil=0
 close(c:income(1),16*Catalog.ById.item01.income*1.25,'Owner income includes upper-floor items')
 check(c:beginSteal(2,stolen,100),'A deposited upper-floor item remains stealable')
 check(c.items[stolen].owner==1 and p.slots[16]==stolen,'Owner retains upper-floor slot while theft is in transit')
 close(c:income(1),15*Catalog.ById.item01.income*1.25,'Carried upper-floor item pauses owner income')
 check(c:finish(2,false,102),'Interrupted upper-floor theft resolves')
 check(c.items[stolen].state=='Stored' and c.items[stolen].slot==16 and c.items[stolen].owner==1,'Failed theft recovers same item in upper slot')
 check(c:beginSteal(2,stolen,103) and c:finish(2,true,104),'Successful upper-floor theft transfers once')
 check(p.slots[16]==nil and c.items[stolen].owner==2,'Successful theft frees original upper slot')
 close(c:income(2),2*Catalog.ById.item01.income,'Stolen income uses new owner level rather than original owner multiplier')
 check(c:characterReset(1,106),'Character reset succeeds with second floor')
 check(p.capacity==16 and p.slots[15] and c.items[p.slots[15]].owner==1,'Death preserves upper-floor stored items and capacity')
 local offer=c:setOffer('upper-purchase','item01',200,55)
 check(c:purchaseAttempt(1,offer.id,offer.token,200),'Upper slot is reserved for a conveyor purchase')
 local tx=c.transactions[p.pending]
 check(tx.slot==16 and p.slots[16]=='@'..tx.id,'Last upper slot uses normal escrow reservation')
 c:advance(202);check(p.carry==offer.uid,'Upper reservation becomes normal overhead carry')
 check(c:finish(1,true,203) and c.items[offer.uid].slot==16,'Normal delivery commits into last upper slot')
 check(c:finish(1,true,204)==false,'Upper-floor delivery cannot commit twice')
 c=fresh(1);p=c.players[1]
 p.cash=1499;check(not c:upgrade(1) and p.cash==1499 and p.level==0,'Insufficient money cannot partially level up')
 p.cash=10000;p.pending='pending';check(not c:upgrade(1),'Bidding blocks paid upgrade')
 p.pending=nil;p.carry='carry';check(not c:upgrade(1),'Carrying blocks paid upgrade')
 p.carry=nil;check(c:gainLevel(1,5),'Gifted level batch is valid')
 local bank=c:income(1);c:tick(1);close(p.bank,bank,'Bank retains fractional five-percent income')
 p.bank=6.75;p.cash=100;check(c:collect(1),'Bank collection succeeds')
 check(p.cash==106,'Collected currency stays whole')
 close(p.bank,.75,'Uncollected cents remain available for future earnings')
 p.cash=1999999999;p.held=1;p.bank=5.75
 check(c:collect(1) and p.cash+p.held==2000000000,'Escrow-inclusive money cap is respected')
 close(p.bank,5.75,'Full cash wallet does not discard stored earnings')
 check(not c:protect(1,29),'Initial protection cannot recharge early')
 check(c:protect(1,30) and p.lockUntil==85 and p.lockReady==90,'Level-five timer and normal recharge are applied')
 check(not c:protect(1,89) and c:protect(1,90),'Protection remains server-clock gated')
 c=fresh(1);p=c.players[1]
 for i=1,10 do check(c:gainLevel(1,100),'Bounded gifts can reach maximum level') end
 check(p.progression==1000 and p.capacity==16 and not c:gainLevel(1,1),'Maximum level is strict and does not add more capacity')
 check(c:upgradeCost(1)==nil and not c:upgrade(1),'Paid upgrade unavailable at maximum level')
 check(c:protectionDuration(1)==180 and c:protect(1,100),'Protection duration caps at three minutes')
 check(p.lockUntil==280 and p.lockReady==280,'Long protection cannot recharge before it expires')
 p.pendingReward='max-reward';check(not c:claimExodia(1,'max-reward','level',300),'Max-level reward does not consume a no-op level choice')
 check(p.pendingReward=='max-reward' and c:claimExodia(1,'max-reward','respawn',301),'Max-level player can still select safe respawn reward')
 snap=c:snapshot(1,400);check(not snap.canUpgrade and snap.capacity==16 and #snap.inventory==1,'Maximum-level snapshot remains finite and honest')
 close(c:incomeMultiplier(1),51,'Maximum income multiplier is finite')
 return tostring(checks)..' progression checks; paid and gifted levels, owner-only five-percent income, protection timers and all sixteen escrow/ownership slots'
end
