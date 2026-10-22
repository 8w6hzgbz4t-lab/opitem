"""Exercise configured music/cues offline and verify the exact ID in native Luau."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
from run_game_checks import lua_string


NATIVE = r'''
local count=0
local function check(value,why)count+=1;assert(value,why)end
local function signal()
 local s={listeners={}}
 function s:Connect(f)local c={Connected=true};self.listeners[c]=f;function c:Disconnect()self.Connected=false end;return c end
 function s:Fire(...)for c,f in pairs(self.listeners)do if c.Connected then f(...)end end end
 return s
end
local sounds={};local service={}
local function instance(kind)
 local object={ClassName=kind,IsPlaying=false}
 function object:Play()self.IsPlaying=true;self.plays=(self.plays or 0)+1 end
 function object:Pause()self.IsPlaying=false end
 function object:Stop()self.IsPlaying=false end
 function object:Destroy()self.Parent=nil end
 if kind=='Sound'then sounds[#sounds+1]=object end
 return object
end
local settings,signals={},{}
local gui={DescendantAdded=signal()}
function gui:GetDescendants()return{}end
function gui:GetAttribute(key)return settings[key]end
function gui:GetAttributeChangedSignal(key)signals[key]=signals[key]or signal();return signals[key]end
function gui:SetAttribute(key,value)settings[key]=value;self:GetAttributeChangedSignal(key):Fire()end
local net={WaitForChild=function(_,name)assert(name=='Audio');return{OnClientEvent=signal()}end}
local config=assert(loadstring(sources['AudioConfig.lua']))()
local env=setmetatable({
 game={GetService=function(_,name)if name=='SoundService'then return service end;if name=='Debris'then return{AddItem=function()end}end;error(name)end},
 script={Parent={WaitForChild=function(_,name)assert(name=='AudioConfig');return name end}},
 require=function(name)assert(name=='AudioConfig');return config end,
 Instance={new=instance},
},{__index=getfenv()})
for name,source in pairs(sources)do assert(loadstring(source,'@'..name));end
local chunk=assert(loadstring(sources['AudioClient.lua'],'@AudioClient.lua'));setfenv(chunk,env)
local client=chunk();local session=client.start(net,gui);local music=sounds[1]
check(config.Music.AssetId==111355988554529,'Owner asset ID not configured exactly')
check(music.SoundId=='rbxassetid://111355988554529','Native Luau changed asset ID formatting or precision')
check(music.IsPlaying and music.Looped and music.Volume==.18,'Configured track is not playing/looped at default volume')
check(client.start(net,gui)==session and #sounds==1,'Repeated start duplicated music')
gui:SetAttribute('OPSfxMuted',true)
check(music.IsPlaying and music.Volume==.18,'SFX mute changed music')
gui:SetAttribute('OPMusicMuted',true)
check(not music.IsPlaying and music.Volume==0,'Music mute failed')
gui:SetAttribute('OPMusicMuted',false)
check(music.IsPlaying and music.SoundId=='rbxassetid://111355988554529','Unmute failed to resume exact configured music')
gui:SetAttribute('OPMusicVolume',0)
check(not music.IsPlaying,'Zero music volume did not pause')
gui:SetAttribute('OPMusicVolume',.4)
check(music.IsPlaying and music.Volume==.4,'Raising volume did not resume')
session.destroy()
check(not music.IsPlaying,'Destroy did not stop playback')
config.Music.AssetId=0
local disabled=client.start(net,gui)
check(sounds[#sounds].SoundId=='' and not sounds[#sounds].IsPlaying,'Zero asset ID attempted playback')
disabled.destroy()
print('NATIVE AUDIO PASS '..count..' assertions')
'''


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v82-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version82/audio-checks.json'))
    parser.add_argument('--luau',type=Path,default=Path('/workspace/.cache/opitem-tools/luau'))
    args=parser.parse_args()
    args.report.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['texlua','tests/v82_audio.lua',str(args.root),str(args.report)],check=True)
    report=json.loads(args.report.read_text())
    assert report['passed'] and report['configured_music_asset_id']=='111355988554529'
    # The historical mock JSON encoder formats numbers to 12 significant digits.
    # Keep this long identifier as text across that adapter, then encode it exactly.
    report['configured_music_asset_id']=int(report['configured_music_asset_id'])
    sources={path.relative_to(args.root).as_posix():path.read_text()for path in sorted(args.root.rglob('*.lua'))}
    harness='local sources={}\n'+'\n'.join('sources['+lua_string(name)+']='+lua_string(source)for name,source in sources.items())+'\n'+NATIVE
    with tempfile.TemporaryDirectory(prefix='opitem-v82-audio-')as directory:
        path=Path(directory)/'audio.luau';path.write_text(harness)
        result=subprocess.run([str(args.luau),str(path)],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    print(result.stdout,end='')
    assert result.returncode==0,'Native Luau audio check failed'
    match=re.search(r'NATIVE AUDIO PASS (\d+) assertions',result.stdout);assert match
    report['compatibility_assertions']=report['assertions']
    report['native_luau_assertions']=int(match[1])
    report['assertions']+=int(match[1])
    report['compiled_sources']=len(sources)
    report['runtime']='Actual AudioClient/AudioConfig with texlua Roblox sound/GUI doubles; native official Luau compiles all production sources and executes exact configured-ID playback/volume routing with minimal sound doubles'
    report['source_hashes']={name:hashlib.sha256(source.encode()).hexdigest()for name,source in sources.items()}
    report['test_sha256']=hashlib.sha256(Path('tests/v82_audio.lua').read_bytes()).hexdigest()
    report['runner_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    report['limits']='No real Roblox audio request, moderation, asset ownership, universe permission or native playback test; Sound.Play records intent only.'
    metrics=json.loads(Path('releases/Version76/Audio/audio-metrics.json').read_text())
    for name,digest in metrics['files'].items():
        assert hashlib.sha256((Path('releases/Version76/Audio')/name).read_bytes()).hexdigest()==digest,name
    assert metrics['original_composition']and not metrics['sampled_audio']
    assert metrics['music_peak']<.9 and metrics['music_loop_boundary_jump']<.04
    report['assets']=metrics
    args.report.write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
