local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Debris=game:GetService('Debris')
local Tween=game:GetService('TweenService')
local Rules=require(script.Parent.PhaseConfig)
local Powers=require(script.Parent.PowerCatalog)
local ItemPresentation=require(script.Parent.ItemPresentation)
local BaseEntrance=require(script.Parent.BaseEntrance)
local HitRules=require(script.Parent.PowerRules)
local S={};S.__index=S
local function finite(n) return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge end
function S.new(ctx)
 local self=setmetatable({ctx=ctx,core=ctx.core,models={},markers={},holds={},holdRate={},visitors={},auctionAlerts={},fields={},offerSeq=0,nextSpawn=os.clock()+ctx.config.ConveyorInterval,acc=0,second=0},S)
 self.connection=Run.Heartbeat:Connect(function(dt) self.acc+=dt;if self.acc>=.05 then local elapsed=self.acc;self.acc=0;self:step(elapsed) end end)
 return self
end
function S:destroy()
 if self.connection then self.connection:Disconnect() end
 for _,v in pairs(self.models) do v.model:Destroy() end
 for _,m in pairs(self.markers) do if m then m:Destroy() end end
 for _,rt in pairs(self.ctx.runtime) do if rt.shockRoot and rt.shockRoot.Parent then rt.shockRoot.Anchored=rt.shockAnchored;rt.shockRoot=nil end end
 self.models={};self.markers={};self.holds={}
end
function S:spawn(kind)
 local count=0;for _ in pairs(self.core.offers) do count+=1 end
 if count>=self.ctx.config.ConveyorMaxOffers or (kind and not self.ctx.catalog.ById[kind]) then return false end
 self.offerSeq+=1
 self.core:setOffer('conveyor'..self.offerSeq,kind or self.ctx.catalog.roll(self.ctx.rng),os.clock())
 self:syncVisuals();return true
end
function S:position(it)
 if it.state=='Stored' then local rt=self.ctx.runtime[it.owner];return rt and rt.base.slots[it.slot].Position end
 local o=it.offer and self.core.offers[it.offer]
 return o and Vector3.new(o.x,self.ctx.config.ConveyorY,0)
end
function S:canInteract(p,it,kind,token)
 local state=self.core.players[p.UserId];local rt=self.ctx.runtime[p.UserId];local r=self.ctx.body(p)
 if not state or not rt or not r or not r:IsDescendantOf(workspace) or state.carry or state.pending or os.clock()<(rt.interruptedUntil or 0) or os.clock()<(rt.shockUntil or 0) or not self.ctx.movementSafe(p) then return false end
 if kind=='buy' then
  local o=it and self.core.offers[it.offer]
  if not self.core:availableOffer(o,os.clock()) or o.token~=token or state.cash<self.ctx.catalog.ById[it.kind].price or not self.core:free(p.UserId) then return false end
 else
  local owner=it and self.core.players[it.owner]
  if not it or it.state~='Stored' or it.owner==p.UserId or not owner or os.clock()<owner.lockUntil or not self.core:free(p.UserId) then return false end
 end
 local pos=self:position(it)
 return pos and (r.Position-pos).Magnitude<=Rules.HoldRange and self.ctx.los(r.Position,pos)
end
function S:beginHold(p,uid,kind,prompt)
 local now=os.clock();if now<(self.holdRate[p.UserId] or 0) then return end;self.holdRate[p.UserId]=now+.2
 local it=self.core.items[uid];local o=it and it.offer and self.core.offers[it.offer];local token=o and o.token
 if not prompt.Enabled or not self:canInteract(p,it,kind,token) then return end
 self.holds[p.UserId]={uid=uid,kind=kind,token=token,start=now,prompt=prompt}
end
function S:endHold(p,prompt)
 local h=self.holds[p.UserId]
 if h and h.prompt==prompt then
  if os.clock()-h.start<Rules.HoldSeconds-Rules.HoldJitter then self.holds[p.UserId]=nil else h.released=os.clock() end
 end
