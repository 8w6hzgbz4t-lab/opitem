-- Only ProcessReceipt can request a durable reward. Prompts never grant anything.
local Powers=require(script.Parent.PowerCatalog)
local S={};S.__index=S
local owners=setmetatable({},{__mode='k'})
local cashIds={pocket=true,stack=true,chest=true,fortune=true}
local levelIds={level_one=1,level_five=5}
local normal={dash=true,gravity=true,slow=true,slam=true,repulse=true,shield=true,lightning=true,kiblast=true,spinjitzu=true}
local configKeys={Enabled=true,PreviewOnly=true,CashPerRobux=true,Offers=true,ProductInfoTTL=true,PromptCooldown=true,OpenCooldown=true}
local common={id=true,name=true,category=true,robux=true,productId=true}
local glyphs={dash='>>',gravity='PULL',slow='SLOW',slam='SLAM',repulse='PULSE',shield='SHIELD',lightning='BOLT',kiblast='KI',spinjitzu='WIND'}
local function integer(n)return type(n)=='number'and n==n and n>0 and n<=9007199254740991 and n%1==0 end
local function copy(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=copy(x)end;return t end
function S.validate(c)
 if type(c)~='table'or type(c.Enabled)~='boolean'or type(c.PreviewOnly)~='boolean'or c.Enabled==c.PreviewOnly then return false,'Choose either live checkout or preview mode.'end
 for k in pairs(c)do if not configKeys[k]then return false,'Unsupported shop configuration field.'end end
 if not integer(c.CashPerRobux)or type(c.Offers)~='table'or #c.Offers~=15 then return false,'Expected four cash, two level and nine ordinary-power offers.'end
 for k in pairs(c.Offers)do if type(k)~='number'or k%1~=0 or k<1 or k>15 then return false,'Offer list must be a dense array.'end end
 for k,b in pairs({ProductInfoTTL={10,600},PromptCooldown={1,30},OpenCooldown={.25,5}})do
  local n=c[k];if n~=nil and(type(n)~='number'or n~=n or n<b[1]or n>b[2])then return false,'Invalid shop throttle.'end
 end
 local ids,products={},{};local counts={cash=0,levels=0,powers=0}
 for _,o in ipairs(c.Offers)do
  if type(o)~='table'or type(o.id)~='string'or #o.id<1 or #o.id>32 or ids[o.id]or type(o.name)~='string'or #o.name<1 or #o.name>40
   or not integer(o.robux)or not counts[o.category]or not(o.productId==0 or integer(o.productId))then return false,'Invalid or duplicated offer.'end
  if c.Enabled and o.productId==0 then return false,'Every live offer needs a real Developer Product ID.'end
  if o.productId~=0 then if products[o.productId]then return false,'Product IDs must be unique.'end;products[o.productId]=true end
  local effect=o.category=='powers'and'power'or o.category
  for k in pairs(o)do if not common[k]and k~=effect then return false,'Unsupported reward or developer privilege.'end end
  if o.category=='cash'then
   if not cashIds[o.id]or not integer(o.cash)or o.cash~=o.robux*c.CashPerRobux then return false,'Cash prices must stay proportional.'end
  elseif o.category=='levels'then
   if levelIds[o.id]~=o.levels or not integer(o.levels)then return false,'Invalid base-level offer.'end
  else
   local p=normal[o.power]and Powers.ById[o.power]
   if not p or o.id~='unlock_'..o.power or o.robux~=math.ceil(p.price/c.CashPerRobux)then return false,'Only ordinary power unlocks belong here.'end
  end
  counts[o.category]+=1;ids[o.id]=true
 end
 return counts.cash==4 and counts.levels==2 and counts.powers==9,'Missing supported offers.'
end
function S.new(config,ctx)
 local valid,why=S.validate(config);assert(valid,why)
 assert(type(ctx)=='table'and ctx.core,'Shop requires server context.')
 if config.Enabled then
  assert(ctx.persistence and type(ctx.persistence.isReady)=='function'and type(ctx.purchaseGrant)=='function','Live checkout requires durable receipt fulfillment.')
  assert(ctx.marketplace and type(ctx.marketplace.PromptProductPurchase)=='function'and type(ctx.marketplace.GetProductInfo)=='function','Live checkout requires MarketplaceService.')
 end
 local self=setmetatable({config=copy(config),ctx=ctx,offers={},byId={},byProduct={},info={},nextOpen={},nextRequest={},prompting={},receiptBusy={},clock=ctx.clock or os.clock},S)
 for _,o in ipairs(config.Offers)do local row=copy(o);self.offers[#self.offers+1]=row;self.byId[row.id]=row;if row.productId>0 then self.byProduct[row.productId]=row end end
 return self
end
function S:ready(p)
 if not p or not p.Parent or not self.ctx.core.players[p.UserId]then return false,'Player unavailable.'end
 if self.ctx.core.persistenceBusy then return false,'Saving progress. Please wait.'end
 local store=self.ctx.persistence
 if not store or type(store.isReady)~='function'or type(self.ctx.purchaseGrant)~='function'then return false,'Saved purchase delivery is not configured.'end
 local ok,ready=pcall(store.isReady,store,p.UserId)
 return ok and ready==true,'Your saved profile is not ready.'
end
function S:atBench(p)
 if not p or not p.Parent or not self.ctx.core.players[p.UserId]then return false,'Player unavailable.'end
 local root,h=self.ctx.body(p);local a=self.ctx.anchor
 if not root or not h or h.Health<=0 or not a or not a.Parent or(root.Position-a.Position).Magnitude>12 then return false,'Visit the Robux shop bench.'end
 return true
end
function S:productInfo(o)
 if o.productId==0 or not self.ctx.marketplace then return nil,'Developer Product is not configured.'end
 local now=self.clock();local old=self.info[o.productId];if old and now<old.untilAt then return old.value,old.reason end
 local ok,d=pcall(function()return self.ctx.marketplace:GetProductInfo(o.productId,self.ctx.infoType or Enum.InfoType.Product)end)
 local value,reason
 if ok and type(d)=='table'and integer(d.PriceInRobux)and d.IsForSale~=false and(d.ProductId==nil or d.ProductId==o.productId)then
  value={price=d.PriceInRobux,imageId=integer(d.IconImageAssetId)and d.IconImageAssetId or nil}
  if value.price~=o.robux then reason='The Roblox price changed. This offer is temporarily unavailable.'end
 else reason='Roblox could not confirm this product. Please try again.'end
 self.info[o.productId]={value=value,reason=reason,untilAt=now+(value and(self.config.ProductInfoTTL or 120)or 5)}
 return value,reason
end
function S:eligibility(p,o)
 if not self.config.Enabled or self.config.PreviewOnly then return false,'Coming soon. Purchases are not available yet.'end
 local ready,why=self:ready(p);if not ready then return false,why end
 if self.ctx.persistence.canPurchase then
  local safe,reason=self.ctx.persistence:canPurchase(p.UserId);if not safe then return false,reason end
 end
 local state=self.ctx.core.players[p.UserId]
 if state.carry or state.pending then return false,'Deliver your item or leave the bid battle first.'end
 if o.power and Powers.ById[o.power].starter and not state.starterChosen then return false,'Choose your free starter in Powers before buying this unlock.'end
 if o.power and state.powerOwned and state.powerOwned[o.power]then return false,'Already owned.'end
 if o.levels and(state.progression or 0)+o.levels>1000 then return false,'This pack exceeds the maximum base level.'end
 if o.cash and((state.cash or 0)+(state.held or 0)+o.cash>2000000000 or(state.paidCashCredit or 0)>0)then return false,'Spend or collect your existing cash credit before buying more.'end
 local info,reason=self:productInfo(o);if not info or reason then return false,reason end
 return true,nil,info
end
function S:catalog(p)
 local out={};local any=false;local state=p and self.ctx.core.players[p.UserId]
 for _,o in ipairs(self.offers)do
  local info=self:productInfo(o);local available,reason=self:eligibility(p,o);local power=o.power and Powers.ById[o.power]
  out[#out+1]={id=o.id,name=o.name,category=o.category,robux=info and info.price or o.robux,proposedRobux=o.robux,
   cash=o.cash,levels=o.levels,power=o.power,rank=power and power.rank,cooldown=power and power.cooldown,
   description=power and power.description or(o.cash and'Add game cash to your saved balance.'or'Raise your base level, income and protection.'),
   icon=o.cash and'$'or(o.levels and'LV'or glyphs[o.power]),imageId=info and info.imageId,
   available=available,owned=o.power~=nil and state~=nil and state.powerOwned~=nil and state.powerOwned[o.power]==true or false,
   reason=reason,preview=o.power,priceSource=info and'roblox'or'proposed',priceVerified=info~=nil}
  any=any or available
 end
 return{kind='catalog',available=any,configured=self.config.Enabled and not self.config.PreviewOnly,title='Robux Shop',
  message=self.config.Enabled and'Roblox confirms the final price before you buy.'or'Coming soon. Purchases are not available yet.',offers=out}
end
function S:notify(p,data)if p and p.Parent and self.ctx.remote then pcall(function()self.ctx.remote:FireClient(p,data)end)end end
function S:open(p)
 local near,why=self:atBench(p);if not near then return false,why end
 local now=self.clock();if now<(self.nextOpen[p.UserId]or 0)then return false,'Please wait.'end
 self.nextOpen[p.UserId]=now+(self.config.OpenCooldown or .5);self:notify(p,self:catalog(p));return true
end
function S:request(p,payload)
 if not p or not p.Parent or not self.ctx.core.players[p.UserId]then return false,'Player unavailable.'end
 local function deny(why)self:notify(p,{kind='result',ok=false,message=why});return false,why end
 local now=self.clock();if now<(self.nextRequest[p.UserId]or 0)then return deny('Please wait.')end
 self.nextRequest[p.UserId]=now+(self.config.PromptCooldown or 3)
 if type(payload)~='table'or payload.kind~='buy'or type(payload.id)~='string'or #payload.id>32 then return deny('Invalid shop request.')end
 for k in pairs(payload)do if k~='kind'and k~='id'then return deny('Only an offer ID can be requested.')end end
 local o=self.byId[payload.id];if not o then return deny('Offer unavailable.')end
 local near,why=self:atBench(p);if not near then return deny(why)end
 local pending=self.prompting[p.UserId];if pending and now-pending.started<90 then return deny('Finish your current Roblox checkout first.')end
 local allowed,reason=self:eligibility(p,o);if not allowed then return deny(reason)end
 if not self.attached then return deny('Purchase delivery is not connected.')end
 self.prompting[p.UserId]={offerId=o.id,productId=o.productId,started=now}
 local ok=pcall(function()self.ctx.marketplace:PromptProductPurchase(p,o.productId)end)
 if not ok then self.prompting[p.UserId]=nil;return deny('Roblox checkout could not open. No reward was granted.')end
 self:notify(p,{kind='result',ok=true,id=o.id,message='Complete or cancel the Roblox purchase window.'});return true
end
function S:processReceipt(r)
 local decisions=self.ctx.purchaseDecision or Enum.ProductPurchaseDecision
 local pending,granted=decisions.NotProcessedYet,decisions.PurchaseGranted
 if type(r)~='table'or not integer(r.PlayerId)or not integer(r.ProductId)or type(r.PurchaseId)~='string'or #r.PurchaseId<1 or #r.PurchaseId>128 or not string.match(r.PurchaseId,'^[%w_%-:]+$')then return pending end
 local o=self.byProduct[r.ProductId];if not o or self.receiptBusy[r.PurchaseId]then return pending end
 local p
 if self.ctx.getPlayerByUserId then p=self.ctx.getPlayerByUserId(r.PlayerId)elseif self.ctx.players then p=self.ctx.players:GetPlayerByUserId(r.PlayerId)end
 if not p or p.UserId~=r.PlayerId or not self:ready(p)then return pending end
 self.receiptBusy[r.PurchaseId]=true
 local ok,done,reason=pcall(self.ctx.purchaseGrant,p,r,copy(o));self.receiptBusy[r.PurchaseId]=nil
 if not ok or done~=true then return pending end
 self.prompting[p.UserId]=nil
 self:notify(p,{kind='result',ok=true,id=o.id,message=type(reason)=='string'and reason or'Purchase saved and delivered.'})
 local built,catalog=pcall(self.catalog,self,p);if built then self:notify(p,catalog)end
 return granted
end
function S:attach()
 if self.attached then return true end
 local m=self.ctx.marketplace;if not m then return false,'MarketplaceService is unavailable.'end
 if owners[m]and owners[m]~=self then return false,'A receipt handler is already attached.'end
 self.receiptHandler=function(r)return self:processReceipt(r)end
 local ok=pcall(function()m.ProcessReceipt=self.receiptHandler end)
 if not ok then self.receiptHandler=nil;return false,'Receipt handler could not be installed.'end
 owners[m]=self;self.attached=true
 if m.PromptProductPurchaseFinished then self.finished=m.PromptProductPurchaseFinished:Connect(function(userId,productId,purchased)
  local current=self.prompting[userId];if not current or current.productId~=productId then return end;self.prompting[userId]=nil
  local p=self.ctx.getPlayerByUserId and self.ctx.getPlayerByUserId(userId)or(self.ctx.players and self.ctx.players:GetPlayerByUserId(userId))
  self:notify(p,{kind='result',ok=purchased==true,id=current.offerId,message=purchased and'Purchase processing. Delivery follows the confirmed Roblox receipt.'or'Purchase cancelled. No reward was granted.'})
 end)end
 return true
end
function S:removePlayer(p)self.nextOpen[p.UserId]=nil;self.nextRequest[p.UserId]=nil;self.prompting[p.UserId]=nil end
return S
