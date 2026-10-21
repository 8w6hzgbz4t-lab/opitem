"""Package revised listing art and setup files without changing the V79 game."""
import csv
import hashlib
import json
from pathlib import Path
import zipfile

ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'releases/Version79_ArtworkUpdate'
TARGET=ROOT/'releases/Version79_DragonBallArtworkAndSetup.zip'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    base=json.loads((ROOT/'releases/Version79/preservation-report.json').read_text())
    game=ROOT/'releases'/base['output']
    assert sha(game)==base['output_sha256']
    for path,digest in base['source_hashes'].items():
        assert sha(ROOT/'roblox/v79-game'/path)==digest,'Gameplay source unexpectedly changed'
    art=json.loads((FOLDER/'art-manifest.json').read_text())
    assert len(art['files'])==2 and not art['uploaded_to_roblox']
    for row in art['files']:assert sha(FOLDER/row['file'])==row['sha256']
    assert art['files'][0]['width']==art['files'][0]['height']>=512
    assert abs(art['files'][1]['width']/art['files'][1]['height']-16/9)<.005
    metrics=json.loads((ROOT/'releases/Version76/Audio/audio-metrics.json').read_text())
    for name,digest in metrics['files'].items():assert sha(FOLDER/'Audio'/name)==digest,'Audio file changed'
    products=list(csv.DictReader((FOLDER/'ProductSetup.csv').open()))
    assert len(products)==15 and len({row['offer_id']for row in products})==15
    assert all(row['developer_product_id']=='0'for row in products),'Unconfigured setup sheet expected'
    assert len((FOLDER/'STORE_AND_AUDIO_SETUP.md').read_text())>2000
    report=dict(art_files_checked=2,audio_files_checked=len(metrics['files']),product_offers=15,
                all_product_ids_unconfigured=True,checkout_enabled=False,music_uploaded=False,
                gameplay_modified=False,game_sha256=sha(game),published_to_roblox=False)
    (FOLDER/'package-checks.json').write_text(json.dumps(report,indent=2)+'\n')
    files=sorted(path for path in FOLDER.rglob('*')if path.is_file())
    with zipfile.ZipFile(TARGET,'w',zipfile.ZIP_DEFLATED)as bundle:
        for path in files:bundle.write(path,path.relative_to(FOLDER))
    with zipfile.ZipFile(TARGET)as bundle:
        assert bundle.testzip()is None and len(bundle.infolist())==len(files)
        assert {'STORE_AND_AUDIO_SETUP.md','ProductSetup.csv','Audio/relic-rivalry-loop.ogg'}<=set(bundle.namelist())
    row=dict(file=TARGET.name,bytes=TARGET.stat().st_size,sha256=sha(TARGET),files=len(files))
    (ROOT/'releases/Version79_ArtworkUpdate_DOWNLOAD.json').write_text(json.dumps(row,indent=2)+'\n')
    print(json.dumps(row,indent=2))
if __name__=='__main__':main()