end
function S:completeHold(p,prompt)
 local h=self.holds[p.UserId]
 if not h or h.prompt~=prompt or not prompt.Enabled then return end
 local elapsed=os.clock()-h.start
 if elapsed<Rules.HoldSeconds then
  if elapsed>=Rules.HoldSeconds-Rules.HoldJitter and not h.triggerQueued then
   h.triggerQueued=true
   task.delay(Rules.HoldSeconds-elapsed+.01,function()if self.holds[p.UserId]==h then self:completeHold(p,prompt)end end)
  elseif elapsed<Rules.HoldSeconds-Rules.HoldJitter then self.holds[p.UserId]=nil end
  return
 end
 self.holds[p.UserId]=nil
 local it=self.core.items[h.uid]
 if not self:canInteract(p,it,h.kind,h.token) then return end
 local ok,msg
 if h.kind=='buy' then ok,msg=self.core:purchaseAttempt(p.UserId,it.offer,h.token,os.clock())
 else ok,msg=self.core:beginSteal(p.UserId,h.uid,os.clock()) end
 if msg then self.ctx.say(p,msg) end
 if ok then self.ctx.refresh() end
end
function S:makePrompt(root,uid)
 local q=Instance.new('ProximityPrompt');q.KeyboardKeyCode=Enum.KeyCode.E;q.GamepadKeyCode=Enum.KeyCode.ButtonX
 q.HoldDuration=Rules.HoldSeconds;q.MaxActivationDistance=Rules.HoldRange;q.RequiresLineOfSight=true;q.Parent=root
 q.PromptButtonHoldBegan:Connect(function(p) local it=self.core.items[uid];if it then self:beginHold(p,uid,it.state=='Stored' and 'steal' or 'buy',q) end end)
 q.PromptButtonHoldEnded:Connect(function(p)self:endHold(p,q)end)
 q.Triggered:Connect(function(p)self:completeHold(p,q)end)
 return q
end
function S:marker(tx,now)
 local x=tx.pickupX-self.ctx.config.ConveyorSpeed*(now-tx.started)
 if x<=self.ctx.config.ConveyorEndX then if self.markers[tx.id] then self.markers[tx.id]:Destroy() end;self.markers[tx.id]=false;return end
 if self.markers[tx.id]==false then return end
 local model=self.markers[tx.id]
 if not model then
  local it=self.core.items[tx.uid];if not it then return end
  model=self.ctx.templates[it.kind]:Clone();model.Name='InTransitSilhouette';model:SetAttribute('TransitMarker',true)
  for _,part in model:GetDescendants() do if part:IsA('BasePart') then part.Transparency=.94;part.Color=Color3.fromRGB(153,179,222);part.CanCollide=false;part.CanTouch=false;part.CanQuery=false end end
  local highlight=Instance.new('Highlight');highlight.FillTransparency=.93;highlight.OutlineTransparency=.55;highlight.OutlineColor=Color3.fromRGB(174,196,231);highlight.Parent=model
  model.Parent=self.ctx.world.folder;self.markers[tx.id]=model
 end
 if not model:GetAttribute('ConveyorBorn') then model:SetAttribute('ConveyorBorn',workspace:GetServerTimeNow()-(self.ctx.config.ConveyorStartX-x)/self.ctx.config.ConveyorSpeed) end
 model:SetAttribute('ConveyorStartX',self.ctx.config.ConveyorStartX);model:SetAttribute('ConveyorEndX',self.ctx.config.ConveyorEndX)
 model:SetAttribute('ConveyorSpeed',self.ctx.config.ConveyorSpeed);model:SetAttribute('ConveyorY',self.ctx.config.ConveyorY)
 model:PivotTo(CFrame.new(x,self.ctx.config.ConveyorY,0))
