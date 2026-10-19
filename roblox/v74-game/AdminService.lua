local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local TextService=game:GetService('TextService')
local Policy=require(script.Parent.AdminPolicy)
local Powers=require(script.Parent.PowerCatalog)
local S={}; S.__index=S
local specs={
 help='help',state='state',logs='logs [count]',inventory='inventory <UserId|self>',
 cash='cash <UserId|self> <add|remove|set> <amount>',
 grant='grant <UserId|self> <itemID> [quantity]',remove='remove <UserId|self> <ownedRelicUID>',
 offer='offer <itemID>',teleport='teleport <UserId|self> <x> <y> <z>',
 flight='flight <on|off>',noclip='noclip <on|off>',protect='protect <UserId|self> <seconds>',
 god='god <on|off>',speed='speed <16..64>',jump='jump <50..120>',heal='heal',
 powers='powers',cooldowns='cooldowns',cast='cast <powerID>',home='home',resetmods='resetmods',
 announce='announce <message>',kick='kick <UserId> [reason]',ban='ban <UserId> [reason]',unban='unban <UserId>',
}
local function number(value,minimum,maximum,integer)
 local n=tonumber(value)
 if not n or n~=n or n==math.huge or n==-math.huge or n<minimum or n>maximum or (integer and n%1~=0) then return nil end
 return n
end
local function setOwnership(root,serverOwned)
 if root and root:IsDescendantOf(workspace) and not root.Anchored then
  local allowed=root:CanSetNetworkOwnership()
  if allowed then
   if serverOwned then root:SetNetworkOwner(nil) else root:SetNetworkOwnershipAuto() end
  end
 end
end
function S.new(config,ctx)
 local clock=ctx.clock or os.clock
 local resolved={};for key,value in pairs(config) do resolved[key]=value end
 local explicit=type(config.DeveloperUserId)=='number' and number(config.DeveloperUserId,1,9007199254740991,true) or nil
 if config.Enabled==true and not explicit and (config.DeveloperUserId==nil or config.DeveloperUserId==0) and type(config.DeveloperUsername)=='string' and #config.DeveloperUsername>0 then
  local lookup=ctx.resolveUserId or function(username) return Players:GetUserIdFromNameAsync(username) end
  local ok,id=pcall(lookup,config.DeveloperUsername)
  local numeric=ok and type(id)=='number' and number(id,1,9007199254740991,true) or nil
  if numeric then resolved.DeveloperUserId=numeric
  else
   resolved.DeveloperUserId=0
   warn('Developer menu disabled: Roblox could not resolve the configured developer username. Check AdminConfig and restart the server.')
  end
 end
 config=resolved
 local self=setmetatable({config=config,ctx=ctx,clock=clock,bans={},input={},mobility={},busy={},deniedAt={},chat={}},S)
 local ownerUserId=game.CreatorType==Enum.CreatorType.User and game.CreatorId or nil
 self.policy=Policy.new(config,clock,ctx.nonce or function() return Http:GenerateGUID(false) end,ownerUserId)
 return self
end
function S:authorized(p) return p and self.policy:authorized(p.UserId) end
function S:target(actor,value,online)
 local id=value=='self' and actor.UserId or number(value,1,9007199254740991,true)
 if not id then return nil,'Use a numeric Roblox UserId or self.' end
 if online and not self.ctx.runtime[id] then return nil,'Player is not in this server.' end
 return id
