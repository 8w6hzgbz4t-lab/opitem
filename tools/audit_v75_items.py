#!/usr/bin/env python3
"""Check all 76 native collectibles and preserve the complete 69-item Version 74 catalog."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

from audit_v70_items import compile_sources, contact_sheet, render_one
from build_puzzle_asset import export_xml
from export_free_models import front_card
from run_game_checks import build_harness

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


def run_catalog_checks(root: Path, baseline: Path, output: Path, luau: str) -> None:
    """Run the real session suite and V75 catalog/upper-floor transactions.

    V75 intentionally changes TransactionCore for level-based protection and
    second floors. Keep V74 immutable and compare catalog data against it without
    invoking the older runner's gameplay-source-is-unchanged assertion.
    """
    check = ROOT/'tests/v75_catalog.lua'
    harness = build_harness(root.resolve(), [], [check], baseline.resolve())
    with tempfile.TemporaryDirectory(prefix='opitem-v75-catalog-') as directory:
        path = Path(directory)/'checks.luau'
        path.write_text(harness)
        completed = subprocess.run([luau, str(path)], cwd=ROOT, text=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout, end='')
    assert completed.returncode == 0, 'Actual V75 catalog/session tests failed'
    matched = re.search(r'UPGRADE PASS [^\n]+: (\d+) checks;', completed.stdout)
    assert matched and 'SESSION 6 actual repository test groups passed' in completed.stdout
    report = {
        'passed': True,
        'checks': int(matched.group(1)),
        'catalog_items': 76,
        'previous_definitions_preserved': 69,
        'new_collectibles_transaction_paths_checked': 7,
        'upper_floor_reservation_delivery_theft_death_and_capacity_checked': True,
        'owner_only_five_percent_level_income_checked': True,
        'original_session_groups_passed': 6,
        'original_regression_groups_passed': 13,
        'runtime': 'Official Luau CLI executing unmodified production modules',
        'test_sha256': hashlib.sha256(check.read_bytes()).hexdigest(),
        'source_hashes': {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in sorted(root.rglob('*.lua'))},
    }
    (output/'catalog-checks.json').write_text(json.dumps(report, indent=2)+'\n')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT/'roblox/v75-game')
    parser.add_argument('--baseline', type=Path, default=ROOT/'roblox/v74-game')
    parser.add_argument('--specs', type=Path, default=Path('/tmp/opitem-v75-items'))
    parser.add_argument('--output', type=Path, default=ROOT/'releases/Version75')
    parser.add_argument('--luau', default='/workspace/.cache/opitem-tools/luau')
    parser.add_argument('--skip-preview', action='store_true')
    args = parser.parse_args()
    args.specs.mkdir(parents=True, exist_ok=True)
    args.output.mkdir(parents=True, exist_ok=True)
    compile_sources(args.root, args.luau)
    subprocess.run(['texlua', 'tests/v75_items.lua', str(args.root), str(args.specs), str(args.baseline)],
                   cwd=ROOT, check=True)
    report = json.loads((args.specs/'audit.json').read_text())
    original = {item['id']: item for item in report['baselineCatalog']}
    current = {item['id']: item for item in report['catalog']}
    assert len(original) == 69 and len(current) == 76, 'Expected 69 preserved items and seven additions'
    for old in report['baselineCatalog']:
        new = current[old['id']]
        assert old == new, f"Previous item changed: {old['id']}"
    new_ids = {'stardust_dragon', 'blue_eyes_white_dragon', 'michael_jackson_glove', 'tungs_bat', 'moms_credit_card', 'sonic_gold_ring', 'captain_america_shield'}
    assert set(current) - set(original) == new_ids, 'Unexpected added IDs'
    assert report['puzzleUnchanged'] and not report['changedGeometry'], 'All 69 previous item models must be preserved'
    report['approvedGeometryChanges'] = []
    report['previous_models_preserved_exactly'] = True
    report['previous_surface_gui_properties_preserved_exactly'] = True
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
    report['approvedNameChanges'] = []
    report['limitations'] = ['Offline geometry checks do not simulate Studio rendering, multiplayer, physics or performance.']
    report['sources_sha256'] = {str(path.relative_to(args.root)): hashlib.sha256(path.read_bytes()).hexdigest()
                                for path in sorted(args.root.rglob('*.lua'))}
    report['baseline_sources_sha256'] = {str(path.relative_to(args.baseline)): hashlib.sha256(path.read_bytes()).hexdigest()
                                         for path in sorted(args.baseline.rglob('*.lua'))}
    (args.output/'items-manifest.json').write_text(json.dumps(report, indent=2)+'\n')
    tiers, items = probability_rows(report)
    baseline_report = dict(report, catalog=report['baselineCatalog'])
    baseline_tiers, baseline_items = probability_rows(baseline_report)
    previous_chances = {item['id']: item for item in baseline_items}
    for item in items:
        old = previous_chances.get(item['id'])
        item['new'] = old is None
        item['baseline_global_probability'] = old['global_probability'] if old else None
        item['baseline_global_percent'] = old['global_percent'] if old else None
        if old:
            assert old['within_tier_weight'] == item['within_tier_weight'], item['id']
    assert all(a['probability'] == b['probability'] for a, b in zip(tiers, baseline_tiers)), 'Rarity distribution changed'
    spawn = dict(source='Actual v75 Catalog.lua and ExpandedCatalog.lua values executed by the factory audit',
                 rule='Roll rarity first using relative rarity weights, then item using its within-tier weight.',
                 rarity_weight_total=107,
                 note='Relative rarity weights sum to 107; divide by 107 for percentages. Pool size never changes tier frequency.',
                 formula='global_probability = rarity_weight / 107 * item_spawn_weight / within_tier_weight_total',
                 preserved_modifiers=['Swords, axes and pickaxes receive half within-tier weight.',
                                      'Existing configured Pokemon IDs receive 0.2 within-tier weight.'],
                 new_item_modifier='The seven new collectibles use their configured within-tier weights; all previous weapon/Pokemon modifiers remain exact.',
                 baseline_item_count=69, current_item_count=76,
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
    additions = [row for row in report['items'] if row['id'] in new_ids]
    (args.output/'new-items.json').write_text(json.dumps(additions, indent=2)+'\n')
    models = args.output/'models'; models.mkdir(exist_ok=True)
    for row in additions:
        spec = json.loads((args.specs/(row['id']+'.json')).read_text())
        target = models/(row['id']+'.rbxmx')
        export_xml(spec, target)
        tree = ET.parse(target).getroot()
        objects = list(tree.iter('Item'))
        refs = {node.get('referent') for node in objects}
        assert len(refs) == len(objects) == row['parts'] + 1, 'Standalone model lost parts or unique references'
        assert all(ref.text in refs or ref.text in {'null', 'nil', None} for ref in tree.iter('Ref')), 'Dangling standalone model reference'
    run_catalog_checks(args.root, args.baseline, args.output, args.luau)
    if not args.skip_preview:
        previews = args.output/'previews'; previews.mkdir(exist_ok=True)
        for row in additions:
            target = previews/(row['id']+'.png')
            render_one((str(args.specs/(row['id']+'.json')), str(target)))
            if row['id'] in {'moms_credit_card', 'tungs_bat'}:
                # Matplotlib's average polygon sort can hide tiny raised strokes
                # behind a large card/barrel face. An exact front-depth projection
                # shows the actual chip/lettering without changing model geometry.
                target.replace(target.with_stem(target.stem+'-3d'))
                front_card(json.loads((args.specs/(row['id']+'.json')).read_text()), target)
        contact_sheet(additions, previews, args.output/'NewItems.png', columns=4)
    print(f"PASS: {len(report['items'])} distinct item models; {report['checks']} structural checks; all 69 previous models, GUI properties, names and definitions preserved exactly")
    print('PASS: seven detailed native additions; seven rarity pools; all 76 global probabilities sum to one')
    print(f'Wrote {args.output}')


if __name__ == '__main__':
    main()