end
function S:syncVisuals()
 local now=os.clock()
 for uid,v in pairs(self.models) do if not self.core.items[uid] then v.model:Destroy();self.models[uid]=nil end end
 for uid,it in pairs(self.core.items) do
  local v=self.models[uid];local d=self.ctx.catalog.ById[it.kind]
  if not v then
   local model=self.ctx.templates[it.kind]:Clone();model:SetAttribute('ItemUID',uid);model.Parent=self.ctx.world.folder
   v={model=model,label=self.ctx.world.label(model.PrimaryPart,''),prompt=self:makePrompt(model.PrimaryPart,uid)};self.models[uid]=v
  end
  local carried=it.state=='PurchaseCarry' or it.state=='TheftCarry'
  local carrier=carried and it.carrier or nil
  v.model:SetAttribute('Carried',carried);v.model:SetAttribute('ItemState',it.state)
  -- Clients follow the live carrier every rendered frame. These attributes are
  -- presentation only; the server still validates the player's real position.
  v.model:SetAttribute('CarrierUserId',carrier)
  v.model:SetAttribute('CarryVisualOffset',carried and Rules.CarryVisualOffset or nil)
  local o=it.offer and self.core.offers[it.offer]
  local changed=v.state~=it.state or v.carrier~=carrier or (o and v.token~=o.token)
  if changed then v.model:SetAttribute('ConveyorBorn',nil);v.model:SetAttribute('DisplayCF',nil) end
  v.prompt.Enabled=false
  if carried then
   local rt=self.ctx.runtime[it.carrier];local r=rt and self.ctx.body(rt.player)
   if r and (changed or now-(v.lastCarrySnapshot or -math.huge)>=Rules.CarryServerInterval) then
    v.model:PivotTo(CFrame.new(r.Position+Vector3.new(0,Rules.CarryVisualOffset,0)))
    v.lastCarrySnapshot=now
   end
   if v.state~=it.state and rt then rt.shield=0;rt.shieldHits=0;rt.player:SetAttribute('OPShieldUntil',nil);rt.castSerial=(rt.castSerial or 0)+1 end
   v.label.Text=d.name..'\nIN TRANSIT • DELIVER HOME'
   local tx=self.core.transactions[it.tx];if it.state=='PurchaseCarry' and tx then self:marker(tx,now) end
  else
   local pos=self:position(it)
   if pos then
    local cf=CFrame.new(pos)
    if it.state~='Stored' or changed or v.model:GetAttribute('DisplayCF')~=cf then v.model:PivotTo(cf) end
    if it.state=='Stored' then
     v.model:SetAttribute('DisplayCF',cf);v.prompt.Enabled=true;v.prompt.ActionText='Steal'
     v.label.Text=d.name..' ['..d.rarity..']\n+$'..d.income..'/s'
    else
     local o=self.core.offers[it.offer]
     v.prompt.Enabled=self.core:availableOffer(o,now);v.prompt.ActionText='Buy'
     v.label.Text=d.name..'\n$'..d.price..(it.state=='Auction' and ' • BUY BATTLE' or '')
     if o and o.state=='Conveyor' and changed then
      v.model:SetAttribute('ConveyorBorn',workspace:GetServerTimeNow()-(self.ctx.config.ConveyorStartX-o.x)/self.ctx.config.ConveyorSpeed)
      v.model:SetAttribute('ConveyorStartX',self.ctx.config.ConveyorStartX);v.model:SetAttribute('ConveyorEndX',self.ctx.config.ConveyorEndX)
      v.model:SetAttribute('ConveyorSpeed',self.ctx.config.ConveyorSpeed);v.model:SetAttribute('ConveyorY',self.ctx.config.ConveyorY)
     end
    end
   end
   v.lastCarrySnapshot=nil
  end
  if not v.presented then ItemPresentation.update(v.model,v.label,d,self.ctx.catalog);v.presented=true end
  v.state=it.state;v.token=o and o.token;v.carrier=carrier
 end
 for txid,model in pairs(self.markers) do
  local tx=self.core.transactions[txid]
  if not tx or tx.resolved or tx.status~='Carrying' then if model then model:Destroy() end;self.markers[txid]=nil end
 end
end
function S:finish(p,success,reason)
 if self.core:finish(p.UserId,success,os.clock()) then
  local _,h=self.ctx.body(p);if h then h.WalkSpeed=self.ctx.config.WalkSpeed end
  self.ctx.say(p,reason or (success and 'Delivered to your vault.' or 'Delivery interrupted. Reservations released.'))
  self.ctx.refresh();return true
 end
 return false
end
function S:interrupt(p,drop)
 local rt=self.ctx.runtime[p.UserId];if not rt then return end
 rt.castSerial=(rt.castSerial or 0)+1;rt.interruptedUntil=os.clock()+.4;self.holds[p.UserId]=nil;self.core:withdraw(p.UserId,os.clock())
 if drop then self:finish(p,false,'Item knocked loose. Reservation refunded or loot returned.') end
 self.ctx.refresh()
