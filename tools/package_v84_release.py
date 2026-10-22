"""Package the V84 earnings display fix with current offline evidence."""
import json
from pathlib import Path
import zipfile

from package_v80_release import archive, sha

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'roblox/v84-game'
RELEASE = ROOT / 'releases/Version84'


def main():
    preservation = json.loads((RELEASE / 'preservation-report.json').read_text())
    hashes = {p.relative_to(STAGE).as_posix(): sha(p) for p in sorted(STAGE.rglob('*.lua'))}
    assert hashes == preservation['source_hashes'] and len(hashes) == 109
    assert preservation['modified_sources'] == ['Server.lua'] and not preservation['added_modules']
    assert preservation['original_objects_preserved'] == preservation['total_objects'] == 315
    assert preservation['all_other_original_properties_hierarchy_and_backups_preserved']
    assert preservation['saved_fractional_earnings_and_collection_logic_unchanged']
    game = ROOT / 'releases' / preservation['output']
    baseline = ROOT / 'releases' / preservation['baseline']
    assert sha(game) == preservation['output_sha256']
    assert sha(baseline) == preservation['baseline_sha256']
    previous = json.loads((ROOT / 'releases/Version83/validation-report.json').read_text())
    assert previous['passed'] and previous['game_sha256'] == sha(baseline)
    assert {k for k in hashes if hashes[k] != previous['source_hashes'][k]} == {'Server.lua'}
    checks = {}
    for name, count, key, test_key, test in (
        ('session', 171, 'sourceHashes', 'testHash', 'v78_session.lua'),
        ('server', 24, 'source_hashes', 'test_sha256', 'v79_server.lua'),
    ):
        data = json.loads((RELEASE / (name + '-checks.json')).read_text())
        assert data['passed'] and data['assertions'] == count and data[key] == hashes
        assert data[test_key] == sha(ROOT / 'tests' / test)
        checks[name] = count
    assert len(preservation['display_smoke_examples']) == 5
    assert 'Enabled=false' in (STAGE / 'CashShopConfig.lua').read_text()
    assert 'PreviewOnly=true' in (STAGE / 'CashShopConfig.lua').read_text()
    assert 'Enabled=true' in (STAGE / 'PersistenceConfig.lua').read_text()
    report = dict(
        passed=True, game=game.name, game_sha256=sha(game), baseline=baseline.name,
        baseline_sha256=sha(baseline), source_hashes=hashes, active_sources_compiled=109,
        modified_sources=['Server.lua'], added_modules=[], original_objects_preserved=315,
        only_change='Base earnings sign formatting; whole-dollar amount, fractional balance retained',
        current_offline_assertions=checks, display_smoke_examples=preservation['display_smoke_examples'],
        all_other_source_properties_hierarchy_and_backups_preserved=True,
        studio_multiplayer_tested=False, live_saving_and_purchases_tested=False,
        checkout_enabled=False, published_to_Roblox=False, public_launch_readiness_verified=False,
        limitations='Official Luau production code with controlled storage/recipient adapters and native display-statement smoke checks. No Roblox Studio, native rendering or live services tested here. V83 retains the broader unchanged-gameplay evidence.',
    )
    (RELEASE / 'validation-report.json').write_text(json.dumps(report, indent=2) + '\n')
    (RELEASE / 'TEST_RESULTS.md').write_text('''# V84 offline checks

Only one display statement in Server.lua changes from V83. The base collection sign displays whole dollars; it does not modify banked earnings, prices, level boosts or collection/saving rules.

- All 109 active Lua sources compile verbatim in official Luau.
- Existing durable session suite: 171 assertions pass, covering bank checkpoint/rejoin, items, receipts, recoverable theft and saved settings.
- Existing server snapshot/audio/owner-alert suite: 24 assertions pass.
- Exact production sign statement: the reported 1306.3000000000002 renders as $1306; accumulated 22.049999999999997 renders as $22. Zero, a sub-dollar balance and the two-billion bank cap are also checked. Each underlying fractional balance is unchanged.
- All 315 V83 place objects, references, properties, hierarchy and backups are preserved except the one approved source statement. The other 108 active source files are byte-identical, including every collectible model, catalog, power, profile and purchase module.

These are offline checks with API/storage adapters. No Studio playtest, native UI inspection, published-server saving, product purchase or performance test was performed here. Broader unchanged gameplay evidence remains in the V83 report. Checkout stays off and public launch readiness remains unverified.
''')
    for name in ('README.md', 'TEST_RESULTS.md'):
        assert (RELEASE / name).is_file()
    outputs = [archive(ROOT / 'releases/Version84_Game.zip', [game], ROOT / 'releases')]
    with zipfile.ZipFile(ROOT / 'releases/Version84_Game.zip') as bundle:
        assert bundle.namelist() == [game.name]
        assert bundle.read(game.name) == game.read_bytes()
    files = [game, baseline, ROOT / 'README.md', ROOT / 'releases/VERSION_84_HANDOFF.md',
             ROOT / 'releases/VERSION_83_HANDOFF.md']
    for folder in (STAGE, ROOT / 'roblox/v83-game', RELEASE, ROOT / 'releases/Version76/Audio'):
        files += [p for p in folder.rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    files += [p for p in (ROOT / 'tools').iterdir() if p.is_file() and p.suffix in {'.py', '.lua'}]
    files += list((ROOT / 'tests').glob('*.lua'))
    files += [ROOT / 'releases/Version83' / name for name in ('README.md', 'TEST_RESULTS.md', 'RELEASE_QUESTIONS.md', 'validation-report.json')]
    files += [ROOT / 'releases/Version80' / name for name in ('PRIVATE_TEST_STEPS.md', 'PRODUCT_IDS.md', 'ProductSetup.csv')]
    files += [ROOT / 'releases/Version78' / name for name in ('LAUNCH_CHECKLIST.md', 'ASSET_PERMISSIONS.md', 'ANALYTICS_PLAN.md')]
    outputs.append(archive(ROOT / 'releases/Version84_SourceAndGame.zip', files))
    assert all(row['bytes'] < 100_000_000 for row in outputs)
    (ROOT / 'releases/Version84_DOWNLOADS.json').write_text(json.dumps(outputs, indent=2) + '\n')
    for row in outputs:
        print(row['file'], row['bytes'], 'bytes', row['sha256'])


if __name__ == '__main__':
    main()
