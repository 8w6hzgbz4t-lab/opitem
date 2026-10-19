"""Render actual World.build geometry around the shared market presentation.

Run tests/v72_presentation.lua first to record /tmp/opitem-v72-world.json.
This is an offline geometry review, not a Roblox lighting/physics screenshot.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from build_puzzle_asset import faces

BACKGROUND = '#171f2d'
FOREGROUND = '#e8dfc9'
MUTED = '#aab7c6'


def clipped(face, low, high):
    """Crop polygons to the cutaway, including large original floor slabs."""
    points = list(face)
    for axis in range(3):
        for boundary, keep_greater in ((low[axis], True), (high[axis], False)):
            output = []
            if not points:
                return None
            previous = points[-1]
            previous_inside = previous[axis] >= boundary if keep_greater else previous[axis] <= boundary
            for current in points:
                current_inside = current[axis] >= boundary if keep_greater else current[axis] <= boundary
                if current_inside != previous_inside:
                    ratio = (boundary - previous[axis]) / (current[axis] - previous[axis])
                    output.append(previous + ratio * (current - previous))
                if current_inside:
                    output.append(current)
                previous, previous_inside = current, current_inside
            points = output
    return np.array(points) if len(points) >= 3 else None


def scene(spec, target, limits, view):
    low, high = np.array(limits[0]), np.array(limits[1])
    groups = {}
    for part in spec['parts']:
        position = np.array(part['cf'][:3])
        half = np.abs(np.array(part['cf'][3:]).reshape(3, 3)) @ (np.array(part['size']) * .5)
        if part['transparency'] >= .9 or np.any(position + half < low) or np.any(position - half > high):
            continue
        if part['name'].startswith(('DomainPanel', 'DomainBackstop')):
            continue
        for face in faces(part):
            face = clipped(face, low, high)
            if face is None:
                continue
            color = tuple(round(value, 5) for value in part['color'])
            group = groups.setdefault(color, {'color': color, 'vertices': [], 'faces': []})
            start = len(group['vertices'])
            group['vertices'].extend(face[:, [0, 2, 1]].tolist())
            group['faces'].append(list(range(start, start + len(face))))
    geometry_path = Path('/tmp') / f'v72-plaza-{view}-blender.json'
    geometry_path.write_text(json.dumps({'groups': list(groups.values())}))
    environment = os.environ.copy()
    environment['MESA_SHADER_CACHE_DIR'] = '/tmp/opitem-mesa-shader-cache'
    Path(environment['MESA_SHADER_CACHE_DIR']).mkdir(exist_ok=True)
    result = subprocess.run([
        'blender', '--background', '--python', str(Path(__file__).with_name('render_v72_plaza_blender.py')),
        '--', str(geometry_path), str(target), view,
    ], env=environment, capture_output=True, text=True)
    Path(f'/tmp/v72-plaza-{view}-blender.log').write_text(result.stdout + result.stderr)
    if result.returncode:
        raise RuntimeError(f'Blender {view} render failed: {result.stderr[-4000:]}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--world', type=Path, default=Path('/tmp/opitem-v72-world.json'))
    parser.add_argument('--output', type=Path, default=Path('releases/Version72/PlazaPresentation.png'))
    args = parser.parse_args()
    spec = json.loads(args.world.read_text())
    args.output.parent.mkdir(parents=True, exist_ok=True)
    scene(spec, '/tmp/v72-market-overview.png', ((-128, -.6, -33), (127, 24, 33)), 'market')
    scene(spec, '/tmp/v72-powerlab-detail.png', ((-10, -.4, 11), (10, 7, 29)), 'lab')
    scene(spec, '/tmp/v72-portal-detail.png', ((108, -.4, -16), (126, 23, 16)), 'portal')
    canvas = Image.new('RGB', (1800, 1180), BACKGROUND)
    draw = ImageDraw.Draw(canvas)
    font_path = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    title = ImageFont.truetype(font_path, 36)
    body = ImageFont.truetype(font_path, 22)
    small = ImageFont.truetype(font_path, 19)
    draw.text((44, 27), 'THE RELIC MARKET', font=title, fill=FOREGROUND)
    draw.text((45, 77), 'Slate promenades  /  Bronze relic inlays  /  A shared fantasy and technology palette', font=body, fill=MUTED)
    overview = Image.open('/tmp/v72-market-overview.png').resize((1740, 510), Image.Resampling.LANCZOS)
    canvas.paste(overview, (30, 113))
    for path, x, caption in [
        ('/tmp/v72-powerlab-detail.png', 30, 'POWER LAB  •  original interaction anchor retained'),
        ('/tmp/v72-portal-detail.png', 915, 'RIFT ARRIVAL  •  original ring and item passage retained'),
    ]:
        image = Image.open(path).resize((855, 500), Image.Resampling.LANCZOS)
        canvas.paste(image, (x, 635))
        draw.text((x + 13, 627), caption, font=small, fill=FOREGROUND)
    draw.text((44, 1143), 'Actual generated geometry. Offline cutaway; in-game SurfaceGui labels and Studio lighting will differ.', font=small, fill=MUTED)
    canvas.save(args.output)
    print(f'Wrote actual shared-area geometry review to {args.output}')


if __name__ == '__main__':
    main()
