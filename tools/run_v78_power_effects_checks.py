"""Run actual Ki Blast/Spinjitzu cosmetic renderer with bounded geometry doubles."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path('roblox/v78-game'))
    p.add_argument('--report',type=Path,default=Path('releases/Version78/power-effect-checks.json'))
    a=p.parse_args();a.report.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['texlua','tests/v78_power_effects.lua',str(a.root),str(a.report)],check=True)
    report=json.loads(a.report.read_text());assert report['passed']and report['assertions']>0
    report['source_hashes']={'PowerEffects.lua':hashlib.sha256((a.root/'PowerEffects.lua').read_bytes()).hexdigest()}
    report['test_sha256']=hashlib.sha256(Path('tests/v78_power_effects.lua').read_bytes()).hexdigest()
    report['runner_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    a.report.write_text(json.dumps(report,indent=2)+'\n')
if __name__=='__main__':main()
