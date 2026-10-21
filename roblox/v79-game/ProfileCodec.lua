-- Pure, versioned profile snapshots. Roblox storage and session locks live elsewhere.
local Powers=require(script.Parent.PowerCatalog)
local M={SchemaVersion=1,MaxReceipts=10000,MaxCatchupSeconds=60}
local MAX_CASH,MAX_CREDIT=2000000000,1000000000000
local settingsDefaults={musicMuted=false,sfxMuted=false,reducedEffects=false,musicVolume=.18,sfxVolume=.55}
local topKeys={schemaVersion=true,userId=true,cash=true,bank=true,level=true,steals=true,items=true,
 equipped=true,powerOwned=true,loadout=true,powerSlots=true,starterChosen=true,seen=true,
 infinityAwarded=true,pendingReward=true,rewardReadyAt=true,settings=true,tutorialCompleted=true,
 receipts=true,paidCashCredit=true,checkpointAt=true,checkpointIncome=true,powerReadyAt=true,
 castReadyAt=true,protectionUntilAt=true,protectionReadyAt=true,carryReturnRecovery=true}
local function finite(value)return type(value)=='number'and value==value and math.abs(value)<math.huge end
local function number(value,minimum,maximum,integer)
 return finite(value)and value>=minimum and value<=maximum and(not integer or value%1==0)
end
local function identifier(value,maximum)
 return type(value)=='string'and #value>=1 and #value<=maximum and string.match(value,'^[%w_%-:]+$')~=nil
end
local function onlyKeys(object,allowed)
 for key in pairs(object)do if allowed[key]==nil then return false end end
 return true
end
local function clone(value)
 if type(value)~='table'then return value end
 local out={};for key,item in pairs(value)do out[key]=clone(item)end;return out
