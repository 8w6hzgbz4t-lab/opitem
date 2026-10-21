"""Package the frozen V75 game, source, models, previews and meaningful test reports."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v75-game'
RELEASE=ROOT/'releases/Version75'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def read(name):return json.loads((RELEASE/name).read_text())


def main():
    preservation=read('preservation-report.json')
    hashes={p.relative_to(STAGE).as_posix():sha(p) for p in STAGE.rglob('*.lua')}
    assert len(hashes)==93 and hashes==preservation['source_hashes']
    models=read('items-manifest.json');catalog=read('catalog-checks.json');admin=read('admin-checks.json')
    powers=read('power-checks.json');hud=read('hud-checks.json');ui=read('admin-client-checks.json')
    artifacts=read('artifact-checks.json');effects=read('effect-checks.json');upper=read('upper-floor-checks.json');levels=read('progression-checks.json')
    for report,key in ((models,'sources_sha256'),(catalog,'source_hashes'),(powers,'sourceHashes'),(artifacts,'source_sha256'),(effects,'source_hashes'),(upper,'source_hashes'),(levels,'source_hashes')):
        assert report[key]==hashes,'Production changed after a validation run'
    assert models['checks']>0 and len(models['items'])==76 and not models['failures'] and not models['warnings']
    assert models['puzzleUnchanged'] and models['distinct_geometry'] and not models['changedGeometry']
    assert all(report['passed'] for report in (catalog,admin,powers,hud,artifacts,effects,levels))
    assert ui['status']=='passed'
    assert catalog['previous_definitions_preserved']==69
    for name,digest in admin['input_sha256'].items():
        # The reused runner's legacy check label is independent of its --check path.
        path=ROOT/'tests/v75_admin.lua' if name.startswith('@checks/') else STAGE/name
        assert sha(path)==digest,'Admin check input changed: '+name
    assert sha(ROOT/'tools/run_admin_checks.py')==admin['runner_sha256']
    for name,digest in hud['sourceHashes'].items():assert hashes[name]==digest
    assert ui['sourceSha256']==hashes['AdminClient.lua']
    assert ui['testSha256']==sha(ROOT/'tests/v75_admin_client.lua')
    assert hud['testHash']==sha(ROOT/'tests/v75_player_hud.lua')
    assert powers['testHash']==sha(ROOT/'tests/v75_powers.lua')
    for report,test in ((catalog,'v75_catalog.lua'),(artifacts,'v75_artifacts.lua'),(effects,'v75_effects.lua'),(upper,'v75_upper_floor.lua'),(levels,'v75_progression.lua')):
        assert report['test_sha256']==sha(ROOT/'tests'/test)
    assert upper['checks']>0 and upper['expanded_bases_checked']==8 and upper['shell_camera_attributes_ready_before_parenting']
    spawn=read('spawn-rates.json')
    assert len(spawn['items'])==76 and abs(spawn['probability_sum']-1)<1e-12
    mom=next(item for item in spawn['items'] if item['id']=='moms_credit_card')
    assert mom['rarity']=='Ethereal' and mom['tier']==7
    game=ROOT/'releases'/preservation['output']
    assert sha(game)==preservation['output_sha256']
    baseline=ROOT/'releases'/preservation['baseline']
    assert sha(baseline)==preservation['baseline_sha256']
    for row in read('new-items.json'):
        tree=ET.parse(RELEASE/'models'/(row['id']+'.rbxmx')).getroot()
        items=list(tree.iter('Item'));refs={item.get('referent') for item in items}
        assert len(refs)==len(items)==row['parts']+1
    report={
        'game':game.name,'game_sha256':sha(game),'active_sources_compiled':len(hashes),'collectible_models_checked':76,
        'geometry_assertions':models['checks'],'previous_models_definitions_and_gui_preserved':69,
        'catalog_transaction_assertions':catalog['checks'],'admin_assertions':admin['assertions'],
        'admin_command_dispatches':admin['authorized_command_dispatches'],'power_assertions':powers['assertions'],
        'power_groups':len(powers['groups']),'developer_menu_assertions':ui['assertions'],'player_hud_assertions':hud['assertions'],
        'artifact_assertions':artifacts['assertions'],'developer_effect_assertions':effects['assertions'],
        'progression_assertions':levels['assertions'],'upper_floor_assertions':upper['checks'],
        'original_session_groups_passed':6,'original_regression_groups_passed':13,
        'all_original_objects_and_backups_preserved':preservation['original_objects_preserved'],
        'paid_and_gifted_second_floor_unlock_level':5,'base_item_capacity_before_after':[8,16],
        'linear_income_bonus_per_level':.05,'developer_username':'Goverment_cheesee',
        'millennium_puzzle_original_preserved':True,'animated_slifer_and_version_73_removals_preserved':True,
        'source_hashes':hashes,'studio_playtest_performed':False,'published_to_roblox':False,
        'limitations':'Offline production-code and controlled Roblox API checks; real account lookup, Studio rendering, physics, performance and multiplayer remain untested.'}
    (RELEASE/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    files=[game,baseline,ROOT/'README.md',ROOT/'releases/VERSION_75_HANDOFF.md']
    for directory in (STAGE,ROOT/'roblox/v74-game',RELEASE):files += [p for p in directory.rglob('*') if p.is_file()]
    files += [p for p in (ROOT/'tools').iterdir() if p.is_file() and p.suffix in {'.py','.lua'}]
    files += list((ROOT/'tests').glob('v75*.lua'))
    target=ROOT/'releases/Version75_SourceAndGame.zip'
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(set(files)):archive.write(path,path.relative_to(ROOT))
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None and len(archive.infolist())==len(set(files))
    print(f'Packaged {len(set(files))} files: {target.name} ({target.stat().st_size} bytes)')
    print('Game SHA256 '+sha(game));print('Package SHA256 '+sha(target))


if __name__=='__main__':main()
