-- Execute real request boundaries; Core/session mutation and storage have their own suite.
return function(package,require)
 local V=require(package.VaultService)
 local count,groups=0,{}
 local function check(value,msg)count+=1;assert(value,msg)end
 local now=1;local active=true;local busy=false;local safe=true;local alive=true
 local calls,notices,updates={}, {}, {}
 local owner={UserId=77};local visitor={UserId=88}
 local position={X=0,Y=5,Z=0}
 local function base(id)return{owner=id,cf={PointToObjectSpace=function(_,value)return value end}}end
 local runtime={[77]={base=base(77)},[88]={base=base(88)}}
 local core={players={[77]={capacity=8},[88]={capacity=8}}}
 for _,name in ipairs({'beginItemMove','cancelItemMove','moveItem'})do
  core[name]=function(_,...)calls[#calls+1]={name=name,args={...}};return true,'Saved.'end
 end
 local refreshes=0
 local service=V.new({core=core,runtime=runtime,clock=function()return now end,
  body=function()if alive then return{Position=position}end end,movementSafe=function()return safe end,
  persistence={isReady=function()return active end},
  say=function(p,msg)notices[#notices+1]={p=p,msg=msg}end,
  update={FireClient=function(_,p,data)updates[#updates+1]={p=p,data=data}end},
  refresh=function()refreshes+=1 end})
 local function request(p,verb,arg)now+=1;return service:handle(p,verb,arg)end
 check(service:open(owner),'Owner could not open base management')
 check(#updates==1 and updates[1].p==owner and updates[1].data.open=='inventory','Opening menu leaked or did not target owner')
 runtime[88].base.owner=77
 check(not service:open(visitor),'Visitor opened another base management')
 check(request(visitor,'beginItemMove','item-1')and #calls==0,'Visitor modified another base')
 check(not request(owner,'removeItem','item-1'),'Cancelled Remove feature remained exposed')
 check(request(owner,'beginItemMove','item-1')and #calls==1,'Valid move selection was not delegated')
 check(calls[1].name=='beginItemMove'and calls[1].args[1]==77 and calls[1].args[2]=='item-1','Server accepted a different actor')
 local previous=#calls;service:handle(owner,'beginItemMove','item-2')
 check(#calls==previous,'Request throttle did not apply')
 service:handle(owner,'cancelItemMove')
 check(#calls==previous+1 and calls[#calls].name=='cancelItemMove','Rapid menu close was blocked by the start-move throttle')
 previous=#calls;service:handle(owner,'cancelItemMove')
 check(#calls==previous,'Cancellation has no separate spam limit')
 for _,bad in ipairs({false,123,{},string.rep('x',97),''})do request(owner,'beginItemMove',bad)end
 check(#calls==previous,'Malformed move UID reached Core')
 for _,bad in ipairs({0,-1,17,1.5,math.huge,0/0,'2',false,{}})do
  request(owner,'moveItem',{uid='item-1',token='move-1',slot=bad})
 end
 request(owner,'moveItem',{uid='item-1',slot=2});request(owner,'moveItem','item-1')
 check(#calls==previous,'Malformed slot/token reached Core')
 request(owner,'moveItem',{uid='item-1',slot=2,token='move-1',owner=88})
 check(#calls==previous+1 and calls[#calls].args[1]==77 and calls[#calls].args[3]==2 and calls[#calls].args[4]=='move-1','Move request did not retain server actor and token')
 previous=#calls
 for _,pos in ipairs({{X=24,Y=5,Z=0},{X=0,Y=5,Z=25},{X=0,Y=-2,Z=0},{X=0,Y=19,Z=0},{X=0,Y=25,Z=0},{X=0,Y=40,Z=0}})do
  position=pos;request(owner,'beginItemMove','item-1')
 end
 check(#calls==previous,'Outside base or locked upstairs request reached Core')
 core.players[77].capacity=16;position={X=0,Y=25,Z=0}
 request(owner,'beginItemMove','item-1');check(#calls==previous+1,'Unlocked upstairs rejected')
 previous=#calls;position={X=100,Y=5,Z=0}
 request(owner,'cancelItemMove');check(#calls==previous+1 and calls[#calls].name=='cancelItemMove','Walking away blocked safe cancellation')
 previous=#calls;position={X=0,Y=5,Z=0}
 for _,mode in ipairs({'busy','closing','notready','reset','unsafe','dead'})do
  core.persistenceBusy=mode=='busy';core.closing=mode=='closing';active=mode~='notready'
  runtime[77].pendingReset=mode=='reset';safe=mode~='unsafe';alive=mode~='dead'
  check(not service:open(owner),'Unsafe state opened menu: '..mode)
  request(owner,'beginItemMove','item-1')
 end
 check(#calls==previous,'Unsafe player/storage state delegated an item change')
 core.persistenceBusy=false;core.closing=false;active=true;runtime[77].pendingReset=nil;safe=true;alive=true
 service:removePlayer(owner);check(service.rate[77]==nil,'Request throttle leaked disconnected player')
 groups[1]='Owner base/floor checks, safe cancellation, request validation/throttling, storage and character gates'
 return{assertions=count,groups=groups}
end
