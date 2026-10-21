-- Durable opaque profiles and recoverable cross-profile changes.
-- UpdateAsync callbacks never yield. A journal decision, not cleanup order,
-- decides which prepared snapshots are authoritative after a crash.
local Store={};Store.__index=Store
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function integer(n)return finite(n)and n>0 and n%1==0 end
local function clone(value,seen)
 if type(value)~='table'then return value end
 seen=seen or{};assert(not seen[value],'Cyclic profile data')
 seen[value]=true;local out={}
 for k,v in pairs(value)do out[k]=clone(v,seen)end
 seen[value]=nil;return out
end
local function sameUsers(users,id)
 if type(users)~='table'then return false end
 for _,userId in ipairs(users)do if userId==id then return true end end
 return false
end
function Store.new(config,deps)
 assert(type(config)=='table'and type(deps)=='table','ProfileStore requires configuration and adapters')
 assert(deps.profiles and deps.journal and type(deps.sessionId)=='string'and #deps.sessionId>0 and #deps.sessionId<=36,'Invalid profile storage adapters/session ID')
 assert(finite(config.LockSeconds)and config.LockSeconds>=30,'LockSeconds must be at least 30')
 assert(finite(config.JournalSeconds)and config.JournalSeconds>0 and config.JournalSeconds<config.LockSeconds,'Journal lease must be shorter than profile lease')
 return setmetatable({config=config,deps=deps,profiles=deps.profiles,journal=deps.journal,
  clock=deps.clock or os.time,wait=deps.wait or task.wait,owner=deps.sessionId,loaded={},counter=0},Store)
end
function Store:_id()
 self.counter+=1;return self.owner..':'..self.counter
end
function Store:_validData(data)
 if type(data)~='table'then return false end
 if self.deps.validate then
  local ok,result=pcall(self.deps.validate,data)
  return ok and result==true
 end
 return true
end
function Store:_record(record,id)
 return type(record)=='table'and record.Schema==1 and record.UserId==id and self:_validData(record.Data)
  and(record.Lock==nil or(type(record.Lock)=='table'and type(record.Lock.Owner)=='string'and finite(record.Lock.ExpiresAt)))
  and(record.Pending==nil or(type(record.Pending)=='table'and type(record.Pending.OperationId)=='string'
   and type(record.Pending.Owner)=='string'and self:_validData(record.Pending.After)))
end
function Store:_journal(record)
 return type(record)=='table'and record.Schema==1 and type(record.Owner)=='string'and finite(record.ExpiresAt)
  and type(record.Users)=='table'and(record.Status=='Preparing'or record.Status=='Committed'or record.Status=='Aborted')
end
function Store:_owned(record)
 return record.Lock and record.Lock.Owner==self.owner and record.Lock.ExpiresAt>self.clock()
end
function Store:_update(adapter,key,transform,label)
 local attempts=math.clamp(math.floor(self.config.Retries or 3),1,5)
 for attempt=1,attempts do
  local budget=true
  if self.deps.allowRequest then
   local ok,allowed=pcall(self.deps.allowRequest,label or'profiles')
   budget=ok and allowed==true
  end
  if budget then
   local ok,result=pcall(function()return adapter:UpdateAsync(key,transform)end)
   if ok then return true,result end
  end
  if attempt<attempts then self.wait(math.min(self.config.MaxRetryDelay or 2,(self.config.RetryDelay or .35)*2^(attempt-1)))end
 end
 return false,'StorageUnavailable'
end
function Store:_read(adapter,key,label)
 -- An identity UpdateAsync obtains the current value without GetAsync's cache.
 return self:_update(adapter,key,function(current)return current end,label)
end
function Store:_block(id,why)
 local entry=self.loaded[id]
 if entry then entry.Ready=false;entry.Error=why end
end
function Store:_remember(id,record)
 self.loaded[id]={Data=clone(record.Data),Ready=true,ExpiresAt=record.Lock.ExpiresAt}
 return true,clone(record.Data)
end
function Store:isLoaded(id)return self.loaded[id]~=nil end
function Store:isReady(id)
 local entry=self.loaded[id]
 return entry~=nil and entry.Ready and entry.ExpiresAt>self.clock()or false
end
function Store:status(id)
 local entry=self.loaded[id]
 return{loaded=entry~=nil,ready=self:isReady(id),error=entry and entry.Error,leaseExpiresAt=entry and entry.ExpiresAt}
end
function Store:_decision(operationId,forceAbort)
 local key='t:'..operationId
 local ok,journal=self:_read(self.journal,key,'journal')
 if not ok then return false,journal end
 if not self:_journal(journal)then return false,'MissingOrInvalidJournal'end
 if journal.Status=='Preparing'then
  if not(forceAbort and journal.Owner==self.owner)and self.clock()<journal.ExpiresAt then return false,'TransactionPending'end
  local why
  ok,journal=self:_update(self.journal,key,function(current)
   why=nil
   if not self:_journal(current)then why='MissingOrInvalidJournal';return nil end
   if current.Status~='Preparing'then return current end
   if not(forceAbort and current.Owner==self.owner)and self.clock()<current.ExpiresAt then why='TransactionPending';return nil end
   local next=clone(current);next.Status='Aborted';return next
  end,'journal')
  if not ok then return false,journal end
  if not journal then return false,why or'TransactionPending'end
 end
 return true,journal
end
function Store:_finalize(id,operationId,journal)
 local why
 local ok,record=self:_update(self.profiles,'u:'..id,function(current)
  why=nil
  if not self:_record(current,id)then why='InvalidProfile';return nil end
  if not current.Pending then return current end
  if current.Pending.OperationId~=operationId then why='ProfileChanged';return nil end
  if current.Pending.Owner~=journal.Owner or not sameUsers(journal.Users,id)then why='InvalidJournalParticipant';return nil end
  local next=clone(current)
  if journal.Status=='Committed'then next.Data=clone(current.Pending.After)end
  next.Pending=nil;return next
 end,'profiles')
 if not ok then return false,record end
 if not record then return false,why or'ProfileChanged'end
 return true,record
end
function Store:_resolve(id,record,forceAbort)
 if not record.Pending then return true,record end
 local pending=record.Pending
 local ok,journal=self:_decision(pending.OperationId,forceAbort)
 if not ok then return false,journal end
 if journal.Owner~=pending.Owner or not sameUsers(journal.Users,id)then return false,'InvalidJournalParticipant'end
 return self:_finalize(id,pending.OperationId,journal)
end
function Store:load(id,defaultData)
 if not integer(id)then return false,'InvalidUserId'end
 if self.loaded[id]then
  if self:isReady(id)then return true,clone(self.loaded[id].Data)end
  return self:recover(id)
 end
 local why
 local ok,record=self:_update(self.profiles,'u:'..id,function(current)
  why=nil
  if current==nil then
   local fresh=type(defaultData)=='function'and defaultData()or defaultData
   if not self:_validData(fresh)then why='InvalidDefaultProfile';return nil end
   return{Schema=1,UserId=id,Data=clone(fresh),Lock={Owner=self.owner,ExpiresAt=self.clock()+self.config.LockSeconds}}
  end
  if not self:_record(current,id)then why='InvalidProfile';return nil end
  if current.Lock and current.Lock.Owner~=self.owner and current.Lock.ExpiresAt>self.clock()then why='ProfileLocked';return nil end
  if current.Pending then return current end
  local next=clone(current);next.Lock={Owner=self.owner,ExpiresAt=self.clock()+self.config.LockSeconds};return next
 end,'profiles')
 if not ok then return false,record end
 if not record then return false,why or'ProfileUnavailable'end
 if record.Pending then
  ok,record=self:_resolve(id,record,false)
  if not ok then return false,record end
  -- Acquire after recovery; another server may have acquired while resolving.
  ok,record=self:_update(self.profiles,'u:'..id,function(current)
   why=nil
   if not self:_record(current,id)or current.Pending then why='ProfileChanged';return nil end
   if current.Lock and current.Lock.Owner~=self.owner and current.Lock.ExpiresAt>self.clock()then why='ProfileLocked';return nil end
   local next=clone(current);next.Lock={Owner=self.owner,ExpiresAt=self.clock()+self.config.LockSeconds};return next
  end,'profiles')
  if not ok then return false,record end
  if not record then return false,why or'ProfileUnavailable'end
 end
 return self:_remember(id,record)
end
function Store:recover(id)
 if not self.loaded[id]then return false,'ProfileNotLoaded'end
 local ok,record=self:_read(self.profiles,'u:'..id,'profiles')
 if not ok then self:_block(id,record);return false,record end
 if not self:_record(record,id)then self:_block(id,'InvalidProfile');return false,'InvalidProfile'end
 if record.Pending then
  ok,record=self:_resolve(id,record,false)
  if not ok then self:_block(id,record);return false,record end
 end
 local why
 ok,record=self:_update(self.profiles,'u:'..id,function(current)
  why=nil
  if not self:_record(current,id)or current.Pending then why='ProfileChanged';return nil end
  if current.Lock and current.Lock.Owner~=self.owner and current.Lock.ExpiresAt>self.clock()then why='ProfileLocked';return nil end
  local next=clone(current);next.Lock={Owner=self.owner,ExpiresAt=self.clock()+self.config.LockSeconds};return next
 end,'profiles')
 if not ok then self:_block(id,record);return false,record end
 if not record then self:_block(id,why);return false,why or'ProfileUnavailable'end
 return self:_remember(id,record)
end
function Store:save(id,data)
 if not self:isReady(id)then return false,'ProfileNotReady'end
 if not self:_validData(data)then return false,'InvalidProfileData'end
 local staged=clone(data);local writeId=self:_id();local why
 local ok,record=self:_update(self.profiles,'u:'..id,function(current)
  why=nil
  if not self:_record(current,id)then why='InvalidProfile';return nil end
  if current.LastWriteId==writeId and self:_owned(current)and not current.Pending then return current end
  if not self:_owned(current)then why='SessionLost';return nil end
  if current.Pending then why='TransactionPending';return nil end
  local next=clone(current);next.Data=clone(staged);next.LastWriteId=writeId
  next.Lock.ExpiresAt=self.clock()+self.config.LockSeconds;return next
 end,'profiles')
 if not ok then self:_block(id,'WriteInDoubt');return false,'WriteInDoubt'end
 if not record then self:_block(id,why);return false,why or'SaveRejected'end
 self:_remember(id,record);return true
end
function Store:renew(id)
 if not self:isReady(id)then return false,'ProfileNotReady'end
 local why
 local ok,record=self:_update(self.profiles,'u:'..id,function(current)
  why=nil
  if not self:_record(current,id)then why='InvalidProfile';return nil end
  if not self:_owned(current)then why='SessionLost';return nil end
  if current.Pending then why='TransactionPending';return nil end
  local next=clone(current);next.Lock.ExpiresAt=self.clock()+self.config.LockSeconds;return next
 end,'profiles')
 if not ok then self:_block(id,'RenewInDoubt');return false,'RenewInDoubt'end
 if not record then self:_block(id,why);return false,why or'RenewRejected'end
 self:_remember(id,record);return true
end
function Store:_finishAtomic(ids,operationId,committed)
 local journal={Status=committed and'Committed'or'Aborted',Owner=self.owner,Users=ids}
 for _,id in ipairs(ids)do
  local ok,record=self:_finalize(id,operationId,journal)
  if ok and self:_owned(record)and not record.Pending then self:_remember(id,record)
  else self:_block(id,'TransactionCleanupPending')end
 end
 return committed,committed and nil or'TransactionAborted'
end
function Store:atomic(ids,afterData)
 if type(ids)~='table'or #ids<2 or #ids>(self.config.MaxProfilesPerTransaction or 8)or type(afterData)~='table'then return false,'InvalidParticipants'end
 local users,seen,staged={},{},{}
 local entries=0
 for key in pairs(ids)do
  if type(key)~='number'or key%1~=0 or key<1 or key>#ids then return false,'InvalidParticipants'end
  entries+=1
 end
 if entries~=#ids then return false,'InvalidParticipants'end
 for _,id in ipairs(ids)do
  if not integer(id)or seen[id]or not self:isReady(id)or not self:_validData(afterData[id])then return false,'InvalidParticipants'end
  users[#users+1]=id;seen[id]=true;staged[id]=clone(afterData[id])
 end
 table.sort(users)
 local operationId=self:_id();local key='t:'..operationId
 local deadline=self.clock()+self.config.JournalSeconds
 local ok,journal=self:_update(self.journal,key,function(current)
  if current~=nil then return current end
  return{Schema=1,Owner=self.owner,Status='Preparing',ExpiresAt=deadline,Users=clone(users)}
 end,'journal')
 if not ok or not self:_journal(journal)or journal.Owner~=self.owner or journal.Status~='Preparing'then
  for _,id in ipairs(users)do self:_block(id,'TransactionInDoubt')end
  return false,'TransactionInDoubt'
 end
 local prepared=true
 for _,id in ipairs(users)do
  local why
  local saved,record=self:_update(self.profiles,'u:'..id,function(current)
   why=nil
   if not self:_record(current,id)or not self:_owned(current)then why='SessionLost';return nil end
   if self.clock()>=deadline then why='TransactionExpired';return nil end
   if current.Pending then
    if current.Pending.OperationId==operationId then return current end
    why='TransactionPending';return nil
   end
   local next=clone(current);next.Pending={OperationId=operationId,Owner=self.owner,After=clone(staged[id])}
   next.Lock.ExpiresAt=self.clock()+self.config.LockSeconds;return next
  end,'profiles')
  if not saved or not record then prepared=false;break end
 end
 if prepared then
  ok,journal=self:_update(self.journal,key,function(current)
   if not self:_journal(current)or current.Owner~=self.owner then return nil end
   if current.Status~='Preparing'then return current end
   local next=clone(current);next.Status=self.clock()<current.ExpiresAt and'Committed'or'Aborted';return next
  end,'journal')
  if ok and journal and journal.Status=='Committed'then return self:_finishAtomic(users,operationId,true)end
 end
 -- Abort is a CAS competing with a possibly acknowledged-late commit. If a
 -- commit won, it stays authoritative; network errors never imply rollback.
 ok,journal=self:_decision(operationId,true)
 if not ok then
  for _,id in ipairs(users)do self:_block(id,'TransactionInDoubt')end
  return false,'TransactionInDoubt'
 end
 return self:_finishAtomic(users,operationId,journal.Status=='Committed')
end
function Store:release(id,data)
 if not self:isReady(id)then return false,'ProfileNotReady'end
 if data~=nil and not self:_validData(data)then return false,'InvalidProfileData'end
 local staged=data~=nil and clone(data)or nil
 local writeId=self:_id();local why
 local ok,record=self:_update(self.profiles,'u:'..id,function(current)
  why=nil
  if not self:_record(current,id)then why='InvalidProfile';return nil end
  if current.LastWriteId==writeId and current.Lock==nil and not current.Pending then return current end
  if not self:_owned(current)then why='SessionLost';return nil end
  if current.Pending then why='TransactionPending';return nil end
  local next=clone(current);if staged~=nil then next.Data=clone(staged)end
  next.LastWriteId=writeId;next.Lock=nil;return next
 end,'profiles')
 if not ok then self:_block(id,'ReleaseInDoubt');return false,'ReleaseInDoubt'end
 if not record then self:_block(id,why);return false,why or'ReleaseRejected'end
 self.loaded[id]=nil;return true
end
return Store
