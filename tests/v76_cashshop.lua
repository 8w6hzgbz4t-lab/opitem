return function(package,require,setGlobals)
 local checks=0;local groups={}
 local function check(value,message) checks+=1;assert(value,message) end
 local C=require(package.CashShopConfig);local Service=require(package.CashShopService)
 local function copy()local c=table.clone(C);c.Packs={};for i,p in ipairs(C.Packs)do c.Packs[i]=table.clone(p)end;return c end
 check(Service.validate(C),'Prepared configuration valid')
 check(C.Enabled==false and C.PreviewOnly==true,'Live purchases disabled')
 for _,pack in ipairs(C.Packs)do
  check(pack.cash==pack.robux*200,'All packs have equal cash/Robux rate')
  check(pack.productId==0,'No real product IDs installed')
 end
 for _,mutate in ipairs({
  function(c)c.Enabled=true end,function(c)c.PreviewOnly=false end,
  function(c)c.CashPerRobux=0 end,function(c)c.Packs[1].cash+=1 end,
  function(c)c.Packs[1].productId=12345 end,function(c)c.Packs[2].id=c.Packs[1].id end,
  function(c)c.Packs[1].robux=0/0 end,function(c)c.Packs[1].cash=math.huge end,
  function(c)c.Packs[1].robux=2.5 end,function(c)c.Packs[1].name='' end,
 }) do local c=copy();mutate(c);check(not Service.validate(c),'Unsafe configuration rejected')end
 groups[#groups+1]='Proportional configured packs; no enabling without persistent profiles'
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
 check(#calls==1 and calls[1].p==player and calls[1].d.available==false,'Only that player receives disabled preview')
 check(#calls[1].d.packs==4,'Four prepared packs shown')
 check(not shop:open(player),'Repeated open throttled')
 now+=1;root.Position=pos(13);check(not shop:open(player),'Remote opening denied outside bench reach')
 root.Position=pos(0);humanoid.Health=0;check(not shop:open(player),'Dead player cannot open')
 humanoid.Health=100;check(not shop:open(outsider),'Unknown player rejected')
 player.Parent=false;check(not shop:open(player),'Disconnected player rejected');player.Parent=true
 anchor.Parent=false;check(not shop:open(player),'Removed bench rejected');anchor.Parent=true
 check(not shop:open(nil),'Nil player rejected')
 groups[#groups+1]='Server-proximity checks, player state, throttling and targeted opening'
 for _,payload in ipairs({{}, {id='pocket'},{productId=12345},{id='fortune',cash=999999999,robux=0},{command='royalseal'},{developer=true},{kind='flight'},{kind='god'},{kind='giftlevels',amount=1000}})do
  check(not shop:request(player,payload),'Forged or legitimate purchase disabled')
  check(state.cash==before.cash and state.held==before.held and state.progression==before.progression,'Preview never changes cash, escrow or levels')
  check(state.powers==before.powers and state.loadout==before.loadout,'Shop never grants powers or developer loadout')
 end
 check(not shop:request(nil,nil),'Malformed request disabled')
 local a=shop:catalog();a.packs[1].cash=9;a.packs[1].name='Tampered';table.remove(a.packs)
 local b=shop:catalog();check(#b.packs==4 and b.packs[1].cash==5000 and b.packs[1].name=='Pocket Cash','Catalog does not expose mutable internal tables')
 shop:removePlayer(player);check(shop.nextOpen[1]==nil,'Disconnect clears throttle state')
 groups[#groups+1]='Every purchase request disabled; cash, escrow and developer features untouched'
 return {assertions=checks,groups=groups}
end
