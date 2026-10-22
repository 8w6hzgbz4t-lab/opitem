-- Local playback only. Server gameplay events carry a cue name, never an arbitrary asset ID.
local SoundService=game:GetService('SoundService')
local Debris=game:GetService('Debris')
local Config=require(script.Parent:WaitForChild('AudioConfig'))
local M={}
local sessions=setmetatable({},{__mode='k'})
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function volume(gui,key,fallback)
 local n=gui:GetAttribute(key)
 return finite(n) and math.clamp(n,0,1) or fallback
end
local function asset(id)
 return finite(id) and id>0 and id%1==0 and 'rbxassetid://'..tostring(id) or nil
end
local function vector(v)
 return typeof(v)=='Vector3' and finite(v.X) and finite(v.Y) and finite(v.Z)
end
function M.start(net,gui)
 if sessions[gui] then return sessions[gui] end
 local folder=Instance.new('Folder');folder.Name='OPGameAudio';folder.Parent=SoundService
 local music=Instance.new('Sound');music.Name='OriginalBattleMusic';music.Looped=true
 music.SoundId=asset(Config.Music.AssetId) or '';music.PlaybackSpeed=Config.Music.PlaybackSpeed or 1
 music.Parent=folder
 local connections,active,last={},{},{}
 local buttons=setmetatable({},{__mode='k'})
 local tokens,updated=12,os.clock()
 local dead=false
 local function settings()
  music.Volume=gui:GetAttribute('OPMusicMuted')==true and 0 or volume(gui,'OPMusicVolume',Config.Music.Volume)
  if music.SoundId~='' and music.Volume>0 then
   if not music.IsPlaying then music:Play() end
  elseif music.IsPlaying then music:Pause() end
  for sound,base in pairs(active)do
   if sound.Parent then sound.Volume=gui:GetAttribute('OPSfxMuted')==true and 0 or base*volume(gui,'OPSfxVolume',Config.EffectsVolume)
   else active[sound]=nil end
  end
 end
 local function play(payload)
  if dead or type(payload)~='table' or type(payload.kind)~='string' then return false end
  local cue=Config.Cues[payload.kind]
  if not cue or gui:GetAttribute('OPSfxMuted')==true then return false end
  local now=os.clock();tokens=math.min(12,tokens+math.max(0,now-updated)*8);updated=now
  if tokens<1 or now-(last[payload.kind] or -math.huge)<(cue.Gap or .1) then return false end
  local count=0
  for sound in pairs(active)do if sound.Parent then count=count+1 else active[sound]=nil end end
  if count>=(Config.MaxSimultaneous or 12) then return false end
  local attenuation=1
  if payload.position~=nil then
   if not vector(payload.position) then return false end
   local camera=workspace.CurrentCamera
   if camera then
    local distance=(camera.CFrame.Position-payload.position).Magnitude
    if distance>(Config.MaxDistance or 160) then return false end
    attenuation=math.clamp(1-distance/(Config.MaxDistance or 160),.08,1)
   end
  end
  local effectVolume=volume(gui,'OPSfxVolume',Config.EffectsVolume)
  if effectVolume<=0 then return false end
  tokens=tokens-1;last[payload.kind]=now
  local sound=Instance.new('Sound');sound.Name='OPCue_'..payload.kind
  sound.SoundId=asset(cue.AssetId) or cue.Fallback
  sound.PlaybackSpeed=asset(cue.AssetId) and 1 or cue.Speed or 1
  if payload.kind=='powerCast' or payload.kind=='powerHit' or payload.kind=='shield' then
   sound.PlaybackSpeed=sound.PlaybackSpeed*(Config.PowerPitch[payload.power] or 1)
  end
  local base=(cue.Volume or .5)*attenuation
  sound.Volume=base*effectVolume;sound.Parent=folder;active[sound]=base
  sound.Ended:Once(function()active[sound]=nil;sound:Destroy()end)
  sound:Play();Debris:AddItem(sound,5)
  return true
 end
 local allowedRoots={OPItemHUD=true,OPPhaseHUD=true,OPDeveloperConsole=true,OPItemCashShop=true}
 local function bindButton(button)
  if not button:IsA('GuiButton') or buttons[button] then return end
  local ancestor=button.Parent;local allowed=false
  while ancestor and ancestor~=gui do
   if allowedRoots[ancestor.Name] then allowed=true;break end
   ancestor=ancestor.Parent
  end
  if allowed then buttons[button]=button.Activated:Connect(function()play({kind='ui'})end) end
 end
 for _,descendant in ipairs(gui:GetDescendants())do bindButton(descendant) end
 connections[#connections+1]=gui.DescendantAdded:Connect(bindButton)
 connections[#connections+1]=net:WaitForChild('Audio').OnClientEvent:Connect(play)
 for _,key in ipairs({'OPMusicMuted','OPSfxMuted','OPMusicVolume','OPSfxVolume'})do
  connections[#connections+1]=gui:GetAttributeChangedSignal(key):Connect(settings)
 end
 settings()
 local session={play=play}
 function session.destroy()
  if dead then return end;dead=true
  for _,connection in ipairs(connections)do connection:Disconnect() end
  for _,connection in pairs(buttons)do connection:Disconnect() end
  music:Stop();folder:Destroy();sessions[gui]=nil;table.clear(active)
 end
 sessions[gui]=session;return session
end
return M
