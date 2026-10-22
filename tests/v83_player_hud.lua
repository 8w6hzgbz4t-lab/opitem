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
  local f=fixture(dimensions[1],dimensions[2],dimensions[3],dimensions[4]);local width,height=dimensions[1],dimensions[2]
  local s=f.snapshot();f.Update.OnClientEvent:Fire(s);f.Run.Heartbeat:Fire(.1)
  local status,nav,hotbar=f.find('Status'),f.find('Navigation'),f.find('PowerHotbar')
  check(not f.find('PowerSlot4').Visible,'Normal players have exactly three visible power slots')
  local beforeAdmin=#f.adminSent
  local result=f.bound.OPPowerSlot4('',f.enum.UserInputState.Begin)
  f.find('PowerSlot4').Activated:Fire()
  check(#f.adminSent==beforeAdmin and result==f.enum.ContextActionResult.Pass,'Fourth key and button cannot request developer casts without server metadata')
  for _,disabled in ipairs({{id='royalseal',enabled=true,mode=false},{id='royalseal',enabled=false,mode=true},{id='tag',enabled=true,mode=true}})do
   f.Update.OnClientEvent:Fire(f.snapshot({developerAbility=disabled}));f.Run.Heartbeat:Fire(.1)
   check(not f.find('PowerSlot4').Visible,'Inactive or unrelated metadata never enables the developer slot')
  end
  f.Update.OnClientEvent:Fire(f.snapshot({developerAbility={id='royalseal',enabled=true,mode=true,remaining=0}}));f.Run.Heartbeat:Fire(.1)
  check(f.find('PowerSlot4').Visible and f.find('PowerSlot4').Text=='4 ROYAL SEAL','Authorized developer mode exposes the unique fourth slot')
  check(hotbar.AbsoluteSize.X<=width-16,'Four developer slots fit within the safe viewport')
  f.bound.OPPowerSlot4('',f.enum.UserInputState.Begin)
  check(#f.adminSent==beforeAdmin and f.pg:GetAttribute('OPSelectedPowerSlot')==4 and f.find('PowerSlot4'):GetAttribute('Selected'),'Fourth slot only selects and highlights')
  f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.adminSent==beforeAdmin+1 and f.adminSent[#f.adminSent].mode=='command'and f.adminSent[#f.adminSent].text=='royalseal','Fourth shortcut uses the authenticated admin channel')
  f.AdminResponse.OnClientEvent:Fire({ok=true,mods={developerMode=true,royalSealRemaining=15}});f.Run.Heartbeat:Fire(.1)
  check(f.find('PowerSlot4').Text=='4 ROYAL SEAL · 15s','Developer slot displays the server signature cooldown')
  f.find('PowerSlot4').Activated:Fire();f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.adminSent==beforeAdmin+1,'Signature cooldown prevents repeated UI requests')
  f.advance(15.1);f.Run.Heartbeat:Fire(.1)
  f.Update.OnClientEvent:Fire(f.snapshot({carry='relic',developerAbility={id='royalseal',enabled=true,mode=true,remaining=0}}))
  f.find('PowerSlot4').Activated:Fire();f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin);check(#f.adminSent==beforeAdmin+1,'Carrying blocks the fourth ability too')
  f.Update.OnClientEvent:Fire(f.snapshot({pending='bid',developerAbility={id='royalseal',enabled=true,mode=true,remaining=0}}))
  f.bound.OPPowerSlot4('',f.enum.UserInputState.Begin);f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin);check(#f.adminSent==beforeAdmin+1,'Bidding blocks the fourth ability too')
  f.Update.OnClientEvent:Fire(f.snapshot({developerAbility={id='royalseal',enabled=true,mode=true,remaining=0}}))
  f.AdminResponse.OnClientEvent:Fire({mods={developerMode=false}})
  check(not f.find('PowerSlot4').Visible,'Disabling developer mode immediately hides the signature slot')
  f.Update.OnClientEvent:Fire(f.snapshot({developerAbility={id='royalseal',enabled=true,mode=true,remaining=0}}))
  f.AdminResponse.OnClientEvent:Fire({authorized=false})
  check(not f.find('PowerSlot4').Visible,'Server access revocation removes the fourth slot immediately')
  f.Update.OnClientEvent:Fire(s);f.Run.Heartbeat:Fire(.1)

  check(status.AbsoluteSize.Y<=52,'Status bar is oversized')
  check(nav.AbsoluteSize.Y==40 and nav.AbsoluteSize.X<=width-16,'Navigation exceeds viewport')
  check(hotbar.AbsoluteSize.Y==36 and hotbar.AbsoluteSize.X<=width-16,'Power bar exceeds viewport')
  for slot=1,4 do
   local b=f.find('PowerSlot'..slot)
   check(b.Font==f.enum.Font.GothamMedium and b.TextSize==10,'Every power hotbar uses smaller medium labels')
   check(b.TextWrapped==false and b.TextScaled==false and b.TextStrokeTransparency==1,'Power labels must remain plain single-line text')
   check(b:FindFirstChild('Selection').ApplyStrokeMode==f.enum.ApplyStrokeMode.Border,'Selection must outline the button rather than the letters')
  end
  check(f.find('UseSelectedPower').Font==f.enum.Font.GothamMedium and f.find('UseSelectedPower').TextSize==10,'Touch action uses compact medium-weight text')
  check(f.find('NavigatePowers').Font==f.enum.Font.GothamMedium and f.find('NavigatePowers').TextSize==11,'Power navigation label matches compact typography')
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
  check(not hotbar.Visible and not f.find('UseSelectedPower').Visible,'Hotbar and Use button hide behind menus')
  local card=f.find('PowerCard_dash');local altered=f.snapshot({cash=100001,revision=999})
  local heading=f.find('PowerMenuTitle')
  check(heading.Font==f.enum.Font.GothamMedium and heading.TextSize==16,'Power menu heading is smaller and lighter')
  local powerName=f.find('PowerName',card);local description=f.find('PowerDescription',card)
  check(powerName.Font==f.enum.Font.GothamMedium and powerName.TextSize==12,'Power name and rank use compact medium text')
  check(description.TextSize==11 and description.TextWrapped,'Power descriptions remain wrapped and phone readable')
  f.Update.OnClientEvent:Fire(altered);check(not card.destroyed,'Irrelevant currency update rebuilt power cards/focus')
  f.pg:SetAttribute('OPActiveMenu','developer')
  check(not f.find('Menu').Visible and not f.find('PowerMenu').Visible,'Developer menu must close every player panel')
  f.find('NavigateSettings').Activated:Fire();check(f.pg:GetAttribute('OPActiveMenu')=='settings','Settings navigation failed')
  f.find('ReducedEffects').Activated:Fire();check(f.pg:GetAttribute('OPReducedEffects')==true,'Reduced effects did not publish cosmetic preference')
  f.find('MenuClose').Activated:Fire();check(f.pg:GetAttribute('OPActiveMenu')==nil and f.touch.Enabled,'Closing menus should resume gameplay without disabling touch')
  f.clearSent();check(f.bound.OPItemPower==nil,'Legacy Q/R2 cast binding is removed')
  check(table.find(f.boundKeys.OPUseSelectedPower,f.enum.KeyCode.F) and table.find(f.boundKeys.OPUseSelectedPower,f.enum.KeyCode.ButtonR2),'F and controller R2 share one activation binding')
  f.find('PowerSlot1').Activated:Fire()
  check(#f.sent==0 and f.pg:GetAttribute('OPSelectedPowerSlot')==1 and f.find('PowerSlot1'):GetAttribute('Selected'),'Hotbar click only selects and highlights Tag')
  f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==1 and f.sent[1][2].id=='tag','F/R2 activates the selected normal power once')
  f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin);check(#f.sent==1,'Repeated activation is briefly debounced')
  f.bound.OPPowerSlot2('',f.enum.UserInputState.Begin)
  check(#f.sent==1 and f.pg:GetAttribute('OPSelectedPowerSlot')==2 and f.find('PowerSlot2'):GetAttribute('Selected'),'Number keys only select and highlight')
  f.advance(.21);f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==2 and f.sent[2][2].id=='dash','Selected optional power activates separately')
  f.Update.OnClientEvent:Fire(f.snapshot({carry='relic1'}));f.find('PowerSlot1').Activated:Fire();f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==2,'Carry state blocks actual activation')
  f.Update.OnClientEvent:Fire(f.snapshot({pending='battle1'}));f.bound.OPPowerSlot2('',f.enum.UserInputState.Begin);f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==2,'Pending bids block activation')
  f.Update.OnClientEvent:Fire(f.snapshot());f.focus({});f.bound.OPPowerSlot1('',f.enum.UserInputState.Begin);f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==2,'Typing blocks selection/activation');f.focus(nil)
  f.Update.OnClientEvent:Fire(f.snapshot({powerReady={dash=9}}));f.find('PowerSlot2').Activated:Fire();f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==2,'Authoritative cooldown blocks activation even after selection')
  f.advance(9.1);f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==3 and f.sent[3][2].id=='dash','Selected power activates after cooldown expiry')
  f.Update.OnClientEvent:Fire(f.snapshot());f.bound.OPTagController('',f.enum.UserInputState.Begin)
  check(#f.sent==3 and f.pg:GetAttribute('OPSelectedPowerSlot')==1,'Controller L2 selects Tag without casting')
  if width<640 then
   check(f.find('UseSelectedPower').Visible and f.find('UseSelectedPower').Position.Y.Offset==148,'Touch activation is a separate safe button below selection slots')
   f.advance(.21);f.find('UseSelectedPower').Activated:Fire();check(#f.sent==4 and f.sent[4][2].id=='tag','Touch Use activates the selected power')
  end
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
  check(f.find('QuickStart').Visible,'First-play guide is opt-in and visible during play')
  f.find('QuickStart').Activated:Fire();check(f.pg:GetAttribute('OPActiveMenu')=='help' and f.find('QuickStartGuide').Visible,'Guide chip opens quick instructions')
  f.clearSent();f.find('FinishQuickStart').Activated:Fire();f.advance(.3);f.flush()
  check(f.pg:GetAttribute('OPActiveMenu')==nil and not f.find('QuickStart').Visible,'Finishing guide returns to play without an obstructive popup')
  local saved=f.sent[#f.sent];check(saved and saved[1]=='settings'and saved[2].tutorialCompleted==true,'Tutorial completion requests durable settings')
  f.Update.OnClientEvent:Fire(f.snapshot({settings={musicMuted=true,sfxMuted=true,reducedEffects=true,musicVolume=.3,sfxVolume=.4,tutorialCompleted=true}}))
  check(f.pg:GetAttribute('OPMusicMuted') and f.pg:GetAttribute('OPSfxMuted') and f.pg:GetAttribute('OPReducedEffects'),'Saved preferences restore from server snapshot')
  check(f.pg:GetAttribute('OPMusicVolume')==.3 and f.pg:GetAttribute('OPSfxVolume')==.4 and not f.find('QuickStart').Visible,'Saved volumes and onboarding restore')
  f.find('NavigateSettings').Activated:Fire();check(string.find(f.find('MusicReadiness').Text,'coming soon',1,true),'Unconfigured music is explained honestly')
  f.clearSent();f.find('MusicToggle').Activated:Fire();f.find('SfxToggle').Activated:Fire();f.GS.SelectedObject=f.find('musicVolumeSlider');f.bound.OPVolumeSlider('',f.enum.UserInputState.Begin,{KeyCode=f.enum.KeyCode.Right});f.bound.OPVolumeSlider('',f.enum.UserInputState.Begin,{KeyCode=f.enum.KeyCode.DPadRight});f.advance(.3);f.flush()
  check(#f.sent==1 and f.sent[1][1]=='settings','Rapid preference edits merge into one server request')
  check(f.sent[1][2].musicMuted==false and f.sent[1][2].sfxMuted==false and f.sent[1][2].musicVolume==.4,'Only selected preference values are sent')
  local slider=f.find('musicVolumeSlider');slider.AbsolutePosition={X=100,Y=0};local sw=slider.AbsoluteSize.X
  local mouse={UserInputType=f.enum.UserInputType.MouseButton1,Position={X=100+sw*.75}}
  slider.InputBegan:Fire(mouse);check(f.pg:GetAttribute('OPMusicVolume')==.75,'Mouse slider press chooses volume')
  f.UIS.InputChanged:Fire({UserInputType=f.enum.UserInputType.MouseMovement,Position={X=100+sw*2}})
  check(f.pg:GetAttribute('OPMusicVolume')==1,'Mouse slider clamps above the track')
  f.UIS.InputEnded:Fire(mouse)
  local touchSlider=f.find('sfxVolumeSlider');touchSlider.AbsolutePosition={X=100,Y=0};local tw=touchSlider.AbsoluteSize.X
  local touchInput={UserInputType=f.enum.UserInputType.Touch,Position={X=100+tw*.25}}
  touchSlider.InputBegan:Fire(touchInput);check(f.pg:GetAttribute('OPSfxVolume')==.25,'Touch slider chooses independent effects volume')
  touchInput.Position.X=10;f.UIS.InputChanged:Fire(touchInput)
  check(f.pg:GetAttribute('OPSfxVolume')==0,'Touch slider clamps below the track')
  f.UIS.InputEnded:Fire(touchInput);f.advance(.3);f.flush()
  check(f.sent[#f.sent][2].musicVolume==1 and f.sent[#f.sent][2].sfxVolume==0,'Final dragged slider values are batched for persistence')
  f.find('MenuClose').Activated:Fire();f.Update.OnClientEvent:Fire(f.snapshot({powerSlots=3,powerOwned={tag=true,kiblast=true,spinjitzu=true},loadout={'tag','kiblast','spinjitzu'}}));f.Run.Heartbeat:Fire(.1)
  check(f.find('PowerSlot2').Text=='2 KI BLAST'and f.find('PowerSlot3').Text=='3 TORNADO','New powers fit normal equipped slots')
  f.clearSent();f.find('PowerSlot2').Activated:Fire();check(#f.sent==0,'Ki Blast selection never casts')
  f.advance(.21);f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin);f.find('PowerSlot3').Activated:Fire();check(#f.sent==1,'Spinjitzu selection never casts')
  f.advance(.21);f.bound.OPUseSelectedPower('',f.enum.UserInputState.Begin)
  check(#f.sent==2 and f.sent[1][2].id=='kiblast'and f.sent[2][2].id=='spinjitzu','New selected powers activate through normal server power channel')
  f.find('NavigatePowers').Activated:Fire();check(f.find('PowerCard_kiblast').Visible and f.find('PowerCard_spinjitzu').Visible,'All ten power cards are available')
  f.pg:SetAttribute('OPActiveMenu',nil);f.clearSent()
  local alert=f.find('TheftAlert');local alertStatus=f.find('TheftStatus');local alertItem=f.find('TheftItem')
  check(not alert.Visible,'Theft banner starts closed')
  f.Update.OnClientEvent:Fire({theftAlert={kind='taken',item='Millennium Puzzle',thief='Player Two'}})
  check(alert.Visible and alertItem.Text=='Millennium Puzzle'and alertStatus.Text=='TAKEN · Player Two','Owner sees exact item and thief at pickup')
  check(not alert.Active and not alert.Selectable and not alertStatus.Active and not alertItem.Active,'Theft banner has no input capture')
  check(f.pg:GetAttribute('OPActiveMenu')==nil and f.touch.Enabled,'Theft alert never opens a menu or disables native controls')
  local aw,ah=alert.AbsoluteSize.X,alert.AbsoluteSize.Y
  local ax=safeWidth-8-aw;local ay=alert.Position.Y.Offset
  check(ax>=0 and ay>=0 and ax+aw<=safeWidth and ay+ah<=safeHeight,'Theft banner fits each device safe viewport')
  check((width<640 and ay==188 and ah==52)or(width>=640 and ay==92 and ah==58),'Theft banner stays below controls with compact device placement')
  f.Update.OnClientEvent:Fire({message='Someone entered your vault.'})
  check(alert.Visible and alertItem.Text=='Millennium Puzzle'and not f.find('Notice').Visible,'Routine intrusion toast cannot overwrite or cover theft banner')
  f.advance(6);f.flush();check(alert.Visible,'Theft banner lasts at least six seconds')
  f.Update.OnClientEvent:Fire({theftAlert={kind='stolen',item='Millennium Puzzle',thief='Player Two'}})
  check(alertStatus.Text=='STOLEN · Player Two'and alertItem.Text=='Millennium Puzzle','Successful theft has explicit item status')
  f.advance(1.1);f.flush();check(alert.Visible,'Old alert timer cannot hide a newer theft update')
  f.Update.OnClientEvent:Fire({theftAlert={kind='recovered',item='Millennium Puzzle',thief='Player Two'}})
  check(alertStatus.Text=='RECOVERED · BACK AT BASE'and alertItem.Text=='Millennium Puzzle','Recovery names the returned item clearly')
  f.advance(7.1);f.flush();check(not alert.Visible,'Theft banner expires after seven seconds')
  f.Update.OnClientEvent:Fire({theftAlert={kind='unknown',item='Millennium Puzzle'}})
  f.Update.OnClientEvent:Fire({theftAlert={kind='taken',item=7}})
  check(not alert.Visible and #f.sent==0,'Malformed alerts are ignored and alerts never send client remotes')
  f.pg:SetAttribute('OPActiveMenu','inventory')
  f.Update.OnClientEvent:Fire({theftAlert={kind='taken',item='Blue-Eyes White Dragon',thief='Raider'}})
  check(alert.Visible and f.pg:GetAttribute('OPActiveMenu')=='inventory','Theft alert preserves an existing menu and input ownership')
  f.resize(375,667)
  check(alert.Position.Y.Offset==188 and alert.AbsoluteSize.X<=359 and alert.AbsoluteSize.Y==52,'Active theft alert refits after switching to portrait phone size')
  f.resize(812,375)
  check(alert.Position.Y.Offset==92 and alert.AbsoluteSize.X<=300 and alert.AbsoluteSize.Y==58,'Active theft alert refits after switching to wide phone size')
 end
 print('PLAYER HUD PASS '..checks..' assertions across desktop, phone, landscape and small-phone layouts')
 return checks
end