end
function S:hitPower(casterId,target,key,origin,now)
 if self.ctx.isDeveloperInvulnerable and self.ctx.isDeveloperInvulnerable(target.player) then return false,'Developer ability immunity.' end
 local tr,th=self.ctx.body(target.player);if not tr then return end
 local d=Powers.ById[key]
 local gate=HitRules.hit(target,key,now,Rules.PowerImmunity)
 if gate=='shield' then
  self.ctx.fx:FireAllClients('shieldBreak',tr.Position,3,d.name,0,Color3.fromRGB(75,240,180),target.player.UserId)
  target.player:SetAttribute('OPShieldUntil',nil);return
 elseif gate~='hit' then return end
 self:interrupt(target.player,d.dislodge)
 if d.slow then target.slow=math.max(target.slow or 0,now+d.duration) end
 if d.stun then
  target.shockUntil=now+math.min(Rules.MaxStun,d.duration);tr.AssemblyLinearVelocity=Vector3.zero
  target.shockRoot=tr;target.shockAnchored=tr.Anchored;tr.Anchored=true
 end
 if d.force>0 then
  local delta=tr.Position-origin;local flat=Vector3.new(delta.X,0,delta.Z);local dir=flat.Magnitude>.01 and flat.Unit or Vector3.xAxis
  tr.AssemblyLinearVelocity=(d.pull and -dir or dir)*d.force+Vector3.new(0,7,0);target.impulseUntil=now+.8
 end
 self.ctx.fx:FireAllClients('hit',tr.Position,2,d.name,nil,Color3.fromRGB(table.unpack(d.warningColor)))
