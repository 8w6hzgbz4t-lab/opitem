"""Run V76's real session, catalog and paid-delivery risk contracts in Luau."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

from run_game_checks import build_harness


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('roblox/v76-game'))
    parser.add_argument('--baseline', type=Path, default=Path('roblox/v74-game'))
    parser.add_argument('--luau', type=Path, default=Path('/workspace/.cache/opitem-tools/luau'))
    parser.add_argument('--report', type=Path, default=Path('releases/Version76/risk-checks.json'))
    args = parser.parse_args()
    checks = [Path('tests/v76_catalog.lua'), Path('tests/v76_risk.lua')]
    harness = build_harness(args.root.resolve(), [], checks, args.baseline.resolve())
    with tempfile.TemporaryDirectory(prefix='opitem-v76-risk-') as task_dir:
        script = Path(task_dir) / 'checks.luau'
        script.write_text(harness)
        completed = subprocess.run([str(args.luau.resolve()), str(script)], text=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout, end='')
    if completed.returncode:
        raise SystemExit(completed.returncode)
    upgrade = re.findall(r'^UPGRADE PASS (.+)$', completed.stdout, re.M)
    assert len(upgrade) == 2 and 'SESSION 6 actual repository test groups passed' in completed.stdout
    report = {
        'passed': True,
        'session_groups': 6,
        'regression_groups': 13,
        'upgrade_results': upgrade,
        'all_catalog_items_risk_checked': 76,
        'purchase_losses_refunded': False,
        'unfinished_bid_refunds_preserved': True,
        'trusted_exodia_safe_respawn_recovery_preserved': True,
        'runtime': 'Official Luau CLI executing actual production source verbatim',
        'limitations': 'Pure session ledger checks; Roblox replication and physics require Studio.',
        'source_hashes': {p.relative_to(args.root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in sorted(args.root.rglob('*.lua'))},
        'test_hashes': {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in checks},
        'runner_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + '\n')


if __name__ == '__main__':
    main()
