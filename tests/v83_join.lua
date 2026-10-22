return function(sources)
 local checks=0
 local function check(value,msg)checks+=1;assert(value,msg)end
 local function signal()
  local s={callbacks={}}
  function s:Connect(callback)self.callbacks[#self.callbacks+1]=callback;return{Disconnect=function()end}end
  function s:Fire(...)for _,callback in ipairs(self.callbacks)do callback(...)end end
  return s
 end
 local cfg=assert(loadstring(sources.config))()
 check(cfg.MaxPlayers==8 and cfg.BaseSlots==8,'Eight-player/eight-slot configuration changed')
 local function fixture()
  local now=100;local loaded,left,kicks={}, {}, {}
  local env=setmetatable({Config=cfg,runtime={},world={bases={}},core={players={}},
   warn=function()end,refresh=function()end,finish=function()end,
   Instance={new=function(class)return{ClassName=class}end},
   task={spawn=function(fn,...)fn(...)end},os=setmetatable({clock=function()return now end},{__index=os}),
   admin={admit=function()return true end,onJoin=function()end,resetCharacter=function()end},
   phase={cancelPlayer=function()end,interrupt=function()end,handle=function()return false end},
  },{__index=getfenv()})
  for i=1,8 do env.world.bases[i]={spawn='spawn-'..i,home={Position='home-'..i},upgrade={Position='power-'..i},manager={Position='manager-'..i}}end
  env.persistence={loading={},load=function(_,id)loaded[#loaded+1]=id;env.core.players[id]={};return true end,
   leave=function(_,id)left[#left+1]=id;env.core.players[id]=nil;return true end}
  env.core.characterReset=function()return true end
  local chunk=assert(loadstring(sources.join..'\nreturn join'));setfenv(chunk,env);local join=chunk()
  local function player(id)
   local p={UserId=id,Parent=true,CharacterAdded=signal()}
   function p:Kick(msg)kicks[#kicks+1]={id=self.UserId,message=msg};self.kicked=true end
   function p:WaitForChild()return nil end
   return p
  end
  return{env=env,join=join,player=player,loaded=loaded,left=left,kicks=kicks,advance=function()now+=1 end}
 end
 do
  local f=fixture();local owners={}
  for i=1,8 do
   local p=f.player(i);f.join(p)
   local rt=f.env.runtime[i]
   check(rt and rt.base.owner==i and not owners[rt.base],'Joining player was not assigned a unique owned vault')
   owners[rt.base]=true
   local root={Position={X=0,Y=5,Z=0},CFrame={}};local h={Health=100,HealthChanged=signal(),Died=signal()}
   local c={WaitForChild=function(_,name)return name=='HumanoidRootPart'and root or h end}
   function c:PivotTo(where)self.destination=where end
   p.Character=c;p.CharacterAdded:Fire(c)
   check(c.destination==rt.base.spawn,'Joining character did not spawn in its assigned vault')
  end
  local ninth=f.player(9);f.join(ninth)
  check(ninth.kicked and not f.env.runtime[9]and #f.loaded==8,'Ninth player claimed a vault or loaded a profile')
  check(#f.kicks==1 and f.kicks[1].message:find('8',1,true),'Full lobby does not explain its eight-vault limit')
  local player=f.env.runtime[1].player;f.join(player)
  check(#f.loaded==8,'Duplicate join claimed another vault or reloaded progress')
 end
 do
  local f=fixture();local a,b=f.player(11),f.player(12);local nesting=false
  f.env.persistence.load=function(_,id)
   f.loaded[#f.loaded+1]=id
   if not nesting then nesting=true;f.join(b)end
   f.env.core.players[id]={};return true
  end
  f.join(a)
  check(f.env.runtime[11].base~=f.env.runtime[12].base,'Concurrent profile loading assigned the same vault')
  check(f.env.runtime[11].base.owner==11 and f.env.runtime[12].base.owner==12,'Reserved vault ownership changed during loading')
 end
 do
  local f=fixture();local p=f.player(13)
  f.env.persistence.load=function()return false,'Unavailable'end;f.join(p)
  check(p.kicked and not f.env.world.bases[1].owner and not f.env.runtime[13],'Failed load left a writable vault assignment')
  local gone=f.player(14);gone.Parent=false
  f.env.persistence.load=function()return true end;f.join(gone)
  check(not f.env.world.bases[1].owner and not f.env.runtime[14]and f.left[1]==14,'Leaving during load leaked a vault reservation')
 end
 do
  local f=fixture();local p=f.player(77);f.join(p);local sold,upgrades,favorites={},{},{}
  local inside=true;local nearby={};local refreshes=0
  f.env.body=function()return{}end;f.env.movementSafe=function()return true end
  f.env.vault={inside=function()return inside end,handle=function()return false end}
  f.env.near=function(_,where)return nearby[where]==true end
  f.env.say=function()end;f.env.refresh=function()refreshes+=1 end
  f.env.core.sell=function(_,id,uid)sold[#sold+1]={id,uid};return true,'Sold'end
  f.env.core.equip=function(_,id,uid)favorites[#favorites+1]={id,uid};return true,'Equipped'end
  f.env.core.upgrade=function(_,id)upgrades[#upgrades+1]=id;return true,'Upgraded'end
  f.env.action={OnServerEvent=signal()}
  local chunk=assert(loadstring(sources.action));setfenv(chunk,f.env);chunk()
  local function request(verb,arg)f.advance();f.env.action.OnServerEvent:Fire(p,verb,arg)end
  request('sell','owned-uid');check(#sold==1 and sold[1][1]==77 and sold[1][2]=='owned-uid','Sell action did not reach the existing owner economy method')
  inside=false;request('sell','owned-uid');check(#sold==1,'Sale accepted outside the owner base')
  inside=true;request('sell',{});check(#sold==1,'Malformed sale UID reached the economy')
  request('equip','owned-uid');check(#favorites==1,'Favorite did not retain the old preference action')
  request('upgrade');check(#upgrades==0,'Base upgrade accepted away from a workbench')
  nearby['manager-1']=true;request('upgrade');check(#upgrades==1,'New vault workbench cannot use its existing level-up control')
  nearby['manager-1']=false;nearby['power-1']=true;request('upgrade');check(#upgrades==2,'Existing power workbench lost base upgrades')
  f.env.core.persistenceBusy=true;request('sell','owned-uid');check(#sold==1,'Sale bypassed a pending save')
  f.env.core.persistenceBusy=false;f.env.runtime[77].pendingReset=true;request('sell','owned-uid');check(#sold==1,'Sale accepted during character reset')
 end
 do
  local target;local activations=0;local created={}
  local env=setmetatable({
   Instance={new=function(class)local object={class=class,Enabled=true,Triggered=signal()};created[#created+1]=object;return object end},
   require=function()return{HoldSeconds=.35}end,script={Parent={PhaseConfig={}}},
   allowed=function(_,pos)target=pos;return true end,
  },{__index=getfenv()})
  local chunk=assert(loadstring(sources.prompt..'\nreturn prompt'));setfenv(chunk,env);local prompt=chunk()
  local offset={X=0,Y=1.2,Z=-1.65}
  local anchor={Name='Vault Manager',Parent=true,Position='old-center',CFrame=setmetatable({},{__mul=function(_,v)return{X=v.X-16,Y=v.Y+2.2,Z=v.Z-17}end})}
  local q=prompt(anchor,'Manage base items',function()activations+=1 end,offset)
  check(q.Parent.class=='Attachment'and q.Parent.Parent==anchor and q.Parent.Position==offset,'Workbench prompt was not attached above/front of its retained anchor')
  q.Triggered:Fire({UserId=77})
  check(activations==1 and math.abs(target.Y-3.4)<.001 and math.abs(target.Z+18.65)<.001,'Server validates the blocked desk center rather than the forward attachment')
  check(q.HoldDuration==.35 and q.RequiresLineOfSight,'Workbench lost hold/line-of-sight functionality')
 end
 print('JOIN PASS '..checks..' assertions')
end
