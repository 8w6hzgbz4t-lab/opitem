return function(package,require,setGlobals)
 local checks=0;local groups={}
 local function check(value,message)checks+=1;assert(value,message)end
 local C=require(package.CashShopConfig);local Service=require(package.CashShopService)
 local Powers=require(package.PowerCatalog)
 local function copy()
  local c=table.clone(C);c.Offers={}
  for i,offer in ipairs(C.Offers)do c.Offers[i]=table.clone(offer)end
  return c
 end
 check(Service.validate(C),'Prepared three-category configuration valid')
 check(C.Enabled==false and C.PreviewOnly==true,'Live purchases disabled')
 local counts={cash=0,levels=0,powers=0};local seen={}
 local expectedPowers={dash=2,gravity=6,slow=8,slam=25,repulse=70,shield=90,lightning=325}
 for _,offer in ipairs(C.Offers)do
  counts[offer.category]+=1;seen[offer.id]=true
  check(offer.productId==0,'No real product IDs installed')
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
 check(counts.cash==4 and counts.levels==2 and counts.powers==7,'All thirteen prepared offers available')
 for _,mutate in ipairs({
  function(c)c.Enabled=true end,function(c)c.PreviewOnly=false end,
  function(c)c.CashPerRobux=0 end,function(c)c.Offers[1].cash+=1 end,
  function(c)c.Offers[1].productId=12345 end,function(c)c.Offers[2].id=c.Offers[1].id end,
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
 groups[#groups+1]='Cash, base levels and seven regular powers only; proposed prices; unsupported effects denied'
 local vector={};vector.__index=function(t,k)if k=='Magnitude'then return math.abs(t.n)end end
 vector.__sub=function(a,b)return setmetatable({n=a.n-b.n},vector)end
 local function pos(n)return setmetatable({n=n},vector)end
 local now=10;local player={UserId=1,Parent=true};local outsider={UserId=2,Parent=true}
 local root={Position=pos(0)};local humanoid={Health=100};local anchor={Parent=true,Position=pos(0)}
 local state={cash=123,held=15,loadout={'tag','dash'},powers={tag=true,dash=true},progression=0}
 local core={players={[1]=state}};local calls={}
 local shop=Service.new(C,{core=core,body=function()return root,humanoid end,anchor=anchor,clock=function()return now end,remote={FireClient=function(_,p,d)calls[#calls+1]={p=p,d=d}end}})
 local before=table.clone(state)
 check(shop:open(player),'Near live player opens storefront')
 check(#calls==1 and calls[1].p==player and calls[1].d.available==false and calls[1].d.configured==false,'Only that player receives disabled preview')
 check(#calls[1].d.offers==13,'Thirteen prepared offers sent')
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
  check(state.powers==before.powers and state.loadout==before.loadout,'Preview never grants regular or developer powers')
 end
 check(not shop:request(nil,nil),'Malformed request disabled')
 local a=shop:catalog();a.offers[1].cash=9;a.offers[1].name='Tampered';table.remove(a.offers)
 local b=shop:catalog();check(#b.offers==13 and b.offers[1].cash==5000 and b.offers[1].name=='Pocket Cash','Catalog does not expose mutable internal tables')
 for _,offer in ipairs(b.offers)do
  check(offer.productId==nil,'Client preview has no product ID to purchase')
  check(offer.category=='cash'or offer.category=='levels'or offer.category=='powers','Only intended public categories')
 end
 shop:removePlayer(player);check(shop.nextOpen[1]==nil,'Disconnect clears throttle state')
 groups[#groups+1]='Every purchase request disabled; no collectibles/developer perks or state writes'
 return {assertions=checks,groups=groups}
end
