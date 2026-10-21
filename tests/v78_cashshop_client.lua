local checks=0
local function check(v,m)checks+=1;assert(v,m)end
local function signal()
 local s={callbacks={}};function s:Connect(f)self.callbacks[#self.callbacks+1]=f;return{Disconnect=function()end}end
 function s:Fire(...)for _,f in ipairs(self.callbacks)do f(...)end end;return s
end
local instances={}
local function object(class)
 local p={Name=class,ClassName=class,AbsoluteSize={X=900,Y=700},Visible=true};local signals={};local o
 o=setmetatable({},{__index=function(_,k)
  if k=='IsA'then return function(_,c)return c==class end end
  if k=='GetPropertyChangedSignal'then return function(_,n)signals[n]=signals[n]or signal();return signals[n]end end
  if k=='Destroy'then return function()p.destroyed=true;for _,child in ipairs(instances)do if child.Parent==o then child:Destroy()end end end end
  if p[k]~=nil then return p[k]end
  if k=='Activated'then p[k]=signal();return p[k]end
 end,__newindex=function(_,k,v)local old=p[k];p[k]=v;if old~=v and signals[k]then signals[k]:Fire()end end})
 instances[#instances+1]=o;return o
end
local function find(name)for _,o in ipairs(instances)do if o.Name==name and not o.destroyed then return o end end;error('Missing '..name)end
local attributes,signals={},{};local pg={}
function pg:GetAttribute(k)return attributes[k]end
function pg:SetAttribute(k,v)local old=attributes[k];attributes[k]=v;if old~=v and signals[k]then signals[k]:Fire()end end
function pg:GetAttributeChangedSignal(k)signals[k]=signals[k]or signal();return signals[k]end
local events=signal();local purchases=0;local requests={};local tweenCount,cancelCount=0,0
local remote={OnClientEvent=events,FireServer=function(_,payload)purchases+=1;requests[#requests+1]=payload end}
local net={WaitForChild=function(_,n)assert(n=='CashShop');return remote end}
local uis={InputBegan=signal(),GamepadEnabled=false};local gs={}
local services={Players={LocalPlayer={WaitForChild=function(_,n)assert(n=='PlayerGui');return pg end}},ReplicatedStorage={WaitForChild=function()return net end},UserInputService=uis,GuiService=gs,TweenService={Create=function()tweenCount+=1;return{Play=function()end,Cancel=function()cancelCount+=1 end}end}}
local enums=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(_,n)return k..'.'..n end});rawset(t,k,v);return v end})
local env=setmetatable({game={GetService=function(_,n)return services[n]end},script={Parent=object('ScreenGui')},Instance={new=object},Enum=enums,
 TweenInfo={new=function(...)return{...}end},UDim2={new=function(...)return{...}end,fromScale=function(x,y)return{x,y}end,fromOffset=function(x,y)return{x,y}end},UDim={new=function(...)return{...}end},Vector2={new=function(x,y)return{X=x,Y=y}end},Color3={fromRGB=function(...)return{...}end}},{__index=getfenv()})
