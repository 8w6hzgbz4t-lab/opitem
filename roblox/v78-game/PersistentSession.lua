-- Serialize durable economy changes before the server acknowledges them.
-- A storage failure stops play; unconfirmed memory is never saved over good data.
local Codec=require(script.Parent.ProfileCodec)
local S={};S.__index=S
local MAX_CASH=2000000000
local function clone(v)
 if type(v)~='table'then return v end
 local out={};for k,x in pairs(v)do out[k]=clone(x)end;return out
end
local function equal(a,b)
 if type(a)~=type(b)then return false end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not equal(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local fields={'players','items','offers','transactions','exodiaUsed','infinityAwarded','seq','revision','now'}
local function backup(core)
 local references={}
 local function snapshot(value)
  if type(value)~='table'then return value end
  local out={};references[out]=value
  for k,v in pairs(value)do out[k]=snapshot(v)end;return out
 end
 local out={};for _,key in ipairs(fields)do out[key]=snapshot(core[key])end
 return{values=out,references=references}
end
local function rollback(core,saved)
 local function restore(value)
  if type(value)~='table'then return value end
  local target=saved.references[value]or{};table.clear(target)
  for k,v in pairs(value)do target[k]=restore(v)end;return target
 end
 for _,key in ipairs(fields)do core[key]=restore(saved.values[key])end
end
local methods={'purchaseAttempt','bid','withdraw','pickup','expireOffer','finish','beginSteal','sell','collect',
 'upgrade','gainLevel','shopPower','chooseStarter','loadPower','unlockPowerSlot','grant','claimExodia',
 'checkExodia','checkInfinity','protect','equip','characterReset','cancelAll'}
function S.new(core,store,ctx)
 local self=setmetatable({core=core,store=store,ctx=ctx or{},loaded={},loading={},rate={},pendingSettings={},depth=0,original={},failed=false},S)
 self.clock=self.ctx.clock or os.clock;self.wall=self.ctx.wall or os.time
 self.wait=self.ctx.wait or task.wait
 self.guid=assert(self.ctx.guid,'Unique item IDs require a server GUID factory')
 self.namespace=self.guid();core.persistenceBusy=false
 -- Prefix every persistent item/reward ID across servers. Models/stats are unchanged.
 core.nextId=function(c,prefix)c.seq+=1;return self.namespace..':'..prefix..c.seq end
 for _,name in ipairs(methods)do
  local original=core[name];self.original[name]=original
  core[name]=function(c,...)
   local args=table.pack(...)
   if self.depth>0 and self.ownerThread==coroutine.running()then return self:_invoke(name,original,args)end
   if name=='grant'and self.loading[args[1]]then return self:_invoke(name,original,args)end
   return self:_change(name,args,function()return self:_invoke(name,original,args)end)
  end
 end
 return self
end
function S:_invoke(name,original,args)
 local result=table.pack(original(self.core,table.unpack(args,1,args.n)))
 if name=='grant'and type(result[1])=='string'then
  local uid=result[1];local item=self.core.items[uid]
  if item then
   local fresh=self.core:nextId('relic');self.core.items[uid]=nil;item.uid=fresh;self.core.items[fresh]=item
   local p=self.core.players[item.owner];p.slots[item.slot]=fresh;if p.equipped==uid then p.equipped=fresh end
   result[1]=fresh
  end
 end
 return table.unpack(result,1,result.n)
end
function S:isReady(id)
 return not self.failed and self.loaded[id]==true and self.store:isReady(id)
end
function S:canPurchase(id)
 if not self:isReady(id)or self.core.persistenceBusy then return false,'Saved profile is not ready.'end
 local count=0;for _ in pairs(self.core.players[id].receipts)do count+=1 end
 if count>=Codec.MaxReceipts then return false,'Purchases are unavailable while your receipt history needs maintenance.'end
 if self.ctx.canStore then
  local data=Codec.capture(self.core,id,self.clock(),self.wall())
  if not data or not self.ctx.canStore(data,10000)then return false,'Purchases are unavailable while your saved profile needs maintenance.'end
 end
 return true
end
function S:_fatal(why)
 self.failed=true;self.core.persistenceBusy=true
 if self.ctx.onFailure then self.ctx.onFailure(tostring(why))end
 return false,'Saved progress is unavailable. Rejoin when storage recovers.'
end
function S:_ids(name,args)
 local ids={};local used={}
 local function add(id)if id and self.loaded[id]and not used[id]then used[id]=true;ids[#ids+1]=id end end
 if name=='cancelAll'or name=='claimExodia'or name=='admin'then for id in pairs(self.loaded)do add(id)end
 elseif name=='pickup'or name=='expireOffer'then
  local o=name=='pickup'and args[1]or self.core.offers[args[1]]
  if o then for id in pairs(o.bids)do add(id)end end
  if name=='pickup'and args[2]then add(args[2].player)end
 else
  add(args[1]);local p=self.core.players[args[1]]
  if name=='finish'or name=='characterReset'then local it=p and self.core.items[p.carry];if it then add(it.owner)end end
  if name=='beginSteal'then local it=self.core.items[args[2]];if it then add(it.owner)end end
 end
 table.sort(ids);return ids
end
function S:_capture(ids,now,wall)
 local data={}
 for _,id in ipairs(ids)do
  local value,why=Codec.capture(self.core,id,now,wall)
  if not value then return nil,why end
  data[id]=value
 end
 return data
end
function S:_budget(ids,cost)
 local now=self.clock()
 for _,id in ipairs(ids)do
  local r=self.rate[id]or{tokens=6,time=now};self.rate[id]=r
  r.tokens=math.min(6,r.tokens+math.max(0,now-r.time)*.25);r.time=now
  if r.tokens<cost then return false end
 end
 for _,id in ipairs(ids)do self.rate[id].tokens-=cost end
 return true
end
function S:_redeem(ids)
 for _,id in ipairs(ids)do local p=self.core.players[id]
  local amount=math.min(p.paidCashCredit or 0,math.max(0,MAX_CASH-p.cash-p.held))
  if amount>0 then p.cash+=amount;p.paidCashCredit-=amount end
 end
end
function S:_change(name,args,callback,urgent)
 if self.failed or self.core.persistenceBusy then return false,'Progress is saving. Please try again.'end
 local ids=self:_ids(name,args)
 if #ids==0 then return false,'Saved profile is not ready.'end
 for _,id in ipairs(ids)do if not self:isReady(id)then return self:_fatal('Profile lease is not ready: '..id)end end
 local now,wall=self.clock(),self.wall()
 local before,why=self:_capture(ids,now,wall);if not before then return self:_fatal(why)end
 local saved=backup(self.core)
 self.core.persistenceBusy=true;self.depth=1;self.ownerThread=coroutine.running()
 local result=table.pack(pcall(callback));self.depth=0;self.ownerThread=nil
 if not result[1]then rollback(self.core,saved);return self:_fatal(result[2])end
 self:_redeem(ids)
 local after;after,why=self:_capture(ids,now,wall)
 if not after then rollback(self.core,saved);return self:_fatal(why)end
 local changed={};for _,id in ipairs(ids)do if not equal(before[id],after[id])then changed[#changed+1]=id end end
 if #changed>0 then
  local cost=#changed>1 and 3 or 1
  local automatic=name=='finish'or name=='characterReset'or name=='pickup'or name=='expireOffer'or name=='withdraw'or urgent
  if not automatic and not self:_budget(changed,cost)then
   rollback(self.core,saved);self.core.persistenceBusy=false
   return false,'Progress is saving. Please wait a moment before changing your vault.'
  end
  local ok,reason
  if #changed==1 then ok,reason=self.store:save(changed[1],after[changed[1]])else ok,reason=self.store:atomic(changed,after)end
  if not ok then rollback(self.core,saved);return self:_fatal(reason)end
  -- A committed journal remains authoritative even if final cleanup needs retry.
  for _,id in ipairs(changed)do
   if not self.store:isReady(id)then
    local recovered=self.store:recover(id)
    if not recovered then return self:_fatal('Committed transfer cleanup needs recovery')end
   end
  end
 end
 self.core.persistenceBusy=false
 return table.unpack(result,2,result.n)
end
function S:_waitForTurn()
 local limit=self.clock()+12
 while self.core.persistenceBusy and not self.failed and self.clock()<limit do self.wait(.05)end
 return not self.failed and not self.core.persistenceBusy
end
function S:load(id)
 if self.loaded[id]or self.loading[id]then return false,'Profile is already loading.'end
 self.loading[id]=true
 -- Defaults are built away from the active world. Only a successful missing-key
 -- UpdateAsync may install them; a failed load never creates a writable fallback.
 local class=getmetatable(self.core);local fresh=class.new(self.core.catalog,self.core.config)
 fresh:addPlayer(id,self.clock())
 local p=fresh.players[id];local old=p.slots[1];local uid=self.guid()..':starter'
 if old then local item=fresh.items[old];fresh.items[old]=nil;item.uid=uid;fresh.items[uid]=item;p.slots[1]=uid;p.equipped=uid end
 local defaults,why=Codec.capture(fresh,id,self.clock(),self.wall())
 if not defaults then self.loading[id]=nil;return false,why end
 local ok,data=self.store:load(id,defaults)
 if not ok then self.loading[id]=nil;return false,data end
 if not self:_waitForTurn()then self.loading[id]=nil;self.store:release(id);return false,'Server progress is unavailable.'end
 self.core.persistenceBusy=true;self.depth=1;self.ownerThread=coroutine.running();self.core:addPlayer(id,self.clock());self.depth=0;self.ownerThread=nil
 ok,why=Codec.restore(self.core,id,data,self.clock(),self.wall())
 if not ok then
  self.loading[id]=nil;self.core.players[id]=nil;self.core.persistenceBusy=false;self.store:release(id)
  return false,why
 end
 self.loaded[id]=true;self.loading[id]=nil
 local recovery=self.core.players[id].carryReturnRecovery
 if recovery then
  self.recoverySeq=(self.recoverySeq or 0)+1
  local index='recovered'..self.recoverySeq
  local x=math.clamp(recovery.pickupX,self.core.config.ConveyorEndX+.1,self.core.config.ConveyorStartX)
  local offer=self.core:setOffer(index,recovery.kind,self.clock(),x)
  self.core.items[offer.uid]=nil;offer.uid=recovery.uid
  self.core.items[recovery.uid]={uid=recovery.uid,kind=recovery.kind,state='Conveyor',offer=index}
  self.core.players[id].carryReturnRecovery=nil
 end
 local normalized;normalized,why=Codec.capture(self.core,id,self.clock(),self.wall())
 if not normalized then return self:_fatal(why)end
 ok,why=self.store:save(id,normalized)
 if not ok then return self:_fatal(why)end
 self.core.persistenceBusy=false
 return true
end
function S:flushAll()
 if not self:_waitForTurn()then return false,'Progress unavailable.'end
 self.core.persistenceBusy=true
 for id in pairs(self.loaded)do
  local pending=clone(self.pendingSettings[id]);if pending then self:_applySettings(id,pending)end
  local data,why=Codec.capture(self.core,id,self.clock(),self.wall())
  if not data then return self:_fatal(why)end
  local ok;ok,why=self.store:save(id,data);if not ok then return self:_fatal(why)end
  if pending then self:_clearSettings(id,pending)end
 end
 self.core.persistenceBusy=false;return true
end
function S.validateSettings(patch)
 if type(patch)~='table'then return false,'Invalid settings.'end
 local allowed={musicMuted='boolean',sfxMuted='boolean',reducedEffects='boolean',musicVolume='number',sfxVolume='number',tutorialCompleted='boolean'}
 local count=0
 for k,v in pairs(patch)do
  count+=1;if count>6 or not allowed[k]or type(v)~=allowed[k]then return false,'Invalid settings.'end
  if type(v)=='number'and(v~=v or v<0 or v>1)then return false,'Invalid volume.'end
 end
 return true
end
function S:_applySettings(id,patch)
 local p=self.core.players[id]
 for k,v in pairs(patch)do if k=='tutorialCompleted'then p.tutorialCompleted=v else p.settings[k]=v end end
end
function S:_clearSettings(id,patch)
 local pending=self.pendingSettings[id]
 if not pending then return end
 for k,v in pairs(patch)do if pending[k]==v then pending[k]=nil end end
 if not next(pending)then self.pendingSettings[id]=nil end
end
function S:settings(id,patch)
 local valid,why=S.validateSettings(patch);if not valid then return false,why end
 return self:_change('settings',{id},function()
  self:_applySettings(id,patch)
  return true,'Settings saved.'
 end)
end
function S:queueSettings(id,patch)
 local valid,why=S.validateSettings(patch);if not valid then return false,why end
 if not self:isReady(id)then return false,'Saved profile is not ready.'end
 local pending=self.pendingSettings[id]or{};self.pendingSettings[id]=pending
 for k,v in pairs(patch)do pending[k]=v end
 return true
end
function S:flushSettings(onlyId)
 if self.core.persistenceBusy or self.failed then return false end
 local flushed=false
 for id,queued in pairs(self.pendingSettings)do if(not onlyId or onlyId==id)and self.loaded[id]then
  local patch=clone(queued)
  if self:settings(id,patch)then self:_clearSettings(id,patch);flushed=true end
 end end
 return flushed
end
function S:adminCommand(callback)
 return self:_change('admin',{},callback)
end
function S:runFor(id,callback)
 return self:_change('direct',{id},callback)
end
local function addCash(p,amount)
 local available=math.max(0,MAX_CASH-p.cash-p.held);local direct=math.min(amount,available)
 p.cash+=direct;p.paidCashCredit=(p.paidCashCredit or 0)+(amount-direct)
end
function S:grantReceipt(player,receipt,offer,cashPerRobux)
 local id=player.UserId
 if self.core.persistenceBusy or not self:isReady(id)then return false,'Profile is not ready.'end
 local old=self.core.players[id].receipts[receipt.PurchaseId]
 if old then return old.productId==receipt.ProductId,'Receipt already saved.'end
 return self:_change('receipt',{id},function()
  local p=self.core.players[id];local count=0;for _ in pairs(p.receipts)do count+=1 end
  if count>=Codec.MaxReceipts then return false,'Receipt ledger capacity reached.'end
  local result='Granted'
  if offer.cash then addCash(p,offer.cash)
  elseif offer.levels then
   local gain=math.min(offer.levels,1000-p.progression)
   if gain>0 then self.core:gainLevel(id,gain)end
   if gain<offer.levels then addCash(p,math.floor(offer.robux*cashPerRobux*(offer.levels-gain)/offer.levels));result='CashFallback'end
  elseif offer.power then
   if p.powerOwned[offer.power]then
    addCash(p,require(script.Parent.PowerCatalog).ById[offer.power].price);result='CashFallback'
   else p.powerOwned[offer.power]=true end
  else return false,'Unsupported receipt reward.'end
  p.receipts[receipt.PurchaseId]={productId=receipt.ProductId,grantedAt=self.wall(),offerId=offer.id,result=result}
  return true,result=='CashFallback'and'Purchase delivered as game cash because the original reward was already owned or capped.'or'Purchase saved.'
 end,true)
end
function S:leave(id)
 if not self.loaded[id]then return false,'Profile is not loaded.'end
 if self.failed then
  if not self.store:isReady(id)then self.store:recover(id)end
  self.store:release(id);self.loaded[id]=nil;return false,'Server stopped after a storage failure.'
 end
 -- PlayerRemoving must not orphan a loaded profile while another write is
 -- yielding. Keep this callback alive until that write completes or the
 -- server enters its fail-closed release path.
 while not self:_waitForTurn()do
  if self.failed then return self:leave(id)end
 end
 -- BindToClose and PlayerRemoving may both wait for the same departure.
 if not self.loaded[id]then return true end
 -- Resolve carries/bids durably before removing owned world models.
 self.core:characterReset(id,self.clock())
 for other,p in pairs(self.core.players)do
  local it=p.carry and self.core.items[p.carry]
  if it and it.owner==id then self.core:finish(other,false,self.clock())end
 end
 if self.failed then return self:leave(id)end
 self.core.persistenceBusy=true
 local pending=self.pendingSettings[id];if pending then self:_applySettings(id,pending)end
 local data,why=Codec.capture(self.core,id,self.clock(),self.wall())
 if not data then return self:_fatal(why)end
 local ok;ok,why=self.store:release(id,data)
 if not ok then return self:_fatal(why)end
 self.loaded[id]=nil;self.rate[id]=nil;self.pendingSettings[id]=nil
 self.depth=1;self.ownerThread=coroutine.running();self.core:removePlayer(id);self.depth=0;self.ownerThread=nil;self.core.persistenceBusy=false
 return true
end
return S
