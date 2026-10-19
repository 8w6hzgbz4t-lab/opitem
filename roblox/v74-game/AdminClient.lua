-- Only AdminService injects this LocalScript, and no control opens before server verification.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local UIS = game:GetService('UserInputService')
local Run = game:GetService('RunService')
local Http = game:GetService('HttpService')
local player = Players.LocalPlayer
local net = RS:WaitForChild('OPItemNet')
local request = net:WaitForChild('AdminRequest')
local response = net:WaitForChild('AdminResponse')
local gui = script.Parent
local verified, flight, windowFocused = false, false, true
local mods = {flight=false, noclip=false, god=false}
local pending, selectedItem
local touchInputs = {}
local palette = {
 background=Color3.fromRGB(16,23,39), surface=Color3.fromRGB(28,38,57),
 raised=Color3.fromRGB(40,53,75), gold=Color3.fromRGB(224,189,108),
 text=Color3.fromRGB(238,241,248), muted=Color3.fromRGB(164,180,202),
 active=Color3.fromRGB(36,99,87), danger=Color3.fromRGB(139,54,55),
}
gui.IgnoreGuiInset = false

local function round(object, radius)
 local corner = Instance.new('UICorner')
 corner.CornerRadius = UDim.new(0, radius or 8)
 corner.Parent = object
end
local function label(parent, text, size)
 local object = Instance.new('TextLabel')
 object.BackgroundTransparency = 1
 object.Size = size
 object.Text = text
 object.Font = Enum.Font.Gotham
 object.TextSize = 13
 object.TextColor3 = palette.text
 object.TextWrapped = true
 object.TextXAlignment = Enum.TextXAlignment.Left
 object.RichText = false
 object.Parent = parent
 return object
end
local function button(parent, text, size, callback)
 local object = Instance.new('TextButton')
 object.Size = size
 object.BackgroundColor3 = palette.raised
 object.BorderSizePixel = 0
 object.TextColor3 = palette.text
 object.Text = text
 object.TextSize = 13
 object.Font = Enum.Font.GothamBold
 object.TextWrapped = true
 object.AutoButtonColor = true
 object.Parent = parent
 round(object, 7)
 object.Activated:Connect(callback)
 return object
end
local function textbox(parent, text, placeholder)
 local object = Instance.new('TextBox')
 object.Size = UDim2.new(1, 0, 0, 42)
 object.Text = text
 object.PlaceholderText = placeholder
 object.ClearTextOnFocus = false
 object.MultiLine = false
 object.TextTruncate = Enum.TextTruncate.AtEnd
 object.TextSize = 14
 object.Font = Enum.Font.Code
 object.TextColor3 = palette.text
 object.PlaceholderColor3 = palette.muted
 object.BackgroundColor3 = palette.raised
 object.BorderSizePixel = 0
 object.Parent = parent
 round(object, 7)
 local padding = Instance.new('UIPadding')
 padding.PaddingLeft = UDim.new(0, 10)
 padding.PaddingRight = UDim.new(0, 10)
 padding.Parent = object
 return object
end
local function list(parent, gap)
 local layout = Instance.new('UIListLayout')
 layout.Padding = UDim.new(0, gap or 8)
 layout.SortOrder = Enum.SortOrder.LayoutOrder
 layout.Parent = parent
 return layout
end
local function row(parent, height)
 local frame = Instance.new('Frame')
 frame.BackgroundTransparency = 1
 frame.Size = UDim2.new(1, -8, 0, height or 42)
 frame.Parent = parent
 return frame
end
local function description(parent, text, height)
 local object = label(parent, text, UDim2.new(1, -8, 0, height or 42))
 object.TextColor3 = palette.muted
 return object
end

