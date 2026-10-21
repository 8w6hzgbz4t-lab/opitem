-- Engine-independent authorization, throttling, confirmations and bounded audit log.
local P={}; P.__index=P
local function positiveId(id)
 return type(id)=='number' and id>0 and id<9007199254740992 and id%1==0
end
function P.new(config,clock,nonce,ownerUserId)
 -- ownerUserId must come from the server's personal-place ownership metadata.
 return setmetatable({config=config,clock=clock,nonce=nonce,ownerUserId=ownerUserId,buckets={},pending={},logs={}},P)
end
function P:authorized(id)
 if self.config.Enabled~=true or not positiveId(id) then return false end
 local configured=self.config.DeveloperUserId
 if positiveId(configured) then return id==configured end
 -- An invalid nonzero explicit ID fails closed; it never silently broadens access.
 if configured~=nil and configured~=0 then return false end
 if self.config.DeveloperUsername~=nil and self.config.DeveloperUsername~='' then return false end
 return self.config.AutoAuthorizePlaceOwner==true and positiveId(self.ownerUserId) and id==self.ownerUserId or false
end
function P:prepare(id,command,destructive,token)
 if not self:authorized(id) then return false,'Access denied.' end
 local now=self.clock(); local b=self.buckets[id] or {time=now,tokens=self.config.CommandBurst}
 b.tokens=math.min(self.config.CommandBurst,b.tokens+math.max(0,now-b.time)*self.config.CommandsPerSecond)
 b.time=now; self.buckets[id]=b
 if b.tokens<1 then return false,'Rate limited.' end
 b.tokens=b.tokens-1
 if destructive then
  if token~=nil then
   local pending=self.pending[id]
   self.pending[id]=nil -- A token is single-use even when invalid.
   if type(token)~='string' or #token>64 or not pending or pending.token~=token or pending.command~=command or now>pending.expires then
    return false,'Confirmation invalid or expired.'
   end
  else
   local generated=self.nonce()
   self.pending[id]={token=generated,command=command,expires=now+self.config.ConfirmationSeconds}
   return false,'Confirm this exact command within '..self.config.ConfirmationSeconds..' seconds.',generated
  end
 elseif token~=nil then return false,'Unexpected confirmation token.' end
 return true
end
function P:record(id,command,status)
 table.insert(self.logs,{time=self.clock(),actor=id,command=string.sub(command,1,512),status=string.sub(tostring(status),1,240)})
 while #self.logs>self.config.MaxLogs do table.remove(self.logs,1) end
end
function P:forget(id) self.buckets[id]=nil;self.pending[id]=nil end
return P