end
local function dense(array,maximum)
 if type(array)~='table'or #array>maximum then return false end
 for key in pairs(array)do if not number(key,1,#array,true)then return false end end
 for i=1,#array do if array[i]==nil then return false end end
 return true
end
local function deadline(clockValue,now,wall)
 return wall+math.max(0,(clockValue or 0)-now)
end
function M.validate(data,catalog,powers)
 powers=powers or Powers
 if type(data)~='table'or data.schemaVersion~=M.SchemaVersion then return false,'Unsupported profile schema.'end
 if not onlyKeys(data,topKeys)then return false,'Unsupported profile field.'end
 if not number(data.userId,1,9007199254740991,true)
  or not number(data.cash,0,MAX_CASH,true)or not number(data.bank,0,MAX_CASH,false)
  or not number(data.level,0,1000,true)or not number(data.steals,0,MAX_CASH,true)
  or not number(data.paidCashCredit,0,MAX_CREDIT,true)
  or not number(data.checkpointAt,0,9007199254740991,true)
  or not number(data.checkpointIncome,0,MAX_CREDIT,false)then return false,'Invalid profile economy.'end
 local capacity=data.level>=5 and 16 or 8
 if not dense(data.items,capacity)then return false,'Invalid inventory array.'end
 local uids,slots={},{}
 for _,item in ipairs(data.items)do
  if type(item)~='table'or not onlyKeys(item,{uid=true,kind=true,slot=true,deposited=true,exodiaUsed=true})
   or not identifier(item.uid,96)or uids[item.uid]or not catalog.ById[item.kind]
   or not number(item.slot,1,capacity,true)or slots[item.slot]
   or type(item.deposited)~='boolean'or type(item.exodiaUsed)~='boolean'then return false,'Invalid stored item.'end
  uids[item.uid]=true;slots[item.slot]=true
 end
 if data.equipped~=nil and(not identifier(data.equipped,96)or not uids[data.equipped])then return false,'Equipped item is not stored.'end
 if type(data.powerOwned)~='table'or data.powerOwned.tag~=true
  or type(data.loadout)~='table'or(data.powerSlots~=2 and data.powerSlots~=3)
  or data.loadout['1']~='tag'or type(data.starterChosen)~='boolean'then return false,'Invalid power state.'end
 for key,value in pairs(data.powerOwned)do if not powers.ById[key]or value~=true then return false,'Unknown owned power.'end end
 local equippedPowers={}
 for savedSlot,key in pairs(data.loadout)do
  local slot=type(savedSlot)=='string'and tonumber(savedSlot)or nil
  if type(savedSlot)~='string'or tostring(slot)~=savedSlot or not number(slot,1,data.powerSlots,true)or not powers.ById[key]or data.powerOwned[key]~=true
   or equippedPowers[key]or(slot~=1 and key=='tag')then return false,'Invalid saved loadout.'end
  equippedPowers[key]=true
 end
 if type(data.powerReadyAt)~='table'then return false,'Invalid power cooldowns.'end
 for key,value in pairs(data.powerReadyAt)do
  if not powers.ById[key]or not number(value,0,data.checkpointAt+86400,false)then return false,'Invalid power deadline.'end
 end
 for _,key in ipairs({'rewardReadyAt','castReadyAt','protectionUntilAt','protectionReadyAt'})do
  if not number(data[key],0,data.checkpointAt+86400,false)then return false,'Invalid saved deadline.'end
 end
 if type(data.seen)~='table'then return false,'Invalid discoveries.'end
 for key,value in pairs(data.seen)do if not catalog.ById[key]or value~=true then return false,'Unknown discovery.'end end
 if type(data.infinityAwarded)~='boolean'or type(data.tutorialCompleted)~='boolean'
  or(data.pendingReward~=nil and not identifier(data.pendingReward,96))then return false,'Invalid reward state.'end
 if type(data.settings)~='table'or not onlyKeys(data.settings,settingsDefaults)
  or type(data.settings.musicMuted)~='boolean'or type(data.settings.sfxMuted)~='boolean'
  or type(data.settings.reducedEffects)~='boolean'
  or not number(data.settings.musicVolume,0,1,false)or not number(data.settings.sfxVolume,0,1,false)then return false,'Invalid saved settings.'end
 if type(data.receipts)~='table'then return false,'Invalid receipt ledger.'end
 local count=0
 for purchaseId,record in pairs(data.receipts)do
  count+=1
  if count>M.MaxReceipts or not identifier(purchaseId,160)or type(record)~='table'
   or not onlyKeys(record,{productId=true,grantedAt=true,offerId=true,result=true})
   or not number(record.productId,1,9007199254740991,true)
   or not number(record.grantedAt,0,9007199254740991,true)or not identifier(record.offerId,64)
   or(record.result~='Granted'and record.result~='CashFallback')then return false,'Invalid receipt record or receipt capacity reached.'end
 end
 if data.carryReturnRecovery~=nil then
  local recovery=data.carryReturnRecovery
  if type(recovery)~='table'or not onlyKeys(recovery,{uid=true,kind=true,pickupX=true})
   or not identifier(recovery.uid,96)or uids[recovery.uid]or not catalog.ById[recovery.kind]
   or not number(recovery.pickupX,-10000,10000,false)then return false,'Invalid paid carry recovery.'end
 end
 return true
end
function M.capture(core,id,now,wall)
 local p=core.players[id]
 if not p or not number(now,0,9007199254740991,false)or not number(wall,0,9007199254740991,true)then return nil,'Player or capture clock unavailable.'end
 local cash=p.cash
 -- A bid is still a reservation. A carried purchase is a committed wager.
 if p.pending then
  local tx=core.transactions[p.pending]
  if not tx or tx.resolved or tx.status~='Reserved'or tx.player~=id then return nil,'Pending reservation is inconsistent.'end
  cash+=tx.amount
 end
 local data={schemaVersion=M.SchemaVersion,userId=id,cash=cash,bank=p.bank,level=p.progression or p.level or 0,
  steals=p.steals,paidCashCredit=p.paidCashCredit or 0,items={},equipped=p.equipped,
  powerOwned=clone(p.powerOwned or{tag=true}),loadout={},powerSlots=p.powerSlots or 2,
  starterChosen=p.starterChosen==true,seen=clone(p.seen or{}),
  infinityAwarded=core.infinityAwarded[id]==true,pendingReward=p.pendingReward,
  rewardReadyAt=deadline(p.rewardReady,now,wall),castReadyAt=deadline(p.castReady,now,wall),
  protectionUntilAt=deadline(p.lockUntil,now,wall),protectionReadyAt=deadline(p.lockReady,now,wall),
  settings=clone(p.settings or settingsDefaults),tutorialCompleted=p.tutorialCompleted==true,
  receipts=clone(p.receipts or{}),checkpointAt=wall,checkpointIncome=core:income(id),powerReadyAt={}}
 for slot,key in pairs(p.loadout or{'tag'})do data.loadout[tostring(slot)]=key end
 for key,value in pairs(p.powerReady or{})do
  if value>now then data.powerReadyAt[key]=deadline(value,now,wall)end
 end
 for slot=1,p.capacity do
  local uid=p.slots[slot];local item=uid and core.items[uid]
  if item and item.owner==id then
   -- A stolen item remains its original owner's property until deposit.
   if item.state~='Stored'and item.state~='TheftCarry'then return nil,'Owned item has an inconsistent state.'end
   data.items[#data.items+1]={uid=uid,kind=item.kind,slot=slot,deposited=item.deposited==true,exodiaUsed=core.exodiaUsed[uid]==true}
  end
 end
 if data.equipped then
  local found=false;for _,item in ipairs(data.items)do if item.uid==data.equipped then found=true;break end end
  if not found then data.equipped=nil end
 end
 if p.carry then
  local item=core.items[p.carry];local tx=item and core.transactions[item.tx]
  if not item or not tx or tx.resolved or tx.status~='Carrying'or tx.player~=id then return nil,'Carry transaction is inconsistent.'end
  if item.state=='PurchaseCarry'then data.carryReturnRecovery={uid=item.uid,kind=item.kind,pickupX=tx.pickupX}
  elseif item.state~='TheftCarry'then return nil,'Unexpected carried item state.'end
 elseif p.carryReturnRecovery then data.carryReturnRecovery=clone(p.carryReturnRecovery)end
 local ok,why=M.validate(data,core.catalog)
 if not ok then return nil,why end
 return data
end
function M.defaults(core,id,now,wall)return M.capture(core,id,now,wall)end
function M.restore(core,id,data,now,wall)
 local valid,why=M.validate(data,core.catalog)
 if not valid then return false,why end
 if data.userId~=id or not core.players[id]or not number(now,0,9007199254740991,false)
  or not number(wall,0,9007199254740991,true)then return false,'Profile owner or restore clock mismatch.'end
 -- Validate all conflicts before deleting even the temporary fresh starter.
 for _,item in ipairs(data.items)do
  local existing=core.items[item.uid]
  if existing and(existing.owner~=id or existing.carrier~=nil)then return false,'Stored UID conflicts with an active item.'end
 end
 local recovery=data.carryReturnRecovery
 if recovery and core.items[recovery.uid]then return false,'Paid carry recovery UID is already active.'end
 local old=core.players[id]
 if old.carry or old.pending then return false,'Cannot load a profile over an active transaction.'end
 local restored=clone(data)
 local elapsed=math.clamp(wall-data.checkpointAt,0,M.MaxCatchupSeconds)
 local p={cash=data.cash,bank=math.min(MAX_CASH,data.bank+elapsed*data.checkpointIncome),
  progression=data.level,level=data.level,capacity=data.level>=5 and 16 or 8,steals=data.steals,
  paidCashCredit=data.paidCashCredit,slots={},seen=clone(data.seen),equipped=data.equipped,
  powerOwned=clone(data.powerOwned),loadout={},powerSlots=data.powerSlots,
  starterChosen=data.starterChosen,powerReady={},held=0,pending=nil,carry=nil,
  rewardReady=now+math.max(0,data.rewardReadyAt-wall),pendingReward=data.pendingReward,
  castReady=now+math.max(0,data.castReadyAt-wall),cooldown=0,
  lockUntil=now+math.max(0,data.protectionUntilAt-wall),
  lockReady=now+math.max(0,data.protectionReadyAt-wall),
  settings=clone(data.settings),tutorialCompleted=data.tutorialCompleted,receipts=clone(data.receipts),
  carryReturnRecovery=clone(data.carryReturnRecovery),profileCheckpointAt=data.checkpointAt,profileRestored=true}
 for key,value in pairs(data.powerReadyAt)do p.powerReady[key]=now+math.max(0,value-wall)end
 for slot,key in pairs(data.loadout)do p.loadout[tonumber(slot)]=key end
 for uid,item in pairs(core.items)do if item.owner==id then core.items[uid]=nil;core.exodiaUsed[uid]=nil end end
 core.players[id]=p
 for _,item in ipairs(data.items)do
  core.items[item.uid]={uid=item.uid,kind=item.kind,slot=item.slot,owner=id,state='Stored',deposited=item.deposited}
  p.slots[item.slot]=item.uid
  if item.exodiaUsed then core.exodiaUsed[item.uid]=true end
 end
 core.infinityAwarded[id]=data.infinityAwarded or nil
 core:changed()
 -- Return normalized recovered bank/checkpoint data for the caller's first save.
 restored.bank=p.bank;restored.checkpointAt=wall;restored.checkpointIncome=core:income(id)
 return true,restored
end
return M
