"""Run actual native developer spell effects with controlled client services."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v75-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version75/effect-checks.json'))
    args=parser.parse_args()
    args.report.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['texlua','tests/v75_effects.lua',str(args.root),str(args.report)],check=True)
    report=json.loads(args.report.read_text())
    assert report['passed'] and report['assertions']>0
    report['source_hashes']={p.relative_to(args.root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(args.root.rglob('*.lua'))}
    report['test_sha256']=hashlib.sha256(Path('tests/v75_effects.lua').read_bytes()).hexdigest()
    args.report.write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
