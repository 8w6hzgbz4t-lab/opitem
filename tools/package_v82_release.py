"""Package the configured music ID after audio/source/place preservation checks."""
import csv
import hashlib
import json
from pathlib import Path
import zipfile
from package_v80_release import archive,sha

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v82-game'
RELEASE=ROOT/'releases/Version82'
MUSIC_ID=111355988554529


def main():
    p=json.loads((RELEASE/'preservation-report.json').read_text())
    hashes={path.relative_to(STAGE).as_posix():sha(path)for path in sorted(STAGE.rglob('*.lua'))}
    assert len(hashes)==107 and hashes==p['source_hashes']
    assert p['modified_sources']==['AudioConfig.lua']and not p['added_modules']
    assert p['original_objects_preserved']==p['total_objects']==313
    assert p['all_other_original_properties_hierarchy_and_backups_preserved']
    assert p['all_76_collectible_models_catalog_names_and_stats_preserved']
    game=ROOT/'releases'/p['output'];baseline=ROOT/'releases'/p['baseline']
    assert sha(game)==p['output_sha256']
    assert sha(baseline)==p['baseline_sha256']=='c31783ad964d8af34c7709f46aaace9ed847c67612590198201d56aa5961792f'
    previous=json.loads((ROOT/'releases/Version81/validation-report.json').read_text())
    assert previous['passed']and previous['game_sha256']==sha(baseline)
    assert hashes.keys()==previous['source_hashes'].keys()
    assert {key for key in hashes if hashes[key]!=previous['source_hashes'][key]}=={'AudioConfig.lua'}
    old=(ROOT/'roblox/v81-game/AudioConfig.lua').read_text()
    current=(STAGE/'AudioConfig.lua').read_text()
    assert current==old.replace('Music={AssetId=0,',f'Music={{AssetId={MUSIC_ID},')
    assert 'Enabled=false'in(STAGE/'CashShopConfig.lua').read_text()
    assert 'PreviewOnly=true'in(STAGE/'CashShopConfig.lua').read_text()
    audio=json.loads((RELEASE/'audio-checks.json').read_text())
    assert audio['passed']and audio['assertions']==140 and audio['compiled_sources']==107
    assert audio['configured_music_asset_id']==MUSIC_ID and audio['source_hashes']==hashes
    assert audio['test_sha256']==sha(ROOT/'tests/v82_audio.lua')
    assert audio['runner_sha256']==sha(ROOT/'tools/run_v82_audio_checks.py')
    assert not audio['roblox_asset_permissions_tested']and not audio['studio_playback_tested']
    progress=json.loads((RELEASE/'SetupProgress.json').read_text())
    assert progress['music_audio_id']==MUSIC_ID and progress['music_id_configured']
    assert not progress['checkout_enabled']and not progress['Studio_playback_tested']
    with(RELEASE/'AudioIDs.csv').open(newline='')as f:rows=list(csv.DictReader(f))
    assert len(rows)==11
    music=[row for row in rows if row['cue']=='Music']
    assert len(music)==1 and int(music[0]['audio_asset_id'])==MUSIC_ID
    assert all(not row['audio_asset_id']for row in rows if row['cue']!='Music')
    original=ROOT/'releases/Version76/Audio'
    for filename,digest in audio['assets']['files'].items():assert sha(original/filename)==digest
    assert sha(original/'relic-rivalry-loop.ogg')==progress['original_file_sha256']
    report=dict(passed=True,game=game.name,game_sha256=sha(game),baseline=baseline.name,
                baseline_sha256=sha(baseline),source_hashes=hashes,active_sources_compiled=107,
                modified_sources=['AudioConfig.lua'],unchanged_active_sources=106,
                original_objects_preserved=313,total_objects=313,collectibles_preserved=76,
                all_other_original_properties_hierarchy_and_backups_preserved=True,
                configured_music_asset_id=MUSIC_ID,audio_offline_assertions=audio['assertions'],
                native_Luau_audio_assertions=audio['native_luau_assertions'],
                music_asset_type_ownership_moderation_and_permissions_verified=False,
                studio_playback_tested=False,custom_SFX_ids_configured=0,
                existing_SFX_fallbacks_preserved=True,saved_mute_volume_preferences_preserved=True,
                product_ids_unchanged=True,checkout_live=False,published_to_Roblox=False,
                public_launch_readiness_verified=False,
                inherited_evidence='Version81/validation-report.json: all non-AudioConfig sources are byte-identical; its 3332 offline assertions were not rerun for this one-line music configuration change.',
                limitations='Audio tests record Sound.Play intent with controlled API/GUI doubles, including exact ID in native Luau. No actual Roblox request, audible playback, approval or universe permission verification occurred.')
    (RELEASE/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    lines=['# V82 test results','','**Offline audio checks pass. Actual Roblox playback remains unverified.**','',
           '- 140 assertions exercise actual AudioClient/AudioConfig: 129 through the existing Roblox sound/GUI adapter and 11 in native official Luau.',
           '- All 107 active production sources compile verbatim in official Luau. The configured ID becomes exactly `rbxassetid://111355988554529`, without precision loss or scientific notation.',
           '- Looping, quiet default volume, independent Music/SFX mute and sliders, zero-volume pause/resume, all ten ordinary power cues plus Royal Seal, cue whitelist, distance/malformed inputs, rate limits and cleanup pass with doubles.',
           '- Only the music ID changes from V81. All other 106 sources, all 313 place objects/properties/hierarchy/backups and all 76 collectible designs/stats are preserved. Move/Sell, saving, product IDs and checkout-off settings match V81.',
           '- Original music/SFX file hashes still match the preserved assets. Ten custom SFX IDs remain zero with built-in fallback cues.',
           '', 'The sound adapter records playback intent; it cannot establish that Roblox approved the upload, that the ID belongs to the correct audio/owner, that the experience has permission, or that a device audibly plays/loops it. Test those in the intended Roblox experience. Saved mute/volume preferences remain active.',
           '', 'Unchanged gameplay evidence is inherited by exact source hashes from Version81/validation-report.json. Its 3332 assertions were not rerun for this one-line configuration change. Existing live save/purchase/multiplayer/device/performance gates remain. Checkout stays off; no automatic Roblox publication occurred.',
           '', 'Reproduce audio checks: `python3 tools/run_v82_audio_checks.py --root roblox/v82-game --report releases/Version82/audio-checks.json --luau /path/to/luau` (requires texlua and official Luau CLI).',
           '', 'Game SHA-256: `'+sha(game)+'`.','']
    (RELEASE/'TEST_RESULTS.md').write_text('\n'.join(lines))
    outputs=[archive(ROOT/'releases/Version82_Game.zip',[game],ROOT/'releases')]
    with zipfile.ZipFile(ROOT/'releases/Version82_Game.zip')as z:
        assert z.namelist()==[game.name]and hashlib.sha256(z.read(game.name)).hexdigest()==sha(game)
    files=[game,baseline,ROOT/'README.md',ROOT/'releases/VERSION_82_HANDOFF.md',
           ROOT/'releases/VERSION_81_HANDOFF.md',ROOT/'releases/Version81/README.md',
           ROOT/'releases/Version81/TEST_RESULTS.md',ROOT/'releases/Version81/validation-report.json',
           ROOT/'releases/Version81/preservation-report.json',ROOT/'releases/Version81/AUDIO_UPLOAD.md']
    for folder in (STAGE,ROOT/'roblox/v81-game',RELEASE,original):
        files += [path for path in folder.rglob('*')if path.is_file()and '__pycache__'not in path.parts]
    files += [path for path in(ROOT/'tools').iterdir()if path.is_file()and path.suffix in{'.py','.lua'}]
    files += list((ROOT/'tests').glob('*.lua'))
    files += [ROOT/'releases/Version80'/name for name in('README.md','PRIVATE_TEST_STEPS.md','PRODUCT_IDS.md','ProductSetup.csv')]
    files += [ROOT/'releases/Version78'/name for name in('LAUNCH_CHECKLIST.md','ASSET_PERMISSIONS.md','ANALYTICS_PLAN.md')]
    for name in('README.md','AudioIDs.csv','SetupProgress.json','TEST_RESULTS.md'):assert(RELEASE/name).is_file()
    outputs.append(archive(ROOT/'releases/Version82_SourceAndGame.zip',files))
    assert all(row['bytes']<100_000_000 for row in outputs)
    (ROOT/'releases/Version82_DOWNLOADS.json').write_text(json.dumps(outputs,indent=2)+'\n')
    for row in outputs:print(row['file'],row['bytes'],'bytes',row['sha256'])


if __name__=='__main__':main()
