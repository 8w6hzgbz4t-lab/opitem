"""Verify current V81 evidence and package game, source and owner audio uploads."""
import hashlib
import json
from pathlib import Path
import zipfile
from package_v80_release import archive, sha, EXPECTED_IDS

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v81-game'
RELEASE=ROOT/'releases/Version81'


def read(name):return json.loads((RELEASE/name).read_text())


def main():
    p=read('preservation-report.json')
    hashes={path.relative_to(STAGE).as_posix():sha(path)for path in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes)==107 and hashes==p['source_hashes']
    changed={'Client.lua','TransactionCore.lua','PersistentSession.lua','AdminService.lua','Server.lua'}
    assert set(p['modified_sources'])==changed and p['added_modules']==['VaultService.lua']
    assert p['original_objects_preserved']==312 and p['total_objects']==313
    assert p['all_other_original_properties_hierarchy_and_backups_preserved']
    assert p['all_76_collectible_models_catalog_names_and_stats_preserved']
    game=ROOT/'releases'/p['output'];baseline=ROOT/'releases'/p['baseline']
    assert sha(game)==p['output_sha256']
    assert sha(baseline)==p['baseline_sha256']=='92aa800091dc32d54c8ef6d68b32c97eea3d4b6bdf84be8d2df3336e645110b8'
    old=json.loads((ROOT/'releases/Version80/validation-report.json').read_text())
    assert old['passed']and old['game_sha256']==sha(baseline)
    assert set(hashes)-set(old['source_hashes'])=={'VaultService.lua'}
    assert {name for name,digest in old['source_hashes'].items()if hashes[name]!=digest}==changed
    assert old['configured_product_ids']==EXPECTED_IDS
    config=(STAGE/'CashShopConfig.lua').read_text()
    assert 'Enabled=false'in config and 'PreviewOnly=true'in config
    assert 'Music={AssetId=0,'in(STAGE/'AudioConfig.lua').read_text()
    checks={}
    specs=(('vault',105,'v81_vault.lua'),('vault-service',24,'v81_vault_service.lua'),
           ('cashshop',379,'v80_cashshop.lua'),('session',171,'v78_session.lua'),
           ('power',933,'v79_powers.lua'),('conveyor',212,'v79_conveyor.lua'))
    for name,count,test in specs:
        data=read(name+'-checks.json');checks[name]=data
        assert data['passed']and data['assertions']==count,name
        assert data['sourceHashes']==hashes and data['sourcesCompiled']==107,'Stale sources '+name
        assert data['testHash']==sha(ROOT/'tests'/test),'Stale test '+name
    for name,count,test in (('hud',648,'v79_player_hud.lua'),('vault-ui',309,'v81_vault_ui.lua')):
        data=read(name+'-checks.json');checks[name]=data
        assert data['passed']and data['assertions']==count
        assert all(hashes[key]==value for key,value in data['sourceHashes'].items())
        assert data['testHash']==sha(ROOT/'tests'/test)
    data=read('server-checks.json');checks['server']=data
    assert data['passed']and data['assertions']==24 and data['source_hashes']==hashes
    assert data['test_sha256']==sha(ROOT/'tests/v79_server.lua')
    data=read('admin-checks.json');checks['admin']=data
    assert data['passed']and data['assertions']==527 and data['authorized_command_dispatches']==233
    assert data['input_sha256']==dict(hashes,**{'@checks/v74_admin.lua':sha(ROOT/'tests/v78_admin.lua')})
    assert data['runner_sha256']==sha(ROOT/'tools/run_v78_admin_checks.py')
    audio=read('audio-upload-manifest.json')
    assert len(audio['files'])==11 and not audio['uploaded_to_roblox']
    assert not audio['audio_ids_configured']and not audio['studio_playback_verified']
    for row in audio['files']:
        assert sha(RELEASE/'AudioUpload'/row['file'])==row['sha256']
        assert sha(ROOT/'releases/Version76/Audio'/row['file'])==row['sha256']
    results={name:data['assertions']for name,data in checks.items()}
    report=dict(passed=True,game=game.name,game_sha256=sha(game),
                baseline=baseline.name,baseline_sha256=sha(baseline),
                active_sources_compiled=107,source_hashes=hashes,modified_sources=sorted(changed),
                added_modules=['VaultService.lua'],unchanged_original_active_sources=101,
                original_objects_preserved=312,total_objects=313,collectibles_preserved=76,
                original_properties_hierarchy_and_backups_preserved=True,
                current_offline_assertions=results,total_offline_assertions=sum(results.values()),
                move_selection_seconds=20,move_grants_theft_immunity=False,
                moving_or_carried_items_sellable=False,move_and_sale_saved_before_ack=True,
                separate_remove_feature=False,existing_sell_fraction=.5,
                product_ids_unchanged=EXPECTED_IDS,checkout_live=False,music_asset_configured=False,
                existing_SFX_fallbacks_preserved=True,original_audio_upload_files=11,
                inherited_evidence='V80/V79 validation reports; unchanged artwork, catalog, prices/income/spawn weights, power roster, flight, audio and receipt schema retain exact source hashes.',
                live_prices_and_product_ownership_verified=False,live_receipts_tested=False,
                studio_multiplayer_tested=False,native_touch_controller_tested=False,
                published_to_roblox=False,public_launch_readiness_verified=False,
                limitations='Official Luau with controlled storage, API, GUI and collision doubles. Real Roblox saves/receipts, multiplayer, devices, physics/performance and audio permission/playback still require testing.')
    (RELEASE/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    lines=['# V81 test results','','**Offline checks pass. Real Studio and Roblox testing remain required.**','',
           '| Production-code suite | Assertions |','| --- | ---: |']
    lines += [f'| {name} | {count} |'for name,count in results.items()]
    lines += ['',f'Total: {sum(results.values())} assertions. All 107 active sources compile verbatim in the official Luau CLI.',
              '', 'The new vault suite executes actual Core, ProfileCodec, ProfileStore and PersistentSession code. It verifies one saved UID after moving/rejoining, both floors, occupied/reserved-slot rejection, owner/token checks, cancellation/timeout/death, theft winning a race, Sell interlocks and exactly-once removal/payment. Before-write failures and ambiguous after-write failures recover the authoritative saved move or sale without recreating a sold item.',
              '', 'Request tests execute VaultService to check owner/base/floor boundaries, malformed inputs, storage/character safety and separate cancellation throttling. Actual Client GUI/event tests check Move, empty slot choices, confirmed existing Sell, absence of a Remove button, transit disabling, stale acknowledgements, cancellation and responsive layouts. Rendering and native controls are represented by doubles.',
              '', 'Existing saving, receipt, powers, conveyor, server, developer and HUD regressions pass on the current sources. All 15 IDs and checkout-off settings are unchanged from V80. The 312 original place objects/properties/hierarchy/backups remain; one new service module is added. All 76 collectible designs and stats are preserved by exact source hashes.',
              '', 'The original music and ten optional WAVs match their preserved file hashes. They have not been uploaded or played in Roblox. Background music remains silent with asset ID zero; existing SFX fallbacks remain.',
              '', 'No actual Studio multiplayer, production DataStore/Marketplace receipt, mobile/controller input, native physics/FPS or audio permission test was performed here. Keep checkout off and complete the V80 private purchase steps and V78 launch checklist. No automatic Roblox publication occurred. Public launch readiness is unverified.',
              '', 'Game SHA-256: `'+sha(game)+'`.','']
    (RELEASE/'TEST_RESULTS.md').write_text('\n'.join(lines))
    outputs=[archive(ROOT/'releases/Version81_Game.zip',[game],ROOT/'releases')]
    with zipfile.ZipFile(ROOT/'releases/Version81_Game.zip')as z:
        assert z.namelist()==[game.name]and hashlib.sha256(z.read(game.name)).hexdigest()==sha(game)
    audiofiles=[RELEASE/'AUDIO_UPLOAD.md',RELEASE/'audio-upload-manifest.json']+list((RELEASE/'AudioUpload').iterdir())
    outputs.append(archive(ROOT/'releases/Version81_AudioUpload.zip',audiofiles,RELEASE))
    files=[game,baseline,ROOT/'README.md',ROOT/'releases/VERSION_81_HANDOFF.md',ROOT/'releases/VERSION_80_HANDOFF.md',
           ROOT/'releases/StealAnOPItem_79_ConveyorAndTheftAlerts.rbxlx',ROOT/'releases/StealAnOPItem_77_RobuxOffers.rbxlx']
    for version in range(74,82):
        folder=ROOT/f'roblox/v{version}-game'
        files += [p for p in folder.rglob('*')if p.is_file()and '__pycache__'not in p.parts]
    for folder in [RELEASE]+[ROOT/f'releases/Version{v}'for v in range(76,81)]+[ROOT/'releases/Version79_ArtworkUpdate']:
        files += [p for p in folder.rglob('*')if p.is_file()and '__pycache__'not in p.parts]
    icons=ROOT/'releases/StoreIcons/Remaining14'
    files += [icons/(key+'.png')for key in EXPECTED_IDS]+[icons/'All15_ProductIcons.png']
    files += [p for p in(ROOT/'tools').iterdir()if p.is_file()and p.suffix in{'.py','.lua'}]
    files += list((ROOT/'tests').glob('*.lua'))
    for name in ('README.md','AUDIO_UPLOAD.md','TEST_RESULTS.md'):
        assert(RELEASE/name).is_file()
    outputs.append(archive(ROOT/'releases/Version81_SourceAndGame.zip',files))
    assert all(row['bytes']<100_000_000 for row in outputs)
    (ROOT/'releases/Version81_DOWNLOADS.json').write_text(json.dumps(outputs,indent=2)+'\n')
    for row in outputs:print(row['file'],row['bytes'],'bytes',row['sha256'])


if __name__=='__main__':main()
