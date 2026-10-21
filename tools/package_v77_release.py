"""Package V77 only after actual-code checks and baseline preservation agree."""
import hashlib
import json
from pathlib import Path
import zipfile
ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v77-game';RELEASE=ROOT/'releases/Version77'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(name):return json.loads((RELEASE/name).read_text())
def archive(target,files,relative):
    files=sorted(set(files))
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED)as z:
        for path in files:z.write(path,path.relative_to(relative))
    with zipfile.ZipFile(target)as z:assert z.testzip()is None and len(z.infolist())==len(files)
    return {'file':target.name,'bytes':target.stat().st_size,'sha256':sha(target),'files':len(files)}
def main():
    preservation=read('preservation-report.json')
    hashes={p.relative_to(STAGE).as_posix():sha(p)for p in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes)==99 and hashes==preservation['source_hashes']
    shop=read('cashshop-checks.json');ui=read('cashshop-client-checks.json')
    power=read('power-checks.json');server=read('server-checks.json')
    for data,key in ((shop,'sourceHashes'),(power,'sourceHashes'),(server,'source_hashes')):
        assert data['passed'] and data[key]==hashes,'Stale or failing production checks'
    assert ui['passed'] and ui['sourceSha256']==hashes['CashShopClient.lua'] and ui['benchSourceSha256']==hashes['CashShopBench.lua']
    for data,key,test in ((shop,'testHash','v77_cashshop.lua'),(power,'testHash','v76_powers.lua'),
                          (server,'test_sha256','v76_server.lua'),(ui,'testSha256','v77_cashshop_client.lua'),
                          (ui,'benchTestSha256','v77_cashshop_bench.lua')):
        assert data[key]==sha(ROOT/'tests'/test),'Stale test '+test
    game=ROOT/'releases'/preservation['output'];baseline=ROOT/'releases'/preservation['baseline']
    assert sha(game)==preservation['output_sha256'] and sha(baseline)==preservation['baseline_sha256']
    previous=json.loads((ROOT/'releases/Version76/validation-report.json').read_text())
    assert previous['game_sha256']==sha(baseline)
    for relative,digest in hashes.items():
        if relative not in preservation['modified_sources']:
            assert previous['source_hashes'][relative]==digest,'Preserved subsystem changed'
    report={'passed':True,'game':game.name,'game_sha256':sha(game),'active_sources_compiled':99,
            'shop_server_assertions':shop['assertions'],'shop_gui_assertions':ui['assertions'],
            'shop_geometry_assertions':ui['benchAssertions'],'power_assertions':power['assertions'],
            'server_glue_assertions':server['assertions'],'offers':{'cash':4,'levels':2,'regular_powers':7},
            'conveyor_collectibles_sold':False,'developer_perks_sold':False,'tag_free':True,
            'all_76_collectible_models_and_stats_preserved':True,'original_objects_preserved':305,
            'only_power_change_is_slow_field_description':True,'checkout_live':False,
            'saved_progress':False,'music_asset_configured':False,
            'unchanged_subsystem_evidence':'Version76/validation-report.json and exact preserved source hashes',
            'source_hashes':hashes,'studio_playtest_performed':False,'published_to_roblox':False,
            'limitations':'Offline production-code and GUI/geometry adapter checks; live receipts, saved profiles, audio IDs/permissions and Studio multiplayer remain outstanding.'}
    (RELEASE/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    outputs=[archive(ROOT/'releases/Version77_Game.zip',[game],ROOT/'releases')]
    files=[game,baseline,ROOT/'README.md',ROOT/'releases/VERSION_77_HANDOFF.md']
    for directory in (STAGE,ROOT/'roblox/v76-game',ROOT/'roblox/v74-game',RELEASE,ROOT/'releases/Version76'):
        files += [p for p in directory.rglob('*')if p.is_file()]
    files += [p for p in (ROOT/'tools').iterdir()if p.is_file()and p.suffix in {'.py','.lua'}]
    files += list((ROOT/'tests').glob('*.lua'))
    outputs.append(archive(ROOT/'releases/Version77_SourceAndGame.zip',files,ROOT))
    (ROOT/'releases/Version77_DOWNLOADS.json').write_text(json.dumps(outputs,indent=2)+'\n')
    for row in outputs:print(row['file'],row['bytes'],'bytes',row['sha256'])
if __name__=='__main__':main()
