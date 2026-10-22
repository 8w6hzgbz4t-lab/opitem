-- Owner-only base management. Durable Core methods own every item transition.
local V={};V.__index=V
local verbs={beginItemMove=true,cancelItemMove=true,moveItem=true}
local function uid(value)return type(value)=='string'and #value>0 and #value<=96 end
local function integer(value)return type(value)=='number'and value==value and math.abs(value)<math.huge and value%1==0 end
function V.new(ctx)
 return setmetatable({ctx=ctx,rate={},cancelRate={},clock=ctx.clock or os.clock},V)
end
function V:inside(p)
 local rt=self.ctx.runtime[p.UserId];local state=self.ctx.core.players[p.UserId]
 local root=self.ctx.body(p)
 if not rt or not state or rt.pendingReset or rt.base.owner~=p.UserId or not root or not self.ctx.movementSafe(p)then return false end
 local position=rt.base.cf:PointToObjectSpace(root.Position)
 if math.abs(position.X)>23 or math.abs(position.Z)>24 then return false end
 return position.Y>=.5 and position.Y<=12 or state.capacity>=16 and position.Y>=20 and position.Y<=31
end
function V:open(p)
 if self.ctx.core.closing or self.ctx.core.persistenceBusy or not self.ctx.persistence:isReady(p.UserId)or not self:inside(p)then return false end
 self.ctx.update:FireClient(p,{open='inventory'});return true
end
function V:handle(p,verb,arg)
 if not verbs[verb]then return false end
 local now=self.clock();local id=p.UserId
 local rate=verb=='cancelItemMove'and self.cancelRate or self.rate
 if now<(rate[id]or 0)then return true end;rate[id]=now+.2
 local core=self.ctx.core
 if core.closing or core.persistenceBusy or not self.ctx.persistence:isReady(id)then return true end
 local ok,msg
 if verb=='cancelItemMove'then
  -- Cancellation is allowed after walking away; it cannot mutate ownership.
  ok,msg=core:cancelItemMove(id)
 elseif not self:inside(p)then
  msg='Return inside your own base to manage items.'
 elseif verb=='beginItemMove'and uid(arg)then
  ok,msg=core:beginItemMove(id,arg,now)
 elseif verb=='moveItem'and type(arg)=='table'and uid(arg.uid)and uid(arg.token)and integer(arg.slot)and arg.slot>=1 and arg.slot<=16 then
  ok,msg=core:moveItem(id,arg.uid,arg.slot,arg.token,now)
 else msg='Invalid item management request.'end
 if msg then self.ctx.say(p,msg)end
 self.ctx.refresh();return true
end
function V:removePlayer(p)self.rate[p.UserId]=nil;self.cancelRate[p.UserId]=nil end
return V
