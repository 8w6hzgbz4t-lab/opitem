-- tools/run_v75_admin_client_checks.py embeds the production LocalScript verbatim as SOURCE.
-- Only Roblox GUI/input services are adapted; all request-building logic is real.
local assertions=0
local function expect(value,message) assertions+=1;assert(value,message) end
local function signal()
 local s={callbacks={}}
 function s:Connect(callback) table.insert(self.callbacks,callback);return {Disconnect=function() end} end
 function s:Fire(...) for _,callback in ipairs(self.callbacks) do callback(...) end end
 return s
end
local vectorMt={}
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMt) end
vectorMt.__index=function(v,k)
 if k=='Magnitude' then return math.sqrt(v.X^2+v.Y^2+v.Z^2) end
 if k=='Unit' then local m=v.Magnitude;return vector(v.X/m,v.Y/m,v.Z/m) end
end
vectorMt.__add=function(a,b)return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vectorMt.__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vectorMt.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return vector(a.X*b,a.Y*b,a.Z*b)end
local Vector3={new=vector,zero=vector(0,0,0),yAxis=vector(0,1,0)}
local Vector2={new=function(x,y)return{X=x,Y=y}end,zero={X=0,Y=0}}
local UDim2={new=function(...)return{...}end,fromOffset=function(x,y)return{x,y}end,fromScale=function(x,y)return{x,y}end}
local Enum=setmetatable({},{__index=function(t,k)local e=setmetatable({},{__index=function(_,n)return k..'.'..n end});rawset(t,k,e);return e end})
local instances={}
local function object(class)
 local properties={ClassName=class,Name=class,Visible=true,Text=''}
 local signals={}
 local o
 o=setmetatable({}, {
  __index=function(_,key)
   if key=='GetPropertyChangedSignal' then return function(_,property) signals[property]=signals[property]or signal();return signals[property]end end
   if key=='Destroy' then return function()properties.destroyed=true end end
   if key=='CaptureFocus' then return function() end end
   if properties[key]~=nil then return properties[key] end
   if key=='Activated' or key=='InputBegan' or key=='InputEnded' or key=='MouseLeave' or key=='FocusLost' then properties[key]=signal();return properties[key]end
  end,
  __newindex=function(_,key,value)local old=properties[key];properties[key]=value;if old~=value and signals[key]then signals[key]:Fire()end end,
 })
 table.insert(instances,o)
 return o
end
local function find(name)
 for _,o in ipairs(instances)do if o.Name==name and not o.destroyed then return o end end
 error('Missing instance '..name)
end
local sent={}
local request={FireServer=function(_,payload)table.insert(sent,payload)end}
local response={OnClientEvent=signal()}
local net={WaitForChild=function(_,name)return name=='AdminRequest' and request or response end}
local attributes, attributeSignals = {}, {}
local playerGui = {}
function playerGui:GetAttribute(key) return attributes[key] end
function playerGui:SetAttribute(key,value)
 local old=attributes[key];attributes[key]=value
 if old~=value and attributeSignals[key] then attributeSignals[key]:Fire() end
end
function playerGui:GetAttributeChangedSignal(key) attributeSignals[key]=attributeSignals[key] or signal();return attributeSignals[key] end
local player={UserId=77,CharacterAdded=signal(),WaitForChild=function(_,name)assert(name=='PlayerGui');return playerGui end}
local keys,focused={},nil
local UIS={InputBegan=signal(),InputEnded=signal(),WindowFocused=signal(),WindowFocusReleased=signal(),TextBoxFocused=signal(),TouchEnabled=true,
 GetFocusedTextBox=function()return focused end,IsKeyDown=function(_,key)return keys[key]or false end}
