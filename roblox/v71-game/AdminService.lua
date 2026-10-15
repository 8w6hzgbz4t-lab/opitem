local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local TextService=game:GetService('TextService')
local Policy=require(script.Parent.AdminPolicy)
local S={}; S.__index=S
local specs={
 help='help',state='state',logs='logs [count]',inventory='inventory <UserId|self>',
 cash='cash <UserId|self> <add|remove|set> <amount>',
 grant='grant <UserId|self> <itemID> [quantity]',remove='remove <UserId|self> <ownedRelicUID>',
 offer='offer <itemID>',teleport='teleport <UserId|self> <x> <y> <z>',
 flight='flight <on|off>',noclip='noclip <on|off>',protect='protect <UserId|self> <seconds>',
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
 local self=setmetatable({config=config,ctx=ctx,clock=clock,bans={},input={},mobility={},busy={},deniedAt={},chat={}},S)
 self.policy=Policy.new(config,clock,ctx.nonce or function() return Http:GenerateGUID(false) end)
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
 if name=='help' or name=='state' then if n~=1 then return nil,specs[name] end
 elseif name=='logs' then
  if n>2 then return nil,specs[name] end
  command.count=n==1 and 20 or number(words[2],1,self.config.MaxLogs,true)
  if not command.count then return nil,specs[name] end
 elseif name=='flight' or name=='noclip' then
  if n~=2 or (words[2]~='on' and words[2]~='off') then return nil,specs[name] end
  command.enabled=words[2]=='on';command.target=actor.UserId
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
function S:resetTravel(p)
 local rt=self.ctx.runtime[p.UserId]; local root=self.ctx.body(p)
 if rt and root then
  root.AssemblyLinearVelocity=Vector3.zero
  rt.travelPosition=root.Position;rt.travelTime=self.clock();rt.travelCredit=5;rt.safeCF=root.CFrame;rt.blockedUntil=0;rt.impulseUntil=0
 end
end
function S:setMobility(p,kind,enabled)
 if not self:authorized(p) then return false,'Access denied.' end
 local state=self.ctx.core.players[p.UserId]; local root,h=self.ctx.body(p)
 if enabled and (not state or state.carry or state.pending or not root or not root:IsDescendantOf(workspace)) then return false,'Respawn or deliver carried loot first.' end
 local m=self.mobility[p.UserId] or {player=p,parts={}}
 self.mobility[p.UserId]=m
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
   setOwnership(root,true)
  elseif root then setOwnership(root,false) end
 else
  m.noclip=enabled
  if not enabled then for part,original in pairs(m.parts) do if part.Parent then part.CanCollide=original end end;m.parts={} end
 end
 self:resetTravel(p)
 return true,kind..' '..(enabled and 'enabled.' or 'disabled.')
end
function S:resetCharacter(p)
 local m=self.mobility[p.UserId]
 if m then
  if m.velocity then m.velocity:Destroy() end;if m.attachment then m.attachment:Destroy() end
  if m.humanoid and m.humanoid.Parent then m.humanoid.PlatformStand=m.oldPlatform;m.humanoid.AutoRotate=m.oldRotate end
  for part,original in pairs(m.parts) do if part.Parent then part.CanCollide=original end end
 end
 self.mobility[p.UserId]=nil;self.input[p.UserId]=nil
 local root=self.ctx.body(p)
 setOwnership(root,false)
 self:resetTravel(p)
end
function S:allowsMovement(p)
 local m=self.mobility[p.UserId]
 return self:authorized(p) and m~=nil and (m.flight or m.noclip)
end
function S:execute(actor,c)
 local core=self.ctx.core;local p=c.target and core.players[c.target]
 local name=c.name
 if name=='help' then return true,specs
 elseif name=='state' then
  local offers=0;for _ in pairs(core.offers) do offers+=1 end
  local players={};for id,state in pairs(core.players) do players[#players+1]={userId=id,cash=state.cash,bank=state.bank,capacity=state.capacity,carry=state.carry} end
  local bans={};for id in pairs(self.bans) do table.insert(bans,id) end
  return true,{players=players,offers=offers,catalogItems=#self.ctx.catalog.Items,sessionBans=bans,revision=core.revision}
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
  -- Do not place a normal character inside solid geometry.
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude
  overlap.FilterDescendantsInstances={rt.player.Character};overlap.RespectCanCollide=true
  if #workspace:GetPartBoundsInBox(CFrame.new(pos),Vector3.new(3,5,3),overlap)>0 then return false,'Destination intersects solid geometry.' end
  if p and p.pending then core:withdraw(c.target,core.now) end
  if p and p.carry then self.ctx.finish(rt.player,false,'Developer teleport returned carried loot.') end
  rt.player.Character:PivotTo(CFrame.new(pos));self:resetTravel(rt.player);return true,'Teleported.'
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
  return {ok=false,message='Access denied.'}
 end
 if type(payload)~='table' then return {ok=false,message='Malformed request.'} end
 if payload.mode=='move' then
  local now=self.clock();local previous=self.input[actor.UserId]
  if previous and now-previous.time<self.config.InputInterval then return nil end
  local d=payload.direction
  if typeof(d)~='Vector3' or d.X~=d.X or d.Y~=d.Y or d.Z~=d.Z or math.abs(d.X)>1 or math.abs(d.Y)>1 or math.abs(d.Z)>1 or d.Magnitude>1.01 then return nil end
  if not self.mobility[actor.UserId] or not self.mobility[actor.UserId].flight then return nil end
  self.input[actor.UserId]={time=now,direction=d};return nil
 end
 if self.busy[actor.UserId] then return {ok=false,message='Previous command is still running.'} end
 if payload.mode=='hello' then
  local ok,msg=self.policy:prepare(actor.UserId,'hello',false,nil)
  return {ok=ok,message=ok and 'Developer console ready. Use help.' or msg,authorized=ok}
 end
 if payload.mode~='command' then return {ok=false,message='Unknown request.'} end
 -- Authorize and rate-limit before expensive or stateful command parsing.
 local allowed,why=self.policy:prepare(actor.UserId,'request',false,nil)
 if not allowed then return {ok=false,message=why} end
 local c,err=self:parse(actor,payload.text)
 if not c then self.policy:record(actor.UserId,tostring(payload.text),err);return {ok=false,message=err} end
 -- The request has already spent its token; confirmation checks use the same budget.
 self.policy.buckets[actor.UserId].tokens=math.min(self.config.CommandBurst,self.policy.buckets[actor.UserId].tokens+1)
 local ok,msg,token=self.policy:prepare(actor.UserId,c.raw,c.destructive,payload.confirmation)
 if not ok then self.policy:record(actor.UserId,c.raw,msg);return {ok=false,message=msg,confirmation=token,command=token and c.raw or nil} end
 self.busy[actor.UserId]=true
 local success,executed,data=pcall(self.execute,self,actor,c)
 self.busy[actor.UserId]=nil
 if not success then executed=false;data='Command failed safely; inspect server output.';warn('Admin command error: '..tostring(c.name)) end
 self.policy:record(actor.UserId,c.raw,executed and 'OK' or tostring(data))
 local mobility=self.mobility[actor.UserId]
 return {ok=executed,message=type(data)=='string' and data or nil,data=type(data)=='table' and data or nil,flight=mobility and mobility.flight or false,noclip=mobility and mobility.noclip or false}
end
function S:tick()
 for id,m in pairs(self.mobility) do
  local root=self.ctx.body(m.player)
  if not self:authorized(m.player) or not root then self:resetCharacter(m.player)
  else
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
  if m.noclip and self:authorized(m.player) and m.player.Character then
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

