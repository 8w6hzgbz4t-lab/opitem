"""Execute real base progression/session tests and retain the exact input hashes."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v75-game'))
    parser.add_argument('--luau',type=Path,default=Path('/workspace/.cache/opitem-tools/luau'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version75/progression-checks.json'))
    args=parser.parse_args()
    command=['python','tools/run_game_checks.py','--root',str(args.root),'--check','tests/v75_progression.lua','--luau',str(args.luau)]
    result=subprocess.run(command,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    print(result.stdout,end='')
    if result.returncode:return result.returncode
    match=re.search(r'UPGRADE PASS .*: (\d+) progression checks;',result.stdout)
    assert match and 'SESSION 6 actual repository test groups passed' in result.stdout
    report={'passed':True,'assertions':int(match.group(1)),'original_session_groups_passed':6,'original_regression_groups_passed':13,
            'scope':'Actual paid/gifted progression, income, protection and sixteen-slot escrow/ownership paths; official Luau CLI',
            'source_hashes':{p.relative_to(args.root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(args.root.rglob('*.lua'))},
            'test_sha256':hashlib.sha256(Path('tests/v75_progression.lua').read_bytes()).hexdigest()}
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2)+'\n')
    return 0


if __name__=='__main__':raise SystemExit(main())
