"""Render actual level-five base geometry, with a separately labeled cutaway."""
from __future__ import annotations

import argparse
import copy
import json
import os
from pathlib import Path

import numpy as np

import preview_v72_bases as renderer


def parts_for_base(spec, cutaway=False):
    rotation = np.diag([-1., 1., -1.])
    result = []
    for source in spec['parts']:
        part = copy.deepcopy(source)
        cf = np.asarray(part['cf'], dtype=float)
        center = rotation @ (cf[:3] - [-84., 0., -57.])
        if abs(center[0]) > 26 or abs(center[2]) > 26 or not (-.1 <= center[1] <= 42):
            continue
        if part['transparency'] >= .85 or part['name'] == 'ProtectionField':
            continue
        if cutaway and (
            center[1]>35 or 'Roof' in part['name'] or 'Cornice' in part['name'] or part['name'].startswith(('EntranceRune','VentGem'))
            or part['name'].startswith(('UpperSolid', 'UpperWall', 'UpperWindow', 'UpperFacade', 'UpperFront', 'SolidSideWall', 'SolidBackWall', 'CornerPier'))
        ):
            continue
        part['cf'] = list(center) + list((rotation @ cf[3:].reshape(3, 3)).reshape(-1))
        result.append(part)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--world', type=Path, default=Path('/tmp/opitem-v75-upper-world.json'))
    parser.add_argument('--output', type=Path, default=Path('releases/Version75/UpperFloor.png'))
    args = parser.parse_args()
    os.environ.setdefault('MPLCONFIGDIR', '/tmp/opitem-v75-matplotlib')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    spec = json.loads(args.world.read_text())
    fig, axes = plt.subplots(1, 2, figsize=(16, 8.5), facecolor='#151b2a')
    counts = []
    for ax, cutaway, title in zip(axes, (False, True), ('LEVEL 5 · FITTED EXTERIOR', 'INTERIOR CUTAWAY · 8 + 8 DISPLAYS')):
        renderer.local_base = lambda source, cut=cutaway: parts_for_base(source, cut)
        counts.append(renderer.render(spec, ax))
        ax.set_title(title, color='#e8c877', fontsize=16, pad=14)
    fig.suptitle('THE UPPER RELIC GALLERY', color='#edf1f7', fontsize=24, y=.96)
    fig.text(.05, .055, 'Solid roof and walls  /  Rear switchback stairs  /  Matching green protection line', color='#bbc8d9', fontsize=13)
    fig.text(.05, .025, 'Actual generated geometry. Right image hides exterior walls/roof for review; they remain solid in-game. Studio lighting and lettering will differ.', color='#8598b1', fontsize=10)
    fig.subplots_adjust(left=.02, right=.98, top=.87, bottom=.11, wspace=.025)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=130, facecolor=fig.get_facecolor())
    plt.close(fig)
    print(f'Rendered actual level-five base ({counts[0]} / {counts[1]} visible parts): {args.output}')


if __name__ == '__main__':
    main()
