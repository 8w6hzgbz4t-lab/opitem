-- Execute the actual player HUD prefix and complete power menu with GUI/event doubles.
-- Model rendering, decorative animations, native touch movement and network replication require Studio.
return function(sources)
 local checks=0
 local function check(value,message)checks+=1;assert(value,message)end
 local function signal()
  local object={callbacks={}}
  function object:Connect(callback)local c={callback=callback,Connected=true};function c:Disconnect()self.Connected=false end;self.callbacks[#self.callbacks+1]=c;return c end
  function object:Fire(...)for _,c in ipairs(self.callbacks)do if c.Connected then c.callback(...)end end end
  return object
 end
 local function fixture(width,height,safeTop,safeSide)
  local all={};local queue={};local sent={};local bound={};local boundKeys={};local focused;local now=100
  local enum=setmetatable({},{__index=function(t,k)local c=setmetatable({},{__index=function(_,key)return k..'.'..key end});rawset(t,k,c);return c end})
  local function v2(x,y)return{X=x,Y=y}end
  local function udim(scale,offset)return{Scale=scale or 0,Offset=offset or 0}end
  local function u2(xs,xo,ys,yo)return{X=udim(xs,xo),Y=udim(ys,yo)}end
  local new
  local function resolve(object)
   local p=object._p
   if p.ClassName=='ScreenGui'then return v2(width-(safeSide or 0)*2,height-(safeTop or 0))end
   if p.Name=='PlayerGui'then return v2(width,height)end
   local parent=p.Parent;local base=parent and parent.AbsoluteSize or v2(width,height)
   local size=p.Size or u2(0,0,0,0)
   return v2(base.X*size.X.Scale+size.X.Offset,base.Y*size.Y.Scale+size.Y.Offset)
  end
  local methods={}
  function methods:GetChildren()return table.clone(self._children)end
  function methods:GetDescendants()local out={};local function walk(o)for _,c in ipairs(o._children)do out[#out+1]=c;walk(c)end end;walk(self);return out end
  function methods:IsA(class)return self._p.ClassName==class end
  function methods:FindFirstChild(name)for _,c in ipairs(self._children)do if c.Name==name then return c end end end
  function methods:WaitForChild(name)return self:FindFirstChild(name)end
  function methods:IsDescendantOf(parent)local current=self.Parent;while current do if current==parent then return true end;current=current.Parent end;return false end
  function methods:GetPropertyChangedSignal(name)self._signals[name]=self._signals[name]or signal();return self._signals[name]end
  function methods:SetAttribute(name,value)local old=self._attrs[name];self._attrs[name]=value;if old~=value and self._attributeSignals[name]then self._attributeSignals[name]:Fire()end end
  function methods:GetAttribute(name)return self._attrs[name]end
  function methods:GetAttributeChangedSignal(name)self._attributeSignals[name]=self._attributeSignals[name]or signal();return self._attributeSignals[name]end
  function methods:Destroy()for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil;self._p.destroyed=true end
  function methods:IsFocused()return focused==self end
  function methods:CaptureFocus()focused=self end
  new=function(class,parent)
   local object=setmetatable({_p={ClassName=class,Name=class,Visible=true,Text='',Enabled=true,CanvasPosition=v2(0,0),AnchorPoint=v2(0,0)},_children={},_signals={},_attrs={},_attributeSignals={}}, {
    __index=function(o,k)
     if methods[k]then return methods[k]end
     if k=='AbsoluteSize'then return resolve(o)end
     if k=='Activated'or k=='FocusLost'or k=='InputBegan'or k=='InputEnded'or k=='MouseLeave'then o._p[k]=o._p[k]or signal();return o._p[k]end
     return o._p[k]
    end,
    __newindex=function(o,k,value)
     local old=o._p[k]
     if k=='Parent'and old~=value then
      if old then local at=table.find(old._children,o);if at then table.remove(old._children,at)end end
      if value then value._children[#value._children+1]=o end
     end
     o._p[k]=value;if old~=value and o._signals[k]then o._signals[k]:Fire()end
    end,
   })
   all[#all+1]=object;object.Parent=parent;return object
  end
  local pg=new('Folder');pg.Name='PlayerGui'
  local touch=new('ScreenGui',pg);touch.Name='TouchGui';touch.Enabled=true
  local player={PlayerGui=pg,WaitForChild=function(_,name)if name=='PlayerGui'then return pg end end}
  local Update={OnClientEvent=signal()};local Phase={OnClientEvent=signal()}
  local FX={OnClientEvent=signal()}
  local AdminResponse={OnClientEvent=signal()}
  local adminSent={}
  local AdminRequest={FireServer=function(_,payload)adminSent[#adminSent+1]=payload end}
  local Action={FireServer=function(_,...)sent[#sent+1]={...}end}
  local catalog={Items={
   {id='stardust_dragon',name='Stardust Dragon',tier=5,rarity='Legendary',price=85000,income=900},
   {id='moms_credit_card',name='Moms Credit Card',tier=7,rarity='Ethereal',price=2000000,income=18000},
   {id='tungs_bat',name='Tungs Bat',tier=3,rarity='Rare',price=5500,income=95},
  },ById={},Colors={{180,180,180},{80,180,100},{80,130,240},{170,80,230},{240,180,50},{240,80,110},{240,240,240}}}
  for _,d in ipairs(catalog.Items)do catalog.ById[d.id]=d end
  local powers={Items={},ById={}}
  for index,key in ipairs({'tag','dash','gravity','slow','slam','repulse','shield','lightning','kiblast','spinjitzu'})do
   local d={id=key,name=string.upper(key),rank=math.min(5,index),price=index*100,cooldown=index+3,description='A visible '..key..' ability.',starter=key=='dash'}
   powers.Items[#powers.Items+1]=d;powers.ById[key]=d
  end
  local netObjects={AdminRequest=AdminRequest,AdminResponse=AdminResponse,Action=Action,Update=Update,Phase=Phase,FX=FX,Catalog={kind='Catalog'},AudioConfig={kind='AudioConfig'},PowerCatalog={kind='PowerCatalog'},Models={FindFirstChild=function()return nil end}}
  local net=setmetatable({WaitForChild=function(_,name)return netObjects[name]end},{__index=netObjects})
  local run={Heartbeat=signal(),RenderStepped=signal()}
  local UIS={InputChanged=signal(),InputEnded=signal(),TouchEnabled=width<640,GamepadEnabled=false,GetFocusedTextBox=function()return focused end}
  local services={Players={LocalPlayer=player},ReplicatedStorage={WaitForChild=function()return net end},RunService=run,UserInputService=UIS,ContextActionService={BindAction=function(_,name,callback,...)bound[name]=callback;boundKeys[name]={...} end},GuiService={},TweenService={},Debris={}}
  local camera=new('Camera');camera.ViewportSize=v2(width,height);camera.CFrame={LookVector={X=0,Y=0,Z=-1}}
  local workspace=new('Folder');workspace.CurrentCamera=camera
  local color={fromRGB=function(r,g,b)return{R=r/255,G=g/255,B=b/255}end,new=function(r,g,b)return{R=r,G=g,B=b}end}
  local env=setmetatable({os={clock=function()return now end},game={GetService=function(_,name)return assert(services[name],name)end},workspace=workspace,Instance={new=new},Enum=enum,Color3=color,Vector2={new=v2},Vector3={zAxis={X=0,Y=0,Z=1}},UDim={new=udim},UDim2={new=u2,fromOffset=function(x,y)return u2(0,x,0,y)end,fromScale=function(x,y)return u2(x,0,y,0)end},
   task={delay=function(seconds,callback)queue[#queue+1]={at=now+seconds,callback=callback} end,spawn=function(callback)queue[#queue+1]={at=now,callback=callback} end,defer=function(callback)callback()end},require=function(module)if module.kind=='Catalog'then return catalog elseif module.kind=='PowerCatalog'then return powers elseif module.kind=='AudioConfig'then return {Music={AssetId=0}} end;error('Unexpected UI require')end}, {__index=getfenv()})
  local hudGui=new('ScreenGui',pg);hudGui.Name='OPItemHUD';env.script={Parent=hudGui}
  local marker=assert(string.find(sources.Client,'-- Compact local presentation;',1,true),'Player HUD boundary missing')
  local hud=assert(loadstring(string.sub(sources.Client,1,marker-1),'ActualClientHUD'));setfenv(hud,env);hud()
  local phaseGui=new('ScreenGui',pg);phaseGui.Name='OPPhaseHUD';env.script={Parent=phaseGui}
  local phase=assert(loadstring(sources.PhaseClient,'ActualPhaseClient'));setfenv(phase,env);phase()
  local function find(name,parent)
   for _,o in ipairs(all)do if not o.destroyed and o.Name==name and(not parent or o:IsDescendantOf(parent))then return o end end
   error('Missing GUI '..name)
  end
  local function byText(value,parent)
   for _,o in ipairs(all)do if not o.destroyed and o.ClassName=='TextButton'and o.Text==value and(not parent or o:IsDescendantOf(parent))then return o end end
   error('Missing button '..value)
  end
  local function snapshot(extra)
   local s={cash=100000,steals=0,income=900,bank=1500,occupied=2,capacity=8,held=0,level=0,upgradeCost=1500,protectionDuration=30,incomeMultiplier=1,lock=20,lockReady=0,revision=1,
    inventory={{uid='relic1',kind='stardust_dragon',slot=1},{uid='relic2',kind='tungs_bat',slot=2}},seen={stardust_dragon=true,tungs_bat=true},powerSlots=2,powerOwned={tag=true,dash=true},loadout={'tag','dash'},powerReady={},thirdSlotPrice=5000,starterPending=true,battles={},mode='SAVED PROGRESS',persistenceStatus='ready',settings={musicMuted=false,sfxMuted=false,reducedEffects=false,musicVolume=.18,sfxVolume=.55,tutorialCompleted=false}}
   for k,v in pairs(extra or{})do s[k]=v end
   return s
  end
  return {resize=function(w,h)width,height=w,h;camera.ViewportSize=v2(w,h)end,boundKeys=boundKeys,UIS=UIS,GS=services.GuiService,adminSent=adminSent,AdminResponse=AdminResponse,pg=pg,touch=touch,Update=Update,Phase=Phase,Run=run,sent=sent,bound=bound,find=find,byText=byText,snapshot=snapshot,camera=camera,workspace=workspace,enum=enum,env=env,
   flush=function()local pending=table.clone(queue);table.clear(queue);for _,entry in ipairs(pending)do if entry.at<=now then entry.callback()else queue[#queue+1]=entry end end end,advance=function(dt)now+=dt end,focus=function(o)focused=o end,clearSent=function()table.clear(sent)end,signal=signal}
 end

 for _,dimensions in ipairs({{1280,720},{375,667},{812,375},{320,480},{375,667,58,0},{812,375,36,44}})do
  local f=fixture(dimensions[1],dimensions[2],dimensions[3],dimensions[4])
  local s=f.snapshot()
  f.Update.OnClientEvent:Fire(s)
  f.Update.OnClientEvent:Fire({open='inventory'})
  check(f.find('Menu').Visible and f.pg:GetAttribute('OPActiveMenu')=='inventory','Owner console must open Inventory')
  f.Update.OnClientEvent:Fire({open='inventory'})
  check(f.find('Menu').Visible,'Repeated owner-console opening must not toggle the menu closed')
  f.find('Select_relic1').Activated:Fire()
  check(f.find('ItemSlotLabel').Text=='GROUND FLOOR · SLOT 1','Stored item floor/slot must be clear')
  check(not pcall(f.find,'RemoveRelic'),'No separate Remove button is added because Sell exists')
  f.clearSent();f.find('MoveRelic').Activated:Fire()
  check(#f.sent==1 and f.sent[1][1]=='beginItemMove'and f.sent[1][2]=='relic1','Move must request the exact owned UID without client teleportation')
  local token='move-1'
  local function moving(extra)
   local values={itemMove={uid='relic1',token=token,remaining=20},occupiedSlots={[1]=true,[2]=true,[4]=true},
    inventory={{uid='relic1',kind='stardust_dragon',slot=1,moving=true},{uid='relic2',kind='tungs_bat',slot=2}}}
   for key,value in pairs(extra or{})do values[key]=value end
   return f.snapshot(values)
  end
  f.Update.OnClientEvent:Fire(moving())
  check(f.find('MoveRelic').Text=='CANCEL MOVE','Moving selection must expose a clear Cancel control')
  check(f.find('MoveInstructions').Text:find('20 seconds',1,true)~=nil,'Move selection expiry must be explained')
  if dimensions[1]>=640 then check(f.find('Select_relic1').Text:find('MOVING',1,true)~=nil,'Moving item must be visibly marked in the wide list')end
  f.clearSent();f.find('SellRelic').Activated:Fire();f.find('SellRelic').Activated:Fire();f.find('EquipRelic').Activated:Fire()
  check(#f.sent==0,'Moving item cannot be sold or equipped')
  for _,slot in ipairs({1,2,4})do
   local b=f.find('MoveToSlot'..slot)
   check(b.Text:find('OCCUPIED',1,true)~=nil and b.Selectable==false,'Stored and reserved transaction slots must be unavailable')
   b.Activated:Fire()
  end
  check(#f.sent==0,'Even an invoked occupied-slot button cannot request a move')
  check(not pcall(f.find,'MoveToSlot9'),'Upstairs destinations must remain hidden before level five')
  f.find('MoveToSlot3').Activated:Fire()
  local payload=f.sent[#f.sent]
  check(#f.sent==1 and payload[1]=='moveItem'and payload[2].uid=='relic1'and payload[2].slot==3 and payload[2].token==token,'Destination move must retain server UID/token and request one exact empty slot')
  f.Update.OnClientEvent:Fire(f.snapshot({inventory={{uid='relic1',kind='stardust_dragon',slot=3},{uid='relic2',kind='tungs_bat',slot=2}}}))
  check(f.find('ItemSlotLabel').Text=='GROUND FLOOR · SLOT 3','A slot-only authoritative update must refresh the inventory')
  check(f.find('MoveRelic').Text=='MOVE TO AN EMPTY SLOT','Committed move must leave selection mode')
  check(not pcall(f.find,'MoveToSlot3'),'Completed destination grid must be removed')
  f.clearSent();f.find('SellRelic').Activated:Fire()
  check(#f.sent==0,'Existing sale must retain separate confirmation')
  f.find('SellRelic').Activated:Fire()
  check(#f.sent==1 and f.sent[1][1]=='sell'and f.sent[1][2]=='relic1','Confirmed sale must retain existing exact-UID action')
  f.Update.OnClientEvent:Fire(f.snapshot({inventory={{uid='relic2',kind='tungs_bat',slot=2}},occupied=1}))
  check(not pcall(f.find,'Select_relic1'),'Sold item must leave the displayed inventory')
  f.find('Select_relic2').Activated:Fire()
  check(f.find('ItemSlotLabel').Text=='GROUND FLOOR · SLOT 2','Sold selection cannot retain a phantom slot or item')

  token='move-upstairs'
  f.Update.OnClientEvent:Fire(moving({capacity=16,level=5,secondFloor=true,occupiedSlots={[1]=true,[2]=true,[9]=true}}))
  check(f.find('MoveToSlot16').Text:find('EMPTY',1,true)~=nil,'Level-five upstairs destinations must be available')
  f.clearSent();f.find('MoveToSlot9').Activated:Fire()
  check(#f.sent==0,'Occupied upstairs slot cannot be selected')
  f.find('MoveToSlot16').Activated:Fire()
  check(#f.sent==1 and f.sent[1][2].slot==16,'Upstairs displayed slot eight must map to authoritative slot16')
  for slot=1,16 do
   local b=f.find('MoveToSlot'..slot)
   check(b.AbsoluteSize.Y>=42 and b.AbsoluteSize.X>=40,'Destination touch/gamepad targets must remain usable in safe viewports')
  end
  local old=f.find('MoveInstructions');f.Update.OnClientEvent:Fire(moving({capacity=16,level=5,secondFloor=true,occupiedSlots={[1]=true,[2]=true,[9]=true}}))
  check(not old.destroyed,'Unchanged move snapshot must not rebuild controls or steal focus')
  f.clearSent();f.find('MoveRelic').Activated:Fire();f.find('MoveRelic').Activated:Fire()
  check(#f.sent==1 and f.sent[1][1]=='cancelItemMove','Repeated Cancel must send one request per server token')
  f.Update.OnClientEvent:Fire(f.snapshot())
  token='move-close';f.Update.OnClientEvent:Fire(moving())
  f.clearSent();f.find('MenuClose').Activated:Fire()
  check(#f.sent==1 and f.sent[1][1]=='cancelItemMove'and not f.find('Menu').Visible,'Closing Inventory must cancel the active move once')
  f.Update.OnClientEvent:Fire(moving())
  check(#f.sent==1,'Repeated late snapshot cannot duplicate the same cancellation request')
  f.Update.OnClientEvent:Fire(f.snapshot())
  token='late-move';f.Update.OnClientEvent:Fire(moving())
  check(#f.sent==2 and f.sent[2][1]=='cancelItemMove','A move acknowledgement arriving after close must be cancelled')
  f.Update.OnClientEvent:Fire(f.snapshot())
  f.Update.OnClientEvent:Fire({open='inventory'})
  token='move-menu-switch';f.Update.OnClientEvent:Fire(moving())
  f.clearSent();f.find('NavigateIndex').Activated:Fire()
  check(#f.sent==1 and f.sent[1][1]=='cancelItemMove'and f.pg:GetAttribute('OPActiveMenu')=='index','Opening another menu must cancel the move without duplicate remotes')
  f.Update.OnClientEvent:Fire(f.snapshot());f.Update.OnClientEvent:Fire({open='inventory'})
  token='move-back';f.Update.OnClientEvent:Fire(moving())
  f.clearSent();f.find('MenuBack').Activated:Fire()
  check(#f.sent==1 and f.sent[1][1]=='cancelItemMove','Back must cancel the move on desktop and narrow layouts')

  for _,extra in ipairs({{carry='carrying'},{pending='bidding'},{inventory={{uid='relic1',kind='stardust_dragon',slot=1,carried=true}}}})do
   f.find('MenuClose').Activated:Fire();f.Update.OnClientEvent:Fire(f.snapshot(extra));f.Update.OnClientEvent:Fire({open='inventory'});f.find('Select_relic1').Activated:Fire()
   f.clearSent();f.find('MoveRelic').Activated:Fire();f.find('SellRelic').Activated:Fire();f.find('SellRelic').Activated:Fire();f.find('EquipRelic').Activated:Fire()
   check(#f.sent==0,'Carrying, bidding and stolen-item transit must block management actions')
  end
  f.Update.OnClientEvent:Fire(f.snapshot());f.find('NavigateHelp').Activated:Fire()
  local found=false
  for _,child in ipairs(f.find('Content'):GetDescendants())do
   if child.ClassName=='TextLabel'and child.Text:find('MOVE & SELL',1,true)then found=child.Text:find('50%',1,true)~=nil and child.Text:find('20 seconds',1,true)~=nil end
  end
  check(found,'Help must explain Move/Cancel and existing confirmed Sell')
 end
 print('VAULT UI PASS '..checks..' assertions across desktop, phone, landscape and small-phone layouts')
 return checks
end
