#!/usr/bin/env python3
"""Exercise the actual carry/presentation modules with small Roblox API doubles.

This covers server snapshot timing and metadata reset, cached billboard geometry,
and the client's actual RenderStepped callback. It does not simulate Roblox
replication latency, rendering, or multiplayer physics; verify those in Studio.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import tempfile


def lua_string(value: str) -> str:
    equals = "="
    while "]" + equals + "]" in value:
        equals += "="
    return "[" + equals + "[" + value + "]" + equals + "]"


SERVER_MOCK = r'''
local now=0
local vectorMeta={}
vectorMeta.__index=vectorMeta
vectorMeta.__add=function(a,b)return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vectorMeta)end
local Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vectorMeta)end}
local CFrame={new=function(pos)return {Position=pos}end}
local UDim2={fromOffset=function(x,y)return {width=x,height=y}end,new=function(...)return {...}end}
local UDim={new=function(...)return {...}end}
local Color3={fromRGB=function(...)return {...}end}
local Enum={Font={GothamBold='GothamBold'}}
local function instance(class)
 local node={ClassName=class,Name=class,children={}}
 function node:FindFirstChild(name)return self.children[name]end
 return setmetatable(node,{__newindex=function(t,k,v)
  if k=='Parent' and v then v.children[t.Name]=t end
  rawset(t,k,v)
 end})
end
local Instance={new=instance}
local services={}
local game={GetService=function(_,name)return services[name] or {}end}
local script={Parent={PhaseConfig='rules',PowerCatalog='powers',ItemPresentation='presentation',BaseEntrance='entrance'}}
local modules={powers={},entrance={}}
local environment=setmetatable({game=game,script=script,Vector3=Vector3,CFrame=CFrame,UDim2=UDim2,UDim=UDim,Color3=Color3,Enum=Enum,Instance=Instance,os={clock=function()return now end},require=function(key)return assert(modules[key],key)end},{__index=getfenv()})
local function loadModule(source,name)
 local chunk=assert(loadstring(source,name));setfenv(chunk,environment);return chunk()
end
'''

SERVER_CHECKS = r'''
local model={attributes={},PrimaryPart={Position=Vector3.new(0,0,0)},bboxCalls=0,pivots=0}
function model:SetAttribute(key,value)self.attributes[key]=value end
function model:GetAttribute(key)return self.attributes[key]end
function model:GetBoundingBox()self.bboxCalls+=1;return {Position=Vector3.new(0,2,0)},{Y=4}end
function model:PivotTo(cf)self.pivots+=1;self.cf=cf end
local gui=instance('BillboardGui');local label={Parent=gui}
local def={name='Test Relic',rarity='Legendary',id='item01',tier=1,income=25,price=100}
local catalog={ById={item01=def},Colors={{255,100,50}}}
Presentation.update(model,label,def,catalog)
assert(gui.Size.width==176 and gui.Size.height==62,'Compact fixed-pixel item label')
assert(label.TextSize==12 and label.TextScaled==false and gui.MaxDistance==75,'Label sizing and range')
assert(gui.StudsOffset.Y==4.8,'Label clears actual art geometry')
Presentation.update(model,label,def,catalog)
assert(model.bboxCalls==1,'Geometry must only be measured once')
local p7={UserId=7};local p8={UserId=8}
local roots={[7]={Position=Vector3.new(20,5,0)},[8]={Position=Vector3.new(80,5,0)}}
local runtime={[7]={player=p7,shield=100,base={slots={{Position=Vector3.new(10,2.9,10)}}}},[8]={player=p8,shield=100}}
local item={kind='item01',state='PurchaseCarry',carrier=7}
local core={items={uid=item},offers={},transactions={}}
local visual={model=model,label=label,prompt={},presented=true}
local service=setmetatable({core=core,models={uid=visual},markers={},ctx={runtime=runtime,catalog=catalog,body=function(p)return roots[p.UserId]end}},{__index=PhaseService})
service:syncVisuals()
assert(model.pivots==1 and model.cf.Position.Y==8.2,'Initial carry snapshot and offset')
assert(model:GetAttribute('CarrierUserId')==7 and model:GetAttribute('Carried')==true,'Carrier metadata')
assert(visual.prompt.Enabled==false and runtime[7].shield==0,'No carrying prompt or retained shield')
now=.05;roots[7].Position=Vector3.new(22,5,0);service:syncVisuals()
now=.199;service:syncVisuals();assert(model.pivots==1,'No heartbeat-rate carry snapshots')
now=.201;service:syncVisuals();assert(model.pivots==2 and model.cf.Position.X==22,'Scheduled fallback snapshot')
item.carrier=8;service:syncVisuals()
assert(model.pivots==3 and model:GetAttribute('CarrierUserId')==8 and model.cf.Position.X==80,'New carrier snapshot is immediate')
item.state='Stored';item.owner=7;item.slot=1;item.carrier=nil;service:syncVisuals()
assert(model:GetAttribute('Carried')==false and model:GetAttribute('CarrierUserId')==nil,'Carrier metadata clears after delivery/drop')
assert(model:GetAttribute('CarryVisualOffset')==nil and visual.lastCarrySnapshot==nil,'Carry-only values clear')
assert(visual.prompt.Enabled and model:GetAttribute('DisplayCF'),'Stored display and steal prompt restored')
assert(model.bboxCalls==1,'Sync never remeasures cached art')
print('CARRY PASS: snapshot timing, immediate carrier changes, drop reset, stored prompts, cached compact labels')
'''

CLIENT_MOCK = r'''
local vectorMeta={__add=function(a,b)return {X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z}end}
local Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vectorMeta)end}
local CFrame={new=function(pos)return {Position=pos}end}
local root={Position=Vector3.new(30,5,9)}
local character={FindFirstChild=function(_,key)assert(key=='HumanoidRootPart');return root end}
local carrier={Character=character}
local Players={GetPlayerByUserId=function(_,id)assert(id==7);return carrier end}
local model={attributes={Carried=true,CarrierUserId=7,CarryVisualOffset=3.2},pivots=0}
function model:GetAttribute(key)return self.attributes[key]end
function model:PivotTo(cf)self.pivots+=1;self.cf=cf end
local animated={[model]=true}
local reduced=true
local updateRoofs=function()end
local workspace={GetServerTimeNow=function()return 1 end}
local renderCallback
local Run={RenderStepped={Connect=function(_,fn)renderCallback=fn end}}
'''

CLIENT_CHECKS = r'''
renderCallback(1/120)
assert(model.pivots==1 and model.cf.Position.X==30 and model.cf.Position.Y==8.2,'Carry follows root before 30 Hz throttle with reduced FX')
root.Position=Vector3.new(35,8,10)
renderCallback(1/120)
assert(model.pivots==2 and model.cf.Position.X==35 and model.cf.Position.Y==11.2,'Every frame reads the current character root')
carrier.Character=nil
renderCallback(1/120)
assert(model.pivots==2,'Missing character leaves server fallback intact')
print('CLIENT CARRY PASS: frame-rate root following, reduced FX, no character fallback')
'''

def server_harness(root: Path) -> str:
    source = SERVER_MOCK
    source += "\nmodules.rules=loadModule(" + lua_string((root / "PhaseConfig.lua").read_text()) + ",'PhaseConfig')\n"
    source += "assert(modules.rules.CarryVisualOffset==3.2 and modules.rules.CarryServerInterval==.2,'Configured carry presentation defaults')\n"
    source += "local Presentation=loadModule(" + lua_string((root / "ItemPresentation.lua").read_text()) + ",'ItemPresentation')\nmodules.presentation=Presentation\n"
    source += "local PhaseService=loadModule(" + lua_string((root / "PhaseService.lua").read_text()) + ",'PhaseService')\n"
    return source + SERVER_CHECKS


def client_harness(root: Path) -> str:
    source = (root / "Client.lua").read_text()
    start = source.index("local elapsed=0\nRun.RenderStepped:Connect")
    stop = source.index("action:FireServer('ready')", start)
    return CLIENT_MOCK + source[start:stop] + CLIENT_CHECKS


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1] / "roblox/game")
    parser.add_argument("--luau", required=True, type=Path, help="Path to the official Luau CLI")
    args = parser.parse_args()
    passed = True
    with tempfile.TemporaryDirectory(prefix="opitem-carry-checks-") as task_directory:
        for name, harness in (("server", server_harness(args.root)), ("client", client_harness(args.root))):
            path = Path(task_directory) / f"{name}.luau"
            path.write_text(harness)
            result = subprocess.run([str(args.luau.resolve()), str(path)], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
            print(result.stdout.rstrip(), flush=True)
            passed = result.returncode == 0 and passed
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
