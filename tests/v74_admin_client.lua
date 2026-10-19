-- tools/run_admin_client_checks.py embeds the production LocalScript verbatim as SOURCE.
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
local player={CharacterAdded=signal()}
local keys,focused={},nil
local UIS={InputBegan=signal(),InputEnded=signal(),WindowFocused=signal(),WindowFocusReleased=signal(),TextBoxFocused=signal(),TouchEnabled=true,
 GetFocusedTextBox=function()return focused end,IsKeyDown=function(_,key)return keys[key]or false end}
local Run={Heartbeat=signal()}
local workspace={CurrentCamera={ViewportSize=Vector2.new(900,900),CFrame={LookVector=vector(0,0,-1),RightVector=vector(1,0,0)}}}
local workspaceSignal,cameraSignal=signal(),signal()
workspace.GetPropertyChangedSignal=function()return workspaceSignal end
workspace.CurrentCamera.GetPropertyChangedSignal=function()return cameraSignal end
local services={Players={LocalPlayer=player},ReplicatedStorage={WaitForChild=function()return net end},UserInputService=UIS,RunService=Run,HttpService={JSONEncode=function()return 'json data' end}}
local env=setmetatable({game={GetService=function(_,name)return services[name]end},workspace=workspace,script={Parent=object('ScreenGui')},
 Instance={new=object},Enum=Enum,UDim2=UDim2,UDim={new=function(...)return{...}end},Vector2=Vector2,Vector3=Vector3,
 Color3={new=function(...)return{...}end,fromRGB=function(...)return{...}end}}, {__index=getfenv()})
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
response.OnClientEvent:Fire({ok=true,authorized=true,data={catalog={{id='transformers_allspark',name='Transformers AllSpark',rarity='Mythic',tier=6},{id='item08',name='Millennium Puzzle',tier=5}},powers={{id='tag',name='Tag',cooldown=4}}},mods={flight=false,noclip=false,god=false,speed=16,jump=50}})
expect(toggle.Visible and not panel.Visible,'Verified UI stays collapsed')
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
player.CharacterAdded:Fire();local beforeRespawn=#sent;Run.Heartbeat:Fire(.2)
expect(#sent==beforeRespawn and not find('DeveloperFlightTouch').Visible,'Respawn resets local movement')
response.OnClientEvent:Fire({authorized=false,ok=false});expect(not toggle.Visible and not panel.Visible,'Revocation closes and hides menu')
UIS.InputBegan:Fire({KeyCode=Enum.KeyCode.F8});find('heal').Activated:Fire();Run.Heartbeat:Fire(.2)
expect(#sent==beforeRespawn,'Revoked client cannot command or move')
print('AdminClient UI behavior passed '..assertions..' assertions')
