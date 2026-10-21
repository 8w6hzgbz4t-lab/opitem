"""Run actual Core/Codec/ProfileStore/PersistentSession integration and crash checks."""
import argparse
from pathlib import Path
import subprocess

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path('roblox/v78-game'))
    p.add_argument('--report',type=Path,default=Path('releases/Version78/session-checks.json'))
    a=p.parse_args()
    return subprocess.run(['python','tools/run_power_checks.py','--root',str(a.root),'--check','tests/v78_session.lua','--report',str(a.report)]).returncode
if __name__=='__main__':raise SystemExit(main())