local panel = Instance.new('Frame')
panel.Name = 'DeveloperMenu'
panel.AnchorPoint = Vector2.new(.5, .5)
panel.Position = UDim2.fromScale(.5, .5)
panel.Size = UDim2.fromOffset(520, 620)
panel.BackgroundColor3 = palette.background
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
round(panel, 12)
local bounds = Instance.new('UISizeConstraint')
bounds.MinSize = Vector2.new(300, 360)
bounds.MaxSize = Vector2.new(520, 620)
bounds.Parent = panel
local scale = Instance.new('UIScale')
scale.Parent = panel
local outline = Instance.new('UIStroke')
outline.Color = palette.gold
outline.Transparency = .35
outline.Thickness = 1
outline.Parent = panel
local title = label(panel, 'DEVELOPER', UDim2.new(1, -70, 0, 25))
title.Position = UDim2.fromOffset(16, 10)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = palette.gold
local verifiedLabel = label(panel, 'Server verified · this server only', UDim2.new(1, -70, 0, 20))
verifiedLabel.Position = UDim2.fromOffset(16, 34)
verifiedLabel.TextSize = 11
verifiedLabel.TextColor3 = palette.muted

local function stopTouch()
 table.clear(touchInputs)
 if verified and flight then request:FireServer({mode='move', direction=Vector3.zero}) end
end
local close = button(panel, '×', UDim2.fromOffset(38, 38), function()
 panel.Visible = false
 stopTouch()
end)
close.Position = UDim2.new(1, -50, 0, 12)
close.TextSize = 24

local tabBar = Instance.new('Frame')
tabBar.BackgroundTransparency = 1
tabBar.Position = UDim2.fromOffset(12, 64)
tabBar.Size = UDim2.new(1, -24, 0, 36)
tabBar.Parent = panel
local tabLayout = Instance.new('UIGridLayout')
tabLayout.CellPadding = UDim2.fromOffset(6, 0)
tabLayout.CellSize = UDim2.new(.25, -5, 1, 0)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar
local body = Instance.new('Frame')
body.Name = 'Pages'
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(12, 110)
body.Size = UDim2.new(1, -24, 1, -232)
body.Parent = panel
local pages, tabButtons = {}, {}
local function showPage(name)
 for key, page in pairs(pages) do
  page.Visible = key == name
  tabButtons[key].BackgroundColor3 = key == name and palette.active or palette.surface
  tabButtons[key].TextColor3 = key == name and palette.gold or palette.text
 end
end
local function page(name)
 local frame = Instance.new('ScrollingFrame')
 frame.Name = name
 frame.Size = UDim2.fromScale(1, 1)
 frame.BackgroundTransparency = 1
 frame.BorderSizePixel = 0
 frame.CanvasSize = UDim2.new()
 frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
 frame.ScrollBarThickness = 4
 frame.ScrollBarImageColor3 = palette.gold
 frame.ScrollingDirection = Enum.ScrollingDirection.Y
 frame.Visible = false
 frame.Parent = body
 list(frame)
 pages[name] = frame
 tabButtons[name] = button(tabBar, name, UDim2.new(), function() showPage(name) end)
 return frame
end
local modsPage = page('Mods')
local powersPage = page('Powers')
local itemsPage = page('Items')
local consolePage = page('Console')
showPage('Mods')

-- Output and destructive confirmation remain visible on every tab.
local footer = Instance.new('Frame')
footer.BackgroundTransparency = 1
footer.Size = UDim2.new(1, -24, 0, 100)
footer.Position = UDim2.new(0, 12, 1, -112)
footer.Parent = panel
local outputScroll = Instance.new('ScrollingFrame')
outputScroll.Size = UDim2.new(1, 0, 0, 100)
outputScroll.BackgroundColor3 = palette.surface
outputScroll.BorderSizePixel = 0
outputScroll.CanvasSize = UDim2.new()
outputScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
outputScroll.ScrollBarThickness = 4
outputScroll.Parent = footer
round(outputScroll, 7)
local output = label(outputScroll, 'Waiting for server verification…', UDim2.new(1, -20, 0, 0))
output.Position = UDim2.fromOffset(8, 6)
output.AutomaticSize = Enum.AutomaticSize.Y
output.TextYAlignment = Enum.TextYAlignment.Top
output.Font = Enum.Font.Code
output.TextSize = 12
local confirmation = Instance.new('Frame')
confirmation.BackgroundTransparency = 1
confirmation.Position = UDim2.fromOffset(0, 108)
confirmation.Size = UDim2.new(1, 0, 0, 78)
confirmation.Visible = false
confirmation.Parent = footer
local confirmationText = label(confirmation, '', UDim2.new(1, 0, 0, 34))
confirmationText.TextColor3 = palette.gold
confirmationText.TextSize = 11
local confirmButton
local function clearConfirmation()
 pending = nil
 confirmation.Visible = false
 footer.Size = UDim2.new(1, -24, 0, 100)
 footer.Position = UDim2.new(0, 12, 1, -112)
 body.Size = UDim2.new(1, -24, 1, -232)