end
function S:parse(actor,raw)
 if type(raw)~='string' or #raw<1 or #raw>512 or string.find(raw,'[%z\1-\8\11\12\14-\31]') then return nil,'Invalid command text.' end
 local words={}; for word in string.gmatch(raw,'%S+') do table.insert(words,word) end
 local name=string.lower(words[1] or ''); local command={name=name,raw=table.concat(words,' '),words=words,destructive=false}
 if not specs[name] then return nil,'Unknown command. Use help.' end
 local n=#words
 if name=='help' or name=='state' or name=='heal' or name=='powers' or name=='cooldowns' or name=='home' or name=='resetmods' then
  if n~=1 then return nil,specs[name] end
  command.target=actor.UserId
 elseif name=='logs' then
  if n>2 then return nil,specs[name] end
  command.count=n==1 and 20 or number(words[2],1,self.config.MaxLogs,true)
  if not command.count then return nil,specs[name] end
 elseif name=='flight' or name=='noclip' or name=='god' then
  if n~=2 or (words[2]~='on' and words[2]~='off') then return nil,specs[name] end
  command.enabled=words[2]=='on';command.target=actor.UserId
 elseif name=='speed' or name=='jump' then
  if n~=2 then return nil,specs[name] end
  local minimum=name=='speed' and (self.config.MinDeveloperSpeed or 16) or (self.config.MinDeveloperJump or 50)
  local maximum=name=='speed' and (self.config.MaxDeveloperSpeed or 64) or (self.config.MaxDeveloperJump or 120)
  command.value=number(words[2],minimum,maximum)
  if not command.value then return nil,specs[name] end
  command.target=actor.UserId
 elseif name=='cast' then
  if n~=2 or not Powers.ById[words[2]] then return nil,specs[name] end
  command.kind=words[2];command.target=actor.UserId
 elseif name=='offer' then
  if n~=2 or not self.ctx.catalog.ById[words[2]] then return nil,'Unknown item ID.' end
  command.kind=words[2]
 elseif name=='announce' then
  command.text=table.concat(words,' ',2)
  if #command.text<1 or #command.text>240 then return nil,'Announcement must contain 1..240 bytes.' end
 else
  local offline=name=='ban' or name=='unban'
  local id,err=self:target(actor,words[2],not offline)
  if not id then return nil,err end;command.target=id
  if name=='inventory' then if n~=2 then return nil,specs[name] end
  elseif name=='cash' then
   if n~=4 or not ({add=true,remove=true,set=true})[words[3]] then return nil,specs[name] end
   command.operation=words[3];command.amount=number(words[4],0,self.config.MaxCurrency,true)
   if not command.amount then return nil,'Invalid currency amount.' end
   command.destructive=command.operation~='add'
  elseif name=='grant' then
   if n<3 or n>4 or not self.ctx.catalog.ById[words[3]] then return nil,specs[name] end
   command.kind=words[3];command.quantity=n==3 and 1 or number(words[4],1,8,true)
   if not command.quantity then return nil,'Quantity must be 1..8.' end
  elseif name=='remove' then
   if n~=3 or #words[3]>40 then return nil,specs[name] end
   command.uid=words[3];command.destructive=true
  elseif name=='teleport' then
   if n~=5 then return nil,specs[name] end
   command.x=number(words[3],-122,122);command.y=number(words[4],3,120);command.z=number(words[5],-90,90)
   if not command.x or not command.y or not command.z then return nil,'Teleport bounds: X ±122, Y 3..120, Z ±90.' end
   local state=self.ctx.core.players[id]
   command.destructive=id~=actor.UserId or (state and (state.carry~=nil or state.pending~=nil)) or false
  elseif name=='protect' then
   if n~=3 then return nil,specs[name] end
   command.seconds=number(words[3],0,self.config.MaxProtectionSeconds,true)
   if not command.seconds then return nil,'Invalid protection duration.' end
   local state=self.ctx.core.players[id]
   local remaining=state and math.max(0,state.lockUntil-self.clock()) or 0
   command.destructive=command.seconds==0 or command.seconds<remaining
  elseif name=='kick' or name=='ban' then
   if n<2 then return nil,specs[name] end
   command.reason=string.sub(table.concat(words,' ',3),1,160);command.destructive=true
  elseif name=='unban' then if n~=2 then return nil,specs[name] end end
 end
 return command
end
function S:readyForMods(p)
 if not self:authorized(p) then return false,'Access denied.' end
 local state=self.ctx.core.players[p.UserId];local root,h=self.ctx.body(p)
 if not state or not root or not h or h.Health<=0 or not root:IsDescendantOf(workspace) then return false,'Character unavailable. Respawn first.' end
 if state.carry or state.pending then return false,'Deliver carried loot or leave the bid battle first.' end
 local rt=self.ctx.runtime[p.UserId]
 if rt and (self.clock()<(rt.shockUntil or 0) or rt.originalJump~=nil) then return false,'Wait until the stun recovery finishes before enabling developer mods.' end
 if rt and self.clock()<(rt.interruptedUntil or 0) then return false,'Wait until the interruption ends before enabling developer mods.' end
 return true,root,h
