"""Execute actual Server snapshot/audio functions, retaining exact production hashes."""
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
    parser.add_argument('--root',type=Path,default=Path('roblox/v76-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version76/server-checks.json'))
    args=parser.parse_args()
    source=(args.root/'Server.lua').read_text()
    sound=source[source.index('local function sound('):source.index('local function los(')]
    send=source[source.index('local function send('):source.index('local function clone(')]
    test=Path('tests/v76_server.lua').read_text()
    harness='local sources={sound='+lua_string(sound)+',send='+lua_string(send)+'}\n'
    harness+='assert(loadstring('+lua_string(test)+'))()(sources)\n'
    with tempfile.TemporaryDirectory(prefix='opitem-v76-server-') as task:
        path=Path(task)/'check.luau';path.write_text(harness)
        result=subprocess.run(['/workspace/.cache/opitem-tools/luau',str(path)],text=True,capture_output=True)
    print(result.stdout,end='');print(result.stderr,end='')
    if result.returncode:return result.returncode
    match=re.search(r'SERVER INTEGRATION PASS (\d+) assertions',result.stdout);assert match
    report={'passed':True,'assertions':int(match.group(1)),
            'runtime':'Official Luau CLI executing actual Server snapshot/audio functions with controlled recipients',
            'source_hashes':{p.relative_to(args.root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(args.root.rglob('*.lua'))},
            'test_sha256':hashlib.sha256(test.encode()).hexdigest(),
            'limitations':'Does not start a Roblox server or exercise replication, asset permissions, or Marketplace.'}
    args.report.parent.mkdir(parents=True,exist_ok=True);args.report.write_text(json.dumps(report,indent=2)+'\n')
    return 0
if __name__=='__main__':raise SystemExit(main())
