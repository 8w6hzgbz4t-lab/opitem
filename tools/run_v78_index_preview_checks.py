"""Exercise actual index camera fitting against all native collectible templates."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v78-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version78/index-preview-checks.json'))
    args=parser.parse_args();args.report.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['texlua','tests/v78_index_preview.lua',str(args.root),str(args.report)],check=True)
    report=json.loads(args.report.read_text());assert report['passed']and report['actual_factory_items']==76
    report['source_hashes']={p.relative_to(args.root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()for p in sorted(args.root.rglob('*.lua'))}
    report['test_sha256']=hashlib.sha256(Path('tests/v78_index_preview.lua').read_bytes()).hexdigest()
    args.report.write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
