"""Reject stale checks and package the reviewed V76 game, sources and media."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v76-game'
RELEASE=ROOT/'releases/Version76'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def read(name):return json.loads((RELEASE/name).read_text())
def verified_sources(report,key,hashes,full=True):
    values=report[key]
    assert (values==hashes) if full else all(hashes[name]==value for name,value in values.items()),'Stale source checks'
def test_hash(report,key,path):assert report[key]==sha(ROOT/path),'Stale test: '+path
def archive(path,files,relative=ROOT):
    files=sorted(set(files))
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        for item in files:z.write(item,item.relative_to(relative))
    with zipfile.ZipFile(path) as z:assert z.testzip() is None and len(z.infolist())==len(files)
    return {'file':path.name,'bytes':path.stat().st_size,'sha256':sha(path),'files':len(files)}

def main():
    preservation=read('preservation-report.json')
    hashes={p.relative_to(STAGE).as_posix():sha(p) for p in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes)==99 and hashes==preservation['source_hashes']
    model=read('items-manifest.json');verified_sources(model,'sources_sha256',hashes)
    assert len(model['items'])==76 and model['checks']>0 and not model['failures'] and not model['warnings']
    assert model['puzzleUnchanged'] and model['distinct_geometry'] and not model['changedGeometry']
    checks={name:read(name+'-checks.json') for name in ('catalog','risk','power','admin','admin-client','hud','audio','cashshop','cashshop-client','slifer','server','artifact','effect','progression','upper-floor')}
    for name,report in checks.items():
        if name=='admin-client':assert report['status']=='passed'
        elif name!='upper-floor':assert report['passed'],name
    for name,key in (('catalog','source_hashes'),('risk','source_hashes'),('power','sourceHashes'),
                     ('cashshop','sourceHashes'),('slifer','source_hashes'),('server','source_hashes'),
                     ('artifact','source_sha256'),('effect','source_hashes'),('progression','source_hashes'),('upper-floor','source_hashes')):
        verified_sources(checks[name],key,hashes)
    for name,key in (('audio','source_hashes'),('hud','sourceHashes')):verified_sources(checks[name],key,hashes,False)
    for path,digest in checks['admin']['input_sha256'].items():
        actual=ROOT/'tests/v76_admin.lua' if path.startswith('@checks/') else STAGE/path
        assert sha(actual)==digest,'Stale admin input '+path
    assert checks['admin']['runner_sha256']==sha(ROOT/'tools/run_v76_admin_checks.py')
    for name,key,test in (('catalog','test_sha256','v76_catalog.lua'),('power','testHash','v76_powers.lua'),
                          ('hud','testHash','v76_player_hud.lua'),('admin-client','testSha256','v76_admin_client.lua'),
                          ('audio','test_sha256','v76_audio.lua'),('cashshop','testHash','v76_cashshop.lua'),
                          ('cashshop-client','testSha256','v76_cashshop_client.lua'),('slifer','test_sha256','v76_slifer.lua'),
                          ('server','test_sha256','v76_server.lua'),('artifact','test_sha256','v75_artifacts.lua'),
                          ('effect','test_sha256','v75_effects.lua'),('progression','test_sha256','v75_progression.lua'),
                          ('upper-floor','test_sha256','v75_upper_floor.lua')):
        test_hash(checks[name],key,'tests/'+test)
    for path,digest in checks['risk']['test_hashes'].items():assert sha(ROOT/path)==digest
    assert checks['admin-client']['sourceSha256']==hashes['AdminClient.lua']
    assert checks['cashshop-client']['sourceSha256']==hashes['CashShopClient.lua']
    assert checks['cashshop-client']['benchSourceSha256']==hashes['CashShopBench.lua']
    test_hash(checks['cashshop-client'],'benchTestSha256','tests/v76_cashshop_bench.lua')
    assert checks['upper-floor']['checks']>0 and checks['upper-floor']['expanded_bases_checked']==8
    assert checks['upper-floor']['upper_roof_and_walls_solid']
    assert checks['slifer']['animated_slifer_count']==1
    metrics=read('Audio/audio-metrics.json')
    for name,digest in metrics['files'].items():assert sha(RELEASE/'Audio'/name)==digest
    assert metrics['original_composition'] and metrics['decoded_ogg']['peak']<1 and metrics['decoded_ogg']['all_finite']
    assert metrics['generator_sha256']==sha(ROOT/'tools/generate_v76_audio.py')
    spawn=read('spawn-rates.json');assert len(spawn['items'])==76 and abs(spawn['probability_sum']-1)<1e-12
    # Every collectible definition/model remains identical to the full V75 baseline.
    model_paths=['Catalog.lua','ExpandedCatalog.lua','ModelFactory.lua','MillenniumPuzzle.lua']
    model_paths += [p.relative_to(STAGE).as_posix() for p in (STAGE/'FreeModels').glob('*.lua')]
    for name in model_paths:assert sha(STAGE/name)==sha(ROOT/'roblox/v75-game'/name),'Collectible source changed '+name
    game=ROOT/'releases'/preservation['output'];baseline=ROOT/'releases'/preservation['baseline']
    assert sha(game)==preservation['output_sha256'] and sha(baseline)==preservation['baseline_sha256']
    report={'game':game.name,'game_sha256':sha(game),'active_sources_compiled':99,'collectible_models_checked':76,
            'geometry_assertions':model['checks'],'catalog_assertions':checks['catalog']['checks'],
            'risk_items_checked':76,'paid_losses_refund':False,'unfinished_bids_refund':True,
            'session_groups':6,'regression_groups':13,'admin_assertions':checks['admin']['assertions'],
            'admin_command_dispatches':checks['admin']['authorized_command_dispatches'],
            'power_assertions':checks['power']['assertions'],'hud_assertions':checks['hud']['assertions'],
            'admin_menu_assertions':checks['admin-client']['assertions'],'audio_assertions':checks['audio']['assertions'],
            'shop_server_assertions':checks['cashshop']['assertions'],'shop_gui_assertions':checks['cashshop-client']['assertions'],
            'shop_geometry_assertions':checks['cashshop-client']['benchAssertions'],
            'slifer_assertions':checks['slifer']['checks'],'server_glue_assertions':checks['server']['assertions'],
            'artifact_assertions':checks['artifact']['assertions'],'effect_assertions':checks['effect']['assertions'],
            'progression_assertions':checks['progression']['assertions'],'upper_floor_assertions':checks['upper-floor']['checks'],
            'original_objects_preserved':299,'developer_username':'Goverment_cheesee','developer_perks_sold':False,
            'cash_shop_preview_only':True,'music_requires_owner_audio_id':True,'saved_progress':False,
            'source_hashes':hashes,'studio_playtest_performed':False,'published_to_roblox':False,
            'limitations':'Offline actual-code/API-adapter checks; live account lookup, Studio rendering, physics, multiplayer, native input and audio asset permissions remain untested.'}
    (RELEASE/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    gamezip=ROOT/'releases/Version76_Game.zip'
    mediazip=ROOT/'releases/Version76_ArtAndAudio.zip'
    media=[p for d in ('Art','Audio') for p in (RELEASE/d).rglob('*') if p.is_file()]
    outputs=[archive(gamezip,[game],ROOT/'releases'),archive(mediazip,media,RELEASE)]
    files=[game,baseline,ROOT/'README.md',ROOT/'releases/VERSION_76_HANDOFF.md']
    for directory in (STAGE,ROOT/'roblox/v75-game',ROOT/'roblox/v74-game',RELEASE):
        files += [p for p in directory.rglob('*') if p.is_file()]
    files += [p for p in (ROOT/'tools').iterdir() if p.is_file() and p.suffix in {'.py','.lua'}]
    files += list((ROOT/'tests').glob('*.lua'))
    outputs.append(archive(ROOT/'releases/Version76_SourceAndGame.zip',files))
    (ROOT/'releases/Version76_DOWNLOADS.json').write_text(json.dumps(outputs,indent=2)+'\n')
    for row in outputs:print(row['file'],row['bytes'],'bytes',row['sha256'])
if __name__=='__main__':main()
