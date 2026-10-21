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
  local all={};local queue={};local sent={};local bound={};local focused
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
  local Action={FireServer=function(_,...)sent[#sent+1]={...}end}
  local catalog={Items={
   {id='stardust_dragon',name='Stardust Dragon',tier=5,rarity='Legendary',price=85000,income=900},
   {id='moms_credit_card',name='Moms Credit Card',tier=7,rarity='Ethereal',price=2000000,income=18000},
   {id='tungs_bat',name='Tungs Bat',tier=3,rarity='Rare',price=5500,income=95},
  },ById={},Colors={{180,180,180},{80,180,100},{80,130,240},{170,80,230},{240,180,50},{240,80,110},{240,240,240}}}
  for _,d in ipairs(catalog.Items)do catalog.ById[d.id]=d end
  local powers={Items={},ById={}}
  for index,key in ipairs({'tag','dash','gravity','slow','slam','repulse','shield','lightning'})do
   local d={id=key,name=string.upper(key),rank=math.min(5,index),price=index*100,cooldown=index+3,description='A visible '..key..' ability.',starter=key=='dash'}
   powers.Items[#powers.Items+1]=d;powers.ById[key]=d
  end
  local netObjects={Action=Action,Update=Update,Phase=Phase,FX=FX,Catalog={kind='Catalog'},PowerCatalog={kind='PowerCatalog'},Models={FindFirstChild=function()return nil end}}
  local net=setmetatable({WaitForChild=function(_,name)return netObjects[name]end},{__index=netObjects})
  local run={Heartbeat=signal(),RenderStepped=signal()}
  local UIS={TouchEnabled=width<640,GamepadEnabled=false,GetFocusedTextBox=function()return focused end}
  local services={Players={LocalPlayer=player},ReplicatedStorage={WaitForChild=function()return net end},RunService=run,UserInputService=UIS,ContextActionService={BindAction=function(_,name,callback,...)bound[name]=callback end},GuiService={},TweenService={},Debris={}}
  local camera=new('Camera');camera.ViewportSize=v2(width,height);camera.CFrame={LookVector={X=0,Y=0,Z=-1}}
  local workspace=new('Folder');workspace.CurrentCamera=camera
  local color={fromRGB=function(r,g,b)return{R=r/255,G=g/255,B=b/255}end,new=function(r,g,b)return{R=r,G=g,B=b}end}
  local env=setmetatable({game={GetService=function(_,name)return assert(services[name],name)end},workspace=workspace,Instance={new=new},Enum=enum,Color3=color,Vector2={new=v2},Vector3={zAxis={X=0,Y=0,Z=1}},UDim={new=udim},UDim2={new=u2,fromOffset=function(x,y)return u2(0,x,0,y)end,fromScale=function(x,y)return u2(x,0,y,0)end},
   task={delay=function(_,callback)queue[#queue+1]=callback end,spawn=function(callback)queue[#queue+1]=callback end,defer=function(callback)callback()end},require=function(module)if module.kind=='Catalog'then return catalog elseif module.kind=='PowerCatalog'then return powers end;error('Unexpected UI require')end}, {__index=getfenv()})
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
    inventory={{uid='relic1',kind='stardust_dragon',slot=1},{uid='relic2',kind='tungs_bat',slot=2}},seen={stardust_dragon=true,tungs_bat=true},powerSlots=2,powerOwned={tag=true,dash=true},loadout={'tag','dash'},powerReady={},thirdSlotPrice=5000,starterPending=true,battles={}}
   for k,v in pairs(extra or{})do s[k]=v end
   return s
  end
  return {pg=pg,touch=touch,Update=Update,Phase=Phase,Run=run,sent=sent,bound=bound,find=find,byText=byText,snapshot=snapshot,camera=camera,workspace=workspace,enum=enum,env=env,
   focus=function(o)focused=o end,clearSent=function()table.clear(sent)end,signal=signal}
 end
 for _,dimensions in ipairs({{1280,720},{375,667},{812,375},{320,480},{375,667,58,0},{812,375,36,44}})do
  local f=fixture(dimensions[1],dimensions[2],dimensions[3],dimensions[4]);local width,height=dimensions[1],dimensions[2]
  local s=f.snapshot();f.Update.OnClientEvent:Fire(s);f.Run.Heartbeat:Fire(.1)
  local status,nav,hotbar=f.find('Status'),f.find('Navigation'),f.find('PowerHotbar')
  check(status.AbsoluteSize.Y<=52,'Status bar is oversized')
  check(nav.AbsoluteSize.Y==40 and nav.AbsoluteSize.X<=width-16,'Navigation exceeds viewport')
  check(hotbar.AbsoluteSize.Y==36 and hotbar.AbsoluteSize.X<=width-16,'Power bar exceeds viewport')
  for _,name in ipairs({'Inventory','Index','Powers','Help','Settings'})do check(f.find('Navigate'..name).AbsoluteSize.Y>=36,'Touch navigation target too small')end
  if width<640 then check(nav.Position.Y.Offset==60 and hotbar.Position.Y.Offset==104,'Portrait bars must avoid native joystick/jump corners')
  else check(nav.Position.Y.Scale==1 and hotbar.Position.Y.Scale==1,'Wide-screen bars should use compact bottom center')end
  check(f.touch.Enabled,'HUD must not disable native touch controls')
  f.find('NavigateInventory').Activated:Fire()
  check(f.pg:GetAttribute('OPActiveMenu')=='inventory'and f.find('Menu').Visible,'Inventory navigation failed')
  check(f.find('UpgradeBase').Text=='UPGRADE · $1500','Base level upgrade cost must be visible')
  f.find('UpgradeBase').Activated:Fire();check(f.sent[#f.sent][1]=='upgrade','Base upgrade action not routed')
  f.find('NavigatePowers').Activated:Fire()
  check(f.pg:GetAttribute('OPActiveMenu')=='powers'and not f.find('Menu').Visible and f.find('PowerMenu').Visible,'Power navigation must close inventory')
  local safeWidth,safeHeight=width-(dimensions[4] or 0)*2,height-(dimensions[3] or 0)
  for _,name in ipairs({'Menu','PowerMenu'})do
   local m=f.find(name);local size=m.AbsoluteSize;local pos=m.Position;local anchor=m.AnchorPoint
   local x=pos.X.Scale*safeWidth+pos.X.Offset-anchor.X*size.X
   local y=pos.Y.Scale*safeHeight+pos.Y.Offset-anchor.Y*size.Y
   check(x>=0 and y>=0 and x+size.X<=safeWidth+.01 and y+size.Y<=safeHeight+.01,'Menu must remain inside Roblox/device safe insets: '..name)
  end
  check(not hotbar.Visible,'Hotbar should hide behind open menus')
  local card=f.find('PowerCard_dash');local altered=f.snapshot({cash=100001,revision=999})
  f.Update.OnClientEvent:Fire(altered);check(not card.destroyed,'Irrelevant currency update rebuilt power cards/focus')
  f.pg:SetAttribute('OPActiveMenu','developer')
  check(not f.find('Menu').Visible and not f.find('PowerMenu').Visible,'Developer menu must close every player panel')
  f.find('NavigateSettings').Activated:Fire();check(f.pg:GetAttribute('OPActiveMenu')=='settings','Settings navigation failed')
  f.find('ReducedEffects').Activated:Fire();check(f.pg:GetAttribute('OPReducedEffects')==true,'Reduced effects did not publish cosmetic preference')
  f.find('MenuClose').Activated:Fire();check(f.pg:GetAttribute('OPActiveMenu')==nil and f.touch.Enabled,'Closing menus should resume gameplay without disabling touch')
  f.clearSent();f.pg:SetAttribute('OPDeveloperFlight',true);f.bound.OPItemPower('',f.enum.UserInputState.Begin)
  check(#f.sent==0,'Flight Q descent must not also cast normal power')
  f.pg:SetAttribute('OPDeveloperFlight',false);f.bound.OPItemPower('',f.enum.UserInputState.Begin)
  check(#f.sent==1 and f.sent[1][1]=='power','Normal Q power shortcut failed')
  f.clearSent();f.find('PowerSlot1').Activated:Fire()
  check(#f.sent==1 and f.sent[1][2].id=='tag','Hotbar must cast selected slot power')
  f.Update.OnClientEvent:Fire(f.snapshot({carry='relic1'}));f.find('PowerSlot2').Activated:Fire()
  check(#f.sent==1,'Carry state should block hotbar requests')
  f.Update.OnClientEvent:Fire(f.snapshot({pending='battle1'}));f.bound.OPPowerSlot2('',f.enum.UserInputState.Begin)
  check(#f.sent==1,'Pending bids should block keyboard power requests')
  f.Update.OnClientEvent:Fire(f.snapshot());f.focus({});f.bound.OPPowerSlot1('',f.enum.UserInputState.Begin)
  check(#f.sent==1,'Typing should block keyboard power requests');f.focus(nil)
  f.find('NavigateIndex').Activated:Fire();local search=f.find('RelicSearch');search.Text='ethereal'
  check(not f.find('Select_stardust_dragon').Visible and f.find('Select_moms_credit_card').Visible,'Relic search must use actual name/rarity metadata')
  f.find('Select_moms_credit_card').Activated:Fire();check(f.find('RelicDetails').Visible,'Selected relic details missing')
  if width<640 then
   check(f.find('RelicDetails').Size.X.Scale==1,'Narrow item detail should occupy full panel width')
   f.find('MenuBack').Activated:Fire();check(f.find('RelicList').Visible and not f.find('Menu').Visible==false,'Back should return to narrow item list')
  end
  f.find('MenuClose').Activated:Fire()
  f.Update.OnClientEvent:Fire(f.snapshot({level=5,capacity=16,secondFloor=true,incomeMultiplier=1.25,protectionDuration=55,upgradeCost=4500}))
  f.find('NavigateInventory').Activated:Fire();check(f.find('UpgradeBase').Text=='UPGRADE · $4500','Gifted level/base upgrade values did not refresh')
  f.find('Select_relic1').Activated:Fire();f.clearSent();f.find('SellRelic').Activated:Fire();check(#f.sent==0,'Sale needs a separate confirmation')
  f.find('SellRelic').Activated:Fire();check(#f.sent==1 and f.sent[1][1]=='sell'and f.sent[1][2]=='relic1','Confirmed sale must target exact owned UID')
  f.find('MenuClose').Activated:Fire()
  local battle={id='offerA',name='Blue-Eyes White Dragon',price=1000,minimum=1050,ends=100}
  f.workspace.GetServerTimeNow=function()return 90 end
  f.Update.OnClientEvent:Fire(f.snapshot({battles={battle},exodia='rewardA'}))
  check(f.pg:GetAttribute('OPActiveMenu')==nil and not f.find('BattleDetails').Visible and not f.find('ExodiaReward').Visible,'Auction and reward must not force blocking windows')
  f.find('OpenBuyBattle').Activated:Fire();check(f.find('BattleDetails').Visible,'Auction banner should expose bid controls')
  f.find('BidAmount').Text='1200';f.clearSent();f.byText('PLACE BID').Activated:Fire()
  check(#f.sent==1 and f.sent[1][1]=='bid'and f.sent[1][2].offer=='offerA'and f.sent[1][2].amount==1200,'Bid action payload is incorrect')
  f.find('BidAmount').Text='nan';f.byText('PLACE BID').Activated:Fire();check(#f.sent==1,'Invalid bids should not be sent')
  f.pg:SetAttribute('OPActiveMenu',nil);f.find('OpenExodiaReward').Activated:Fire()
  check(f.find('ExodiaReward').Visible and not f.find('BattleDetails').Visible,'Collection reward should own one active modal')
  f.byText('GAIN ONE BASE LEVEL').Activated:Fire()
  check(f.sent[#f.sent][1]=='exodia'and f.sent[#f.sent][2].token=='rewardA'and f.sent[#f.sent][2].choice=='level','Reward should preserve the server token and choice')
  check(f.pg:GetAttribute('OPActiveMenu')==nil,'Reward choice should return to gameplay')
 end
 print('PLAYER HUD PASS '..checks..' assertions across desktop, phone, landscape and small-phone layouts')
 return checks
end
