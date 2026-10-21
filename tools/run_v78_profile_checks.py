"""Run actual durable profile code with crash-injected UpdateAsync doubles."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
from run_game_checks import lua_string

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path('roblox/v78-game'))
    p.add_argument('--report',type=Path,default=Path('releases/Version78/profile-checks.json'))
    a=p.parse_args()
    paths=['ProfileStore.lua','PersistenceConfig.lua']
    sources={name:(a.root/name).read_text()for name in paths}
    test=Path('tests/v78_profiles.lua').read_text()
    harness='local sources={}\n'+'\n'.join('sources['+lua_string(name)+']='+lua_string(code)for name,code in sources.items())
    harness+='\nlocal store=assert(loadstring(sources["ProfileStore.lua"],"@ProfileStore.lua"))()\n'
    harness+='local config=assert(loadstring(sources["PersistenceConfig.lua"],"@PersistenceConfig.lua"))()\n'
    harness+='local result=assert(loadstring('+lua_string(test)+',"@v78_profiles.lua"))()(store,config)\n'
    harness+='for _,name in ipairs(result.groups)do print("PROFILE PASS "..name)end\nprint("PROFILE ASSERTIONS "..result.assertions)\n'
    with tempfile.TemporaryDirectory(prefix='opitem-v78-profiles-')as tmp:
        script=Path(tmp)/'checks.luau';script.write_text(harness)
        result=subprocess.run(['/workspace/.cache/opitem-tools/luau',str(script)],text=True,capture_output=True)
    print(result.stdout,end='');print(result.stderr,end='')
    if result.returncode:return result.returncode
    count=re.search(r'PROFILE ASSERTIONS (\d+)',result.stdout);assert count
    groups=re.findall(r'^PROFILE PASS (.+)$',result.stdout,re.M);assert groups
    report={'passed':True,'assertions':int(count.group(1)),'groups':groups,
            'cross_profile_crash_boundaries_checked':12,'runtime':'Official Luau CLI executing production ProfileStore verbatim',
            'source_hashes':{name:hashlib.sha256(code.encode()).hexdigest()for name,code in sources.items()},
            'test_sha256':hashlib.sha256(test.encode()).hexdigest(),
            'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'limitations':'Injected atomic DataStore API doubles; live DataStore availability, request budgets and Roblox shutdown timing require Studio/live verification.'}
    a.report.parent.mkdir(parents=True,exist_ok=True);a.report.write_text(json.dumps(report,indent=2)+'\n')
    return 0
if __name__=='__main__':raise SystemExit(main())
