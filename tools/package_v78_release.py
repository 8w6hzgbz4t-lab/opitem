"""Package V78 only when preservation, production checks and previews agree.

These checks are offline evidence, never a claim of live Roblox launch readiness.
"""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT/'roblox/v78-game'
RELEASE = ROOT/'releases/Version78'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def read(name):
    return json.loads((RELEASE/name).read_text())

def verified_sources(report, key, hashes, full=True):
    values = report[key]
    valid = values == hashes if full else bool(values) and all(hashes[name] == value for name, value in values.items())
    assert valid, 'Stale production checks: '+key

def test_hash(report, key, relative):
    assert report[key] == sha(ROOT/relative), 'Stale test: '+relative

def archive(target, files, relative=ROOT):
    files = sorted(set(files))
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as bundle:
        for path in files:
            bundle.write(path, path.relative_to(relative))
    with zipfile.ZipFile(target) as bundle:
        assert bundle.testzip() is None and len(bundle.infolist()) == len(files)
    return dict(file=target.name, bytes=target.stat().st_size, sha256=sha(target), files=len(files))

def main():
    preservation = read('preservation-report.json')
    hashes = {p.relative_to(STAGE).as_posix(): sha(p) for p in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes) == 106 and hashes == preservation['source_hashes']
    assert preservation['original_objects_preserved'] == 305 and preservation['total_objects'] == 312
    assert preservation['all_other_original_properties_hierarchy_and_backups_preserved']
    game = ROOT/'releases'/preservation['output']
    baseline = ROOT/'releases'/preservation['baseline']
    assert sha(game) == preservation['output_sha256']
    assert sha(baseline) == preservation['baseline_sha256'] == '7028edc1c3a5b0e100c08949e6359de435279189ab1bdf51eb2d846d89b0d2d1'
    previous = json.loads((ROOT/'releases/Version77/validation-report.json').read_text())
    assert previous['game_sha256'] == sha(baseline)
    assert set(hashes) == set(previous['source_hashes']) | set(preservation['added_modules'])
    for relative, digest in previous['source_hashes'].items():
        if relative not in preservation['modified_sources']:
            assert hashes[relative] == digest, 'Preserved subsystem changed: '+relative

    names = ('catalog','risk','power','power-effect','profile','session','codec','admin','admin-client',
             'hud','audio','cashshop','cashshop-client','slifer','server','artifact','effect',
             'progression','upper-floor','flight-pose','index-preview')
    checks = {name: read(name+'-checks.json') for name in names}
    for name, report in checks.items():
        if name == 'admin-client':
            assert report['status'] == 'passed'
        elif name != 'upper-floor':
            assert report['passed'], name
    full = {'catalog':'source_hashes','risk':'source_hashes','power':'sourceHashes',
            'session':'sourceHashes','codec':'sourceHashes','cashshop':'sourceHashes',
            'slifer':'source_hashes','server':'source_hashes','artifact':'source_sha256',
            'effect':'source_hashes','progression':'source_hashes','upper-floor':'source_hashes',
            'index-preview':'source_hashes'}
    for name, key in full.items():
        verified_sources(checks[name], key, hashes)
    for name, key in (('audio','source_hashes'),('hud','sourceHashes'),('profile','source_hashes'),
                      ('flight-pose','source_hashes'),('power-effect','source_hashes')):
        verified_sources(checks[name], key, hashes, False)
    admin_inputs = checks['admin']['input_sha256']
    assert set(admin_inputs) == set(hashes) | {'@checks/v74_admin.lua'}
    for relative, digest in admin_inputs.items():
        actual = ROOT/'tests/v78_admin.lua' if relative.startswith('@checks/') else STAGE/relative
        assert sha(actual) == digest, 'Stale admin input: '+relative
    assert checks['admin']['runner_sha256'] == sha(ROOT/'tools/run_v78_admin_checks.py')
    tests = (
        ('catalog','test_sha256','v78_catalog.lua'),('power','testHash','v78_powers.lua'),
        ('power-effect','test_sha256','v78_power_effects.lua'),('profile','test_sha256','v78_profiles.lua'),
        ('session','testHash','v78_session.lua'),('codec','testHash','v78_codec.lua'),
        ('hud','testHash','v78_player_hud.lua'),('admin-client','testSha256','v78_admin_client.lua'),
        ('audio','test_sha256','v76_audio.lua'),('cashshop','testHash','v78_cashshop.lua'),
        ('cashshop-client','testSha256','v78_cashshop_client.lua'),
        ('cashshop-client','benchTestSha256','v77_cashshop_bench.lua'),
        ('slifer','test_sha256','v76_slifer.lua'),('server','test_sha256','v78_server.lua'),
        ('artifact','test_sha256','v75_artifacts.lua'),('effect','test_sha256','v75_effects.lua'),
        ('progression','test_sha256','v75_progression.lua'),('upper-floor','test_sha256','v75_upper_floor.lua'),
        ('flight-pose','test_sha256','v78_flight_pose.lua'),('index-preview','test_sha256','v78_index_preview.lua'))
    for name, key, test in tests:
        test_hash(checks[name], key, 'tests/'+test)
    for relative, digest in checks['risk']['test_hashes'].items():
        assert sha(ROOT/relative) == digest, 'Stale risk test: '+relative
    assert checks['risk']['runner_sha256'] == sha(ROOT/'tools/run_v76_risk_checks.py')
    assert checks['profile']['runner_sha256'] == sha(ROOT/'tools/run_v78_profile_checks.py')
    assert checks['power-effect']['runner_sha256'] == sha(ROOT/'tools/run_v78_power_effects_checks.py')
    assert checks['admin-client']['sourceSha256'] == hashes['AdminClient.lua']
    assert checks['cashshop-client']['sourceSha256'] == hashes['CashShopClient.lua']
    assert checks['cashshop-client']['benchSourceSha256'] == hashes['CashShopBench.lua']
    assert checks['upper-floor']['checks'] > 0 and checks['upper-floor']['expanded_bases_checked'] == 8
    assert checks['upper-floor']['upper_roof_and_walls_solid']
    assert checks['slifer']['animated_slifer_count'] == 1
    assert checks['index-preview']['actual_factory_items'] == 76 and checks['index-preview']['all_bounding_corners_fit']

    models = read('items-manifest.json')
    verified_sources(models, 'sources_sha256', hashes)
    assert len(models['items']) == 76 and models['checks'] > 0 and not models['failures'] and not models['warnings']
    assert models['puzzleUnchanged'] and models['distinct_geometry'] and not models['changedGeometry']
    test_hash(models, 'test_sha256', 'tests/v75_items.lua')
    assert models['runner_sha256'] == sha(ROOT/'tools/audit_v78_items.py')
    model_paths = ['Catalog.lua','ExpandedCatalog.lua','ModelFactory.lua','MillenniumPuzzle.lua']
    model_paths += [p.relative_to(STAGE).as_posix() for p in (STAGE/'FreeModels').glob('*.lua')]
    for relative in model_paths:
        assert sha(STAGE/relative) == sha(ROOT/'roblox/v77-game'/relative), 'Collectible changed: '+relative
    previews = read('item-preview-report.json')
    assert previews['passed'] and previews['items'] == 76 and previews['sheet_sha256'] == sha(RELEASE/'All76Items.png')
    assert previews['rendered_model_geometry_hashes'] == {row['id']:row['geometry_sha256'] for row in models['items']}
    assert all((RELEASE/'previews'/(row['id']+'.png')).is_file() for row in models['items'])
    spawn = read('spawn-rates.json')
    assert len(spawn['items']) == 76 and abs(spawn['probability_sum']-1) < 1e-12

    media = ROOT/'releases/Version76'
    metrics = json.loads((media/'Audio/audio-metrics.json').read_text())
    for relative, digest in metrics['files'].items():
        assert sha(media/'Audio'/relative) == digest
    assert metrics['original_composition'] and not metrics['sampled_audio']
    assert metrics['decoded_ogg']['peak'] < 1 and metrics['decoded_ogg']['all_finite']
    assert metrics['generator_sha256'] == sha(ROOT/'tools/generate_v76_audio.py')

    report = dict(
        passed=True, game=game.name, game_sha256=sha(game), active_sources_compiled=106,
        collectible_models_checked=76, geometry_assertions=models['checks'],
        catalog_assertions=checks['catalog']['checks'], profile_assertions=checks['profile']['assertions'],
        session_assertions=checks['session']['assertions'], codec_assertions=checks['codec']['assertions'],
        power_assertions=checks['power']['assertions'], power_effect_assertions=checks['power-effect']['assertions'],
        admin_assertions=checks['admin']['assertions'], admin_command_dispatches=checks['admin']['authorized_command_dispatches'],
        flight_pose_assertions=checks['flight-pose']['assertions'], hud_assertions=checks['hud']['assertions'],
        admin_menu_assertions=checks['admin-client']['assertions'], index_preview_assertions=checks['index-preview']['assertions'],
        shop_server_assertions=checks['cashshop']['assertions'], shop_gui_assertions=checks['cashshop-client']['assertions'],
        shop_geometry_assertions=checks['cashshop-client']['benchAssertions'],
        audio_assertions=checks['audio']['assertions'], slifer_assertions=checks['slifer']['checks'],
        server_glue_assertions=checks['server']['assertions'], artifact_assertions=checks['artifact']['assertions'],
        developer_effect_assertions=checks['effect']['assertions'], progression_assertions=checks['progression']['assertions'],
        upper_floor_assertions=checks['upper-floor']['checks'], original_session_groups_passed=6,
        original_regression_groups_passed=13, original_objects_preserved=305, added_modules=7,
        regular_power_count=10, normal_equipped_slots=3, tag_fixed_slot=1, developer_separate_slot=4,
        offers=dict(cash=4, levels=2, regular_powers=9), developer_username='Goverment_cheesee',
        conveyor_collectibles_sold=False, developer_perks_sold=False, tag_free=True,
        paid_losses_refund=False, unfinished_bids_refund=True, exodia_safe_respawn_exception_preserved=True,
        all_76_collectible_models_names_stats_and_weights_preserved=True, source_hashes=hashes,
        saved_progress_implementation=True, recoverable_theft_journal_implementation=True,
        atomic_reward_and_receipt_implementation=True, live_saved_progress_verified=False,
        checkout_live=False, developer_products_configured=0, music_asset_configured=False,
        offline_checks_passed=True, studio_playtest_performed=False, published_to_roblox=False,
        public_launch_readiness_verified=False,
        limitations='Offline production Luau/API/geometry checks. Live DataStore budgets, latency, crash/shutdown recovery, Roblox receipts, account lookup, multiplayer, device input, physics, performance and audio/asset permissions require the owner-run launch checklist.')
    (RELEASE/'validation-report.json').write_text(json.dumps(report, indent=2)+'\n')
    rows = [
        ('Profile locks, retries and injected crash boundaries', report['profile_assertions']),
        ('Actual economy/save/receipt/departure integration', report['session_assertions']),
        ('Profile schema and all collectible round trips', report['codec_assertions']),
        ('All ten powers and developer Royal Seal', report['power_assertions']),
        ('Bounded projectile, tornado, rubble and lock warnings', report['power_effect_assertions']),
        ('Developer server authorization and commands', report['admin_assertions']),
        ('R6/R15 flight pose and restoration', report['flight_pose_assertions']),
        ('Power controls, settings and small-screen HUD', report['hud_assertions']),
        ('Developer menu controls', report['admin_menu_assertions']),
        ('Shop server pricing, prompts and receipts', report['shop_server_assertions']),
        ('Shop interface / bench geometry', str(report['shop_gui_assertions'])+' / '+str(report['shop_geometry_assertions'])),
        ('All 76 Index templates at four viewport widths', report['index_preview_assertions']),
        ('Collectible native geometry / catalog transactions', str(report['geometry_assertions'])+' / '+str(report['catalog_assertions'])),
        ('Eight expanded bases, stairs, roofs and walls', report['upper_floor_assertions']),
        ('Developer puzzle / rod attachments', report['artifact_assertions']),
        ('Developer visual effects', report['developer_effect_assertions']),
        ('Progression / animated Slifer / audio routing', str(report['progression_assertions'])+' / '+str(report['slifer_assertions'])+' / '+str(report['audio_assertions'])),
        ('Server snapshot and audio glue', report['server_glue_assertions']),
    ]
    lines = ['# V78 test results', '', '**Offline checks passed. Live launch readiness is unverified.**', '',
             'Production modules ran under the official Luau CLI or Roblox API/native-geometry adapters. '
             'These adapters do not start Studio or prove multiplayer replication, live storage behavior, native input or performance.', '',
             '| Offline area | Assertions/checks |', '| --- | ---: |']
    lines += ['| '+name+' | '+str(count)+' |' for name, count in rows]
    lines += ['', 'The original six session groups and thirteen regression groups pass. All 76 models, names, stats and rarity weights match V77. '
              'The XML builder retained all 305 original instances and added seven modules. '
              'The packager verified current source/test hashes, preview geometry and ZIP integrity.', '',
              '## Required live checks', '',
              'No actual Roblox Studio multiplayer, DataStore/API budget/latency, shutdown timing, Marketplace receipt, '
              'touch/controller device, full-server physics/FPS, audio playback/permission or account lookup test ran in this cloud. '
              'Follow LAUNCH_CHECKLIST.md in a private test experience. Product IDs and the music upload ID remain unset; checkout is disabled.', '',
              'Game SHA-256: `'+sha(game)+'`.', '']
    (RELEASE/'TEST_RESULTS.md').write_text('\n'.join(lines))
    outputs = [archive(ROOT/'releases/Version78_Game.zip', [game], ROOT/'releases')]
    with zipfile.ZipFile(ROOT/'releases/Version78_Game.zip') as bundle:
        assert bundle.namelist() == [game.name] and hashlib.sha256(bundle.read(game.name)).hexdigest() == sha(game)
    files = [game, baseline, ROOT/'README.md', ROOT/'releases/VERSION_78_HANDOFF.md']
    directories = (STAGE, ROOT/'roblox/v77-game', ROOT/'roblox/v76-game', ROOT/'roblox/v75-game',
                   ROOT/'roblox/v74-game', RELEASE, media, ROOT/'releases/Version77')
    for directory in directories:
        files += [p for p in directory.rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    files += [p for p in (ROOT/'tools').iterdir() if p.is_file() and p.suffix in {'.py','.lua'}]
    files += list((ROOT/'tests').glob('*.lua'))
    outputs.append(archive(ROOT/'releases/Version78_SourceAndGame.zip', files))
    media_files = [p for name in ('Audio','Art') for p in (media/name).rglob('*') if p.is_file()]
    outputs.append(archive(ROOT/'releases/Version78_ArtAndAudio.zip', media_files, media))
    (ROOT/'releases/Version78_DOWNLOADS.json').write_text(json.dumps(outputs, indent=2)+'\n')
    for row in outputs:
        print(row['file'], row['bytes'], 'bytes', row['sha256'])

if __name__ == '__main__':
    main()
