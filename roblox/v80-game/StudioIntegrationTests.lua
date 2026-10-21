-- Manual, isolated Studio tests of the real PhaseService with two simulated server participants.
-- These exercise server paths and Instances, not actual multi-client network replication.
return function(package)
 local Core=require(package.Core);local Catalog=require(package.Catalog);local Config=table.clone(require(package.Config));local S=require(package.PhaseService)
 local folder=Instance.new('Folder');folder.Name='OP66_IsolatedIntegration';folder.Parent=workspace
 local results={};local service
 local ok,err=xpcall(function()
  local core=Core.new(Catalog,Config);local runtime={};local effects={};local bodies={}
  local origin=Vector3.new(1000,4,1000)
  local function participant(id,pos)
   local char=Instance.new('Model');char.Name='SimulatedParticipant'..id;char.Parent=folder
   local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Size=Vector3.new(2,2,1);root.Anchored=true;root.CanCollide=false;root.Position=pos;root.Parent=char;char.PrimaryPart=root
   local hum=Instance.new('Humanoid');hum.Parent=char
   local p={UserId=id,Character=char,Parent=true,attributes={}}
   function p:SetAttribute(k,v)self.attributes[k]=v end
   local base={owner=id,cf=CFrame.new(pos+Vector3.new(0,-4,40)),slots={}}
   for i=1,8 do base.slots[i]=CFrame.new(pos+Vector3.new(i,0,40)) end
   runtime[id]={player=p,base=base,shield=0,slow=0,immune=0,tagImmune=0}
   bodies[p]={root,hum};core:addPlayer(id,os.clock());core.players[id].cash=10000000
   return p,root,hum
  end
  local p1,r1=participant(-101,origin);local p2,r2=participant(-102,origin+Vector3.new(0,0,-5))
  local function body(p)local x=bodies[p];return x[1],x[2] end
  local ctx={core=core,config=Config,runtime=runtime,catalog=Catalog,templates=game.ReplicatedStorage.OPItemNet.Models,rng=Random.new(66),world={folder=folder,bases={}},body=body,movementSafe=function()return true end,los=function()return true end,refresh=function()end,say=function()end,fx={FireAllClients=function(_,kind,...)table.insert(effects,kind)end}}
  service=S.new(ctx);service.nextSpawn=math.huge
  -- Stop autonomous stepping; the test drives transaction time and cleanup explicitly.
  service.connection:Disconnect()
  for _,id in ipairs({-101,-102}) do local p=core.players[id];p.powerOwned={tag=true,dash=true,shield=true,lightning=true,slow=true};p.powerSlots=3;p.loadout={'tag','shield','lightning'} end
  service:cast(p2,{id='shield',aim=Vector3.new(0,0,1)})
  assert(runtime[-102].shieldHits==1)
  service:cast(p1,{id='tag',aim=Vector3.new(0,0,-1)});task.wait(.2)
  assert(runtime[-102].shieldHits==0 and runtime[-102].shield==0 and table.find(effects,'shieldBreak'))
  results.shield='Actual cast surrounds target and server consumes one hit'
  -- A paid carrier cannot use powers; an unblocked Tag forfeits the paid price.
  local now=os.clock();local offer=core:setOffer('purchase','item05',now,70)
  assert(core:purchaseAttempt(-102,'purchase',offer.token,now));core:advance(now+1.6)
  assert(core.players[-102].carry);assert(not core:power(-102,now+2,'shield'))
  service:hitPower(-101,runtime[-102],'tag',r1.Position,now+5)
  assert(not core.players[-102].carry and core.players[-102].held==0 and core.players[-102].cash==10000000-Catalog.ById.item05.price)
  assert(core.items[offer.uid].state=='Conveyor')
  results.tag='Carrier powers rejected; hit interrupts and returns same item without a refund'
  -- Solid wall is checked repeatedly with a swept character volume during Dash.
  local wall=Instance.new('Part');wall.Name='DashTestWall';wall.Size=Vector3.new(12,10,1);wall.Anchored=true;wall.Position=origin+Vector3.new(0,0,-4);wall.Parent=folder
  core.players[-101].loadout={'tag','dash'};core.players[-101].castReady=0;runtime[-101].interruptedUntil=0
  r1.CFrame=CFrame.new(origin);service:cast(p1,{id='dash',aim=Vector3.new(0,0,-1)});task.wait(.3)
  assert(r1.Position.Z>wall.Position.Z+1.7 and (r1.Position-origin).Magnitude<=2.2)
  results.dash='Dash stops before solid wall';wall:Destroy()
  -- Lightning marks its target area and applies a bounded stun, then shared immunity.
  r1.CFrame=CFrame.new(origin);r2.CFrame=CFrame.new(origin+Vector3.new(0,0,-16.9))
  core.players[-101].loadout={'tag','lightning'};core.players[-101].castReady=0
  runtime[-102].immune=0;runtime[-102].tagImmune=0
  service:cast(p1,{id='lightning',aim=Vector3.new(0,0,-1)});task.wait(1.25)
  assert(runtime[-102].shockRoot==r2 and runtime[-102].shockUntil>os.clock())
  local untilTime=runtime[-102].shockUntil
  service:hitPower(-101,runtime[-102],'lightning',origin,os.clock());assert(runtime[-102].shockUntil==untilTime)
  results.lightning='Target warning, bounded stun and repeated-hit immunity verified'
  service:cancelPlayer(p2);assert(not runtime[-102].shockRoot)
  -- Delivering a real transaction through the service sets owner and the income/index path.
  local t=os.clock()+10;offer=core:setOffer('delivered','krabby_patty',t,70)
  assert(core:purchaseAttempt(-102,'delivered',offer.token,t));core:advance(t+1.6)
  assert(service:finish(p2,true));assert(core.items[offer.uid].owner==-102 and core.players[-102].seen.krabby_patty)
  assert(core:characterReset(-102,t+3) and core.items[offer.uid].state=='Stored')
  results.delivery='Service delivery and reset preserve deposited owner/index'
 end,debug.traceback)
 if service then service:destroy() end;folder:Destroy()
 assert(ok,err);return results
end
