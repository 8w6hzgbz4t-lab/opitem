-- Per-player labels only. The server derives Buy/Sell/Steal from live ownership.
local Prompts=game:GetService('ProximityPromptService')
local Players=game:GetService('Players')
local M={}
local sessions=setmetatable({},{__mode='k'})
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function M.start(net,player)
 player=player or Players.LocalPlayer
 if not player then return nil end
 if sessions[player]then return sessions[player]end
 local records=setmetatable({},{__mode='k'})
 local connections={};local dead=false
 local function forget(prompt)
  local record=records[prompt];if not record then return end
  records[prompt]=nil
  for _,connection in ipairs(record.connections)do connection:Disconnect()end
 end
 local function refresh(prompt)
  local record=records[prompt]
  if dead or not record or record.updating or prompt:GetAttribute('OPItemPrompt')~=true then return end
  local state=prompt:GetAttribute('ItemState');local owner=prompt:GetAttribute('ItemOwnerUserId')
  local uid=prompt:GetAttribute('ItemUID');local label='Interact'
  if type(uid)=='string'and #uid>0 and #uid<=96 then
   if state=='Stored'and finite(owner)and owner>0 and owner%1==0 then
    if owner==player.UserId then
     local price=prompt:GetAttribute('SellPrice')
     label=finite(price)and price>=0 and price%1==0 and('Sell · $'..string.format('%.0f',price)..' (50%)')or'Sell (50%)'
    else label='Steal'end
   elseif state=='Conveyor'or state=='Contesting'or state=='Auction'then label='Buy'
   elseif state=='PurchaseCarry'or state=='TheftCarry'then label='In transit'end
  end
  if prompt.ActionText~=label then
   record.updating=true;prompt.ActionText=label;record.updating=false
  end
 end
 local function observe(prompt)
  if dead or not prompt:IsA('ProximityPrompt')or not prompt:IsDescendantOf(workspace)then return end
  if records[prompt]then refresh(prompt);return end
  local record={connections={}};records[prompt]=record
  local function watch(signal,callback)record.connections[#record.connections+1]=signal:Connect(callback)end
  -- Retain one bounded observer set per live prompt, including hidden prompts,
  -- so ownership text is correct before Roblox displays its next interaction.
  for _,name in ipairs({'OPItemPrompt','ItemUID','ItemOwnerUserId','ItemState','SellPrice'})do
   watch(prompt:GetAttributeChangedSignal(name),function()refresh(prompt)end)
  end
  watch(prompt:GetPropertyChangedSignal('ActionText'),function()refresh(prompt)end)
  watch(prompt.AncestryChanged,function()
   if not prompt:IsDescendantOf(workspace)then forget(prompt)end
  end)
  watch(prompt.Destroying,function()forget(prompt)end)
  refresh(prompt)
 end
 connections[#connections+1]=workspace.DescendantAdded:Connect(observe)
 connections[#connections+1]=Prompts.PromptShown:Connect(function(prompt)
  observe(prompt);local record=records[prompt];if record then record.shown=true;refresh(prompt)end
 end)
 connections[#connections+1]=Prompts.PromptHidden:Connect(function(prompt)
  -- Showing/hiding never allocates listeners, so repeated approaches cannot leak.
  local record=records[prompt];if record then record.shown=false end
 end)
 for _,descendant in ipairs(workspace:GetDescendants())do observe(descendant)end
 local session={}
 function session.destroy()
  if dead then return end;dead=true
  for _,connection in ipairs(connections)do connection:Disconnect()end
  local prompts={};for prompt in pairs(records)do prompts[#prompts+1]=prompt end
  for _,prompt in ipairs(prompts)do forget(prompt)end
  sessions[player]=nil
 end
 sessions[player]=session;return session
end
return M
