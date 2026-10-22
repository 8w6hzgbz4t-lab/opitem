"""Check actual base desk bounds, original interactions and eight-base geometry budget."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v83-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version83/base-workbench-checks.json'))
    args=parser.parse_args()
    args.report.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['texlua','tests/v83_base_workbench.lua',str(args.root),str(args.report)],check=True)
    report=json.loads(args.report.read_text())
    assert report['passed']and report['assertions']>0 and report['bases']==8
    report['source_hashes']={'BaseWorkbench.lua':hashlib.sha256((args.root/'BaseWorkbench.lua').read_bytes()).hexdigest()}
    report['test_sha256']=hashlib.sha256(Path('tests/v83_base_workbench.lua').read_bytes()).hexdigest()
    report['runner_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    args.report.write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