end
function S:cast(p,arg,visualOrigin)
 local rt=self.ctx.runtime[p.UserId];local r=self.ctx.body(p)
 if not rt or not r or not self.ctx.movementSafe(p) or os.clock()<(rt.shockUntil or 0) or os.clock()<(rt.interruptedUntil or 0) or not self.ctx.config.EnablePowers then return false,'Power unavailable while stunned or character is unavailable.' end
 local kind=type(arg)=='string' and arg or (type(arg)=='table' and arg.id or nil)
 if kind~=nil and (type(kind)~='string' or #kind>24) then return false,'Invalid power ID.' end
 local direction=r.CFrame.LookVector
 if type(arg)=='table' and arg.aim~=nil then
  local a=arg.aim;if typeof(a)~='Vector3' or not finite(a.X) or not finite(a.Y) or not finite(a.Z) or a.Magnitude<.1 or a.Magnitude>1.01 then return false,'Invalid aim direction.' end;direction=a.Unit
 end
 direction=Vector3.new(direction.X,0,direction.Z)
 direction=direction.Magnitude>.1 and direction.Unit or Vector3.new(0,0,-1)
 local now=os.clock();local ok,key=self.core:power(p.UserId,now,kind)
 if not ok then self.ctx.say(p,key);return false,key end
 local d=Powers.ById[key];local origin=r.Position
 -- Only server callbacks can supply this extra cosmetic origin; remote payloads cannot.
 if typeof(visualOrigin)~='Vector3' or not finite(visualOrigin.X) or not finite(visualOrigin.Y) or not finite(visualOrigin.Z) or (visualOrigin-origin).Magnitude>12 then visualOrigin=nil end
 rt.castSerial=(rt.castSerial or 0)+1;local serial=rt.castSerial
 local color=Color3.fromRGB(table.unpack(d.warningColor))
 if d.dash then
  -- Repeated swept character volumes stop at solid geometry even during the burst.
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
  local exclude={};for _,other in ipairs(Players:GetPlayers()) do if other.Character then table.insert(exclude,other.Character) end end
  params.FilterDescendantsInstances=exclude
  rt.impulseUntil=now+.8
  self.ctx.fx:FireAllClients('dash',origin,8,d.name,nil,color,p.UserId,d.duration,direction,visualOrigin)
  task.spawn(function()
   local elapsed=0;while elapsed<d.duration and r.Parent and rt.castSerial==serial do
    local state=self.core.players[p.UserId];if not state or state.carry or os.clock()<(rt.shockUntil or 0) then break end
    local dt=math.min(Run.Heartbeat:Wait(),.05);local distance=40*dt
    local obstruction=workspace:Blockcast(r.CFrame,Vector3.new(2.7,4,2.7),direction*(distance+.2),params)
    if obstruction then distance=math.max(0,obstruction.Distance-.2) end
    if distance>0 then r.CFrame=r.CFrame+direction*distance end
    r.AssemblyLinearVelocity=Vector3.new(0,r.AssemblyLinearVelocity.Y,0)
    elapsed+=dt;if obstruction then break end
   end
  end)
  self.ctx.refresh();return true,key
 end
 if key=='shield' then
  rt.shield=now+d.duration;rt.shieldHits=1;p:SetAttribute('OPShieldUntil',workspace:GetServerTimeNow()+d.duration)
  self.ctx.fx:FireAllClients('shield',origin,3,d.name,nil,color,p.UserId,d.duration,nil,visualOrigin)
  self.ctx.refresh();return true,key
 end
 local center=d.target=='field' and origin+direction*d.range*.65 or origin
 self.ctx.fx:FireAllClients(key,center,math.max(2,d.radius>0 and d.radius or d.range),d.name,d.windup,color,p.UserId,d.duration,direction,visualOrigin)
 task.delay(d.windup,function()
  local state=self.core.players[p.UserId];local current=self.ctx.body(p)
  if self.ctx.runtime[p.UserId]~=rt or rt.castSerial~=serial or not state or state.carry or state.pending or not current or (current.Position-origin).Magnitude>7 or os.clock()<(rt.shockUntil or 0) then return end
  local now=os.clock()
  if key=='slow' then
   table.insert(self.fields,{caster=p.UserId,origin=center,source=origin,expires=now+d.duration,hit={}})
  else
   for id,target in pairs(self.ctx.runtime) do
    local tr=self.ctx.body(target.player)
    if id~=p.UserId and tr then
     local delta=tr.Position-origin;local hit=delta.Magnitude<=d.range
     if d.target=='cone' then hit=hit and (delta.Magnitude<.01 or delta.Unit:Dot(direction)>=d.cone)
     elseif d.target=='field' then hit=hit and (tr.Position-center).Magnitude<=d.radius end
     if hit and self.ctx.los(origin,tr.Position) then self:hitPower(p.UserId,target,key,origin,now) end
    end
   end
  end
  self.ctx.fx:FireAllClients(key,center,math.max(2,d.radius),d.name,nil,color,p.UserId,d.duration,direction,visualOrigin)
 end)
 self.ctx.refresh();return true,key
end
function S:battles(p)
 local r=self.ctx.body(p);if not r then return {} end;local out={}
 for id,o in pairs(self.core.offers) do if o.state=='Auction' and (r.Position-Vector3.new(o.x,2.5,0)).Magnitude<22 then
  local leader=self.core:leader(o)
  out[#out+1]={id=id,name=self.ctx.catalog.ById[o.kind].name,price=leader and leader.amount or self.ctx.catalog.ById[o.kind].price,minimum=(leader and leader.amount or self.ctx.catalog.ById[o.kind].price)+math.max(Rules.MinimumBid,math.ceil(self.ctx.catalog.ById[o.kind].price*Rules.BidFraction)),ends=workspace:GetServerTimeNow()+math.max(0,o.endAt-os.clock()),joined=o.bids[p.UserId]~=nil,x=o.x}
 end end
 table.sort(out,function(a,b)return a.id<b.id end);return out
end
function S:celebrate(eventName)
 for i=1,14 do
  local part=Instance.new('Part');part.Name=(eventName or 'Exodia')..'Comet';part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
  part.Size=Vector3.new(.5,.5,8);part.Material=Enum.Material.Neon;part.Color=Color3.fromHSV(i/14,.65,1)
  local a=Instance.new('Attachment');a.Position=Vector3.new(0,0,-4);a.Parent=part
  local b=Instance.new('Attachment');b.Position=Vector3.new(0,0,4);b.Parent=part
  local trail=Instance.new('Trail');trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=.65;trail.Color=ColorSequence.new(part.Color);trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,1)});trail.Parent=part
  part.CFrame=CFrame.lookAt(Vector3.new(-100+i*14,55+(i%3)*7,-50),Vector3.new(0,35,25));part.Parent=self.ctx.world.folder
  Tween:Create(part,TweenInfo.new(1.8),{CFrame=part.CFrame+Vector3.new(-20,-17,80),Transparency=1}):Play();Debris:AddItem(part,2)
 end