end
local commandInput = textbox(consolePage, 'help', 'Enter a server command')
local function command(text)
 if not verified then return end
 clearConfirmation()
 commandInput.Text = text
 request:FireServer({mode='command', text=text})
end
confirmButton = button(confirmation, 'CONFIRM EXACT COMMAND', UDim2.new(.68, -4, 0, 38), function()
 if not verified or not pending or commandInput.Text ~= pending.command then clearConfirmation(); return end
 local exact = pending
 clearConfirmation()
 request:FireServer({mode='command', text=exact.command, confirmation=exact.token})
end)
confirmButton.Position = UDim2.fromOffset(0, 38)
confirmButton.BackgroundColor3 = palette.danger
local cancelButton = button(confirmation, 'Cancel', UDim2.new(.32, -4, 0, 38), clearConfirmation)
cancelButton.Position = UDim2.new(.68, 4, 0, 38)
commandInput:GetPropertyChangedSignal('Text'):Connect(clearConfirmation)
commandInput.FocusLost:Connect(function(enter)
 if enter and verified then command(commandInput.Text) end
end)

-- Central action descriptors keep button labels and exact server commands together.
local Actions = {
 {id='flight', label='Flight', flag='flight', on='flight on', off='flight off'},
 {id='noclip', label='Noclip', flag='noclip', on='noclip on', off='noclip off'},
 {id='immunity', label='Ability immunity', flag='god', on='god on', off='god off'},
 {id='heal', label='Heal', command='heal'},
 {id='home', label='Return home', command='home'},
 {id='resetmods', label='Reset all mods', command='resetmods'},
}
local modButtons = {}
description(modsPage, 'Developer controls affect your character. Ability immunity blocks other players’ powers; world hazards and resets still apply.', 52)
local modGrid = row(modsPage, 142)
local gridLayout = Instance.new('UIGridLayout')
gridLayout.CellSize = UDim2.new(.5, -5, 0, 42)
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = modGrid
for _, action in ipairs(Actions) do
 local control = button(modGrid, action.label, UDim2.new(), function()
  command(action.flag and (mods[action.flag] and action.off or action.on) or action.command)
 end)
 control.Name = action.id
 modButtons[action.id] = control
end
local movementStatus = description(modsPage, 'Movement values are reported by the server.', 28)
local function numericControl(parent, titleText, initial, verb, hint)
 description(parent, titleText..' · '..hint, 24)
 local holder = row(parent, 42)
 local value = textbox(holder, initial, titleText)
 value.Size = UDim2.new(.58, -4, 1, 0)
 local set = button(holder, 'Set '..titleText:lower(), UDim2.new(.42, -4, 1, 0), function()
  local numeric = tonumber(value.Text)
  if not numeric or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
   output.Text = 'Enter a finite number. The server validates the allowed range.'
   return
  end
  command(verb..' '..value.Text)
 end)
 set.Position = UDim2.new(.58, 4, 0, 0)
 return value
end
numericControl(modsPage, 'Speed', '32', 'speed', '16–64; Reset all mods restores normal')
numericControl(modsPage, 'Jump', '75', 'jump', '50–120; Reset all mods restores normal')
description(modsPage, 'Flight: WASD to move, Q down, E up. Touch flight controls appear while flying. Deliver carried loot before enabling movement mods.', 56)

local PowerActions = {
 {id='tag', name='Tag'}, {id='dash', name='Dash'},
 {id='gravity', name='Gravity'}, {id='slow', name='Slow'},
 {id='slam', name='Slam'}, {id='repulse', name='Repulse'},
 {id='shield', name='Shield'}, {id='lightning', name='Lightning'},
}
description(powersPage, 'Test the same eight powers players use. Casts keep normal range, carry restrictions and cooldowns. Face your character toward a target.', 52)
button(powersPage, 'UNLOCK ALL 8 POWERS', UDim2.new(1, -8, 0, 42), function() command('powers') end).Name = 'unlockPowers'
button(powersPage, 'RESET MY POWER COOLDOWNS', UDim2.new(1, -8, 0, 42), function() command('cooldowns') end).Name = 'resetCooldowns'
local powerControls = {}
for _, entry in ipairs(PowerActions) do
 local control = button(powersPage, 'CAST '..entry.name:upper(), UDim2.new(1, -8, 0, 42), function()
  command('cast '..entry.id)
 end)
 control.Name = 'cast_'..entry.id
 powerControls[entry.id] = control
