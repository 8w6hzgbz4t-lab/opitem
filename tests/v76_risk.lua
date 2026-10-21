-- Execute the real immutable-item transaction ledger under the V76 risk policy.
return function(package,requireModule)
 local Core=requireModule(package.Core);local Catalog=requireModule(package.Catalog);local Config=requireModule(package.Config)
 local checks=0
 local function check(value,message)checks+=1;assert(value,message)end
 local function fresh(n)
  local c=Core.new(Catalog,Config)
  for id=1,n or 2 do c:addPlayer(id,0);c.players[id].cash=10000000 end
  return c
 end
 for _,item in ipairs(Catalog.Items)do
  local c=fresh();local buyer=c.players[1];local before=buyer.cash
  local offer=c:setOffer('risk',item.id,100,55);local uid,token=offer.uid,offer.token
  check(c:purchaseAttempt(1,'risk',token,100),item.id..' reserve')
  c:advance(101.6);local tx=c.transactions[c.items[uid].tx]
  check(buyer.carry==uid and tx.status=='Carrying',item.id..' pickup')
  check(not c:withdraw(1,102),item.id..' cannot withdraw after pickup')
  check(c:finish(1,false,103),item.id..' failed delivery resolves')
  check(buyer.cash==before-item.price and buyer.held==0 and not buyer.carry,item.id..' forfeits exact paid amount')
  check(tx.resolved and tx.status=='Lost',item.id..' recorded paid loss')
  check(c.items[uid].state=='Conveyor' and not c.items[uid].owner and offer.uid==uid,item.id..' same item returns')
  check(offer.x==55 and offer.token~=token and offer.expires>103,item.id..' recorded pickup point/new offer token')
  check(not c:finish(1,false,104) and not c:purchaseAttempt(1,'risk',token,104),item.id..' no replay/refund')
  check(buyer.cash==before-item.price and c:free(1)==2,item.id..' exact loss and slot released once')
  check(c:purchaseAttempt(1,'risk',offer.token,104),item.id..' returned item can be contested again')
  c:advance(105.6);check(c:finish(1,true,106),item.id..' next paid attempt can deliver')
  check(buyer.cash==before-2*item.price and c.items[uid].owner==1,item.id..' retry is a new purchase')
  local pending=fresh();local bid=pending:setOffer('bid',item.id,100,55)
  check(pending:purchaseAttempt(1,'bid',bid.token,100),item.id..' unfinished bid setup')
  check(pending:withdraw(1,100.2),item.id..' unfinished bid withdraw')
  check(pending.players[1].cash==10000000 and pending.players[1].held==0,item.id..' unfinished reservation fully released')
 end
 local c=fresh();local o=c:setOffer('auction','item01',100,55)
 check(c:purchaseAttempt(1,'auction',o.token,100) and c:purchaseAttempt(2,'auction',o.token,100),'auction setup')
 c:advance(101.6);check(c:bid(2,'auction',400,102),'winning bid')
 c:advance(110)
 check(c.players[1].cash==10000000 and c.players[1].held==0,'auction loser refunded')
 check(c.players[2].carry==o.uid and c:finish(2,false,111),'auction winner intercepted')
 check(c.players[2].cash==10000000-400 and c.players[2].held==0,'winner loses actual winning bid, not catalog price')
 c=fresh();o=c:setOffer('safe','item05',100,55);check(c:purchaseAttempt(1,'safe',o.token,100),'safe event setup');c:advance(101.6)
 c:cancelAll(102);check(c.players[1].cash==10000000 and c.players[1].held==0 and c.items[o.uid].state=='Conveyor','trusted forced safe event keeps promised recovery')
 c=fresh();o=c:setOffer('leave','item05',100,55);c:purchaseAttempt(1,'leave',o.token,100);c:advance(101.6)
 local buyer=c.players[1];local tx=c.transactions[c.items[o.uid].tx];c:removePlayer(1)
 check(tx.status=='Lost' and buyer.cash==10000000-Catalog.ById.item05.price,'disconnect cannot bypass paid risk')
 check(c.items[o.uid].state=='Conveyor' and not c.items[o.uid].owner,'disconnect restores same item for other buyers')
 return string.format('%d checks; all 76 paid carried-item losses forfeit exact purchase price; original pickup points and UIDs; retries; losing/withdrawn bid refunds; auction winner forfeits winning bid; safe-event recovery; disconnect risk',checks)
end
