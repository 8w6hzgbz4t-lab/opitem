-- Only AdminService injects this LocalScript, and no control opens before server verification.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local UIS = game:GetService('UserInputService')
local Run = game:GetService('RunService')
local Http = game:GetService('HttpService')
local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')
local net = RS:WaitForChild('OPItemNet')
local request = net:WaitForChild('AdminRequest')
local response = net:WaitForChild('AdminResponse')
local gui = script.Parent
local verified, flight, windowFocused = false, false, true
local mods = {flight=false, noclip=false, god=false, developerMode=false}
local pending, selectedItem, selectedTarget
local giftPendingId, giftStarted, giftRetryPayload = nil, 0, nil
local targetRows = {}
local setGiftBusy, refreshGiftPlayers, retryGift
local activePage = 'Flight'
local royalReadyAt = 0
local touchInputs = {}
local jumpCount, jumpStarted, lastTakeoff = 0, 0, -math.huge
local jumpHeld = {}
local function resetJumpSequence()
 jumpCount, jumpStarted = 0, 0
 table.clear(jumpHeld)
end
local palette = {
 background=Color3.fromRGB(16,23,39), surface=Color3.fromRGB(28,38,57),
 raised=Color3.fromRGB(40,53,75), gold=Color3.fromRGB(224,189,108),
 text=Color3.fromRGB(238,241,248), muted=Color3.fromRGB(164,180,202),
 active=Color3.fromRGB(36,99,87), danger=Color3.fromRGB(139,54,55),
}
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
local title = label(panel, 'DEVELOPER TOOLS', UDim2.new(1, -70, 0, 25))
title.Position = UDim2.fromOffset(16, 10)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = palette.gold
local verifiedLabel = label(panel, 'Your tools · F8 opens and closes · this server only', UDim2.new(1, -70, 0, 20))
verifiedLabel.Position = UDim2.fromOffset(16, 34)
verifiedLabel.TextSize = 11
verifiedLabel.TextColor3 = palette.muted

local function stopTouch()
 table.clear(touchInputs)
 if verified and flight then request:FireServer({mode='move', direction=Vector3.zero}) end
end
local function setOpen(open)
 if open and not verified then return end
 panel.Visible = open
 if open then playerGui:SetAttribute('OPActiveMenu', 'developer')
 else
  if playerGui:GetAttribute('OPActiveMenu') == 'developer' then playerGui:SetAttribute('OPActiveMenu', nil) end
  stopTouch()
 end
end
playerGui:GetAttributeChangedSignal('OPActiveMenu'):Connect(function()
 if playerGui:GetAttribute('OPActiveMenu') ~= 'developer' and panel.Visible then panel.Visible = false; stopTouch() end
end)
local close = button(panel, '×', UDim2.fromOffset(38, 38), function() setOpen(false) end)
close.Name = 'DeveloperClose'
close.Position = UDim2.new(1, -50, 0, 12)
close.TextSize = 24

local tabBar = Instance.new('Frame')
tabBar.BackgroundTransparency = 1
tabBar.Position = UDim2.fromOffset(12, 64)
tabBar.Size = UDim2.new(1, -24, 0, 36)
tabBar.Parent = panel
local tabLayout = Instance.new('UIGridLayout')
tabLayout.CellPadding = UDim2.fromOffset(6, 0)
tabLayout.CellSize = UDim2.new(.2, -5, 1, 0)
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
 activePage = name
 if name == 'Gifts' and refreshGiftPlayers and verified then refreshGiftPlayers() end
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
 tabButtons[name].Name = 'DeveloperTab_'..name
 return frame
