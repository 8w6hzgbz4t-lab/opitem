"""Package the narrow V79 update only after source, test, place and media checks."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v79-game';RELEASE=ROOT/'releases/Version79'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def read(name):return json.loads((RELEASE/name).read_text())
def archive(target,files,relative=ROOT):
    files=sorted(set(files))
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED)as bundle:
        for path in files:bundle.write(path,path.relative_to(relative))
    with zipfile.ZipFile(target)as bundle:assert bundle.testzip()is None and len(bundle.infolist())==len(files)
    return dict(file=target.name,bytes=target.stat().st_size,sha256=sha(target),files=len(files))
def main():
    p=read('preservation-report.json')
    hashes={path.relative_to(STAGE).as_posix():sha(path)for path in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes)==106 and hashes==p['source_hashes']
    assert p['original_objects_preserved']==p['total_objects']==312 and not p['added_modules']
    assert p['all_other_original_properties_hierarchy_and_backups_preserved']
    assert set(p['modified_sources'])=={'Client.lua','PhaseClient.lua','PhaseService.lua','PersistentSession.lua','Server.lua'}
    game=ROOT/'releases'/p['output'];baseline=ROOT/'releases'/p['baseline']
    assert sha(game)==p['output_sha256']
    assert sha(baseline)==p['baseline_sha256']=='188f8827842ce36144c597113e4d31069516889297698aeffa0b227663c3706c'
    old=json.loads((ROOT/'releases/Version78/validation-report.json').read_text())
    assert old['passed']and old['game_sha256']==sha(baseline)
    for name,digest in hashes.items():
        if name not in p['modified_sources']:assert old['source_hashes'][name]==digest,'Unexpected subsystem change '+name
    checks={name:read(name+'-checks.json')for name in ('conveyor','power','session','codec','cashshop','hud','server','index-preview','profile')}
    for name,data in checks.items():assert data['passed'],name
    for name,key in (('conveyor','sourceHashes'),('power','sourceHashes'),('session','sourceHashes'),
                     ('codec','sourceHashes'),('cashshop','sourceHashes'),('server','source_hashes'),('index-preview','source_hashes')):
        assert checks[name][key]==hashes,'Stale full-source check '+name
    for name,key in (('hud','sourceHashes'),('profile','source_hashes')):
        assert all(hashes[path]==digest for path,digest in checks[name][key].items()),'Stale partial check '+name
    for name,key,test in (('conveyor','testHash','v79_conveyor.lua'),('power','testHash','v79_powers.lua'),
                          ('session','testHash','v78_session.lua'),('codec','testHash','v78_codec.lua'),
                          ('cashshop','testHash','v78_cashshop.lua'),('hud','testHash','v79_player_hud.lua'),
                          ('server','test_sha256','v79_server.lua'),('index-preview','test_sha256','v78_index_preview.lua'),
                          ('profile','test_sha256','v78_profiles.lua')):
        assert checks[name][key]==sha(ROOT/'tests'/test),'Stale test '+test
    assert checks['index-preview']['actual_factory_items']==76 and checks['index-preview']['all_bounding_corners_fit']
    art=read('Art/art-manifest.json')
    assert len(art['files'])==2 and not art['uploaded_to_roblox']
    for row in art['files']:
        assert sha(RELEASE/'Art'/row['file'])==row['sha256']
        assert row['width']>=512 and row['height']>=512
    assert art['files'][0]['width']==art['files'][0]['height']
    assert abs(art['files'][1]['width']/art['files'][1]['height']-16/9)<.005
    results={name:data['assertions']for name,data in checks.items()}
    report=dict(passed=True,game=game.name,game_sha256=sha(game),active_sources_compiled=106,
                current_offline_assertions=results,original_objects_preserved=312,added_modules=0,
                source_hashes=hashes,reviewed_modified_sources=p['modified_sources'],
                unchanged_subsystems_proven_by_exact_source_hashes=True,collectibles_preserved=76,
                saving_schema_and_product_configuration_unchanged=True,
                baseline_regressions_reproduced=['Unbought conveyor offer never expires when no player owns it',
                                               'Hologram/lifetime discarded the carried item'],
                fixed_ownerless_expiry=True,ownerless_expiry_writes_profiles=False,
                real_carries_survive_hologram_disposal=True,automatic_carry_timeout_removed=True,
                paid_losses_refunded=False,unfinished_bids_refund=True,owner_only_theft_banners=True,
                normal_controls_unchanged=True,new_listing_art_files=art['files'],
                inherited_evidence='Version78/validation-report.json; models, base geometry, flight and other unchanged source hashes are identical',
                checkout_live=False,music_asset_configured=False,studio_playtest_performed=False,
                published_to_roblox=False,public_launch_readiness_verified=False,
                limitations='Offline actual Luau/API/UI/native-geometry adapters. Real Studio multiplayer, native device input, DataStore latency/budgets, live purchases, physics/performance and audio/asset permissions remain owner-run release gates.')
    (RELEASE/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    lines=['# V79 test results','','**Offline checks pass; actual Studio testing remains required.**','',
           '| Actual production-code suite | Assertions |','| --- | ---: |']
    lines+=['| '+name+' | '+str(value)+' |'for name,value in results.items()]
    lines+=['','The new tests first reproduced the V78 unowned-item disposal failure and automatic timed carry loss. '
            'They now verify repeated conveyor replenishment, exact visual cleanup, hologram/real-item separation, '
            'valid power drops, no paid-loss refund, later delivery, owner-only taken/recovered/stolen alerts, '
            'and safety guards. Full save/crash/receipt and existing ten-power tests still pass.',
            '', 'All 312 original place objects, all 76 collectible designs/stats and all unmodified source files match V78. '
            'The builder preserves backup sources and every non-source property. The packager checks current test/source hashes and ZIP integrity.',
            '', 'No live Studio multiplayer, touch/controller device, DataStore, receipt, physics/FPS or audio permission test '
            'was performed in this cloud. Use the V78 launch checklist plus the focused V79 Play checks in README.md.',
            '', 'Game SHA-256: `'+sha(game)+'`.','']
    (RELEASE/'TEST_RESULTS.md').write_text('\n'.join(lines))
    outputs=[archive(ROOT/'releases/Version79_Game.zip',[game],ROOT/'releases')]
    with zipfile.ZipFile(ROOT/'releases/Version79_Game.zip')as bundle:
        assert bundle.namelist()==[game.name]
        assert hashlib.sha256(bundle.read(game.name)).hexdigest()==sha(game)
    art_files=[path for path in (RELEASE/'Art').rglob('*')if path.is_file()]+[RELEASE/'GAME_DESCRIPTION.txt']
    outputs.append(archive(ROOT/'releases/Version79_ArtAndDescription.zip',art_files,RELEASE))
    files=[game,baseline,ROOT/'README.md',ROOT/'releases/VERSION_79_HANDOFF.md',ROOT/'releases/StealAnOPItem_77_RobuxOffers.rbxlx']
    for directory in (STAGE,ROOT/'roblox/v78-game',ROOT/'roblox/v77-game',ROOT/'roblox/v76-game',
                      ROOT/'roblox/v75-game',ROOT/'roblox/v74-game',RELEASE,ROOT/'releases/Version78',
                      ROOT/'releases/Version77',ROOT/'releases/Version76'):
        files+=[path for path in directory.rglob('*')if path.is_file()and '__pycache__'not in path.parts]
    files+=[path for path in (ROOT/'tools').iterdir()if path.is_file()and path.suffix in {'.py','.lua'}]
    files+=list((ROOT/'tests').glob('*.lua'))
    outputs.append(archive(ROOT/'releases/Version79_SourceAndGame.zip',files))
    (ROOT/'releases/Version79_DOWNLOADS.json').write_text(json.dumps(outputs,indent=2)+'\n')
    for row in outputs:print(row['file'],row['bytes'],'bytes',row['sha256'])
if __name__=='__main__':main()