end
function S:handle(p,verb,arg)
 local verbs={bid=true,withdraw=true,starter=true,buyPower=true,loadPower=true,powerSlot=true,exodia=true}
 if not verbs[verb] then return false end
 local ok,msg=false,'Invalid request.';local state=self.core.players[p.UserId];local r=self.ctx.body(p);local now=os.clock()
 if not state or not r then return true end
 if verb=='bid' and type(arg)=='table' and type(arg.offer)=='string' and #arg.offer<40 then
  local o=self.core.offers[arg.offer]
  if o and (r.Position-Vector3.new(o.x,2.5,0)).Magnitude<=Rules.AuctionRange and self.ctx.los(r.Position,Vector3.new(o.x,2.5,0)) and now>=(self.ctx.runtime[p.UserId].interruptedUntil or 0) and now>=(self.ctx.runtime[p.UserId].shockUntil or 0) then ok,msg=self.core:bid(p.UserId,arg.offer,arg.amount,now) end
 elseif verb=='withdraw' then ok=self.core:withdraw(p.UserId,now);msg='Bid reservations released.'
 elseif verb=='starter' and type(arg)=='string' then ok,msg=self.core:chooseStarter(p.UserId,arg)
 elseif verb=='buyPower' and type(arg)=='string' then
  local rt=self.ctx.runtime[p.UserId]
  if (r.Position-rt.base.upgrade.Position).Magnitude<=12 or (r.Position-self.ctx.world.powerShop.Position).Magnitude<=12 then ok,msg=self.core:shopPower(p.UserId,arg) else msg='Use a power shop console.' end
 elseif verb=='loadPower' and type(arg)=='table' and type(arg.id)=='string' then ok,msg=self.core:loadPower(p.UserId,arg.id,arg.slot)
 elseif verb=='powerSlot' then
  local rt=self.ctx.runtime[p.UserId]
  if (r.Position-rt.base.upgrade.Position).Magnitude<=12 or (r.Position-self.ctx.world.powerShop.Position).Magnitude<=12 then ok,msg=self.core:unlockPowerSlot(p.UserId) else msg='Use a power shop console.' end
 elseif verb=='exodia' and type(arg)=='table' then
  ok,msg=self.core:claimExodia(p.UserId,arg.token,arg.choice,now)
  if ok then
   self:celebrate()
   if msg=='respawn' then
    self.holds={};self:syncVisuals()
    for _,rt in pairs(self.ctx.runtime) do task.spawn(function() if rt.player.Parent then local success=pcall(function()rt.player:LoadCharacterAsync()end);if not success then self.ctx.say(rt.player,'Respawn unavailable; your collection is safe.') end end end) end
   end
   msg=arg.choice=='level' and 'Progression level gained. Capacity stays eight.' or 'Safe respawn. Collections preserved.'
  end
 end
 self.ctx.say(p,msg);self.ctx.refresh();return true
end
function S:cancelPlayer(p)
 local rt=self.ctx.runtime[p.UserId]
 if rt then rt.castSerial=(rt.castSerial or 0)+1;rt.shield=0;rt.shieldHits=0;p:SetAttribute('OPShieldUntil',nil) end
 if rt and rt.shockRoot then if rt.shockRoot.Parent then rt.shockRoot.Anchored=rt.shockAnchored end;rt.shockRoot=nil;rt.shockUntil=0 end
 self.holds[p.UserId]=nil;self.holdRate[p.UserId]=nil;self.core:withdraw(p.UserId,os.clock());self:finish(p,false)
 for key,v in pairs(self.visitors) do if v.owner==p.UserId or v.visitor==p.UserId then self.visitors[key]=nil end end