end
local modsPage = page('Flight')
local powersPage = page('Powers')
local itemsPage = page('Items')
local giftsPage = page('Gifts')
local consolePage = page('Console')
showPage('Flight')

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
 if not verified then return false end
 local gift = string.match(text, '^giftcash%s') or string.match(text, '^giftlevels%s')
 if gift and giftPendingId then output.Text = 'Wait for the current gift result before sending another gift.'; return false end
 clearConfirmation()
 commandInput.Text = text
 local payload = {mode='command', text=text}
 if gift then
  local ok, id = pcall(Http.GenerateGUID, Http, false)
  if not ok or type(id) ~= 'string' or #id < 8 then output.Text = 'Could not prepare a gift. Please try again.'; return false end
  giftPendingId = id
  giftStarted = os.clock()
  payload.requestId = id
  giftRetryPayload = payload
  if setGiftBusy then setGiftBusy(true) end
 end
 request:FireServer(payload)
 return true
end
refreshGiftPlayers = function() command('state') end
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
 {id='devmode', label='Developer mode', flag='developerMode', on='devmode on', off='devmode off'},
 {id='flight', label='Flight', flag='flight', on='flight on', off='flight off'},
 {id='noclip', label='Noclip', flag='noclip', on='noclip on', off='noclip off'},
 {id='immunity', label='Millennium protection', flag='god', on='god on', off='god off'},
 {id='heal', label='Heal', command='heal'},
 {id='home', label='Return home', command='home'},
 {id='resetmods', label='Reset all mods', command='resetmods'},
}
local modButtons = {}
description(modsPage, 'Enable Developer mode for your fourth Royal Seal ability. Close menus and press Jump three times quickly to fly. These tools are exclusive to your account.', 66)
local modGrid = row(modsPage, 192)
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
description(modsPage, 'Flight stays upright: WASD moves with the camera; E rises and Q descends. Touch players use the arrows. Release movement to hover or press LAND. Carrying, bidding or respawning resets developer mode.', 76)

description(powersPage, 'YOUR SIGNATURE POWER', 24).TextColor3 = palette.gold
local royalSeal = button(powersPage, 'CAST ROYAL SEAL', UDim2.new(1, -8, 0, 48), function()
 if os.clock() < royalReadyAt then return end
 if command('royalseal') then royalReadyAt = os.clock() + .5 end
end)
royalSeal.Name = 'RoyalSeal'
royalSeal.TextColor3 = palette.gold
description(powersPage, 'Your Millennium Rod channels Royal Seal. The server controls its cooldown and hit checks. Your other menu casts also display the Rod.', 54)

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
 local previousId = selectedItem and selectedItem.id
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
   if item.id == previousId then
    selectedItem = item
    selectedLabel.Text = item.name..'\n'..item.id..' · '..item.rarity
    control.BackgroundColor3 = palette.active
   end
   table.insert(itemRows, {button=control, search=string.lower(item.name..' '..item.id..' '..item.rarity)})
  end
 end
 filterItems()
end

