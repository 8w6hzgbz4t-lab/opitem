"""Run actual audio module checks and validate synthesized asset metadata."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path('roblox/v76-game'))
    parser.add_argument('--report',type=Path,default=Path('releases/Version76/audio-checks.json'))
    args=parser.parse_args()
    args.report.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['texlua','tests/v76_audio.lua',str(args.root),str(args.report)],check=True)
    report=json.loads(args.report.read_text())
    assert report['passed'] and report['assertions']>0
    report['source_hashes']={name:hashlib.sha256((args.root/name).read_bytes()).hexdigest() for name in ('AudioClient.lua','AudioConfig.lua')}
    report['test_sha256']=hashlib.sha256(Path('tests/v76_audio.lua').read_bytes()).hexdigest()
    metrics=json.loads(Path('releases/Version76/Audio/audio-metrics.json').read_text())
    for name,digest in metrics['files'].items():
        path=Path('releases/Version76/Audio')/name
        assert hashlib.sha256(path.read_bytes()).hexdigest()==digest,name
    assert metrics['original_composition'] and not metrics['sampled_audio']
    assert metrics['music_peak']<.9 and metrics['music_loop_boundary_jump']<.04
    report['assets']=metrics
    args.report.write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':main()
