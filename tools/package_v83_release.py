"""Package owner Sell/workbenches after current-code, geometry and save checks."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile
from package_v80_release import archive,sha

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v83-game';RELEASE=ROOT/'releases/Version83'


def read(name):return json.loads((RELEASE/name).read_text())


def main():
    p=read('preservation-report.json')
    hashes={path.relative_to(STAGE).as_posix():sha(path)for path in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes)==109 and hashes==p['source_hashes']
    changed={'Client.lua','PhaseClient.lua','PhaseService.lua','Server.lua'}
    added={'BaseWorkbench.lua','ItemPromptClient.lua'}
    assert set(p['modified_sources'])==changed and set(p['added_modules'])==added
    assert p['original_objects_preserved']==313 and p['total_objects']==315
    assert p['all_other_original_properties_hierarchy_and_backups_preserved']
    assert p['all_76_collectible_models_catalog_names_and_stats_preserved']
    assert p['approved_property_changes']==[{'class':'Players','property':'MaxPlayersInternal','before':12,'after':8}]
    game=ROOT/'releases'/p['output'];baseline=ROOT/'releases'/p['baseline']
    assert sha(game)==p['output_sha256']
    assert sha(baseline)==p['baseline_sha256']=='6ec75ff8f854692e05cf77ed516cbb11a6b457e756e0493b2591ad00f4da97fe'
    old=json.loads((ROOT/'releases/Version82/validation-report.json').read_text())
    assert old['passed']and old['game_sha256']==sha(baseline)
    assert set(hashes)-set(old['source_hashes'])==added
    assert {key for key in old['source_hashes']if hashes[key]!=old['source_hashes'][key]}==changed
    root=ET.parse(game).getroot();players=[i for i in root.iter('Item')if i.get('class')=='Players']
    assert len(players)==1 and players[0].findtext("Properties/int[@name='MaxPlayersInternal']")=='8'
    assert 'MaxPlayers=8'in(STAGE/'Config.lua').read_text()
    assert 'Enabled=false'in(STAGE/'CashShopConfig.lua').read_text()and 'PreviewOnly=true'in(STAGE/'CashShopConfig.lua').read_text()
    assert 'Music={AssetId=111355988554529,'in(STAGE/'AudioConfig.lua').read_text()
    checks={}
    for name,count,test in (
        ('power',971,'v83_powers.lua'),('prompt-client',36,'v83_prompt_client.lua'),
        ('conveyor',212,'v79_conveyor.lua'),('session',171,'v78_session.lua'),
        ('vault',105,'v81_vault.lua'),('cashshop',379,'v80_cashshop.lua'),
        ('vault-service',24,'v81_vault_service.lua'),
    ):
        data=read(name+'-checks.json');checks[name]=data
        assert data['passed']and data['assertions']==count,name
        assert data['sourceHashes']==hashes and data['sourcesCompiled']==109,'Stale sources '+name
        assert data['testHash']==sha(ROOT/'tests'/test),'Stale test '+name
    for name,count,test in(('hud',696,'v83_player_hud.lua'),('vault-ui',363,'v83_vault_ui.lua')):
        data=read(name+'-checks.json');checks[name]=data
        assert data['passed']and data['assertions']==count
        assert all(hashes[key]==digest for key,digest in data['sourceHashes'].items())
        assert data['testHash']==sha(ROOT/'tests'/test)
    for name,count,test in(('server',24,'v79_server.lua'),('join',36,'v83_join.lua')):
        data=read(name+'-checks.json');checks[name]=data
        assert data['passed']and data['assertions']==count and data['source_hashes']==hashes
        assert data['test_sha256']==sha(ROOT/'tests'/test)
    data=read('join-checks.json');assert data['runner_sha256']==sha(ROOT/'tools/run_v83_join_checks.py')
    data=read('admin-checks.json');checks['admin']=data
    assert data['passed']and data['assertions']==527 and data['authorized_command_dispatches']==233
    assert data['input_sha256']==dict(hashes,**{'@checks/v74_admin.lua':sha(ROOT/'tests/v78_admin.lua')})
    assert data['runner_sha256']==sha(ROOT/'tools/run_v78_admin_checks.py')
    data=read('audio-checks.json');checks['audio']=data
    assert data['passed']and data['assertions']==140 and data['compiled_sources']==109
    assert data['source_hashes']==hashes and data['configured_music_asset_id']==111355988554529
    assert data['test_sha256']==sha(ROOT/'tests/v82_audio.lua')and data['runner_sha256']==sha(ROOT/'tools/run_v82_audio_checks.py')
    data=read('base-workbench-checks.json');checks['base-workbench']=data
    assert data['passed']and data['assertions']==18338 and data['bases']==8
    assert all(hashes[key]==digest for key,digest in data['source_hashes'].items())
    assert data['test_sha256']==sha(ROOT/'tests/v83_base_workbench.lua')and data['runner_sha256']==sha(ROOT/'tools/run_v83_base_workbench_checks.py')
    results={name:data['assertions']for name,data in checks.items()}
    report=dict(passed=True,game=game.name,game_sha256=sha(game),baseline=baseline.name,
                baseline_sha256=sha(baseline),source_hashes=hashes,active_sources_compiled=109,
                modified_sources=sorted(changed),added_modules=sorted(added),unchanged_original_active_sources=103,
                original_objects_preserved=313,total_objects=315,approved_property_changes=p['approved_property_changes'],
                all_other_properties_hierarchy_and_backups_preserved=True,collectibles_preserved=76,
                current_offline_assertions=results,total_offline_assertions=sum(results.values()),
                own_stored_prompts='Sell with 50% confirmation',other_stored_prompts='Steal',
                server_derives_action_from_live_ownership=True,sale_opening_mutates_economy=False,
                moving_or_carried_items_sellable=False,sold_UIDs_recoverable_through_prompts=False,
                inventory_equip_label='Favorite; same saved star/preference',power_equip_behavior_unchanged=True,
                power_hotbar_text_size=10,selection_strokes_apply_to='button borders',
                base_workbenches=2,added_workbench_parts_per_base=64,configured_maximum_players=8,
                unique_vault_and_spawn_assignment_tested_with_doubles=True,Roblox_Dashboard_capacity_verified=False,
                music_asset_id=111355988554529,product_ids_unchanged=True,checkout_live=False,
                Studio_multiplayer_tested=False,native_input_rendering_physics_performance_tested=False,
                actual_audio_playback_tested=False,live_purchases_and_storage_tested=False,
                published_to_Roblox=False,public_launch_readiness_verified=False,
                limitations='Official Luau production-code tests with controlled API/player/GUI/storage/collision doubles and recorded native part geometry. Does not start Roblox Studio or verify live Roblox services/devices.')
    (RELEASE/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    lines=['# V83 test results','','**Offline checks pass. Actual Studio/private-server testing remains required.**','',
           '| Production-code suite | Assertions |','| --- | ---: |']
    lines += [f'| {name} | {count} |'for name,count in results.items()]
    lines += ['', 'All 109 active Lua sources compile verbatim in official Luau. The owner prompt test follows the actual 0.35-second server hold through confirmation, without changing money early; it verifies visitor theft, full vault sales, Move/carry/save/LOS gates, theft during a hold and stale sold UIDs. Client tests check personalized labels before display, ownership changes, late metadata, lifecycle cleanup and no authority changes.',
              '', 'Actual GUI/event checks cover item-specific confirmation/cancellation, Favorite preserving its stored preference action, stolen/deleted selection rejection, plain single-line power text and border-only selection outlines across desktop/phone/landscape layouts. Native rendering and controller/touch input are not simulated.',
              '', 'The actual Server join function assigns eight unique vaults and spawn points, rejects a ninth admitted player, avoids duplicate reservations under concurrent loads and releases failed/departed loads. Request-wiring checks retain Sell, Favorite and base upgrades near either workbench. These use controlled players and storage boundaries, rather than Roblox matchmaking.',
              '', 'Workbench tests record actual generated geometry for all eight bases: 64 parts each, bounds/door/pedestal clearance, retained anchor/callbacks, idempotent rebuilding and unobstructed forward prompt attachment segments in both orientations. Physics and visual appearance still need Studio inspection.',
              '', 'Saving/receipt, conveyor, power, developer and configured-audio regressions pass on the current source hashes. All 76 collectible designs/stats, music ID and product IDs match V82. All 313 existing objects and backups remain; two modules are added. The one approved non-source property change is Players.MaxPlayersInternal12→8; verify the published Dashboard setting separately.',
              '', 'No actual Studio multiplayer, live save/purchase, native device rendering/input, physics/FPS or Roblox audio/asset permission test occurred here. Checkout remains off. Nothing was published to Roblox automatically. Public launch readiness remains unverified. See RELEASE_QUESTIONS.md, the full launch checklist and private purchase steps.',
              '', 'Game SHA-256: `'+sha(game)+'`.','']
    (RELEASE/'TEST_RESULTS.md').write_text('\n'.join(lines))
    outputs=[archive(ROOT/'releases/Version83_Game.zip',[game],ROOT/'releases')]
    with zipfile.ZipFile(ROOT/'releases/Version83_Game.zip')as z:
        assert z.namelist()==[game.name]and hashlib.sha256(z.read(game.name)).hexdigest()==sha(game)
    files=[game,baseline,ROOT/'README.md',ROOT/'releases/VERSION_83_HANDOFF.md',ROOT/'releases/VERSION_82_HANDOFF.md',
           ROOT/'releases/Version82/README.md',ROOT/'releases/Version82/validation-report.json',ROOT/'releases/Version82/AudioIDs.csv']
    for folder in(STAGE,ROOT/'roblox/v82-game',RELEASE,ROOT/'releases/Version76/Audio'):
        files += [path for path in folder.rglob('*')if path.is_file()and '__pycache__'not in path.parts]
    files += [path for path in(ROOT/'tools').iterdir()if path.is_file()and path.suffix in{'.py','.lua'}]
    files += list((ROOT/'tests').glob('*.lua'))
    files += [ROOT/'releases/Version80'/name for name in('README.md','PRIVATE_TEST_STEPS.md','PRODUCT_IDS.md','ProductSetup.csv')]
    files += [ROOT/'releases/Version78'/name for name in('LAUNCH_CHECKLIST.md','ASSET_PERMISSIONS.md','ANALYTICS_PLAN.md')]
    for name in('README.md','TEST_RESULTS.md','RELEASE_QUESTIONS.md'):assert(RELEASE/name).is_file()
    outputs.append(archive(ROOT/'releases/Version83_SourceAndGame.zip',files))
    assert all(row['bytes']<100_000_000 for row in outputs)
    (ROOT/'releases/Version83_DOWNLOADS.json').write_text(json.dumps(outputs,indent=2)+'\n')
    for row in outputs:print(row['file'],row['bytes'],'bytes',row['sha256'])


if __name__=='__main__':main()