-- Gifts select a server-listed player, including the developer, rather than a typed name.
description(giftsPage, 'GIFT MONEY OR LEVELS', 24).TextColor3 = palette.gold
description(giftsPage, 'Choose a player below, including yourself. Gifts are developer grants; money is not deducted from your wallet. Levels use the normal base progression.', 62)
local targetLabel = label(giftsPage, 'Select a player to gift.', UDim2.new(1, -8, 0, 44))
targetLabel.Name = 'GiftTargetLabel'
targetLabel.TextColor3 = palette.gold
local refreshPlayers = button(giftsPage, 'REFRESH PLAYERS', UDim2.new(1, -8, 0, 36), function() command('state') end)
refreshPlayers.Name = 'RefreshGiftPlayers'
local targetHolder = Instance.new('ScrollingFrame')
targetHolder.BackgroundTransparency = 1
targetHolder.Size = UDim2.new(1, -8, 0, 28)
targetHolder.CanvasSize = UDim2.new()
targetHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
targetHolder.ScrollBarThickness = 4
targetHolder.BorderSizePixel = 0
targetHolder.Parent = giftsPage
list(targetHolder, 6)
local function loadPlayers(players)
 if type(players) ~= 'table' then return end
 local oldId = selectedTarget and selectedTarget.userId
 selectedTarget = nil
 for _, entry in ipairs(targetRows) do entry.button:Destroy() end
 table.clear(targetRows)
 for index, raw in ipairs(players) do
  if type(raw) == 'table' and type(raw.userId) == 'number' and raw.userId > 0 and raw.userId % 1 == 0 then
   local target = {userId=raw.userId, name=tostring(raw.name or raw.userId), displayName=tostring(raw.displayName or raw.name or raw.userId), level=raw.level or 0}
   local own = target.userId == player.UserId
   local display = target.displayName..(own and ' · YOU' or '')..'\n@'..target.name..' · Level '..tostring(target.level)
   local control
   control = button(targetHolder, display, UDim2.new(1, 0, 0, 50), function()
    selectedTarget = target
    targetLabel.Text = 'Selected: '..target.displayName..' (@'..target.name..')'
    for _, entry in ipairs(targetRows) do entry.button.BackgroundColor3 = entry.button == control and palette.active or palette.surface end
   end)
   control.Name = 'GiftPlayer_'..tostring(target.userId)
   control.LayoutOrder = index
   control.BackgroundColor3 = palette.surface
   table.insert(targetRows, {button=control, player=target})
   if target.userId == oldId then selectedTarget = target; control.BackgroundColor3 = palette.active end
  end
 end
 targetHolder.Size = UDim2.new(1, -8, 0, math.max(28, math.min(3, #targetRows) * 56))
 if selectedTarget then targetLabel.Text = 'Selected: '..selectedTarget.displayName..' (@'..selectedTarget.name..')'
 else targetLabel.Text = oldId and 'That player left. Select a player below.' or 'Select a player to gift.' end
end
local moneyHeading = description(giftsPage, 'Money amount · whole dollars', 24)
moneyHeading.LayoutOrder = 100
local giftCashAmount = textbox(giftsPage, '1000', 'Money amount: positive whole dollars')
giftCashAmount.Name = 'GiftCashAmount'
giftCashAmount.LayoutOrder = 101
local levelHeading = description(giftsPage, 'Level amount · 1–100', 24)
levelHeading.LayoutOrder = 200
local giftLevelAmount = textbox(giftsPage, '1', 'Levels to grant: 1–100')
giftLevelAmount.Name = 'GiftLevelAmount'
giftLevelAmount.LayoutOrder = 201
local giftStatus = description(giftsPage, 'No gift sent.', 40)
giftStatus.Name = 'GiftStatus'
giftStatus.LayoutOrder = 300
local function gift(kind, amountInput)
 if giftPendingId then return end
 if not selectedTarget then giftStatus.Text = 'Select a player first.'; return end
 local amount = tonumber(amountInput.Text)
 local max = kind == 'giftlevels' and 100 or 2000000000
 if not amount or amount ~= amount or amount <= 0 or amount % 1 ~= 0 or amount > max then
  giftStatus.Text = kind == 'giftlevels' and 'Enter 1–100 whole levels.' or 'Enter a positive whole money amount, up to 2 billion.'
  return
 end
 if command(kind..' '..tostring(selectedTarget.userId)..' '..string.format('%.0f', amount)) then
  giftStatus.Text = 'Sending to '..selectedTarget.displayName..'…'
 end
end
local giftCash = button(giftsPage, 'GIFT MONEY', UDim2.new(1, -8, 0, 44), function() gift('giftcash', giftCashAmount) end)
giftCash.Name = 'GiftCash'
giftCash.LayoutOrder = 102
local giftLevels = button(giftsPage, 'GIFT LEVELS', UDim2.new(1, -8, 0, 44), function() gift('giftlevels', giftLevelAmount) end)
giftLevels.Name = 'GiftLevels'
giftLevels.LayoutOrder = 202
retryGift = button(giftsPage, 'CHECK GIFT RESULT', UDim2.new(1, -8, 0, 40), function()
 if not verified or not giftPendingId or not giftRetryPayload then return end
 giftStarted = os.clock()
 request:FireServer(giftRetryPayload)
 retryGift.Visible = false
 giftStatus.Text = 'Checking the same gift request. No second gift is created.'
end)
retryGift.Name = 'RetryGift'
retryGift.LayoutOrder = 301
retryGift.Visible = false
setGiftBusy = function(busy)
 if not busy then retryGift.Visible = false end
 giftCash.Active = not busy; giftLevels.Active = not busy
 giftCash.AutoButtonColor = not busy; giftLevels.AutoButtonColor = not busy
 giftCash.Text = busy and 'SENDING GIFT…' or 'GIFT MONEY'
 giftLevels.Text = busy and 'WAIT FOR GIFT RESULT' or 'GIFT LEVELS'
end

button(consolePage, 'EXECUTE COMMAND', UDim2.new(1, -8, 0, 40), function() command(commandInput.Text) end)
description(consolePage, 'Targets use self or a numeric Roblox UserId. Destructive commands need a separate confirmation of the exact text. Ban and unban affect this server session only.', 62)
local templates = {
 'help', 'state', 'logs 20', 'royalseal', 'inventory self', 'cash self add 1000',
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
local toggle = button(gui, 'DEVELOPER  ·  F8', UDim2.fromOffset(156, 38), function()
 if verified then setOpen(not panel.Visible) end
end)
toggle.Name = 'DeveloperToggle'
toggle.Position = UDim2.new(1, -164, 0, 8)
toggle.TextColor3 = palette.background
toggle.BackgroundColor3 = palette.gold
toggle.Visible = false
local developerHint = label(toggle, 'TOOLS READY · TAP TO OPEN', UDim2.new(1, -8, 0, 12))
developerHint.Name = 'DeveloperHint'
developerHint.Position = UDim2.new(0, 4, 1, -13)
developerHint.TextXAlignment = Enum.TextXAlignment.Center
developerHint.TextColor3 = palette.background
developerHint.TextSize = 9
developerHint.Visible = false
local land = button(gui, 'FLYING · LAND', UDim2.fromOffset(156, 34), function() command('flight off') end)
land.Name = 'DeveloperLand'
land.Position = UDim2.new(1, -164, 0, 50)
land.BackgroundColor3 = palette.active
land.Visible = false
local function applyMods(state)
 if type(state) ~= 'table' then return end
 for _, key in ipairs({'flight','noclip','god','speed','jump','developerMode'}) do
  if state[key] ~= nil then mods[key] = state[key] end
 end
 local oldFlight = flight
 flight = mods.flight == true
 if not mods.developerMode or oldFlight ~= flight then resetJumpSequence() end
 playerGui:SetAttribute('OPDeveloperMode', verified and mods.developerMode == true)
 playerGui:SetAttribute('OPDeveloperFlight', verified and flight)
 land.Visible = verified and flight
 if flight then developerHint.Visible = false; toggle.TextYAlignment = Enum.TextYAlignment.Center end
 if type(state.royalSealRemaining) == 'number' then royalReadyAt = os.clock() + math.max(0, state.royalSealRemaining) end
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
  mods.developerMode = false
  resetJumpSequence()
  playerGui:SetAttribute('OPDeveloperMode', false)
  playerGui:SetAttribute('OPDeveloperFlight', false)
  land.Visible = false
  developerHint.Visible = false
  giftPendingId = nil; giftRetryPayload = nil
  setGiftBusy(false)
  toggle.Visible = false
  setOpen(false)
  touchPad.Visible = false
  clearConfirmation()
  return
 end
 if not verified then
  if reply.authorized ~= true then return end
  verified = true
  toggle.Visible = true
  developerHint.Visible = true
  toggle.TextYAlignment = Enum.TextYAlignment.Top
  task.delay(6, function() developerHint.Visible = false; toggle.TextYAlignment = Enum.TextYAlignment.Center end)
 end
 local data = type(reply.data) == 'table' and reply.data or nil
 local catalog = reply.catalog or (data and data.catalog)
 local powers = reply.powers or (data and data.powers)
 local players = reply.players or (data and data.players)
 if players then loadPlayers(players) end
 if reply.requestId and reply.requestId == giftPendingId then
  giftPendingId = nil; giftRetryPayload = nil
  setGiftBusy(false)
  giftStatus.Text = tostring(reply.message or (reply.ok and 'Gift sent.' or 'Gift was not sent.'))
 end
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
   if key ~= 'catalog' and key ~= 'powers' and key ~= 'mods' and key ~= 'players' and key ~= 'uniquePower' then details[key] = value end
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
  setOpen(true)
 end
end)

local viewportConnection
local function fit()
 local camera = workspace.CurrentCamera
 if not camera then return end
 local viewport = camera.ViewportSize
 land.Position = UDim2.new(1, -164, 0, viewport.X < 640 and 148 or 50)
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
  setOpen(not panel.Visible)
 end
end)
UIS.WindowFocusReleased:Connect(function() windowFocused = false; stopTouch(); resetJumpSequence() end)
UIS.WindowFocused:Connect(function() windowFocused = true end)
UIS.TextBoxFocused:Connect(function() stopTouch(); resetJumpSequence() end)
player.CharacterAdded:Connect(function()
 stopTouch()
 applyMods({flight=false, noclip=false, god=false, developerMode=false})
 clearConfirmation()
end)
-- Count physical press edges, never repeated JumpRequest events while a key is held.
-- The server independently verifies identity, mode and movement restrictions.
local function jumpPress(token)
 if not verified or not mods.developerMode or flight or not windowFocused
  or playerGui:GetAttribute('OPActiveMenu') or UIS:GetFocusedTextBox() then
  resetJumpSequence()
  return
 end
 if jumpHeld[token] then return end
 jumpHeld[token] = true
 local now = os.clock()
 if now - lastTakeoff < 1.2 then return end
 if jumpCount == 0 or now - jumpStarted > 1.2 then jumpCount, jumpStarted = 1, now
 else jumpCount += 1 end
 if jumpCount >= 3 then
  jumpCount, jumpStarted, lastTakeoff = 0, 0, now
  command('triplejump')
 end
end
UIS.InputBegan:Connect(function(input)
 if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then jumpPress(input.KeyCode) end
end)
UIS.InputEnded:Connect(function(input)
 if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then jumpHeld[input.KeyCode] = nil end
 jumpHeld[input] = nil
end)
local observedJumpButtons = setmetatable({}, {__mode='k'})
local function observeJumpButton(object)
 if object.Name ~= 'JumpButton' or not (object:IsA('ImageButton') or object:IsA('TextButton')) or observedJumpButtons[object] then return end
 observedJumpButtons[object] = true
 object.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.Touch then jumpPress(input) end
 end)
 object.InputEnded:Connect(function(input) jumpHeld[input] = nil end)
end
for _, object in ipairs(playerGui:GetDescendants()) do observeJumpButton(object) end
playerGui.DescendantAdded:Connect(observeJumpButton)
playerGui:GetAttributeChangedSignal('OPActiveMenu'):Connect(function()
 if playerGui:GetAttribute('OPActiveMenu') then resetJumpSequence() end
end)
local elapsed = 0
Run.Heartbeat:Connect(function(dt)
 elapsed += dt
 if elapsed < .1 then return end
 elapsed = 0
 if verified then
  local remaining = math.max(0, royalReadyAt - os.clock())
  royalSeal.Text = remaining > 0 and ('ROYAL SEAL · '..math.ceil(remaining)..'s') or 'CAST ROYAL SEAL'
  royalSeal.Active = remaining <= 0
  if giftPendingId and os.clock() - giftStarted > 10 then
   retryGift.Visible = true
   giftStatus.Text = 'Still waiting for the gift result. Check the same request safely below.'
  end
 end
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
