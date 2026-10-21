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
  if k=='Destroy'then return function()p.destroyed=true end end
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
local events=signal();local purchases=0
local remote={OnClientEvent=events,FireServer=function()purchases+=1 end}
local net={WaitForChild=function(_,n)assert(n=='CashShop');return remote end}
local uis={InputBegan=signal(),GamepadEnabled=false};local gs={}
local services={Players={LocalPlayer={WaitForChild=function(_,n)assert(n=='PlayerGui');return pg end}},ReplicatedStorage={WaitForChild=function()return net end},UserInputService=uis,GuiService=gs}
local enums=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(_,n)return k..'.'..n end});rawset(t,k,v);return v end})
local env=setmetatable({game={GetService=function(_,n)return services[n]end},script={Parent=object('ScreenGui')},Instance={new=object},Enum=enums,
 UDim2={new=function(...)return{...}end,fromScale=function(x,y)return{x,y}end,fromOffset=function(x,y)return{x,y}end},UDim={new=function(...)return{...}end},Vector2={new=function(x,y)return{X=x,Y=y}end},Color3={fromRGB=function(...)return{...}end}},{__index=getfenv()})
local chunk,err=loadstring(SOURCE,'@CashShopClient.lua');assert(chunk,err);setfenv(chunk,env);chunk()
local panel=find('CashShopPanel');check(not panel.Visible,'Shop starts closed')
local data={kind='preview',available=false,configured=false,offers={
 {id='pocket',name='Pocket Cash',category='cash',cash=5000,robux=25},
 {id='stack',name='Vault Stack',category='cash',cash=20000,robux=100},
 {id='chest',name='Treasure Chest',category='cash',cash=50000,robux=250},
 {id='fortune',name='Grand Fortune',category='cash',cash=100000,robux=500},
 {id='level1',name='Base Level',category='levels',levels=1,robux=25},
 {id='level5',name='Five Base Levels',category='levels',levels=5,robux=100},
}}
for _,row in ipairs({{'dash','Dash',2},{'gravity','Pull',6},{'slow','Slow Field',8},{'slam','Ground Slam',25},{'repulse','Knockback Pulse',70},{'shield','Force Field Shield',90},{'lightning','Lightning Strike',325}})do
 data.offers[#data.offers+1]={id='power_'..row[1],name=row[2],category='powers',power=row[1],robux=row[3]}
end
local function countCards()
 local count=0
 for _,o in ipairs(instances)do if not o.destroyed and string.sub(o.Name,1,10)=='ShopOffer_'then count+=1 end end
 return count
end
local function category(key,expected)
 find('ShopCategory_'..key).Activated:Fire()
 check(countCards()==expected,'Wrong number of '..key..' offers')
 check(find('ShopOffers').CanvasSize[2]==expected*78,'All '..key..' offers remain scrollable')
 check(find('ShopOffers').CanvasPosition.X==0 and find('ShopOffers').CanvasPosition.Y==0,'Category switch resets scroll')
 for _,offer in ipairs(data.offers)do if offer.category==key then
  local card=find('ShopOffer_'..offer.id);card.Activated:Fire();check(purchases==0,'Previewing never sends purchase requests')
  local expectedText=offer.cash and('$'..offer.cash..' game cash')or(offer.levels and('+'..offer.levels..' base level'..(offer.levels==1 and''or's')))or'Unlock for your loadout'
  local found=false;for _,o in ipairs(instances)do if not o.destroyed and o.Parent==card and o.Text==expectedText then found=true end end
  check(found,'Offer effect is clear: '..offer.id)
 end end
end
events:Fire({available=true,offers=data.offers});check(not panel.Visible,'Malformed/live payload cannot open preview')
events:Fire(data);check(panel.Visible and attributes.OPActiveMenu=='cashshop','Server preview opens shared menu')
local unavailable=find('PurchasesUnavailable');check(not unavailable.Active and not unavailable.Selectable and unavailable.Text=='COMING SOON','Purchase action visibly unavailable')
check(countCards()==4,'Cash is default category')
category('cash',4);category('levels',2);category('powers',7)
check(data.offers[13].power=='lightning','Every normal nonfree power is represented')
pg:SetAttribute('OPActiveMenu','powers');check(not panel.Visible,'Opening another menu closes shop')
events:Fire(data);find('CloseCashShop').Activated:Fire();check(not panel.Visible and attributes.OPActiveMenu==nil,'Close button releases menu state')
events:Fire(data);uis.InputBegan:Fire({KeyCode=enums.KeyCode.Escape},false);check(not panel.Visible and attributes.OPActiveMenu==nil,'Escape closes')
uis.GamepadEnabled=true;events:Fire(data);check(gs.SelectedObject==find('CloseCashShop'),'Gamepad starts on close')
uis.InputBegan:Fire({KeyCode=enums.KeyCode.ButtonB},false);check(not panel.Visible,'Gamepad back closes')
for _,size in ipairs({{X=375,Y=600},{X=320,Y=500},{X=844,Y=318},{X=1920,Y=1000}})do
 find('CashShopSafeBounds').AbsoluteSize=size;events:Fire(data)
 check(panel.Size[1]<=size.X-16 and panel.Size[2]<=size.Y-24,'Panel fits safe viewport')
 for _,row in ipairs({{'cash',4},{'levels',2},{'powers',7}})do
  find('ShopCategory_'..row[1]).Activated:Fire()
  check(find('ShopOffers').CanvasSize[2]==row[2]*78,'Category scroll height correct on device')
  check(panel.Size[2]-218>0,'Scrolling list remains usable on short device')
 end
end
local malformed={kind='preview',available=false,offers={{id='bad1',name='Bad',category='items',robux=5,cash=100},{id='bad2',name='Bad',category='cash',robux=0,cash=100},{id='bad3',name='Bad',category='levels',robux=5,levels=0/0}}}
events:Fire(malformed);check(countCards()==0,'Malformed/unsupported offer categories are ignored')
check(purchases==0,'No Robux prompts or purchases across every UI interaction')
print('CashShopClient v77 passed '..checks..' assertions')