local Run={Heartbeat=signal()}
local workspace={CurrentCamera={ViewportSize=Vector2.new(900,900),CFrame={LookVector=vector(0,0,-1),RightVector=vector(1,0,0)}}}
local workspaceSignal,cameraSignal=signal(),signal()
workspace.GetPropertyChangedSignal=function()return workspaceSignal end
workspace.CurrentCamera.GetPropertyChangedSignal=function()return cameraSignal end
local guid=0
local delayed={}
local now=10
local services={Players={LocalPlayer=player},ReplicatedStorage={WaitForChild=function()return net end},UserInputService=UIS,RunService=Run,HttpService={JSONEncode=function()return 'json data' end,GenerateGUID=function()guid+=1;return 'request-id-'..guid end}}
local env=setmetatable({game={GetService=function(_,name)return services[name]end},workspace=workspace,script={Parent=object('ScreenGui')},
 Instance={new=object},Enum=Enum,UDim2=UDim2,UDim={new=function(...)return{...}end},Vector2=Vector2,Vector3=Vector3,
 Color3={new=function(...)return{...}end,fromRGB=function(...)return{...}end},
 os={clock=function()return now end},task={delay=function(delay,callback)table.insert(delayed,{at=now+delay,callback=callback})end}}, {__index=getfenv()})