end
function S:captureMovement(p,h)
 local m=self.mobility[p.UserId] or {player=p,parts={}}
 self.mobility[p.UserId]=m
 if m.moveHumanoid~=h then
  m.moveHumanoid=h
  m.originalMovement={WalkSpeed=h.WalkSpeed,UseJumpPower=h.UseJumpPower,JumpPower=h.JumpPower,JumpHeight=h.JumpHeight}
 end
 return m
end
function S:modsActive(p)
 if not self:authorized(p) then return false end
 local state=self.ctx.core.players[p.UserId]
 if not state or state.carry or state.pending then return false end
 local root,h=self.ctx.body(p)
 return root~=nil and h~=nil and h.Health>0
end
function S:isInvulnerable(p)
 local m=p and self.mobility[p.UserId]
 return m~=nil and m.god==true and self:modsActive(p) or false
end
function S:getWalkSpeed(p,default)
 local m=p and self.mobility[p.UserId]
 return m and self:modsActive(p) and m.speed or default
end
function S:getJumpPower(p,default)
 local m=p and self.mobility[p.UserId]
 return m and self:modsActive(p) and m.jump or default
end
function S:applyMovement(p,h)
 local m=self.mobility[p.UserId];local rt=self.ctx.runtime[p.UserId]
 if not m or not h or not self:modsActive(p) or (rt and self.clock()<(rt.shockUntil or 0)) then return end
 if m.speed and (not rt or self.clock()>=(rt.slow or 0)) then h.WalkSpeed=m.speed end
 if m.jump then h.UseJumpPower=true;h.JumpPower=m.jump end
end
function S:getState(p)
 local m=self.mobility[p.UserId];local _,h=self.ctx.body(p)
 local active=self:modsActive(p)
 return {
  flight=active and m~=nil and m.flight==true or false,
  noclip=active and m~=nil and m.noclip==true or false,
  god=active and m~=nil and m.god==true or false,
  speed=h and h.WalkSpeed or (self.ctx.config and self.ctx.config.WalkSpeed or 16),
  jump=h and h.JumpPower or 50,
  speedOverride=active and m and m.speed or nil,
  jumpOverride=active and m and m.jump or nil,
 }
end
function S:menuData(p)
 local catalog={};for _,d in ipairs(self.ctx.catalog.Items) do
  table.insert(catalog,{id=d.id,name=d.name,tier=d.tier,rarity=d.rarity,power=d.power})
 end
 local powers={};for _,d in ipairs(Powers.Items) do
  table.insert(powers,{id=d.id,name=d.name,rank=d.rank,price=d.price,cooldown=d.cooldown,description=d.description})
 end
 return {catalog=catalog,powers=powers,mods=self:getState(p)}
end
function S:reply(p,data)
 data.authorized=self:authorized(p)==true
 if data.authorized then
  data.mods=self:getState(p)
  data.flight=data.mods.flight;data.noclip=data.mods.noclip
 end
 return data
end
function S:resetTravel(p)
 local rt=self.ctx.runtime[p.UserId]; local root=self.ctx.body(p)
 if rt and root then
  root.AssemblyLinearVelocity=Vector3.zero
  rt.travelPosition=root.Position;rt.travelTime=self.clock();rt.travelCredit=5;rt.safeCF=root.CFrame;rt.blockedUntil=0;rt.impulseUntil=0
 end
end
function S:setMobility(p,kind,enabled)
 if not self:authorized(p) then return false,'Access denied.' end
 local root,h=self.ctx.body(p)
 if enabled then
  local ready,err=self:readyForMods(p);if not ready then return false,err end
 end
 local m=self.mobility[p.UserId] or {player=p,parts={}}
 self.mobility[p.UserId]=m
 if enabled then m=self:captureMovement(p,h) end
 if kind=='flight' then
  if m.velocity then m.velocity:Destroy();m.velocity=nil end
  if m.attachment then m.attachment:Destroy();m.attachment=nil end
  if m.humanoid and m.humanoid.Parent then m.humanoid.PlatformStand=m.oldPlatform;m.humanoid.AutoRotate=m.oldRotate end
  m.humanoid=nil;m.flight=enabled
  if enabled then
   m.humanoid=h;m.oldPlatform=h.PlatformStand;m.oldRotate=h.AutoRotate;h.PlatformStand=true;h.AutoRotate=false
   local a=Instance.new('Attachment');a.Name='DeveloperFlightAttachment';a.Parent=root;m.attachment=a
   local v=Instance.new('LinearVelocity');v.Name='DeveloperFlight';v.Attachment0=a;v.RelativeTo=Enum.ActuatorRelativeTo.World
   v.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector;v.ForceLimitsEnabled=false;v.VectorVelocity=Vector3.zero;v.Parent=root;m.velocity=v
   m.flightRoot=root;setOwnership(root,true)
  else
   setOwnership(m.flightRoot or root,false);m.flightRoot=nil
  end
 else
  m.noclip=enabled
  if not enabled then for part,original in pairs(m.parts) do if part.Parent then part.CanCollide=original end end;m.parts={} end
 end
 self:resetTravel(p)
 return true,kind..' '..(enabled and 'enabled.' or 'disabled.')
