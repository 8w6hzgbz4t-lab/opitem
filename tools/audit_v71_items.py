#!/usr/bin/env python3
"""Check v71 factory geometry, approved names and normalized real spawn weights."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import subprocess

from audit_v70_items import compile_sources, render_one

ROOT = Path(__file__).resolve().parents[1]


def probability_rows(report: dict) -> tuple[list[dict], list[dict]]:
    """Record exact two-stage Catalog.roll chances from actual loaded values."""
    weights = report['weights']
    tiers = report['tiers']
    assert len(weights) == len(tiers) == 7
    assert all(math.isfinite(w) and w > 0 for w in weights)
    assert all(a > b for a, b in zip(weights, weights[1:]))
    total = sum(weights)
    assert total == 107
    tier_rows, item_rows = [], []
    for tier, (rarity, weight) in enumerate(zip(tiers, weights), 1):
        pool = [item for item in report['catalog'] if item['tier'] == tier]
        assert pool
        pool_total = sum(item['spawnWeight'] for item in pool)
        assert all(math.isfinite(item['spawnWeight']) and item['spawnWeight'] > 0 for item in pool)
        probability = weight / total
        tier_rows.append(dict(rarity=rarity, tier=tier, relative_weight=weight,
                              item_count=len(pool), within_tier_weight_total=pool_total,
                              probability=probability, percent=probability * 100))
        for item in pool:
            conditional = item['spawnWeight'] / pool_total
            overall = probability * conditional
            item_rows.append(dict(id=item['id'], name=item['name'], rarity=rarity, tier=tier,
                                  within_tier_weight=item['spawnWeight'],
                                  conditional_probability=conditional,
                                  conditional_percent=conditional * 100,
                                  global_probability=overall, global_percent=overall * 100,
                                  average_rolls=1 / overall))
        assert math.isclose(sum(item['global_probability'] for item in item_rows if item['tier'] == tier),
                            probability, abs_tol=1e-12)
    assert math.isclose(sum(row['global_probability'] for row in item_rows), 1, abs_tol=1e-12)
    return tier_rows, item_rows


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT/'roblox/v71-game')
    parser.add_argument('--baseline', type=Path, default=ROOT/'roblox/v70-game')
    parser.add_argument('--specs', type=Path, default=Path('/tmp/opitem-v71-items'))
    parser.add_argument('--output', type=Path, default=ROOT/'releases/Version71')
    parser.add_argument('--names', type=Path, default=ROOT/'docs/v71-name-changes.json')
    parser.add_argument('--luau', default='/workspace/.cache/opitem-tools/luau')
    parser.add_argument('--skip-preview', action='store_true')
    args = parser.parse_args()
    args.specs.mkdir(parents=True, exist_ok=True)
    args.output.mkdir(parents=True, exist_ok=True)
    compile_sources(args.root, args.luau)
    subprocess.run(['texlua', 'tests/v71_items.lua', str(args.root), str(args.specs), str(args.baseline)],
                   cwd=ROOT, check=True)
    report = json.loads((args.specs/'audit.json').read_text())
    original = {item['id']: item for item in report['baselineCatalog']}
    current = {item['id']: item for item in report['catalog']}
    approved = json.loads(args.names.read_text())['changes']
    assert len({change['id'] for change in approved}) == len(approved), 'Duplicate approved name change'
    actual_changes = []
    for old in report['baselineCatalog']:
        new = current[old['id']]
        assert {k: v for k, v in old.items() if k != 'name'} == {k: v for k, v in new.items() if k != 'name'}, old['id']
        if new['name'] != old['name']:
            actual_changes.append(dict(id=old['id'], old=old['name'], new=new['name']))
    assert actual_changes == approved, 'Actual display-name changes differ from reviewable approved manifest'
    assert set(current) - set(original) == {'krabby_patty_formula'}, 'Unexpected added IDs'
    assert report['puzzleUnchanged'] and report['changedGeometry'] == ['gary_shell'], 'Expected only the approved Gary shell geometry change'
    report['approvedGeometryChanges'] = ['gary_shell']
    signatures = {}
    for row in report['items']:
        spec = json.loads((args.specs/(row['id']+'.json')).read_text())
        visible = [{key: part[key] for key in ('class', 'size', 'cf', 'color', 'material', 'shape', 'transparency')}
                   for part in spec['parts'] if part['transparency'] < 1]
        signature = hashlib.sha256(json.dumps(visible, sort_keys=True).encode()).hexdigest()
        assert signature not in signatures, f"Duplicate geometry: {signatures.get(signature)} / {row['id']}"
        signatures[signature] = row['id']
        row['geometry_sha256'] = signature
    report['distinct_geometry'] = True
    report['approvedNameChanges'] = actual_changes
    report['limitations'] = ['Offline geometry checks do not simulate Studio rendering, multiplayer, physics or performance.']
    report['sources_sha256'] = {str(path.relative_to(args.root)): hashlib.sha256(path.read_bytes()).hexdigest()
                                for path in sorted(args.root.rglob('*.lua'))}
    (args.output/'items-manifest.json').write_text(json.dumps(report, indent=2)+'\n')
    tiers, items = probability_rows(report)
    spawn = dict(source='Actual v71 Catalog.lua and ExpandedCatalog.lua values executed by the factory audit',
                 rule='Roll rarity first using relative rarity weights, then item using its within-tier weight.',
                 rarity_weight_total=107,
                 note='Relative rarity weights sum to 107; divide by 107 for percentages. Pool size never changes tier frequency.',
                 formula='global_probability = rarity_weight / 107 * item_spawn_weight / within_tier_weight_total',
                 preserved_modifiers=['Swords, axes and pickaxes receive half within-tier weight.',
                                      'Existing configured Pokemon IDs receive 0.2 within-tier weight.'],
                 tiers=tiers, items=items,
                 probability_sum=sum(row['global_probability'] for row in items))
    (args.output/'spawn-rates.json').write_text(json.dumps(spawn, indent=2)+'\n')
    with (args.output/'spawn-rates.csv').open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(items[0]))
        writer.writeheader(); writer.writerows(items)
    with (args.output/'item-names.csv').open('w', newline='') as stream:
        writer = csv.writer(stream)
        writer.writerow(['id', 'previous_name', 'current_name', 'rarity', 'changed'])
        for item in report['catalog']:
            old = original.get(item['id'])
            writer.writerow([item['id'], old['name'] if old else '', item['name'], item['rarity'],
                             old is None or old['name'] != item['name']])
    if not args.skip_preview:
        previews = args.output/'previews'; previews.mkdir(exist_ok=True)
        render_one((str(args.specs/'krabby_patty_formula.json'), str(previews/'krabby_patty_formula.png')))
    print(f"PASS: {len(report['items'])} distinct item models; {report['checks']} structural checks; all previous geometries preserved except approved Gary shell upgrade")
    print(f'PASS: {len(actual_changes)} approved recognizable names; seven rarity pools; all 66 global probabilities sum to one')
    print(f'Wrote {args.output}')


if __name__ == '__main__':
    main()
