local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService');local Run=game:GetService('RunService');local Http=game:GetService('HttpService')
local player=Players.LocalPlayer;local net=RS:WaitForChild('OPItemNet')
local request=net:WaitForChild('AdminRequest');local response=net:WaitForChild('AdminResponse')
local gui=script.Parent;gui.IgnoreGuiInset=false
local function label(parent,text,size)
 local t=Instance.new('TextLabel');t.Size=size;t.BackgroundTransparency=1;t.Text=text;t.TextColor3=Color3.fromRGB(235,240,255)
 t.Font=Enum.Font.Gotham;t.TextSize=14;t.TextWrapped=true;t.Parent=parent;return t
end
local function button(parent,text,size,callback)
 local b=Instance.new('TextButton');b.Size=size;b.BackgroundColor3=Color3.fromRGB(54,65,98);b.TextColor3=Color3.new(1,1,1)
 b.Text=text;b.Font=Enum.Font.GothamBold;b.TextSize=13;b.Parent=parent;b.Activated:Connect(callback);return b
end
local panel=Instance.new('Frame');panel.Size=UDim2.fromScale(.88,.84);panel.Position=UDim2.fromScale(.06,.08)
 panel.BackgroundColor3=Color3.fromRGB(21,25,43);panel.Visible=false;panel.Parent=gui
local title=label(panel,'DEVELOPER CONSOLE — server verified',UDim2.new(1,-52,0,35));title.TextXAlignment=Enum.TextXAlignment.Left
button(panel,'X',UDim2.fromOffset(40,32),function() panel.Visible=false end).Position=UDim2.new(1,-44,0,2)
local scroll=Instance.new('ScrollingFrame');scroll.Position=UDim2.fromOffset(8,40);scroll.Size=UDim2.new(1,-16,1,-48)
 scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.CanvasSize=UDim2.new();scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.ScrollBarThickness=5;scroll.Parent=panel
local layout=Instance.new('UIListLayout');layout.Padding=UDim.new(0,5);layout.Parent=scroll
label(scroll,'Use numeric UserIds or self. Item IDs: item01–item41. Commands run on this server only. F8 opens/closes. Flight: WASD + Q/E; touch controls below.',UDim2.new(1,-8,0,65))
local input=Instance.new('TextBox');input.Size=UDim2.new(1,-8,0,44);input.Text='help';input.PlaceholderText='Enter a command'
 input.ClearTextOnFocus=false;input.TextSize=14;input.Font=Enum.Font.Code;input.TextColor3=Color3.new(1,1,1);input.BackgroundColor3=Color3.fromRGB(37,43,66);input.Parent=scroll
local pending
local function run() pending=nil;request:FireServer({mode='command',text=input.Text}) end
button(scroll,'EXECUTE COMMAND',UDim2.new(1,-8,0,36),run)
local confirm=button(scroll,'CONFIRM EXACT DESTRUCTIVE COMMAND',UDim2.new(1,-8,0,36),function()
 if pending then local p=pending;pending=nil;request:FireServer({mode='command',text=p.command,confirmation=p.token}) end
end);confirm.Visible=false;confirm.BackgroundColor3=Color3.fromRGB(140,58,59)
input:GetPropertyChangedSignal('Text'):Connect(function() pending=nil;confirm.Visible=false end)
input.FocusLost:Connect(function(enter) if enter then run() end end)
local output=label(scroll,'Waiting for server…',UDim2.new(1,-8,0,100));output.TextXAlignment=Enum.TextXAlignment.Left;output.TextYAlignment=Enum.TextYAlignment.Top;output.AutomaticSize=Enum.AutomaticSize.Y;output.Font=Enum.Font.Code
local templates={
 'help','state','logs 20','inventory self','cash self add 1000','cash self remove 1000','cash self set 650',
 'grant self item17 1','remove self relic2','offer item41','teleport self 0 5 15','flight on','flight off','noclip on','noclip off',
 'protect self 60','protect self 0','announce Welcome to the arena!','kick USERID reason','ban USERID reason','unban USERID',
}
for _,command in ipairs(templates) do button(scroll,command,UDim2.new(1,-8,0,28),function() input.Text=command end) end
local touchDirection=Vector3.zero
local touch={Forward=Vector3.new(0,0,-1),Back=Vector3.new(0,0,1),Left=Vector3.new(-1,0,0),Right=Vector3.new(1,0,0),Up=Vector3.new(0,1,0),Down=Vector3.new(0,-1,0)}
for name,dir in pairs(touch) do
 local b=button(scroll,'FLIGHT HOLD: '..name,UDim2.new(1,-8,0,30),function() end)
 b.MouseButton1Down:Connect(function() touchDirection=dir end)
 b.MouseButton1Up:Connect(function() touchDirection=Vector3.zero end)
 b.MouseLeave:Connect(function() touchDirection=Vector3.zero end)
end
local toggle=button(gui,'DEV / F8',UDim2.fromOffset(94,30),function() panel.Visible=not panel.Visible end)
toggle.Position=UDim2.new(1,-104,1,-106);toggle.Visible=false
local flight=false
response.OnClientEvent:Connect(function(reply)
 if reply.authorized then toggle.Visible=true end
 output.Text=(reply.ok and 'OK: ' or 'NOTICE: ')..(reply.message or '')
 if reply.data then local ok,json=pcall(Http.JSONEncode,Http,reply.data);if ok then output.Text=output.Text..'\n'..json end end
 if reply.confirmation then pending={token=reply.confirmation,command=reply.command};confirm.Visible=true;panel.Visible=true else confirm.Visible=false end
 if reply.flight~=nil then flight=reply.flight end
end)
UIS.InputBegan:Connect(function(key,processed)
 if key.KeyCode==Enum.KeyCode.F8 and not UIS:GetFocusedTextBox() then panel.Visible=not panel.Visible end
end)
local acc=0
Run.Heartbeat:Connect(function(dt)
 acc+=dt;if acc<.1 then return end;acc=0
 if not flight then return end
 local camera=workspace.CurrentCamera;if not camera then return end
 local d=Vector3.zero
 if not UIS:GetFocusedTextBox() then
  if UIS:IsKeyDown(Enum.KeyCode.W) then d+=camera.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.S) then d-=camera.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.D) then d+=camera.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.A) then d-=camera.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.E) then d+=Vector3.yAxis end
  if UIS:IsKeyDown(Enum.KeyCode.Q) then d-=Vector3.yAxis end
 end
 d+=camera.CFrame.RightVector*touchDirection.X+Vector3.yAxis*touchDirection.Y-camera.CFrame.LookVector*touchDirection.Z
 if d.Magnitude>1 then d=d.Unit end
 request:FireServer({mode='move',direction=d})
end)
request:FireServer({mode='hello'})