end
function S:resetCharacter(p)
 local m=self.mobility[p.UserId]
 local rt=self.ctx.runtime[p.UserId];local root,currentHumanoid=self.ctx.body(p)
 if m then
  if m.velocity then m.velocity:Destroy() end;if m.attachment then m.attachment:Destroy() end
  if m.humanoid and m.humanoid.Parent then m.humanoid.PlatformStand=m.oldPlatform;m.humanoid.AutoRotate=m.oldRotate end
  for part,original in pairs(m.parts) do if part.Parent then part.CanCollide=original end end
  if m.moveHumanoid and m.moveHumanoid.Parent and m.originalMovement then
   for property,value in pairs(m.originalMovement) do m.moveHumanoid[property]=value end
  end
  if m.originalMovement and rt and rt.originalJump~=nil then
   if currentHumanoid==m.moveHumanoid and currentHumanoid and currentHumanoid.Parent and self.clock()<(rt.shockUntil or 0) then
    -- The server will restore jump after this stun. Restore the underlying
    -- normal value then, rather than resurrecting a removed jump override.
    rt.originalJump=m.originalMovement.JumpPower
    currentHumanoid.JumpPower=0;currentHumanoid.WalkSpeed=0
   else
    -- Expired stun, death, or a new character: no deferred old override.
    rt.originalJump=nil
   end
  end
  setOwnership(m.flightRoot,false)
 end
 self.mobility[p.UserId]=nil;self.input[p.UserId]=nil
 setOwnership(root,false)
 self:resetTravel(p)
 if m and self.response and p.Parent then self.response:FireClient(p,self:reply(p,{ok=true,message='Developer movement mods reset.'})) end
end
function S:allowsMovement(p)
 local m=self.mobility[p.UserId]
 return self:modsActive(p) and m~=nil and (m.flight or m.noclip)
end
function S:teleportPlayer(player,pos)
 local rt=self.ctx.runtime[player.UserId];local state=self.ctx.core.players[player.UserId]
 local root=rt and self.ctx.body(player)
 if not root or not player.Character then return false,'Character unavailable.' end
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude
 overlap.FilterDescendantsInstances={player.Character};overlap.RespectCanCollide=true
 if #workspace:GetPartBoundsInBox(CFrame.new(pos),Vector3.new(3,5,3),overlap)>0 then return false,'Destination intersects solid geometry.' end
 if state and state.pending then self.ctx.core:withdraw(player.UserId,self.clock()) end
 if state and state.carry then self.ctx.finish(player,false,'Developer teleport returned carried loot.') end
 player.Character:PivotTo(CFrame.new(pos));self:resetTravel(player);return true,'Teleported.'