end
description(powersPage, 'Unlocking powers preserves Tag and a valid loadout. Use the normal power menu to choose your two optional slots. Resetting mods restores movement and immunity.', 60)

-- Catalog rows are built only from current server metadata, never guessed item IDs.
description(itemsPage, 'Select a current catalog item. Grant places one in your base if a slot is free; Offer puts a buyable item on this server’s conveyor.', 52)
local search = textbox(itemsPage, '', 'Search item name, rarity or ID')
local selectedLabel = label(itemsPage, 'No item selected.', UDim2.new(1, -8, 0, 44))
selectedLabel.TextColor3 = palette.gold
local itemActions = row(itemsPage, 42)
local grant = button(itemActions, 'GRANT 1 TO MY BASE', UDim2.new(.5, -4, 1, 0), function()
 if selectedItem then command('grant self '..selectedItem.id..' 1') end
end)
local offer = button(itemActions, 'SPAWN ON BELT', UDim2.new(.5, -4, 1, 0), function()
 if selectedItem then command('offer '..selectedItem.id) end
end)
offer.Position = UDim2.new(.5, 4, 0, 0)
local itemCount = description(itemsPage, 'Waiting for the server catalog…', 24)
local itemRows = {}
local catalogHolder = Instance.new('Frame')
catalogHolder.BackgroundTransparency = 1
catalogHolder.Size = UDim2.new(1, -8, 0, 0)
catalogHolder.AutomaticSize = Enum.AutomaticSize.Y
catalogHolder.Parent = itemsPage
list(catalogHolder, 6)
local function filterItems()
 local query = string.lower(search.Text)
 local count = 0
 for _, entry in ipairs(itemRows) do
  entry.button.Visible = query == '' or string.find(entry.search, query, 1, true) ~= nil
  if entry.button.Visible then count += 1 end
 end
 itemCount.Text = tostring(count)..' of '..tostring(#itemRows)..' catalog items'
end
search:GetPropertyChangedSignal('Text'):Connect(filterItems)
local rarityNames = {'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Mythic', 'Ethereal'}
local function loadCatalog(catalog)
 if type(catalog) ~= 'table' then return end
 selectedItem = nil
 selectedLabel.Text = 'No item selected.'
 for _, entry in ipairs(itemRows) do entry.button:Destroy() end
 table.clear(itemRows)
 for index, raw in ipairs(catalog) do
  if type(raw) == 'table' and type(raw.id) == 'string' and type(raw.name) == 'string' then
   local item = {id=raw.id, name=raw.name, rarity=tostring(raw.rarity or rarityNames[raw.tier] or '')}
   local control
   control = button(catalogHolder, '', UDim2.new(1, 0, 0, 52), function()
    selectedItem = item
    selectedLabel.Text = item.name..'\n'..item.id..' · '..item.rarity
    for _, other in ipairs(itemRows) do other.button.BackgroundColor3 = other.button == control and palette.active or palette.surface end
   end)
   control.Name = 'item_'..item.id
   control.LayoutOrder = index
   control.BackgroundColor3 = palette.surface
   local itemName = label(control, item.name, UDim2.new(1, -16, 0, 25))
   itemName.Position = UDim2.fromOffset(8, 2)
   itemName.TextSize = 13
   itemName.Font = Enum.Font.GothamBold
   itemName.TextTruncate = Enum.TextTruncate.AtEnd
   local details = label(control, item.id..' · '..item.rarity, UDim2.new(1, -16, 0, 20))
   details.Position = UDim2.fromOffset(8, 27)
   details.TextColor3 = palette.muted
   details.TextSize = 11
   table.insert(itemRows, {button=control, search=string.lower(item.name..' '..item.id..' '..item.rarity)})
  end
 end
 filterItems()
end

button(consolePage, 'EXECUTE COMMAND', UDim2.new(1, -8, 0, 40), function() command(commandInput.Text) end)
description(consolePage, 'Targets use self or a numeric Roblox UserId. Destructive commands need a separate confirmation of the exact text. Ban and unban affect this server session only.', 62)
local templates = {
 'help', 'state', 'logs 20', 'inventory self', 'cash self add 1000',
 'cash self remove 1000', 'cash self set 650', 'protect self 60', 'protect self 0',
 'teleport self 0 5 15', 'announce Welcome to the arena!',
 'remove self OWNED_RELIC_UID', 'kick USERID reason', 'ban USERID reason', 'unban USERID',
}
for _, text in ipairs(templates) do
 button(consolePage, text, UDim2.new(1, -8, 0, 36), function()
  commandInput.Text = text
  clearConfirmation()
  commandInput:CaptureFocus()
 end)
end

-- Hold controls stay reachable when the panel is closed, and combine multiple touches.
local touchPad = Instance.new('Frame')
touchPad.Name = 'DeveloperFlightTouch'
touchPad.Size = UDim2.fromOffset(212, 144)
touchPad.Position = UDim2.new(0, 16, 1, -300)
touchPad.BackgroundTransparency = 1
touchPad.Visible = false
touchPad.Parent = gui
local touchDirections = {
 {name='Forward', text='↑', direction=Vector3.new(0,0,-1), x=48, y=0},
 {name='Left', text='←', direction=Vector3.new(-1,0,0), x=0, y=48},
 {name='Back', text='↓', direction=Vector3.new(0,0,1), x=48, y=48},
 {name='Right', text='→', direction=Vector3.new(1,0,0), x=96, y=48},
 {name='Up', text='UP', direction=Vector3.new(0,1,0), x=164, y=0},
 {name='Down', text='DN', direction=Vector3.new(0,-1,0), x=164, y=48},
}
for _, entry in ipairs(touchDirections) do
 local control = button(touchPad, entry.text, UDim2.fromOffset(44, 44), function() end)
 control.Name = 'Flight'..entry.name
 control.Position = UDim2.fromOffset(entry.x, entry.y)
 control.InputBegan:Connect(function(input)
  if verified and flight and windowFocused and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
   touchInputs[input] = {direction=entry.direction, control=control}
  end
 end)
 control.InputEnded:Connect(function(input) touchInputs[input] = nil end)
 control.MouseLeave:Connect(function()
  for input, value in pairs(touchInputs) do
   if value.control == control and input.UserInputType == Enum.UserInputType.MouseButton1 then touchInputs[input] = nil end
  end
 end)
end
UIS.InputEnded:Connect(function(input) touchInputs[input] = nil end)
local toggle = button(gui, 'DEV / F8', UDim2.fromOffset(92, 34), function()
 if verified then panel.Visible = not panel.Visible; if not panel.Visible then stopTouch() end end
end)
toggle.Name = 'DeveloperToggle'
toggle.Position = UDim2.new(1, -104, 1, -108)
toggle.TextColor3 = palette.gold
toggle.Visible = false
local function applyMods(state)
 if type(state) ~= 'table' then return end
 for _, key in ipairs({'flight','noclip','god','speed','jump'}) do
  if state[key] ~= nil then mods[key] = state[key] end
 end
 flight = mods.flight == true
 touchPad.Visible = verified and flight and UIS.TouchEnabled
 if not flight then table.clear(touchInputs) end
 for _, action in ipairs(Actions) do
  local control = modButtons[action.id]
  if action.flag then
   local enabled = mods[action.flag] == true
   control.Text = action.label..' · '..(enabled and 'ON' or 'OFF')
   control.BackgroundColor3 = enabled and palette.active or palette.raised
  end
 end
 movementStatus.Text = 'Server movement · speed '..tostring(mods.speed or '—')..' · jump '..tostring(mods.jump or '—')
end
applyMods(mods)
response.OnClientEvent:Connect(function(reply)
 if type(reply) ~= 'table' then return end
 if reply.authorized == false then
  verified = false
  stopTouch()
  flight = false
  toggle.Visible = false
  panel.Visible = false
  touchPad.Visible = false
  clearConfirmation()
  return
 end
 if not verified then
  if reply.authorized ~= true then return end
  verified = true
  toggle.Visible = true
 end
 local data = type(reply.data) == 'table' and reply.data or nil
 local catalog = reply.catalog or (data and data.catalog)
 local powers = reply.powers or (data and data.powers)
 if catalog then loadCatalog(catalog) end
 if type(powers) == 'table' then
  for _, entry in ipairs(powers) do
   if type(entry) == 'table' and powerControls[entry.id] then
    powerControls[entry.id].Text = 'CAST '..tostring(entry.name or entry.id):upper()..' · '..tostring(entry.cooldown or '?')..'s'
   end
  end
 end
 applyMods(reply.mods or (data and data.mods) or {flight=reply.flight, noclip=reply.noclip})
 output.Text = (reply.ok and 'OK: ' or 'NOTICE: ')..tostring(reply.message or 'Command completed.')
 if data then
  -- State/log output stays readable when a reply also refreshes catalog metadata.
  local details = {}
  for key, value in pairs(data) do
   if key ~= 'catalog' and key ~= 'powers' and key ~= 'mods' then details[key] = value end
  end
  local ok, json = pcall(Http.JSONEncode, Http, details)
  if ok and next(details) then output.Text ..= '\n'..string.sub(json, 1, 8000) end
 end
 outputScroll.CanvasPosition = Vector2.zero
 clearConfirmation()
 if type(reply.confirmation) == 'string' and type(reply.command) == 'string' then
  -- Canonicalize the input first: edits revoke this exact-command confirmation.
  commandInput.Text = reply.command
  pending = {token=reply.confirmation, command=reply.command}
  confirmationText.Text = 'Confirm only: '..reply.command
  confirmation.Visible = true
  footer.Size = UDim2.new(1, -24, 0, 186)
  footer.Position = UDim2.new(0, 12, 1, -198)
  body.Size = UDim2.new(1, -24, 1, -318)
  panel.Visible = true
 end
end)

local viewportConnection
local function fit()
 local camera = workspace.CurrentCamera
 if not camera then return end
 local viewport = camera.ViewportSize
 local availableWidth = math.max(1, viewport.X-24)
 local availableHeight = math.max(1, viewport.Y-84)
 local width = math.clamp(availableWidth, 300, 520)
 local height = math.clamp(availableHeight, 360, 620)
 panel.Size = UDim2.fromOffset(width, height)
 -- Keep text and touch targets at native size on phones; scale only below minimum bounds.
 scale.Scale = math.min(1, availableWidth/width, availableHeight/height)
end
local function cameraChanged()
 if viewportConnection then viewportConnection:Disconnect() end
 local camera = workspace.CurrentCamera
 if camera then viewportConnection = camera:GetPropertyChangedSignal('ViewportSize'):Connect(fit) end
 fit()
end
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(cameraChanged)
cameraChanged()
UIS.InputBegan:Connect(function(input)
 if verified and input.KeyCode == Enum.KeyCode.F8 and not UIS:GetFocusedTextBox() then
  panel.Visible = not panel.Visible
  if not panel.Visible then stopTouch() end
 end
end)
UIS.WindowFocusReleased:Connect(function() windowFocused = false; stopTouch() end)
UIS.WindowFocused:Connect(function() windowFocused = true end)
UIS.TextBoxFocused:Connect(stopTouch)
player.CharacterAdded:Connect(function()
 stopTouch()
 applyMods({flight=false, noclip=false, god=false})
 clearConfirmation()
end)
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
 elapsed += dt
 if elapsed < .1 then return end
 elapsed = 0
 if not verified or not flight or not windowFocused then return end
 local camera = workspace.CurrentCamera
 if not camera then return end
 local direction = Vector3.zero
 if not UIS:GetFocusedTextBox() then
  if UIS:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.E) then direction += Vector3.yAxis end
  if UIS:IsKeyDown(Enum.KeyCode.Q) then direction -= Vector3.yAxis end
  for _, value in pairs(touchInputs) do
   local d = value.direction
   direction += camera.CFrame.RightVector*d.X + Vector3.yAxis*d.Y - camera.CFrame.LookVector*d.Z
  end
 end
 if direction.Magnitude > 1 then direction = direction.Unit end
 request:FireServer({mode='move', direction=direction})
end)
-- This is the sole request sent before authorization succeeds.
request:FireServer({mode='hello'})
