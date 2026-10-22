-- Cosmetic animation suppression while the authorized server flight pose is active.
-- No movement, permission or orientation authority is granted by this module.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local M={};local started=false
function M.start()
 if started then return end;started=true
 local cache={}
 Run.PreSimulation:Connect(function()
  for _,player in ipairs(Players:GetPlayers())do
   local character=player.Character
   if player:GetAttribute('OPDeveloperFlying')==true and character then
    local entry=cache[player]
    if not entry or entry.character~=character then
     entry={character=character,joints={}};cache[player]=entry
     for _,joint in ipairs(character:GetDescendants())do if joint:IsA('Motor6D')then entry.joints[#entry.joints+1]=joint end end
    end
    for _,joint in ipairs(entry.joints)do if joint.Parent then joint.Transform=CFrame.identity end end
   else cache[player]=nil end
  end
 end)
 Players.PlayerRemoving:Connect(function(player)cache[player]=nil end)
end
return M
