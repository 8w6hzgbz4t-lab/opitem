"""Execute the actual HUD and power-menu code with a controlled GUI/event adapter."""
from __future__ import annotations
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
    parser.add_argument('--root',type=Path,default=Path('roblox/v75-game'))
    parser.add_argument('--luau',type=Path,default=Path('/workspace/.cache/opitem-tools/luau'))
    parser.add_argument('--report',type=Path)
    args=parser.parse_args()
    sources={name:(args.root/(name+'.lua')).read_text() for name in ('Client','PhaseClient')}
    test=Path('tests/v75_player_hud.lua').read_text()
    harness='local sources={}\n'+'\n'.join('sources['+lua_string(name)+']='+lua_string(source) for name,source in sources.items())
    harness+='\nlocal test=assert(loadstring('+lua_string(test)+'))()\ntest(sources)\n'
    with tempfile.TemporaryDirectory(prefix='opitem-v75-hud-') as task:
        path=Path(task)/'checks.luau';path.write_text(harness)
        result=subprocess.run([str(args.luau.resolve()),str(path)],text=True,capture_output=True)
    print(result.stdout,end='');print(result.stderr,end='')
    if result.returncode:return result.returncode
    match=re.search(r'PLAYER HUD PASS (\d+) assertions',result.stdout)
    assert match,'No assertions executed'
    report={'passed':True,'assertions':int(match.group(1)),'viewports':[[1280,720],[375,667],[812,375],[320,480]],'runtime':'Official Luau CLI; actual Client HUD prefix and complete PhaseClient with GUI/event doubles','limitations':'Studio rendering, native touch controls, physics, live networking and decorative animation execution are not simulated.','sourceHashes':{name+'.lua':hashlib.sha256(source.encode()).hexdigest() for name,source in sources.items()},'testHash':hashlib.sha256(test.encode()).hexdigest()}
    if args.report:args.report.parent.mkdir(parents=True,exist_ok=True);args.report.write_text(json.dumps(report,indent=2)+'\n')
    return 0
if __name__=='__main__':raise SystemExit(main())
