"""Audit actual V76 scenery cleanup and bind results to the tested source."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('roblox/v76-game'))
    parser.add_argument('--report', type=Path, default=Path('releases/Version76/slifer-checks.json'))
    args = parser.parse_args()
    check = Path('tests/v76_slifer.lua')
    args.report.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['texlua', str(check), str(args.root), str(args.report)], check=True)
    report = json.loads(args.report.read_text())
    assert report['passed'] and report['checks'] > 0 and report['animated_slifer_count'] == 1
    report['source_hashes'] = {p.relative_to(args.root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                               for p in sorted(args.root.rglob('*.lua'))}
    report['test_sha256'] = hashlib.sha256(check.read_bytes()).hexdigest()
    report['runner_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    args.report.write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