local chunk,err=loadstring(SOURCE,'@CashShopClient.lua');assert(chunk,err);setfenv(chunk,env);chunk()
local panel=find('CashShopPanel');check(not panel.Visible,'Shop starts closed')
local data={kind='catalog',available=false,configured=false,message='Products awaiting configuration.',offers={
 {id='pocket',name='Pocket Cash',category='cash',cash=5000,robux=25,icon='$',available=false},
 {id='stack',name='Vault Stack',category='cash',cash=20000,robux=100,icon='$',available=false},
 {id='chest',name='Treasure Chest',category='cash',cash=50000,robux=250,icon='$',available=false},
 {id='fortune',name='Grand Fortune',category='cash',cash=100000,robux=500,icon='$',available=false},
 {id='level1',name='Base Level',category='levels',levels=1,robux=25,icon='LV',available=false},
 {id='level5',name='Five Base Levels',category='levels',levels=5,robux=100,icon='LV',available=false},
}}
for _,row in ipairs({{'dash','Dash',2},{'gravity','Pull',6},{'slow','Slow Field',8},{'slam','Ground Slam',25},{'repulse','Knockback Pulse',70},{'shield','Force Field Shield',90},{'lightning','Lightning Strike',325},{'kiblast','Ki Blast',325},{'spinjitzu','Spinjitzu',80}})do
 data.offers[#data.offers+1]={id='power_'..row[1],name=row[2],category='powers',power=row[1],robux=row[3],rank=row[1]=='kiblast'and 5 or 4,cooldown=22,description='Visible '..row[2]..' effect.',icon=row[1]=='kiblast'and'KI'or'WIND',available=false}
end
local function countCards()
 local count=0;for _,o in ipairs(instances)do if not o.destroyed and string.sub(o.Name,1,10)=='ShopOffer_'then count+=1 end end;return count
end
local function currentOffer(index)return find('ShopOffer_'..data.offers[index].id)end
local function category(key,expected)
 find('ShopCategory_'..key).Activated:Fire()
 check(countCards()==expected,'Wrong number of '..key..' offers')
 check(find('ShopOffers').CanvasSize[2]>=expected*84,'All '..key..' offers remain scrollable')
 check(find('ShopOffers').CanvasPosition.X==0 and find('ShopOffers').CanvasPosition.Y==0,'Category switch resets scroll')
 for _,offer in ipairs(data.offers)do if offer.category==key then
  find('ShopOffer_'..offer.id).Activated:Fire();check(purchases==0,'Previewing never sends purchase requests')
  local card=find('ShopOffer_'..offer.id);local effect=false;local icon=false
  for _,o in ipairs(instances)do if not o.destroyed and o.Parent==card then
   if o.Text and(offer.category=='cash'and o.Text=='$'..offer.cash..' game cash'or offer.category=='levels'and o.Text=='+'..offer.levels..' base level'..(offer.levels==1 and''or's')or offer.category=='powers'and string.find(o.Text,'COOLDOWN',1,true))then effect=true end
   if o.Name=='OfferIcon'then icon=true end
  end end
  check(effect and icon,'Offer has clear effect/rank/cooldown and icon: '..offer.id)
  check(find('OfferDescription').Visible,'Selected offer shows its description')
 end end
end
events:Fire({available=true,offers=data.offers});check(not panel.Visible,'Malformed payload cannot open shop')
events:Fire(data);check(panel.Visible and attributes.OPActiveMenu=='cashshop','Server catalog opens shared menu')
check(find('ShopStatus').Text==data.message,'Product configuration status visible')
local buy=find('ShopBuyButton');check(not buy.Active and not buy.Selectable and buy.Text=='COMING SOON','Unconfigured purchase action unavailable')
check(countCards()==4,'Cash is default category')
category('cash',4);category('levels',2);category('powers',9)
check(data.offers[14].power=='kiblast'and data.offers[15].power=='spinjitzu','Both new normal powers are represented')
find('ShopOffer_power_kiblast').Activated:Fire();check(find('KiPreviewOrb').Visible and tweenCount>0,'Ki Blast has a short local visual preview')
local beforeReduced=tweenCount;pg:SetAttribute('OPReducedEffects',true)
find('ShopOffer_power_spinjitzu').Activated:Fire();check(find('TornadoPreviewRing4').Visible and tweenCount==beforeReduced,'Reduced effects preserve static tornado preview without animation')
pg:SetAttribute('OPReducedEffects',false)
check(cancelCount>0,'Category/selection changes cancel old preview tweens')
pg:SetAttribute('OPActiveMenu','powers');check(not panel.Visible,'Opening another menu closes shop')
events:Fire(data);find('CloseCashShop').Activated:Fire();check(not panel.Visible and attributes.OPActiveMenu==nil,'Close button releases menu state')
events:Fire(data);uis.InputBegan:Fire({KeyCode=enums.KeyCode.Escape},false);check(not panel.Visible and attributes.OPActiveMenu==nil,'Escape closes')
uis.GamepadEnabled=true;events:Fire(data);check(gs.SelectedObject==find('CloseCashShop'),'Gamepad starts on close')
uis.InputBegan:Fire({KeyCode=enums.KeyCode.ButtonB},false);check(not panel.Visible,'Gamepad back closes')
for _,size in ipairs({{X=375,Y=600},{X=320,Y=500},{X=844,Y=318},{X=1920,Y=1000}})do
 find('CashShopSafeBounds').AbsoluteSize=size;events:Fire(data)
 check(panel.Size[1]<=size.X-16 and panel.Size[2]<=size.Y-24,'Panel fits safe viewport')
 for _,row in ipairs({{'cash',4},{'levels',2},{'powers',9}})do
  find('ShopCategory_'..row[1]).Activated:Fire()
  check(find('ShopOffers').CanvasSize[2]>=row[2]*84,'Category scroll height correct on device')
  check(panel.Size[2]-236>0,'Scrolling list remains usable on short device')
 end
end
local malformed={kind='catalog',available=false,configured=false,offers={{id='bad1',name='Bad',category='items',robux=5,cash=100},{id='bad2',name='Bad',category='cash',robux=0,cash=100},{id='bad3',name='Bad',category='levels',robux=5,levels=0/0},{id='dev',name='Royal Seal',category='powers',robux=5,power='royalseal'},{id='tag',name='Tag',category='powers',robux=5,power='tag'}}}
events:Fire(malformed);check(countCards()==0,'Malformed, conveyor and developer offer categories are ignored')
check(purchases==0,'No purchases across preview interactions')
-- Live configuration permits only a request for the selected server offer.
data.available=true;data.configured=true
for _,offer in ipairs(data.offers)do offer.available=true;offer.priceVerified=true end
events:Fire(data);find('ShopCategory_powers').Activated:Fire();find('ShopOffer_power_kiblast').Activated:Fire()
check(buy.Active and buy.Text=='BUY · 325 ROBUX','Server-available offer enables purchase action')
check(gs.SelectedObject==find('ShopOffer_power_kiblast'),'Rebuilt selected card preserves controller focus')
buy.Activated:Fire();buy.Activated:Fire()
check(purchases==1 and requests[1].kind=='buy'and requests[1].id=='power_kiblast','Purchase requests contain only the selected offer ID')
check(requests[1].amount==nil and requests[1].productId==nil and not buy.Active,'Client never grants rewards or supplies products; pending request guarded')
events:Fire({kind='result',ok=false,message='Please wait.'})
check(find('ShopStatus').Text=='Please wait.'and buy.Active,'Server rejection clears pending UI and explains failure')
data.offers[14].owned=true;data.offers[14].available=false;events:Fire(data)
check(buy.Text=='ALREADY OWNED'and not buy.Active,'Owned powers cannot be repurchased from menu')
buy.Activated:Fire();check(purchases==1,'Owned action never sends another purchase')
find('ShopCategory_levels').Activated:Fire();find('ShopOffer_level1').Activated:Fire()
data.offers[5].available=false;data.offers[5].reason='Maximum level';events:Fire(data)
check(buy.Text=='Maximum level'and not buy.Active,'Level-cap reason disables action')
find('CloseCashShop').Activated:Fire();data.open=false;events:Fire(data)
check(not panel.Visible and attributes.OPActiveMenu==nil,'Receipt catalog refresh never forces a closed menu open')
events:Fire({kind='result',ok=true,message='Purchase saved.'})
check(not panel.Visible and find('ShopStatus').Text=='Purchase saved.','Receipt result updates without blocking gameplay')
print('CashShopClient v78 passed '..checks..' assertions')
