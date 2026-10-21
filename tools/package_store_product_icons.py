"""Validate all 15 upload-size product icons and package the owner setup sheet."""
import csv
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import zipfile

ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'releases/StoreIcons/Remaining14'
ZIP=ROOT/'releases/StoreProducts_All15_IconsAndSetup.zip'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    rows=list(csv.DictReader((FOLDER/'ProductSetup.csv').open()))
    create=list(csv.DictReader((FOLDER/'CREATE_PRODUCTS.csv').open()))
    assert len(rows)==15 and len(create)==14
    assert len({row['offer_id']for row in rows})==15
    pending={row['offer_id']for row in rows if row['developer_product_id']=='0'}
    assert {row['offer_id']for row in create}==pending
    assert rows[0]['offer_id']=='pocket'and rows[0]['developer_product_id']=='3720840251'
    assert (FOLDER/'ProductSetup.csv').read_bytes()==(ROOT/'releases/Version80/ProductSetup.csv').read_bytes()
    shutil.copyfile(ROOT/'releases/StoreIcons/PocketCash_5000.png',FOLDER/'pocket.png')
    shutil.copyfile(ROOT/'releases/StoreIcons/PocketCash_5000_original.png',FOLDER/'Originals/pocket.png')
    manifest=[]
    for row in rows:
        image=FOLDER/(row['offer_id']+'.png');original=FOLDER/'Originals'/image.name
        data=image.read_bytes();assert data[:8]==b'\x89PNG\r\n\x1a\n'
        width,height=struct.unpack('>II',data[16:24])
        assert (width,height,data[24],data[25])==(512,512,8,2),'Expected512pixel8bitRGB PNG: '+image.name
        assert original.is_file()
        reward=(row['cash']+' game cash')if row['cash']else(row['levels']+' base levels')if row['levels']else row['power']+' power'
        manifest.append(dict(offer_id=row['offer_id'],name=row['name'],file=image.name,proposed_robux=int(row['proposed_robux']),
                             reward=reward,width=width,height=height,sha256=sha(image),original_sha256=sha(original)))
    assert len({row['sha256']for row in manifest})==15,'Duplicate product artwork'
    for row in create:
        match=next(x for x in rows if x['offer_id']==row['offer_id'])
        assert row['name']==match['name']and row['robux']==match['proposed_robux']and row['icon_file']==row['offer_id']+'.png'
    preview=FOLDER/'All15_ProductIcons.png'
    subprocess.run(['magick','montage',*[str(FOLDER/row['file'])for row in manifest],
                    '-thumbnail','256x256','-tile','5x3','-geometry','256x256+10+10','-background','#101026',str(preview)],check=True)
    result=dict(upload_icons=15,new_icons=14,configured_product_ids=1,product_offers=15,
                recorded_pocket_cash_id=3720840251,roblox_ids_verified=False,checkout_enabled=False,
                original_art_preserved=True,icons=manifest,preview_sha256=sha(preview),published_to_roblox=False)
    (FOLDER/'icon-manifest.json').write_text(json.dumps(result,indent=2)+'\n')
    files=sorted(path for path in FOLDER.iterdir()if path.is_file()and not path.name.startswith('group-'))
    with zipfile.ZipFile(ZIP,'w',zipfile.ZIP_DEFLATED)as bundle:
        for path in files:bundle.write(path,path.name)
    with zipfile.ZipFile(ZIP)as bundle:
        assert bundle.testzip()is None and len(bundle.infolist())==len(files)
        assert 'Originals/pocket.png'not in bundle.namelist()
        for row in manifest:assert hashlib.sha256(bundle.read(row['file'])).hexdigest()==row['sha256']
    output=dict(file=ZIP.name,bytes=ZIP.stat().st_size,sha256=sha(ZIP),files=len(files),icons=15,new_icons=14)
    (ROOT/'releases/StoreProducts_All15_DOWNLOAD.json').write_text(json.dumps(output,indent=2)+'\n')
    print(json.dumps(output,indent=2))
if __name__=='__main__':main()
