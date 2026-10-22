"""Exercise the actual Server join and request wiring with controlled players."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
from run_game_checks import lua_string


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v83-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version83/join-checks.json'))
    args=parser.parse_args()
    source=(args.root/'Server.lua').read_text()
    join=source[source.index('local function join(p)'):source.index('phase=require(script.Parent.PhaseService)')]
    action=source[source.index('action.OnServerEvent:Connect(function(p,verb,arg)'):source.index('local tickAcc,moveAcc,saveAcc=')]
    prompt=source[source.index('local function prompt(anchor,title,cb,offset)'):source.index('local function send(p)')]
    test=Path('tests/v83_join.lua').read_text()
    harness='local sources={join='+lua_string(join)+',action='+lua_string(action)+',prompt='+lua_string(prompt)+',config='+lua_string((args.root/'Config.lua').read_text())+'}\n'
    harness+='assert(loadstring('+lua_string(test)+'))()(sources)\n'
    with tempfile.TemporaryDirectory(prefix='opitem-v83-join-')as d:
        path=Path(d)/'join.luau';path.write_text(harness)
        result=subprocess.run(['/workspace/.cache/opitem-tools/luau',str(path)],text=True,capture_output=True)
    print(result.stdout,end='');print(result.stderr,end='')
    if result.returncode:return result.returncode
    match=re.search(r'JOIN PASS (\d+) assertions',result.stdout);assert match
    report={'passed':True,'assertions':int(match[1]),'source_hashes':{p.relative_to(args.root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()for p in sorted(args.root.rglob('*.lua'))},'test_sha256':hashlib.sha256(test.encode()).hexdigest(),'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'runtime':'Official Luau executing actual Server join, action dispatch and prompt helper with controlled player/character/storage-boundary doubles','limitations':'Not real Roblox matchmaking, Studio replication or production profile storage. Creator Dashboard Maximum Players still requires owner verification.'}
    args.report.parent.mkdir(parents=True,exist_ok=True);args.report.write_text(json.dumps(report,indent=2)+'\n')
    return 0


if __name__=='__main__':raise SystemExit(main())
