-- Executes the real client audio module with controlled sound and remote services.
local Mock=dofile('tools/roblox_mock.lua')
local now,checks=0,0
local function check(value,message)checks=checks+1;assert(value,message)end
local function signal()
 local s={listeners={}}
 function s:Connect(callback)
  local c={Connected=true,callback=callback}
  function c:Disconnect()self.Connected=false end
  self.listeners[#self.listeners+1]=c;return c
 end
 function s:Once(callback)
  local c;c=self:Connect(function(...)c:Disconnect();callback(...)end);return c
 end
 function s:Fire(...)for _,c in ipairs(self.listeners)do if c.Connected then c.callback(...)end end end
 return s
end
local oldNew=Instance.new
local sounds={}
function Instance.new(class,parent)
 if class=='TextButton' then
  local button=oldNew('Folder',parent);button.Activated=signal()
  rawset(button,'_audioButton',true)
  return button
 end
 if class~='Sound' then return oldNew(class,parent) end
 local s=oldNew('Folder',parent);s.IsPlaying=false;s.Ended=signal();s.TimePosition=0
 s.Play=function(self)self.IsPlaying=true;self.plays=(self.plays or 0)+1 end
 s.Pause=function(self)self.IsPlaying=false;self.pauses=(self.pauses or 0)+1 end
 s.Stop=function(self)self.IsPlaying=false end
 sounds[#sounds+1]=s;return s
end
local service=oldNew('Folder');service.Name='SoundService'
local debris={}
game={GetService=function(_,name)
 if name=='SoundService' then return service end
 if name=='Debris' then return {AddItem=function(_,sound,life)debris[#debris+1]={sound=sound,life=life}end} end
 error(name)
end}
workspace={CurrentCamera={CFrame=CFrame.new()}}
local gui=oldNew('Folder')
gui.DescendantAdded=signal()
local attrs={}
function gui:GetAttributeChangedSignal(key)attrs[key]=attrs[key]or signal();return attrs[key]end
local setAttr=gui.SetAttribute
local instanceMeta=getmetatable(gui);local oldIndex=instanceMeta.__index
instanceMeta.__index=function(instance,key)
 if key=='IsA' and rawget(instance,'_audioButton') then
  return function(_,kind)return kind=='GuiButton' or kind=='TextButton' or kind=='Folder'end
 end
 if instance==gui and key=='SetAttribute' then
  return function(self,name,value)setAttr(self,name,value);self:GetAttributeChangedSignal(name):Fire()end
 end
 return oldIndex(instance,key)
end
local remote=signal()
local net={WaitForChild=function(_,name)check(name=='Audio','Only the audio remote is consumed');return {OnClientEvent=remote}end}
local oldclock=os.clock;os.clock=function()return now end
local root=arg[1]or'roblox/v82-game'
local config=Mock.loadModule(root..'/AudioConfig.lua')
local client=Mock.loadModule(root..'/AudioClient.lua')
local session=client.start(net,gui)
check(client.start(net,gui)==session,'Repeated client starts reuse one session')
check(#service:GetChildren()==1 and #sounds==1,'One audio folder and one music instance')
local originalId=config.Music.AssetId
check(originalId==111355988554529,'Owner music ID was transcribed incorrectly')
check(sounds[1].IsPlaying and sounds[1].SoundId=='rbxassetid://111355988554529','Owner-uploaded music uses the exact configured asset ID')
check(sounds[1].Looped==true and sounds[1].Volume==.18,'Configured music loops at the quiet default volume')
check(not session.play({kind='bogus',SoundId='rbxassetid://123'}),'Arbitrary audio IDs cannot bypass the cue whitelist')
check(not session.play('purchase'),'Non-table payload rejected')
check(not session.play({kind=7}),'Non-string kind rejected')
local hud=oldNew('Folder',gui);hud.Name='OPItemHUD'
local button=Instance.new('TextButton',hud);button.Name='Index'
gui.DescendantAdded:Fire(button);now=now+1;local before=#sounds
button.Activated:Fire()
check(#sounds==before+1 and sounds[#sounds].Name=='OPCue_ui','New game HUD buttons receive a click cue')
sounds[#sounds].Ended:Fire()
local unrelated=oldNew('Folder',gui);unrelated.Name='OtherGameGui'
local unrelatedButton=Instance.new('TextButton',unrelated);gui.DescendantAdded:Fire(unrelatedButton)
now=now+1;before=#sounds;unrelatedButton.Activated:Fire()
check(#sounds==before,'Unrelated GUI buttons are left alone')
for _,kind in ipairs({'powerCast','powerHit','shield','purchase','lost','deliver','lock','unlock','levelup','ui'})do
 now=now+1
 check(session.play({kind=kind}),'Configured cue plays: '..kind)
 local sound=sounds[#sounds]
 check(sound.IsPlaying and sound.SoundId==config.Cues[kind].Fallback,'Unuploaded effects use only configured built-ins')
 check(sound.Volume>0 and sound.Volume<=1,'Effect volume is bounded')
 check(debris[#debris].life==5,'Every effect has a fallback cleanup lifetime')
 check(not session.play({kind=kind}),'Repeated same-frame cues are debounced')
 sound.Ended:Fire();check(sound.Parent==nil,'Finished sounds immediately free capacity')
end
now=now+1
check(not session.play({kind='purchase',position=Vector3.new(500,0,0)}),'Distant effects are culled')
check(not session.play({kind='purchase',position={X=0,Y=0,Z=0}}),'Non-vector position rejected')
check(not session.play({kind='purchase',position=Vector3.new(0/0,0,0)}),'Non-finite position rejected')
for _,power in ipairs({'tag','dash','gravity','slow','slam','repulse','shield','lightning','kiblast','spinjitzu','royalseal'})do
 now=now+1;check(session.play({kind='powerCast',power=power}),'Each power has a cast cue')
 local s=sounds[#sounds]
 check(math.abs(s.PlaybackSpeed-config.Cues.powerCast.Speed*config.PowerPitch[power])<1e-9,'Power-specific sound pitch comes from trusted config')
 s.Ended:Fire()
end
now=now+1
check(session.play({kind='purchase',position=Vector3.new(80,0,0)}),'Nearby positional cue plays')
local nearby=sounds[#sounds];local base=nearby.Volume
gui:SetAttribute('OPSfxMuted',true)
check(nearby.Volume==0,'Muting SFX silences existing effects immediately')
check(sounds[1].IsPlaying and sounds[1].Volume==.18,'SFX mute does not stop or silence the music')
now=now+1;check(not session.play({kind='levelup'}),'Muted SFX create no new instances')
gui:SetAttribute('OPSfxMuted',false)
check(math.abs(nearby.Volume-base)<1e-9,'Unmuting preserves distance attenuation')
gui:SetAttribute('OPSfxVolume',10)
check(nearby.Volume<=1,'Out-of-range settings clamp safely')
gui:SetAttribute('OPSfxVolume',0/0)
check(nearby.Volume>0 and nearby.Volume<1,'Non-finite volume falls back safely')
gui:SetAttribute('OPSfxVolume',0)
now=now+1;check(not session.play({kind='lost'}),'Zero volume avoids silent instance allocation')
gui:SetAttribute('OPSfxVolume',.55)
-- The bounded pool protects the client even if event names rotate to avoid per-cue gaps.
for i=1,30 do now=now+.15;session.play({kind='powerCast'})end
local count=0
for _,s in ipairs(sounds)do if s.Name~='OriginalBattleMusic' and s.Parent then count=count+1 end end
check(count<=config.MaxSimultaneous,'Simultaneous sound pool is bounded')
session.destroy();session.destroy()
check(#service:GetChildren()==0,'Destroy removes the entire audio folder')
check(not remote.listeners[1].Connected,'Destroy disconnects server events')
check(not gui.DescendantAdded.listeners[1].Connected and not button.Activated.listeners[1].Connected,'Destroy disconnects future GUI and button events')
for _,s in pairs(attrs)do for _,c in ipairs(s.listeners)do check(not c.Connected,'Destroy disconnects settings listeners')end end
check(not session.play({kind='ui'}),'Destroyed sessions cannot create audio')
config.Music.AssetId=0;now=now+1
local unconfigured=client.start(net,gui);local missing=sounds[#sounds]
check(missing.SoundId=='' and not missing.IsPlaying,'Missing music ID never creates a misleading playback attempt')
unconfigured.destroy()
config.Music.AssetId=originalId;now=now+1
local configured=client.start(net,gui);local music=sounds[#sounds]
check(music.SoundId=='rbxassetid://111355988554529' and music.IsPlaying,'The same owner music ID starts again after cleanup')
check(music.Looped==true and music.Volume==.18,'Music loops at a quiet default volume')
gui:SetAttribute('OPMusicMuted',true)
check(not music.IsPlaying and music.Volume==0,'Music mute pauses playback')
now=now+1;check(configured.play({kind='purchase'}),'Music mute leaves SFX available')
check(sounds[#sounds].SoundId==config.Cues.purchase.Fallback,'Music mute does not replace or mute SFX')
sounds[#sounds].Ended:Fire()
gui:SetAttribute('OPMusicMuted',false)
check(music.IsPlaying,'Music resumes after unmuting')
gui:SetAttribute('OPMusicVolume',2)
check(music.Volume==1,'Music volume clamps to Roblox range')
gui:SetAttribute('OPMusicVolume',0)
check(music.Volume==0 and not music.IsPlaying,'Zero music slider pauses playback')
gui:SetAttribute('OPMusicVolume',.35)
check(music.IsPlaying and music.Volume==.35,'Raising music volume resumes the same track')
now=now+1;check(configured.play({kind='purchase',SoundId='rbxassetid://999999'}),'Known cue remains usable with untrusted extra fields')
check(sounds[#sounds].SoundId==config.Cues.purchase.Fallback and music.SoundId=='rbxassetid://111355988554529','Remote fields cannot override cue or music asset IDs')
sounds[#sounds].Ended:Fire()
config.Cues.purchase.AssetId=987654
now=now+1;check(configured.play({kind='purchase'}),'Owner-configured SFX plays')
check(sounds[#sounds].SoundId=='rbxassetid://987654' and sounds[#sounds].PlaybackSpeed==1,'Custom uploads retain their authored pitch')
configured.destroy();os.clock=oldclock
local report={passed=true,assertions=checks,actual_module='AudioClient.lua',configured_music_asset_id='111355988554529',configured_music_routes_exactly=true,unconfigured_music_disabled=true,
 builtin_sfx_verified=true,custom_id_routing_verified=true,mute_controls_verified=true,spam_limits_verified=true,
 cleanup_verified=true,roblox_asset_permissions_tested=false,studio_playback_tested=false}
local file=assert(io.open(arg[2]or'/tmp/opitem-v82-audio.json','w'));file:write(Mock.json(report));file:close()
print('PASS '..checks..' audio assertions; actual configured music, cues, upload guards, independent volume/mute controls, limits and cleanup')
