-- Official Luau integration check for version 64's actual Catalog/Core modules.
-- Run with tools/run_game_checks.py --root roblox/v64-game --baseline roblox/game
-- --check tests/free_catalog_upgrade.lua --luau <official Luau CLI>.
return function(package,requireModule,baselinePackage)
 assert(baselinePackage,"Native model catalog integration requires the version 63 baseline")
 local original=requireModule(baselinePackage.Catalog)
 local current=requireModule(package.Catalog)
 local Core=requireModule(package.Core)
 local Config=requireModule(package.Config)
 local Rules=requireModule(package.PhaseConfig)
 local checks=0
 local function check(value,message)
  assert(value,message)
  checks=checks+1
 end
 check(#original.Items==46,"The baseline is the existing version 63 catalog")
 check(#current.Items==63,"The upgraded catalog contains 46 existing plus 17 new items")
 for index,old in ipairs(original.Items) do
  local item=current.Items[index]
  check(item.id==old.id,"Existing collectible ID/order is preserved: "..old.id)
  for key,value in pairs(old) do
   check(item[key]==value,"Existing collectible data is preserved: "..old.id.."/"..key)
  end
  for key in pairs(item) do
   check(old[key]~=nil,"Existing collectible fields remain unchanged: "..old.id.."/"..key)
  end
 end
 for tier,label in ipairs(original.Tiers) do
  check(current.Tiers[tier]==label,"Rarity label preserved")
  check(current.Weights[tier]==original.Weights[tier],"This model release preserves existing rarity weights")
  for channel,value in ipairs(original.Colors[tier]) do
   check(current.Colors[tier][channel]==value,"Rarity display color preserved")
  end
 end
 check(current.SpawnSettings.PokemonWeightMultiplier==original.SpawnSettings.PokemonWeightMultiplier,"Existing Pokemon multiplier is preserved")
 for id,value in pairs(original.SpawnSettings.PokemonIds) do
  check(current.SpawnSettings.PokemonIds[id]==value,"Existing Pokemon ID reduction is preserved")
 end
 for id,value in pairs(current.SpawnSettings.PokemonIds) do
  check(original.SpawnSettings.PokemonIds[id]==value,"No new franchise-wide Pokemon IDs are introduced")
 end

 local unique,newModels,stones={}, {},0
 for index,item in ipairs(current.Items) do
  check(item.id==string.format("item%02d",index),"Catalog IDs remain contiguous")
  check(not unique[item.id] and current.ById[item.id]==item,"Unique catalog lookup: "..item.id)
  unique[item.id]=true
  check(type(item.name)=="string" and #item.name>0,"Readable name: "..item.id)
  check(type(item.price)=="number" and item.price>0 and item.price%1==0,"Valid purchase price: "..item.id)
  check(type(item.income)=="number" and item.income>0,"Valid deposited income: "..item.id)
  check(type(item.spawnWeight)=="number" and item.spawnWeight>0,"Positive spawn weight: "..item.id)
  check(current.Tiers[item.tier]==item.rarity,"Actual rarity and index label agree: "..item.id)
  local occurrences=0
  for _,entry in ipairs(current.ByTier[item.tier]) do if entry==item then occurrences=occurrences+1 end end
  check(occurrences==1,"Every item occurs once in its native rarity pool: "..item.id)
  if index>46 then
   check(not newModels[item.model],"New visual keys are unique")
   newModels[item.model]=item.id
   if item.model:match("^infinity_") then
    stones=stones+1
    check(item.rarity=="Legendary","Infinity Stones are actual Legendary catalog items")
   end
  end
 end
 check(stones==6,"Six distinct Infinity Stones are included")
 for _,key in ipairs({"infinity_space","infinity_mind","infinity_reality","infinity_power","infinity_time","infinity_soul",
  "kirby_sword","golden_spatula","krabby_patty","gary_shell","super_star","fire_flower","hylian_shield","companion_cube","proton_pack","pekka","mega_knight"}) do
  check(newModels[key]~=nil,"Requested new collectible is buyable: "..key)
 end
 check(current.ById.item05.model==original.ById.item05.model,"Blue Shell retains its existing catalog model key")
 check(current.ById.item08.model=="puzzle" and current.ById.item43.model=="dragonballs","Puzzle and Dragon Balls retain their existing IDs/models")

 -- Exercise both sides of every actual two-stage native roll interval. Drawing
 -- the tier and item separately ensures every added item is truly reachable.
 local function rollAt(tierDraw,itemDraw)
  local draws={tierDraw,itemDraw};local index=0
  local kind=current.roll({NextNumber=function()
   index=index+1
   return assert(draws[index],"Unexpected catalog random draw")
  end})
  check(index==2,"Native catalog consumes one tier draw and one item draw")
  return kind
 end
 local tierTotal=0
 for tier,weight in ipairs(current.Weights) do if #current.ByTier[tier]>0 then tierTotal=tierTotal+weight end end
 local tierStart=0
 for tier,weight in ipairs(current.Weights) do
  local pool=current.ByTier[tier]
  if #pool>0 then
   local itemTotal=0
   for _,item in ipairs(pool) do itemTotal=itemTotal+item.spawnWeight end
   local itemStart=0
   for _,item in ipairs(pool) do
    for _,t in ipairs({.000001,.5,.999999}) do
     for _,v in ipairs({.000001,.5,.999999}) do
      check(rollAt((tierStart+weight*t)/tierTotal,(itemStart+item.spawnWeight*v)/itemTotal)==item.id,
       "Actual roll interval selects the expected collectible: "..item.id)
     end
    end
    itemStart=itemStart+item.spawnWeight
   end
   tierStart=tierStart+weight
  end
 end
 check(rollAt(0,0)==current.ByTier[1][1].id,"Native lower random boundary remains valid")
 local seed,seen=47293,{}
 local rng={NextNumber=function()
  seed=seed*16807%2147483647
  return (seed-1)/2147483646
 end}
 for _=1,60000 do
  local kind=current.roll(rng)
  check(current.ById[kind]~=nil,"Actual weighted roll returns a catalog ID")
  seen[kind]=(seen[kind] or 0)+1
 end
 for _,kind in pairs(newModels) do check((seen[kind] or 0)>0,"New item appears in deterministic native roll sample: "..kind) end

 local function invariant(c)
  for id,p in pairs(c.players) do
   check(p.capacity==8 and p.cash>=0 and p.held>=0,"Eight-slot capacity and nonnegative funds")
   local escrow=0
   for _,tx in pairs(c.transactions) do
    if tx.player==id and not tx.resolved then
     escrow=escrow+tx.amount
     check(p.slots[tx.slot]=="@"..tx.id,"Unresolved transactions retain their reserved slots")
    end
   end
   check(p.held==escrow,"Escrow matches actual unresolved transaction balances")
   if p.carry then
    local it=c.items[p.carry]
    check(it and it.carrier==id and c.transactions[it.tx].status=="Carrying","Carried item has one active carrier transaction")
   end
  end
  for uid,it in pairs(c.items) do
   if it.state=="Stored" then check(c.players[it.owner].slots[it.slot]==uid,"Stored ownership and slot agree") end
  end
 end
 for index=47,63 do
  local item=current.Items[index]
  local c=Core.new(current,Config)
  c:addPlayer(1,0);c:addPlayer(2,0)
  c.players[1].cash=10000000;c.players[2].cash=10000000
  local income1,income2=c:income(1),c:income(2)
  local offer=c:setOffer("new-"..item.id,item.id,100,55)
  local uid,token=offer.uid,offer.token
  check(c:purchaseAttempt(1,offer.id,token,100),"New item can reserve a purchase: "..item.id)
  check(c.players[1].cash==10000000-item.price and c.players[1].held==item.price,"Correct funds held before delivery: "..item.id)
  check(c.items[uid].owner==nil and c:income(1)==income1,"Ownership and income wait for deposit: "..item.id)
  invariant(c)
  local pickup=100+Rules.ContestWindow+.01
  c:advance(pickup)
  check(c.players[1].carry==uid and c.items[uid].state=="PurchaseCarry","New item enters overhead carry state: "..item.id)
  check(not c:power(1,pickup,"tag"),"Carrier powers are disabled: "..item.id)
  check(c:finish(1,true,pickup+1),"New item delivers successfully: "..item.id)
  check(c.items[uid].owner==1 and c.items[uid].state=="Stored" and c.items[uid].deposited,"Deposit establishes ownership: "..item.id)
  check(c.players[1].held==0 and c.players[1].cash==10000000-item.price and c:income(1)==income1+item.income,"One deposit commits funds and income once: "..item.id)
  check(c.players[1].seen[item.id] and not c.offers[offer.id],"Deposit updates the index and clears the offer: "..item.id)
  check(not c:finish(1,true,pickup+2),"Duplicate deposit cannot commit twice: "..item.id)
  invariant(c)

  check(c:beginSteal(2,uid,110),"Stored new item can be stolen: "..item.id)
  check(c.items[uid].owner==1 and c.items[uid].state=="TheftCarry" and c:income(1)==income1,"Theft pauses income before ownership changes: "..item.id)
  check(not c:power(2,110.1,"tag"),"Thief powers are disabled while carrying: "..item.id)
  invariant(c)
  check(c:finish(2,false,111),"Interrupted theft recovers the new item: "..item.id)
  check(c.items[uid].owner==1 and c.items[uid].state=="Stored" and c:income(1)==income1+item.income,"Recovery restores owner income: "..item.id)
  check(c:beginSteal(2,uid,112) and c:finish(2,true,113),"Completed theft transfers the new item: "..item.id)
  check(c.items[uid].owner==2 and c:income(1)==income1 and c:income(2)==income2+item.income,"Theft permanently transfers stored income once: "..item.id)
  check(c.players[2].steals==1 and not c:finish(2,true,114),"Theft transfer cannot replay: "..item.id)
  invariant(c)

  local retry=c:setOffer("refund-"..item.id,item.id,120,42)
  local initialCash=c.players[1].cash
  local oldToken=retry.token
  check(c:purchaseAttempt(1,retry.id,oldToken,120),"New item supports another independent purchase: "..item.id)
  c:advance(120+Rules.ContestWindow+.01)
  check(c:finish(1,false,123),"Interrupted purchase returns the new item: "..item.id)
  check(c.players[1].cash==initialCash and c.players[1].held==0,"Interrupted purchase refunds escrow once: "..item.id)
  check(c.items[retry.uid].state=="Conveyor" and retry.x==42 and retry.token~=oldToken,"Return restores the original pickup location with a fresh token: "..item.id)
  check(not c:finish(1,false,124) and not c:purchaseAttempt(1,retry.id,oldToken,124),"Duplicate refund and stale purchase tokens reject: "..item.id)
  invariant(c)
 end
 return string.format("%d checks; original 46 item records/weights preserved; 63 actual catalog entries and roll intervals; six Legendary stones; all 17 new items pass real purchase/carry/deposit/refund/theft ledgers",checks)
end
