"""Package V80 only when current source, product mappings and offline checks agree."""
import csv
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'roblox/v80-game'
RELEASE = ROOT / 'releases/Version80'
EXPECTED_IDS = {
    'pocket': 3720840251, 'stack': 3720846297, 'chest': 3720846778,
    'fortune': 3720847183, 'level_one': 3720847536, 'level_five': 3720847942,
    'unlock_dash': 3720848352, 'unlock_gravity': 3720848733,
    'unlock_slow': 3720849165, 'unlock_slam': 3720849458,
    'unlock_repulse': 3720851934, 'unlock_shield': 3720852231,
    'unlock_lightning': 3720852595, 'unlock_kiblast': 3720852857,
    'unlock_spinjitzu': 3720853158,
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(name):
    return json.loads((RELEASE / name).read_text())


def archive(target, files, relative=ROOT):
    files = sorted(set(files))
    assert all(path.is_file() for path in files)
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as bundle:
        for path in files:
            bundle.write(path, path.relative_to(relative))
    with zipfile.ZipFile(target) as bundle:
        assert bundle.testzip() is None and len(bundle.infolist()) == len(files)
    return dict(file=target.name, bytes=target.stat().st_size,
                sha256=sha(target), files=len(files))


def main():
    preservation = read('preservation-report.json')
    hashes = {path.relative_to(STAGE).as_posix(): sha(path)
              for path in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes) == 106 and hashes == preservation['source_hashes']
    assert preservation['modified_sources'] == ['CashShopConfig.lua']
    assert preservation['original_objects_preserved'] == preservation['total_objects'] == 312
    assert not preservation['added_modules']
    assert preservation['all_other_original_properties_hierarchy_and_backups_preserved']
    assert preservation['all_76_collectible_models_catalog_names_and_stats_preserved']
    baseline = ROOT / 'releases' / preservation['baseline']
    game = ROOT / 'releases' / preservation['output']
    assert sha(baseline) == preservation['baseline_sha256'] == 'ee90a6c724e0f02405bb829e94731fcd744339e8710aef143ce57fee702139e3'
    assert sha(game) == preservation['output_sha256']
    previous = json.loads((ROOT / 'releases/Version79/validation-report.json').read_text())
    assert previous['passed'] and previous['game_sha256'] == sha(baseline)
    assert {name for name in hashes if hashes[name] != previous['source_hashes'][name]} == {'CashShopConfig.lua'}

    checks = {name: read(name + '-checks.json') for name in ('cashshop', 'session', 'server')}
    for name, count, key, test_key, test in (
        ('cashshop', 379, 'sourceHashes', 'testHash', 'v80_cashshop.lua'),
        ('session', 171, 'sourceHashes', 'testHash', 'v78_session.lua'),
        ('server', 24, 'source_hashes', 'test_sha256', 'v79_server.lua'),
    ):
        data = checks[name]
        assert data['passed'] and data['assertions'] == count, name
        assert data[key] == hashes, 'Stale sources: ' + name
        assert data[test_key] == sha(ROOT / 'tests' / test), 'Stale test: ' + name

    configuration = (STAGE / 'CashShopConfig.lua').read_text()
    assert re.search(r'\bEnabled\s*=\s*false\b', configuration)
    assert re.search(r'\bPreviewOnly\s*=\s*true\b', configuration)
    offers = {}
    for line in configuration.splitlines():
        if "{id='" not in line:
            continue
        offer = dict(re.findall(r"(\w+)='([^']*)'", line))
        offer.update({key: int(value) for key, value in re.findall(r'(\w+)=(\d+)', line)})
        assert offer['id'] not in offers
        offers[offer['id']] = offer
    assert {key: value['productId'] for key, value in offers.items()} == EXPECTED_IDS
    assert len(set(EXPECTED_IDS.values())) == len(EXPECTED_IDS) == 15
    with (RELEASE / 'ProductSetup.csv').open(newline='') as stream:
        rows = list(csv.DictReader(stream))
    assert len(rows) == 15 and {row['offer_id'] for row in rows} == set(EXPECTED_IDS)
    progress = read('SetupProgress.json')
    assert progress['status'] == 'configured_checkout_disabled'
    assert progress['configured_product_ids'] == progress['total_product_offers'] == 15
    assert not progress['pending_offer_ids'] and not progress['checkout_enabled']
    assert not progress['verified_with_Roblox'] and progress['music_audio_id'] == 0
    assert set(progress['products']) == set(EXPECTED_IDS)
    for row in rows:
        offer = offers[row['offer_id']]
        saved = progress['products'][row['offer_id']]
        assert int(row['developer_product_id']) == saved['productId'] == offer['productId']
        assert int(row['proposed_robux']) == saved['robux'] == offer['robux']
        assert row['name'] == saved['name'] == offer['name']
        assert row['category'] == offer['category'] and not saved['verified_with_Roblox']
        for key in ('cash', 'levels', 'power'):
            assert row[key] == str(offer.get(key, ''))
    assert re.search(r'Music=\{AssetId=0,', (STAGE / 'AudioConfig.lua').read_text())

    icons_dir = ROOT / 'releases/StoreIcons/Remaining14'
    historical_icons = json.loads((icons_dir / 'icon-manifest.json').read_text())
    icon_files = []
    icon_records = []
    assert {row['offer_id'] for row in historical_icons['icons']} == set(EXPECTED_IDS)
    for row in historical_icons['icons']:
        path = icons_dir / row['file']
        raw = path.read_bytes()
        assert raw[:8] == b'\x89PNG\r\n\x1a\n' and struct.unpack('>II', raw[16:24]) == (512, 512)
        assert sha(path) == row['sha256']
        assert row['proposed_robux'] == offers[row['offer_id']]['robux']
        icon_files.append(path)
        icon_records.append({key: row[key] for key in ('offer_id', 'file', 'sha256', 'width', 'height')})
    icon_files.append(icons_dir / 'All15_ProductIcons.png')
    assert sha(icon_files[-1]) == historical_icons['preview_sha256']
    art_dir = ROOT / 'releases/Version79_ArtworkUpdate'
    art = json.loads((art_dir / 'art-manifest.json').read_text())
    assert len(art['files']) == 2 and not art['uploaded_to_roblox']
    for row in art['files']:
        assert sha(art_dir / row['file']) == row['sha256']

    results = {name: data['assertions'] for name, data in checks.items()}
    report = dict(
        passed=True, game=game.name, game_sha256=sha(game),
        baseline=baseline.name, baseline_sha256=sha(baseline),
        active_sources_compiled=106, source_hashes=hashes,
        modified_sources=['CashShopConfig.lua'], unchanged_active_sources=105,
        original_objects_preserved=312, collectibles_preserved=76,
        all_other_original_properties_hierarchy_and_backups_preserved=True,
        current_offline_assertions=results,
        configured_product_ids=EXPECTED_IDS, configured_product_count=15,
        product_ids_source='User-provided; not verified against Roblox',
        current_Roblox_prices_verified=False, product_ownership_verified=False,
        checkout_live=False, preview_only=True, music_asset_configured=False,
        product_icon_upload_files=icon_records,
        inherited_evidence='Version79/validation-report.json; all gameplay, saving, receipt service, UI, flight, art and geometry sources are byte-identical to V79.',
        studio_playtest_performed=False, live_receipts_tested=False,
        published_to_roblox=False, public_launch_readiness_verified=False,
        limitations='Production Luau executed with controlled API/storage doubles. Real Roblox product ownership/prices, receipts, DataStore latency, multiplayer, devices, physics/performance and audio permissions remain owner-run gates.',
    )
    (RELEASE / 'validation-report.json').write_text(json.dumps(report, indent=2) + '\n')
    lines = [
        '# V80 test results', '',
        '**Offline checks pass. Actual Studio and Roblox purchase testing remain required.**', '',
        '| Production-code suite | Assertions |', '| --- | ---: |',
    ]
    lines += [f'| {name} | {count} |' for name, count in results.items()]
    lines += [
        '', 'All 106 active Lua sources compile. The shop suite checks every configured ID against its intended reward, cancellation, disabled checkout, price mismatch, owned/capped rewards and receipt retries. The session suite checks saved grants, rejoin, crash/ambiguous-write recovery and ownership transfers. The server suite checks snapshot, audio and owner-only theft notifications.',
        '', 'These suites execute actual production source with controlled Roblox API/storage doubles. They do not verify real Robux charges, Roblox ownership, current prices, production DataStore behavior or Studio multiplayer.',
        '', 'Only CashShopConfig.lua differs from V79. The other 105 active sources, all 312 original place objects, hierarchy/properties/backups and all 76 collectible designs/stats match the preserved baseline. Existing V79 evidence covers unchanged systems; those entire suites were not rerun for this configuration-only change.',
        '', 'All 15 IDs match the owner messages, CSV, setup JSON and embedded Studio source. Checkout stays off. Music has not been uploaded; its asset ID remains zero. All 15 provided product PNGs pass their recorded hashes and 512×512 PNG dimension checks.',
        '', 'Use PRIVATE_TEST_STEPS.md and the wider Version78/LAUNCH_CHECKLIST.md before release. Nothing has been published to Roblox by this build. Public launch readiness remains unverified.',
        '', 'Game SHA-256: `' + sha(game) + '`.', '',
    ]
    (RELEASE / 'TEST_RESULTS.md').write_text('\n'.join(lines))

    outputs = [archive(ROOT / 'releases/Version80_Game.zip', [game], ROOT / 'releases')]
    with zipfile.ZipFile(ROOT / 'releases/Version80_Game.zip') as bundle:
        assert bundle.namelist() == [game.name]
        assert hashlib.sha256(bundle.read(game.name)).hexdigest() == sha(game)
    files = [game, baseline, ROOT / 'README.md', ROOT / 'releases/VERSION_80_HANDOFF.md',
             ROOT / 'releases/StealAnOPItem_77_RobuxOffers.rbxlx'] + icon_files
    for directory in (
        STAGE, ROOT / 'roblox/v79-game', ROOT / 'roblox/v78-game', ROOT / 'roblox/v77-game',
        ROOT / 'roblox/v76-game', ROOT / 'roblox/v75-game', ROOT / 'roblox/v74-game',
        RELEASE, ROOT / 'releases/Version79', ROOT / 'releases/Version78',
        ROOT / 'releases/Version77', ROOT / 'releases/Version76', art_dir,
    ):
        files += [path for path in directory.rglob('*')
                  if path.is_file() and '__pycache__' not in path.parts]
    files += [path for path in (ROOT / 'tools').iterdir()
              if path.is_file() and path.suffix in {'.py', '.lua'}]
    files += list((ROOT / 'tests').glob('*.lua'))
    for required in ('README.md', 'PRODUCT_IDS.md', 'PRIVATE_TEST_STEPS.md', 'TEST_RESULTS.md'):
        assert (RELEASE / required).is_file()
    outputs.append(archive(ROOT / 'releases/Version80_SourceAndGame.zip', files))
    assert all(row['bytes'] < 100_000_000 for row in outputs)
    (ROOT / 'releases/Version80_DOWNLOADS.json').write_text(json.dumps(outputs, indent=2) + '\n')
    for row in outputs:
        print(row['file'], row['bytes'], 'bytes', row['sha256'])


if __name__ == '__main__':
    main()
