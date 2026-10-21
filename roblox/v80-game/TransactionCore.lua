-- Pure session transactions. No Instances, yielding or client authority in state transitions.
local T={}
local Rules=require(script.Parent.PhaseConfig)
local Powers=require(script.Parent.PowerCatalog)
local function valid(n) return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge end
function T.install(Core)
 local originalNew,originalAdd,originalGrant=Core.new,Core.addPlayer,Core.grant
 function Core.new(catalog,config)
  local self=originalNew(catalog,config);self.transactions={};self.now=0;self.exodiaUsed={};self.infinityAwarded={};return self
 end
 function Core:nextId(prefix) self.seq+=1;return prefix..self.seq end
 function Core:addPlayer(id,now)
  local p=originalAdd(self,id,now);p.held=0;p.pending=nil;p.progression=0;p.powerSlots=2
  p.powerOwned={tag=true};p.loadout={'tag'};p.powerReady={};p.starterChosen=false;p.rewardReady=0
  return p
 end
 function Core:grant(id,kind)
  local uid=originalGrant(self,id,kind);if uid then self.items[uid].state='Stored';self.items[uid].deposited=false end;return uid
 end
 function Core:setOffer(index,kind,now,x)
  assert(self.catalog.ById[kind]);assert(not self.offers[index],'Offer ID cannot be reused while active')
  now=now or self.now;x=x or self.config.ConveyorStartX
  local uid=self:nextId('relic');local token=self:nextId('offer')
  self.items[uid]={uid=uid,kind=kind,state='Conveyor',offer=index}
  self.offers[index]={id=index,uid=uid,kind=kind,token=token,state='Conveyor',x=x,last=now,expires=now+math.min(Rules.ReturnLifetime,(x-self.config.ConveyorEndX)/self.config.ConveyorSpeed),bids={}}
  self:changed();return self.offers[index]
 end
 function Core:eligible(id)
  local p=self.players[id];return p and not p.carry and not p.pending and self:free(id)~=nil
 end
 function Core:reserve(id,o,amount,now)
  local p=self.players[id]
  if not self:eligible(id) or not valid(amount) or amount<0 or amount%1~=0 or p.cash<amount then return nil,'Funds, space or player state changed.' end
  local txid=self:nextId('tx');local slot=self:free(id)
  local tx={id=txid,player=id,uid=o.uid,offer=o.id,slot=slot,amount=amount,status='Reserved',started=now,pickupX=o.x,order=self.seq}
  p.cash-=amount;p.held+=amount;p.slots[slot]='@'..txid;p.pending=txid
  self.transactions[txid]=tx;self:changed();return tx
 end
 function Core:release(tx,status,now,commit)
  if not tx or tx.resolved then return false end
  local p=self.players[tx.player]
  if p then
   if p.slots[tx.slot]=='@'..tx.id then p.slots[tx.slot]=nil end
   p.held-=tx.amount
   if not commit then p.cash+=tx.amount end
   if p.pending==tx.id then p.pending=nil end
   if p.carry==tx.uid then p.carry=nil end
  end
  tx.resolved=true;tx.status=status;tx.finished=now;self:changed();return true
 end
 function Core:availableOffer(o,now)
  return o and ((o.state=='Conveyor' and o.x>Rules.DisposalEntryX and now<o.expires) or o.state=='Contesting')
 end
 function Core:purchaseAttempt(id,index,token,now)
  self.now=now;local o=self.offers[index]
  if not self:availableOffer(o,now) or o.token~=token then return false,'Offer unavailable.' end
  if o.state=='Contesting' and now>=o.contestEnd then return false,'Contest window closed.' end
  local tx,msg=self:reserve(id,o,self.catalog.ById[o.kind].price,now);if not tx then return false,msg end
  o.bids[id]=tx.id
  if o.state=='Conveyor' then o.state='Contesting';o.contestEnd=now+Rules.ContestWindow;self.items[o.uid].state='Contesting' end
  self:changed();return true,'Funds and slot reserved.',tx.id
 end
 function Core:buy(id,index,token) return self:purchaseAttempt(id,index,token,self.now) end
 function Core:leader(o)
  local best
  for _,txid in pairs(o.bids) do local tx=self.transactions[txid]
   if tx and not tx.resolved and self.players[tx.player] then
    if not best or tx.amount>best.amount or (tx.amount==best.amount and (tx.order<best.order or (tx.order==best.order and tx.player<best.player))) then best=tx end
   end
  end
  return best
 end
 function Core:withdraw(id,now)
  local p=self.players[id];local tx=p and self.transactions[p.pending]
  if not tx or tx.resolved then return false end
  local o=self.offers[tx.offer];if o then o.bids[id]=nil end
  return self:release(tx,'Cancelled',now,false)
 end
 function Core:pickup(o,tx,now)
  if not tx or tx.resolved then return false end
  local p=self.players[tx.player];if not p or p.carry or p.pending~=tx.id then return false end
  local losing={};for _,other in pairs(o.bids) do if other~=tx.id then table.insert(losing,other) end end
  for _,other in ipairs(losing) do self:release(self.transactions[other],'Lost',now,false) end
  o.bids={};o.state='InTransit';o.tx=tx.id
  tx.status='Carrying';tx.started=now;tx.pickupX=o.x
  p.pending=nil;p.carry=tx.uid
  local it=self.items[tx.uid];it.state='PurchaseCarry';it.carrier=tx.player;it.tx=tx.id;it.started=now
  self:changed();return true
 end
 function Core:bid(id,index,amount,now)
  local o=self.offers[index]
  if not o or o.state~='Auction' or now>=o.endAt or not valid(amount) or amount%1~=0 or amount>2000000000 then return false,'Auction or bid invalid.' end
  local best=self:leader(o);local minimum=(best and best.amount or self.catalog.ById[o.kind].price)+math.max(Rules.MinimumBid,math.ceil(self.catalog.ById[o.kind].price*Rules.BidFraction))
  if amount<minimum then return false,'Minimum bid is $'..minimum end
  local p=self.players[id];local txid=o.bids[id];local tx=txid and self.transactions[txid]
  if not tx or tx.resolved then
   local created,msg=self:reserve(id,o,amount,now);if not created then return false,msg end
   tx=created;o.bids[id]=tx.id
  else
   if not p or p.pending~=tx.id or p.carry or p.cash<amount-tx.amount then return false,'Insufficient available funds.' end
   local delta=amount-tx.amount;p.cash-=delta;p.held+=delta;tx.amount=amount
  end
  o.endAt=math.min(o.hardEnd,math.max(o.endAt,now+Rules.AuctionExtendSeconds));self:changed();return true,'Bid reserved.'
 end
 function Core:returnOffer(o,tx,now)
  if not o or not self.items[o.uid] then return end
  o.state='Conveyor';o.x=tx and tx.pickupX or o.x;o.last=now;o.tx=nil;o.bids={};o.token=self:nextId('offer')
  o.expires=now+math.min(Rules.ReturnLifetime,math.max(.01,(o.x-self.config.ConveyorEndX)/self.config.ConveyorSpeed))
  local it=self.items[o.uid];it.state='Conveyor';it.carrier=nil;it.tx=nil;it.started=nil
 end
 function Core:finish(id,success,now,recovery)
  now=now or self.now;local p=self.players[id];local it=p and self.items[p.carry];local tx=it and self.transactions[it.tx]
  if not tx or tx.resolved or tx.player~=id or tx.status~='Carrying' then return false end
  local old=it.owner and self.players[it.owner]
  if success and (tx.type~='Theft' or old) and p.slots[tx.slot]=='@'..tx.id then
   if old and tx.type=='Theft' then old.slots[it.slot]=nil;if old.equipped==it.uid then old.equipped=nil end;p.steals+=1 end
   self:release(tx,'Delivered',now,true)
   it.owner=id;it.slot=tx.slot;it.state='Stored';it.carrier=nil;it.tx=nil;it.started=nil;it.deposited=true
   p.slots[tx.slot]=it.uid;p.seen[it.kind]=true;p.equipped=p.equipped or it.uid
   if tx.offer then self.offers[tx.offer]=nil;it.offer=nil end
   self:checkExodia(id,now);self:checkInfinity(id,now)
  else
   -- A paid pickup is a committed wager: combat, death, timeout and leaving
   -- return the relic, never its purchase price. Only the server's forced
   -- safe-respawn event can unwind a carry without penalizing its buyer.
   local lostPurchase=tx.type~='Theft' and recovery~='SafeRespawn'
   self:release(tx,lostPurchase and 'Lost' or 'Cancelled',now,lostPurchase)
   if tx.type=='Theft' then
    it.carrier=nil;it.tx=nil;it.started=nil
    if old then it.state='Stored' else self.items[it.uid]=nil end
   else self:returnOffer(self.offers[tx.offer],tx,now) end
  end
  self:changed();return true
 end
 function Core:beginSteal(id,uid,now)
  local p,it=self.players[id],self.items[uid]
  local old=it and it.owner and self.players[it.owner]
  if not p or not it or it.state~='Stored' or it.owner==id or not old or now<old.lockUntil then return false,'Relic unavailable or protected.' end
  local tx,msg=self:reserve(id,{uid=uid,x=0},0,now);if not tx then return false,msg end
  tx.type='Theft';tx.status='Carrying';p.pending=nil;p.carry=uid
  it.carrier=id;it.tx=tx.id;it.state='TheftCarry';it.started=now;self:changed();return true,'Carry it to your delivery pad.'
 end
 function Core:expireOffer(id,now)
  local o=self.offers[id];if not o or o.state=='InTransit' then return false end
  for _,txid in pairs(o.bids) do self:release(self.transactions[txid],'Expired',now,false) end
  self.items[o.uid]=nil;self.offers[id]=nil;self:changed();return true
 end
 function Core:advance(now)
  self.now=now
  for id,o in pairs(self.offers) do
   if o.state=='Conveyor' then
    o.x-=self.config.ConveyorSpeed*math.max(0,now-o.last);o.last=now
    if o.x<=self.config.ConveyorEndX or now>=o.expires then self:expireOffer(id,now) end
   elseif o.state=='Contesting' and now>=o.contestEnd then
    local count=0;for _,txid in pairs(o.bids) do local tx=self.transactions[txid];if tx and not tx.resolved then count+=1 end end
    if count>=2 then
     o.state='Auction';self.items[o.uid].state='Auction';o.endAt=o.contestEnd+Rules.AuctionSeconds;o.hardEnd=o.contestEnd+Rules.AuctionMaxSeconds;self:changed()
     if now>=o.endAt then self:pickup(o,self:leader(o),now) end
    else local best=self:leader(o);if best then self:pickup(o,best,now) else self:returnOffer(o,nil,now) end end
   elseif o.state=='Auction' and now>=o.endAt then
    local best=self:leader(o);if best then self:pickup(o,best,now) else self:returnOffer(o,nil,now) end
   end
  end
  for txid,tx in pairs(self.transactions) do if tx.resolved and now-tx.finished>Rules.LedgerRetention then self.transactions[txid]=nil end end
 end
 function Core:incomeMultiplier(id)
  local p=self.players[id];return p and (1+(p.progression or 0)*.05) or 1
 end
 function Core:income(id)
  local income=0;for _,it in pairs(self.items) do if it.owner==id and it.state=='Stored' then income+=self.catalog.ById[it.kind].income end end
  -- Keep cents in the bank so every five-percent level increment is retained.
  local level=self.players[id] and (self.players[id].progression or 0) or 0
  return math.floor(income*(100+level*5)+.5)/100
 end
 function Core:sell(id,uid)
  local p,it=self.players[id],self.items[uid]
  if not p or not it or it.owner~=id or it.state~='Stored' or p.carry then return false,'Relic unavailable.' end
  p.cash=math.min(2000000000-p.held,p.cash+math.floor(self.catalog.ById[it.kind].price*.5));p.slots[it.slot]=nil
  if p.equipped==uid then p.equipped=nil end;self.items[uid]=nil;self:changed();return true,'Sold.'
 end
 function Core:collect(id)
  local p=self.players[id];if not p then return false end
  local amount=math.floor(math.min(p.bank,2000000000-p.cash-p.held));p.cash+=amount;p.bank-=amount;self:changed();return true,'Collected $'..amount
 end
 function Core:removePlayer(id)
  local p=self.players[id];if not p then return end
  self:withdraw(id,self.now);self:finish(id,false,self.now)
  for other,op in pairs(self.players) do local it=self.items[op.carry];if it and it.owner==id then self:finish(other,false,self.now) end end
  for uid,it in pairs(self.items) do if it.owner==id then self.items[uid]=nil end end
  self.players[id]=nil;self:changed()
 end
 function Core:cancelAll(now)
  -- Trusted Exodia safe-respawn recovery; no remote accepts this policy value.
  for id in pairs(self.players) do self:withdraw(id,now);self:finish(id,false,now,'SafeRespawn') end
  for _,o in pairs(self.offers) do if o.state=='Auction' or o.state=='Contesting' then self:returnOffer(o,nil,now) end end
 end
 -- Character resets only unwind pending/carry transactions. Stored ownership is untouched.
 function Core:characterReset(id,now)
  if not self.players[id] then return false end
  self:withdraw(id,now);self:finish(id,false,now);self:changed();return true
 end
 function Core:gainLevel(id,amount)
  local p=self.players[id];if amount==nil then amount=1 end
  if not p or not valid(amount) or amount%1~=0 or amount<1 or amount>100 or (p.progression or 0)+amount>1000 then return false,'Level grant unavailable.' end
  p.progression=(p.progression or 0)+amount;p.level=p.progression
  p.capacity=p.progression>=5 and 16 or 8
  self:changed();return true,'Level '..p.progression..' reached.'
 end
 function Core:upgradeCost(id)
  local p=self.players[id];if not p or (p.progression or 0)>=1000 then return nil end
  local level=p.progression or 0
  return level>=31 and 2000000000 or math.min(2000000000,math.floor(1500*1.6^level+.5))
 end
 function Core:upgrade(id)
  local p=self.players[id]
  if not p or p.carry or p.pending then return false,'Deliver carried loot or leave the bid battle first.' end
  local cost=self:upgradeCost(id)
  if not cost then return false,'Maximum base level reached.' end
  if p.cash<cost then return false,'Upgrade costs $'..cost end
  local ok,msg=self:gainLevel(id)
  if not ok then return false,msg end
  p.cash-=cost
  return true,'Base level '..p.progression..'. Income +'..(p.progression*5)..'% and '..self:protectionDuration(id)..'s protection.'
 end
 function Core:protectionDuration(id)
  local p=self.players[id]
  return math.min(180,(self.config.ProtectionDuration or 30)+(p and (p.progression or 0) or 0)*5)
 end
 function Core:protect(id,now)
  local p=self.players[id]
  if not p or not valid(now) then return false,'No vault.' end
  if now<p.lockReady then return false,'Protection recharges in '..math.ceil(p.lockReady-now)..'s.' end
  local duration=self:protectionDuration(id)
  p.lockUntil=now+duration;p.lockReady=now+math.max(self.config.ProtectionRecharge or 60,duration)
  self:changed();return true,'Stored relics protected for '..duration..'s.'
 end
 function Core:checkInfinity(id,now)
  local p=self.players[id];if not p or self.infinityAwarded[id] then return false end
  local kinds={};local count=0
  for _,uid in pairs(p.slots) do
   local it=self.items[uid];local d=it and self.catalog.ById[it.kind]
   if it and d and d.infinityStone and it.owner==id and it.state=='Stored' and it.deposited and not kinds[it.kind] then kinds[it.kind]=true;count+=1 end
  end
  if count<5 then return false end
  -- Mark before awarding; retained for the entire session, including leave/rejoin.
  self.infinityAwarded[id]=true;self:gainLevel(id);p.infinityCelebration=true
  return true
 end
 function Core:migratePowers(id)
  local p=self.players[id];if not p then return end
  p.powerOwned=p.powerOwned or {};p.powerReady=p.powerReady or {};p.loadout=p.loadout or {}
  for old,new in pairs(Powers.Replacements) do
   if p.powerOwned[old] then p.powerOwned[new]=true end
   p.powerReady[new]=math.max(p.powerReady[new] or 0,p.powerReady[old] or 0)
   p.powerOwned[old]=nil;p.powerReady[old]=nil
   for slot=2,3 do if p.loadout[slot]==old then p.loadout[slot]=new end end
  end
  local used={tag=true};p.powerOwned.tag=true;p.loadout[1]='tag'
  for slot=2,3 do local key=p.loadout[slot];if key and (not Powers.ById[key] or not p.powerOwned[key] or used[key]) then p.loadout[slot]=nil elseif key then used[key]=true end end
 end
 function Core:chooseStarter(id,kind)
  local p=self.players[id];local d=Powers.ById[kind]
  if not p or p.starterChosen or not d or not d.starter then return false,'Starter unavailable.' end
  p.starterChosen=true;p.powerOwned[kind]=true;p.loadout[2]=kind;self:changed();return true,'Starter chosen.'
 end
 function Core:shopPower(id,kind)
  local p=self.players[id];local d=Powers.ById[kind]
  if not p or p.carry or p.pending or not d or p.powerOwned[kind] or p.cash<d.price then return false,'Power unavailable or insufficient available funds.' end
  p.cash-=d.price;p.powerOwned[kind]=true;self:changed();return true,'Power unlocked.'
 end
 function Core:loadPower(id,kind,slot)
  local p=self.players[id]
  if not p or p.carry or p.pending or (slot~=2 and slot~=3) or slot>p.powerSlots or kind=='tag' or not Powers.ById[kind] or not p.powerOwned[kind] then return false,'Invalid power loadout.' end
  for i=2,3 do if p.loadout[i]==kind then p.loadout[i]=nil end end
  p.loadout[slot]=kind;p.loadout[1]='tag';self:changed();return true,'Loadout updated.'
 end
 function Core:unlockPowerSlot(id)
  local p=self.players[id];if not p or p.carry or p.pending or p.powerSlots==3 then return false,'Slot unavailable.' end
  if p.progression<1 then if p.cash<Rules.ThirdSlotPrice then return false,'Third slot costs $'..Rules.ThirdSlotPrice end;p.cash-=Rules.ThirdSlotPrice end
  p.powerSlots=3;self:changed();return true,'Third power slot unlocked.'
 end
 function Core:power(id,now,kind)
  self:migratePowers(id)
  local p=self.players[id];kind=kind or (p and p.loadout[2]) or 'tag';local d=Powers.ById[kind]
  if not p or not d or p.carry or p.pending then return false,'Powers unavailable while carrying or bidding.' end
  local equipped=false;for _,key in pairs(p.loadout) do if key==kind then equipped=true end end
  if not equipped or not p.powerOwned[kind] then return false,'Power is not equipped.' end
  if now<(p.castReady or 0) then return false,'Power recovering.' end
  if now<(p.powerReady[kind] or 0) then return false,'Power recharging.' end
  p.castReady=now+math.max(.3,d.windup);p.powerReady[kind]=now+d.cooldown;self:changed();return true,kind
 end
 function Core:checkExodia(id,now)
  local p=self.players[id];if not p or p.pendingReward or now<p.rewardReady then return end
  local pieces={}
  for _,kind in ipairs(Rules.ExodiaKinds) do
   for _,uid in pairs(p.slots) do local it=self.items[uid]
    if it and it.kind==kind and it.owner==id and it.state=='Stored' and it.deposited and not self.exodiaUsed[uid] then pieces[#pieces+1]=uid;break end
   end
  end
  if #pieces~=5 then return end
  for _,uid in ipairs(pieces) do self.exodiaUsed[uid]=true end
  p.pendingReward=self:nextId('exodia');p.rewardReady=now+Rules.ExodiaCooldown;self:changed()
 end
 function Core:claimExodia(id,token,choice,now)
  local p=self.players[id]
  if not p or not p.pendingReward or token~=p.pendingReward or (choice~='respawn' and choice~='level') then return false,'Reward unavailable.' end
  if choice=='level' and p.progression>=1000 then return false,'Maximum base level reached. Choose the respawn reward.' end
  p.pendingReward=nil;p.rewardReady=math.max(p.rewardReady,now+Rules.ExodiaCooldown)
  if choice=='level' then self:gainLevel(id) else self:cancelAll(now) end
  self:changed();return true,choice
 end
 function Core:snapshot(id,now)
  self:migratePowers(id)
  local p=self.players[id];if not p then return nil end;local inv={};local occupied=0
  for slot=1,p.capacity do
   if p.slots[slot] then occupied+=1 end
   local it=self.items[p.slots[slot]]
   if it and it.owner==id then inv[#inv+1]={uid=it.uid,kind=it.kind,slot=slot,carried=it.state=='TheftCarry'} end
  end
  local ready={};for _,d in ipairs(Powers.Items) do ready[d.id]=math.max(0,(p.powerReady[d.id] or 0)-now) end
  return {thirdSlotPrice=Rules.ThirdSlotPrice,cash=p.cash,held=p.held,bank=p.bank,income=self:income(id),capacity=p.capacity,occupied=occupied,level=p.progression,upgradeCost=self:upgradeCost(id),canUpgrade=p.progression<1000,protectionDuration=self:protectionDuration(id),incomeMultiplier=self:incomeMultiplier(id),secondFloor=p.capacity==16,secondFloorLevel=5,inventory=inv,seen=p.seen,equipped=p.equipped,carry=p.carry,pending=p.pending,steals=p.steals,lock=math.max(0,math.ceil(p.lockUntil-now)),lockReady=math.max(0,math.ceil(p.lockReady-now)),cooldown=math.ceil(ready[p.loadout[2] or 'tag'] or 0),revision=self.revision,powerOwned=p.powerOwned,loadout=p.loadout,powerSlots=p.powerSlots,powerReady=ready,starterPending=not p.starterChosen,exodia=p.pendingReward}
 end
 return Core
end
return T

