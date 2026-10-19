#!/usr/bin/env python3
"""Exercise real PhaseService/Core power paths in official Luau with small API mocks.

No production source is rewritten. Geometry raycasts and Roblox replication are
represented by controlled test doubles; this does not replace Studio testing.
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('roblox/v74-game'))
    parser.add_argument('--check', type=Path, default=Path('tests/v74_powers.lua'))
    parser.add_argument('--luau', type=Path, default=Path('/workspace/.cache/opitem-tools/luau'))
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    sources = {p.relative_to(root).as_posix(): p.read_text() for p in sorted(root.rglob('*.lua'))}
    sources['@check'] = args.check.read_text()
    lines = ['local sources={}']
    lines += [f'sources[{lua_string(name)}]={lua_string(source)}' for name, source in sources.items()]
    lines.append(r'''
local compiled={};local count=0
for name,source in pairs(sources) do
 local chunk,err=loadstring(source,'@'..name)
 assert(chunk,'SYNTAX '..name..': '..tostring(err));compiled[name]=chunk;count+=1
end
print('POWER SYNTAX '..count..' sources compiled verbatim')
local package={Name='OPItemV2'};local nodes={}
for name in pairs(sources) do if name~='@check' then
 local node=package;local parts=string.split(string.sub(name,1,-5),'/')
 for _,part in ipairs(parts) do node[part]=node[part] or {Name=part,Parent=node};node=node[part] end
 node.__path=name;nodes[name]=node
end end
local native=getfenv();local mocks={};local cache={};local loading={}
local function environment(node)
 return setmetatable({script=node},{__index=function(_,key)
  if mocks[key]~=nil then return mocks[key] end
  return native[key]
 end})
end
local function moduleRequire(node)
 assert(type(node)=='table' and node.__path,'Unsupported require target')
 local name=node.__path
 if cache[name]~=nil then return cache[name] end
 assert(not loading[name],'Circular require '..name);loading[name]=true
 local env=environment(node);env.require=moduleRequire;setfenv(compiled[name],env)
 local result=compiled[name]();assert(result~=nil,'Nil module '..name)
 cache[name]=result;loading[name]=nil;return result
end
local env=environment({Parent=package});env.require=moduleRequire
setfenv(compiled['@check'],env)
local check=compiled['@check']()
local result=check(package,moduleRequire,function(values) for key,value in pairs(values) do mocks[key]=value end end)
for _,group in ipairs(result.groups) do print('POWER PASS '..group) end
print('POWER ASSERTIONS '..result.assertions)
''')
    with tempfile.TemporaryDirectory(prefix='opitem-powers-') as task_dir:
        harness = Path(task_dir) / 'checks.luau'
        harness.write_text('\n'.join(lines))
        completed = subprocess.run([str(args.luau.resolve()), str(harness)], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout, end='')
    if completed.returncode:
        return completed.returncode
    groups = re.findall(r'^POWER PASS (.+)$', completed.stdout, flags=re.M)
    assertions = re.search(r'^POWER ASSERTIONS (\d+)$', completed.stdout, flags=re.M)
    assert groups and assertions, 'Suite did not produce results'
    report = {
        'passed': True,
        'assertions': int(assertions.group(1)),
        'groups': groups,
        'sourcesCompiled': len(sources) - 1,
        'runtime': 'Official Luau CLI, production sources executed verbatim',
        'limitations': 'Roblox API test doubles; live Studio rendering, physics, replication and multi-client gameplay not exercised.',
        'sourceHashes': {name: hashlib.sha256(source.encode()).hexdigest() for name, source in sources.items() if name != '@check'},
        'testHash': hashlib.sha256(sources['@check'].encode()).hexdigest(),
    }
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + '\n')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
