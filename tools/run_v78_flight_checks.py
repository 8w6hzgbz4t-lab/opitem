import argparse
import hashlib
import json
from pathlib import Path
import subprocess
def main():
    p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path('roblox/v78-game'));p.add_argument('--report',type=Path,default=Path('releases/Version78/flight-pose-checks.json'));a=p.parse_args()
    a.report.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['texlua','tests/v78_flight_pose.lua',str(a.root),str(a.report)],check=True)
    data=json.loads(a.report.read_text());assert data['passed']and data['assertions']>0
    data['source_hashes']={name:hashlib.sha256((a.root/name).read_bytes()).hexdigest()for name in ('FlightPose.lua','FlightPoseClient.lua','AdminService.lua')}
    data['test_sha256']=hashlib.sha256(Path('tests/v78_flight_pose.lua').read_bytes()).hexdigest()
    a.report.write_text(json.dumps(data,indent=2)+'\n')
if __name__=='__main__':main()
