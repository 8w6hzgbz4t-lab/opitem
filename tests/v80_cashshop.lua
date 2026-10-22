return function(package,require,setGlobals)
 local checks=0;local groups={}
 setGlobals({Enum={InfoType={Product='Product'},ProductPurchaseDecision={NotProcessedYet='Pending',PurchaseGranted='Granted'}}})
 local function check(value,message)checks+=1;assert(value,message)end
 local C=require(package.CashShopConfig);local Service=require(package.CashShopService)
 local Powers=require(package.PowerCatalog)
 local expectedIds={pocket=3720840251,stack=3720846297,chest=3720846778,fortune=3720847183,
  level_one=3720847536,level_five=3720847942,unlock_dash=3720848352,unlock_gravity=3720848733,
  unlock_slow=3720849165,unlock_slam=3720849458,unlock_repulse=3720851934,unlock_shield=3720852231,
  unlock_lightning=3720852595,unlock_kiblast=3720852857,unlock_spinjitzu=3720853158}
 local pocketId=expectedIds.pocket

 local function copy()
  local c=table.clone(C);c.Offers={}
  for i,offer in ipairs(C.Offers)do c.Offers[i]=table.clone(offer)end
  return c
 end
 check(Service.validate(C),'Prepared three-category configuration valid')
 check(C.Enabled==false and C.PreviewOnly==true,'Live purchases disabled')
 local counts={cash=0,levels=0,powers=0};local seen={}
 local expectedPowers={dash=2,gravity=6,slow=8,slam=25,repulse=70,shield=90,lightning=325,kiblast=325,spinjitzu=80}
 for _,offer in ipairs(C.Offers)do
  counts[offer.category]+=1;seen[offer.id]=true
  check(offer.productId==expectedIds[offer.id],'Owner-supplied product ID bound to the wrong reward')
  if offer.category=='cash'then check(offer.cash==offer.robux*200,'Cash uses 200 per Robux')
  elseif offer.category=='levels'then
   check((offer.levels==1 and offer.robux==25)or(offer.levels==5 and offer.robux==100),'Base level prices match proposed packs')
  else
   check(expectedPowers[offer.power]==offer.robux,'Every normal power has expected price')
   check(offer.robux==math.ceil(Powers.ById[offer.power].price/C.CashPerRobux),'Power price scales with in-game cash price')
   check(offer.power~='tag'and offer.power~='royalseal','Tag remains free and developer power is excluded')
  end
  check(offer.item==nil and offer.itemId==nil and offer.developer==nil and offer.flight==nil,'No collectibles or developer effects')
 end
 check(counts.cash==4 and counts.levels==2 and counts.powers==9,'All fifteen prepared offers available')
 for _,mutate in ipairs({
  function(c)c.Enabled=true end,function(c)c.PreviewOnly=false end,
  function(c)c.CashPerRobux=0 end,function(c)c.Offers[1].cash+=1 end,
  function(c)c.Offers[2].id=c.Offers[1].id end,
  function(c)c.Offers[1].robux=0/0 end,function(c)c.Offers[1].cash=math.huge end,
  function(c)c.Offers[1].robux=2.5 end,function(c)c.Offers[1].name='' end,
  function(c)c.Offers[1].category='items' end,function(c)c.Offers[1].item='item08' end,
  function(c)c.Offers[1].developer=true end,function(c)c.Offers[1].flight=true end,
  function(c)c.Offers[1].levels=5 end,function(c)c.Offers[5].cash=10000 end,
  function(c)c.Offers[5].levels=1000 end,function(c)c.Offers[5].id='giftlevels' end,
  function(c)c.Offers[7].power='royalseal';c.Offers[7].id='unlock_royalseal' end,
  function(c)c.Offers[7].power='tag';c.Offers[7].id='unlock_tag' end,
  function(c)c.Offers[7].power='item08';c.Offers[7].id='unlock_item08' end,
  function(c)c.Offers[7].robux+=1 end,function(c)c.Offers[7].category='developer' end,
  function(c)c.Offers[7].power=nil end,function(c)c.Offers[7].id='flight' end,
  function(c)c.Offers[7]=table.clone(c.Offers[8])end,
  function(c)c.Offers.admin={power='royalseal'}end,
  function(c)c.DeveloperProducts={royalseal=12345}end,
 })do local c=copy();mutate(c);check(not Service.validate(c),'Unsupported or unsafe offer rejected')end
 groups[#groups+1]='Cash, base levels and nine regular powers only; proposed prices; unsupported effects denied'
 local vector={};vector.__index=function(t,k)if k=='Magnitude'then return math.abs(t.n)end end
 vector.__sub=function(a,b)return setmetatable({n=a.n-b.n},vector)end
 local function pos(n)return setmetatable({n=n},vector)end
 local now=10;local player={UserId=1,Parent=true};local outsider={UserId=2,Parent=true}
 local root={Position=pos(0)};local humanoid={Health=100};local anchor={Parent=true,Position=pos(0)}
 local state={cash=123,held=15,loadout={'tag','dash'},powerOwned={tag=true,dash=true},progression=0}
 local core={players={[1]=state}};local calls={}
 local shop=Service.new(C,{core=core,body=function()return root,humanoid end,anchor=anchor,clock=function()return now end,remote={FireClient=function(_,p,d)calls[#calls+1]={p=p,d=d}end}})
 local before=table.clone(state)
 check(shop:open(player),'Near live player opens storefront')
 check(#calls==1 and calls[1].p==player and calls[1].d.available==false and calls[1].d.configured==false,'Only that player receives disabled preview')
 check(#calls[1].d.offers==15,'Fifteen prepared offers sent')
 check(not shop:open(player),'Repeated open throttled')
 now+=1;root.Position=pos(13);check(not shop:open(player),'Remote opening denied outside bench reach')
 root.Position=pos(0);humanoid.Health=0;check(not shop:open(player),'Dead player cannot open')
 humanoid.Health=100;check(not shop:open(outsider),'Unknown player rejected')
 player.Parent=false;check(not shop:open(player),'Disconnected player rejected');player.Parent=true
 anchor.Parent=false;check(not shop:open(player),'Removed bench rejected');anchor.Parent=true
 check(not shop:open(nil),'Nil player rejected')
 groups[#groups+1]='Server-proximity checks, player state, throttling and targeted opening'
 for _,payload in ipairs({{}, {id='pocket'},{id='level_one'},{id='level_five'},{id='unlock_lightning'},
  {productId=12345},{id='fortune',cash=999999999,robux=0},{id='unlock_royalseal'},
  {command='royalseal'},{developer=true},{kind='flight'},{kind='god'},{item='item08'},
  {kind='giftlevels',amount=1000},{category='powers',power='lightning'},
 })do
  check(not shop:request(player,payload),'Forged or legitimate purchase disabled')
  check(state.cash==before.cash and state.held==before.held and state.progression==before.progression,'Preview never changes cash, escrow or levels')
  check(state.powerOwned==before.powerOwned and state.loadout==before.loadout,'Preview never grants regular or developer powers')
 end
 check(not shop:request(nil,nil),'Malformed request disabled')
 local a=shop:catalog();a.offers[1].cash=9;a.offers[1].name='Tampered';table.remove(a.offers)
 local b=shop:catalog();check(#b.offers==15 and b.offers[1].cash==5000 and b.offers[1].name=='Pocket Cash','Catalog does not expose mutable internal tables')
 for _,offer in ipairs(b.offers)do
  check(offer.productId==nil,'Client preview has no product ID to purchase')
  check(offer.category=='cash'or offer.category=='levels'or offer.category=='powers','Only intended public categories')
 end
 shop:removePlayer(player);check(shop.nextOpen[1]==nil,'Disconnect clears throttle state')
 groups[#groups+1]='Every purchase request disabled; no collectibles/developer perks or state writes'
 local liveConfig=copy();liveConfig.Enabled=true;liveConfig.PreviewOnly=false
 -- Controlled test only: use the configured IDs with fake Marketplace/storage APIs.
 check(Service.validate(liveConfig),'Real unique product IDs allow configured checkout')
 local duplicate=copy();duplicate.Offers[1].productId=1;duplicate.Offers[2].productId=1
 check(not Service.validate(duplicate),'Duplicated product IDs rejected')
 local finished={callbacks={}};function finished:Connect(fn)self.callbacks[#self.callbacks+1]=fn;return{Disconnect=function()end}end
 local prompted,grants,ledger,apiCalls={},{},{},0
 local priceChanged=false;local apiDown=false;local writable=true;local grantAllowed=true
 local marketplace={PromptProductPurchaseFinished=finished}
 function marketplace:GetProductInfo(id,infoType)
  apiCalls+=1;check(infoType=='Product','Correct Developer Product info type')
  if apiDown then error('API unavailable')end
  for _,o in ipairs(liveConfig.Offers)do if o.productId==id then
   return{ProductId=id,PriceInRobux=o.robux+(priceChanged and 1 or 0),IsForSale=true,IconImageAssetId=555}
  end end
 end
 function marketplace:PromptProductPurchase(p,id)prompted[#prompted+1]={p=p,id=id}end
 local durable={isReady=function()return writable end,canPurchase=function()return writable,'Receipt capacity unavailable.'end}
 local ctx={core=core,body=function()return root,humanoid end,anchor=anchor,clock=function()return now end,
  marketplace=marketplace,persistence=durable,getPlayerByUserId=function(id)return id==1 and player or nil end,
  remote={FireClient=function(_,p,d)calls[#calls+1]={p=p,d=d}end},
  purchaseGrant=function(p,r,o)
   check(p==player and o.productId==r.ProductId,'Only mapped server reward reaches durable grant')
   if not grantAllowed then return false,'Saving unavailable'end
   if not ledger[r.PurchaseId]then grants[#grants+1]={r=r,o=o};ledger[r.PurchaseId]=true end
   return true,'Saved'
  end}
 local live=Service.new(liveConfig,ctx)
 check(live:attach()and marketplace.ProcessReceipt==live.receiptHandler,'One server receipt handler attaches')
 local second=Service.new(liveConfig,ctx);check(not second:attach(),'Second service cannot replace receipt handler')
 state.powerOwned={tag=true};state.progression=0;state.cash=123;state.pending=nil;state.carry=nil;state.starterChosen=true
 now+=10
 local catalog=live:catalog(player)
 check(catalog.kind=='catalog'and catalog.available and catalog.configured and #catalog.offers==15,'Configured catalog exposes fifteen public offers')
 local cached=apiCalls;live:catalog(player);check(apiCalls==cached,'Verified product prices use bounded cache')
 for _,o in ipairs(catalog.offers)do
  check(o.priceSource=='roblox'and o.priceVerified and o.available,'Live offers show server-verified Roblox prices')
  if o.power then check(o.icon and o.description and o.rank and o.cooldown and o.preview==o.power,'Power preview shows effects, rank and cooldown')end
 end
 check(live:request(player,{kind='buy',id='pocket'}),'Valid request opens Roblox prompt')
 check(#prompted==1 and prompted[1].id==pocketId and #grants==0,'Opening prompt never grants cash')
 finished.callbacks[1](1,pocketId,false)
 check(#grants==0 and not live.prompting[1],'Cancelled prompt grants nothing')
 now+=4
 check(not live:request(player,{kind='buy',id='pocket',cash=999999}),'Client cannot add reward fields')
 now+=4;state.starterChosen=false
 check(not live:request(player,{kind='buy',id='unlock_dash'}),'A free starter cannot be sold before the starter choice')
 state.starterChosen=true
 now+=4;state.powerOwned.kiblast=true
 check(not live:request(player,{kind='buy',id='unlock_kiblast'}),'Owned regular power cannot be prompted again')
 state.powerOwned.kiblast=nil;state.progression=999;now+=4
 check(not live:request(player,{kind='buy',id='level_five'}),'Capped level pack is blocked before payment')
 state.progression=0;state.cash=2000000000;now+=4
 check(not live:request(player,{kind='buy',id='pocket'}),'Cash-cap purchase blocked before payment')
 state.cash=123;writable=false;now+=4
 check(not live:request(player,{kind='buy',id='pocket'}),'Unready durable profile cannot spend Robux')
 writable=true;root.Position=pos(40);now+=4
 check(not live:request(player,{kind='buy',id='pocket'}),'Checkout still requires real bench proximity')
 root.Position=pos(0);priceChanged=true;now+=121
 check(not live:request(player,{kind='buy',id='pocket'}),'Changed Roblox price stops mismatched proportional offer')
 priceChanged=false;apiDown=true;now+=121
 check(not live:request(player,{kind='buy',id='pocket'}),'Product API failure cannot start an unverified prompt')
 apiDown=false;now+=121
 check(live:request(player,{kind='buy',id='pocket'}),'Checkout recovers after verified product API returns')
 local receipt={PlayerId=1,ProductId=pocketId,PurchaseId='purchase-real-1'}
 grantAllowed=false
 check(marketplace.ProcessReceipt(receipt)=='Pending'and #grants==0,'Failed durable fulfillment never acknowledges payment')
 grantAllowed=true
 check(marketplace.ProcessReceipt(receipt)=='Granted'and #grants==1,'Confirmed receipt acknowledges only durable delivery')
 check(marketplace.ProcessReceipt(receipt)=='Granted'and #grants==1,'Retried confirmed receipt stays idempotent')
 player.Parent=false
 check(live:processReceipt({PlayerId=1,ProductId=pocketId,PurchaseId='offline'})=='Pending','Offline player receipt waits')
 player.Parent=true
 for _,bad in ipairs({{}, {PlayerId=2,ProductId=pocketId,PurchaseId='outsider'},
  {PlayerId=1,ProductId=9999,PurchaseId='unknown'}, {PlayerId=1,ProductId=pocketId,PurchaseId='invalid id'},
  {PlayerId=1,ProductId=pocketId,PurchaseId=''}, {PlayerId=1,ProductId=pocketId,PurchaseId=string.rep('x',129)}})do
  check(live:processReceipt(bad)=='Pending','Malformed, unknown or unavailable receipt cannot grant')
 end
 local previewWithIds=copy()
 local disabled=Service.new(previewWithIds,ctx)
 check(disabled:processReceipt({PlayerId=1,ProductId=pocketId,PurchaseId='already-paid-before-disabled'})=='Granted','Disabling new checkout does not abandon a legitimate pending receipt')
 check(#grants==2 and state.cash==123,'Service itself never mutates currency; verified rewards use durable callback only')
 groups[#groups+1]='Configured checkout, current-price verification, cancellation, ownership/caps and receipt-only durable delivery/retries'
 local seenIds={}
 for _,o in ipairs(C.Offers)do
  check(not seenIds[o.productId],'Two rewards share a product ID');seenIds[o.productId]=true
  local count=#grants;local r={PlayerId=1,ProductId=o.productId,PurchaseId='owner-mapping-'..o.id}
  check(live:processReceipt(r)=='Granted'and #grants==count+1,'Configured product did not reach durable fulfillment')
  check(grants[#grants].o.id==o.id,'Configured receipt granted a different reward')
  check(live:processReceipt(r)=='Granted'and #grants==count+1,'Configured receipt retry double-granted')
 end
 local missing=copy();missing.Enabled=true;missing.PreviewOnly=false;missing.Offers[1].productId=0
 check(not Service.validate(missing),'Enabled checkout accepted a missing product ID')
 check(C.Enabled==false and C.PreviewOnly==true,'Testing enabled the production configuration')
 groups[#groups+1]='All fifteen owner-supplied IDs map uniquely to the intended reward and retry safely in the controlled receipt adapter'

 return {assertions=checks,groups=groups}
end
