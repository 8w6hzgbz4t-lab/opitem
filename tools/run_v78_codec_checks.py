"""Run actual profile codec/Core round-trips and retain the current source hashes."""
from pathlib import Path
import argparse
import subprocess
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v78-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version78/codec-checks.json'))
    args=parser.parse_args()
    return subprocess.run(['python','tools/run_power_checks.py','--root',str(args.root),'--check','tests/v78_codec.lua','--report',str(args.report)]).returncode
if __name__=='__main__':raise SystemExit(main())
