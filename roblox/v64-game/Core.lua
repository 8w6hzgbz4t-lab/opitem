-- Engine-independent session state. Spatial and rate checks live in Server.
local Core={}; Core.__index=Core
function Core.new(catalog,config)
 return setmetatable({players={},items={},offers={},seq=0,catalog=catalog,revision=0,config=config or require(script.Parent.Config)},Core)
end
function Core:changed() self.revision=self.revision+1 end
function Core:addPlayer(id,now)
 assert(not self.players[id],'duplicate player')
 self.players[id]={cash=self.config.StartingCash,bank=0,capacity=self.config.BaseSlots,level=0,slots={},seen={},lockUntil=now+self.config.SpawnProtection,lockReady=now+self.config.SpawnProtection,steals=0,cooldown=0}
 self:grant(id,self.config.StarterItem); self:changed()
 return self.players[id]
end
function Core:free(id)
 local p=self.players[id]; if not p then return nil end
 for i=1,p.capacity do if not p.slots[i] then return i end end
end
function Core:grant(id,kind)
 local p=self.players[id]; local slot=self:free(id)
 if not p or not slot or not self.catalog.ById[kind] then return nil end
 self.seq=self.seq+1; local uid='relic'..self.seq
 self.items[uid]={uid=uid,kind=kind,owner=id,slot=slot}
 p.slots[slot]=uid; p.seen[kind]=true; p.equipped=p.equipped or uid
 self:changed(); return uid
end
function Core:setOffer(index,kind)
 assert(self.catalog.ById[kind]); self.seq=self.seq+1
 self.offers[index]={kind=kind,token='offer'..self.seq}; self:changed()
end
function Core:buy(id,index,token)
 local p,o=self.players[id],self.offers[index]
 if not p or not o or o.token~=token then return false,'Offer changed.' end
 if p.carry then return false,'Deliver your loot first.' end
 if not self:free(id) then return false,'Vault full. Sell a relic or buy more slots.' end
 local d=self.catalog.ById[o.kind]
 if p.cash<d.price then return false,'Not enough cash. Collect your vault earnings.' end
 p.cash=p.cash-d.price; self.offers[index]=nil
 self:grant(id,o.kind); self:changed(); return true,'Purchased '..d.name
end
function Core:beginSteal(thief,uid,now)
 local p,it=self.players[thief],self.items[uid]
 if not p or not it or it.owner==thief or it.carrier or p.carry then return false,'Relic unavailable.' end
 local owner=self.players[it.owner]
 if not owner or now<owner.lockUntil then return false,'This vault is protected.' end
 local slot=self:free(thief); if not slot then return false,'Your vault is full.' end
 p.slots[slot]=uid; p.carry=uid; it.carrier=thief; it.destination=slot; it.started=now
 self:changed(); return true,'Return to your green delivery pad!'
end
function Core:finish(thief,success)
 local p=self.players[thief]; local it=p and self.items[p.carry]
 if not it then return false end
 local old=self.players[it.owner]
 p.slots[it.destination]=nil; p.carry=nil
 if success and old then
  old.slots[it.slot]=nil
  if old.equipped==it.uid then old.equipped=nil end
  it.owner=thief; it.slot=it.destination; p.slots[it.slot]=it.uid
  p.seen[it.kind]=true; p.steals=p.steals+1
  if not p.equipped then p.equipped=it.uid end
 elseif not old then self.items[it.uid]=nil end
 it.carrier=nil; it.destination=nil; it.started=nil
 self:changed(); return true
end
function Core:sell(id,uid)
 local p,it=self.players[id],self.items[uid]
 if not p or not it or it.owner~=id or it.carrier or p.carry then return false,'Cannot sell this relic now.' end
 p.cash=math.min(2000000000,p.cash+math.floor(self.catalog.ById[it.kind].price*.5))
 p.slots[it.slot]=nil; if p.equipped==uid then p.equipped=nil end
 self.items[uid]=nil; self:changed(); return true,'Sold for 50% of purchase value.'
end
function Core:equip(id,uid)
 local p,it=self.players[id],self.items[uid]
 if not p or not it or it.owner~=id or it.carrier or p.carry then return false,'Cannot equip this relic now.' end
 p.equipped=uid; self:changed(); return true,'Equipped '..self.catalog.ById[it.kind].name
end
function Core:income(id)
 local n=0
 for _,it in pairs(self.items) do if it.owner==id and not it.carrier then n=n+self.catalog.ById[it.kind].income end end
 return n
end
function Core:tick(seconds)
 for id,p in pairs(self.players) do p.bank=math.min(2000000000,p.bank+self:income(id)*seconds) end
end
function Core:collect(id)
 local p=self.players[id]; if not p then return false end
 local amount=math.min(p.bank,2000000000-p.cash)
 p.cash=p.cash+amount; p.bank=p.bank-amount; self:changed(); return true,'Collected $'..amount
end
function Core:upgradeCost(id) local p=self.players[id]; return p and 1500*3^p.level end
function Core:upgrade(id)
 local p=self.players[id]
 if not p or p.carry then return false,'Deliver your loot first.' end
 if p.capacity>=self.config.BaseSlots then return false,'All eight pedestals are available.' end
 local cost=self:upgradeCost(id)
 if p.cash<cost then return false,'Upgrade costs $'..cost end
 p.cash=p.cash-cost; p.level=p.level+1; p.capacity=math.min(self.config.BaseSlots,p.capacity+2)
 self:changed(); return true,'Vault expanded to '..p.capacity..' slots.'
end
function Core:protect(id,now)
 local p=self.players[id]
 if not p then return false,'No vault.' end
 if now<p.lockReady then return false,'Protection recharges in '..math.ceil(p.lockReady-now)..'s.' end
 p.lockUntil=now+self.config.ProtectionDuration; p.lockReady=now+self.config.ProtectionRecharge; self:changed(); return true,'Stored relics protected for '..self.config.ProtectionDuration..'s.'
end
function Core:power(id,now)
 local p=self.players[id]; local it=p and self.items[p.equipped]
 if not p or not it or it.owner~=id or it.carrier then return false,'Equip an available relic first.' end
 if p.carry then return false,'Powers are disabled while carrying loot.' end
 if now<p.cooldown then return false,'Power recharging.' end
 local power=self.catalog.ById[it.kind].power
 p.cooldown=now+self.catalog.ById[it.kind].cooldown; self:changed(); return true,power
end
function Core:removePlayer(id)
 local p=self.players[id]; if not p then return end
 self:finish(id,false)
 for thief,tp in pairs(self.players) do
  local it=self.items[tp.carry]
  if it and it.owner==id then self:finish(thief,false) end
 end
 for uid,it in pairs(self.items) do if it.owner==id then self.items[uid]=nil end end
 self.players[id]=nil; self:changed()
end
function Core:snapshot(id,now)
 local p=self.players[id]; if not p then return nil end
 local inv={}
 for slot=1,p.capacity do
  local it=self.items[p.slots[slot]]
  if it and it.owner==id then inv[#inv+1]={uid=it.uid,kind=it.kind,slot=slot,carried=it.carrier~=nil} end
 end
 return {cash=p.cash,bank=p.bank,income=self:income(id),capacity=p.capacity,level=p.level,upgrade=self:upgradeCost(id),inventory=inv,seen=p.seen,equipped=p.equipped,carry=p.carry,steals=p.steals,lock=math.max(0,math.ceil(p.lockUntil-now)),lockReady=math.max(0,math.ceil(p.lockReady-now)),cooldown=math.max(0,math.ceil(p.cooldown-now)),revision=self.revision}
end
return require(script.Parent.TransactionCore).install(Core)