end
function S:execute(actor,c)
 local core=self.ctx.core;local p=c.target and core.players[c.target]
 local name=c.name
 if name=='help' then local data=self:menuData(actor);data.commands=specs;return true,data
 elseif name=='resetmods' then self:resetCharacter(actor);return true,'Developer movement mods reset.'
 elseif name=='god' then
  if not c.enabled then local m=self.mobility[actor.UserId];if m then m.god=false end;return true,'Power immunity disabled.' end
  local ready,root,h=self:readyForMods(actor);if not ready then return false,root end
  local m=self:captureMovement(actor,h);m.god=true
  return true,'Power immunity enabled. World hazards and respawn still apply.'
 elseif name=='speed' or name=='jump' then
  local ready,root,h=self:readyForMods(actor);if not ready then return false,root end
  local m=self:captureMovement(actor,h);m[name]=c.value;self:applyMovement(actor,h);self:resetTravel(actor)
  return true,(name=='speed' and 'Walk speed' or 'Jump power')..' set to '..c.value..'.'
 elseif name=='heal' or name=='powers' or name=='cooldowns' or name=='cast' or name=='home' then
  local ready,root,h=self:readyForMods(actor);if not ready then return false,root end
  local state=core.players[actor.UserId]
  if name=='heal' then h.Health=h.MaxHealth;return true,'Healed.'
  elseif name=='powers' then
   core:migratePowers(actor.UserId)
   for _,d in ipairs(Powers.Items) do state.powerOwned[d.id]=true end
   state.powerSlots=3;state.starterChosen=true;state.loadout[1]='tag'
   local used={};for _,kind in pairs(state.loadout) do used[kind]=true end
   for slot=2,3 do if not state.loadout[slot] then
    for _,kind in ipairs({'dash','shield','lightning','gravity','slow','slam','repulse'}) do
     if not used[kind] then state.loadout[slot]=kind;used[kind]=true;break end
    end
   end end
   core:changed();self.ctx.refresh();return true,'All eight powers unlocked. Tag stays fixed; three slots available.'
  elseif name=='cooldowns' then
   state.powerReady={};state.castReady=0;core:changed();self.ctx.refresh();return true,'Power cooldowns cleared.'
  elseif name=='cast' then
   if type(self.ctx.castPower)~='function' then return false,'Power casting unavailable.' end
   core:migratePowers(actor.UserId)
   if not state.powerOwned[c.kind] then return false,'Unlock the power first with powers or the power shop.' end
   local equipped=false;for _,kind in pairs(state.loadout) do if kind==c.kind then equipped=true end end
   if not equipped then
    local ok,msg=core:loadPower(actor.UserId,c.kind,2);if not ok then return false,msg end
   end
   local ok,msg=self.ctx.castPower(actor,c.kind)
   return ok,ok and ('Cast '..Powers.ById[c.kind].name..'.') or msg
  else
   local rt=self.ctx.runtime[actor.UserId]
   if not rt or not rt.base or not rt.base.spawn then return false,'Your base is unavailable.' end
   return self:teleportPlayer(actor,rt.base.spawn.Position)
  end
 elseif name=='state' then
  local offers=0;for _ in pairs(core.offers) do offers+=1 end
  local players={};for id,state in pairs(core.players) do players[#players+1]={userId=id,cash=state.cash,bank=state.bank,capacity=state.capacity,carry=state.carry} end
  local bans={};for id in pairs(self.bans) do table.insert(bans,id) end
  local data=self:menuData(actor)
  data.players=players;data.offers=offers;data.catalogItems=#self.ctx.catalog.Items;data.sessionBans=bans;data.revision=core.revision
  return true,data
 elseif name=='logs' then
  local out={};for i=math.max(1,#self.policy.logs-c.count+1),#self.policy.logs do table.insert(out,self.policy.logs[i]) end
  return true,out
 elseif name=='inventory' then return true,core:snapshot(c.target,self.clock())
 elseif name=='offer' then
  local ok=self.ctx.spawnOffer(c.kind);return ok,ok and 'Offer spawned.' or 'Conveyor is full.'
 elseif name=='cash' then
  if not p then return false,'Player left.' end
  if c.operation=='add' then p.cash=math.min(self.config.MaxCurrency-(p.held or 0),p.cash+c.amount)
  elseif c.operation=='remove' then p.cash=math.max(0,p.cash-c.amount) else p.cash=math.min(self.config.MaxCurrency-(p.held or 0),c.amount) end
  core:changed();self.ctx.refresh();return true,'Cash is now '..p.cash
 elseif name=='grant' then
  if not p or p.carry or p.pending then return false,'Player left, is carrying or is bidding.' end
  local free=0;for slot=1,p.capacity do if not p.slots[slot] then free+=1 end end
  if free<c.quantity then return false,'Not enough unreserved slots. No items granted.' end
  local granted={};for _=1,c.quantity do table.insert(granted,assert(core:grant(c.target,c.kind))) end
  self.ctx.refresh();return true,{granted=granted}
 elseif name=='remove' then
  local it=core.items[c.uid]
  if not p or not it or it.owner~=c.target or it.carrier then return false,'Owned item missing or in transit.' end
  p.slots[it.slot]=nil;if p.equipped==c.uid then p.equipped=nil end;core.items[c.uid]=nil
  core:changed();self.ctx.refresh();return true,'Item removed without sell proceeds.'
 elseif name=='teleport' then
  local rt=self.ctx.runtime[c.target];local root=rt and self.ctx.body(rt.player)
  if not root then return false,'Character unavailable.' end
  local pos=Vector3.new(c.x,c.y,c.z)
  return self:teleportPlayer(rt.player,pos)
 elseif name=='flight' or name=='noclip' then return self:setMobility(actor,name,c.enabled)
 elseif name=='protect' then
  if not p then return false,'Player left.' end
  p.lockUntil=self.clock()+c.seconds;core:changed();self.ctx.refresh();return true,'Protection set to '..c.seconds..' seconds.'
 elseif name=='announce' then
  local filtered=TextService:FilterStringAsync(c.text,actor.UserId):GetNonChatStringForBroadcastAsync()
  if not self:authorized(actor) then return false,'Access revoked.' end
  for _,rt in pairs(self.ctx.runtime) do self.ctx.say(rt.player,'DEVELOPER: '..filtered) end
  return true,'Announcement sent.'
 elseif name=='kick' or name=='ban' then
  if c.target==actor.UserId then return false,'Self kick/ban is disabled.' end
  if name=='ban' then self.bans[c.target]={actor=actor.UserId,reason=c.reason,time=self.clock()} end
  local rt=self.ctx.runtime[c.target]
  if rt then rt.player:Kick(name=='ban' and 'Removed by developer. This server session is restricted.' or 'Removed by developer.') end
  return true,name=='ban' and 'Banned for this server lifetime.' or 'Player kicked.'
 elseif name=='unban' then self.bans[c.target]=nil;return true,'Session ban removed.' end
 return false,'Unknown command.'
end
function S:dispatch(actor,payload)
 if not self:authorized(actor) then
  local now=self.clock();local last=self.deniedAt[actor.UserId]
  if last and now-last<2 then return nil end
  self.deniedAt[actor.UserId]=now
  self.policy:record(actor.UserId,'[unauthorized request]','Access denied.')
  return {ok=false,message='Access denied.',authorized=false}
 end
 if type(payload)~='table' then return self:reply(actor,{ok=false,message='Malformed request.'}) end
 if payload.mode=='move' then
  local now=self.clock();local previous=self.input[actor.UserId]
  if previous and now-previous.time<self.config.InputInterval then return nil end
  local d=payload.direction
  if typeof(d)~='Vector3' or d.X~=d.X or d.Y~=d.Y or d.Z~=d.Z or math.abs(d.X)>1 or math.abs(d.Y)>1 or math.abs(d.Z)>1 or d.Magnitude>1.01 then return nil end
  if not self.mobility[actor.UserId] or not self.mobility[actor.UserId].flight then return nil end
  self.input[actor.UserId]={time=now,direction=d};return nil
 end
 if self.busy[actor.UserId] then return self:reply(actor,{ok=false,message='Previous command is still running.'}) end
 if payload.mode=='hello' then
  local ok,msg=self.policy:prepare(actor.UserId,'hello',false,nil)
  return self:reply(actor,{ok=ok,message=ok and 'Developer menu ready. Use help for commands.' or msg,data=ok and self:menuData(actor) or nil})
 end
 if payload.mode~='command' then return self:reply(actor,{ok=false,message='Unknown request.'}) end
 -- Authorize and rate-limit before expensive or stateful command parsing.
 local allowed,why=self.policy:prepare(actor.UserId,'request',false,nil)
 if not allowed then return self:reply(actor,{ok=false,message=why}) end
 local c,err=self:parse(actor,payload.text)
 if not c then self.policy:record(actor.UserId,tostring(payload.text),err);return self:reply(actor,{ok=false,message=err}) end
 -- The request has already spent its token; confirmation checks use the same budget.
 self.policy.buckets[actor.UserId].tokens=math.min(self.config.CommandBurst,self.policy.buckets[actor.UserId].tokens+1)
 local ok,msg,token=self.policy:prepare(actor.UserId,c.raw,c.destructive,payload.confirmation)
 if not ok then self.policy:record(actor.UserId,c.raw,msg);return self:reply(actor,{ok=false,message=msg,confirmation=token,command=token and c.raw or nil}) end
 self.busy[actor.UserId]=true
 local success,executed,data=pcall(self.execute,self,actor,c)
 self.busy[actor.UserId]=nil
 if not success then executed=false;data='Command failed safely; inspect server output.';warn('Admin command error: '..tostring(c.name)) end
 self.policy:record(actor.UserId,c.raw,executed and 'OK' or tostring(data))
 return self:reply(actor,{ok=executed,message=type(data)=='string' and data or nil,data=type(data)=='table' and data or nil})
end
function S:tick()
 for id,m in pairs(self.mobility) do
  local root=self.ctx.body(m.player)
  if not self:modsActive(m.player) or not root then self:resetCharacter(m.player)
  else
   local _,h=self.ctx.body(m.player);self:applyMovement(m.player,h)
   if m.flight and m.velocity then
    local input=self.input[id];local d=input and self.clock()-input.time<.35 and input.direction or Vector3.zero
    m.velocity.VectorVelocity=d*self.config.FlightSpeed
    local pos=root.Position
    if math.abs(pos.X)>122 or math.abs(pos.Z)>90 or pos.Y<3 or pos.Y>120 then
     root.CFrame=CFrame.new(math.clamp(pos.X,-122,122),math.clamp(pos.Y,3,120),math.clamp(pos.Z,-90,90));m.velocity.VectorVelocity=Vector3.zero
    end
   end
  end
 end
end
function S:applyNoclip()
 for _,m in pairs(self.mobility) do
  if m.noclip and self:modsActive(m.player) and m.player.Character then
   for _,part in m.player.Character:GetDescendants() do if part:IsA('BasePart') then
    if m.parts[part]==nil then m.parts[part]=part.CanCollide end;part.CanCollide=false
   end end
  end
 end
end
function S:admit(p)
 if self.bans[p.UserId] then p:Kick('This server session is restricted.');return false end
 return true
end
function S:onJoin(p)
 if not self:authorized(p) then return end
 if not self.chat[p.UserId] then
  self.chat[p.UserId]=p.Chatted:Connect(function(message)
   if string.sub(message,1,4)~='!op ' then return end
   local text=string.sub(message,5)
   local token=string.match(text,'^confirm%s+([%w%-]+)$')
   local pending=token and self.policy.pending[p.UserId]
   local reply=self:dispatch(p,{mode='command',text=pending and pending.command or text,confirmation=token})
   if reply and p.Parent then
    if self.response then self.response:FireClient(p,reply) end
    self.ctx.say(p,reply.message or 'Developer command completed. Inspect the console for details.')
   end
  end)
 end
 task.spawn(function()
  local pg=p:WaitForChild('PlayerGui',10)
  if not pg or not p.Parent or not self:authorized(p) or pg:FindFirstChild('OPDeveloperConsole') then return end
  local gui=Instance.new('ScreenGui');gui.Name='OPDeveloperConsole';gui.ResetOnSpawn=false;gui.DisplayOrder=50;gui.Parent=pg
  local client=script.Parent.AdminClient:Clone();client.Enabled=false;client.Parent=gui;client.Enabled=true
 end)
end
function S:removePlayer(p)
 self:resetCharacter(p);self.policy:forget(p.UserId);self.busy[p.UserId]=nil;self.deniedAt[p.UserId]=nil
 if self.chat[p.UserId] then self.chat[p.UserId]:Disconnect();self.chat[p.UserId]=nil end
end
function S.attach(config,ctx)
 local self=S.new(config,ctx)
 local request=Instance.new('RemoteEvent');request.Name='AdminRequest';request.Parent=ctx.net
 local response=Instance.new('RemoteEvent');response.Name='AdminResponse';response.Parent=ctx.net
 self.request=request;self.response=response
 request.OnServerEvent:Connect(function(p,payload)
  local reply=self:dispatch(p,payload)
  if reply and p.Parent then response:FireClient(p,reply) end
 end)
 local acc=0;Run.Heartbeat:Connect(function(dt) acc+=dt;if acc>=.05 then acc=0;self:tick() end end)
 Run.PreSimulation:Connect(function() self:applyNoclip() end)
 return self
end
return S