local chunk,err=loadstring(SOURCE,'@AdminClient.lua');assert(chunk,err);setfenv(chunk,env);chunk()
local panel,toggle=find('DeveloperMenu'),find('DeveloperToggle')
workspace.CurrentCamera.ViewportSize=Vector2.new(375,667);cameraSignal:Fire()
expect(panel.Size[1]==351 and panel.Size[2]==583, 'Phone layout uses available space at native text size')
workspace.CurrentCamera.ViewportSize=Vector2.new(900,900);cameraSignal:Fire()
expect(#sent==1 and sent[1].mode=='hello','Only hello before authorization')
expect(not panel.Visible and not toggle.Visible,'UI hidden before authorization')
UIS.InputBegan:Fire({KeyCode=Enum.KeyCode.F8});expect(not panel.Visible,'F8 gated before authorization')
find('heal').Activated:Fire();expect(#sent==1,'Commands gated before authorization')
Run.Heartbeat:Fire(.2);expect(#sent==1,'Movement gated before authorization')
response.OnClientEvent:Fire({authorized=false,ok=false,message='Access denied.'})
expect(#sent==1 and not panel.Visible and not toggle.Visible,'Denied hello leaves all controls hidden')
response.OnClientEvent:Fire({ok=true,authorized=true,data={players={{userId=77,name='Goverment_cheesee',displayName='Developer',level=0,cash=650},{userId=88,name='Friend',displayName='Player Two',level=3,cash=100}},uniquePower={id='royalseal',name='Royal Seal',cooldown=15,remaining=0},catalog={{id='transformers_allspark',name='Transformers AllSpark',rarity='Mythic',tier=6},{id='item08',name='Millennium Puzzle',tier=5}},powers={{id='tag',name='Tag',cooldown=4}}},mods={flight=false,noclip=false,god=false,speed=16,jump=50}})
expect(toggle.Visible and not panel.Visible,'Verified UI stays collapsed')
expect(toggle.Text=='DEVELOPER  ·  F8' and toggle.Position[2]==-164 and toggle.Position[4]==8,'Developer toggle is readable and anchored in reserved top-right')
expect(find('DeveloperHint').Visible,'First authorization shows nonblocking discoverability hint')
toggle.Activated:Fire();expect(panel.Visible,'Verified DEV opens menu')
UIS.InputBegan:Fire({KeyCode=Enum.KeyCode.F8});expect(not panel.Visible,'F8 closes verified menu')
find('flight').Activated:Fire();expect(sent[#sent].text=='flight on','Flight toggle on command')
response.OnClientEvent:Fire({ok=true,mods={flight=true,noclip=false,god=false,speed=32,jump=75}})
expect(find('DeveloperFlightTouch').Visible,'Touch controls shown while flying')
keys[Enum.KeyCode.W]=true;Run.Heartbeat:Fire(.2)
expect(sent[#sent].mode=='move'and sent[#sent].direction.Z==-1,'Flight forward sends camera direction')
UIS.WindowFocusReleased:Fire();local afterFocus=#sent;Run.Heartbeat:Fire(.2)
expect(#sent==afterFocus and sent[#sent].direction.Magnitude==0,'Focus loss stops flight and sends no new movement')
UIS.WindowFocused:Fire();keys[Enum.KeyCode.W]=false
local touch={UserInputType=Enum.UserInputType.Touch}
find('FlightUp').InputBegan:Fire(touch);Run.Heartbeat:Fire(.2)
expect(sent[#sent].direction.Y==1,'Touch flight up works')
UIS.InputEnded:Fire(touch);Run.Heartbeat:Fire(.2)
expect(sent[#sent].direction.Magnitude==0,'Global input end releases touch flight')
local secondTouch={UserInputType=Enum.UserInputType.Touch}
find('FlightUp').InputBegan:Fire(touch);find('FlightRight').InputBegan:Fire(secondTouch);Run.Heartbeat:Fire(.2)
expect(math.abs(sent[#sent].direction.Magnitude-1)<.00001 and sent[#sent].direction.X>0 and sent[#sent].direction.Y>0,'Simultaneous touch directions combine and normalize')
UIS.InputEnded:Fire(secondTouch);Run.Heartbeat:Fire(.2)
expect(sent[#sent].direction.X==0 and sent[#sent].direction.Y==1,'Releasing one touch preserves the other')
UIS.TextBoxFocused:Fire();Run.Heartbeat:Fire(.2)
expect(sent[#sent].direction.Magnitude==0,'Focusing a textbox clears all held touch inputs')
find('flight').Activated:Fire();expect(sent[#sent].text=='flight off','Enabled flight button requests off')
find('noclip').Activated:Fire();expect(sent[#sent].text=='noclip on','Noclip toggle requests on')
find('immunity').Activated:Fire();expect(sent[#sent].text=='god on','Ability immunity toggle requests on')
for _,id in ipairs({'heal','home','resetmods'})do
 find(id).Activated:Fire();expect(sent[#sent].text==id,'Developer control command '..id)
end
for _,id in ipairs({'tag','dash','gravity','slow','slam','repulse','shield','lightning'})do
 find('cast_'..id).Activated:Fire();expect(sent[#sent].text=='cast '..id,'Power button '..id)
end
find('unlockPowers').Activated:Fire();expect(sent[#sent].text=='powers','Unlock command')
find('resetCooldowns').Activated:Fire();expect(sent[#sent].text=='cooldowns','Cooldown command')
find('item_transformers_allspark').Activated:Fire()
local grant,offer,input,confirm
for _,o in ipairs(instances)do
 if o.Text=='GRANT 1 TO MY BASE'then grant=o end
 if o.Text=='SPAWN ON BELT'then offer=o end
 if o.PlaceholderText=='Enter a server command'then input=o end
 if o.Text=='CONFIRM EXACT COMMAND'then confirm=o end
end
expect(grant~=nil and offer~=nil,'Catalog actions exist')
grant.Activated:Fire();expect(sent[#sent].text=='grant self transformers_allspark 1','Grant uses actual selected catalog ID')
offer.Activated:Fire();expect(sent[#sent].text=='offer transformers_allspark','Offer uses actual selected catalog ID')
response.OnClientEvent:Fire({ok=false,message='Confirm',confirmation='abc123',command='cash self set 0'})
expect(panel.Visible and input.Text=='cash self set 0','Confirmation shows canonical command')
confirm.Activated:Fire();expect(sent[#sent].text=='cash self set 0'and sent[#sent].confirmation=='abc123','Confirmation sends exact command and token')
response.OnClientEvent:Fire({ok=false,confirmation='new-token',command='cash self set 0'})
input.Text='cash self add 50';local beforeConfirm=#sent;confirm.Activated:Fire()
expect(#sent==beforeConfirm,'Input edit cancels destructive confirmation')
-- New v75 navigation, flight affordance, gifting and signature power controls.
expect(playerGui:GetAttribute('OPDeveloperFlight')==true,'Verified flight state is shared with normal HUD hotkeys')
expect(find('DeveloperLand').Visible and find('DeveloperLand').Position[4]==50,'Desktop flight land chip remains visible without the menu')
workspace.CurrentCamera.ViewportSize=Vector2.new(375,667);cameraSignal:Fire()
expect(find('DeveloperLand').Position[4]==148,'Phone flight chip clears navigation and powers rows')
workspace.CurrentCamera.ViewportSize=Vector2.new(900,900);cameraSignal:Fire()
find('DeveloperLand').Activated:Fire();expect(sent[#sent].text=='flight off','Obvious land button disables flight')
-- Opening one menu closes the other and back/close releases its ownership.
playerGui:SetAttribute('OPActiveMenu','inventory')
toggle.Activated:Fire();expect(playerGui:GetAttribute('OPActiveMenu')=='developer','Developer owns shared menu state on open')
playerGui:SetAttribute('OPActiveMenu','powers');expect(not panel.Visible,'Player power menu hides developer menu')
toggle.Activated:Fire();expect(panel.Visible and playerGui:GetAttribute('OPActiveMenu')=='developer','Developer toggle reopens and claims navigation')
find('DeveloperClose').Activated:Fire();expect(not panel.Visible and playerGui:GetAttribute('OPActiveMenu')==nil,'Close releases menu ownership')
toggle.Activated:Fire()
find('DeveloperTab_Gifts').Activated:Fire();expect(sent[#sent].text=='state','Gift tab refreshes actual online players')
expect(find('Gifts').Visible and not find('Flight').Visible,'Tab navigation shows one developer page')
local cashAmount,levelAmount=find('GiftCashAmount'),find('GiftLevelAmount')
local beforeGift=#sent;find('GiftCash').Activated:Fire();expect(#sent==beforeGift,'Gifts require explicit player selection')
find('GiftPlayer_88').Activated:Fire();expect(string.find(find('GiftTargetLabel').Text,'Player Two',1,true)~=nil,'Target name is clear and selected from server data')
for _,invalid in ipairs({'0','-1','1.5','NaN','2000000001'})do
 cashAmount.Text=invalid;local before=#sent;find('GiftCash').Activated:Fire();expect(#sent==before,'Invalid money amount rejected locally '..invalid)
end
cashAmount.Text='2500';find('GiftCash').Activated:Fire()
local firstGift=sent[#sent]
expect(firstGift.text=='giftcash 88 2500' and type(firstGift.requestId)=='string'and #firstGift.requestId>=8,'Money gift uses selected server UserId, whole amount and unique request ID')
expect(find('GiftCash').Active==false and find('GiftLevels').Active==false,'Gift controls disabled while awaiting result')
local duplicate=#sent;find('GiftCash').Activated:Fire();find('GiftLevels').Activated:Fire();expect(#sent==duplicate,'Rapid duplicate gift clicks send no second request')
response.OnClientEvent:Fire({ok=true,requestId='unrelated-id',mods={flight=true}})
expect(find('GiftCash').Active==false,'Unrelated reply does not release pending gift')
response.OnClientEvent:Fire({ok=true,requestId=firstGift.requestId,message='Gifted $2500 to Player Two.',players={{userId=77,name='Goverment_cheesee',displayName='Developer',level=0},{userId=88,name='Friend',displayName='Player Two',level=3}}})
expect(find('GiftCash').Active and find('GiftLevels').Active,'Matching gift result releases gift controls')
expect(string.find(find('GiftStatus').Text,'2500',1,true)~=nil and find('Gifts').Visible,'Gift confirmation stays on current page')
expect(string.find(find('GiftTargetLabel').Text,'Player Two',1,true)~=nil,'Player refresh preserves selected existing target')
levelAmount.Text='101';local invalidLevels=#sent;find('GiftLevels').Activated:Fire();expect(#sent==invalidLevels,'Level gift rejects more than 100 levels')
levelAmount.Text='2';find('GiftLevels').Activated:Fire();local secondGift=sent[#sent]
expect(secondGift.text=='giftlevels 88 2' and secondGift.requestId~=firstGift.requestId,'Level gift uses correct command and fresh request ID')
response.OnClientEvent:Fire({ok=false,requestId=secondGift.requestId,message='Player left.',players={{userId=77,name='Goverment_cheesee',displayName='Developer',level=0}}})
expect(find('GiftCash').Active and string.find(find('GiftTargetLabel').Text,'left',1,true)~=nil,'Departed target is cleared and retry controls restored')
local missingTarget=#sent;find('GiftLevels').Activated:Fire();expect(#sent==missingTarget,'Departed target cannot be gifted again')
find('GiftPlayer_77').Activated:Fire();cashAmount.Text='100';find('GiftCash').Activated:Fire();local selfGift=sent[#sent]
expect(selfGift.text=='giftcash 77 100','Developer can select and gift self through same checked route')
response.OnClientEvent:Fire({ok=true,requestId=selfGift.requestId,message='Gifted.',mods={royalSealRemaining=0}})
cashAmount.Text='200';find('GiftCash').Activated:Fire();local slowGift=sent[#sent]
now+=10.1;Run.Heartbeat:Fire(.2)
expect(find('RetryGift').Visible and not find('GiftCash').Active,'Slow gift keeps the original pending ID and offers a safe result check')
find('RetryGift').Activated:Fire();expect(sent[#sent].requestId==slowGift.requestId and sent[#sent].text==slowGift.text,'Checking a slow gift resends the same deduplicated request ID')
response.OnClientEvent:Fire({ok=true,requestId=slowGift.requestId,message='Gift result recovered.'})
expect(find('GiftCash').Active and not find('RetryGift').Visible,'Recovered gift reply safely re-enables controls')
find('RoyalSeal').Activated:Fire();expect(sent[#sent].text=='royalseal','Unique power button sends Royal Seal command')
response.OnClientEvent:Fire({ok=true,mods={royalSealRemaining=15}});Run.Heartbeat:Fire(.2)
expect(find('RoyalSeal').Text=='ROYAL SEAL · 15s' and not find('RoyalSeal').Active,'Unique power shows server-reported cooldown')
local cooling=#sent;find('RoyalSeal').Activated:Fire();expect(#sent==cooling,'Unique power blocks clicks during displayed cooldown')
now+=15.1;Run.Heartbeat:Fire(.2);expect(find('RoyalSeal').Text=='CAST ROYAL SEAL'and find('RoyalSeal').Active,'Unique power returns to ready when countdown ends')
-- Metadata refresh does not lose catalog selection or change the open page.
find('item_item08').Activated:Fire()
response.OnClientEvent:Fire({ok=true,data={catalog={{id='item08',name='Millennium Puzzle',tier=5},{id='stardust_dragon',name='Stardust Dragon',tier=5},{id='moms_credit_card',name='Moms Credit Card',tier=7}}}})
grant.Activated:Fire();expect(sent[#sent].text=='grant self item08 1','Refreshing catalog preserves selected item by stable ID')
find('item_stardust_dragon').Activated:Fire();offer.Activated:Fire();expect(sent[#sent].text=='offer stardust_dragon','New dragon is selectable without hardcoded old item limit')
player.CharacterAdded:Fire();local beforeRespawn=#sent;Run.Heartbeat:Fire(.2)
expect(#sent==beforeRespawn and not find('DeveloperFlightTouch').Visible and playerGui:GetAttribute('OPDeveloperFlight')==false and not find('DeveloperLand').Visible,'Respawn resets local movement and HUD flight marker')
response.OnClientEvent:Fire({authorized=false,ok=false});expect(not toggle.Visible and not panel.Visible,'Revocation closes and hides menu')
UIS.InputBegan:Fire({KeyCode=Enum.KeyCode.F8});find('heal').Activated:Fire();Run.Heartbeat:Fire(.2)
expect(#sent==beforeRespawn,'Revoked client cannot command or move')
print('AdminClient v75 UI behavior passed '..assertions..' assertions')