end
function S:step(dt)
 local now=os.clock();self.core.now=now
 for i=#self.fields,1,-1 do
  local field=self.fields[i];local caster=self.core.players[field.caster]
  if now>=field.expires or not caster then table.remove(self.fields,i)
  else
   for id,target in pairs(self.ctx.runtime) do
    local tr=self.ctx.body(target.player)
    if id~=field.caster and tr and not field.hit[id] and (tr.Position-field.origin).Magnitude<=Powers.ById.slow.radius and self.ctx.los(field.origin,tr.Position) then
     field.hit[id]=true;self:hitPower(field.caster,target,'slow',field.origin,now)
     -- Remaining time belongs to the field, never extends indefinitely.
     if target.slow and target.slow>now then target.slow=math.min(target.slow,field.expires) end
    end
   end
  end
 end
 for id,h in pairs(self.holds) do
  local rt=self.ctx.runtime[id]
  if not rt or not h.prompt.Parent or (h.released and now-h.released>.3) or not self:canInteract(rt.player,self.core.items[h.uid],h.kind,h.token) then self.holds[id]=nil end
 end
 for id,p in pairs(self.core.players) do
  local rt=self.ctx.runtime[id];local r=rt and self.ctx.body(rt.player)
  if rt and rt.shockRoot and now>=(rt.shockUntil or 0) then if rt.shockRoot.Parent then rt.shockRoot.Anchored=rt.shockAnchored end;rt.shockRoot=nil end
  if p.pending then
   local tx=self.core.transactions[p.pending];local o=tx and self.core.offers[tx.offer]
   if not r or not o or (r.Position-Vector3.new(o.x,2.5,0)).Magnitude>Rules.AuctionRange or not self.ctx.los(r.Position,Vector3.new(o.x,2.5,0)) or not self.ctx.movementSafe(rt.player) or now<(rt.interruptedUntil or 0) then self.core:withdraw(id,now) end
  end
  if p.carry then
   local it=self.core.items[p.carry];local tx=it and self.core.transactions[it.tx]
   if not r or not tx or now-tx.started>Rules.DeliverySeconds or not self.ctx.movementSafe(rt.player) then self:finish(rt.player,false,'Delivery expired or interrupted.')
   else
    local owner=it.owner and self.ctx.runtime[it.owner];local defender=owner and self.ctx.body(owner.player)
    if it.state=='TheftCarry' and defender and (defender.Position-r.Position).Magnitude<5.5 and self.ctx.los(defender.Position,r.Position) then self:finish(rt.player,false,'Defender recovered their relic.')
    else
     if rt.base.owner==id and BaseEntrance.contains(rt.base.cf,r.Position,p.capacity>=16) then self:finish(rt.player,true) end
    end
   end
  end
  if rt then
   local atEntrance=r and rt.base.owner==id and BaseEntrance.contains(rt.base.cf,r.Position,p.capacity>=16) or false
   if atEntrance and not rt.atEntrance and self.ctx.movementSafe(rt.player) then
    local ok,msg=BaseEntrance.activate(self.core,id,rt.base.owner,now)
    if ok then self.ctx.say(rt.player,msg);self.ctx.refresh() end
   end
   rt.atEntrance=atEntrance
  end
 end
 self.core:advance(now)
 if now>=self.nextSpawn then self.nextSpawn=now+self.ctx.config.ConveyorInterval;self:spawn() end
 for id,o in pairs(self.core.offers) do if o.state=='Auction' and not self.auctionAlerts[id] then
  self.auctionAlerts[id]=true;for _,rt in pairs(self.ctx.runtime) do self.ctx.say(rt.player,'Buy Battle • conveyor X '..math.floor(o.x)) end
 elseif o.state~='Auction' then self.auctionAlerts[id]=nil end end
 self.second+=dt
 if self.second>=1 then
  self.second=0
  for _,base in ipairs(self.ctx.world.bases) do if base.owner then
   self.core:checkExodia(base.owner,now);self.core:checkInfinity(base.owner,now)
   local state=self.core.players[base.owner]
   if state and state.infinityCelebration then state.infinityCelebration=nil;self:celebrate('Infinity');local rt=self.ctx.runtime[base.owner];if rt then self.ctx.say(rt.player,'INFINITY COLLECTION • Five distinct stones deposited. +1 level!');self.ctx.refresh() end end
   for id,rt in pairs(self.ctx.runtime) do if id~=base.owner then
    local r=self.ctx.body(rt.player);local inside=false
    if r then local pos=base.cf:PointToObjectSpace(r.Position);inside=math.abs(pos.X)<23 and math.abs(pos.Z)<23 and pos.Y>0 and pos.Y<18 end
    local key=tostring(base.owner)..':'..id;local v=self.visitors[key] or {owner=base.owner,visitor=id,last=-math.huge,inside=false};self.visitors[key]=v
    if inside and not v.inside and now-v.last>=Rules.IntrusionCooldown then
     v.last=now;local owner=self.ctx.runtime[base.owner];if owner then self.ctx.say(owner.player,rt.player.DisplayName..' entered your vault.') end
    end
    v.inside=inside
   end end
  end end
 end
 self:syncVisuals()
end
return S

