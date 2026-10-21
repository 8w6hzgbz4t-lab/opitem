-- Execute ProfileStore with atomic UpdateAsync doubles and injected crashes.
return function(Store,baseConfig)
 local checks,groups=0,{}
 local function check(value,message)checks+=1;assert(value,message)end
 local function group(message)groups[#groups+1]=message end
 local function copy(value)
  if type(value)~='table'then return value end
  local out={};for k,v in pairs(value)do out[k]=copy(v)end;return out
 end
 local function equal(a,b)
  if type(a)~=type(b)then return false end
  if type(a)~='table'then return a==b end
  for k,v in pairs(a)do if not equal(v,b[k])then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end
  return true
 end
 local function data(cash,items)
  return{schemaVersion=1,cash=cash,bank=5.25,items=items or{},settings={music=true},receipts={},collections={infinity=false,exodiaUsed={}}}
 end
 local function fixture(retries)
  local f={now=1000,calls=0,waits={},fault=nil}
  local config=copy(baseConfig);config.Retries=retries or 1
  local function adapter(label)
   local a={records={},label=label}
   function a:UpdateAsync(key,transform)
    f.calls+=1;local event={n=f.calls,label=label,key=key,phase='before'}
    if f.fault then f.fault(event)end
    local current=copy(self.records[key]);local result=transform(current)
    if f.repeatCallback then result=transform(copy(self.records[key]))end
    if result~=nil then self.records[key]=copy(result)end
    event.phase='after';event.result=copy(result)
    if f.fault then f.fault(event)end
    return copy(result)
   end
   return a
  end
  f.profiles=adapter('profiles');f.journal=adapter('journal')
  function f.store(owner)
   return Store.new(config,{profiles=f.profiles,journal=f.journal,sessionId=owner,
    clock=function()return f.now end,wait=function(seconds)f.waits[#f.waits+1]=seconds end,
    validate=function(d)return type(d)=='table'and d.schemaVersion==1 and type(d.cash)=='number'and d.cash>=0 end,
    allowRequest=function(label)return not f.noBudget end})
  end
  function f.record(id)return f.profiles.records['u:'..id]end
  return f
 end
 do
  local f=fixture();local s=f.store('alpha');local defaults=0
  local ok,loaded=s:load(77,function()defaults+=1;return data(650,{'a'})end)
  check(ok and defaults==1 and loaded.cash==650,'New profile not acquired from confirmed absent record')
  check(s:isLoaded(77)and s:isReady(77),'Loaded readiness incorrect')
  check(f.record(77).Lock.Owner=='alpha'and f.record(77).Lock.ExpiresAt==1120,'Session lease not created')
  loaded.cash=999;check(f.record(77).Data.cash==650,'Loaded result aliases durable data')
  local _,again=s:load(77,function()error('Must not invoke existing defaults')end)
  check(again.cash==650,'Cached profile mutated through result')
  check(s:save(77,data(800,{'a'})),'Ordinary save failed')
  check(f.record(77).Data.cash==800,'Saved cash absent')
  check(f.record(77).Data.bank==5.25 and f.record(77).Data.settings.music,'Opaque bank/settings lost')
  local before=copy(f.record(77));local intruder=f.store('beta')
  local denied,reason=intruder:load(77,function()error('Locked profile used default')end)
  check(not denied and reason=='ProfileLocked'and equal(before,f.record(77)),'Concurrent session overwrote locked profile')
  f.now=1100;check(s:renew(77),'Lease renew failed')
  check(f.record(77).Lock.ExpiresAt==1220,'Lease not extended')
  check(s:release(77,data(900,{'a'}))and not s:isLoaded(77),'Final save/release failed')
  check(f.record(77).Lock==nil and f.record(77).Data.cash==900,'Release cleared or lost data')
  local admitted,restored=intruder:load(77,data(0))
  check(admitted and restored.cash==900,'Next session did not restore final data')
  check(not s:save(77,data(0)),'Released session could save')
  group('Confirmed-absent creation, opaque fields, defensive clones, exclusive locks, renew and final release')
 end
 do
  local f=fixture(3);local s=f.store('load-errors');local defaults=0
  f.fault=function(e)if e.phase=='before'then error('offline')end end
  local ok,why=s:load(77,function()defaults+=1;return data(650)end)
  check(not ok and why=='StorageUnavailable'and defaults==0,'Failed load created a fallback profile')
  check(f.record(77)==nil and not s:isLoaded(77),'Failed load became writable')
  check(f.calls==3 and #f.waits==2 and f.waits[1]<f.waits[2],'Retries/backoff not bounded')
  f.fault=nil;f.profiles.records['u:77']={Schema=2,UserId=77,Data=data(700)}
  local before=copy(f.record(77));ok,why=s:load(77,function()defaults+=1;return data(0)end)
  check(not ok and why=='InvalidProfile'and defaults==0 and equal(before,f.record(77)),'Unknown schema overwritten')
  f.profiles.records['u:77']={Schema=1,UserId=77,Data={schemaVersion=999,cash=0}}
  before=copy(f.record(77));ok,why=s:load(77,data(0))
  check(not ok and why=='InvalidProfile'and equal(before,f.record(77)),'Corrupt data accepted or replaced')
  for _,id in ipairs({0,-1,1.2,math.huge})do check(not s:load(id,data(0)),'Invalid UserId accepted')end
  group('Load failures, invalid schemas and data never create a writable replacement; bounded retries')
 end
 do
  local f=fixture();local s=f.store('budget');f.noBudget=true
  check(not s:load(77,data(650))and f.calls==0,'No-budget request reached DataStore')
  f.noBudget=false;check(s:load(77,data(650)),'Budget recovery failed')
  f.now=1121
  check(not s:isReady(77)and not s:save(77,data(0)),'Expired lease remained writable')
  check(s:recover(77),'Own expired lease could not be reacquired')
  f.now=1242;local other=f.store('new-owner');check(other:load(77,data(0)),'Expired lock not recoverable by new owner')
  local before=copy(f.record(77));local ok,why=s:recover(77)
  check(not ok and why=='ProfileLocked'and equal(before,f.record(77)),'Stale session stole a renewed lock')
  check(not s:isReady(77)and not s:save(77,data(0)),'Stale session could write after takeover')
  group('Budget gating, expired lease recovery and fencing against stale writers')
 end
 do
  local f=fixture(3);local s=f.store('receipt');check(s:load(77,data(650)),'Receipt fixture load')
  local after=data(5650);after.receipts['receipt-1']={productId=12345,offerId='pocket',grantedAt=f.now}
  local target=f.calls+1;local injected=false
  f.fault=function(e)if e.n==target and e.phase=='after'and not injected then injected=true;error('reply lost after durable write')end end
  check(s:save(77,after),'Acknowledged-late save did not retry idempotently')
  check(f.record(77).Data.cash==5650 and f.record(77).Data.receipts['receipt-1'].productId==12345,'Cash/receipt not persisted together')
  check(f.calls==target+1,'Write was not retried exactly once')
  after.cash=0;after.receipts['receipt-1']=nil
  check(f.record(77).Data.cash==5650 and f.record(77).Data.receipts['receipt-1']~=nil,'Saved snapshot aliases caller')
  f.fault=nil;check(s:release(77),'Receipt release')
  local _,rejoin=f.store('receipt-rejoin'):load(77,data(0))
  check(rejoin.receipts['receipt-1'].offerId=='pocket'and rejoin.cash==5650,'Receipt lost after rejoin')
  group('Cash and receipt share one atomic profile write; acknowledged-late retry is idempotent')
 end
 do
  local f=fixture();local s=f.store('ambiguous-save');check(s:load(77,data(650)),'Ambiguous save load')
  local at=f.calls+1
  f.fault=function(e)if e.n>=at and(e.n>at or e.phase=='after')then error('partition after write')end end
  local ok,why=s:save(77,data(900))
  check(not ok and why=='WriteInDoubt'and not s:isReady(77),'Ambiguous write did not block subsequent writes')
  check(not s:save(77,data(0)),'In-doubt snapshot could be overwritten')
  f.fault=nil
  local recovered,value=s:recover(77)
  check(recovered and value.cash==900 and s:isReady(77),'Recover did not read authoritative applied write')
  check(s:save(77,data(950)),'Recovered writer stayed blocked')
  group('Ambiguous single-profile writes freeze writes until authoritative recovery')
 end
 do
  local f=fixture();local s=f.store('load-ack');local defaults=0;local fail=f.calls+1
  f.fault=function(e)if e.n>=fail and(e.n>fail or e.phase=='after')then error('load creation reply lost')end end
  local ok=s:load(77,function()defaults+=1;return data(650,{'starter-original'})end)
  check(not ok and not s:isLoaded(77)and defaults==1,'Ambiguous load became writable or duplicated defaults')
  check(f.record(77).Data.items[1]=='starter-original','Ambiguous load did not retain original durable starter')
  f.fault=nil;f.now+=121
  local next=f.store('load-recover');local loaded,value=next:load(77,function()error('Existing starter replaced')end)
  check(loaded and value.cash==650 and value.items[1]=='starter-original','Load retry reset durable starting progress')
  group('A lost creation acknowledgement never recreates an existing starter/profile')
 end
 do
  local f=fixture();local s=f.store('transfer')
  check(s:load(77,data(650,{'unique-a'}))and s:load(88,data(650)),'Transfer loads')
  local beforeCalls=f.calls
  check(s:atomic({88,77},{[77]=data(650),[88]=data(650,{'unique-a'})}),'Atomic transfer failed')
  check(f.calls-beforeCalls==6,'Cross-profile transfer should use six bounded atomic writes')
  check(#f.record(77).Data.items==0 and f.record(88).Data.items[1]=='unique-a','Transfer duplicated/lost item')
  check(f.record(77).Pending==nil and f.record(88).Pending==nil,'Finalized records retain pending state')
  check(s:isReady(77)and s:isReady(88),'Successful transaction left profiles blocked')
  check(not s:atomic({77,77},{[77]=data(0)}),'Duplicate transaction participant accepted')
  check(not s:atomic({77,99},{[77]=data(0),[99]=data(0)}),'Unloaded participant accepted')
  check(not s:atomic({77,88,extra=99},{[77]=data(0),[88]=data(0)}),'Non-array participant accepted')
  check(not s:atomic({77,88},{[77]=data(0),[88]={schemaVersion=2,cash=0}}),'Invalid after snapshot accepted')
  group('Two-profile ownership changes commit once, without duplicate items or extra participants')
 end
 -- Stop all storage calls at every write boundary, before and after its effect.
 -- A fresh server can recover only the complete old state or complete new state.
 for _,phase in ipairs({'before','after'})do
  for cut=1,6 do
   local f=fixture();local s=f.store('crash-'..phase..cut)
   check(s:load(77,data(100,{'unique-a'}))and s:load(88,data(200)),'Crash fixture loads')
   local first=f.calls;local stop=first+cut
   f.fault=function(e)
    if e.n>stop or(e.n==stop and(e.phase==phase or phase=='before'))then error('simulated process storage loss')end
   end
   s:atomic({77,88},{[77]=data(100),[88]=data(200,{'unique-a'})})
   f.fault=nil;f.now+=121
   local next=f.store('recover-'..phase..cut)
   local left,a=next:load(77,function()error('Existing profile defaulted after crash')end)
   local right,b=next:load(88,function()error('Existing profile defaulted after crash')end)
   check(left and right,'Crash recovery load failed at '..phase..cut)
   local committed=cut>4 or(cut==4 and phase=='after')
   check(#a.items+#b.items==1,'Crash duplicated or lost unique item at '..phase..cut)
   check((committed and #a.items==0 and b.items[1]=='unique-a')or(not committed and a.items[1]=='unique-a'and #b.items==0),'Crash resolved mixed/incorrect transaction decision at '..phase..cut)
   check(a.cash==100 and b.cash==200,'Crash damaged unrelated cash')
   check(f.record(77).Pending==nil and f.record(88).Pending==nil,'Recovery left unresolved pending snapshots')
  end
 end
 group('All twelve before/after cross-write crash boundaries recover complete ownership exactly once')
 do
  local f=fixture();local s=f.store('aborted');s:load(77,data(100,{'a'}));s:load(88,data(200))
  local fail=f.calls+3
  f.fault=function(e)if e.n==fail and e.phase=='before'then error('second preparation rejected')end end
  local ok,why=s:atomic({77,88},{[77]=data(100),[88]=data(200,{'a'})})
  check(not ok and why=='TransactionAborted','Known abort not returned')
  check(f.record(77).Data.items[1]=='a'and #f.record(88).Data.items==0,'Abort applied a partial after snapshot')
  check(s:isReady(77)and s:isReady(88),'Known abort could not resume safe old state')
  group('Known preparation failures abort cleanly and preserve both original profiles')
 end
 do
  local f=fixture();local s=f.store('late-commit');s:load(77,data(100,{'a'}));s:load(88,data(200))
  local fail=f.calls+4
  f.fault=function(e)if e.n==fail and e.phase=='after'then error('commit response lost')end end
  check(s:atomic({77,88},{[77]=data(100),[88]=data(200,{'a'})}),'Durable committed transaction treated as abort after response loss')
  check(#f.record(77).Data.items==0 and f.record(88).Data.items[1]=='a','Late-ack commit rolled back or duplicated')
  group('A committed journal cannot roll back after an ambiguous commit response')
 end
 do
  local f=fixture();local s=f.store('cleanup');s:load(77,data(100,{'a'}));s:load(88,data(200))
  local fail=f.calls+5
  f.fault=function(e)if e.n==fail and e.phase=='before'then error('first finalizer unavailable')end end
  check(s:atomic({77,88},{[77]=data(100),[88]=data(200,{'a'})}),'Durable commit failed because cosmetic cleanup was unavailable')
  check(not s:isReady(77)and s:isReady(88),'Unfinalized profile was left writable or healthy peer blocked')
  check(f.record(77).Pending~=nil and f.record(88).Data.items[1]=='a','Cleanup failure did not retain recovery pointer')
  local ok,value=s:recover(77)
  check(ok and #value.items==0 and s:isReady(77),'Committed pending snapshot did not recover')
  check(f.record(77).Pending==nil and f.record(88).Data.items[1]=='a','Cleanup recovery rolled back committed transfer')
  group('Committed transfers stay committed when finalization fails; only unresolved profiles block writes')
 end
 do
  local f=fixture();local s=f.store('expiry');s:load(77,data(100,{'a'}));s:load(88,data(200))
  local expire=f.calls+4
  f.fault=function(e)if e.n==expire and e.phase=='before'then f.now+=61 end end
  local ok,why=s:atomic({77,88},{[77]=data(100),[88]=data(200,{'a'})})
  check(not ok and why=='TransactionAborted','Transaction committed after its decision lease expired')
  check(f.record(77).Data.items[1]=='a'and #f.record(88).Data.items==0,'Expired transaction changed ownership')
  group('Decision lease expiry prevents a stale coordinator from committing prepared profiles')
 end
 do
  local f=fixture();local s=f.store('dangling')
  f.profiles.records['u:77']={Schema=1,UserId=77,Data=data(100,{'a'}),Pending={OperationId='missing',Owner='other',After=data(0)}}
  local before=copy(f.record(77));local ok,why=s:load(77,data(0))
  check(not ok and why=='MissingOrInvalidJournal'and equal(before,f.record(77)),'Missing journal defaulted or guessed an ownership decision')
  f.journal.records['t:missing']={Schema=1,Owner='other',Status='Committed',ExpiresAt=1000,Users={88,99}}
  ok,why=s:load(77,data(0))
  check(not ok and why=='InvalidJournalParticipant'and equal(before,f.record(77)),'Unrelated journal changed this profile')
  group('Missing or mismatched recovery journals fail closed without replacing data')
 end
 do
  local f=fixture(3);f.repeatCallback=true;local s=f.store('callback-retry')
  check(s:load(77,data(100))and s:load(88,data(200)),'Repeated callback load')
  check(s:atomic({77,88},{[77]=data(90),[88]=data(210)}),'Retried UpdateAsync callbacks changed outcome')
  check(f.record(77).Data.cash==90 and f.record(88).Data.cash==210,'Callback retry applied a delta twice')
  local fail=f.calls+1
  f.fault=function(e)if e.n==fail and e.phase=='after'then error('release reply lost')end end
  check(s:release(77,data(95))and f.record(77).Lock==nil,'Release retry did not recognize its own durable write')
  check(f.record(77).Data.cash==95,'Release callback duplicated/corrupted saved value')
  group('Repeated UpdateAsync callbacks and release retries preserve absolute snapshots and write IDs')
 end
 return{assertions=checks,groups=groups}
end
