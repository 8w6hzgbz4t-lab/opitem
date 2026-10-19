#!/usr/bin/env python3
"""Execute the real developer service in Luau with a small Roblox API fixture.

Production modules are compiled verbatim. The fixture models only character,
network and service APIs; authorization, parsing and mutations are real code.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

from run_game_checks import lua_string


FIXTURE = r'''
local clock=100
local callbacks={}
local fixture={}
local function signal()
 local s={listeners={}}
 function s:Connect(f)
  local c={Connected=true};self.listeners[c]=f
  function c:Disconnect()self.Connected=false end
  return c
 end
 function s:Fire(...)for c,f in pairs(self.listeners)do if c.Connected then f(...)end end end
 function s:Wait()clock+=.05;return .05 end
 return s
end
local vectors={}
function vectors.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,__kind='Vector3'},vectors)end
vectors.__index=function(v,key)
 if key=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end
 if key=='Unit'then return v/v.Magnitude end
 return vectors[key]
end
function vectors:Dot(b)return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
vectors.__add=function(a,b)return vectors.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vectors.__sub=function(a,b)return vectors.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vectors.__unm=function(a)return vectors.new(-a.X,-a.Y,-a.Z)end
vectors.__mul=function(a,b)if type(a)=='number'then return b*a end;return vectors.new(a.X*b,a.Y*b,a.Z*b)end
vectors.__div=function(a,b)return vectors.new(a.X/b,a.Y/b,a.Z/b)end
vectors.zero=vectors.new();vectors.xAxis=vectors.new(1,0,0)
local frames={}
function frames.new(x,y,z)
 local pos=type(x)=='table'and x or vectors.new(x,y,z)
 return setmetatable({Position=pos,LookVector=vectors.new(0,0,-1),__kind='CFrame'},frames)
end
frames.__index=frames
function frames:PointToObjectSpace(pos)return pos-self.Position end
frames.__add=function(a,b)return frames.new(a.Position+b)end
frames.__mul=function(a,b)return frames.new(a.Position+b.Position)end
function frames.Angles()return frames.new()end
local enums=setmetatable({}, {__index=function(self,category)
 local t=setmetatable({}, {__index=function(_,name)return category..'.'..name end})
 rawset(self,category,t);return t
end})
local methods={}
local instanceMeta={}
instanceMeta.__index=function(self,key)
 if methods[key]then return methods[key]end
 if key=='Position'and self._props.CFrame then return self._props.CFrame.Position end
 if self._props[key]~=nil then return self._props[key]end
 for _,c in ipairs(self._children)do if c.Name==key then return c end end
 return nil
end
instanceMeta.__newindex=function(self,key,value)
 if key=='Parent'then
  local before=self._props.Parent
  if before then for i,c in ipairs(before._children)do if c==self then table.remove(before._children,i);break end end end
  self._props.Parent=value
  if value then table.insert(value._children,self)end
 else self._props[key]=value end
 local s=self._signals[key];if s then s:Fire()end
end
local instances={}
local function newInstance(class)
 local i=setmetatable({_props={ClassName=class,Name=class},_children={},_signals={},_attributes={}},instanceMeta)
 if class=='Part'then i.CFrame=frames.new();i.Anchored=false;i.CanCollide=true;i.AssemblyLinearVelocity=vectors.zero
 elseif class=='Humanoid'then
  i.Health=100;i.MaxHealth=100;i.PlatformStand=false;i.AutoRotate=true;i.WalkSpeed=16;i.UseJumpPower=true;i.JumpPower=50;i.JumpHeight=7.2;i.Died=signal()
 elseif class=='RemoteEvent'then i.OnServerEvent=signal();i.calls={}
 elseif class=='Player'then i.Chatted=signal()end
 table.insert(instances,i);return i
end
function methods:IsA(class)return self.ClassName==class or class=='Instance'or(class=='BasePart'and self.ClassName=='Part')end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()
 local out={};local function walk(p)for _,c in ipairs(p._children)do table.insert(out,c);walk(c)end end;walk(self);return out
end
function methods:FindFirstChild(name)for _,c in ipairs(self._children)do if c.Name==name then return c end end end
function methods:WaitForChild(name)return self:FindFirstChild(name)end
function methods:FindFirstChildOfClass(class)for _,c in ipairs(self._children)do if c:IsA(class)then return c end end end
function methods:IsDescendantOf(parent)local p=self.Parent;while p do if p==parent then return true end;p=p.Parent end;return false end
function methods:Destroy()for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil;self._destroyed=true end
function methods:Clone()local i=newInstance(self.ClassName);for k,v in pairs(self._props)do if k~='Parent'then i[k]=v end end;return i end
function methods:SetAttribute(k,v)self._attributes[k]=v end
function methods:GetAttribute(k)return self._attributes[k]end
function methods:GetPropertyChangedSignal(k)if not self._signals[k]then self._signals[k]=signal()end;return self._signals[k]end
function methods:CanSetNetworkOwnership()return true end
function methods:SetNetworkOwner(p)self.networkOwner=p;self.serverOwned=p==nil end
function methods:SetNetworkOwnershipAuto()self.serverOwned=false;self.ownershipRestored=true end
function methods:PivotTo(cf)self.lastPivot=cf;local root=self:FindFirstChild('HumanoidRootPart');if root then root.CFrame=cf end end
function methods:Kick(message)self.kicked=message end
function methods:FireClient(p,payload)table.insert(self.calls,{player=p,payload=payload})end
function methods:FireAllClients(...)table.insert(self.calls,{...})end
local workspace=newInstance('Workspace')
function workspace:GetPartBoundsInBox()return self.blocked and {newInstance('Part')}or{}end
function workspace:GetServerTimeNow()return clock end
function workspace:Blockcast()return nil end
local players={players={},lookupIds={},lookupCalls={}}
function players:GetPlayers()local out={};for _,p in pairs(self.players)do table.insert(out,p)end;return out end
function players:GetPlayerByUserId(id)return self.players[id]end
function players:GetUserIdFromNameAsync(username)
 table.insert(self.lookupCalls,username)
 if self.lookupFailure then error('Fixture identity lookup failed')end
 return assert(self.lookupIds[username],'Fixture username is unconfigured')
end
local run={Heartbeat=signal(),PreSimulation=signal(),IsStudio=function()return true end}
local http={seq=0}
function http:GenerateGUID()self.seq+=1;return 'nonce-'..self.seq end
local text={}
function text:FilterStringAsync(value,id)
 self.lastText=value;self.lastActor=id
 if self.fail then error('Fixture filtering unavailable')end
 return {GetNonChatStringForBroadcastAsync=function()return '[filtered] '..value end}
end
local services={Players=players,RunService=run,HttpService=http,TextService=text,Debris={AddItem=function()end},TweenService={}}
local game={CreatorId=77,CreatorType=enums.CreatorType.User}
function game:GetService(name)return assert(services[name],'Unsupported fixture service: '..name)end
local fakeTask={}
function fakeTask.spawn(f,...)return f(...)end
function fakeTask.defer(f,...)return f(...)end
function fakeTask.delay(delay,f)table.insert(callbacks,{at=clock+delay,run=f})end
function fixture.advance(seconds)
 clock+=seconds
 local ready={};for i=#callbacks,1,-1 do if callbacks[i].at<=clock then table.insert(ready,table.remove(callbacks,i))end end
 for _,c in ipairs(ready)do c.run()end
end
function fixture.setTime(value)clock=value end
function fixture.now()return clock end
function fixture.newPlayer(id,name)
 local p=newInstance('Player');p.UserId=id;p.Name=name or 'SameDisplayName';p.DisplayName='SameDisplayName';p.Parent=workspace
 local pg=newInstance('PlayerGui');pg.Name='PlayerGui';pg.Parent=p
 local character=newInstance('Model');character.Name='Character';character.Parent=workspace;p.Character=character
 local root=newInstance('Part');root.Name='HumanoidRootPart';root.CFrame=frames.new(0,5,0);root.Parent=character
 local h=newInstance('Humanoid');h.Parent=character
 local foot=newInstance('Part');foot.Name='Foot';foot.Parent=character
 local accessory=newInstance('Part');accessory.Name='InitiallyNonColliding';accessory.CanCollide=false;accessory.Parent=character
 players.players[id]=p
 return p,root,h
end
fixture.signal=signal;fixture.newInstance=newInstance;fixture.instances=instances;fixture.workspace=workspace;fixture.game=game
fixture.players=players;fixture.run=run;fixture.text=text;fixture.Vector3=vectors;fixture.CFrame=frames;fixture.Enum=enums
local nativeTypeof=typeof
local testGlobals={
 game=game,workspace=workspace,Vector3=vectors,CFrame=frames,Enum=enums,Instance={new=newInstance},task=fakeTask,
 typeof=function(v)if type(v)=='table'then if v.__kind then return v.__kind elseif getmetatable(v)==instanceMeta then return 'Instance'end end;return nativeTypeof(v)end,
 OverlapParams={new=function()return{}end},RaycastParams={new=function()return{}end},
 Color3={fromRGB=function(r,g,b)return{R=r/255,G=g/255,B=b/255}end,new=function(r,g,b)return{R=r,G=g,B=b}end},
 warn=function(...)print('FIXTURE WARNING',...)end,
 os=setmetatable({clock=function()return clock end},{__index=os}),
}
local nativeGlobals=getfenv()
local function moduleEnv(node)return setmetatable({script=node},{__index=function(_,k)if testGlobals[k]~=nil then return testGlobals[k]end;return nativeGlobals[k]end})end
local packageRoot={Name='OPItemV2'}
local nodes={}
for name in pairs(sources)do
 if string.sub(name,1,1)~='@'then
  local current=packageRoot
  for _,part in ipairs(string.split(string.sub(name,1,-5),'/'))do
   if not current[part]then current[part]={Name=part,Parent=current}end
   current=current[part]
  end
  current.__modulePath=name;nodes[name]=current
  function current:Clone()local i=newInstance('LocalScript');i.Name=self.Name;return i end
 end
end
local compiled={};local count=0
for name,source in pairs(sources)do compiled[name]=assert(loadstring(source,'@'..name));count+=1 end
print('ADMIN SYNTAX '..count..' verbatim sources compiled')
local cache,loading={},{}
local function moduleRequire(node)
 assert(type(node)=='table'and node.__modulePath,'Unsupported require')
 local path=node.__modulePath
 if cache[path]~=nil then return cache[path]end
 assert(not loading[path],'Circular require '..path);loading[path]=true
 local env=moduleEnv(node);env.require=moduleRequire
 setfenv(compiled[path],env)
 local value=compiled[path]();assert(value~=nil,'Module returned nil '..path)
 loading[path]=nil;cache[path]=value;return value
end
local env=moduleEnv({Parent=packageRoot});env.require=moduleRequire
setfenv(compiled['@checks/v74_admin.lua'],env)
local suite=compiled['@checks/v74_admin.lua']()
local result=suite(packageRoot,moduleRequire,fixture)
print('ADMIN PASS '..tostring(result))
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('roblox/v74-game'))
    parser.add_argument('--check', type=Path, default=Path('tests/v74_admin.lua'))
    parser.add_argument('--luau', type=Path, default=Path('/workspace/.cache/opitem-tools/luau'))
    parser.add_argument('--report', type=Path, help='Optional JSON execution report with input hashes')
    args = parser.parse_args()
    sources = {p.relative_to(args.root).as_posix(): p.read_text() for p in sorted(args.root.rglob('*.lua'))}
    sources['@checks/v74_admin.lua'] = args.check.read_text()
    lines = ['local sources={}']
    for name, source in sources.items():
        lines.append(f'sources[{lua_string(name)}]={lua_string(source)}')
    with tempfile.TemporaryDirectory(prefix='opitem-admin-checks-') as directory:
        path = Path(directory) / 'checks.lua'
        path.write_text('\n'.join(lines) + FIXTURE)
        completed = subprocess.run([str(args.luau), str(path)], check=False, text=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout, end='')
    if args.report:
        result = re.search(r'ADMIN PASS (\d+) assertions; (\d+) actual remote commands; (\d+) groups', completed.stdout)
        report = {
            'passed': completed.returncode == 0 and result is not None,
            'engine': 'Official Luau CLI with a lightweight Roblox API fixture',
            'scope': 'Actual AdminConfig, AdminPolicy, AdminService, Core, TransactionCore and catalog execution; no Roblox Studio or live server',
            'assertions': int(result[1]) if result else 0,
            'authorized_command_dispatches': int(result[2]) if result else 0,
            'groups': re.findall(r'ADMIN GROUP PASS (\w+)', completed.stdout),
            'compiled_sources': len(sources),
            'input_sha256': {name: hashlib.sha256(source.encode()).hexdigest()
                             for name, source in sources.items()},
            'runner_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        }
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + '\n')
    return completed.returncode


if __name__ == '__main__':
    raise SystemExit(main())
