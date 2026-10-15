#!/usr/bin/env python3
"""Run the Meshy handoff's offline Python and actual-module Luau checks."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]

def literal(value):
    equals='='
    while ']'+equals+']' in value:equals+='='
    return 'string.sub(['+equals+'[x'+value+']'+equals+'],2)'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau',type=Path)
    args=parser.parse_args()
    subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-p','test_meshy_client.py'],cwd=ROOT,check=True)
    binary=args.luau or shutil.which('luau')
    if not binary:
        candidate=Path('/workspace/.cache/opitem-tools/luau')
        binary=candidate if candidate.exists() else None
    if not binary:
        print('SKIP: native Roblox loader checks require the official Luau CLI; pass --luau PATH')
        return 0
    sources={
        'mock':(ROOT/'tools/roblox_mock.lua').read_text(),
        'assets':(ROOT/'meshy/MeshyAssets.lua').read_text(),
        'loader':(ROOT/'meshy/MeshyModelLoader.lua').read_text(),
    }
    lines=['local sources={}']
    for name,source in sources.items():lines.append('sources['+literal(name)+']='+literal(source))
    integration=(ROOT/'meshy/FactoryIntegration.lua').read_text()
    lines.append('assert(loadstring('+literal(integration)+',"@FactoryIntegration.lua"))')
    suite=(ROOT/'tests/meshy_loader.lua').read_text()
    lines.append('local suite=assert(loadstring('+literal(suite)+',"@tests/meshy_loader.lua"))()')
    lines.append('local result=suite(sources);assert(type(result)=="string" and #result>0);print("LOADER PASS: "..result)')
    with tempfile.TemporaryDirectory(prefix='opitem-meshy-check-') as temp:
        path=Path(temp)/'check.luau';path.write_text('\n'.join(lines))
        subprocess.run([str(binary),str(path)],cwd=ROOT,check=True)
    return 0

if __name__=='__main__':raise SystemExit(main())
